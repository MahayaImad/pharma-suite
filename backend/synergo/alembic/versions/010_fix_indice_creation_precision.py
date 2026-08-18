"""Fix indice_creation precision: NUMERIC(15,4) → NUMERIC(20,0)

Les valeurs HFSQL de indice_creation sont des horodatages concaténés
(ex: 2025060315181251 = 16 chiffres entiers) qui dépassent la précision
NUMERIC(15,4) (max 11 chiffres entiers). Le champ n'a jamais de décimales.

Revision ID: 010
Revises: 009
Create Date: 2026-03-31
"""
from alembic import op

revision = '010'
down_revision = '009'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
        ALTER TABLE operations
            ALTER COLUMN indice_creation TYPE NUMERIC(20, 0)
            USING indice_creation::NUMERIC(20, 0);
    """)


def downgrade() -> None:
    op.execute("""
        ALTER TABLE operations
            ALTER COLUMN indice_creation TYPE NUMERIC(15, 4)
            USING indice_creation::NUMERIC(15, 4);
    """)
