"""Choix des produits à compter un jour donné — logique pure, sans base.

Deux familles, dans cet ordre :
1. **suspects** : produit en rupture d'après EASYPHARM alors qu'il s'est
   vendu dans les 30 derniers jours (peut-être encore en rayon), pas compté
   depuis 14 jours. Au plus la moitié de la liste.
2. **échus** : produits dont le dernier comptage est plus vieux que la
   fréquence de leur classe (A 30 j, B 90 j, C 180 j par défaut), les plus en
   retard d'abord ; un produit jamais compté passe avant, classe A d'abord,
   puis la plus forte valeur en stock.
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from typing import Optional

SUSPECT_RECOMPTE_JOURS = 14


@dataclass(frozen=True)
class Candidat:
    id_nom: int
    classe: Optional[str]            # A, B, C ou None
    stock: int
    valeur: float                    # valeur du stock au prix d'achat
    derniere_vente: Optional[date]
    dernier_comptage: Optional[date]


def frequence(classe: Optional[str], jours: dict[str, int]) -> int:
    return jours.get((classe or "C").upper(), jours["C"])


def choisir(candidats: list[Candidat], jour: date, nombre: int, jours: dict[str, int]) -> list[tuple[int, str]]:
    """(id_nom, raison) des produits à compter, dans l'ordre de la liste."""
    if nombre <= 0:
        return []
    ordre = {"A": 0, "B": 1, "C": 2}

    def depuis(c: Candidat) -> Optional[int]:
        return None if c.dernier_comptage is None else (jour - c.dernier_comptage).days

    suspects = [c for c in candidats
                if c.stock <= 0 and c.derniere_vente is not None and (jour - c.derniere_vente).days <= 30
                and (depuis(c) is None or depuis(c) >= SUSPECT_RECOMPTE_JOURS)]
    suspects.sort(key=lambda c: (ordre.get((c.classe or "").upper(), 3), -(c.derniere_vente.toordinal()), c.id_nom))
    choisis = [(c.id_nom, "en rupture dans EASYPHARM, vendu récemment : vérifier le rayon")
               for c in suspects[:nombre // 2]]
    pris = {i for i, _ in choisis}

    echus = []
    for c in candidats:
        if c.id_nom in pris or c.stock <= 0:
            continue
        d, f = depuis(c), frequence(c.classe, jours)
        if d is None:
            echus.append((0, ordre.get((c.classe or "").upper(), 3), -c.valeur, c.id_nom, "jamais compté"))
        elif d >= f:
            echus.append((1, -d / f, ordre.get((c.classe or "").upper(), 3), c.id_nom,
                          f"dernier comptage il y a {d} jours"))
    echus.sort()
    for e in echus[:nombre - len(choisis)]:
        choisis.append((e[3], e[4]))
    return choisis
