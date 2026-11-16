"""
Quantité à commander ce soir pour un produit — calcul pur, partagé par le
rejeu et l'écran Commandes (la méthode proposée est exactement celle mesurée).

    niveau cible S = demande prévue jusqu'à l'arrivée de la commande suivante + SS
    SS             = Z(classe ABC) × σ journalier × √(jours ouverts couverts),
                     au moins [plancher] boîte(s) pour un produit qui se vend
    quantité       = S − stock − commandes en cours, arrondie à la boîte
    produit lent   : garder 1 boîte s'il s'est vendu dans la fenêtre de la politique

La décision garde sa décomposition, pour que la ligne de commande dise
pourquoi (« 3,1 par jour × 3 jours + sécurité 2 − stock 5 »).
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
RARES = ("intermittent", "sporadique")


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
    # Mini / maxi (stratégie arrêtée le 2026-11-16) : on ne commande que sous
    # le mini, et alors jusqu'au maxi ; couverture visée par classe ABC.
    minmax: bool = False
    couverture_a: int = 15
    couverture_b: int = 21
    couverture_c: int = 30
    couverture_tension: int = 60
    # Produit lent et cher (une ordonnance vaut plus que ce montant) : pas de
    # stock, commandé à la demande du patient (Menopur, Decapeptyl…).
    lent_valeur_max: float = 5000.0

    def couverture(self, classe_abc: Optional[str], tension: bool = False) -> int:
        if tension:
            return self.couverture_tension
        return {"A": self.couverture_a, "B": self.couverture_b}.get((classe_abc or "").upper(), self.couverture_c)


# Politique retenue par l'officine le 2026-11-12 au vu du rejeu sur 12 mois
# (ruptures 13,7 % contre 29,5 % en réel, stock moyen −28 %).
POLITIQUE = Politique()
# Stratégie mini / maxi retenue le 2026-11-16 (lot habituel minimal, taille
# d'ordonnance, tension, génériques au niveau de la DCI).
MINMAX = Politique(nom="mini-maxi", minmax=True)
PLAFOND_LOT_JOURS = 90       # le lot habituel ne fait pas dépasser 90 jours de vente


@dataclass(frozen=True)
class Decision:
    type: str                 # type de demande (modele.classer)
    quantite: int             # boîtes à commander (0 : rien)
    rythme: float             # vente moyenne par jour ouvert
    jours_couverts: int       # jours jusqu'à l'arrivée de la commande suivante
    prevu: float              # demande prévue sur ces jours (calendrier compris)
    securite: float           # stock de sécurité
    cible: float              # niveau cible S (maxi en mini / maxi)
    stock: float
    en_cours: float
    arrivee: date             # livraison attendue de cette commande
    # Mini / maxi
    mini: float = 0.0
    maxi: float = 0.0
    couverture: int = 0        # jours visés au-delà de la livraison suivante
    ordonnance: int = 0        # taille habituelle d'une vente (P80)
    lot: int = 0               # lot habituel appliqué (0 : non)
    tension: bool = False
    sur_demande: bool = False  # lent et cher : pas de stock, commande à la demande
    # Génériques interchangeables calculés ensemble (code DCI, part de cette
    # marque, stock et maxi de tout le groupe).
    groupe: Optional[str] = None
    part: float = 1.0
    stock_groupe: float = 0.0
    maxi_groupe: float = 0.0


def jour_de_commande_suivant(jour: date) -> date:
    suivant = jour + timedelta(days=1)
    return suivant + timedelta(days=1) if suivant.weekday() == VENDREDI else suivant


def decider(demande: np.ndarray, cens: np.ndarray, ouvert: np.ndarray, dates: list[date], jour: int,
            classe: m.Classe, premiere: Optional[int], classe_abc: Optional[str], delai_ouvres: int,
            cal: m.Calendrier, stock: float, en_cours: float, saison: Optional[np.ndarray] = None,
            ramadan: float = 1.0, politique: Politique = POLITIQUE) -> Decision:
    """Décision du soir du jour [jour] (indice dans [dates]). Les séries
    [demande], [cens] et [ouvert] ne sont lues que jusqu'à [jour] inclus."""
    aujourd_hui = dates[jour]
    arrivee = ind.date_livraison(aujourd_hui, delai_ouvres)
    suivante = ind.date_livraison(jour_de_commande_suivant(aujourd_hui), delai_ouvres)
    couverts = m.jours_entre(aujourd_hui + timedelta(days=1), suivante)
    if classe.type == "lent":
        vendu = demande[max(0, jour - politique.fenetre_lent):jour + 1].sum() > 0
        r, prevu, securite = 0.0, 0.0, 0.0
        cible = 1.0 if vendu else 0.0
    else:
        z = ind.Z_PAR_CLASSE.get((classe_abc or "").upper(), ind.Z_DEFAUT) * politique.z_facteur
        r = m.rythme(demande, cens, ouvert, jour + 1, classe.type, premiere)
        prevu = m.demande_prevue(r, couverts, cal, saison, ramadan)
        jours_ouverts = sum(1 for j in couverts if cal.poids(j, None, 1.0) > 0)
        securite = z * m.ecart_type(demande, cens, ouvert, jour + 1) * math.sqrt(max(1, jours_ouverts))
        if r > 0 and (politique.plancher_rares or classe.type not in RARES):
            securite = max(securite, politique.plancher)
        cible = prevu + securite
    manque = cible - stock - en_cours
    # Tolérance : 3,0000000004 boîtes (bruit des poids du calendrier) font 3, pas 4.
    quantite = math.ceil(manque - 1e-6) if manque > 1e-6 else 0
    return Decision(classe.type, quantite, r, len(couverts), prevu, securite, cible, stock, en_cours, arrivee)


def decider_minmax(demande: np.ndarray, cens: np.ndarray, ouvert: np.ndarray, dates: list[date], jour: int,
                   classe: m.Classe, premiere: Optional[int], classe_abc: Optional[str], delai_ouvres: int,
                   cal: m.Calendrier, stock: float, en_cours: float, saison: Optional[np.ndarray] = None,
                   ramadan: float = 1.0, politique: Politique = MINMAX, ordonnance: float = 1.0, lot: int = 0,
                   tension: bool = False, vie_jours: Optional[int] = None, prix: float = 0.0) -> Decision:
    """Mini / maxi.

        mini  = max(demande jusqu'à la livraison suivante + SS, taille d'une ordonnance)
        maxi  = mini + demande prévue sur la couverture visée (A 15 j, B 21, C 30,
                en tension 60 — et pas plus que 80 % de la durée de vie à réception)
        on commande si stock + en cours < mini (en tension : < maxi),
        quantité = maxi − stock − en cours, au moins le lot habituel, sans que
        le lot fasse dépasser 90 jours de vente ni la péremption.
        Produit lent : mini = maxi = une ordonnance s'il s'est vendu récemment,
        sauf s'il est cher (une ordonnance > 5 000 DA) : commandé à la demande.
    """
    aujourd_hui = dates[jour]
    arrivee = ind.date_livraison(aujourd_hui, delai_ouvres)
    suivante = ind.date_livraison(jour_de_commande_suivant(aujourd_hui), delai_ouvres)
    couverts = m.jours_entre(aujourd_hui + timedelta(days=1), suivante)
    ordo = max(1, math.ceil(ordonnance - 1e-6))
    couv = politique.couverture(classe_abc, tension)
    if vie_jours:
        couv = max(7, min(couv, int(0.8 * vie_jours)))
    position = stock + en_cours
    sur_demande = False
    if classe.type == "lent":
        vendu = demande[max(0, jour - politique.fenetre_lent):jour + 1].sum() > 0
        r = prevu = securite = 0.0
        sur_demande = bool(vendu and not tension and politique.lent_valeur_max
                           and prix * ordo > politique.lent_valeur_max)
        mini = maxi = float(ordo) if vendu and not sur_demande else 0.0
        if tension and vendu:
            maxi = float(max(ordo, math.ceil(demande[max(0, jour - 365):jour + 1].sum() / 365 * couv - 1e-6)))
        r_plafond = float(demande[max(0, jour - 365):jour + 1].sum()) / 365
    else:
        z = ind.Z_PAR_CLASSE.get((classe_abc or "").upper(), ind.Z_DEFAUT) * politique.z_facteur
        r = m.rythme(demande, cens, ouvert, jour + 1, classe.type, premiere)
        prevu = m.demande_prevue(r, couverts, cal, saison, ramadan)
        jours_ouverts = sum(1 for j in couverts if cal.poids(j, None, 1.0) > 0)
        securite = z * m.ecart_type(demande, cens, ouvert, jour + 1) * math.sqrt(max(1, jours_ouverts))
        if r > 0 and (politique.plancher_rares or classe.type not in RARES):
            securite = max(securite, politique.plancher)
        mini = max(prevu + securite, float(ordo) if r > 0 else 0.0)
        apres = m.jours_entre(suivante, suivante + timedelta(days=couv))
        maxi = mini + m.demande_prevue(r, apres, cal, saison, ramadan)
        r_plafond = r
    seuil = maxi if tension else mini
    quantite, lot_applique = 0, 0
    if position < seuil - 1e-6 and maxi > 0:
        besoin = math.ceil(maxi - position - 1e-6)
        quantite = besoin
        if lot > besoin:
            jours_plafond = PLAFOND_LOT_JOURS if not vie_jours else min(PLAFOND_LOT_JOURS, int(0.8 * vie_jours))
            plafond = max(besoin, math.ceil(r_plafond * jours_plafond - 1e-6))
            quantite = min(lot, plafond)
            lot_applique = lot if quantite == lot else 0
    return Decision(classe.type, quantite, r, len(couverts), prevu, securite, maxi, stock, en_cours, arrivee,
                    mini=mini, maxi=maxi, couverture=couv, ordonnance=ordo, lot=lot_applique, tension=tension,
                    sur_demande=sur_demande)
