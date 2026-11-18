"""Répartition de l'enveloppe de la prime de rendement — logique pure, en Decimal.

Aucun float : c'est de l'argent (règle « Argent » du CLAUDE.md). Les entrées
sont converties en Decimal par `en_decimal`, sans jamais passer par float.

Deux étapes :

1. **Score distributif** (`scores`) : pour chaque KPI, la part de l'équipe
   que représente l'employé, multipliée par le poids du KPI :
       score_i = Σ_kpi (valeur_i ÷ total_équipe) × poids
   Un KPI dont le total d'équipe est nul ne compte pour personne. Le score
   n'est pas une note sur 100 : c'est un cumul de parts d'équipe, borné par
   Σ poids ; seul le rapport entre employés compte.

2. **Répartition** (`repartir`) avec plancher (règle 4, arbitrage 2026-08-19) :
       part_egalitaire = enveloppe ÷ nb d'éligibles présents
       plancher_i      = part_egalitaire × taux_plancher   (présents seulement)
       reste           = enveloppe − Σ plancher_i
       prime_i         = plancher_i + (score_i ÷ Σ scores) × reste
   Avec `taux_plancher = 0`, c'est la répartition au seul mérite.

Les primes sont arrondies au centime ; les centimes perdus à l'arrondi sont
rendus aux plus fortes parties décimales, pour que Σ primes = enveloppe au
centime près, toujours.
"""
from __future__ import annotations

from decimal import ROUND_DOWN, Decimal
from typing import Hashable, Iterable, Mapping, TypeVar

CENTIME = Decimal("0.01")
PLANCHER = Decimal("0.5")   # règle 4 : 50 % de la part égalitaire

K = TypeVar("K", bound=Hashable)


def en_decimal(valeur) -> Decimal:
    """Convertit sans passer par float : None → 0, int et str exacts, float par sa représentation."""
    if valeur is None:
        return Decimal(0)
    if isinstance(valeur, Decimal):
        return valeur
    return Decimal(str(valeur))


def scores(valeurs: Mapping[K, Mapping[str, object]], poids: Mapping[str, object]) -> dict[K, Decimal]:
    """Score distributif de chaque employé (voir l'en-tête)."""
    resultat = {e: Decimal(0) for e in valeurs}
    for code, p in poids.items():
        p = en_decimal(p)
        if p <= 0:
            continue
        total = sum((en_decimal(v.get(code)) for v in valeurs.values()), Decimal(0))
        if total <= 0:
            continue
        for e, v in valeurs.items():
            resultat[e] += en_decimal(v.get(code)) / total * p
    return resultat


def _au_centime(montants: Mapping[K, Decimal], total: Decimal) -> dict[K, Decimal]:
    """Arrondit au centime en gardant la somme exacte (méthode du plus fort reste)."""
    tronques = {e: m.quantize(CENTIME, rounding=ROUND_DOWN) for e, m in montants.items()}
    manque = int(((total - sum(tronques.values(), Decimal(0))) / CENTIME).to_integral_value())
    ordre = sorted(montants, key=lambda e: (montants[e] - tronques[e], str(e)), reverse=True)
    for e in ordre[:max(0, manque)]:
        tronques[e] += CENTIME
    return tronques


def repartir(enveloppe, scores_: Mapping[K, object], presents: Iterable[K],
             taux_plancher=PLANCHER) -> dict[K, dict[str, Decimal]]:
    """Prime de chaque employé : {"plancher", "merite", "prime", "pct"} (pct de l'enveloppe, 0–100).

    `presents` : éligibles présents sur le mois (au moins un jour de présence
    effective) ; eux seuls reçoivent le plancher. Si aucun score n'est positif,
    le reste est partagé à parts égales entre les présents."""
    enveloppe = en_decimal(enveloppe).quantize(CENTIME)
    s = {e: max(Decimal(0), en_decimal(v)) for e, v in scores_.items()}
    presents = [e for e in s if e in set(presents)]
    taux_plancher = en_decimal(taux_plancher)
    if enveloppe <= 0 or not s:
        return {e: {"plancher": Decimal(0), "merite": Decimal(0), "prime": Decimal(0), "pct": Decimal(0)} for e in s}

    plancher = enveloppe / len(presents) * taux_plancher if presents else Decimal(0)
    reste = enveloppe - plancher * len(presents)
    total = sum(s.values(), Decimal(0))
    if total > 0:
        merite = {e: v / total * reste for e, v in s.items()}
    else:
        merite = {e: (reste / len(presents) if e in presents else Decimal(0)) for e in s} if presents else \
            {e: reste / len(s) for e in s}
    brut = {e: (plancher if e in presents else Decimal(0)) + merite[e] for e in s}
    primes = _au_centime(brut, enveloppe)
    return {e: {"plancher": (plancher if e in presents else Decimal(0)).quantize(CENTIME),
                "merite": (primes[e] - (plancher if e in presents else Decimal(0)).quantize(CENTIME)),
                "prime": primes[e],
                "pct": (primes[e] / enveloppe * 100).quantize(Decimal("0.0001"))}
            for e in s}
