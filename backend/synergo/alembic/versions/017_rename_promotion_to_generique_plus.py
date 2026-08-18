"""Renommer catégorie 'promotion' en 'generique++' dans nomenclature et nomenclature_classification

Revision ID: 017
Revises: 016
Create Date: 2026-04-05
"""
from alembic import op

revision = '017'
down_revision = '016'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
        UPDATE nomenclature
        SET categorie = 'generique++'
        WHERE categorie = 'promotion'
    """)
    op.execute("""
        UPDATE nomenclature_classification
        SET categorie = 'generique++'
        WHERE categorie = 'promotion'
    """)


def downgrade() -> None:
    op.execute("""
        UPDATE nomenclature
        SET categorie = 'promotion'
        WHERE categorie = 'generique++'
    """)
    op.execute("""
        UPDATE nomenclature_classification
        SET categorie = 'promotion'
        WHERE categorie = 'generique++'
    """)
