"""Accès base des commandes. Seul endroit qui écrit dans ces tables."""
from __future__ import annotations

import json
import uuid
from datetime import date, timedelta
from decimal import Decimal
from typing import Any, Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.modules.commandes.rapprochement import ATTENDUE, MANQUANTE, Ligne, Reception, rapprocher

FENETRE_SUIVI = 45   # jours de commandes relus pour le rapprochement des livraisons
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
            SELECT n.id, n.nom, COALESCE(f.famille, n.famille) AS famille, n.segment_abc, n.de_equiv,
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

    async def fournisseurs(self, jour: date) -> dict[int, dict]:
        """Tous les fournisseurs, avec leur réglage de commande.

        Sans réglage du titulaire (`modifie_par` vide), un fournisseur est
        **actif** s'il a livré (hors avoirs et échanges) ou reçu une commande
        PharmaSuite dans les 30 derniers jours ; son type est deviné d'après
        les produits reçus (pharmaceutique si la majorité ont une DCI ou un
        code CNAS)."""
        r = await self.db.execute(text(f"""
            WITH livraisons AS (
                SELECT ep.id_fournisseur, max(ep.date_entree) AS derniere,
                       avg(CASE WHEN COALESCE(n.id_cnas, 0) > 0 OR NULLIF(trim(n.dci), '') IS NOT NULL
                                THEN 1.0 ELSE 0.0 END) AS part_pharma
                FROM entrees_produits ep LEFT JOIN nomenclature n ON n.id = ep.id_nom
                WHERE ep.id_fournisseur IS NOT NULL AND {_EXCLUS_ACHAT}
                GROUP BY ep.id_fournisseur
            ), commandees AS (
                SELECT id_fournisseur, max(jour) AS derniere FROM commandes
                WHERE statut IN ('validee', 'envoyee') GROUP BY id_fournisseur
            )
            SELECT f.id, f.fournisseur AS nom, f.telephone, f.mobile, f.delai_livraison,
                   NULLIF(GREATEST(COALESCE(l.derniere, DATE '1900-01-01'),
                                   COALESCE(c.derniere, DATE '1900-01-01')), DATE '1900-01-01') AS derniere_commande,
                   fc.modifie_par IS NOT NULL AS regle,
                   CASE WHEN fc.modifie_par IS NOT NULL THEN fc.type
                        WHEN COALESCE(l.part_pharma, 1) >= 0.5 THEN 'pharma' ELSE 'para' END AS type,
                   CASE WHEN fc.modifie_par IS NOT NULL THEN fc.actif
                        ELSE GREATEST(l.derniere, c.derniere) >= CAST(:jour AS date) - 30 END AS actif,
                   fc.whatsapp
            FROM fournisseurs f
            LEFT JOIN fournisseurs_commande fc ON fc.id_fournisseur = f.id
            LEFT JOIN livraisons l ON l.id_fournisseur = f.id
            LEFT JOIN commandees c ON c.id_fournisseur = f.id
            ORDER BY f.fournisseur
        """), {"jour": jour})
        resultat = {}
        for x in r:
            d = dict(x._mapping)
            d["actif"] = bool(d["actif"])
            resultat[x.id] = d
        return resultat

    async def regler_fournisseur(self, id_fournisseur: int, type_: str, actif: bool,
                                 whatsapp: Optional[str], qui: str) -> None:
        await self.db.execute(text("""
            INSERT INTO fournisseurs_commande (id_fournisseur, type, actif, whatsapp, modifie_le, modifie_par)
            VALUES (:id, :t, :a, :w, now(), :qui)
            ON CONFLICT (id_fournisseur) DO UPDATE SET type = :t, actif = :a, whatsapp = :w,
                modifie_le = now(), modifie_par = :qui
        """), {"id": id_fournisseur, "t": type_, "a": actif, "w": whatsapp, "qui": qui})

    async def lignes_envoyees(self, depuis: date, jour: date) -> list[dict]:
        """Lignes des commandes validées ou envoyées depuis une date, avec ce
        qu'il faut pour les rapprocher des réceptions. `depuis_envoi` : jour
        de l'envoi (la commande du samedi part le vendredi soir)."""
        r = await self.db.execute(text("""
            SELECT l.id, l.id_commande, l.id_nom, l.qte, l.prix_achat, n.nom,
                   COALESCE(mv.stock_actuel, 0) AS stock,
                   CASE WHEN t.id_nom IS NULL THEN NULL WHEN NOT t.confirme THEN 'proposee'
                        WHEN t.tension THEN 'confirmee' END AS tension,
                   c.jour, c.id_fournisseur, c.statut, c.livraison_prevue, f.fournisseur,
                   LEAST(c.jour, CAST(COALESCE(c.envoye_le, c.valide_le, c.cree_le)
                                      AT TIME ZONE 'Africa/Algiers' AS date)) AS depuis_envoi
            FROM commandes_lignes l JOIN commandes c ON c.id = l.id_commande
            LEFT JOIN nomenclature n ON n.id = l.id_nom
            LEFT JOIN fournisseurs f ON f.id = c.id_fournisseur
            LEFT JOIN mv_stock_produits mv ON mv.id_nom = l.id_nom
            LEFT JOIN produits_tension t ON t.id_nom = l.id_nom
            WHERE c.statut IN ('validee', 'envoyee') AND c.jour BETWEEN :depuis AND :jour
            ORDER BY c.jour DESC, c.id, n.nom
        """), {"depuis": depuis, "jour": jour})
        return [dict(x._mapping) for x in r]

    async def receptions(self, ids_nom: list[int], depuis: date, jour: date) -> list[Reception]:
        """Entrées EASYPHARM (hors avoirs et échanges) de ces produits, par jour et par grossiste."""
        if not ids_nom:
            return []
        r = await self.db.execute(text(f"""
            SELECT ep.id_fournisseur, ep.id_nom, ep.date_entree, sum(ep.qte_entree) AS q
            FROM entrees_produits ep
            WHERE ep.id_nom = ANY(:ids) AND ep.date_entree > :depuis AND ep.date_entree <= :jour
              AND ep.id_fournisseur IS NOT NULL AND {_EXCLUS_ACHAT}
            GROUP BY ep.id_fournisseur, ep.id_nom, ep.date_entree
            HAVING sum(ep.qte_entree) > 0
        """), {"ids": ids_nom, "depuis": depuis, "jour": jour})
        return [Reception(x.id_fournisseur, x.id_nom, x.date_entree, int(x.q)) for x in r]

    async def suivi(self, depuis: date, jour: date) -> list[dict]:
        """Lignes envoyées depuis une date, chacune avec son suivi de livraison
        (`recu`, `recu_le`, `etat`, `reste`)."""
        lignes = await self.lignes_envoyees(depuis, jour)
        if not lignes:
            return []
        objets = [Ligne(l["id"], l["id_fournisseur"], l["id_nom"], l["qte"], l["depuis_envoi"],
                        l["livraison_prevue"] or l["jour"]) for l in lignes]
        recues = await self.receptions(sorted({l["id_nom"] for l in lignes}),
                                       min(o.depuis for o in objets), jour)
        suivis = rapprocher(objets, recues, jour)
        for l, o in zip(lignes, objets):
            s = suivis[l["id"]]
            l.update(recu=s.recu, recu_le=s.recu_le, etat=s.etat, reste=s.reste(o))
        return lignes

    async def en_cours(self, jour: date) -> dict[int, float]:
        """Boîtes commandées les jours précédents, validées ou envoyées, pas
        encore reçues et encore attendues (livraison prévue aujourd'hui ou
        après) : elles ne sont pas dans le stock. Ce qui est déjà entré dans
        EASYPHARM n'est plus compté ; ce qui n'est pas arrivé à la date
        prévue ne l'est plus non plus : le produit est reproposé."""
        en_cours: dict[int, float] = {}
        for l in await self.suivi(jour - timedelta(days=FENETRE_SUIVI), jour):
            if l["etat"] == ATTENDUE and l["jour"] < jour and l["reste"] > 0:
                en_cours[l["id_nom"]] = en_cours.get(l["id_nom"], 0.0) + l["reste"]
        return en_cours

    async def budget(self, jour: date) -> dict[str, Decimal]:
        """Budget du mois, achats reçus ce mois (EASYPHARM) et commandes
        engagées pas encore livrées (le reste à recevoir des lignes attendues)."""
        debut = jour.replace(day=1)
        budget = (await self.db.execute(text(
            "SELECT valeur FROM reglages_stock WHERE cle = 'budget_mensuel_commandes'"))).scalar()
        recu = (await self.db.execute(text(f"""
            SELECT COALESCE(sum(ep.qte_entree * ep.prix_achat), 0) FROM entrees_produits ep
            WHERE ep.date_entree BETWEEN :debut AND :jour AND {_EXCLUS_ACHAT}
        """), {"debut": debut, "jour": jour})).scalar()
        engage = sum((Decimal(l["reste"]) * l["prix_achat"] for l in await self.suivi(debut, jour)
                      if l["etat"] == ATTENDUE), Decimal(0))
        return {"budget": Decimal(budget or 0), "recu": Decimal(recu or 0), "engage": engage}

    async def proposer_tensions_non_livrees(self, jour: date, fois: int = 2) -> int:
        """Propose en tension les produits commandés au moins `fois` fois sur
        la période de suivi sans qu'aucune boîte n'arrive."""
        manques: dict[int, int] = {}
        recus: set[int] = set()
        for l in await self.suivi(jour - timedelta(days=FENETRE_SUIVI), jour):
            if l["recu"] > 0:
                recus.add(l["id_nom"])
            elif l["etat"] == MANQUANTE:
                manques[l["id_nom"]] = manques.get(l["id_nom"], 0) + 1
        n = 0
        for id_nom, k in manques.items():
            if k >= fois and id_nom not in recus:
                r = await self.db.execute(text("""
                    INSERT INTO produits_tension (id_nom, motif) VALUES (:p, :m) ON CONFLICT (id_nom) DO NOTHING
                """), {"p": id_nom, "m": f"Commandé {k} fois en {FENETRE_SUIVI} jours, jamais livré"})
                n += r.rowcount or 0
        return n

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

    # ── Génériques ──
    async def choix_generique(self, id_nom: int, choix: Optional[str], qui: str) -> None:
        if choix is None:
            await self.db.execute(text("DELETE FROM generiques_choix WHERE id_nom = :p"), {"p": id_nom})
            return
        await self.db.execute(text("""
            INSERT INTO generiques_choix (id_nom, choix, modifie_par) VALUES (:p, :c, :qui)
            ON CONFLICT (id_nom) DO UPDATE SET choix = :c, modifie_le = now(), modifie_par = :qui
        """), {"p": id_nom, "c": choix, "qui": qui})

    async def mode_groupe(self, code: str, mode: Optional[str], qui: str) -> None:
        if mode is None:
            await self.db.execute(text("DELETE FROM generiques_groupes WHERE code = :c"), {"c": code})
            return
        await self.db.execute(text("""
            INSERT INTO generiques_groupes (code, mode, modifie_par) VALUES (:c, :m, :qui)
            ON CONFLICT (code) DO UPDATE SET mode = :m, modifie_le = now(), modifie_par = :qui
        """), {"c": code, "m": mode, "qui": qui})

    async def code_dci(self, id_nom: int) -> Optional[str]:
        return (await self.db.execute(text("SELECT de_equiv FROM nomenclature WHERE id = :p"), {"p": id_nom})).scalar()

    # ── Produits en tension ──
    async def detecter_tensions(self, jour: date) -> int:
        """Propose (à confirmer) les produits qui semblent en tension :
        - marqués « quota » dans EASYPHARM ;
        - en rupture depuis au moins 14 jours, sans aucune livraison depuis,
          alors qu'ils se vendaient au moins 6 jours sur les 6 mois d'avant.
        Un produit déjà décidé par le titulaire n'est jamais reproposé."""
        r = await self.db.execute(text(f"""
            WITH ruptures AS (
                SELECT n.id AS id_nom,
                       COALESCE((SELECT max(h.date) FROM historique_stock_jour h
                                 WHERE h.id_nom = n.id AND h.stock_eod > 0), CAST(:jour AS date) - 365) AS dernier_stock
                FROM nomenclature n JOIN mv_stock_produits mv ON mv.id_nom = n.id
                WHERE n.archive = false AND COALESCE(mv.stock_actuel, 0) <= 0 AND mv.actif
            ), candidats AS (
                SELECT r.id_nom, CAST(:jour AS date) - r.dernier_stock AS jours,
                       (SELECT count(DISTINCT sp.date) FROM sorties_produits sp
                        WHERE sp.id_nom = r.id_nom AND sp.qte_sortie > 0
                          AND sp.date BETWEEN r.dernier_stock - 182 AND r.dernier_stock) AS jours_vente
                FROM ruptures r
                WHERE r.dernier_stock <= CAST(:jour AS date) - 14
                  AND NOT EXISTS (SELECT 1 FROM entrees_produits ep
                                  WHERE ep.id_nom = r.id_nom AND ep.date_entree > r.dernier_stock
                                    AND {_EXCLUS_ACHAT})
            )
            INSERT INTO produits_tension (id_nom, motif)
            SELECT DISTINCT ON (id_nom) id_nom, motif FROM (
                SELECT n.id AS id_nom, 'Marqué « quota » dans EASYPHARM' AS motif, 0 AS rang FROM nomenclature n
                WHERE n.archive = false AND n.disponibilite = 'quota'
                UNION ALL
                SELECT id_nom, 'En rupture depuis ' || jours || ' jours sans livraison ; vendu ' || jours_vente
                               || ' jours sur les 6 mois d''avant', 1
                FROM candidats WHERE jours_vente >= 6
            ) c
            ORDER BY id_nom, rang
            ON CONFLICT (id_nom) DO NOTHING
        """), {"jour": jour})
        return r.rowcount or 0

    async def tensions(self) -> list[dict]:
        r = await self.db.execute(text("""
            SELECT t.id_nom, n.nom, COALESCE(mv.stock_actuel, 0) AS stock, t.tension, t.confirme, t.source,
                   t.motif, t.detecte_le, t.modifie_par
            FROM produits_tension t JOIN nomenclature n ON n.id = t.id_nom
            LEFT JOIN mv_stock_produits mv ON mv.id_nom = t.id_nom
            ORDER BY t.confirme, n.nom
        """))
        return [dict(x._mapping) for x in r]

    async def tension(self, id_nom: int) -> Optional[dict]:
        r = (await self.db.execute(text(
            "SELECT id_nom, tension, confirme, source, motif FROM produits_tension WHERE id_nom = :p"),
            {"p": id_nom})).first()
        return dict(r._mapping) if r else None

    async def regler_tension(self, id_nom: int, tension: bool, qui: str) -> None:
        await self.db.execute(text("""
            INSERT INTO produits_tension (id_nom, tension, confirme, source, modifie_le, modifie_par)
            VALUES (:p, :t, true, 'saisie', now(), :qui)
            ON CONFLICT (id_nom) DO UPDATE SET tension = :t, confirme = true, modifie_le = now(), modifie_par = :qui
        """), {"p": id_nom, "t": tension, "qui": qui})
