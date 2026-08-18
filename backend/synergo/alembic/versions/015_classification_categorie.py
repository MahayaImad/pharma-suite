"""Ajout colonne categorie à nomenclature_classification

Revision ID: 015
Revises: 014
Create Date: 2026-04-05

Catégories produits : princeps | generique | promotion
Utilisé pour le calcul de l'assiette prime de rendement
et le rapport performance employés par catégorie.
"""
from alembic import op
import sqlalchemy as sa

revision = '015'
down_revision = '014'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        'nomenclature_classification',
        sa.Column('categorie', sa.String(20), nullable=True),
    )
    op.create_index(
        'ix_nomenclature_classification_categorie',
        'nomenclature_classification',
        ['categorie'],
        postgresql_where=sa.text("categorie IS NOT NULL"),
    )


def downgrade() -> None:
    op.drop_index('ix_nomenclature_classification_categorie',
                  table_name='nomenclature_classification')
    op.drop_column('nomenclature_classification', 'categorie')
