"""
CRM endpoints — Analyse clients, segmentation, rappels
"""
from typing import Optional
from datetime import date
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

from app.core.database import get_db
from app.core.security import get_current_user

router = APIRouter(prefix="/crm", tags=["crm"])


def _classe_filter_sql(classe: str, no_assure_ref: str = 'c.n_assure_chifa') -> str:
    """
    Génère un EXISTS(...) qui vérifie que le client a au moins une facture CHIFA
    avec un médicament de la classe donnée ET duree_trt >= 60 jours.
    Même logique que le sync patients_chifa (chifa.py).
    """
    txt_regex = r"\[a\[a\[(.*)\]a\]a\]"
    _base_lateral = (
        "    FROM factures_chifa f,\n"
        "    LATERAL (\n"
        "        SELECT TRIM(split_part(dr, '|', 1))  AS id_cnas,\n"
        "               TRIM(split_part(dr, '|', 12)) AS duree_str\n"
        "        FROM unnest(string_to_array(\n"
        f"            substring(f.txt_prod FROM '{txt_regex}'), '}}'\n"
        "        )) AS dr\n"
        "    ) d\n"
        "    JOIN nomenclature n\n"
        "        ON LPAD(n.id_cnas::text, 5, '0') = d.id_cnas\n"
        "       AND n.de_equiv IS NOT NULL AND n.de_equiv != ''\n"
        "    JOIN nomenclature_classification nc\n"
        "        ON nc.prefix = SUBSTRING(n.de_equiv, 1, 2) || ' ' || SUBSTRING(n.de_equiv, 3, 1)\n"
    )
    _base_where = (
        f"    WHERE f.no_assure = {no_assure_ref}\n"
        "      AND f.annule = 0\n"
        "      AND d.duree_str ~ '^[0-9]+$'\n"
        "      AND d.duree_str::integer >= 60\n"
    )

    # Classe 05 : anticancéreux — pas d'entrée dans classe_maladie, filtre direct sur nc.prefix
    if classe == '05':
        return (
            "EXISTS (\n"
            "    SELECT 1\n"
            + _base_lateral
            + _base_where
            + "      AND nc.prefix LIKE '05 %'\n"
            ")"
        )

    _CARDIO_COND = (
        "EXISTS (SELECT 1 FROM maladies_chroniques mc2 "
        "WHERE mc2.code = cm.code_maladie AND mc2.specialite = 'Cardiologie')"
    )
    _PREFIX_COND: dict[str, str] = {
        '14B':    "cm.prefix = '14 B'",
        '15G':    "cm.prefix = '15 G'",
        '20A':    "cm.prefix = '20 A'",
        '16':     "cm.prefix LIKE '16 _'",
        'cardio': _CARDIO_COND,
    }
    prefix_cond = _PREFIX_COND.get(classe)
    if not prefix_cond:
        return "FALSE"

    return (
        "EXISTS (\n"
        "    SELECT 1\n"
        + _base_lateral
        + "    JOIN classe_maladie cm ON cm.prefix = nc.prefix\n"
        + _base_where
        + f"      AND {prefix_cond}\n"
        ")"
    )


def _f(v) -> float:
    return float(v) if v is not None else 0.0


# ── Dashboard KPIs ─────────────────────────────────────────────────────────────

@router.get("/dashboard")
async def crm_dashboard(
    annee: Optional[int] = Query(None),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    KPIs CRM globaux :
    - total clients, actifs (6 mois), inactifs, nouveaux (90j)
    - taux rétention et churn (année N vs N-1)
    - total CA global
    """
    from datetime import date as date_cls
    today = date_cls.today()
    a = annee or today.year

    res = await db.execute(text("""
        WITH stats AS (
            SELECT
                COUNT(DISTINCT s.id_client)
                    FILTER (WHERE s.date >= CURRENT_DATE - INTERVAL '6 months')  AS nb_actifs,
                COUNT(DISTINCT s.id_client)
                    FILTER (WHERE s.date >= CURRENT_DATE - INTERVAL '90 days')   AS nb_nouveaux_90j,
                SUM(s.total_a_payer)
                    FILTER (WHERE s.type != 'A')                                  AS ca_total
            FROM sorties s
            WHERE s.type != 'A'
        ),
        total_c AS (SELECT COUNT(*) AS nb FROM clients WHERE is_archive IS NOT TRUE),
        -- Rétention : clients vus en N-1 qui reviennent en N
        prev_year AS (
            SELECT DISTINCT id_client FROM sorties
            WHERE EXTRACT(YEAR FROM date) = :annee - 1 AND type != 'A'
        ),
        curr_year AS (
            SELECT DISTINCT id_client FROM sorties
            WHERE EXTRACT(YEAR FROM date) = :annee AND type != 'A'
        ),
        retention AS (
            SELECT COUNT(*) AS nb_retained FROM prev_year p
            WHERE EXISTS (SELECT 1 FROM curr_year c WHERE c.id_client = p.id_client)
        ),
        prev_count AS (SELECT COUNT(*) AS nb FROM prev_year),
        -- Comparaison annuelle N vs N-1 (hors clients archivés)
        annuel AS (
            SELECT
                COALESCE(SUM(s.total_a_payer) FILTER (WHERE EXTRACT(YEAR FROM s.date) = :annee),     0) AS ca_n,
                COALESCE(SUM(s.total_a_payer) FILTER (WHERE EXTRACT(YEAR FROM s.date) = :annee - 1), 0) AS ca_prev,
                COUNT(DISTINCT s.id_client) FILTER (WHERE EXTRACT(YEAR FROM s.date) = :annee)           AS nb_n,
                COUNT(DISTINCT s.id_client) FILTER (WHERE EXTRACT(YEAR FROM s.date) = :annee - 1)       AS nb_prev_ann
            FROM sorties s
            LEFT JOIN clients c ON c.id = s.id_client
            WHERE s.type != 'A' AND c.is_archive IS NOT TRUE
        )
        SELECT
            total_c.nb                                                   AS nb_total,
            stats.nb_actifs                                              AS nb_actifs,
            total_c.nb - COALESCE(stats.nb_actifs, 0)                   AS nb_inactifs,
            stats.nb_nouveaux_90j                                        AS nb_nouveaux,
            stats.ca_total                                               AS ca_total,
            prev_count.nb                                                AS nb_prev_year,
            retention.nb_retained                                        AS nb_retained,
            annuel.ca_n, annuel.ca_prev, annuel.nb_n, annuel.nb_prev_ann
        FROM stats, total_c, retention, prev_count, annuel
    """), {"annee": a})

    row = res.fetchone()
    nb_prev = int(row.nb_prev_year or 0)
    nb_ret  = int(row.nb_retained  or 0)
    taux_retention = round(nb_ret / nb_prev * 100, 1) if nb_prev > 0 else 0.0
    taux_churn     = round(100 - taux_retention, 1)

    ca_n        = _f(row.ca_n)
    ca_prev     = _f(row.ca_prev)
    nb_n        = int(row.nb_n or 0)
    nb_prev_ann = int(row.nb_prev_ann or 0)
    delta_ca    = round((ca_n - ca_prev) / ca_prev * 100, 1) if ca_prev > 0 else None
    delta_nb    = round((nb_n - nb_prev_ann) / nb_prev_ann * 100, 1) if nb_prev_ann > 0 else None

    return {
        "nb_total":          int(row.nb_total    or 0),
        "nb_actifs":         int(row.nb_actifs   or 0),
        "nb_inactifs":       int(row.nb_inactifs or 0),
        "nb_nouveaux":       int(row.nb_nouveaux or 0),
        "ca_total":          _f(row.ca_total),
        "taux_retention":    taux_retention,
        "taux_churn":        taux_churn,
        "annee":             a,
        "ca_annee":          ca_n,
        "ca_prev":           ca_prev,
        "delta_ca_pct":      delta_ca,
        "nb_clients_annee":  nb_n,
        "nb_clients_prev":   nb_prev_ann,
        "delta_nb_pct":      delta_nb,
    }


# ── Évolution mensuelle ────────────────────────────────────────────────────────

@router.get("/evolution")
async def crm_evolution(
    annee: Optional[int] = Query(None, description="Année (défaut : année courante)"),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Évolution mensuelle : clients uniques et CA sur les 12 mois de l'année."""
    from datetime import date as _date
    year = annee or _date.today().year
    rows = (await db.execute(text("""
        SELECT
            TO_CHAR(DATE_TRUNC('month', s.date), 'YYYY-MM') AS mois,
            COUNT(DISTINCT s.id_client)                      AS nb_clients,
            COALESCE(SUM(s.total_a_payer), 0)                AS ca
        FROM sorties s
        WHERE s.type != 'A'
          AND EXTRACT(YEAR FROM s.date) = :annee
        GROUP BY DATE_TRUNC('month', s.date)
        ORDER BY DATE_TRUNC('month', s.date)
    """), {"annee": year})).fetchall()

    return [
        {"mois": r.mois, "nb_clients": int(r.nb_clients), "ca": _f(r.ca)}
        for r in rows
    ]


# ── Top 10 clients ─────────────────────────────────────────────────────────────

@router.get("/top-clients")
async def crm_top_clients(
    annee: Optional[int] = Query(None),
    limite: int = Query(10, ge=5, le=50),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Top clients par CA généré sur l'année."""
    from datetime import date as date_cls
    a = annee or date_cls.today().year

    rows = (await db.execute(text("""
        WITH linked AS (
            -- Each sortie attributed to its real client (prefer n_assure match over id_client)
            SELECT DISTINCT ON (s.id)
                s.id, s.total_a_payer, s.date, c.id AS client_id
            FROM sorties s
            JOIN clients c ON (
                s.id_client = c.id
                OR (c.n_assure_chifa IS NOT NULL AND c.n_assure_chifa != ''
                    AND s.n_assure = c.n_assure_chifa)
            )
            WHERE s.type != 'A'
              AND EXTRACT(YEAR FROM s.date) = :annee
            ORDER BY s.id,
                (c.n_assure_chifa IS NOT NULL AND c.n_assure_chifa != ''
                 AND s.n_assure = c.n_assure_chifa) DESC
        )
        SELECT
            c.id,
            c.client,
            c.telephone,
            c.ville,
            c.chronique,
            COALESCE(SUM(l.total_a_payer), 0)  AS ca_total,
            COUNT(DISTINCT l.id)                AS nb_achats,
            MAX(l.date)                         AS derniere_visite
        FROM clients c
        JOIN linked l ON l.client_id = c.id
        WHERE c.is_archive IS NOT TRUE
          AND c.client NOT ILIKE 'CNAS%'
          AND c.client NOT ILIKE 'CASNOS%'
          AND c.client NOT ILIKE 'HORS CHIFA%'
          AND c.client NOT ILIKE 'HORS-CHIFA%'
        GROUP BY c.id, c.client, c.telephone, c.ville, c.chronique
        ORDER BY ca_total DESC
        LIMIT :limite
    """), {"annee": a, "limite": limite})).fetchall()

    return [
        {
            "id":             r.id,
            "client":         r.client,
            "telephone":      r.telephone,
            "ville":          r.ville,
            "chronique":      bool(r.chronique),
            "ca_total":       _f(r.ca_total),
            "nb_achats":      int(r.nb_achats),
            "derniere_visite": r.derniere_visite.isoformat() if r.derniere_visite else None,
        }
        for r in rows
    ]


# ── Segmentation ───────────────────────────────────────────────────────────────

@router.get("/segmentation")
async def crm_segmentation(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Répartition des patients CHIFA par segment d'activité.
    Base : patients_chifa (assuré + ayants-droit).
    VIP est un badge indépendant (nb_vip par segment).
    Segments (non-exclusifs avec VIP) :
      actif      → dernière visite < 6 mois, ≥4 visites/an
      nouveau    → première visite < 90 jours
      dormant    → dernière visite 6–18 mois
      perdu      → dernière visite > 18 mois
      occasionnel → < 4 visites/an mais actif
      sans_achat → aucune vente liée
    """
    # CTE commune : historique par patient_chifa (no_assure, rang_ad)
    # Le lien sorties → patient se fait via sorties.n_assure = patients_chifa.no_assure
    _SEG_BASE = """
        patient_hist AS (
            SELECT
                p.no_assure, p.rang_ad,
                MAX(s.date)  AS derniere_visite,
                MIN(s.date)  AS premiere_visite,
                COUNT(DISTINCT CASE WHEN s.date >= CURRENT_DATE - INTERVAL '12 months'
                                    THEN s.id END)            AS nb_12m,
                SUM(CASE WHEN s.date >= CURRENT_DATE - INTERVAL '12 months'
                         THEN s.total_a_payer ELSE 0 END)     AS ca_12m
            FROM patients_chifa p
            LEFT JOIN (
                -- Ventes CHIFA : rang_ad identifié via factures_chifa
                SELECT s.id, s.date, s.total_a_payer, s.n_assure,
                       COALESCE(f.rang_ad, '00') AS sale_rang
                FROM sorties s
                LEFT JOIN factures_chifa f ON f.no_facture = s.no_facture_chifa
                WHERE s.type != 'A'
                  AND s.no_facture_chifa IS NOT NULL AND s.no_facture_chifa != ''
                UNION ALL
                -- Ventes comptoir (pas de facture CHIFA) : attribuées à l'assuré principal
                SELECT s.id, s.date, s.total_a_payer, s.n_assure, '00' AS sale_rang
                FROM sorties s
                WHERE s.type != 'A'
                  AND (s.no_facture_chifa IS NULL OR s.no_facture_chifa = '')
            ) s ON s.n_assure = p.no_assure AND s.sale_rang = p.rang_ad
            WHERE NOT EXISTS (
                SELECT 1 FROM clients c
                WHERE c.n_assure_chifa = p.no_assure AND c.is_archive IS TRUE
            )
            GROUP BY p.no_assure, p.rang_ad
        ),
        seuil AS (
            SELECT PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY ca_12m) AS p90
            FROM patient_hist WHERE ca_12m > 0
        )
    """

    rows = (await db.execute(text(f"""
        WITH {_SEG_BASE},
        classified AS (
            SELECT
                CASE
                    WHEN h.derniere_visite IS NULL
                        THEN 'sans_achat'
                    WHEN h.derniere_visite < CURRENT_DATE - INTERVAL '18 months'
                        THEN 'perdu'
                    WHEN h.derniere_visite < CURRENT_DATE - INTERVAL '6 months'
                        THEN 'dormant'
                    WHEN h.premiere_visite >= CURRENT_DATE - INTERVAL '90 days'
                        THEN 'nouveau'
                    WHEN h.nb_12m >= 4
                        THEN 'actif'
                    ELSE 'occasionnel'
                END AS segment,
                COALESCE(h.ca_12m >= se.p90 AND h.nb_12m >= 12, FALSE) AS is_vip,
                COALESCE(h.ca_12m, 0) AS ca_12m
            FROM patients_chifa p
            LEFT JOIN patient_hist h  ON h.no_assure = p.no_assure AND h.rang_ad = p.rang_ad
            CROSS JOIN seuil se
        )
        SELECT segment,
               COUNT(*)                                               AS nb,
               COUNT(*) FILTER (WHERE is_vip)                        AS nb_vip,
               COALESCE(SUM(ca_12m), 0)                              AS ca_total,
               COALESCE(AVG(ca_12m) FILTER (WHERE ca_12m > 0), 0)   AS ca_moyen
        FROM classified
        GROUP BY segment
        ORDER BY nb DESC
    """))).fetchall()

    return [
        {
            "segment":  r.segment,
            "nb":       int(r.nb),
            "nb_vip":   int(r.nb_vip),
            "ca_total": _f(r.ca_total),
            "ca_moyen": _f(r.ca_moyen),
        }
        for r in rows
    ]


@router.get("/segmentation/clients")
async def crm_segmentation_clients(
    segment: str = Query(...),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    # Rang : true=assuré principal (rang_ad='00'), false=ayant-droit
    assure: Optional[bool] = Query(None, description="true=assuré (rang 00), false=ayant-droit"),
    avec_credit: Optional[bool] = Query(None),
    vip: Optional[bool] = Query(None, description="true=VIP uniquement, false=non-VIP"),
    classe: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Liste des patients CHIFA d'un segment, avec filtres combinables."""
    # NOTE: conditions are applied in the outer SELECT * FROM classified WHERE ...
    # so only exported column names are valid (no table-alias prefixes).
    extra_where: list[str] = []

    if assure is True:
        extra_where.append("rang_ad = '00'")
    elif assure is False:
        extra_where.append("rang_ad != '00'")

    if avec_credit is True:
        extra_where.append("credit > 0")
    elif avec_credit is False:
        extra_where.append("(credit IS NULL OR credit <= 0)")

    if vip is True:
        extra_where.append("is_vip = TRUE")
    elif vip is False:
        extra_where.append("is_vip = FALSE")

    # The ALD class EXISTS subquery uses p.no_assure — it must be embedded INSIDE
    # the classified CTE (where p is in scope) rather than in the outer WHERE,
    # otherwise bare 'no_assure' would resolve to factures_chifa.no_assure.
    if classe:
        ald_col = (
            ",\n        "
            + _classe_filter_sql(classe, no_assure_ref='p.no_assure')
            + " AS has_ald_classe"
        )
        extra_where.append("has_ald_classe = TRUE")
    else:
        ald_col = ""

    extra_sql = (" AND " + " AND ".join(extra_where)) if extra_where else ""

    _SEG_BASE = """
        patient_hist AS (
            SELECT
                p.no_assure, p.rang_ad,
                MAX(s.date)  AS derniere_visite,
                MIN(s.date)  AS premiere_visite,
                COUNT(DISTINCT CASE WHEN s.date >= CURRENT_DATE - INTERVAL '12 months'
                                    THEN s.id END)            AS nb_12m,
                SUM(CASE WHEN s.date >= CURRENT_DATE - INTERVAL '12 months'
                         THEN s.total_a_payer ELSE 0 END)     AS ca_12m
            FROM patients_chifa p
            LEFT JOIN (
                -- Ventes CHIFA : rang_ad identifié via factures_chifa
                SELECT s.id, s.date, s.total_a_payer, s.n_assure,
                       COALESCE(f.rang_ad, '00') AS sale_rang
                FROM sorties s
                LEFT JOIN factures_chifa f ON f.no_facture = s.no_facture_chifa
                WHERE s.type != 'A'
                  AND s.no_facture_chifa IS NOT NULL AND s.no_facture_chifa != ''
                UNION ALL
                -- Ventes comptoir (pas de facture CHIFA) : attribuées à l'assuré principal
                SELECT s.id, s.date, s.total_a_payer, s.n_assure, '00' AS sale_rang
                FROM sorties s
                WHERE s.type != 'A'
                  AND (s.no_facture_chifa IS NULL OR s.no_facture_chifa = '')
            ) s ON s.n_assure = p.no_assure AND s.sale_rang = p.rang_ad
            WHERE NOT EXISTS (
                SELECT 1 FROM clients c
                WHERE c.n_assure_chifa = p.no_assure AND c.is_archive IS TRUE
            )
            GROUP BY p.no_assure, p.rang_ad
        ),
        seuil AS (
            SELECT PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY ca_12m) AS p90
            FROM patient_hist WHERE ca_12m > 0
        )
    """

    _classified_cols = f"""
        c.id AS client_id,
        p.no_assure, p.rang_ad,
        CASE
            WHEN p.rang_ad = '00' THEN COALESCE(c.client, p.no_assure)
            WHEN p.rang_ad = '80' THEN COALESCE(c.client, p.no_assure) || ' - Conj.'
            ELSE COALESCE(c.client, p.no_assure) || ' - ' || p.rang_ad
        END AS display_name,
        c.telephone, c.ville, c.credit,
        h.derniere_visite, h.ca_12m, h.nb_12m,
        COALESCE(h.ca_12m >= se.p90 AND h.nb_12m >= 12, FALSE) AS is_vip,
        CASE
            WHEN h.derniere_visite IS NULL                               THEN 'sans_achat'
            WHEN h.derniere_visite < CURRENT_DATE - INTERVAL '18 months' THEN 'perdu'
            WHEN h.derniere_visite < CURRENT_DATE - INTERVAL '6 months'  THEN 'dormant'
            WHEN h.premiere_visite >= CURRENT_DATE - INTERVAL '90 days'  THEN 'nouveau'
            WHEN h.nb_12m >= 4                                           THEN 'actif'
            ELSE 'occasionnel'
        END AS segment{ald_col}
    """

    _from_join = """
        FROM patients_chifa p
        LEFT JOIN clients c ON c.n_assure_chifa = p.no_assure
        LEFT JOIN patient_hist h  ON h.no_assure = p.no_assure AND h.rang_ad = p.rang_ad
        CROSS JOIN seuil se
    """

    rows = (await db.execute(text(f"""
        WITH {_SEG_BASE},
        classified AS (SELECT {_classified_cols} {_from_join})
        SELECT * FROM classified
        WHERE segment = :segment {extra_sql}
        ORDER BY COALESCE(ca_12m, 0) DESC
        LIMIT :limit OFFSET :offset
    """), {"segment": segment, "limit": limit, "offset": offset})).fetchall()

    total = (await db.execute(text(f"""
        WITH {_SEG_BASE},
        classified AS (
            SELECT p.no_assure, p.rang_ad, c.credit, h.ca_12m, h.nb_12m,
                   h.derniere_visite, h.premiere_visite,
                   COALESCE(h.ca_12m >= se.p90 AND h.nb_12m >= 12, FALSE) AS is_vip,
                   CASE
                       WHEN h.derniere_visite IS NULL                               THEN 'sans_achat'
                       WHEN h.derniere_visite < CURRENT_DATE - INTERVAL '18 months' THEN 'perdu'
                       WHEN h.derniere_visite < CURRENT_DATE - INTERVAL '6 months'  THEN 'dormant'
                       WHEN h.premiere_visite >= CURRENT_DATE - INTERVAL '90 days'  THEN 'nouveau'
                       WHEN h.nb_12m >= 4                                           THEN 'actif'
                       ELSE 'occasionnel'
                   END AS segment{ald_col}
            {_from_join}
        )
        SELECT COUNT(*) FROM classified WHERE segment = :segment {extra_sql}
    """), {"segment": segment})).scalar()

    return {
        "total": int(total or 0),
        "items": [
            {
                "client_id":       r.client_id,
                "no_assure":       r.no_assure,
                "rang_ad":         r.rang_ad,
                "display_name":    r.display_name,
                "telephone":       r.telephone,
                "ville":           r.ville,
                "is_vip":          bool(r.is_vip),
                "derniere_visite": r.derniere_visite.isoformat() if r.derniere_visite else None,
                "ca_12m":          _f(r.ca_12m),
                "nb_12m":          int(r.nb_12m or 0),
            }
            for r in rows
        ],
    }


# ── Risque churn ──────────────────────────────────────────────────────────────

@router.get("/risque-churn")
async def crm_risque_churn(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Clients à risque de churn : fidèles (≥6 visites/18 mois) mais absents
    depuis 2 à 5 mois. Fenêtre d'action avant qu'ils basculent en dormants.
    """
    rows = (await db.execute(text("""
        WITH hist AS (
            SELECT
                c.id, c.client, c.telephone, c.ville,
                MAX(s.date)                                               AS derniere_visite,
                (CURRENT_DATE - MAX(s.date))::int                        AS jours_absence,
                COUNT(DISTINCT s.id) FILTER (
                    WHERE s.date >= CURRENT_DATE - INTERVAL '18 months'
                )                                                         AS visites_18m,
                COALESCE(SUM(s.total_a_payer) FILTER (
                    WHERE s.date >= CURRENT_DATE - INTERVAL '12 months'
                ), 0)                                                     AS ca_12m
            FROM sorties s
            JOIN clients c ON c.id = s.id_client
            WHERE s.type != 'A' AND c.is_archive IS NOT TRUE
            GROUP BY c.id, c.client, c.telephone, c.ville
        )
        SELECT * FROM hist
        WHERE jours_absence BETWEEN 60 AND 150
          AND visites_18m >= 6
        ORDER BY jours_absence DESC
        LIMIT 50
    """))).fetchall()

    return [
        {
            "id":             r.id,
            "client":         r.client,
            "telephone":      r.telephone or "",
            "ville":          r.ville or "",
            "derniere_visite": r.derniere_visite.isoformat() if r.derniere_visite else None,
            "jours_absence":  int(r.jours_absence),
            "visites_18m":    int(r.visites_18m),
            "ca_12m":         _f(r.ca_12m),
        }
        for r in rows
    ]


# ── Rappels & Communication ────────────────────────────────────────────────────

@router.get("/rappels")
async def crm_rappels(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Clients à contacter groupés par type de rappel :
    - renouvellement : chroniques dont prochain_visite_est < today
    - inactifs       : dernière visite entre 3 et 6 mois (à relancer)
    - dormants       : dernière visite entre 6 et 18 mois (risque de perte)
    - anniversaires  : date_naissance ce mois-ci
    """
    # Chroniques en retard (depuis patients_chifa)
    renouvellement_rows = (await db.execute(text("""
        SELECT
            p.no_assure, p.statut,
            p.derniere_visite, p.prochain_visite_est,
            CURRENT_DATE - p.prochain_visite_est::date AS retard_jours,
            ARRAY(
                SELECT mc.maladie FROM maladies_chroniques mc
                WHERE mc.code = ANY(p.maladies)
            ) AS maladies_noms,
            c.id AS client_id, c.client, c.telephone
        FROM patients_chifa p
        LEFT JOIN clients c ON c.n_assure_chifa = p.no_assure AND p.rang_ad = '00'
        WHERE p.statut IN ('actif', 'nouveau')
          AND p.prochain_visite_est IS NOT NULL
          AND p.prochain_visite_est::date < CURRENT_DATE
          AND (c.is_archive IS NULL OR c.is_archive IS NOT TRUE)
        ORDER BY retard_jours DESC
        LIMIT 50
    """))).fetchall()

    # Clients inactifs à relancer (3-6 mois sans visite)
    inactifs_rows = (await db.execute(text("""
        SELECT
            c.id, c.client, c.telephone, c.ville,
            MAX(s.date) AS derniere_visite,
            CURRENT_DATE - MAX(s.date) AS jours_absence,
            COUNT(DISTINCT s.id) AS nb_achats_total
        FROM sorties s
        JOIN clients c ON c.id = s.id_client
        WHERE s.type != 'A' AND c.is_archive IS NOT TRUE
        GROUP BY c.id, c.client, c.telephone, c.ville
        HAVING MAX(s.date) BETWEEN CURRENT_DATE - INTERVAL '6 months'
                                AND CURRENT_DATE - INTERVAL '3 months'
        ORDER BY jours_absence DESC
        LIMIT 30
    """))).fetchall()

    # Dormants (6-18 mois)
    dormants_rows = (await db.execute(text("""
        SELECT
            c.id, c.client, c.telephone, c.ville,
            MAX(s.date) AS derniere_visite,
            CURRENT_DATE - MAX(s.date) AS jours_absence
        FROM sorties s
        JOIN clients c ON c.id = s.id_client
        WHERE s.type != 'A' AND c.is_archive IS NOT TRUE
        GROUP BY c.id, c.client, c.telephone, c.ville
        HAVING MAX(s.date) BETWEEN CURRENT_DATE - INTERVAL '18 months'
                                AND CURRENT_DATE - INTERVAL '6 months'
        ORDER BY jours_absence ASC
        LIMIT 30
    """))).fetchall()

    # Anniversaires ce mois
    anniversaires_rows = (await db.execute(text("""
        SELECT c.id, c.client, c.telephone, c.date_naissance,
               EXTRACT(YEAR FROM AGE(c.date_naissance))::int AS age
        FROM clients c
        WHERE c.date_naissance IS NOT NULL
          AND c.is_archive IS NOT TRUE
          AND EXTRACT(MONTH FROM c.date_naissance) = EXTRACT(MONTH FROM CURRENT_DATE)
        ORDER BY EXTRACT(DAY FROM c.date_naissance)
        LIMIT 20
    """))).fetchall()

    return {
        "renouvellement": [
            {
                "no_assure": r.no_assure, "statut": r.statut,
                "derniere_visite": r.derniere_visite.isoformat() if r.derniere_visite else None,
                "prochain_visite_est": r.prochain_visite_est.isoformat() if r.prochain_visite_est else None,
                "retard_jours": int(r.retard_jours) if r.retard_jours else 0,
                "maladies": r.maladies_noms or [],
                "client_id": r.client_id, "client": r.client, "telephone": r.telephone,
            }
            for r in renouvellement_rows
        ],
        "inactifs": [
            {
                "id": r.id, "client": r.client, "telephone": r.telephone, "ville": r.ville,
                "derniere_visite": r.derniere_visite.isoformat() if r.derniere_visite else None,
                "jours_absence": int(r.jours_absence) if r.jours_absence else 0,
                "nb_achats_total": int(r.nb_achats_total),
            }
            for r in inactifs_rows
        ],
        "dormants": [
            {
                "id": r.id, "client": r.client, "telephone": r.telephone, "ville": r.ville,
                "derniere_visite": r.derniere_visite.isoformat() if r.derniere_visite else None,
                "jours_absence": int(r.jours_absence) if r.jours_absence else 0,
            }
            for r in dormants_rows
        ],
        "anniversaires": [
            {
                "id": r.id, "client": r.client, "telephone": r.telephone,
                "date_naissance": r.date_naissance.isoformat() if r.date_naissance else None,
                "age": r.age,
            }
            for r in anniversaires_rows
        ],
    }


# ── Fiche client enrichie ──────────────────────────────────────────────────────

@router.get("/clients/{client_id}/fiche")
async def crm_fiche_client(
    client_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Fiche CRM complète d'un client :
    - Coordonnées, statuts, cartes chroniques
    - KPIs achats (CA total, nb visites, panier moyen, dernière visite)
    - Maladies chroniques détectées (depuis patients_chifa)
    - Dernières 10 ventes
    - Instances en cours
    """
    # Base client
    client_row = (await db.execute(text("""
        SELECT * FROM clients WHERE id = :id
    """), {"id": client_id})).fetchone()

    if not client_row:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Client introuvable")

    # KPIs achats (inclut ventes liées par n_assure = n_assure_chifa)
    n_assure = client_row.n_assure_chifa or ""
    kpis = (await db.execute(text("""
        SELECT
            COALESCE(SUM(total_a_payer), 0) AS ca_total,
            COUNT(DISTINCT id)               AS nb_achats,
            COALESCE(AVG(total_a_payer), 0)  AS panier_moyen,
            MAX(date)                         AS derniere_visite,
            MIN(date)                         AS premiere_visite,
            COALESCE(SUM(CASE WHEN date >= CURRENT_DATE - INTERVAL '12 months'
                         THEN total_a_payer ELSE 0 END), 0) AS ca_12m,
            COUNT(DISTINCT CASE WHEN date >= CURRENT_DATE - INTERVAL '12 months'
                           THEN id END)       AS nb_12m
        FROM sorties
        WHERE (id_client = :id
               OR (:n_assure != '' AND n_assure = :n_assure))
          AND type != 'A'
    """), {"id": client_id, "n_assure": n_assure})).fetchone()

    # Score RFM — percentiles globaux + scoring client
    rfm_pct = (await db.execute(text("""
        SELECT
            PERCENTILE_CONT(0.33) WITHIN GROUP (ORDER BY nb_12m) AS f_p33,
            PERCENTILE_CONT(0.67) WITHIN GROUP (ORDER BY nb_12m) AS f_p67,
            PERCENTILE_CONT(0.33) WITHIN GROUP (ORDER BY ca_12m) AS m_p33,
            PERCENTILE_CONT(0.67) WITHIN GROUP (ORDER BY ca_12m) AS m_p67
        FROM (
            SELECT id_client,
                   COUNT(DISTINCT id) FILTER (
                       WHERE date >= CURRENT_DATE - INTERVAL '12 months'
                   ) AS nb_12m,
                   COALESCE(SUM(total_a_payer) FILTER (
                       WHERE date >= CURRENT_DATE - INTERVAL '12 months'
                   ), 0) AS ca_12m
            FROM sorties
            WHERE type != 'A'
            GROUP BY id_client
        ) sub
    """))).fetchone()

    days_since = (date.today() - kpis.derniere_visite).days if kpis.derniere_visite else 999
    r_score = 3 if days_since < 30 else (2 if days_since < 90 else 1)

    nb_12m_v = int(kpis.nb_12m or 0)
    ca_12m_v = float(kpis.ca_12m or 0)
    f_p33 = float(rfm_pct.f_p33 or 0); f_p67 = float(rfm_pct.f_p67 or 1)
    m_p33 = float(rfm_pct.m_p33 or 0); m_p67 = float(rfm_pct.m_p67 or 1)

    f_score = 3 if nb_12m_v >= f_p67 else (2 if nb_12m_v >= f_p33 else 1)
    m_score = 3 if ca_12m_v >= m_p67 else (2 if ca_12m_v >= m_p33 else 1)
    rfm_total = r_score + f_score + m_score
    rfm_label = (
        "Champion"  if rfm_total >= 8 else
        "Fidèle"    if rfm_total >= 6 else
        "Potentiel" if rfm_total >= 4 else
        "À risque"
    )

    # Maladies chroniques depuis patients_chifa
    # Le segment est calculé en temps réel depuis sorties (même logique que /segmentation/clients)
    # pour éviter le décalage avec patients_chifa.statut (valeur du dernier sync).
    chifa_row = None
    if client_row.n_assure_chifa:
        chifa_row = (await db.execute(text("""
            SELECT
                p.statut, p.maladies, p.specialites, p.nb_visites,
                p.premiere_visite, p.derniere_visite, p.prochain_visite_est,
                p.intervalle_moyen, p.mt_total_assure, p.mt_total_officine,
                ARRAY(
                    SELECT mc.maladie FROM maladies_chroniques mc
                    WHERE mc.code = ANY(p.maladies)
                ) AS maladies_noms,
                -- Segment live : même CASE que patient_hist dans la segmentation
                CASE
                    WHEN live.derniere_visite_live IS NULL
                        THEN 'sans_achat'
                    WHEN live.derniere_visite_live < CURRENT_DATE - INTERVAL '18 months'
                        THEN 'perdu'
                    WHEN live.derniere_visite_live < CURRENT_DATE - INTERVAL '6 months'
                        THEN 'dormant'
                    WHEN live.premiere_visite_live >= CURRENT_DATE - INTERVAL '90 days'
                        THEN 'nouveau'
                    WHEN COALESCE(live.nb_12m, 0) >= 4
                        THEN 'actif'
                    ELSE 'occasionnel'
                END AS segment_live
            FROM patients_chifa p
            LEFT JOIN (
                SELECT
                    MAX(date)                                                       AS derniere_visite_live,
                    MIN(date)                                                       AS premiere_visite_live,
                    COUNT(DISTINCT id) FILTER (
                        WHERE date >= CURRENT_DATE - INTERVAL '12 months'
                    )                                                               AS nb_12m
                FROM sorties
                WHERE n_assure = :no_assure AND type != 'A'
            ) live ON TRUE
            WHERE p.no_assure = :no_assure AND p.rang_ad = '00'
            LIMIT 1
        """), {"no_assure": client_row.n_assure_chifa})).fetchone()

    # Dernières 10 ventes (inclut ventes liées par n_assure)
    # WHERE avec OR ne duplique pas les lignes — DISTINCT ON inutile ici
    ventes = (await db.execute(text("""
        SELECT s.id, s.date, s.heure, s.type, s.total_a_payer,
               s.type_versement, s.utilisateur, s.no_facture_chifa,
               s.montant_cnas, s.montant_assure
        FROM sorties s
        WHERE (s.id_client = :id
               OR (:n_assure != '' AND s.n_assure = :n_assure))
        ORDER BY s.date DESC, s.id DESC
        LIMIT 10
    """), {"id": client_id, "n_assure": n_assure})).fetchall()

    # Instances en cours
    instances = (await db.execute(text("""
        SELECT ip.id, ip.date, ip.nom, ip.qte_sortie, ip.motif, ip.utilisateur
        FROM instance_produits ip
        WHERE ip.id_client = :id AND ip.archive = FALSE
        ORDER BY ip.date DESC, ip.id DESC
        LIMIT 10
    """), {"id": client_id})).fetchall()

    c = client_row
    return {
        # Coordonnées
        "id": c.id, "client": c.client,
        "adresse": c.adresse, "ville": c.ville,
        "telephone": c.telephone, "fax": c.fax, "email": c.email,
        "date_naissance": c.date_naissance.isoformat() if c.date_naissance else None,
        "sexe": c.sexe,
        # Statuts
        "chronique": bool(c.chronique),
        "pathologie": c.pathologie,
        "blk_comptoir": bool(c.blk_comptoir), "blk_chifa": bool(c.blk_chifa),
        "blk_cvm": bool(c.blk_cvm), "blk_instance": bool(c.blk_instance),
        # Assurances
        "n_assure_chifa": c.n_assure_chifa,
        "num_assure_cvm": c.num_assure_cvm,
        "date_exp_droits": c.date_exp_droits.isoformat() if c.date_exp_droits else None,
        # Cartes chroniques
        "cartes_chroniques": [
            {"num": c.num_carte_chronique,  "exp": c.date_exp_droits.isoformat()  if c.date_exp_droits  else None},
            {"num": c.num_carte_chronique2, "exp": c.date_exp_droits2.isoformat() if c.date_exp_droits2 else None},
            {"num": c.num_carte_chronique3, "exp": c.date_exp_droits3.isoformat() if c.date_exp_droits3 else None},
            {"num": c.num_carte_chronique4, "exp": c.date_exp_droits4.isoformat() if c.date_exp_droits4 else None},
            {"num": c.num_carte_chronique5, "exp": c.date_exp_droits5.isoformat() if c.date_exp_droits5 else None},
        ],
        # Archivage
        "is_archive":    bool(c.is_archive),
        "date_archive":  c.date_archive.isoformat() if c.date_archive else None,
        "motif_archive": c.motif_archive,
        # Financier
        "credit": float(c.credit or 0),
        "solde_initial": float(c.solde_initial or 0),
        "solde_max": float(c.solde_max or 0),
        # KPIs achats
        "kpis": {
            "ca_total":       float(kpis.ca_total),
            "nb_achats":      int(kpis.nb_achats),
            "panier_moyen":   round(float(kpis.panier_moyen), 2),
            "ca_12m":         float(kpis.ca_12m),
            "nb_12m":         int(kpis.nb_12m),
            "derniere_visite": kpis.derniere_visite.isoformat() if kpis.derniere_visite else None,
            "premiere_visite": kpis.premiere_visite.isoformat() if kpis.premiere_visite else None,
        },
        # Score RFM
        "rfm": {
            "score": rfm_total,
            "label": rfm_label,
            "r": r_score, "f": f_score, "m": m_score,
            "jours_since": days_since,
        },
        # CHIFA / maladies chroniques
        "chifa": None if not chifa_row else {
            "statut":             chifa_row.segment_live,  # calculé live, cohérent avec la segmentation
            "maladies":           chifa_row.maladies_noms or chifa_row.maladies or [],
            "specialites":        chifa_row.specialites or [],
            "nb_visites":         chifa_row.nb_visites,
            "premiere_visite":    chifa_row.premiere_visite.isoformat() if chifa_row.premiere_visite else None,
            "derniere_visite":    chifa_row.derniere_visite.isoformat() if chifa_row.derniere_visite else None,
            "prochain_visite_est": chifa_row.prochain_visite_est.isoformat() if chifa_row.prochain_visite_est else None,
            "intervalle_moyen":   float(chifa_row.intervalle_moyen) if chifa_row.intervalle_moyen else None,
            "mt_total_assure":    float(chifa_row.mt_total_assure) if chifa_row.mt_total_assure else 0,
            "mt_total_officine":  float(chifa_row.mt_total_officine) if chifa_row.mt_total_officine else 0,
        },
        # Historique
        "dernières_ventes": [
            {
                "id": v.id, "date": v.date.isoformat() if v.date else None,
                "heure": v.heure, "type": v.type,
                "total_a_payer": float(v.total_a_payer or 0),
                "type_versement": v.type_versement, "utilisateur": v.utilisateur,
                "no_facture_chifa": v.no_facture_chifa,
                "montant_cnas": float(v.montant_cnas or 0),
                "montant_assure": float(v.montant_assure or 0),
            }
            for v in ventes
        ],
        "instances_en_cours": [
            {
                "id": i.id, "date": i.date.isoformat() if i.date else None,
                "nom": i.nom, "qte": int(i.qte_sortie or 0),
                "motif": i.motif, "utilisateur": i.utilisateur,
            }
            for i in instances
        ],
    }


# ── Export CSV ─────────────────────────────────────────────────────────────────

@router.get("/export")
async def crm_export(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Export CSV de tous les clients avec leurs KPIs CRM.
    BOM UTF-8 inclus pour compatibilité Excel.
    """
    import csv
    import io
    from fastapi.responses import StreamingResponse

    rows = (await db.execute(text("""
        SELECT
            c.id, c.client, c.telephone, c.ville, c.email,
            c.n_assure_chifa, c.num_assure_cvm,
            c.chronique, COALESCE(c.credit, 0) AS credit,
            COALESCE(s.ca_total,  0) AS ca_total,
            COALESCE(s.nb_achats, 0) AS nb_achats,
            COALESCE(s.ca_12m,    0) AS ca_12m,
            COALESCE(s.nb_12m,    0) AS nb_12m,
            s.derniere_visite
        FROM clients c
        LEFT JOIN (
            SELECT id_client,
                   COALESCE(SUM(total_a_payer), 0)                                           AS ca_total,
                   COUNT(DISTINCT id)                                                          AS nb_achats,
                   COALESCE(SUM(total_a_payer) FILTER (
                       WHERE date >= CURRENT_DATE - INTERVAL '12 months'), 0)                 AS ca_12m,
                   COUNT(DISTINCT id) FILTER (
                       WHERE date >= CURRENT_DATE - INTERVAL '12 months')                     AS nb_12m,
                   MAX(date)                                                                   AS derniere_visite
            FROM sorties
            WHERE type != 'A'
            GROUP BY id_client
        ) s ON s.id_client = c.id
        WHERE c.is_archive IS NOT TRUE
        ORDER BY COALESCE(s.ca_total, 0) DESC
    """))).fetchall()

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow([
        'ID', 'Client', 'Téléphone', 'Ville', 'Email',
        'N° CHIFA', 'N° CVM', 'Chronique', 'Crédit (DA)',
        'CA Total (DA)', 'Nb Achats', 'CA 12 mois (DA)',
        'Visites 12 mois', 'Dernière visite',
    ])
    for r in rows:
        writer.writerow([
            r.id, r.client or '', r.telephone or '', r.ville or '', r.email or '',
            r.n_assure_chifa or '', r.num_assure_cvm or '',
            'Oui' if r.chronique else 'Non',
            round(float(r.credit), 2),
            round(float(r.ca_total), 2),
            int(r.nb_achats),
            round(float(r.ca_12m), 2),
            int(r.nb_12m),
            r.derniere_visite.strftime('%d/%m/%Y') if r.derniere_visite else '',
        ])

    content = '﻿' + output.getvalue()
    return StreamingResponse(
        iter([content]),
        media_type='text/csv; charset=utf-8',
        headers={'Content-Disposition': 'attachment; filename="clients_crm.csv"'},
    )


# ── Performance employé ────────────────────────────────────────────────────────

@router.get("/performance/employes")
async def crm_perf_employes(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Liste des employés ayant des ventes (pour le sélecteur)."""
    rows = (await db.execute(text("""
        SELECT DISTINCT utilisateur FROM sorties
        WHERE utilisateur IS NOT NULL AND utilisateur != ''
        ORDER BY utilisateur
    """))).fetchall()
    return [r.utilisateur for r in rows]


@router.get("/performance/employe")
async def crm_perf_employe(
    employe: Optional[str] = Query(None, description="Nom employé (null = tous)"),
    annee: Optional[int] = Query(None),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Dashboard CRM d'un employé :
    - KPIs : clients servis, nouveaux, récupérés, SMS, CA, panier moyen
    - Charts : nouveaux/récupérés par spécialité ALD, évolution mensuelle
    """
    from datetime import date as date_cls
    a = annee or date_cls.today().year
    # Build filter dynamically — asyncpg can't infer the type of a NULL parameter
    emp_clause = "AND utilisateur = :employe" if employe else ""
    fa_clause  = "AND fa.utilisateur = :employe" if employe else ""
    emp_param: dict = {"annee": a}
    if employe:
        emp_param["employe"] = employe

    # ── KPIs principaux ────────────────────────────────────────────────────────
    kpis_row = (await db.execute(text(f"""
        WITH first_annee AS (
            SELECT DISTINCT ON (id_client)
                id_client, date, utilisateur
            FROM sorties
            WHERE type != 'A' AND EXTRACT(YEAR FROM date) = :annee
            ORDER BY id_client, date ASC
        ),
        last_before AS (
            SELECT DISTINCT ON (id_client)
                id_client, date AS last_date
            FROM sorties
            WHERE type != 'A' AND EXTRACT(YEAR FROM date) < :annee
            ORDER BY id_client, date DESC
        ),
        nouveaux AS (
            SELECT fa.id_client FROM first_annee fa
            WHERE NOT EXISTS (
                SELECT 1 FROM last_before lb WHERE lb.id_client = fa.id_client
            )
              {fa_clause}
        ),
        recuperes AS (
            SELECT fa.id_client FROM first_annee fa
            JOIN last_before lb ON lb.id_client = fa.id_client
            WHERE fa.date - lb.last_date > 180
              {fa_clause}
        ),
        ventes_emp AS (
            SELECT id_client, total_a_payer, benefices
            FROM sorties
            WHERE type != 'A'
              AND EXTRACT(YEAR FROM date) = :annee
              {emp_clause}
        )
        SELECT
            COUNT(DISTINCT ve.id_client)         AS total_clients_servis,
            (SELECT COUNT(*) FROM nouveaux)       AS nouveaux_clients,
            (SELECT COUNT(*) FROM recuperes)      AS clients_recuperes,
            COUNT(*)                              AS nb_factures,
            COALESCE(SUM(ve.total_a_payer), 0)   AS ca_genere,
            COALESCE(SUM(ve.benefices), 0)        AS benefices_total
        FROM ventes_emp ve
    """), emp_param)).fetchone()

    nb_factures = int(kpis_row.nb_factures or 0)
    ca_genere   = _f(kpis_row.ca_genere)
    panier_moyen = round(ca_genere / nb_factures, 2) if nb_factures > 0 else 0.0

    # ── SMS envoyés ────────────────────────────────────────────────────────────
    sms_clause = "AND utilisateur = :employe" if employe else ""
    try:
        sms_count = (await db.execute(text(f"""
            SELECT COUNT(*) AS nb
            FROM sms_logs
            WHERE status = 'sent'
              AND EXTRACT(YEAR FROM created_at) = :annee
              {sms_clause}
        """), emp_param)).scalar() or 0
    except Exception:
        sms_count = 0  # migration 031 (sms_logs.utilisateur) not yet applied

    # ── Helper ALD breakdown ───────────────────────────────────────────────────
    async def _ald_breakdown(client_ids_cte_sql: str) -> list[dict]:
        rows = (await db.execute(text(f"""
            WITH target_clients AS ({client_ids_cte_sql})
            SELECT mc.specialite, COUNT(DISTINCT c.id) AS nb
            FROM clients c
            JOIN target_clients tc ON tc.id_client = c.id
            JOIN patients_chifa p
                ON p.no_assure = c.n_assure_chifa AND p.rang_ad = '00'
            JOIN LATERAL (SELECT UNNEST(p.maladies) AS code) m ON TRUE
            JOIN maladies_chroniques mc ON mc.code = m.code
            WHERE mc.specialite IS NOT NULL AND mc.specialite != ''
            GROUP BY mc.specialite
            ORDER BY nb DESC
        """), emp_param)).fetchall()
        return [{"specialite": r.specialite, "nb": int(r.nb)} for r in rows]

    nouveaux_cte = f"""
        SELECT DISTINCT ON (id_client) id_client, date, utilisateur
        FROM sorties
        WHERE type != 'A' AND EXTRACT(YEAR FROM date) = :annee
        ORDER BY id_client, date ASC
    """
    nouveaux_ids_cte = f"""
        SELECT fa.id_client FROM ({nouveaux_cte}) fa
        WHERE NOT EXISTS (
            SELECT 1 FROM sorties s2
            WHERE s2.id_client = fa.id_client
              AND s2.type != 'A'
              AND EXTRACT(YEAR FROM s2.date) < :annee
        )
        {fa_clause}
    """
    recuperes_ids_cte = f"""
        SELECT fa.id_client FROM ({nouveaux_cte}) fa
        JOIN (
            SELECT DISTINCT ON (id_client) id_client, date AS last_date
            FROM sorties WHERE type != 'A' AND EXTRACT(YEAR FROM date) < :annee
            ORDER BY id_client, date DESC
        ) lb ON lb.id_client = fa.id_client
        WHERE fa.date - lb.last_date > 180
          {fa_clause}
    """

    nouveaux_par_ald  = await _ald_breakdown(nouveaux_ids_cte)
    recuperes_par_ald = await _ald_breakdown(recuperes_ids_cte)

    # ── Évolution mensuelle ────────────────────────────────────────────────────
    evol_rows = (await db.execute(text(f"""
        SELECT
            TO_CHAR(DATE_TRUNC('month', date), 'YYYY-MM') AS mois,
            COUNT(DISTINCT id_client)                      AS nb_clients,
            COALESCE(SUM(total_a_payer), 0)                AS ca
        FROM sorties
        WHERE type != 'A'
          AND EXTRACT(YEAR FROM date) = :annee
          {emp_clause}
        GROUP BY DATE_TRUNC('month', date)
        ORDER BY 1
    """), emp_param)).fetchall()

    return {
        "employe":             employe,
        "annee":               a,
        "total_clients_servis": int(kpis_row.total_clients_servis or 0),
        "nouveaux_clients":    int(kpis_row.nouveaux_clients or 0),
        "clients_recuperes":   int(kpis_row.clients_recuperes or 0),
        "sms_envoyes":         int(sms_count),
        "ca_genere":           ca_genere,
        "benefices_total":     _f(kpis_row.benefices_total),
        "nb_factures":         nb_factures,
        "panier_moyen":        panier_moyen,
        "nouveaux_par_ald":    nouveaux_par_ald,
        "recuperes_par_ald":   recuperes_par_ald,
        "evolution_mensuelle": [
            {"mois": r.mois, "nb_clients": int(r.nb_clients), "ca": _f(r.ca)}
            for r in evol_rows
        ],
    }
