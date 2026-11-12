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


# Politique retenue par l'officine le 2026-11-12 au vu du rejeu sur 12 mois
# (ruptures 13,7 % contre 29,5 % en réel, stock moyen −28 %).
POLITIQUE = Politique()


@dataclass(frozen=True)
class Decision:
    type: str                 # type de demande (modele.classer)
    quantite: int             # boîtes à commander (0 : rien)
    rythme: float             # vente moyenne par jour ouvert
    jours_couverts: int       # jours jusqu'à l'arrivée de la commande suivante
    prevu: float              # demande prévue sur ces jours (calendrier compris)
    securite: float           # stock de sécurité
    cible: float              # niveau cible S
    stock: float
    en_cours: float
    arrivee: date             # livraison attendue de cette commande


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
