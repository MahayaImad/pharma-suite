"""
KPIs par domaine — Ventes, Recouvrement, Stock, Achats
Endpoints généraux (pas par employé — voir performance.py pour les KPIs individuels)
"""
from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

from app.core.database import get_db
from app.core.security import get_current_user

router = APIRouter(prefix="/kpis", tags=["kpis"])

# IDs clients Chifa / caisses sociales (exclus du comptoir et du recouvrement)
_CHIFA = (1, 2, 3)


# ── Ventes ────────────────────────────────────────────────────────────────────

@router.get("/ventes/{annee}/{mois}")
async def kpis_ventes(
    annee: int,
    mois: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    r = await db.execute(text("""
        WITH v AS (
            SELECT
                COALESCE(SUM(CASE WHEN type != 'RET' THEN total_a_payer  ELSE 0 END), 0) AS ca,
                COALESCE(SUM(CASE WHEN type != 'RET' THEN benefices       ELSE 0 END), 0) AS benefice,
                COALESCE(SUM(CASE WHEN type != 'RET' THEN remise          ELSE 0 END), 0) AS remise_total,
                COALESCE(SUM(CASE WHEN type != 'RET' THEN total           ELSE 0 END), 0) AS total_brut,
                COUNT(CASE WHEN type != 'RET' THEN 1 END)                               AS nb_ventes,
                COALESCE(SUM(CASE WHEN type = 'RET'  THEN total_a_payer  ELSE 0 END), 0) AS retours_montant,
                COUNT(CASE WHEN type = 'RET'  THEN 1 END)                               AS nb_retours,
                COALESCE(SUM(CASE WHEN id_client NOT IN :chifa AND type != 'RET'
                               THEN total_a_payer ELSE 0 END), 0)                       AS ca_comptoir,
                COALESCE(SUM(CASE WHEN id_client IN :chifa     AND type != 'RET'
                               THEN total_a_payer ELSE 0 END), 0)                       AS ca_chifa
            FROM sorties
            WHERE EXTRACT(YEAR  FROM date) = :annee
              AND EXTRACT(MONTH FROM date) = :mois
        ),
        l AS (
            SELECT
                COUNT(*)                                                                  AS nb_lignes,
                COALESCE(SUM(
                    CASE WHEN famille ILIKE '%complement%' OR famille ILIKE '%paramedic%'
                         THEN qte_sortie * prix_vente ELSE 0 END
                ), 0)                                                                     AS ca_compl
            FROM sorties_produits
            WHERE EXTRACT(YEAR  FROM date) = :annee
              AND EXTRACT(MONTH FROM date) = :mois
              AND type_sortie != 'RET'
        )
        SELECT
            v.ca, v.benefice, v.remise_total, v.total_brut,
            v.nb_ventes, v.retours_montant, v.nb_retours,
            v.ca_comptoir, v.ca_chifa,
            l.nb_lignes, l.ca_compl,
            CASE WHEN v.nb_ventes > 0 THEN v.ca / v.nb_ventes ELSE 0 END AS panier_moyen,
            CASE WHEN v.total_brut > 0 THEN v.remise_total / v.total_brut * 100 ELSE 0 END AS taux_remise
        FROM v, l
    """), {"annee": annee, "mois": mois, "chifa": _CHIFA})

    row = r.mappings().first()
    if not row:
        return {}

    return {
        "ca_realise":         {"valeur": float(row["ca"] or 0),              "unite": "DA"},
        "benefice_brut":      {"valeur": float(row["benefice"] or 0),        "unite": "DA"},
        "nb_ventes":          {"valeur": int(row["nb_ventes"] or 0),         "unite": ""},
        "nb_lignes":          {"valeur": int(row["nb_lignes"] or 0),         "unite": ""},
        "panier_moyen":       {"valeur": float(row["panier_moyen"] or 0),    "unite": "DA"},
        "taux_remise":        {"valeur": float(row["taux_remise"] or 0),     "unite": "%"},
        "retours_montant":    {"valeur": float(row["retours_montant"] or 0), "unite": "DA"},
        "nb_retours":         {"valeur": int(row["nb_retours"] or 0),        "unite": ""},
        "ca_comptoir":        {"valeur": float(row["ca_comptoir"] or 0),     "unite": "DA"},
        "ca_chifa":           {"valeur": float(row["ca_chifa"] or 0),        "unite": "DA"},
        "ca_complement_alim": {"valeur": float(row["ca_compl"] or 0),        "unite": "DA"},
    }


# ── Recouvrement ──────────────────────────────────────────────────────────────

@router.get("/recouvrement/{annee}/{mois}")
async def kpis_recouvrement(
    annee: int,
    mois: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Créances = sorties non soldées sur clients hors Chifa.
    Encaissements = opérations 'Versement client' du mois.
    Vieillissement par tranches 30 / 90 / 180 jours.
    """
    # ── Créances (toutes dates, non soldées) ─────────────────────────────────
    cr = await db.execute(text("""
        SELECT
            COALESCE(SUM(
                GREATEST(s.total_a_payer - s.versement - COALESCE(s.reglement_ult, 0), 0)
            ), 0)                                                                     AS creances_total,

            COUNT(DISTINCT s.id_client) FILTER (
                WHERE GREATEST(s.total_a_payer - s.versement
                               - COALESCE(s.reglement_ult, 0), 0) > 0
            )                                                                         AS nb_clients_debiteurs,

            -- Créances émises ce mois (pour taux de recouvrement mensuel)
            COALESCE(SUM(
                GREATEST(s.total_a_payer - s.versement - COALESCE(s.reglement_ult, 0), 0)
            ) FILTER (
                WHERE EXTRACT(YEAR  FROM s.date) = :annee
                  AND EXTRACT(MONTH FROM s.date) = :mois
            ), 0)                                                                     AS creances_mois,

            -- Vieillissement
            COALESCE(SUM(
                GREATEST(s.total_a_payer - s.versement - COALESCE(s.reglement_ult, 0), 0)
            ) FILTER (WHERE s.date < CURRENT_DATE - INTERVAL '30 days'), 0)          AS creances_30j,

            COALESCE(SUM(
                GREATEST(s.total_a_payer - s.versement - COALESCE(s.reglement_ult, 0), 0)
            ) FILTER (WHERE s.date < CURRENT_DATE - INTERVAL '90 days'), 0)          AS creances_90j,

            COALESCE(SUM(
                GREATEST(s.total_a_payer - s.versement - COALESCE(s.reglement_ult, 0), 0)
            ) FILTER (WHERE s.date < CURRENT_DATE - INTERVAL '180 days'), 0)         AS creances_180j
        FROM sorties s
        WHERE s.id_client NOT IN :chifa
          AND s.type != 'RET'
          AND s.versement < s.total_a_payer
    """), {"annee": annee, "mois": mois, "chifa": _CHIFA})

    cr_row = cr.mappings().first()

    # ── Opérations financières du mois ────────────────────────────────────────
    op = await db.execute(text("""
        SELECT
            COALESCE(SUM(o.montant) FILTER (
                WHERE o.operation ILIKE '%versement%client%'
            ), 0)                                    AS encaissements,
            COALESCE(SUM(o.montant) FILTER (
                WHERE o.operation ILIKE '%remboursement%client%'
            ), 0)                                    AS remboursements
        FROM operations o
        WHERE EXTRACT(YEAR  FROM o.date) = :annee
          AND EXTRACT(MONTH FROM o.date) = :mois
    """), {"annee": annee, "mois": mois})

    op_row = op.mappings().first()

    creances_total = float(cr_row["creances_total"] or 0)
    creances_mois  = float(cr_row["creances_mois"] or 0)
    encaissements  = float(op_row["encaissements"] or 0)

    # Taux de recouvrement = encaissements mois / créances émises ce mois
    taux = round(encaissements / creances_mois * 100, 2) if creances_mois > 0 else 0

    return {
        "creances_total":         {"valeur": creances_total,                                   "unite": "DA"},
        "encaissements_mois":     {"valeur": encaissements,                                    "unite": "DA"},
        "taux_recouvrement":      {"valeur": taux,                                             "unite": "%"},
        "nb_clients_debiteurs":   {"valeur": int(cr_row["nb_clients_debiteurs"] or 0),         "unite": ""},
        "creances_30j":           {"valeur": float(cr_row["creances_30j"] or 0),               "unite": "DA"},
        "creances_90j":           {"valeur": float(cr_row["creances_90j"] or 0),               "unite": "DA"},
        "creances_180j":          {"valeur": float(cr_row["creances_180j"] or 0),              "unite": "DA"},
        "remboursements_clients": {"valeur": float(op_row["remboursements"] or 0),             "unite": "DA"},
    }


# ── Stock ─────────────────────────────────────────────────────────────────────

@router.get("/stock")
async def kpis_stock(
    employe_id: Optional[int] = Query(None, description="Filtrer par employé responsable"),
    famille: Optional[str] = Query(None, description="Filtrer par famille"),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    KPIs stock temps réel.
    Avec employe_id : restreint aux produits dont la classification est assignée à cet employé.
    Avec famille    : restreint aux produits de cette famille.
    """
    params: dict = {}
    id_conditions = ["n.archive = false"]
    join_classif = ""

    if employe_id is not None:
        join_classif = """
            JOIN nomenclature_classification nc ON (
                (nc.niveau = 2 AND LEFT(n.de_equiv, 2) || ' ' || SUBSTR(n.de_equiv, 3, 1) = nc.prefix)
                OR (nc.niveau = 1 AND LEFT(n.de_equiv, 2) = nc.prefix)
            )
        """
        id_conditions.append("nc.employe_id = :employe_id")
        params["employe_id"] = employe_id

    if famille:
        id_conditions.append("n.famille = :famille")
        params["famille"] = famille

    id_where = " AND ".join(id_conditions)

    r = await db.execute(text(f"""
        WITH filtered_ids AS (
            SELECT DISTINCT n.id
            FROM nomenclature n
            {join_classif}
            WHERE {id_where}
        ),
        ventes_moy AS (
            SELECT id_nom, SUM(qte_sortie) / 12.0 AS avg_monthly
            FROM sorties_produits
            WHERE date >= CURRENT_DATE - INTERVAL '12 months'
              AND type_sortie NOT IN ('RET', 'AV')
              AND id_nom IN (SELECT id FROM filtered_ids)
            GROUP BY id_nom
        ),
        stock_agg AS (
            SELECT
                COUNT(*) FILTER (WHERE COALESCE(mv.stock_actuel, 0) = 0)                            AS nb_ruptures,
                COUNT(*) FILTER (
                    WHERE n.qte_alerte > 0
                      AND mv.stock_actuel > 0
                      AND mv.stock_actuel < n.qte_alerte
                )                                                                                    AS nb_alertes,
                COUNT(*) FILTER (WHERE COALESCE(mv.stock_actuel, 0) > 0)                            AS nb_references,
                COUNT(*) FILTER (
                    WHERE COALESCE(vm.avg_monthly, 0) > 0
                      AND COALESCE(mv.stock_actuel, 0) > vm.avg_monthly * 6
                )                                                                                    AS nb_surstock,
                COALESCE(SUM(mv.stock_actuel * mv.prix_moyen_pondere), 0)                           AS valeur_stock
            FROM filtered_ids fi
            JOIN nomenclature n ON n.id = fi.id
            LEFT JOIN mv_stock_produits mv ON mv.id_nom = fi.id
            LEFT JOIN ventes_moy vm ON vm.id_nom = fi.id
        ),
        lots_agg AS (
            SELECT
                COUNT(*) FILTER (
                    WHERE ep.peremption_date IS NOT NULL
                      AND ep.peremption_date > CURRENT_DATE
                      AND ep.peremption_date <= CURRENT_DATE + INTERVAL '90 days'
                      AND ep.stock > 0 AND ep.bloque = 0
                )                                                                                    AS nb_perems_3m,
                COUNT(*) FILTER (
                    WHERE ep.peremption_date IS NOT NULL
                      AND ep.peremption_date > CURRENT_DATE
                      AND ep.peremption_date <= CURRENT_DATE + INTERVAL '180 days'
                      AND ep.stock > 0 AND ep.bloque = 0
                )                                                                                    AS nb_perems_6m,
                COUNT(*) FILTER (WHERE ep.bloque = 1 AND ep.stock > 0)                             AS nb_bloques,
                COALESCE(SUM(ep.stock * ep.prix_achat) FILTER (
                    WHERE ep.peremption_date IS NOT NULL
                      AND ep.peremption_date > CURRENT_DATE
                      AND ep.peremption_date <= CURRENT_DATE + INTERVAL '90 days'
                      AND ep.stock > 0
                ), 0)                                                                                AS valeur_risque
            FROM entrees_produits ep
            WHERE ep.id_nom IN (SELECT id FROM filtered_ids)
        )
        SELECT s.*, l.* FROM stock_agg s, lots_agg l
    """), params)

    row = r.mappings().first()
    if not row:
        return {}

    return {
        "valeur_stock":     {"valeur": float(row["valeur_stock"] or 0),  "unite": "DA"},
        "nb_ruptures":      {"valeur": int(row["nb_ruptures"] or 0),     "unite": ""},
        "nb_alertes":       {"valeur": int(row["nb_alertes"] or 0),      "unite": ""},
        "nb_references":    {"valeur": int(row["nb_references"] or 0),   "unite": ""},
        "nb_peremption_3m": {"valeur": int(row["nb_perems_3m"] or 0),    "unite": ""},
        "nb_peremption_6m": {"valeur": int(row["nb_perems_6m"] or 0),    "unite": ""},
        "nb_lots_bloques":  {"valeur": int(row["nb_bloques"] or 0),      "unite": ""},
        "valeur_perimes":   {"valeur": float(row["valeur_risque"] or 0), "unite": "DA"},
        "nb_surstock":      {"valeur": int(row["nb_surstock"] or 0),     "unite": ""},
    }


# ── Achats ────────────────────────────────────────────────────────────────────

@router.get("/achats/{annee}/{mois}")
async def kpis_achats(
    annee: int,
    mois: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    r = await db.execute(text("""
        WITH e AS (
            SELECT
                COALESCE(SUM(CASE WHEN type NOT IN ('AVO','RET') THEN total_ttc          ELSE 0 END), 0) AS ca_achats,
                COUNT(   CASE WHEN type NOT IN ('AVO','RET') THEN 1 END)                               AS nb_bl,
                COUNT(DISTINCT CASE WHEN type NOT IN ('AVO','RET') THEN id_fournisseur END)            AS nb_fournisseurs,
                COALESCE(SUM(CASE WHEN type IN ('AVO')             THEN total_ttc          ELSE 0 END), 0) AS avoirs,
                COALESCE(SUM(
                    GREATEST(total_a_payer - COALESCE(reglement, 0), 0)
                ) FILTER (WHERE type NOT IN ('AVO','RET')), 0)                                         AS dettes
            FROM entrees
            WHERE EXTRACT(YEAR  FROM date) = :annee
              AND EXTRACT(MONTH FROM date) = :mois
        ),
        p AS (
            SELECT
                COALESCE(SUM(o.montant) FILTER (
                    WHERE o.operation ILIKE '%versement%fournisseur%'
                ), 0) AS paiements
            FROM operations o
            WHERE EXTRACT(YEAR  FROM o.date) = :annee
              AND EXTRACT(MONTH FROM o.date) = :mois
        )
        SELECT
            e.ca_achats, e.nb_bl, e.nb_fournisseurs, e.avoirs, e.dettes, p.paiements,
            CASE WHEN e.nb_bl > 0 THEN e.ca_achats / e.nb_bl ELSE 0 END AS panier_moyen_achat
        FROM e, p
    """), {"annee": annee, "mois": mois})

    row = r.mappings().first()
    if not row:
        return {}

    return {
        "ca_achats":              {"valeur": float(row["ca_achats"] or 0),           "unite": "DA"},
        "nb_bons_livraison":      {"valeur": int(row["nb_bl"] or 0),                 "unite": ""},
        "nb_fournisseurs_actifs": {"valeur": int(row["nb_fournisseurs"] or 0),       "unite": ""},
        "panier_moyen_achat":     {"valeur": float(row["panier_moyen_achat"] or 0),  "unite": "DA"},
        "dettes_fournisseurs":    {"valeur": float(row["dettes"] or 0),              "unite": "DA"},
        "paiements_fournisseurs": {"valeur": float(row["paiements"] or 0),           "unite": "DA"},
        "avoirs_fournisseurs":    {"valeur": float(row["avoirs"] or 0),              "unite": "DA"},
    }
