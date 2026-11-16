"""Lectures propres aux alertes (le reste vient du Stock et des Commandes)."""
from __future__ import annotations

from datetime import date
from decimal import Decimal

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


class AlertesRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def peremption(self, jour: date) -> dict:
        """Lots en stock qui périment : déjà périmés, d'ici la fin du mois,
        d'ici 3 mois (un lot daté MM/YY est bon jusqu'à la fin de ce mois)."""
        r = (await self.db.execute(text("""
            WITH lots AS (
                SELECT ep.stock * COALESCE(ep.prix_achat, 0) AS valeur,
                       CAST(date_trunc('month', ep.peremption_date) + interval '1 month' AS date) AS fin
                FROM entrees_produits ep JOIN nomenclature n ON n.id = ep.id_nom
                WHERE ep.stock > 0 AND ep.peremption_date IS NOT NULL AND n.archive = false
            ), bornes AS (
                SELECT CAST(:jour AS date) AS jour,
                       CAST(date_trunc('month', CAST(:jour AS date)) + interval '1 month' AS date) AS fin_mois
            )
            SELECT count(*) FILTER (WHERE l.fin <= b.jour) AS perimes,
                   COALESCE(sum(l.valeur) FILTER (WHERE l.fin <= b.jour), 0) AS valeur_perimes,
                   count(*) FILTER (WHERE l.fin > b.jour AND l.fin <= b.fin_mois) AS ce_mois,
                   COALESCE(sum(l.valeur) FILTER (WHERE l.fin > b.jour AND l.fin <= b.fin_mois), 0) AS valeur_ce_mois,
                   count(*) FILTER (WHERE l.fin > b.fin_mois AND l.fin <= b.jour + 92) AS trois_mois,
                   COALESCE(sum(l.valeur) FILTER (WHERE l.fin > b.fin_mois AND l.fin <= b.jour + 92), 0)
                       AS valeur_trois_mois
            FROM lots l CROSS JOIN bornes b
        """), {"jour": jour})).one()
        return {k: (Decimal(v) if isinstance(v, Decimal) else int(v)) for k, v in r._mapping.items()}

    async def a_confirmer(self) -> dict[str, int]:
        """Propositions en attente d'une décision du titulaire."""
        r = (await self.db.execute(text("""
            SELECT (SELECT count(*) FROM produits_consommables WHERE NOT confirme) AS consommables,
                   (SELECT count(*) FROM gardes WHERE NOT confirme AND NOT annulee) AS gardes
        """))).one()
        return {"consommables": int(r.consommables), "gardes": int(r.gardes)}
