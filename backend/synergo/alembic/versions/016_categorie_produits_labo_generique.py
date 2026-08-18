"""Ajout categorie produit (nomenclature) et is_generique (laboratoires)

Revision ID: 016
Revises: 015
Create Date: 2026-04-05

- nomenclature.categorie     : princeps | generique | promotion (calculé auto ou manuel)
- laboratoires.is_generique  : marque un laboratoire comme fabricant de génériques
"""
from alembic import op
import sqlalchemy as sa

revision = '016'
down_revision = '015'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        'nomenclature',
        sa.Column('categorie', sa.String(20), nullable=True),
    )
    op.create_index('ix_nomenclature_categorie', 'nomenclature', ['categorie'],
                    postgresql_where=sa.text("categorie IS NOT NULL"))

    op.add_column(
        'laboratoires',
        sa.Column('is_generique', sa.Boolean(), nullable=False,
                  server_default='false'),
    )


def downgrade() -> None:
    op.drop_column('laboratoires', 'is_generique')
    op.drop_index('ix_nomenclature_categorie', table_name='nomenclature')
    op.drop_column('nomenclature', 'categorie')
