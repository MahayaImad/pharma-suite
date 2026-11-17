"""Accès base de l'inventaire. Seul endroit qui écrit dans ses tables."""
from __future__ import annotations

import uuid
from datetime import date
from decimal import Decimal
from typing import Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.inventaire.selection import Candidat

_PRIX = """COALESCE(NULLIF(mv.valeur_achat / NULLIF(mv.stock_actuel, 0), 0),
                    (SELECT ep.prix_achat FROM entrees_produits ep WHERE ep.id_nom = n.id AND ep.prix_achat > 0
                     ORDER BY ep.date_entree DESC NULLS LAST, ep.id DESC LIMIT 1), 0)"""


class InventaireRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def commit(self) -> None:
        await self.db.commit()

    async def reglages(self) -> dict[str, int]:
        r = await self.db.execute(text("SELECT cle, valeur FROM reglages_stock WHERE cle LIKE 'inventaire\\_%'"))
        v = {x.cle: int(x.valeur) for x in r}
        return {"par_jour": v.get("inventaire_par_jour", 20), "A": v.get("inventaire_jours_a", 30),
                "B": v.get("inventaire_jours_b", 90), "C": v.get("inventaire_jours_c", 180)}

    async def candidats(self) -> list[Candidat]:
        """Produits actifs, non archivés, hors consommables et psychotropes
        (registre à part), avec leur dernier comptage."""
        r = await self.db.execute(text("""
            SELECT n.id, n.segment_abc, COALESCE(mv.stock_actuel, 0) AS stock,
                   COALESCE(mv.valeur_achat, 0) AS valeur, mv.derniere_vente,
                   (SELECT max(c.jour) FROM inventaire_comptages c WHERE c.id_nom = n.id) AS dernier
            FROM nomenclature n JOIN mv_stock_produits mv ON mv.id_nom = n.id
            WHERE n.archive = false AND mv.actif AND COALESCE(n.psychotrope, 0) <> 1
              AND NOT EXISTS (SELECT 1 FROM produits_consommables pc
                              WHERE pc.id_nom = n.id AND pc.consommable AND pc.confirme)
        """))
        return [Candidat(x.id, x.segment_abc, int(x.stock), float(x.valeur), x.derniere_vente, x.dernier) for x in r]

    async def liste_existe(self, jour: date) -> bool:
        return bool((await self.db.execute(text(
            "SELECT 1 FROM inventaire_liste WHERE jour = :j LIMIT 1"), {"j": jour})).scalar())

    async def ecrire_liste(self, jour: date, produits: list[tuple[int, str]]) -> None:
        for rang, (id_nom, raison) in enumerate(produits):
            await self.db.execute(text("""
                INSERT INTO inventaire_liste (jour, id_nom, rang, raison) VALUES (:j, :p, :r, :m)
                ON CONFLICT DO NOTHING
            """), {"j": jour, "p": id_nom, "r": rang, "m": raison})

    async def liste(self, jour: date) -> list[dict]:
        r = await self.db.execute(text("""
            SELECT l.id_nom, n.nom, n.segment_abc AS classe, l.raison,
                   COALESCE(mv.stock_actuel, 0) AS stock_theorique,
                   (SELECT max(c.jour) FROM inventaire_comptages c WHERE c.id_nom = l.id_nom AND c.jour < :j)
                       AS dernier_comptage
            FROM inventaire_liste l JOIN nomenclature n ON n.id = l.id_nom
            LEFT JOIN mv_stock_produits mv ON mv.id_nom = l.id_nom
            WHERE l.jour = :j ORDER BY l.rang
        """), {"j": jour})
        return [dict(x._mapping) for x in r]

    async def produit(self, id_nom: int) -> Optional[dict]:
        r = (await self.db.execute(text(f"""
            SELECT n.id, n.nom, COALESCE(mv.stock_actuel, 0) AS stock, {_PRIX} AS prix
            FROM nomenclature n LEFT JOIN mv_stock_produits mv ON mv.id_nom = n.id WHERE n.id = :p
        """), {"p": id_nom})).first()
        return dict(r._mapping) if r else None

    _COLONNES = """c.id, c.jour, c.id_nom, n.nom, n.segment_abc AS classe, c.stock_theorique, c.stock_compte,
                   c.ecart, c.valeur_ecart, c.cause, c.compte_par, c.compte_le, c.corrige, c.corrige_par,
                   EXISTS (SELECT 1 FROM inventaire_liste l WHERE l.jour = c.jour AND l.id_nom = c.id_nom)
                       AS dans_la_liste"""

    async def comptages_du_jour(self, jour: date) -> list[dict]:
        r = await self.db.execute(text(f"""
            SELECT {self._COLONNES} FROM inventaire_comptages c JOIN nomenclature n ON n.id = c.id_nom
            WHERE c.jour = :j ORDER BY c.compte_le DESC
        """), {"j": jour})
        return [dict(x._mapping) for x in r]

    async def a_corriger(self) -> list[dict]:
        """Écarts pas encore reportés dans EASYPHARM, les plus chers d'abord."""
        r = await self.db.execute(text(f"""
            SELECT {self._COLONNES} FROM inventaire_comptages c JOIN nomenclature n ON n.id = c.id_nom
            WHERE c.ecart <> 0 AND NOT c.corrige ORDER BY abs(c.valeur_ecart) DESC, c.jour DESC
        """))
        return [dict(x._mapping) for x in r]

    async def comptage(self, id_: int) -> Optional[dict]:
        r = (await self.db.execute(text(f"""
            SELECT {self._COLONNES} FROM inventaire_comptages c JOIN nomenclature n ON n.id = c.id_nom
            WHERE c.id = :i
        """), {"i": id_})).first()
        return dict(r._mapping) if r else None

    async def enregistrer(self, jour: date, id_nom: int, theorique: int, compte: int, valeur: Decimal,
                          cause: Optional[str], qui: str, client_uuid: Optional[uuid.UUID]) -> int:
        """Un comptage par produit et par jour : recompter remplace."""
        return (await self.db.execute(text("""
            INSERT INTO inventaire_comptages (client_uuid, jour, id_nom, stock_theorique, stock_compte, ecart,
                                              valeur_ecart, cause, compte_par)
            VALUES (:u, :j, :p, :t, :c, :e, :v, :cause, :qui)
            ON CONFLICT (id_nom, jour) DO UPDATE SET stock_theorique = :t, stock_compte = :c, ecart = :e,
                valeur_ecart = :v, cause = :cause, compte_par = :qui, compte_le = now(),
                corrige = false, corrige_le = NULL, corrige_par = NULL
            RETURNING id
        """), {"u": client_uuid or uuid.uuid4(), "j": jour, "p": id_nom, "t": theorique, "c": compte,
               "e": compte - theorique, "v": valeur, "cause": cause, "qui": qui})).scalar()

    async def par_uuid(self, client_uuid: uuid.UUID) -> Optional[int]:
        return (await self.db.execute(text(
            "SELECT id FROM inventaire_comptages WHERE client_uuid = :u"), {"u": client_uuid})).scalar()

    async def supprimer(self, id_: int) -> None:
        await self.db.execute(text("DELETE FROM inventaire_comptages WHERE id = :i"), {"i": id_})

    async def marquer_corrige(self, id_: int, corrige: bool, qui: str) -> None:
        await self.db.execute(text("""
            UPDATE inventaire_comptages SET corrige = :c, corrige_le = CASE WHEN :c THEN now() END,
                   corrige_par = CASE WHEN :c THEN :qui END WHERE id = :i
        """), {"c": corrige, "qui": qui, "i": id_})

    async def exactitude(self, jour: date, jours_a: int) -> dict:
        """Sur le mois : produits comptés et part sans écart ; part de la
        classe A en stock comptée dans sa fréquence."""
        r = (await self.db.execute(text("""
            SELECT (SELECT count(*) FROM inventaire_comptages
                    WHERE jour BETWEEN CAST(date_trunc('month', CAST(:j AS date)) AS date) AND CAST(:j AS date)) AS comptes,
                   (SELECT count(*) FROM inventaire_comptages
                    WHERE jour BETWEEN CAST(date_trunc('month', CAST(:j AS date)) AS date) AND CAST(:j AS date) AND ecart = 0) AS justes,
                   (SELECT count(*) FROM nomenclature n JOIN mv_stock_produits mv ON mv.id_nom = n.id
                    WHERE n.archive = false AND mv.actif AND n.segment_abc = 'A' AND mv.stock_actuel > 0) AS classe_a,
                   (SELECT count(DISTINCT c.id_nom) FROM inventaire_comptages c
                    JOIN nomenclature n ON n.id = c.id_nom JOIN mv_stock_produits mv ON mv.id_nom = n.id
                    WHERE n.archive = false AND mv.actif AND n.segment_abc = 'A' AND mv.stock_actuel > 0
                      AND c.jour > CAST(:j AS date) - CAST(:ja AS integer)) AS classe_a_comptee
        """), {"j": jour, "ja": jours_a})).one()
        return {"comptes_mois": int(r.comptes),
                "exactitude_pct": round(100 * r.justes / r.comptes) if r.comptes else None,
                "classe_a_pct": round(100 * r.classe_a_comptee / r.classe_a) if r.classe_a else None}
