"""élargir indice_ouverture (suivi_caisses, caisses_regies)

Au premier chargement complet, les 3 924 lignes de `suivi_caisses` ont été
refusées alors que toutes les autres tables passaient. `indice_ouverture`
était en NUMERIC(10, 4), soit 999 999 au plus : même symptôme que
`operations.indice_creation`, un horodatage concaténé côté HFSQL
(16 chiffres) qu'il avait déjà fallu élargir. Élargir ne perd rien.

Revision ID: 003
Revises: 002
Create Date: 2026-11-10
"""
import sqlalchemy as sa
from alembic import op

revision = "003"
down_revision = "002"
branch_labels = None
depends_on = None

TABLES = ("suivi_caisses", "caisses_regies")


def upgrade() -> None:
    for table in TABLES:
        op.alter_column(table, "indice_ouverture",
                        type_=sa.Numeric(20, 4), existing_type=sa.Numeric(10, 4))


def downgrade() -> None:
    for table in TABLES:
        op.alter_column(table, "indice_ouverture",
                        type_=sa.Numeric(10, 4), existing_type=sa.Numeric(20, 4))
