"""
Rejeu : rejouer les commandes d'un produit jour par jour — calcul pur.

Chaque jour du rejeu :

1. **matin** : les commandes attendues ce jour arrivent ;
2. **journée** : la demande du jour est celle réellement vendue ; on en sert
   ce que le stock simulé permet, le reste est une vente perdue ;
3. **soir** (sauf le vendredi, jour de fermeture des grossistes et de
   l'officine) : on commande. La commande arrive après le délai du
   fournisseur en jours ouvrés (vendredi et samedi non ouvrés : jeudi →
   dimanche). Elle doit couvrir jusqu'à l'arrivée de la commande **suivante** :

       niveau cible S = demande prévue jusqu'à l'arrivée suivante + SS
       SS             = Z(classe ABC) × σ journalier × √(jours ouverts couverts),
                        au moins 1 boîte pour un produit qui se vend
       quantité       = S − stock − commandes en cours, arrondie à la boîte
       produit lent   : garder 1 boîte s'il s'est vendu dans les 6 mois

Un produit référencé pendant le rejeu reçoit sa première réception réelle et
n'est mesuré qu'à partir de ce jour (la réalité comme la simulation).

Limite connue : la demande « réelle » est la vente enregistrée ; les jours
où l'officine était en rupture, la vraie demande est inconnue (souvent sous-
estimée), ce qui avantage un peu l'historique dans la comparaison.
"""
from __future__ import annotations

import math
from dataclasses import dataclass
from datetime import date, timedelta
from typing import Optional

import numpy as np

from app.services import indicateurs_stock as ind
from app.services.prevision import modele as m

VENDREDI = 4
RECLASSEMENT_JOURS = 7       # le type de demande est recalculé chaque semaine


@dataclass(frozen=True)
class Politique:
    """Réglages de la politique de commande, comparés par le rejeu.

    z_facteur          multiplie le Z du taux de service (1 = A 95 %, B 90 %, C 85 %)
    plancher           stock de sécurité minimal d'un produit qui se vend (boîtes)
    plancher_rares     appliquer aussi ce plancher aux intermittents et sporadiques
    fenetre_lent       un produit lent est gardé en stock (1 boîte) s'il s'est
                       vendu dans ces derniers jours
    """
    nom: str = "actuelle"
    z_facteur: float = 1.0
    plancher: float = 1.0
    plancher_rares: bool = True
    fenetre_lent: int = 182


POLITIQUE = Politique()
RARES = ("intermittent", "sporadique")


@dataclass
class Produit:
    id: int
    demande: np.ndarray          # ventes nettes par jour (≥ 0), sur toute la période
    stock_hist: np.ndarray       # stock réel de fin de journée (nan si inconnu)
    classe_abc: Optional[str]
    delai_ouvres: int
    ramadan: float = 1.0
    saison: Optional[np.ndarray] = None
    # Première réception réelle, si le produit est référencé pendant le rejeu :
    # (indice du jour, quantité). Référencer un produit est une décision de
    # l'officine que la méthode ne peut pas deviner : le rejeu la reprend
    # telle quelle et ne mesure le produit qu'à partir de ce jour.
    lancement: Optional[tuple[int, float]] = None


@dataclass
class Resultat:
    id: int
    type: str
    classe_abc: Optional[str]
    jours: int
    rupture_reelle: int
    rupture_simulee: int
    stock_moyen_reel: float
    stock_moyen_simule: float
    demande: float
    servie: float
    commandes: int

    @property
    def taux_service(self) -> float:
        return self.servie / self.demande if self.demande else 1.0


def censure(demande: np.ndarray, stock_hist: np.ndarray) -> np.ndarray:
    """Jour sans information sur la demande : le matin le stock était nul
    (stock de la veille au soir ≤ 0) et rien n'a été vendu."""
    stock_matin = np.concatenate(([np.nan], stock_hist[:-1]))
    return (np.nan_to_num(stock_matin, nan=1.0) <= 0) & (demande <= 0)


def jour_de_commande_suivant(jour: date) -> date:
    suivant = jour + timedelta(days=1)
    return suivant + timedelta(days=1) if suivant.weekday() == VENDREDI else suivant


def simuler(p: Produit, dates: list[date], debut: int, cal: m.Calendrier, ouvert: np.ndarray,
            politique: Politique = POLITIQUE) -> Resultat:
    n = len(dates)
    cens = censure(p.demande, p.stock_hist)
    ventes_idx = np.flatnonzero(p.demande > 0)
    premiere = int(ventes_idx[0]) if ventes_idx.size else None
    z = ind.Z_PAR_CLASSE.get((p.classe_abc or "").upper(), ind.Z_DEFAUT) * politique.z_facteur

    stock = float(np.nan_to_num(p.stock_hist[debut - 1], nan=0.0)) if debut > 0 else 0.0
    arrivees = np.zeros(n + 30)
    stock_sim = np.zeros(n)
    demande_totale = servie = 0.0
    commandes = 0
    classe = m.classer(p.demande, cens, premiere, debut)
    depart = debut
    if p.lancement is not None and p.lancement[0] >= debut:
        depart = p.lancement[0]
        arrivees[depart] += p.lancement[1]

    for d in range(debut, n):
        stock += arrivees[d]
        demande = float(p.demande[d])
        sert = min(stock, demande)
        stock -= sert
        demande_totale += demande
        servie += sert
        stock_sim[d] = stock

        if dates[d].weekday() == VENDREDI or d < depart:
            continue
        if (d - debut) % RECLASSEMENT_JOURS == 0:
            classe = m.classer(p.demande, cens, premiere, d + 1)

        arrivee = (ind.date_livraison(dates[d], p.delai_ouvres) - dates[0]).days
        suivante = (ind.date_livraison(jour_de_commande_suivant(dates[d]), p.delai_ouvres) - dates[0]).days
        if classe.type == "lent":
            vendu_recemment = p.demande[max(0, d - politique.fenetre_lent):d + 1].sum() > 0
            cible = 1.0 if vendu_recemment else 0.0
        else:
            couverts = [dates[0] + timedelta(days=k) for k in range(d + 1, suivante)]
            r = m.rythme(p.demande, cens, ouvert, d + 1, classe.type, premiere)
            prevu = m.demande_prevue(r, couverts, cal, p.saison, p.ramadan)
            jours_ouverts = sum(1 for j in couverts if cal.poids(j, None, 1.0) > 0)
            securite = z * m.ecart_type(p.demande, cens, ouvert, d + 1) * math.sqrt(max(1, jours_ouverts))
            if r > 0 and (politique.plancher_rares or classe.type not in RARES):
                securite = max(securite, politique.plancher)
            cible = prevu + securite
        en_cours = float(arrivees[d + 1:].sum())
        manque = cible - stock - en_cours
        if manque > 1e-9 and arrivee < len(arrivees):
            arrivees[arrivee] += math.ceil(manque - 1e-9)
            commandes += 1

    reel = p.stock_hist[depart:]
    connus = ~np.isnan(reel)
    simule = stock_sim[depart:]
    return Resultat(
        id=p.id, type=classe.type, classe_abc=p.classe_abc, jours=int(connus.sum()),
        rupture_reelle=int((reel[connus] <= 0).sum()),
        rupture_simulee=int((simule[connus] <= 0).sum()),
        stock_moyen_reel=float(reel[connus].mean()) if connus.any() else 0.0,
        stock_moyen_simule=float(simule[connus].mean()) if connus.any() else 0.0,
        demande=demande_totale, servie=servie, commandes=commandes,
    )
