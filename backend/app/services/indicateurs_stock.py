"""
Indicateurs de gestion du stock d'un produit — calculs purs, sans base.

Définitions de référence : docs/05-stock-guide.md, section 5.

    CMM          = ventes nettes des 12 derniers mois ÷ mois d'historique (≤ 12)
    CMJ          = CMM ÷ 30
    L            = délai de livraison d'une commande passée aujourd'hui (jours)
    SS           = Z × σ × √L         (σ : écart-type des ventes journalières)
    SS simple    = CMJ × délai de sécurité
    stock max    = SS + CMM × (période entre deux commandes ÷ 30)
    couverture   = stock ÷ CMJ (jours)
    écoulable    = ce que le lot vendra avant sa péremption, en FEFO
    à risque     = stock du lot − écoulable

Les quantités sont des unités (pas de l'argent) ; seules les valeurs à
risque sont des montants, calculées en Decimal.
"""
from __future__ import annotations

import math
from dataclasses import dataclass
from datetime import date, timedelta
from decimal import Decimal
from typing import Iterable, Optional

# Taux de service visé par classe ABC → Z de la loi normale. Mêmes valeurs
# que le moteur d'achat (purchase_engine/stock_params.py) : A 95 %, B 90 %,
# C 85 %. Un produit non classé est traité comme B.
Z_PAR_CLASSE = {"A": 1.645, "B": 1.282, "C": 1.036}
Z_DEFAUT = Z_PAR_CLASSE["B"]

# Semaine algérienne : vendredi et samedi ne sont pas ouvrés (lundi = 0).
JOURS_NON_OUVRES = {4, 5}

JOURS_PAR_MOIS = 30


# ── Consommation ─────────────────────────────────────────────────────────────

def mois_historique(premiere_vente: Optional[date], aujourdhui: date) -> int:
    """Mois de ventes disponibles sur la fenêtre de 12 mois, entre 1 et 12.

    Un produit référencé il y a trois mois a trois mois d'historique : diviser
    ses ventes par 12 sous-estimerait sa consommation de 75 %.
    """
    if premiere_vente is None:
        return 12
    mois = (aujourdhui.year - premiere_vente.year) * 12 + aujourdhui.month - premiere_vente.month
    if aujourdhui.day < premiere_vente.day:
        mois -= 1
    return max(1, min(12, mois + 1))


def cmm(ventes_12_mois: float, mois: int) -> float:
    """Consommation moyenne mensuelle ; jamais négative (retours > ventes)."""
    return max(0.0, ventes_12_mois / max(1, mois))


def cmj(cmm_: float) -> float:
    """Consommation moyenne journalière."""
    return cmm_ / JOURS_PAR_MOIS


def ecart_type_journalier(ventes_par_jour: Iterable[float], nb_jours: int) -> float:
    """Écart-type des ventes journalières sur [nb_jours] jours, jours sans
    vente compris (ils comptent pour 0) : c'est la variabilité réelle."""
    valeurs = list(ventes_par_jour)
    if nb_jours <= 1:
        return 0.0
    zeros = max(0, nb_jours - len(valeurs))
    moyenne = sum(valeurs) / nb_jours
    somme = sum((v - moyenne) ** 2 for v in valeurs) + zeros * moyenne ** 2
    return math.sqrt(somme / (nb_jours - 1))


# ── Délai de livraison ───────────────────────────────────────────────────────

def date_livraison(commande: date, delai_jours_ouvres: int = 1) -> date:
    """Livraison après [delai_jours_ouvres] jours ouvrés : une commande du
    jeudi, à 24 h, arrive le dimanche."""
    jour = commande
    restants = max(1, delai_jours_ouvres)
    while restants:
        jour += timedelta(days=1)
        if jour.weekday() not in JOURS_NON_OUVRES:
            restants -= 1
    return jour


def delai_livraison(commande: date, delai_jours_ouvres: int = 1) -> int:
    """Délai en jours calendaires d'une commande passée le jour [commande]."""
    return (date_livraison(commande, delai_jours_ouvres) - commande).days


# ── Stock de sécurité et stock maximum ───────────────────────────────────────

def stock_securite(sigma_j: float, delai_j: int, classe_abc: Optional[str]) -> int:
    """SS statistique = Z × σ × √L, arrondi à l'unité supérieure."""
    z = Z_PAR_CLASSE.get((classe_abc or "").upper(), Z_DEFAUT)
    return math.ceil(z * sigma_j * math.sqrt(max(1, delai_j)) - 1e-9)


def stock_securite_simple(cmj_: float, delai_securite_j: float) -> int:
    """SS simple = CMJ × délai de sécurité."""
    return math.ceil(cmj_ * delai_securite_j - 1e-9)


def stock_maximum(ss: int, cmm_: float, periode_j: float) -> int:
    """Stock max = SS + CMM × période entre deux commandes."""
    return math.ceil(ss + cmm_ * periode_j / JOURS_PAR_MOIS - 1e-9)


def couverture_jours(stock: float, cmj_: float) -> Optional[int]:
    """Stock ÷ CMJ ; None sans consommation (non mesurable)."""
    if cmj_ <= 0:
        return None
    return math.floor(stock / cmj_)


# ── Péremption, en FEFO ──────────────────────────────────────────────────────

def fin_de_validite(peremption: date) -> date:
    """Un lot daté MM/YY est vendable jusqu'au dernier jour de ce mois."""
    suivant = date(peremption.year + peremption.month // 12, peremption.month % 12 + 1, 1)
    return suivant - timedelta(days=1)


def duree_vie_restante(peremption: Optional[date], aujourdhui: date) -> Optional[int]:
    """DVR en jours (0 si périmé) ; None si la date est inconnue."""
    if peremption is None:
        return None
    return max(0, (fin_de_validite(peremption) - aujourdhui).days)


@dataclass
class LotFefo:
    id: int
    stock: int
    peremption: Optional[date]
    prix_achat: Decimal = Decimal(0)
    bloque: bool = False


@dataclass
class RisqueLot:
    id: int
    dvr: Optional[int]
    ecoulable: Optional[int]
    a_risque: Optional[int]
    valeur_a_risque: Optional[Decimal]


def risques_fefo(lots: list[LotFefo], cmj_: float, aujourdhui: date) -> list[RisqueLot]:
    """Quantité écoulable et quantité à risque de chaque lot.

    Les lots sont vendus dans l'ordre de leur péremption (FEFO), au rythme
    CMJ. Un lot ne commence à se vendre qu'une fois les précédents épuisés ou
    périmés : sa quantité écoulable est donc CMJ × (DVR − temps déjà pris par
    les lots qui passent avant), et non CMJ × DVR. C'est ce qui fait qu'un lot
    à longue date peut être à risque derrière un gros lot plus court.

    Un lot bloqué ou sans date n'entre pas dans le calcul (résultat None).
    """
    datés = sorted(
        (l for l in lots if l.stock > 0 and l.peremption is not None and not l.bloque),
        key=lambda l: (l.peremption, l.id),
    )
    resultats: dict[int, RisqueLot] = {}
    t = 0.0  # jours de vente déjà consommés par les lots précédents
    for lot in datés:
        dvr = duree_vie_restante(lot.peremption, aujourdhui)
        disponible = max(0.0, dvr - t)
        ecoulable = min(lot.stock, math.floor(cmj_ * disponible + 1e-9)) if cmj_ > 0 else 0
        a_risque = lot.stock - ecoulable
        # Lot vendu en entier : le suivant commence quand il est épuisé.
        # Sinon, on le vend jusqu'à sa péremption ; le reste est perdu et le
        # suivant commence à cette date.
        if a_risque == 0:
            t += lot.stock / cmj_
        else:
            t = max(t, float(dvr))
        resultats[lot.id] = RisqueLot(
            id=lot.id, dvr=dvr, ecoulable=ecoulable, a_risque=a_risque,
            valeur_a_risque=(Decimal(a_risque) * lot.prix_achat).quantize(Decimal("0.01")),
        )
    return [
        resultats.get(l.id) or RisqueLot(
            id=l.id, dvr=duree_vie_restante(l.peremption, aujourdhui),
            ecoulable=None, a_risque=None, valeur_a_risque=None)
        for l in lots
    ]
