"""grossiste préféré d'un produit

Changer le grossiste d'une ligne ne valait que pour le jour : le lendemain
le produit revenait chez son fournisseur du dernier achat. La table
`produits_fournisseur_prefere` retient le choix : le produit est proposé
chez ce grossiste tant qu'il n'a pas été désactivé par le titulaire.

Revision ID: 016
Revises: 015
Create Date: 2026-11-16
"""
import sqlalchemy as sa
from alembic import op

revision = "016"
down_revision = "015"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "produits_fournisseur_prefere",
        sa.Column("id_nom", sa.BigInteger, primary_key=True),
        sa.Column("id_fournisseur", sa.BigInteger, nullable=False),
        sa.Column("modifie_le", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("modifie_par", sa.String(100)),
    )


def downgrade() -> None:
    op.drop_table("produits_fournisseur_prefere")
