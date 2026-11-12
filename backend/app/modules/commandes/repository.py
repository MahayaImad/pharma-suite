"""Accès base des commandes. Seul endroit qui écrit dans ces tables."""
from __future__ import annotations

import json
import uuid
from datetime import date
from decimal import Decimal
from typing import Any, Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

_EXCLUS_ACHAT = "COALESCE(ep.type_entree, '') <> 'AV' AND COALESCE(ep.type_achat, '') <> 'E'"


class CommandesRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def commit(self) -> None:
        await self.db.commit()

    # ── Lecture des données du calcul ──
    async def donnees_du(self):
        return (await self.db.execute(text(
            "SELECT last_sync_at FROM sync_status WHERE table_name = 'mv_stock_produits'"))).scalar()

    async def produits(self, ids: list[int]) -> dict[int, dict]:
        """Nom, stock, psychotrope et fournisseur principal (dernier achat hors
        avoirs et échanges) avec son dernier prix d'achat."""
        r = await self.db.execute(text(f"""
            SELECT n.id, n.nom, COALESCE(f.famille, n.famille) AS famille, n.segment_abc,
                   COALESCE(n.psychotrope, 0) = 1 AS psychotrope,
                   COALESCE(mv.stock_actuel, 0) AS stock,
                   der.id_fournisseur, der.prix_achat
            FROM nomenclature n
            JOIN mv_stock_produits mv ON mv.id_nom = n.id
            LEFT JOIN familles f ON f.id = n.id_famille
            LEFT JOIN LATERAL (
                SELECT ep.id_fournisseur, ep.prix_achat FROM entrees_produits ep
                WHERE ep.id_nom = n.id AND {_EXCLUS_ACHAT} AND COALESCE(ep.prix_achat, 0) > 0
                ORDER BY ep.date_entree DESC NULLS LAST, ep.id DESC LIMIT 1
            ) der ON true
            WHERE n.id = ANY(:ids)
        """), {"ids": ids})
        return {x.id: dict(x._mapping) for x in r}

    async def fournisseurs(self) -> dict[int, dict]:
        """Fournisseurs connus, avec leur réglage de commande s'il existe."""
        r = await self.db.execute(text("""
            SELECT f.id, f.fournisseur AS nom, f.telephone, f.mobile, f.delai_livraison,
                   COALESCE(fc.type, 'pharma') AS type, COALESCE(fc.actif, false) AS actif,
                   fc.whatsapp, fc.id_fournisseur IS NOT NULL AS regle
            FROM fournisseurs f LEFT JOIN fournisseurs_commande fc ON fc.id_fournisseur = f.id
            ORDER BY f.fournisseur
        """))
        return {x.id: dict(x._mapping) for x in r}

    async def regler_fournisseur(self, id_fournisseur: int, type_: str, actif: bool,
                                 whatsapp: Optional[str], qui: str) -> None:
        await self.db.execute(text("""
            INSERT INTO fournisseurs_commande (id_fournisseur, type, actif, whatsapp, modifie_le, modifie_par)
            VALUES (:id, :t, :a, :w, now(), :qui)
            ON CONFLICT (id_fournisseur) DO UPDATE SET type = :t, actif = :a, whatsapp = :w,
                modifie_le = now(), modifie_par = :qui
        """), {"id": id_fournisseur, "t": type_, "a": actif, "w": whatsapp, "qui": qui})

    async def en_cours(self, jour: date) -> dict[int, float]:
        """Boîtes commandées les jours précédents, validées ou envoyées, pas
        encore livrées (livraison prévue aujourd'hui ou après) : elles ne
        sont pas encore dans le stock."""
        r = await self.db.execute(text("""
            SELECT l.id_nom, sum(l.qte) AS q FROM commandes_lignes l JOIN commandes c ON c.id = l.id_commande
            WHERE c.statut IN ('validee', 'envoyee') AND c.jour < :jour AND c.livraison_prevue >= :jour
            GROUP BY l.id_nom
        """), {"jour": jour})
        return {x.id_nom: float(x.q) for x in r}

    async def budget(self, jour: date) -> dict[str, Decimal]:
        """Budget du mois, achats reçus ce mois (EASYPHARM) et commandes
        engagées pas encore livrées."""
        debut = jour.replace(day=1)
        budget = (await self.db.execute(text(
            "SELECT valeur FROM reglages_stock WHERE cle = 'budget_mensuel_commandes'"))).scalar()
        recu = (await self.db.execute(text(f"""
            SELECT COALESCE(sum(ep.qte_entree * ep.prix_achat), 0) FROM entrees_produits ep
            WHERE ep.date_entree BETWEEN :debut AND :jour AND {_EXCLUS_ACHAT}
        """), {"debut": debut, "jour": jour})).scalar()
        engage = (await self.db.execute(text("""
            SELECT COALESCE(sum(l.qte * l.prix_achat), 0) FROM commandes_lignes l
            JOIN commandes c ON c.id = l.id_commande
            WHERE c.statut IN ('validee', 'envoyee') AND c.jour BETWEEN :debut AND :jour
              AND c.livraison_prevue >= :jour
        """), {"debut": debut, "jour": jour})).scalar()
        return {"budget": Decimal(budget or 0), "recu": Decimal(recu or 0), "engage": Decimal(engage or 0)}

    # ── Valideurs ──
    async def valideurs(self) -> list[str]:
        return [x.username for x in await self.db.execute(text(
            "SELECT username FROM commandes_valideurs ORDER BY username"))]

    async def ajouter_valideur(self, username: str, qui: str) -> None:
        await self.db.execute(text(
            "INSERT INTO commandes_valideurs (username, ajoute_par) VALUES (:u, :qui) ON CONFLICT DO NOTHING"),
            {"u": username, "qui": qui})

    async def retirer_valideur(self, username: str) -> bool:
        r = await self.db.execute(text("DELETE FROM commandes_valideurs WHERE username = :u"), {"u": username})
        return r.rowcount > 0

    # ── Commandes ──
    async def commandes_du_jour(self, jour: date) -> list[dict]:
        r = await self.db.execute(text("""
            SELECT id, client_uuid, jour, id_fournisseur, statut, livraison_prevue, observation,
                   cree_par, cree_le, valide_par, valide_le, envoye_le
            FROM commandes WHERE jour = :jour AND statut <> 'annulee' ORDER BY id
        """), {"jour": jour})
        return [dict(x._mapping) for x in r]

    async def commande(self, id_commande: int) -> Optional[dict]:
        r = (await self.db.execute(text("""
            SELECT id, client_uuid, jour, id_fournisseur, statut, livraison_prevue, observation,
                   cree_par, cree_le, valide_par, valide_le, envoye_le
            FROM commandes WHERE id = :id
        """), {"id": id_commande})).first()
        return dict(r._mapping) if r else None

    async def lignes(self, ids_commandes: list[int]) -> list[dict]:
        r = await self.db.execute(text("""
            SELECT id, client_uuid, id_commande, id_nom, qte, qte_proposee, prix_achat, raison
            FROM commandes_lignes WHERE id_commande = ANY(:ids) ORDER BY id
        """), {"ids": ids_commandes})
        return [dict(x._mapping) for x in r]

    async def creer_commande(self, jour: date, id_fournisseur: int, livraison: date, qui: str,
                             client_uuid: Optional[uuid.UUID] = None) -> Optional[int]:
        """Crée le brouillon du jour ; None s'il existe déjà (un par jour et par fournisseur)."""
        r = (await self.db.execute(text("""
            INSERT INTO commandes (client_uuid, jour, id_fournisseur, livraison_prevue, cree_par)
            VALUES (:u, :jour, :f, :liv, :qui)
            ON CONFLICT (jour, id_fournisseur) WHERE statut <> 'annulee' DO NOTHING
            RETURNING id
        """), {"u": client_uuid or uuid.uuid4(), "jour": jour, "f": id_fournisseur, "liv": livraison,
               "qui": qui})).scalar()
        return r

    async def ecrire_ligne(self, id_commande: int, id_nom: int, qte: int, qte_proposee: Optional[int],
                           prix: Decimal, raison: Optional[dict[str, Any]], qui: str,
                           client_uuid: Optional[uuid.UUID] = None) -> None:
        """Crée la ligne ou change sa quantité (la proposition d'origine est gardée)."""
        await self.db.execute(text("""
            INSERT INTO commandes_lignes (client_uuid, id_commande, id_nom, qte, qte_proposee, prix_achat,
                                          raison, modifie_par)
            VALUES (:u, :c, :p, :q, :qp, :prix, CAST(:raison AS jsonb), :qui)
            ON CONFLICT (id_commande, id_nom) DO UPDATE SET qte = :q, modifie_le = now(), modifie_par = :qui
        """), {"u": client_uuid or uuid.uuid4(), "c": id_commande, "p": id_nom, "q": qte, "qp": qte_proposee,
               "prix": prix, "raison": json.dumps(raison) if raison is not None else None, "qui": qui})

    async def retirer_ligne(self, id_commande: int, id_nom: int) -> bool:
        r = await self.db.execute(text(
            "DELETE FROM commandes_lignes WHERE id_commande = :c AND id_nom = :p"), {"c": id_commande, "p": id_nom})
        return r.rowcount > 0

    async def changer_statut(self, id_commande: int, de: str, vers: str, qui: str) -> bool:
        champs = {"validee": ", valide_par = :qui, valide_le = now()",
                  "envoyee": ", envoye_le = now()", "brouillon": ", valide_par = NULL, valide_le = NULL"}
        r = await self.db.execute(text(
            f"UPDATE commandes SET statut = :vers{champs.get(vers, '')} WHERE id = :id AND statut = :de"),
            {"id": id_commande, "de": de, "vers": vers, "qui": qui})
        return r.rowcount > 0
