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

from dataclasses import dataclass, field
from datetime import date
from typing import Optional

import numpy as np

from app.services.prevision import modele as m
from app.services.prevision.proposition import (  # noqa: F401  (réexportés)
    POLITIQUE, RARES, VENDREDI, Politique, decider, jour_de_commande_suivant,
)

RECLASSEMENT_JOURS = 7       # le type de demande est recalculé chaque semaine


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
    # Génériques (prevision.generiques) : code DCI et choix du titulaire.
    code_dci: Optional[str] = None
    choix: Optional[str] = None
    # Marque non gardée de son groupe : jamais recommandée, son stock s'écoule.
    remplace: bool = False
    # Marque gardée : demande propre (la série `demande` reçoit en plus la
    # demande non servie des marques remplacées), et demande des marques
    # remplacées à ajouter à la prévision à partir de leur épuisement :
    # (part × ventes de la marque remplacée, indice du jour d'épuisement).
    demande_propre: Optional[np.ndarray] = None
    reports: list = field(default_factory=list)

    def serie_prevision(self, jour: int) -> np.ndarray:
        """Série sur laquelle se prévoit la demande au jour [jour]."""
        base = self.demande if self.demande_propre is None else self.demande_propre
        actifs = [h for h, j in self.reports if jour >= j]
        return base + sum(actifs) if actifs else base


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


def simuler(p: Produit, dates: list[date], debut: int, cal: m.Calendrier, ouvert: np.ndarray,
            politique: Politique = POLITIQUE) -> Resultat:
    n = len(dates)
    propre = p.demande if p.demande_propre is None else p.demande_propre
    cens = censure(propre, p.stock_hist)
    ventes_idx = np.flatnonzero(propre > 0)
    premiere = int(ventes_idx[0]) if ventes_idx.size else None

    stock = float(np.nan_to_num(p.stock_hist[debut - 1], nan=0.0)) if debut > 0 else 0.0
    arrivees = np.zeros(n + 30)
    stock_sim = np.zeros(n)
    demande_totale = servie = 0.0
    commandes = 0
    classe = m.classer(propre, cens, premiere, debut)
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

        if dates[d].weekday() == VENDREDI or d < depart or p.remplace:
            continue
        serie = p.serie_prevision(d)
        if (d - debut) % RECLASSEMENT_JOURS == 0:
            classe = m.classer(serie, cens, premiere, d + 1)

        en_cours = float(arrivees[d + 1:].sum())
        dec = decider(serie, cens, ouvert, dates, d, classe, premiere, p.classe_abc, p.delai_ouvres,
                      cal, stock, en_cours, p.saison, p.ramadan, politique)
        arrivee = (dec.arrivee - dates[0]).days
        if dec.quantite > 0 and arrivee < len(arrivees):
            arrivees[arrivee] += dec.quantite
            commandes += 1

    reel = p.stock_hist[depart:]
    connus = ~np.isnan(reel)
    simule = stock_sim[depart:]
    if p.remplace:
        # Sa demande non servie passe aux marques gardées : ni rupture ni perte ici.
        servie = demande_totale
    return Resultat(
        id=p.id, type="remplacé" if p.remplace else classe.type, classe_abc=p.classe_abc, jours=int(connus.sum()),
        rupture_reelle=int((reel[connus] <= 0).sum()),
        rupture_simulee=0 if p.remplace else int((simule[connus] <= 0).sum()),
        stock_moyen_reel=float(reel[connus].mean()) if connus.any() else 0.0,
        stock_moyen_simule=float(simule[connus].mean()) if connus.any() else 0.0,
        demande=demande_totale, servie=servie, commandes=commandes,
    )


# ── Génériques ──────────────────────────────────────────────────────────────

FENETRE_DISPONIBLE = 60      # un générique vendu ou en stock dans ces jours est « disponible »


@dataclass
class BilanGeneriques:
    groupes: int = 0
    groupes_chroniques: int = 0
    remplaces: int = 0


def regrouper(produits: list[Produit], debut: int, classes_chroniques: set[str],
              modes_forces: dict[str, str], nombre: int,
              fenetre: int = FENETRE_DISPONIBLE) -> tuple[list[Produit], BilanGeneriques, dict[int, "g.Statut"]]:
    """Applique la règle des génériques au jour [debut] (ventes des 12 mois
    d'avant, disponibilité des [fenetre] jours d'avant). Les marques
    remplacées gardent leur stock, qui s'écoule ; leur demande non servie,
    jour après jour, passe aux marques gardées, et leurs ventes s'ajoutent à
    la prévision des gardées dès leur épuisement."""
    from app.services.prevision import generiques as g

    groupes: dict[str, list[Produit]] = {}
    for p in produits:
        code = g.normaliser(p.code_dci)
        if code:
            groupes.setdefault(code, []).append(p)
    bilan = BilanGeneriques()
    statuts: dict[int, g.Statut] = {}
    nouveaux = {p.id: p for p in produits}
    for code, membres in groupes.items():
        if len(membres) < 2:
            continue
        bilan.groupes += 1
        mode = g.mode_du_groupe(code, classes_chroniques, modes_forces.get(code))
        if mode == g.TOUTES:
            bilan.groupes_chroniques += 1
        d0 = max(0, debut - fenetre)
        infos = [g.Membre(
            id=p.id, ventes=float(p.demande[max(0, debut - 365):debut].sum()),
            disponible=bool(p.demande[d0:debut].sum() > 0 or np.nan_to_num(p.stock_hist[d0:debut], nan=0).max(initial=0) > 0),
            choix=p.choix) for p in membres]
        st = g.choisir(code, infos, mode, nombre)
        statuts.update(st)
        for p in membres:
            s_ = st[p.id]
            if s_.garde:
                continue
            bilan.remplaces += 1
            # Écoulement du stock de la marque remplacée, sans réassort.
            stock = float(np.nan_to_num(p.stock_hist[debut - 1], nan=0.0)) if debut > 0 else 0.0
            non_servie = np.zeros_like(p.demande)
            epuisement = debut
            for d in range(debut, len(p.demande)):
                sert = min(stock, float(p.demande[d]))
                stock -= sert
                non_servie[d] = p.demande[d] - sert
                if stock > 0:
                    epuisement = d + 1
            nouveaux[p.id] = Produit(**{**p.__dict__, "remplace": True})
            for k, part in s_.parts.items():
                q = nouveaux[k]
                propre = q.demande_propre if q.demande_propre is not None else q.demande.copy()
                nouveaux[k] = Produit(**{**q.__dict__, "demande": q.demande + part * non_servie,
                                         "demande_propre": propre,
                                         "reports": [*q.reports, (part * p.demande, epuisement)]})
    return [nouveaux[p.id] for p in produits], bilan, statuts
