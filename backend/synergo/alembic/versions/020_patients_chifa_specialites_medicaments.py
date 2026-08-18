"""Ajouter specialites + medicaments à patients_chifa

Revision ID: 020
Revises: 019
Create Date: 2026-04-08
"""
from alembic import op

revision = '020'
down_revision = '019'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
    ALTER TABLE patients_chifa
        ADD COLUMN IF NOT EXISTS specialites  VARCHAR(50)[],
        ADD COLUMN IF NOT EXISTS medicaments  VARCHAR(200)[]
    """)


def downgrade() -> None:
    op.execute("""
    ALTER TABLE patients_chifa
        DROP COLUMN IF EXISTS specialites,
        DROP COLUMN IF EXISTS medicaments
    """)
