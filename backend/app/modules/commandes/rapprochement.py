"""Rapprochement des livraisons : ce qu'EASYPHARM a reçu, face aux lignes commandées.

Logique pure, sans base. Une réception (entrée EASYPHARM) est attribuée à
la plus ancienne ligne encore ouverte du même grossiste et du même produit,
envoyée avant elle. Une ligne reste ouverte jusqu'à `TOLERANCE` jours après
sa livraison prévue : au-delà, ce qui arrive appartient à une commande
suivante ou à un achat hors commande.

États d'une ligne, au jour donné :
    attendue   pas encore (toute) reçue, livraison prévue pas dépassée
    livree     reçue en entier
    partielle  reçue en partie, livraison prévue dépassée
    manquante  rien reçu, livraison prévue dépassée
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import date, timedelta
from typing import Iterable, Optional

TOLERANCE = 7   # jours après la livraison prévue pendant lesquels une réception solde encore la ligne

ATTENDUE, LIVREE, PARTIELLE, MANQUANTE = "attendue", "livree", "partielle", "manquante"


@dataclass(frozen=True)
class Ligne:
    id: int
    id_fournisseur: int
    id_nom: int
    qte: int
    depuis: date    # jour de l'envoi : seules les réceptions d'après comptent
    prevue: date    # livraison prévue


@dataclass(frozen=True)
class Reception:
    id_fournisseur: int
    id_nom: int
    jour: date
    qte: int


@dataclass
class Suivi:
    recu: int = 0
    recu_le: Optional[date] = None
    etat: str = ATTENDUE

    def reste(self, ligne: Ligne) -> int:
        return max(0, ligne.qte - self.recu)


def rapprocher(lignes: Iterable[Ligne], receptions: Iterable[Reception], jour: date,
               tolerance: int = TOLERANCE) -> dict[int, Suivi]:
    """Suivi de chaque ligne (par id), vu du jour donné."""
    lignes = sorted(lignes, key=lambda l: (l.depuis, l.id))
    suivis = {l.id: Suivi() for l in lignes}
    par_cle: dict[tuple[int, int], list[Ligne]] = {}
    for l in lignes:
        par_cle.setdefault((l.id_fournisseur, l.id_nom), []).append(l)
    for r in sorted(receptions, key=lambda r: r.jour):
        if r.jour > jour:
            continue
        reste = r.qte
        for l in par_cle.get((r.id_fournisseur, r.id_nom), ()):
            if reste <= 0:
                break
            s = suivis[l.id]
            if not (l.depuis < r.jour <= l.prevue + timedelta(days=tolerance)) or s.recu >= l.qte:
                continue
            pris = min(reste, l.qte - s.recu)
            s.recu += pris
            s.recu_le = r.jour
            reste -= pris
    for l in lignes:
        s = suivis[l.id]
        if s.recu >= l.qte:
            s.etat = LIVREE
        elif jour <= l.prevue:
            s.etat = ATTENDUE
        else:
            s.etat = PARTIELLE if s.recu > 0 else MANQUANTE
    return suivis


def etat_commande(etats: Iterable[str]) -> str:
    """État d'une commande d'après ses lignes : attendue tant qu'une ligne
    l'est, sinon livrée (tout reçu), manquante (rien reçu) ou partielle."""
    etats = list(etats)
    if not etats or ATTENDUE in etats:
        return ATTENDUE
    if all(e == LIVREE for e in etats):
        return LIVREE
    if all(e == MANQUANTE for e in etats):
        return MANQUANTE
    return PARTIELLE
