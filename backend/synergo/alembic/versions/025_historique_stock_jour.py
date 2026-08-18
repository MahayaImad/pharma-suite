"""Table historique_stock_jour — stock reconstitué par produit et par jour

Revision ID: 025
Revises: 024
Create Date: 2026-04-11

Stock reconstitué à partir de :
  - sorties_produits         (ventes)
  - entrees_produits         (achats)
  - inventaires_produits     (ajustements, champ ecart)
  - echanges_sorties_produits (sorties échange/retour)
"""

from alembic import op
import sqlalchemy as sa

revision = "025"
down_revision = "024"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "historique_stock_jour",
        sa.Column("id_nom", sa.BigInteger(), nullable=False),
        sa.Column("date",   sa.Date(),       nullable=False),
        sa.Column("stock_eod", sa.Numeric(12, 2), nullable=True,
                  comment="Stock fin de journée reconstitué"),
        sa.Column("updated_at", sa.DateTime(timezone=True),
                  server_default=sa.text("NOW()"), nullable=False),
        sa.PrimaryKeyConstraint("id_nom", "date"),
    )
    op.create_index("ix_histo_stock_id_nom", "historique_stock_jour", ["id_nom"])


def downgrade() -> None:
    op.drop_index("ix_histo_stock_id_nom", "historique_stock_jour")
    op.drop_table("historique_stock_jour")
