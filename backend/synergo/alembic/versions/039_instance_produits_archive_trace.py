"""Ajout archive_trace à instance_produits

Révision ID: 039
Revises: 038
Create Date: 2026-05-04

- archive_trace : VARCHAR(50) — type de traitement issu de instance_produits_trt.info_trt
  Valeurs : 'Vente CHIFA' | 'Vente Comptoir' | 'Suppression manuelle'
  Remplace l'heuristique de déduction depuis sorties pour utilisateur_validation.
"""
from alembic import op

revision = '039'
down_revision = '038'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
        ALTER TABLE instance_produits
            ADD COLUMN IF NOT EXISTS archive_trace VARCHAR(50);
    """)


def downgrade() -> None:
    op.execute("""
        ALTER TABLE instance_produits
            DROP COLUMN IF EXISTS archive_trace;
    """)
