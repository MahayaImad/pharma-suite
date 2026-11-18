"""Accès base de la paie. Seul endroit qui écrit dans ses tables."""
from __future__ import annotations

import json
from datetime import date
from decimal import Decimal
from typing import Any, Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.paie.part_fixe import Regles


class PaieRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def commit(self) -> None:
        await self.db.commit()

    async def regles(self) -> Regles:
        v = {r.cle: Decimal(r.valeur) for r in await self.db.execute(text(
            "SELECT cle, valeur FROM reglages_stock WHERE cle LIKE 'paie\\_%'"))}
        d = Regles()
        return Regles(transport_jour=v.get("paie_transport_jour", d.transport_jour),
                      panier_jour=v.get("paie_panier_jour", d.panier_jour),
                      anciennete_an=v.get("paie_anciennete_an", d.anciennete_an),
                      anciennete_plafond=v.get("paie_anciennete_plafond", d.anciennete_plafond),
                      majoration_hs=v.get("paie_majoration_hs", d.majoration_hs),
                      heures_mois=v.get("paie_heures_mois", d.heures_mois))

    async def postes(self) -> list[dict]:
        r = await self.db.execute(text(
            "SELECT code, libelle, salaire_base, vend_au_comptoir FROM postes_travail ORDER BY ordre, libelle"))
        return [dict(x._mapping) for x in r]

    async def employes(self) -> dict[int, dict]:
        r = await self.db.execute(text("""
            SELECT e.id, e.username, e.nom, e.prenom, e.poste, e.poste_code, e.date_entree, e.date_sortie,
                   e.heure_debut, pt.libelle AS poste_libelle, pt.salaire_base
            FROM employes e LEFT JOIN postes_travail pt ON pt.code = e.poste_code
            WHERE e.actif AND e.eligible_prime
        """))
        return {x.id: dict(x._mapping) for x in r}

    async def employe(self, id_: int) -> Optional[dict]:
        r = (await self.db.execute(text("SELECT id FROM employes WHERE id = :i"), {"i": id_})).first()
        return dict(r._mapping) if r else None

    async def poste_existe(self, code: str) -> bool:
        return bool((await self.db.execute(text("SELECT 1 FROM postes_travail WHERE code = :c"), {"c": code})).scalar())

    async def modifier_employe(self, id_: int, valeurs: dict[str, Any]) -> None:
        colonnes = {k: v for k, v in valeurs.items()
                    if k in ("poste_code", "date_entree", "date_sortie", "heure_debut", "eligible_prime")}
        if not colonnes:
            return
        # Noms de colonnes tirés d'une liste fermée ; les valeurs restent des paramètres liés.
        ensemble = ", ".join(f"{k} = :{k}" for k in colonnes)
        await self.db.execute(text(f"UPDATE employes SET {ensemble} WHERE id = :id"), {**colonnes, "id": id_})

    async def heures_sup(self, annee: int, mois: int) -> dict[int, dict]:
        r = await self.db.execute(text("""
            SELECT employe_id, heures, note, saisi_par, saisi_le FROM paie_heures_sup WHERE annee = :a AND mois = :m
        """), {"a": annee, "m": mois})
        return {x.employe_id: dict(x._mapping) for x in r}

    async def saisir_heures_sup(self, employe_id: int, annee: int, mois: int, heures: Decimal,
                                note: Optional[str], qui: str) -> None:
        if heures == 0:
            await self.db.execute(text(
                "DELETE FROM paie_heures_sup WHERE employe_id = :e AND annee = :a AND mois = :m"),
                {"e": employe_id, "a": annee, "m": mois})
            return
        await self.db.execute(text("""
            INSERT INTO paie_heures_sup (employe_id, annee, mois, heures, note, saisi_par)
            VALUES (:e, :a, :m, :h, :n, :qui)
            ON CONFLICT (employe_id, annee, mois) DO UPDATE SET heures = :h, note = :n, saisi_par = :qui,
                saisi_le = now()
        """), {"e": employe_id, "a": annee, "m": mois, "h": heures, "n": note, "qui": qui})

    async def parts_variables(self, annee: int, mois: int) -> dict[int, dict]:
        r = await self.db.execute(text("""
            SELECT employe_id, prime_calculee, valide FROM performance_mensuelle WHERE annee = :a AND mois = :m
        """), {"a": annee, "m": mois})
        return {x.employe_id: dict(x._mapping) for x in r}

    async def derniers_bulletins(self, annee: int, mois: int) -> dict[int, dict]:
        r = await self.db.execute(text("""
            SELECT DISTINCT ON (employe_id) employe_id, version, brut, valide_le, valide_par
            FROM paie_bulletins WHERE annee = :a AND mois = :m ORDER BY employe_id, version DESC
        """), {"a": annee, "m": mois})
        return {x.employe_id: dict(x._mapping) for x in r}

    async def enregistrer_bulletin(self, employe_id: int, annee: int, mois: int, detail: dict,
                                   part_fixe: Decimal, part_variable: Decimal, brut: Decimal, qui: str) -> int:
        """Ajoute une version : une validation n'écrase jamais la précédente."""
        return (await self.db.execute(text("""
            INSERT INTO paie_bulletins (employe_id, annee, mois, version, detail, part_fixe, part_variable, brut,
                                        valide_par)
            SELECT :e, :a, :m, COALESCE(max(version), 0) + 1, CAST(:d AS jsonb), :pf, :pv, :b, :qui
            FROM paie_bulletins WHERE employe_id = :e AND annee = :a AND mois = :m
            RETURNING version
        """), {"e": employe_id, "a": annee, "m": mois, "d": json.dumps(detail, default=str), "pf": part_fixe,
               "pv": part_variable, "b": brut, "qui": qui})).scalar()

    async def bulletins(self, employe_id: int, annee: int, mois: int) -> list[dict]:
        r = await self.db.execute(text("""
            SELECT version, detail, part_fixe, part_variable, brut, valide_le, valide_par FROM paie_bulletins
            WHERE employe_id = :e AND annee = :a AND mois = :m ORDER BY version DESC
        """), {"e": employe_id, "a": annee, "m": mois})
        return [dict(x._mapping) for x in r]

    async def dernier_calcul_primes(self, annee: int, mois: int) -> dict[int, dict]:
        """Lignes du dernier calcul de primes du mois : plancher, mérite, KPIs (poids, valeur retenue)."""
        r = await self.db.execute(text("""
            SELECT l.employe_id, l.plancher, l.merite, l.prime, l.kpis, c.calcule_le, c.enveloppe
            FROM primes_calculs_lignes l
            JOIN primes_calculs c ON c.id = l.id_calcul
            WHERE c.id = (SELECT max(id) FROM primes_calculs WHERE annee = :a AND mois = :m)
        """), {"a": annee, "m": mois})
        return {x.employe_id: dict(x._mapping) for x in r}

    async def kpis(self) -> dict[str, dict]:
        r = await self.db.execute(text("SELECT code, libelle, unite FROM kpi_definitions"))
        return {x.code: {"libelle": x.libelle, "unite": x.unite} for x in r}

    async def importer_depuis_easypharm(self, exclus: set[str]) -> int:
        """Crée ou met à jour une fiche par utilisateur d'EASYPHARM (`groupware`).
        Une fiche existante garde son poste, ses dates et son choix « dans la
        paie » ; seuls le nom et l'état actif suivent EASYPHARM. Les comptes
        non nominatifs (`exclus`) sont créés hors de la paie."""
        r = await self.db.execute(text("""
            INSERT INTO employes (username, nom, prenom, actif, eligible_prime)
            SELECT g.utilisateur, COALESCE(NULLIF(trim(g.nom), ''), g.utilisateur), NULLIF(trim(g.prenom), ''),
                   COALESCE(g.actif, 1) = 1, NOT (g.utilisateur = ANY(:exclus))
            FROM groupware g WHERE NULLIF(trim(g.utilisateur), '') IS NOT NULL
            ON CONFLICT (username) DO UPDATE SET nom = EXCLUDED.nom, prenom = EXCLUDED.prenom, actif = EXCLUDED.actif
        """), {"exclus": sorted(exclus)})
        return r.rowcount or 0

