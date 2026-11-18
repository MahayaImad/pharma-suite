"""paie : historique des calculs de primes

`performance_mensuelle` est unique par (employé, année, mois) et chaque
recalcul l'écrasait : impossible de répondre à une contestation (« le mois
dernier on m'avait annoncé autre chose »). Chaque calcul garde désormais une
trace complète :

- `primes_calculs` : un calcul (mois, enveloppe, qui, quand) ;
- `primes_calculs_lignes` : la ligne de chaque employé dans ce calcul
  (KPIs, score, plancher, mérite, prime).

`performance_mensuelle` reste le dernier calcul, celui qu'on valide.

Revision ID: 020
Revises: 019
Create Date: 2026-11-18
"""
import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "020"
down_revision = "019"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "primes_calculs",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("annee", sa.Integer, nullable=False),
        sa.Column("mois", sa.Integer, nullable=False),
        sa.Column("enveloppe", sa.Numeric(14, 2), nullable=False),
        sa.Column("calcule_le", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("calcule_par", sa.String(100)),
    )
    op.create_index("ix_primes_calculs_mois", "primes_calculs", ["annee", "mois"])
    op.create_table(
        "primes_calculs_lignes",
        sa.Column("id_calcul", sa.BigInteger, sa.ForeignKey("primes_calculs.id", ondelete="CASCADE"),
                  primary_key=True),
        sa.Column("employe_id", sa.Integer, primary_key=True),
        sa.Column("kpis", postgresql.JSONB),
        sa.Column("score_global", sa.Numeric(14, 4), nullable=False),
        sa.Column("plancher", sa.Numeric(14, 2), nullable=False),
        sa.Column("merite", sa.Numeric(14, 2), nullable=False),
        sa.Column("prime", sa.Numeric(14, 2), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("primes_calculs_lignes")
    op.drop_table("primes_calculs")
