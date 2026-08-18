"""Add presences_overrides table

Revision ID: 032
Revises: 031
Create Date: 2026-04-25
"""
from alembic import op
import sqlalchemy as sa

revision = '032'
down_revision = '031'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'presences_overrides',
        sa.Column('id', sa.Integer, primary_key=True, autoincrement=True),
        sa.Column('employe_id', sa.Integer, sa.ForeignKey('employes.id', ondelete='CASCADE'), nullable=False),
        sa.Column('date', sa.Date, nullable=False),
        sa.Column('statut', sa.String(20), nullable=False),
        sa.Column('note', sa.Text, nullable=True),
        sa.Column('created_by', sa.String(50), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.UniqueConstraint('employe_id', 'date', name='uq_presence_employe_date'),
    )
    op.create_index('ix_presences_overrides_employe_date', 'presences_overrides', ['employe_id', 'date'])


def downgrade() -> None:
    op.drop_index('ix_presences_overrides_employe_date', table_name='presences_overrides')
    op.drop_table('presences_overrides')
