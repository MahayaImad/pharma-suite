"""Accès base du calendrier. Seul endroit qui écrit dans ces tables."""
from __future__ import annotations

from datetime import date
from typing import Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


class CalendrierRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    # ── Gardes ──
    async def gardes(self, debut: date, fin: date) -> list[dict]:
        r = await self.db.execute(text("""
            SELECT date, type, source, confirme, note, modifie_le, modifie_par
            FROM gardes WHERE date BETWEEN :debut AND :fin AND NOT annulee ORDER BY date DESC
        """), {"debut": debut, "fin": fin})
        return [dict(x._mapping) for x in r]

    async def enregistrer_garde(self, jour: date, type_: str, note: Optional[str], qui: str) -> dict:
        """Crée ou corrige une garde ; une garde corrigée ou confirmée par
        l'officine devient confirmée (la source d'origine est gardée)."""
        r = await self.db.execute(text("""
            INSERT INTO gardes (date, type, source, confirme, note, modifie_le, modifie_par)
            VALUES (:d, :t, 'saisie', true, :n, now(), :qui)
            ON CONFLICT (date) DO UPDATE SET type = :t, note = :n, confirme = true, annulee = false,
                modifie_le = now(), modifie_par = :qui
            RETURNING date, type, source, confirme, note, modifie_le, modifie_par
        """), {"d": jour, "t": type_, "n": note, "qui": qui})
        ligne = dict(r.one()._mapping)
        await self.db.commit()
        return ligne

    async def toutes_les_gardes(self) -> list[dict]:
        r = await self.db.execute(text("SELECT date, type, source, annulee FROM gardes ORDER BY date"))
        return [dict(x._mapping) for x in r]

    async def ajouter_propositions(self, propositions: list, qui: str) -> list[dict]:
        """Enregistre des gardes proposées, non confirmées ; un jour déjà
        pris n'est pas touché."""
        lignes = []
        for p in propositions:
            r = await self.db.execute(text("""
                INSERT INTO gardes (date, type, source, confirme, note, modifie_le, modifie_par)
                VALUES (:d, :t, 'prevision', false, :n, now(), :qui)
                ON CONFLICT (date) DO NOTHING
                RETURNING date, type, source, confirme, note, modifie_le, modifie_par
            """), {"d": p.date, "t": p.type, "n": p.note, "qui": qui})
            ligne = r.one_or_none()
            if ligne:
                lignes.append(dict(ligne._mapping))
        await self.db.commit()
        return lignes

    async def annuler_garde(self, jour: date, qui: str) -> bool:
        """Marque annulée une garde non confirmée (détectée ou proposée)."""
        r = await self.db.execute(text("""
            UPDATE gardes SET annulee = true, modifie_le = now(), modifie_par = :qui
            WHERE date = :d AND NOT confirme AND NOT annulee
        """), {"d": jour, "qui": qui})
        await self.db.commit()
        return r.rowcount > 0

    async def supprimer_garde(self, jour: date) -> bool:
        r = await self.db.execute(text("DELETE FROM gardes WHERE date = :d"), {"d": jour})
        await self.db.commit()
        return r.rowcount > 0

    # ── Fêtes à date mobile ──
    async def evenements(self) -> list[dict]:
        r = await self.db.execute(text("""
            SELECT id, type, date_debut, date_fin, a_verifier, modifie_le, modifie_par
            FROM evenements_calendrier ORDER BY date_debut DESC
        """))
        return [dict(x._mapping) for x in r]

    async def creer_evenement(self, type_: str, debut: date, fin: date, qui: str) -> dict:
        r = await self.db.execute(text("""
            INSERT INTO evenements_calendrier (type, date_debut, date_fin, a_verifier, modifie_par)
            VALUES (:t, :d, :f, false, :qui)
            RETURNING id, type, date_debut, date_fin, a_verifier, modifie_le, modifie_par
        """), {"t": type_, "d": debut, "f": fin, "qui": qui})
        ligne = dict(r.one()._mapping)
        await self.db.commit()
        return ligne

    async def modifier_evenement(self, id_: int, type_: str, debut: date, fin: date, qui: str) -> Optional[dict]:
        r = await self.db.execute(text("""
            UPDATE evenements_calendrier
            SET type = :t, date_debut = :d, date_fin = :f, a_verifier = false,
                modifie_le = now(), modifie_par = :qui
            WHERE id = :id
            RETURNING id, type, date_debut, date_fin, a_verifier, modifie_le, modifie_par
        """), {"id": id_, "t": type_, "d": debut, "f": fin, "qui": qui})
        ligne = r.one_or_none()
        await self.db.commit()
        return dict(ligne._mapping) if ligne else None

    async def supprimer_evenement(self, id_: int) -> bool:
        r = await self.db.execute(text("DELETE FROM evenements_calendrier WHERE id = :id"), {"id": id_})
        await self.db.commit()
        return r.rowcount > 0

    async def evenement_existe(self, type_: str, debut: date, sauf: Optional[int] = None) -> bool:
        r = await self.db.execute(text(
            "SELECT 1 FROM evenements_calendrier WHERE type = :t AND date_debut = :d AND id <> COALESCE(:sauf, -1)"),
            {"t": type_, "d": debut, "sauf": sauf})
        return r.first() is not None

    # ── Jours fériés à date fixe (table holidays, lue aussi par tasks) ──
    async def feries(self) -> list[dict]:
        r = await self.db.execute(text("SELECT id, date, label FROM holidays ORDER BY date DESC"))
        return [dict(x._mapping) for x in r]

    async def ferie_existe(self, jour: date) -> bool:
        return (await self.db.execute(text("SELECT 1 FROM holidays WHERE date = :d"), {"d": jour})).first() is not None

    async def creer_ferie(self, jour: date, label: str) -> dict:
        r = await self.db.execute(text(
            "INSERT INTO holidays (date, label) VALUES (:d, :l) RETURNING id, date, label"), {"d": jour, "l": label})
        ligne = dict(r.one()._mapping)
        await self.db.commit()
        return ligne

    async def supprimer_ferie(self, id_: int) -> bool:
        r = await self.db.execute(text("DELETE FROM holidays WHERE id = :id"), {"id": id_})
        await self.db.commit()
        return r.rowcount > 0
