"""Ajout date_archive et utilisateur_validation à instance_produits

Révision ID: 022
Revises: 021
Create Date: 2026-04-09

- date_archive : TIMESTAMPTZ — horodatage de la validation (archive=True)
- utilisateur_validation : VARCHAR(50) — employé qui a transformé l'instance en vente
  (déduit au moment du finalize depuis la table sorties par jointure client+date)
"""
from alembic import op

revision = '022'
down_revision = '021'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
        ALTER TABLE instance_produits
            ADD COLUMN IF NOT EXISTS date_archive TIMESTAMPTZ,
            ADD COLUMN IF NOT EXISTS utilisateur_validation VARCHAR(50);
    """)
    op.execute("""
        CREATE INDEX IF NOT EXISTS ix_instance_produits_date_archive
            ON instance_produits (date_archive)
            WHERE date_archive IS NOT NULL;
    """)


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS ix_instance_produits_date_archive;")
    op.execute("""
        ALTER TABLE instance_produits
            DROP COLUMN IF EXISTS date_archive,
            DROP COLUMN IF EXISTS utilisateur_validation;
    """)
