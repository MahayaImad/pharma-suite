"""Ajoute last_seen_at aux users — détection d'inactivité pour tâches

Revision ID: 028
Revises: 027
Create Date: 2026-04-22
"""

from alembic import op
import sqlalchemy as sa

revision = "028"
down_revision = "027"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column(
            "last_seen_at",
            sa.DateTime(timezone=True),
            nullable=True,
            comment="Dernière activité — mis à jour par le middleware",
        ),
    )
    op.create_index("ix_users_last_seen_at", "users", ["last_seen_at"])


def downgrade() -> None:
    op.drop_index("ix_users_last_seen_at", "users")
    op.drop_column("users", "last_seen_at")
