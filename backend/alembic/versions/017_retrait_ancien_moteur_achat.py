"""retrait de l'ancien moteur d'achat

`assistant_achat` et `services/purchase_engine/` sont remplacés par le module
Commandes (`app/modules/commandes/`, `services/prevision/`). Leurs deux tables
de résultats calculés n'ont plus de lecteur : `parametres_stock` (stock de
sécurité, point de commande, quantité économique) et `previsions_demande`.
Elles ne contenaient que des valeurs recalculables, aucune saisie.

Revision ID: 017
Revises: 016
Create Date: 2026-11-16
"""
import sqlalchemy as sa
from alembic import op

revision = "017"
down_revision = "016"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("DROP TABLE IF EXISTS parametres_stock")
    op.execute("DROP TABLE IF EXISTS previsions_demande")


def downgrade() -> None:
    # Tables recréées vides, comme dans la baseline.
    op.create_table(
        "parametres_stock",
        sa.Column("id_nom", sa.BigInteger, primary_key=True),
        sa.Column("delai_moyen_j", sa.Numeric(8, 2)),
        sa.Column("demande_moy_j", sa.Numeric(10, 4)),
        sa.Column("demande_std_j", sa.Numeric(10, 4)),
        sa.Column("stock_securite", sa.Numeric(10, 2)),
        sa.Column("rop", sa.Numeric(10, 2)),
        sa.Column("eoq", sa.Numeric(10, 2)),
        sa.Column("holding_cost_pct", sa.Numeric(5, 4), server_default="0.20"),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_table(
        "previsions_demande",
        sa.Column("id_nom", sa.BigInteger, primary_key=True),
        sa.Column("modele", sa.String(30)),
        sa.Column("prevision_30j", sa.Numeric(12, 2)),
        sa.Column("prevision_90j", sa.Numeric(12, 2)),
        sa.Column("mape_holdout", sa.Numeric(7, 4)),
        sa.Column("serie_corrigee", sa.dialects.postgresql.JSONB),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
