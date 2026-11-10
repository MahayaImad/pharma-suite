"""
Service de segmentation stock — ABC / XYZ / Disponibilité

ABC  : Segmentation par chiffre d'affaires net cumulé (12 mois glissants)
         A → produits couvrant les 80 premiers % du CA
         B → produits suivants, jusqu'à 95 %
         C → reste des produits vendus
         (aucune classe pour un produit sans vente nette sur 12 mois)

XYZ  : Segmentation par régularité de la demande (coefficient de variation
       mensuel sur les 12 derniers mois complets, mois sans vente comptés à 0)
         X → CV < 0.5  (stable, prévisible)
         Y → 0.5 ≤ CV < 1.0  (variable)
         Z → CV ≥ 1.0, ou moins de 3 mois d'historique

Disponibilité : mise à jour automatique après chaque refresh du MV stock
         oui     → stock > 0  (et disponibilite != 'quota')
         rupture → stock = 0  (et disponibilite != 'quota')
         quota   → positionné manuellement par le pharmacien ;
                   réinitialisé automatiquement si stock dépasse COALESCE(qte_alerte, 5)
"""
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from loguru import logger


# ── Paramètres ────────────────────────────────────────────────────────────────

SEUIL_A = "0.80"      # part cumulée du chiffre d'affaires : A jusqu'à 80 %
SEUIL_B = "0.95"      # B jusqu'à 95 %, C au-delà
CV_X = "0.5"          # coefficient de variation mensuel : X en dessous de 0,5
CV_Y = "1.0"          # Y en dessous de 1, Z au-delà
MOIS_MIN_XYZ = 3      # en dessous de 3 mois d'historique, la régularité ne se mesure pas

# Produits classés : non archivés, avec un chiffre d'affaires net positif sur
# 12 mois glissants. Net : un retour client a une qte_sortie négative
# (docs/BUSINESS_LOGIC.md §2.3), il se déduit donc tout seul. Les lignes de
# vente dont le produit a disparu de la nomenclature sont écartées par la
# jointure : elles ne doivent pas peser dans le total.
_VENDUS = """
    SELECT sp.id_nom,
           SUM(sp.qte_sortie * sp.prix_vente) AS ca_total
    FROM sorties_produits sp
    JOIN nomenclature n ON n.id = sp.id_nom AND n.archive = false
    WHERE sp.date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY sp.id_nom
    HAVING SUM(sp.qte_sortie * sp.prix_vente) > 0
"""


# ── ABC ───────────────────────────────────────────────────────────────────────

async def compute_abc(db: AsyncSession) -> int:
    """
    Calcule segment_abc sur le chiffre d'affaires net des 12 derniers mois.

    Les produits sont rangés par chiffre d'affaires décroissant ; un produit
    est A tant que le cumul **avant lui** est sous 80 %, B sous 95 %, C
    ensuite. Le produit qui fait franchir le seuil appartient donc à la
    classe qu'il termine.

    Un produit sans vente nette sur 12 mois, ou archivé, n'a **pas de
    classe** (NULL) : ce n'est pas un « C », c'est un produit sans mouvement.
    Une classe devenue fausse est effacée — un ancien A qui ne se vend plus ne
    reste pas A.

    Retourne le nombre de produits classés.
    """
    await db.execute(text(f"""
        WITH vendus AS ({_VENDUS}),
        ranges AS (
            SELECT id_nom, ca_total,
                   SUM(ca_total) OVER (
                       ORDER BY ca_total DESC, id_nom
                       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                   ) - ca_total                  AS cumul_avant,
                   SUM(ca_total) OVER ()          AS ca_global
            FROM vendus
        ),
        segments AS (
            SELECT id_nom,
                   CASE
                       WHEN cumul_avant / ca_global < CAST(:seuil_a AS numeric) THEN 'A'
                       WHEN cumul_avant / ca_global < CAST(:seuil_b AS numeric) THEN 'B'
                       ELSE 'C'
                   END AS segment
            FROM ranges
        )
        UPDATE nomenclature n
        SET segment_abc = s.segment
        FROM (
            SELECT n2.id, seg.segment
            FROM nomenclature n2
            LEFT JOIN segments seg ON seg.id_nom = n2.id
        ) s
        WHERE n.id = s.id
          AND n.segment_abc IS DISTINCT FROM s.segment
    """), {"seuil_a": SEUIL_A, "seuil_b": SEUIL_B})
    classes = (await db.execute(text(
        "SELECT count(*) FROM nomenclature WHERE segment_abc IS NOT NULL"))).scalar() or 0
    await db.commit()
    logger.info(f"[ABC] Segmentation terminée — {classes} produits classés")
    return classes


# ── XYZ ───────────────────────────────────────────────────────────────────────

async def compute_xyz(db: AsyncSession) -> int:
    """
    Calcule segment_xyz : régularité de la demande mensuelle.

    Coefficient de variation (écart-type ÷ moyenne) des quantités nettes
    vendues par mois, sur les **12 derniers mois complets** — le mois en cours,
    incomplet, fausserait la mesure. Les mois **sans vente comptent pour
    zéro** : un produit vendu trois mois sur douze est irrégulier, même si
    ses trois mois se ressemblent.

    Pour un produit récent, la série commence au mois de sa première vente,
    pas avant. Avec moins de 3 mois d'historique, la régularité ne se mesure
    pas : Z.

    Mêmes produits classés que l'ABC ; les autres n'ont pas de classe (NULL).
    Retourne le nombre de produits classés.
    """
    await db.execute(text(f"""
        WITH vendus AS ({_VENDUS}),
        bornes AS (
            SELECT date_trunc('month', CURRENT_DATE)::date                         AS fin,
                   (date_trunc('month', CURRENT_DATE) - INTERVAL '12 months')::date AS debut
        ),
        depuis AS (
            -- Mois de la première vente du produit, borné à la fenêtre.
            SELECT sp.id_nom,
                   GREATEST(date_trunc('month', MIN(sp.date))::date, b.debut) AS premier_mois
            FROM sorties_produits sp
            JOIN vendus v ON v.id_nom = sp.id_nom
            CROSS JOIN bornes b
            WHERE sp.qte_sortie > 0
            GROUP BY sp.id_nom, b.debut
        ),
        calendrier AS (
            SELECT d.id_nom, g::date AS mois
            FROM depuis d
            CROSS JOIN bornes b
            CROSS JOIN LATERAL generate_series(
                d.premier_mois::timestamp, b.fin - INTERVAL '1 month', INTERVAL '1 month') g
        ),
        ventes AS (
            SELECT sp.id_nom,
                   date_trunc('month', sp.date)::date AS mois,
                   SUM(sp.qte_sortie)                 AS qte
            FROM sorties_produits sp
            CROSS JOIN bornes b
            WHERE sp.date >= b.debut AND sp.date < b.fin
            GROUP BY sp.id_nom, date_trunc('month', sp.date)
        ),
        stats AS (
            SELECT c.id_nom,
                   AVG(COALESCE(v.qte, 0))        AS mu,
                   STDDEV_POP(COALESCE(v.qte, 0)) AS sigma,
                   COUNT(*)                       AS nb_mois
            FROM calendrier c
            LEFT JOIN ventes v ON v.id_nom = c.id_nom AND v.mois = c.mois
            GROUP BY c.id_nom
        ),
        segments AS (
            SELECT v.id_nom,
                   CASE
                       WHEN st.id_nom IS NULL OR st.nb_mois < :mois_min THEN 'Z'
                       WHEN st.mu <= 0                                   THEN 'Z'
                       WHEN st.sigma / st.mu < CAST(:cv_x AS numeric)    THEN 'X'
                       WHEN st.sigma / st.mu < CAST(:cv_y AS numeric)    THEN 'Y'
                       ELSE 'Z'
                   END AS segment
            FROM vendus v
            LEFT JOIN stats st ON st.id_nom = v.id_nom
        )
        UPDATE nomenclature n
        SET segment_xyz = s.segment
        FROM (
            SELECT n2.id, seg.segment
            FROM nomenclature n2
            LEFT JOIN segments seg ON seg.id_nom = n2.id
        ) s
        WHERE n.id = s.id
          AND n.segment_xyz IS DISTINCT FROM s.segment
    """), {"cv_x": CV_X, "cv_y": CV_Y, "mois_min": MOIS_MIN_XYZ})
    classes = (await db.execute(text(
        "SELECT count(*) FROM nomenclature WHERE segment_xyz IS NOT NULL"))).scalar() or 0
    await db.commit()
    logger.info(f"[XYZ] Segmentation terminée — {classes} produits classés")
    return classes


# ── Disponibilité ─────────────────────────────────────────────────────────────

async def update_disponibilite(db: AsyncSession) -> dict:
    """
    Met à jour disponibilite pour chaque produit non archivé.

    Règles (par ordre de priorité) :
    1. quota + stock > COALESCE(qte_alerte, 5)  →  reset à 'oui' automatiquement
    2. stock = 0, produit actif, != quota       →  'rupture'
    3. stock = 0, produit inactif, != quota     →  'inactif'
    4. stock > 0  et  != quota                  →  'oui'

    Les produits en 'quota' dont le stock n'atteint pas encore le seuil restent 'quota'.
    Retourne un dict résumant les counts de chaque action.
    """
    # Chaque mise à jour ne touche que les lignes dont la valeur change :
    # cette fonction tourne après chaque passe de synchronisation, et réécrire
    # 9 000 lignes à l'identique toutes les 15 minutes gonflerait la table.

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

    # 2. Ruptures : stock nul sur un produit ACTIF (hors quota)
    r_rupture = await db.execute(text("""
        UPDATE nomenclature n
        SET disponibilite = 'rupture'
        FROM mv_stock_produits mv
        WHERE mv.id_nom = n.id
          AND n.disponibilite NOT IN ('quota', 'rupture')
          AND n.archive = false
          AND COALESCE(mv.stock_actuel, 0) <= 0
          AND mv.actif
        RETURNING n.id
    """))
    ruptures = len(r_rupture.fetchall())

    # 3. Inactifs : stock nul, ni vendu depuis 12 mois — pas une rupture
    r_inactif = await db.execute(text("""
        UPDATE nomenclature n
        SET disponibilite = 'inactif'
        FROM mv_stock_produits mv
        WHERE mv.id_nom = n.id
          AND n.disponibilite NOT IN ('quota', 'inactif')
          AND n.archive = false
          AND COALESCE(mv.stock_actuel, 0) <= 0
          AND NOT mv.actif
        RETURNING n.id
    """))
    inactifs = len(r_inactif.fetchall())

    # 4. Disponibles (stock > 0, hors quota)
    r_dispo = await db.execute(text("""
        UPDATE nomenclature n
        SET disponibilite = 'oui'
        FROM mv_stock_produits mv
        WHERE mv.id_nom = n.id
          AND n.disponibilite NOT IN ('quota', 'oui')
          AND n.archive = false
          AND COALESCE(mv.stock_actuel, 0) > 0
        RETURNING n.id
    """))
    disponibles = len(r_dispo.fetchall())

    await db.commit()
    logger.info(
        f"[Disponibilité] changements — oui={disponibles}, rupture={ruptures}, "
        f"inactif={inactifs}, quota_reset={quota_reset}"
    )
    # Nombre de produits dont la valeur a CHANGÉ à cet appel, pas le total.
    return {
        "oui": disponibles,
        "rupture": ruptures,
        "inactif": inactifs,
        "quota_reset": quota_reset,
    }
