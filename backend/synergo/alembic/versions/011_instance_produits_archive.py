"""Ajout colonne archive à instance_produits

Champ PostgreSQL uniquement (non présent dans HFSQL).
True = enregistrement supprimé de HFSQL (ordonnance reçue → retour stock).
Mis à jour par le sync agent lors de chaque full_nightly.

Revision ID: 011
Revises: 010
Create Date: 2026-03-31
"""
from alembic import op
import sqlalchemy as sa

revision = '011'
down_revision = '010'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
        ALTER TABLE instance_produits
            ADD COLUMN IF NOT EXISTS archive BOOLEAN NOT NULL DEFAULT FALSE;
    """)


def downgrade() -> None:
    op.execute("ALTER TABLE instance_produits DROP COLUMN IF EXISTS archive;")
