"""
Outillage commun aux tests de paie.

Ces tests ne se connectent à aucune base : `FakeSession` rejoue des réponses
scriptées. L'objectif est de verrouiller l'arithmétique monétaire, qui doit
rester vérifiable sans docker ni postgres.
"""
from __future__ import annotations

from decimal import Decimal
from typing import Optional, Sequence

import pytest
from sqlalchemy.sql.elements import TextClause

from app.models.performance import PrimeTauxConfig


class _FakeResult:
    """Imite le Result de SQLAlchemy, pour les deux usages du module paie."""

    def __init__(self, rows: Sequence = (), scalar_value=None):
        self._rows = list(rows)
        self._scalar = scalar_value

    def scalars(self):
        return self

    def all(self):
        return list(self._rows)

    def scalar(self):
        return self._scalar

    def __iter__(self):
        # `for row in await db.execute(select(...))` → lignes façon tuple
        return iter([(r,) for r in self._rows])


class FakeSession:
    """
    Session factice.

    - un `select(...)` ORM renvoie les configs de taux ;
    - chaque `text(...)` renvoie le CA suivant de `ca_par_categorie`, dans
      l'ordre des configs.

    Les requêtes SQL réellement émises sont conservées dans `sql_executes`
    pour pouvoir vérifier le paramétrage.
    """

    def __init__(self, configs: Sequence[PrimeTauxConfig], ca_par_categorie: Sequence[Decimal]):
        self.configs = list(configs)
        self._ca = list(ca_par_categorie)
        self._ca_index = 0
        self.sql_executes: list[tuple[str, dict]] = []

    async def execute(self, statement, params: Optional[dict] = None):
        if isinstance(statement, TextClause):
            self.sql_executes.append((str(statement), dict(params or {})))
            valeur = self._ca[self._ca_index] if self._ca_index < len(self._ca) else Decimal(0)
            self._ca_index += 1
            return _FakeResult(scalar_value=valeur)
        return _FakeResult(rows=self.configs)


def config(nom: str, taux: str, filtre: Optional[str] = None) -> PrimeTauxConfig:
    """Raccourci de construction d'une ligne prime_taux_config."""
    return PrimeTauxConfig(nom=nom, taux_pct=Decimal(taux), filtre_famille=filtre, actif=True)


@pytest.fixture
def configs_officine() -> list[PrimeTauxConfig]:
    """Les trois catégories seedées par la migration 038."""
    return [
        config("Princeps", "0.500", "gentype:princeps"),
        config("Générique", "1.000", "gentype:generique"),
        config("Générique++", "3.000", "gentype:generique_remb"),
    ]
