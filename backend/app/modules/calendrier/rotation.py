"""Proposer les gardes à venir d'après la rotation observée — calcul pur.

Sur la base réelle (rapport du 2026-11-12) : soirée tous les 10 jours,
vendredi entier toutes les 10 semaines, 24 h toutes les 16 semaines environ.
La période de chaque type est l'écart le plus fréquent entre ses gardes
connues (saisies ou détectées, pas les propositions), s'il apparaît au moins
trois fois ; sinon la valeur observée ci-dessus.

On part de la dernière garde passée de chaque type et on avance d'une
période à la fois. Un jour qui a déjà une garde n'est jamais proposé.
"""
from __future__ import annotations

from collections import Counter
from dataclasses import dataclass
from datetime import date, timedelta
from typing import Iterable

PERIODES_PAR_DEFAUT = {"soiree": 10, "jour": 70, "24h": 112}
OCCURRENCES_MIN = 3
VENDREDI = 4


@dataclass(frozen=True)
class GardeConnue:
    date: date
    type: str
    source: str


@dataclass(frozen=True)
class Proposition:
    date: date
    type: str
    periode: int
    note: str


def periode(dates: list[date], type_: str) -> int:
    """Écart le plus fréquent entre gardes successives d'un type."""
    ecarts = Counter((b - a).days for a, b in zip(dates, dates[1:]))
    if ecarts:
        ecart, nombre = ecarts.most_common(1)[0]
        if nombre >= OCCURRENCES_MIN and ecart > 0:
            return ecart
    return PERIODES_PAR_DEFAUT[type_]


def proposer(gardes: Iterable[GardeConnue], aujourdhui: date, horizon_jours: int = 92) -> list[Proposition]:
    gardes = list(gardes)
    occupees = {g.date for g in gardes}
    fin = aujourdhui + timedelta(days=horizon_jours)
    propositions: list[Proposition] = []
    for type_ in PERIODES_PAR_DEFAUT:
        connues = sorted(g.date for g in gardes if g.type == type_ and g.source != "prevision")
        if not connues:
            continue
        p = periode(connues, type_)
        # On part de la dernière garde passée ; une garde déjà saisie dans le
        # futur occupe son jour, la rotation continue autour.
        passees = [d for d in connues if d <= aujourdhui]
        jour = passees[-1] if passees else connues[0] - timedelta(days=p)
        while True:
            jour += timedelta(days=p)
            if jour > fin:
                break
            if jour <= aujourdhui or jour in occupees:
                continue
            note = f"proposée : rotation de {p} jours"
            if type_ != "jour" and jour.weekday() == VENDREDI:
                note += " · tombe un vendredi, à vérifier"
            propositions.append(Proposition(jour, type_, p, note))
            occupees.add(jour)
    return sorted(propositions, key=lambda x: x.date)
