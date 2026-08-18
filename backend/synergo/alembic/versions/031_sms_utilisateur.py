"""Add utilisateur to sms_logs

Revision ID: 031
Revises: 030
Create Date: 2026-04-25
"""
from alembic import op
import sqlalchemy as sa

revision = '031'
down_revision = '030'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('sms_logs', sa.Column('utilisateur', sa.String(50), nullable=True))
    op.create_index('ix_sms_logs_utilisateur', 'sms_logs', ['utilisateur'])


def downgrade() -> None:
    op.drop_index('ix_sms_logs_utilisateur', table_name='sms_logs')
    op.drop_column('sms_logs', 'utilisateur')
