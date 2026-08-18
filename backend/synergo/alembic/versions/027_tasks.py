"""Gestion des tâches — templates + assignations + jours fériés

Revision ID: 027
Revises: 026
Create Date: 2026-04-22
"""

from alembic import op
import sqlalchemy as sa

revision = "027"
down_revision = "026"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── Modèles de tâches (définitions réutilisables) ──────────────────────
    op.create_table(
        "task_templates",
        sa.Column("id",           sa.String(36),   primary_key=True, comment="UUID"),
        sa.Column("title",        sa.String(200),  nullable=False),
        sa.Column("category",     sa.String(50),   nullable=False,
                  comment="stock | accueil | administrative | maintenance"),
        sa.Column("duration_min", sa.Integer(),    nullable=False, server_default="30"),
        sa.Column("recurrence",   sa.String(20),   nullable=False, server_default="manual",
                  comment="manual | daily | weekly | monthly"),
        sa.Column("auto_assign",  sa.Boolean(),    nullable=False, server_default="false"),
        sa.Column("day_of_week",  sa.SmallInteger(), nullable=True,
                  comment="weekly: 0=lun 6=dim"),
        sa.Column("day_of_month", sa.SmallInteger(), nullable=True,
                  comment="monthly: 1-31"),
        sa.Column("priority",     sa.String(20),   nullable=False, server_default="normal",
                  comment="low | normal | high | urgent"),
        sa.Column("is_active",    sa.Boolean(),    nullable=False, server_default="true"),
        sa.Column("created_by",   sa.BigInteger(), sa.ForeignKey("users.id", ondelete="SET NULL"),
                  nullable=True),
        sa.Column("created_at",   sa.DateTime(timezone=True), server_default=sa.text("NOW()")),
    )
    op.create_index("ix_task_templates_category",   "task_templates", ["category"])
    op.create_index("ix_task_templates_recurrence", "task_templates", ["recurrence"])

    # ── Assignations quotidiennes ──────────────────────────────────────────
    op.create_table(
        "task_assignments",
        sa.Column("id",             sa.String(36),  primary_key=True, comment="UUID"),
        sa.Column("template_id",    sa.String(36),
                  sa.ForeignKey("task_templates.id", ondelete="CASCADE"), nullable=True),
        sa.Column("title",          sa.String(200), nullable=False,
                  comment="Dénormalisé — conservé si template supprimé"),
        sa.Column("category",       sa.String(50),  nullable=False),
        sa.Column("duration_min",   sa.Integer(),   nullable=False, server_default="30"),
        sa.Column("priority",       sa.String(20),  nullable=False, server_default="normal"),
        sa.Column("assigned_to",    sa.BigInteger(),
                  sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("assigned_date",  sa.Date(),      nullable=False, server_default=sa.text("CURRENT_DATE")),
        sa.Column("scheduled_time", sa.Time(),      nullable=True),
        sa.Column("status",         sa.String(20),  nullable=False, server_default="pending",
                  comment="pending | in_progress | done | skipped"),
        sa.Column("started_at",     sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at",   sa.DateTime(timezone=True), nullable=True),
        sa.Column("note",           sa.Text(),      nullable=True),
        sa.Column("created_at",     sa.DateTime(timezone=True), server_default=sa.text("NOW()")),
    )
    op.create_index("ix_task_assignments_date",        "task_assignments", ["assigned_date"])
    op.create_index("ix_task_assignments_user_date",   "task_assignments", ["assigned_to", "assigned_date"])
    op.create_index("ix_task_assignments_status",      "task_assignments", ["status"])

    # ── Jours fériés ──────────────────────────────────────────────────────
    op.create_table(
        "holidays",
        sa.Column("id",    sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("date",  sa.Date(),    nullable=False, unique=True),
        sa.Column("label", sa.String(100), nullable=True),
    )

    # Jours fériés algériens fixes
    op.execute("""
        INSERT INTO holidays (date, label) VALUES
        ('2026-01-01', 'Nouvel an'),
        ('2026-05-01', 'Fête du Travail'),
        ('2026-07-05', 'Fête de l''Indépendance'),
        ('2026-11-01', 'Fête de la Révolution')
        ON CONFLICT DO NOTHING
    """)


def downgrade() -> None:
    op.drop_table("holidays")
    op.drop_index("ix_task_assignments_status",    "task_assignments")
    op.drop_index("ix_task_assignments_user_date", "task_assignments")
    op.drop_index("ix_task_assignments_date",      "task_assignments")
    op.drop_table("task_assignments")
    op.drop_index("ix_task_templates_recurrence", "task_templates")
    op.drop_index("ix_task_templates_category",   "task_templates")
    op.drop_table("task_templates")
