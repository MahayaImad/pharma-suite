"""KPI — score_peremption et score_crm_ald

Revision ID: 037
Revises: 036
Create Date: 2026-04-26
"""
from alembic import op
import sqlalchemy as sa

revision = "037"
down_revision = "036"
branch_labels = None
depends_on = None

_NEW_KPIS = [
    (
        "score_peremption",
        "Score péremption",
        "ventes",
        "pts",
        "3 pts/100 DA (0-3 mois) + 2 pts/100 DA (4-6 mois) + 1 pt/100 DA (7-9 mois)",
        0,
    ),
    (
        "score_crm_ald",
        "Score CRM ALD",
        "crm",
        "pts",
        "Interféron=10 pts, Insuline=5, Cardio/Psychiatrie=3, autre ALD=1 — par client nouveau/récupéré",
        0,
    ),
]


def upgrade():
    conn = op.get_bind()
    for code, libelle, categorie, unite, description, poids in _NEW_KPIS:
        conn.execute(sa.text("""
            INSERT INTO kpi_definitions
                (code, libelle, categorie, unite, poids, actif)
            VALUES (:code, :libelle, :categorie, :unite, :poids, TRUE)
            ON CONFLICT (code) DO UPDATE SET
                libelle   = EXCLUDED.libelle,
                categorie = EXCLUDED.categorie,
                unite     = EXCLUDED.unite,
                actif     = TRUE
        """), {"code": code, "libelle": libelle, "categorie": categorie,
               "unite": unite, "poids": poids})


def downgrade():
    op.get_bind().execute(
        sa.text("DELETE FROM kpi_definitions WHERE code IN ('score_peremption', 'score_crm_ald')")
    )
