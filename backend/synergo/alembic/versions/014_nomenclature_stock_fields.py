"""Ajout colonnes archive, segment_abc, segment_xyz, disponibilite à nomenclature

Revision ID: 014
Revises: 013
Create Date: 2026-04-03

- archive       : boolean (défaut false) — produit retiré du marché, positionné manuellement
- segment_abc   : char(1) nullable  — A/B/C calculé mensuellement (chiffre d'affaires)
- segment_xyz   : char(1) nullable  — X/Y/Z calculé mensuellement (coefficient de variation)
- disponibilite : varchar(10) (défaut 'oui') — oui/rupture/quota
                  oui et rupture sont mis à jour automatiquement à chaque sync
                  quota est positionné manuellement et réinitialisé si stock > seuil
"""
from alembic import op
import sqlalchemy as sa

revision = '014'
down_revision = '013'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        'nomenclature',
        sa.Column('archive', sa.Boolean(), nullable=False, server_default='false'),
    )
    op.add_column(
        'nomenclature',
        sa.Column('segment_abc', sa.String(1), nullable=True),
    )
    op.add_column(
        'nomenclature',
        sa.Column('segment_xyz', sa.String(1), nullable=True),
    )
    op.add_column(
        'nomenclature',
        sa.Column('disponibilite', sa.String(10), nullable=False, server_default="'oui'"),
    )
    # Index partiel pour accélérer les lookups de rupture et quota
    op.create_index(
        'ix_nomenclature_disponibilite',
        'nomenclature',
        ['disponibilite'],
        postgresql_where=sa.text("disponibilite != 'oui'"),
    )
    op.create_index(
        'ix_nomenclature_segment_abc',
        'nomenclature',
        ['segment_abc'],
    )


def downgrade() -> None:
    op.drop_index('ix_nomenclature_segment_abc', table_name='nomenclature')
    op.drop_index('ix_nomenclature_disponibilite', table_name='nomenclature')
    op.drop_column('nomenclature', 'disponibilite')
    op.drop_column('nomenclature', 'segment_xyz')
    op.drop_column('nomenclature', 'segment_abc')
    op.drop_column('nomenclature', 'archive')
