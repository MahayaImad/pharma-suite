"""GRH — conges_annuels + demandes_conge

Revision ID: 033
Revises: 032
Create Date: 2026-04-26
"""
from alembic import op
import sqlalchemy as sa

revision = '033'
down_revision = '032'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('employes',
        sa.Column('conges_annuels', sa.Integer, nullable=False, server_default='30'))

    op.create_table(
        'demandes_conge',
        sa.Column('id', sa.Integer, primary_key=True, autoincrement=True),
        sa.Column('employe_id', sa.Integer,
                  sa.ForeignKey('employes.id', ondelete='CASCADE'), nullable=False),
        sa.Column('date_debut', sa.Date, nullable=False),
        sa.Column('date_fin',   sa.Date, nullable=False),
        sa.Column('nb_jours',   sa.Integer, nullable=False),
        sa.Column('type',       sa.String(20), nullable=False, server_default='annuel'),
        sa.Column('statut',     sa.String(20), nullable=False, server_default='en_attente'),
        sa.Column('note',       sa.Text, nullable=True),
        sa.Column('note_admin', sa.Text, nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index('ix_demandes_conge_employe', 'demandes_conge', ['employe_id'])
    op.create_index('ix_demandes_conge_statut',  'demandes_conge', ['statut'])


def downgrade() -> None:
    op.drop_index('ix_demandes_conge_statut',  table_name='demandes_conge')
    op.drop_index('ix_demandes_conge_employe', table_name='demandes_conge')
    op.drop_table('demandes_conge')
    op.drop_column('employes', 'conges_annuels')
