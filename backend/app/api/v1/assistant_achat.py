"""
Assistant achat — API FastAPI.

Endpoints :
    GET  /assistant-achat/suggestions         Liste des produits à commander (depuis cache)
    GET  /assistant-achat/prevision/{id_nom}  Prévision détaillée d'un produit
    GET  /assistant-achat/parametres-stock    Paramètres SS/ROP/EOQ de tous les produits
    POST /assistant-achat/calculer            Déclenche le calcul complet (background)
    POST /assistant-achat/optimiser           Optimisation LP sur une sélection + budget
"""

from __future__ import annotations

import asyncio
import logging
from datetime import datetime
from typing import Any, Optional

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_current_user
from app.core.database import get_db
from app.services.purchase_engine.censored_demand import correct_censored_demand
from app.services.purchase_engine.forecaster import forecast_product
from app.services.purchase_engine.optimizer import optimize_order
from app.services.purchase_engine.stock_params import compute_stock_params

import json
import pandas as pd
import numpy as np

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/assistant-achat", tags=["assistant-achat"])

# ── Schémas Pydantic ────────────────────────────────────────────────────────────

class OptimiserRequest(BaseModel):
    id_noms: list[int]
    budget_max: Optional[float] = None


class ParametreStockUpdate(BaseModel):
    holding_cost_pct: Optional[float] = None


# ── GET /suggestions ───────────────────────────────────────────────────────────

@router.get("/suggestions")
async def get_suggestions(
    segment_abc: Optional[str] = Query(None, description="Filtrer par segment ABC (A, B, C)"),
    segment_xyz: Optional[str] = Query(None, description="Filtrer par segment XYZ (X, Y, Z)"),
    only_sous_rop: bool = Query(True, description="Uniquement les produits sous le ROP"),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Retourne les suggestions de commande depuis les tables de cache.
    Requiert un calcul préalable via POST /calculer.
    """
    where_clauses = ["1=1"]
    params: dict[str, Any] = {"limit": limit, "offset": offset}

    if segment_abc:
        where_clauses.append("n.segment_abc = :abc")
        params["abc"] = segment_abc.upper()
    if segment_xyz:
        where_clauses.append("n.segment_xyz = :xyz")
        params["xyz"] = segment_xyz.upper()
    if only_sous_rop:
        where_clauses.append("mv.stock_actuel < ps.rop")

    where = " AND ".join(where_clauses)

    rows = (await db.execute(text(f"""
        SELECT
            n.id                                            AS id_nom,
            n.nom,
            n.segment_abc,
            n.segment_xyz,
            n.disponibilite,
            mv.stock_actuel,
            ps.rop,
            ps.eoq,
            ps.stock_securite,
            ps.demande_moy_j,
            ps.delai_moyen_j,
            pd.modele,
            pd.prevision_30j,
            pd.prevision_90j,
            pd.mape_holdout,
            ps.updated_at,
            GREATEST(ps.eoq, ps.rop - mv.stock_actuel)     AS qte_suggeree,
            (
                SELECT ep.fournisseur
                FROM entrees_produits ep
                WHERE ep.id_nom = n.id
                ORDER BY ep.date_entree DESC
                LIMIT 1
            )                                               AS dernier_fournisseur,
            (
                SELECT ep.prix_achat
                FROM entrees_produits ep
                WHERE ep.id_nom = n.id AND ep.prix_achat > 0
                ORDER BY ep.date_entree DESC
                LIMIT 1
            )                                               AS dernier_prix_achat
        FROM nomenclature n
        JOIN parametres_stock ps ON ps.id_nom = n.id
        JOIN mv_stock_produits mv ON mv.id_nom = n.id
        LEFT JOIN previsions_demande pd ON pd.id_nom = n.id
        WHERE {where}
        ORDER BY n.segment_abc NULLS LAST, (mv.stock_actuel - ps.rop) ASC
        LIMIT :limit OFFSET :offset
    """), params)
    ).fetchall()

    return [dict(r._mapping) for r in rows]


# ── GET /prevision/{id_nom} ────────────────────────────────────────────────────

@router.get("/prevision/{id_nom}")
async def get_prevision(
    id_nom: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Prévision détaillée (depuis cache) pour un produit donné."""
    row = (await db.execute(text("""
        SELECT pd.*, ps.demande_moy_j, ps.demande_std_j,
               ps.stock_securite, ps.rop, ps.eoq,
               n.nom, n.segment_abc, n.segment_xyz
        FROM previsions_demande pd
        JOIN parametres_stock ps ON ps.id_nom = pd.id_nom
        JOIN nomenclature n ON n.id = pd.id_nom
        WHERE pd.id_nom = :id_nom
    """), {"id_nom": id_nom})).fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="Aucune prévision calculée pour ce produit")

    return dict(row._mapping)


# ── GET /parametres-stock ──────────────────────────────────────────────────────

@router.get("/parametres-stock")
async def get_parametres_stock(
    segment_abc: Optional[str] = Query(None),
    limit: int = Query(200, ge=1, le=1000),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Paramètres SS/ROP/EOQ de tous les produits (depuis cache)."""
    extra = "AND n.segment_abc = :abc" if segment_abc else ""
    params: dict[str, Any] = {"limit": limit, "offset": offset}
    if segment_abc:
        params["abc"] = segment_abc.upper()

    rows = (await db.execute(text(f"""
        SELECT ps.*, n.nom, n.segment_abc, n.segment_xyz,
               mv.stock_actuel,
               f.delai_livraison AS delai_fournisseur_configure
        FROM parametres_stock ps
        JOIN nomenclature n ON n.id = ps.id_nom
        JOIN mv_stock_produits mv ON mv.id_nom = ps.id_nom
        LEFT JOIN LATERAL (
            SELECT f2.delai_livraison
            FROM entrees_produits ep
            JOIN fournisseurs f2 ON f2.fournisseur = ep.fournisseur
            WHERE ep.id_nom = ps.id_nom
            ORDER BY ep.date_entree DESC
            LIMIT 1
        ) f ON true
        WHERE 1=1 {extra}
        ORDER BY n.segment_abc NULLS LAST, n.nom
        LIMIT :limit OFFSET :offset
    """), params)
    ).fetchall()

    return [dict(r._mapping) for r in rows]


# ── POST /calculer ─────────────────────────────────────────────────────────────

_calcul_en_cours = False


@router.post("/calculer")
async def lancer_calcul(
    background_tasks: BackgroundTasks,
    segment_abc: Optional[str] = Query(None, description="Restreindre au segment ABC (A/B/C). None = tous"),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Déclenche le calcul complet (correction censurée + prévision + paramètres stock).
    S'exécute en arrière-plan. Réponse immédiate.
    """
    global _calcul_en_cours
    if _calcul_en_cours:
        return {"statut": "en_cours", "message": "Un calcul est déjà en cours"}

    background_tasks.add_task(_run_calcul, segment_abc)
    return {"statut": "lance", "message": "Calcul démarré en arrière-plan"}


async def _run_calcul(segment_abc: str | None) -> None:
    global _calcul_en_cours
    _calcul_en_cours = True
    try:
        from app.core.database import AsyncSessionLocal
        async with AsyncSessionLocal() as db:
            await _calcul_tous_produits(db, segment_abc)
        logger.info("Calcul assistant achat terminé")
    except Exception as exc:
        logger.exception("Erreur calcul assistant achat : %s", exc)
    finally:
        _calcul_en_cours = False


async def _calcul_tous_produits(db: AsyncSession, segment_abc: str | None) -> None:
    """Calcul complet pour tous les produits éligibles."""

    # ── 1. Activité globale de la pharmacie (nb ventes par jour) ──────────────
    global_rows = (await db.execute(text("""
        SELECT date, COUNT(*) AS nb_ventes
        FROM sorties
        WHERE type = 'V'
          AND date >= CURRENT_DATE - INTERVAL '18 months'
        GROUP BY date
        ORDER BY date
    """))).fetchall()

    global_activity = pd.Series(
        {r.date: int(r.nb_ventes) for r in global_rows},
        dtype=float,
    )
    global_activity.index = pd.to_datetime(global_activity.index)
    logger.info("Activité globale : %d jours chargés", len(global_activity))

    # ── 2. Sélection des produits à traiter ────────────────────────────────────
    # segment_abc IS NOT NULL non requis : si NULL on traite quand même (fallback C)
    extra_filter = "AND n.segment_abc = :abc" if segment_abc else ""
    params_sel: dict[str, Any] = {}
    if segment_abc:
        params_sel["abc"] = segment_abc.upper()

    produits = (await db.execute(text(f"""
        SELECT n.id AS id_nom, n.nom,
               COALESCE(n.segment_abc, 'C') AS segment_abc,
               COALESCE(n.segment_xyz, 'Z') AS segment_xyz,
               COALESCE(n.prix_achat_moyen, 0) AS prix_achat_moyen,
               COALESCE(mv.stock_actuel, 0) AS stock_actuel,
               (
                   SELECT f.delai_livraison
                   FROM entrees_produits ep
                   JOIN fournisseurs f ON f.fournisseur = ep.fournisseur
                   WHERE ep.id_nom = n.id AND f.delai_livraison IS NOT NULL
                   ORDER BY ep.date_entree DESC
                   LIMIT 1
               ) AS delai_livraison_j
        FROM nomenclature n
        JOIN mv_stock_produits mv ON mv.id_nom = n.id
        WHERE n.archive = FALSE {extra_filter}
        ORDER BY n.segment_abc NULLS LAST, n.id
    """), params_sel)).fetchall()

    if not produits:
        logger.info("Aucun produit trouvé dans nomenclature")
        return

    logger.info("Produits à traiter : %d", len(produits))

    # ── 3. Série de ventes + historique stock (18 mois) ──────────────────────
    id_noms = [p.id_nom for p in produits]

    # Historique stock reconstitué (si disponible)
    stock_histo_map: dict[int, pd.Series] = {}
    histo_rows = (await db.execute(text("""
        SELECT id_nom, date, stock_eod
        FROM historique_stock_jour
        WHERE date >= CURRENT_DATE - INTERVAL '18 months'
          AND id_nom = ANY(:ids)
        ORDER BY id_nom, date
    """), {"ids": id_noms})).fetchall()

    for r in histo_rows:
        if r.id_nom not in stock_histo_map:
            stock_histo_map[r.id_nom] = {}
        stock_histo_map[r.id_nom][r.date] = float(r.stock_eod)

    for id_nom in id_noms:
        raw = stock_histo_map.get(id_nom, {})
        s = pd.Series(raw, dtype=float)
        if len(s) > 0:
            s.index = pd.to_datetime(s.index)
        stock_histo_map[id_nom] = s

    logger.info("Historique stock reconstitué : %d produits avec données",
                sum(1 for s in stock_histo_map.values() if len(s) > 0))

    # Série de ventes par produit
    # Chunker pour éviter requête trop large
    CHUNK = 500
    ventes_map: dict[int, pd.Series] = {}

    for i in range(0, len(id_noms), CHUNK):
        chunk_ids = id_noms[i: i + CHUNK]
        rows_ventes = (await db.execute(text("""
            SELECT sp.id_nom, sp.date, SUM(sp.qte_sortie) AS qte
            FROM sorties_produits sp
            WHERE sp.id_nom = ANY(:ids)
              AND sp.type_sortie = 'V'
              AND sp.date >= CURRENT_DATE - INTERVAL '18 months'
            GROUP BY sp.id_nom, sp.date
            ORDER BY sp.id_nom, sp.date
        """), {"ids": chunk_ids})).fetchall()

        for r in rows_ventes:
            if r.id_nom not in ventes_map:
                ventes_map[r.id_nom] = {}
            ventes_map[r.id_nom][r.date] = float(r.qte)

    # Convertir en pd.Series
    for id_nom in id_noms:
        raw = ventes_map.get(id_nom, {})
        s = pd.Series(raw, dtype=float)
        if len(s) > 0:
            s.index = pd.to_datetime(s.index)
        ventes_map[id_nom] = s

    # ── 4. Calcul Python pur (pas de DB) ─────────────────────────────────────
    DEFAULT_DELAI = 7.0
    nb_ok = 0
    nb_err = 0
    batch_ps: list[dict] = []   # parametres_stock à insérer
    batch_pd: list[dict] = []   # previsions_demande à insérer
    BATCH_SIZE = 50

    for prod in produits:
        id_nom = prod.id_nom
        series_raw = ventes_map.get(id_nom, pd.Series(dtype=float))
        nb_jours_histo = len(series_raw)

        try:
            stock_hist = stock_histo_map.get(id_nom)
            stock_hist = stock_hist if (stock_hist is not None and len(stock_hist) > 0) else None
            corr = correct_censored_demand(series_raw, global_activity, stock_hist)
            serie_corrigee = corr["serie_corrigee"]

            prev = forecast_product(
                serie_corrigee=serie_corrigee,
                segment_abc=prod.segment_abc,
                segment_xyz=prod.segment_xyz,
                nb_jours_historique=nb_jours_histo,
            )

            vals = np.array(list(serie_corrigee.values()), dtype=float)
            demande_moy_j = float(np.mean(vals)) if len(vals) > 0 else 0.0
            demande_std_j = float(np.std(vals)) if len(vals) > 0 else 0.0
            delai         = float(prod.delai_livraison_j or DEFAULT_DELAI)
            prix_achat    = float(prod.prix_achat_moyen or 0.0)

            params_stock = compute_stock_params(
                demande_moy_j=demande_moy_j,
                demande_std_j=demande_std_j,
                prix_achat=prix_achat,
                delai_livraison_j=delai,
                segment_abc=prod.segment_abc,
            )

            batch_ps.append({
                "id_nom": id_nom,
                "delai":  delai,
                "d_moy":  round(demande_moy_j, 4),
                "d_std":  round(demande_std_j, 4),
                "ss":     params_stock["stock_securite"],
                "rop":    params_stock["rop"],
                "eoq":    params_stock["eoq"],
                "hcp":    params_stock["holding_cost_pct"],
            })
            batch_pd.append({
                "id_nom": id_nom,
                "modele": prev["modele"],
                "p30":    _safe_float(prev["prevision_30j"]),
                "p90":    _safe_float(prev["prevision_90j"]),
                "mape":   _safe_float(prev["mape_holdout"]),
                "serie":  json.dumps(serie_corrigee),
            })
            nb_ok += 1

        except Exception as exc:
            logger.warning("Calcul id_nom=%s : %s", id_nom, exc)
            nb_err += 1

        # ── Flush en base tous les BATCH_SIZE produits ──────────────────────
        if len(batch_ps) >= BATCH_SIZE:
            await _flush_batch(db, batch_ps, batch_pd)
            batch_ps.clear()
            batch_pd.clear()

    # Flush du dernier batch
    if batch_ps:
        await _flush_batch(db, batch_ps, batch_pd)

    await db.commit()
    logger.info("Calcul terminé — %d OK, %d erreurs / %d produits", nb_ok, nb_err, len(produits))


def _safe_float(v: Any) -> float | None:
    """Convertit inf / -inf / nan en None pour éviter les overflow PostgreSQL."""
    if v is None:
        return None
    try:
        f = float(v)
        return None if (f != f or f == float("inf") or f == float("-inf")) else f
    except (TypeError, ValueError):
        return None


async def _flush_batch(
    db: AsyncSession,
    batch_ps: list[dict],
    batch_pd: list[dict],
) -> None:
    """Écrit un batch de résultats en base."""
    for row in batch_ps:
        await db.execute(text("""
            INSERT INTO parametres_stock
                (id_nom, delai_moyen_j, demande_moy_j, demande_std_j,
                 stock_securite, rop, eoq, holding_cost_pct, updated_at)
            VALUES
                (:id_nom, :delai, :d_moy, :d_std, :ss, :rop, :eoq, :hcp, NOW())
            ON CONFLICT (id_nom) DO UPDATE SET
                delai_moyen_j    = EXCLUDED.delai_moyen_j,
                demande_moy_j    = EXCLUDED.demande_moy_j,
                demande_std_j    = EXCLUDED.demande_std_j,
                stock_securite   = EXCLUDED.stock_securite,
                rop              = EXCLUDED.rop,
                eoq              = EXCLUDED.eoq,
                holding_cost_pct = EXCLUDED.holding_cost_pct,
                updated_at       = NOW()
        """), row)

    for row in batch_pd:
        await db.execute(text("""
            INSERT INTO previsions_demande
                (id_nom, modele, prevision_30j, prevision_90j,
                 mape_holdout, serie_corrigee, updated_at)
            VALUES
                (:id_nom, :modele, :p30, :p90, :mape, CAST(:serie AS jsonb), NOW())
            ON CONFLICT (id_nom) DO UPDATE SET
                modele         = EXCLUDED.modele,
                prevision_30j  = EXCLUDED.prevision_30j,
                prevision_90j  = EXCLUDED.prevision_90j,
                mape_holdout   = EXCLUDED.mape_holdout,
                serie_corrigee = EXCLUDED.serie_corrigee,
                updated_at     = NOW()
        """), row)

    await db.flush()


# ── POST /optimiser ────────────────────────────────────────────────────────────

@router.post("/optimiser")
async def optimiser_commande(
    req: OptimiserRequest,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Optimisation LP sur une sélection de produits.
    Minimise le coût total sous contrainte de budget.
    """
    if not req.id_noms:
        raise HTTPException(status_code=400, detail="Liste de produits vide")

    rows = (await db.execute(text("""
        SELECT
            n.id                    AS id_nom,
            n.nom,
            ps.rop,
            ps.eoq,
            mv.stock_actuel,
            COALESCE(
                (SELECT ep.prix_achat
                 FROM entrees_produits ep
                 WHERE ep.id_nom = n.id AND ep.prix_achat > 0
                 ORDER BY ep.date_entree DESC
                 LIMIT 1),
                n.prix_achat_moyen,
                0
            ) AS prix_achat
        FROM nomenclature n
        JOIN parametres_stock ps ON ps.id_nom = n.id
        JOIN mv_stock_produits mv ON mv.id_nom = n.id
        WHERE n.id = ANY(:ids)
    """), {"ids": req.id_noms})).fetchall()

    if not rows:
        raise HTTPException(status_code=404, detail="Aucun produit trouvé avec paramètres calculés")

    produits_lp = []
    for r in rows:
        qte_min = max(0, int((r.rop or 0) - (r.stock_actuel or 0)))
        qte_max = max(qte_min, int((r.eoq or 1) * 3))
        produits_lp.append({
            "id_nom":     r.id_nom,
            "nom":        r.nom,
            "prix_achat": float(r.prix_achat or 0),
            "qte_min":    qte_min,
            "qte_max":    qte_max,
            "eoq":        int(r.eoq or 1),
        })

    result = optimize_order(produits_lp, budget_max=req.budget_max)
    return result


# ── POST /reconstituer-stock ───────────────────────────────────────────────────

_reconstitution_en_cours = False


@router.post("/reconstituer-stock")
async def reconstituer_stock(
    background_tasks: BackgroundTasks,
    mois: int = Query(18, ge=3, le=36, description="Nombre de mois d'historique à reconstituer"),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Reconstitue le stock réel historique pour tous les produits.
    Utilise : sorties + entrees + inventaires_produits (ecart) + rechange_sorties_produits.
    S'exécute en arrière-plan. À lancer une fois par mois.
    """
    global _reconstitution_en_cours
    if _reconstitution_en_cours:
        return {"statut": "en_cours", "message": "Une reconstitution est déjà en cours"}

    background_tasks.add_task(_run_reconstitution, mois)
    return {"statut": "lance", "message": f"Reconstitution démarrée ({mois} mois d'historique)"}


async def _run_reconstitution(mois: int) -> None:
    global _reconstitution_en_cours
    _reconstitution_en_cours = True
    try:
        from app.core.database import AsyncSessionLocal
        from app.services.purchase_engine.stock_history import reconstituer_et_sauvegarder
        from datetime import date, timedelta

        date_debut = (date.today() - timedelta(days=mois * 30)).strftime("%Y-%m-%d")

        # 1. Charger la liste des produits dans une session dédiée
        async with AsyncSessionLocal() as db:
            produits = (await db.execute(text("""
                SELECT n.id AS id_nom, COALESCE(mv.stock_actuel, 0) AS stock_actuel
                FROM nomenclature n
                JOIN mv_stock_produits mv ON mv.id_nom = n.id
                WHERE n.archive = FALSE
                ORDER BY n.id
            """))).fetchall()

        logger.info("Reconstitution stock : %d produits × %d mois", len(produits), mois)
        nb_ok = 0
        nb_err = 0

        # 2. Une session isolée par produit — une erreur n'affecte pas les autres
        for prod in produits:
            try:
                async with AsyncSessionLocal() as db:
                    nb = await reconstituer_et_sauvegarder(
                        db, prod.id_nom, float(prod.stock_actuel), date_debut
                    )
                    await db.commit()
                if nb > 0:
                    nb_ok += 1
            except Exception as exc:
                logger.warning("Reconstitution id_nom=%s : %s", prod.id_nom, exc)
                nb_err += 1

        logger.info("Reconstitution terminée — %d OK, %d erreurs / %d produits",
                    nb_ok, nb_err, len(produits))
    except Exception as exc:
        logger.exception("Erreur reconstitution stock : %s", exc)
    finally:
        _reconstitution_en_cours = False


# ── GET /forecast-score ────────────────────────────────────────────────────────

@router.get("/forecast-score")
async def get_forecast_score(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Score global du système de prévision.
    Métriques agrégées sur tous les produits ayant un mape_holdout calculé.
    """
    global_row = (await db.execute(text("""
        SELECT
            COUNT(*)                                                AS nb_total,
            COUNT(*) FILTER (WHERE pd.mape_holdout IS NOT NULL)    AS nb_avec_score,
            ROUND(AVG(pd.mape_holdout)::numeric, 4)                AS mape_moyen,
            ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
                  (ORDER BY pd.mape_holdout)::numeric, 4)          AS mape_median,
            COUNT(*) FILTER (WHERE pd.mape_holdout < 0.10)         AS excellent,
            COUNT(*) FILTER (WHERE pd.mape_holdout BETWEEN 0.10 AND 0.25) AS bon,
            COUNT(*) FILTER (WHERE pd.mape_holdout BETWEEN 0.25 AND 0.50) AS acceptable,
            COUNT(*) FILTER (WHERE pd.mape_holdout BETWEEN 0.50 AND 1.00) AS mauvais,
            COUNT(*) FILTER (WHERE pd.mape_holdout > 1.00)         AS tres_mauvais
        FROM previsions_demande pd
        WHERE pd.mape_holdout IS NOT NULL
    """))).fetchone()

    # Par segment ABC
    seg_rows = (await db.execute(text("""
        SELECT
            COALESCE(n.segment_abc, '?')                           AS segment,
            COUNT(*)                                               AS nb,
            ROUND(AVG(pd.mape_holdout)::numeric, 4)               AS mape_moyen,
            ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP
                  (ORDER BY pd.mape_holdout)::numeric, 4)         AS mape_median
        FROM previsions_demande pd
        JOIN nomenclature n ON n.id = pd.id_nom
        WHERE pd.mape_holdout IS NOT NULL
        GROUP BY n.segment_abc
        ORDER BY n.segment_abc NULLS LAST
    """))).fetchall()

    # Par modèle
    model_rows = (await db.execute(text("""
        SELECT
            modele,
            COUNT(*)                                               AS nb,
            ROUND(AVG(mape_holdout)::numeric, 4)                  AS mape_moyen,
            ROUND(MIN(mape_holdout)::numeric, 4)                  AS mape_min,
            ROUND(MAX(mape_holdout)::numeric, 4)                  AS mape_max
        FROM previsions_demande
        WHERE mape_holdout IS NOT NULL
        GROUP BY modele
        ORDER BY mape_moyen
    """))).fetchall()

    g = global_row
    nb = int(g.nb_avec_score) if g.nb_avec_score else 0

    return {
        "nb_total":      int(g.nb_total or 0),
        "nb_avec_score": nb,
        "mape_moyen":    float(g.mape_moyen)  if g.mape_moyen  else None,
        "mape_median":   float(g.mape_median) if g.mape_median else None,
        "distribution": {
            "excellent":    int(g.excellent    or 0),   # MAPE < 10%
            "bon":          int(g.bon          or 0),   # 10–25%
            "acceptable":   int(g.acceptable   or 0),   # 25–50%
            "mauvais":      int(g.mauvais      or 0),   # 50–100%
            "tres_mauvais": int(g.tres_mauvais or 0),   # > 100%
        },
        "pct_fiables": round(
            (int(g.excellent or 0) + int(g.bon or 0) + int(g.acceptable or 0)) / nb * 100, 1
        ) if nb > 0 else 0,
        "par_segment": [dict(r._mapping) for r in seg_rows],
        "par_modele":  [dict(r._mapping) for r in model_rows],
    }


# ── GET /statut ────────────────────────────────────────────────────────────────

@router.get("/statut")
async def get_statut(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Indique si un calcul est en cours et la fraîcheur du cache."""
    row = (await db.execute(text("""
        SELECT MAX(updated_at) AS derniere_maj, COUNT(*) AS nb_produits
        FROM parametres_stock
    """))).fetchone()

    return {
        "calcul_en_cours": _calcul_en_cours,
        "derniere_maj": row.derniere_maj,
        "nb_produits_calcules": int(row.nb_produits or 0),
    }
