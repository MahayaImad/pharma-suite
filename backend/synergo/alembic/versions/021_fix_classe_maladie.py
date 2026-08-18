"""Corriger classe_maladie — supprimer/modifier des mappings non pertinents

Revision ID: 021
Revises: 020
Create Date: 2026-04-08

Changements :
  - Supprimer 01 A et 01 D (allergie chronique — trop large)
  - Remplacer 07 H par 07 S pour C033 (Daivobet → psoriasis)
  - Supprimer 09 H → C017 (rhumatologie via endocrino, non pertinent)
  - Supprimer 10 G → C040 (reflux, trop courant)
  - Supprimer 12 B et 12 E (hématologie générale)
"""
from alembic import op

revision = '021'
down_revision = '020'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Supprimer les préfixes non pertinents
    op.execute("""
    DELETE FROM classe_maladie
    WHERE (prefix = '01 A')
       OR (prefix = '01 D')
       OR (prefix = '09 H' AND code_maladie = 'C017')
       OR (prefix = '10 G' AND code_maladie = 'C040')
       OR (prefix = '12 B')
       OR (prefix = '12 E')
    """)

    # Remplacer 07 H par 07 S pour le psoriasis (Daivobet et similaires)
    op.execute("""
    UPDATE classe_maladie
    SET prefix = '07 S'
    WHERE prefix = '07 H' AND code_maladie = 'C033'
    """)


def downgrade() -> None:
    # Restaurer les suppressions
    op.execute("""
    INSERT INTO classe_maladie (prefix, code_maladie) VALUES
    ('01 A','C038'),('01 D','C038'),
    ('09 H','C017'),
    ('10 G','C040'),
    ('12 B','C008'),
    ('12 E','C004')
    ON CONFLICT DO NOTHING
    """)

    # Restaurer 07 H
    op.execute("""
    UPDATE classe_maladie
    SET prefix = '07 H'
    WHERE prefix = '07 S' AND code_maladie = 'C033'
    """)
