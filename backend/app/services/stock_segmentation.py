"""
Service de segmentation stock — ABC / XYZ / Disponibilité

ABC  : Segmentation par chiffre d'affaires cumulé (12 derniers mois)
         A → top produits couvrant 80 % du CA
         B → produits suivants couvrant 80–95 % du CA
         C → reste

XYZ  : Segmentation par stabilité de la demande (coefficient de variation mensuel)
         X → CV < 0.5  (stable, prévisible)
         Y → 0.5 ≤ CV < 1.0  (variable)
         Z → CV ≥ 1.0  (erratique / sporadique)

Disponibilité : mise à jour automatique après chaque refresh du MV stock
         oui     → stock > 0  (et disponibilite != 'quota')
         rupture → stock = 0  (et disponibilite != 'quota')
         quota   → positionné manuellement par le pharmacien ;
                   réinitialisé automatiquement si stock dépasse COALESCE(qte_alerte, 5)
"""
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from loguru import logger


# ── ABC ───────────────────────────────────────────────────────────────────────

async def compute_abc(db: AsyncSession) -> int:
    """
    Calcule segment_abc pour tous les produits actifs.
    Utilise les ventes des 12 derniers mois (sorties de type 0).
    Retourne le nombre de produits mis à jour.
    """
    result = await db.execute(text("""
        WITH ca_produit AS (
            SELECT
                sp.id_nom,
                SUM(sp.qte_sortie * sp.prix_vente) AS ca_total
            FROM sorties_produits sp
            WHERE sp.date >= CURRENT_DATE - INTERVAL '12 months'
              AND sp.type_sortie NOT IN ('RET', 'AV')
            GROUP BY sp.id_nom
            HAVING SUM(sp.qte_sortie * sp.prix_vente) > 0
        ),
        ranked AS (
            SELECT
                id_nom,
                ca_total,
                SUM(ca_total) OVER (
                    ORDER BY ca_total DESC
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                ) AS ca_cumul,
                SUM(ca_total) OVER () AS ca_global
            FROM ca_produit
        ),
        segments AS (
            SELECT
                id_nom,
                CASE
                    WHEN ca_global = 0 THEN 'C'
                    WHEN ca_cumul::numeric / ca_global <= 0.80 THEN 'A'
                    WHEN ca_cumul::numeric / ca_global <= 0.95 THEN 'B'
                    ELSE 'C'
                END AS segment
            FROM ranked
        )
        UPDATE nomenclature n
        SET segment_abc = s.segment
        FROM segments s
        WHERE n.id = s.id_nom
        RETURNING n.id
    """))
    updated = len(result.fetchall())

    # Produits sans ventes sur 12 mois → C (y compris nouveaux produits)
    await db.execute(text("""
        UPDATE nomenclature
        SET segment_abc = 'C'
        WHERE (segment_abc IS NULL OR segment_abc = '')
          AND archive = false
    """))
    await db.commit()
    logger.info(f"[ABC] Segmentation terminée — {updated} produits classés A/B, reste → C")
    return updated


# ── XYZ ───────────────────────────────────────────────────────────────────────

async def compute_xyz(db: AsyncSession) -> int:
    """
    Calcule segment_xyz pour tous les produits actifs.
    Nécessite au moins 3 mois de ventes pour un CV significatif.
    Produits avec < 3 mois ou sans ventes → Z.
    Retourne le nombre de produits mis à jour.
    """
    result = await db.execute(text("""
        WITH ventes_mensuelles AS (
            SELECT
                sp.id_nom,
                DATE_TRUNC('month', sp.date) AS mois,
                SUM(sp.qte_sortie)           AS qte_mois
            FROM sorties_produits sp
            WHERE sp.date >= CURRENT_DATE - INTERVAL '12 months'
              AND sp.type_sortie NOT IN ('RET', 'AV')
            GROUP BY sp.id_nom, DATE_TRUNC('month', sp.date)
        ),
        stats AS (
            SELECT
                id_nom,
                AVG(qte_mois)        AS mu,
                STDDEV_POP(qte_mois) AS sigma,
                COUNT(*)             AS nb_mois_actifs
            FROM ventes_mensuelles
            GROUP BY id_nom
        ),
        segments AS (
            SELECT
                id_nom,
                CASE
                    WHEN nb_mois_actifs < 3           THEN 'Z'
                    WHEN mu IS NULL OR mu = 0         THEN 'Z'
                    WHEN sigma / mu < 0.5             THEN 'X'
                    WHEN sigma / mu < 1.0             THEN 'Y'
                    ELSE 'Z'
                END AS segment
            FROM stats
        )
        UPDATE nomenclature n
        SET segment_xyz = s.segment
        FROM segments s
        WHERE n.id = s.id_nom
        RETURNING n.id
    """))
    updated = len(result.fetchall())

    # Produits sans historique suffisant → Z
    await db.execute(text("""
        UPDATE nomenclature
        SET segment_xyz = 'Z'
        WHERE (segment_xyz IS NULL OR segment_xyz = '')
          AND archive = false
    """))
    await db.commit()
    logger.info(f"[XYZ] Segmentation terminée — {updated} produits classés X/Y, reste → Z")
    return updated


# ── Disponibilité ─────────────────────────────────────────────────────────────

async def update_disponibilite(db: AsyncSession) -> dict:
    """
    Met à jour disponibilite pour chaque produit non archivé.

    Règles (par ordre de priorité) :
    1. quota + stock > COALESCE(qte_alerte, 5)  →  reset à 'oui' automatiquement
    2. stock = 0  et  != quota                  →  'rupture'
    3. stock > 0  et  != quota                  →  'oui'

    Les produits en 'quota' dont le stock n'atteint pas encore le seuil restent 'quota'.
    Retourne un dict résumant les counts de chaque action.
    """
    # 1. Réinitialisation automatique des quotas si stock suffisant
    r_quota_reset = await db.execute(text("""
        UPDATE nomenclature n
        SET disponibilite = 'oui'
        FROM mv_stock_produits mv
        WHERE mv.id_nom = n.id
          AND n.disponibilite = 'quota'
          AND n.archive = false
          AND COALESCE(mv.stock_actuel, 0) > COALESCE(n.qte_alerte, 5)
        RETURNING n.id
    """))
    quota_reset = len(r_quota_reset.fetchall())

    # 2. Ruptures (stock = 0, hors quota)
    r_rupture = await db.execute(text("""
        UPDATE nomenclature n
        SET disponibilite = 'rupture'
        FROM mv_stock_produits mv
        WHERE mv.id_nom = n.id
          AND n.disponibilite != 'quota'
          AND n.archive = false
          AND COALESCE(mv.stock_actuel, 0) <= 0
        RETURNING n.id
    """))
    ruptures = len(r_rupture.fetchall())

    # 3. Disponibles (stock > 0, hors quota)
    r_dispo = await db.execute(text("""
        UPDATE nomenclature n
        SET disponibilite = 'oui'
        FROM mv_stock_produits mv
        WHERE mv.id_nom = n.id
          AND n.disponibilite != 'quota'
          AND n.archive = false
          AND COALESCE(mv.stock_actuel, 0) > 0
        RETURNING n.id
    """))
    disponibles = len(r_dispo.fetchall())

    await db.commit()
    logger.info(
        f"[Disponibilité] oui={disponibles}, rupture={ruptures}, quota_reset={quota_reset}"
    )
    return {
        "oui": disponibles,
        "rupture": ruptures,
        "quota_reset": quota_reset,
    }
