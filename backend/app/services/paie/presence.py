"""Bilan de présence d'un employé sur un mois, pour la paie — logique pure.

Entrée : le statut de chaque jour, tel que le calcule la grille de présence
(`app/api/v1/grh_presence.py`) : present, retard, absent, conge, maladie,
ferie, weekend, a_confirmer.

« a_confirmer » : jour sans vente d'un employé dont le poste ne vend pas au
comptoir (préparateur). Sa présence ne se déduit pas des ventes ; tant que le
titulaire ne l'a pas corrigé, le jour compte comme présent à l'heure pour la
part variable (bénéfice du doute), et il est signalé.

Ce que la paie en tire (règles arbitrées du 2026-08-19, CLAUDE.md partie 4) :

- **présence effective** = present + retard : seuls ces jours ouvrent droit
  au transport et au panier ;
- **jours travaillés pour la part variable** = présence effective + congé +
  maladie + férié : un congé ne doit pas faire baisser la prime ;
- **absence injustifiée** = absent : retenue de 1/30ᵉ du salaire de base ;
- **à l'heure** = present (un retard au-delà de 45 minutes coûte un point
  de ponctualité, jamais d'argent — arbitrage du 2026-11-18) ;
- **présent sur le mois** = au moins un jour de présence effective : seuls
  ceux-là reçoivent le plancher de la part variable.
"""
from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal
from typing import Iterable

from app.services.paie.repartition import en_decimal

TRAVAILLES_VARIABLE = {"present", "retard", "conge", "maladie", "ferie", "a_confirmer"}


@dataclass(frozen=True)
class Bilan:
    presence_effective: int     # present + retard
    a_l_heure: int              # present
    retards: int
    absences: int               # absences injustifiées
    conges: int
    maladie: int
    feries: int
    travailles_variable: int    # présence effective + congé + maladie + férié
    a_confirmer: int = 0        # jours sans vente d'un poste qui ne vend pas, comptés présents

    @property
    def present_sur_le_mois(self) -> bool:
        return self.presence_effective > 0


def bilan(statuts: Iterable[str]) -> Bilan:
    s = list(statuts)
    n = s.count
    return Bilan(presence_effective=n("present") + n("retard") + n("a_confirmer"),
                 a_l_heure=n("present") + n("a_confirmer"), retards=n("retard"),
                 absences=n("absent"), conges=n("conge"), maladie=n("maladie"), feries=n("ferie"),
                 travailles_variable=sum(1 for x in s if x in TRAVAILLES_VARIABLE), a_confirmer=n("a_confirmer"))


def ramener_aux_jours(valeur, b: Bilan) -> Decimal:
    """KPI de volume ramené aux jours de présence, puis étendu aux jours
    comptés comme travaillés : valeur ÷ présence effective × jours travaillés.

    Un employé en congé dix jours n'est pas pénalisé de ses dix jours ; un
    employé jamais présent garde 0."""
    if b.presence_effective <= 0:
        return Decimal(0)
    return en_decimal(valeur) / b.presence_effective * b.travailles_variable
