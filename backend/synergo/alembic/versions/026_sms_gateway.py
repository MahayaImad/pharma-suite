"""Table sms_logs — journal des SMS envoyés via gateway Android

Revision ID: 026
Revises: 025
Create Date: 2026-04-13
"""

from alembic import op
import sqlalchemy as sa

revision = "026"
down_revision = "025"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "sms_logs",
        sa.Column("id",         sa.String(36),  primary_key=True,  comment="UUID"),
        sa.Column("phone",      sa.String(20),  nullable=False,    comment="Numéro destinataire"),
        sa.Column("message",    sa.Text(),       nullable=False,    comment="Corps du SMS"),
        sa.Column("status",     sa.String(20),  nullable=False,
                  server_default="pending",
                  comment="pending | sent | failed | cancelled"),
        sa.Column("error",      sa.Text(),       nullable=True,     comment="Message d'erreur"),
        sa.Column("retries",    sa.SmallInteger(), nullable=False,  server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True),
                  server_default=sa.text("NOW()"), nullable=False),
        sa.Column("sent_at",    sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_sms_logs_status",     "sms_logs", ["status"])
    op.create_index("ix_sms_logs_created_at", "sms_logs", ["created_at"])


def downgrade() -> None:
    op.drop_index("ix_sms_logs_created_at", "sms_logs")
    op.drop_index("ix_sms_logs_status",     "sms_logs")
    op.drop_table("sms_logs")
