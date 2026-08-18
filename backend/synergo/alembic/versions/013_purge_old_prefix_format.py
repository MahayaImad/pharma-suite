"""Supprime les anciens préfixes format 'NNX' (sans espace) doublonnant les nouveaux 'NN X'

Revision ID: 013
Revises: 012
Create Date: 2026-04-01

Contexte : avant la migration 012, le reimport générait des préfixes 3 chars sans espace
ex: '02A', '10B'. Migration 012 a inséré les vrais préfixes DTC ('02 A', '10 B').
Cette migration supprime les doublons anciens format.
"""
from alembic import op

revision = '013'
down_revision = '012'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Supprime les entrées dont le préfixe est au vieux format NNX (3 chars, pas d'espace)
    # ex: '02A', '10B', '13G' — remplacées par '02 A', '10 B', '13 G' dans migration 012
    op.execute("""
        DELETE FROM nomenclature_classification
        WHERE LENGTH(prefix) = 3
          AND prefix ~ '^[0-9]{2}[A-Za-z]$';
    """)


def downgrade() -> None:
    pass  # non réversible — les données propres sont dans migration 012
