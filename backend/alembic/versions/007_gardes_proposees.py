"""gardes proposées par la rotation

`gardes.source` accepte une troisième valeur, `prevision` : garde à venir
proposée d'après la rotation observée (soirée tous les 10 jours, vendredi
toutes les 10 semaines, 24 h toutes les 16 semaines environ), enregistrée
`confirme = false` jusqu'à confirmation par l'officine.

Revision ID: 007
Revises: 006
Create Date: 2026-11-12
"""
from alembic import op

revision = "007"
down_revision = "006"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.drop_constraint("ck_gardes_source", "gardes", type_="check")
    op.create_check_constraint("ck_gardes_source", "gardes", "source IN ('saisie', 'detection', 'prevision')")


def downgrade() -> None:
    op.execute("DELETE FROM gardes WHERE source = 'prevision'")
    op.drop_constraint("ck_gardes_source", "gardes", type_="check")
    op.create_check_constraint("ck_gardes_source", "gardes", "source IN ('saisie', 'detection')")
