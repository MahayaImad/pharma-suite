"""historique du stock : photo de chaque soir ou reconstitution

`historique_stock_jour.source` dit d'où vient le stock de fin de journée :

    photo           relevé tel quel chaque soir (mv_stock_produits, donc le
                    champ entrees_produits.stock d'EASYPHARM) : exact
    reconstitution  recalculé à rebours depuis le stock actuel et les
                    mouvements : une estimation

Une photo n'est jamais écrasée par une reconstitution. Les lignes existantes
viennent de la reconstitution.

Revision ID: 009
Revises: 008
Create Date: 2026-11-12
"""
import sqlalchemy as sa
from alembic import op

revision = "009"
down_revision = "008"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("historique_stock_jour", sa.Column(
        "source", sa.String(15), nullable=False, server_default="reconstitution"))
    op.create_check_constraint(
        "ck_historique_stock_source", "historique_stock_jour", "source IN ('photo', 'reconstitution')")
    op.create_index("ix_histo_stock_date", "historique_stock_jour", ["date"])


def downgrade() -> None:
    op.drop_index("ix_histo_stock_date", "historique_stock_jour")
    op.drop_constraint("ck_historique_stock_source", "historique_stock_jour", type_="check")
    op.drop_column("historique_stock_jour", "source")
