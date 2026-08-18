"""Ajout colonnes archivage client (décès, doublon…)

Revision ID: 030
Revises: 029
"""
from alembic import op
import sqlalchemy as sa

revision = '030'
down_revision = '029'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('clients', sa.Column('is_archive',    sa.Boolean(),     server_default='false', nullable=False))
    op.add_column('clients', sa.Column('date_archive',  sa.Date(),        nullable=True))
    op.add_column('clients', sa.Column('motif_archive', sa.String(200),   nullable=True))
    op.create_index('ix_clients_is_archive', 'clients', ['is_archive'])


def downgrade() -> None:
    op.drop_index('ix_clients_is_archive', table_name='clients')
    op.drop_column('clients', 'motif_archive')
    op.drop_column('clients', 'date_archive')
    op.drop_column('clients', 'is_archive')
