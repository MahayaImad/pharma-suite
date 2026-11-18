"""Part fixe du salaire (brut) d'un employé sur un mois — logique pure, en Decimal.

Règle 7 (arbitrage du 2026-08-19) et arbitrages du 2026-11-18 :

    part_fixe = salaire_base × jours sous contrat ÷ jours du mois    (prorata)
              + ancienneté × jours sous contrat ÷ jours du mois     (prorata)
              + transport × jours de présence effective
              + panier    × jours de présence effective
              + heures supplémentaires × taux horaire × majoration
              − salaire_base ÷ 30 × jours d'absence injustifiée

- **Ancienneté** : 1 000 DA par année révolue au dernier jour du mois (ou au
  départ), plafond 15 000 DA (règle 1).
- **Présence effective** : présent ou en retard, sur les jours sous contrat.
  Congé, maladie et férié n'ouvrent droit ni au transport ni au panier. Un
  jour « à confirmer » (poste qui ne vend pas, présence non saisie) non plus,
  tant que le titulaire ne l'a pas corrigé : il est signalé.
- **Retard** : aucune retenue en argent (il coûte un point de ponctualité).
- **Heures supplémentaires** : saisies à la main, arrondies au quart d'heure ;
  taux horaire = salaire de base ÷ heures mensuelles (173,33 h : 40 h × 52 ÷ 12).
- **Absence injustifiée** : retenue de 1/30ᵉ du salaire de base par jour
  (règle 5), sur le seul salaire de base.
- **Brut seulement** : cotisations CNAS et IRG restent au comptable.

Chaque ligne est arrondie au centime (ROUND_HALF_UP) ; le total est la somme
des lignes arrondies, pour que le bulletin tombe juste à la main.
"""
from __future__ import annotations

import calendar
from dataclasses import dataclass, field
from datetime import date
from decimal import ROUND_HALF_UP, Decimal
from typing import Iterable, Optional

from app.services.paie.repartition import en_decimal

CENTIME = Decimal("0.01")
QUART = Decimal("0.25")


@dataclass(frozen=True)
class Regles:
    transport_jour: Decimal = Decimal(300)
    panier_jour: Decimal = Decimal(600)
    anciennete_an: Decimal = Decimal(1000)
    anciennete_plafond: Decimal = Decimal(15000)
    majoration_hs: Decimal = Decimal("1.5")
    heures_mois: Decimal = Decimal("173.33")


@dataclass
class PartFixe:
    jours_mois: int
    jours_contrat: int
    presence_effective: int
    a_confirmer: int
    absences: int
    annees_anciennete: int
    heures_sup: Decimal
    lignes: dict[str, Decimal] = field(default_factory=dict)

    @property
    def total(self) -> Decimal:
        return sum(self.lignes.values(), Decimal(0))


def _centime(x: Decimal) -> Decimal:
    return x.quantize(CENTIME, rounding=ROUND_HALF_UP)


def arrondi_quart_heure(heures) -> Decimal:
    """1,1 h → 1 h ; 1,13 h → 1,25 h (au quart d'heure le plus proche)."""
    return (en_decimal(heures) / QUART).quantize(Decimal(1), rounding=ROUND_HALF_UP) * QUART


def annees_revolues(entree: Optional[date], au: date) -> int:
    if entree is None or entree > au:
        return 0
    return au.year - entree.year - ((au.month, au.day) < (entree.month, entree.day))


def calculer(annee: int, mois: int, salaire_base, jours: Iterable[tuple[date, str]],
             date_entree: Optional[date] = None, date_sortie: Optional[date] = None,
             heures_sup=0, regles: Regles = Regles()) -> PartFixe:
    """`jours` : (date, statut) de chaque jour du mois, d'après la grille de
    présence. Seuls les jours sous contrat (entre l'entrée et la sortie)
    comptent : un jour « absent » avant l'arrivée n'est pas une absence."""
    nb = calendar.monthrange(annee, mois)[1]
    debut, fin = date(annee, mois, 1), date(annee, mois, nb)
    du = max(debut, date_entree) if date_entree else debut
    au = min(fin, date_sortie) if date_sortie else fin
    contrat = max(0, (au - du).days + 1) if du <= au else 0
    statuts = [s for j, s in jours if du <= j <= au]
    presence = statuts.count("present") + statuts.count("retard")
    absences = statuts.count("absent")
    base = en_decimal(salaire_base)
    prorata = Decimal(contrat) / Decimal(nb)
    annees = annees_revolues(date_entree, au) if contrat else 0
    hs = arrondi_quart_heure(heures_sup)

    p = PartFixe(nb, contrat, presence, statuts.count("a_confirmer"), absences, annees, hs)
    p.lignes = {
        "salaire_base": _centime(base * prorata),
        "anciennete": _centime(min(regles.anciennete_an * annees, regles.anciennete_plafond) * prorata),
        "transport": _centime(regles.transport_jour * presence),
        "panier": _centime(regles.panier_jour * presence),
        "heures_sup": _centime(base / regles.heures_mois * regles.majoration_hs * hs) if regles.heures_mois else
        Decimal(0),
        "retenue_absences": -_centime(base / 30 * absences),
    }
    return p
