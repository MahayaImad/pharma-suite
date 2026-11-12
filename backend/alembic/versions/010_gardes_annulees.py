"""gardes annulées

`gardes.annulee` : une garde retrouvée dans les ventes ou proposée par la
rotation, que l'officine déclare fausse. Elle reste en base pour que ni la
détection (`--enregistrer`) ni la rotation ne la reproposent ; elle n'est
plus affichée, ne sert plus de point de départ à la rotation et ne compte
pas dans la prévision. La saisir ou la confirmer à nouveau la rétablit.

Revision ID: 010
Revises: 009
Create Date: 2026-11-12
"""
import sqlalchemy as sa
from alembic import op

revision = "010"
down_revision = "009"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("gardes", sa.Column("annulee", sa.Boolean, nullable=False, server_default=sa.false()))


def downgrade() -> None:
    op.execute("DELETE FROM gardes WHERE annulee")
    op.drop_column("gardes", "annulee")
