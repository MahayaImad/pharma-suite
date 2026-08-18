"""mv_stock_produits — vue matérialisée stock réel depuis lots

Revision ID: 007
Revises: 006
Create Date: 2026-03-29
"""
from alembic import op

revision = '007'
down_revision = '006'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── Index manquants (clés de jointure non indexées dans les modèles) ───────
    op.execute("""
        CREATE INDEX IF NOT EXISTS ix_entrees_produits_id_nom
            ON entrees_produits(id_nom);
    """)

    op.execute("""
        CREATE INDEX IF NOT EXISTS ix_sorties_produits_id_nom
            ON sorties_produits(id_nom);
    """)

    # Index date sur sorties_produits pour les filtres de période (rotation KPI)
    op.execute("""
        CREATE INDEX IF NOT EXISTS ix_sorties_produits_date
            ON sorties_produits(date);
    """)

    # ── Vue matérialisée ───────────────────────────────────────────────────────
    # Agrège le stock réel par produit depuis entrees_produits (lots).
    # Seuls les lots avec stock > 0 participent au calcul du prix moyen pondéré.
    op.execute("""
        CREATE MATERIALIZED VIEW IF NOT EXISTS mv_stock_produits AS
        SELECT
            n.id                                                              AS id_nom,
            COALESCE(SUM(ep.stock),      0)::BIGINT                           AS stock_actuel,
            COALESCE(SUM(ep.qte_entree), 0)::BIGINT                           AS qte_entree_totale,
            COALESCE(
                SUM(ep.stock * ep.prix_achat) / NULLIF(SUM(ep.stock), 0),
                0
            )::NUMERIC(15,4)                                                  AS prix_moyen_pondere
        FROM nomenclature n
        LEFT JOIN entrees_produits ep ON ep.id_nom = n.id AND ep.stock > 0
        GROUP BY n.id;
    """)

    # Index unique — obligatoire pour REFRESH MATERIALIZED VIEW CONCURRENTLY
    op.execute("""
        CREATE UNIQUE INDEX IF NOT EXISTS uix_mv_stock_produits_id_nom
            ON mv_stock_produits(id_nom);
    """)


def downgrade() -> None:
    op.execute("DROP MATERIALIZED VIEW IF EXISTS mv_stock_produits CASCADE;")
    op.execute("DROP INDEX IF EXISTS ix_entrees_produits_id_nom;")
    op.execute("DROP INDEX IF EXISTS ix_sorties_produits_id_nom;")
    op.execute("DROP INDEX IF EXISTS ix_sorties_produits_date;")
