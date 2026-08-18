"""kpi_definitions — ajout colonne poids + seed KPIs par défaut

Revision ID: 008
Revises: 007
Create Date: 2026-03-29
"""
from alembic import op
import sqlalchemy as sa

revision = "008"
down_revision = "007"
branch_labels = None
depends_on = None

# KPIs par défaut avec leurs poids initiaux (total = 100)
DEFAULT_KPIS = [
    ("ca_realise",          "CA réalisé",                 "ventes",       "DA",    30),
    ("nb_ventes",           "Nombre de ventes",           "ventes",       "nb",    20),
    ("nb_lignes",           "Nombre de lignes",           "productivite", "nb",     5),
    ("panier_moyen",        "Panier moyen",               "ventes",       "DA",    10),
    ("ca_complement_alim",  "CA Compléments alimentaires","ventes",       "DA",    15),
    ("ventes_peremption_3", "Ventes péremption <3 mois",  "stock",        "nb",    20),
    ("ventes_peremption_6", "Ventes péremption <6 mois",  "stock",        "nb",     0),
    ("ventes_peremption_9", "Ventes péremption <9 mois",  "stock",        "nb",     0),
]


def upgrade():
    # 1. Ajouter colonne poids
    op.add_column(
        "kpi_definitions",
        sa.Column("poids", sa.Numeric(5, 2), nullable=False, server_default="0"),
    )

    # 2. Seed les KPI definitions si la table est vide
    conn = op.get_bind()
    count = conn.execute(sa.text("SELECT COUNT(*) FROM kpi_definitions")).scalar()
    if count == 0:
        for code, libelle, categorie, unite, poids in DEFAULT_KPIS:
            conn.execute(sa.text("""
                INSERT INTO kpi_definitions (code, libelle, categorie, unite, poids, actif)
                VALUES (:code, :libelle, :categorie, :unite, :poids, TRUE)
                ON CONFLICT (code) DO NOTHING
            """), {"code": code, "libelle": libelle, "categorie": categorie,
                   "unite": unite, "poids": poids})
    else:
        # Ajouter les KPIs manquants sans toucher aux poids existants
        for code, libelle, categorie, unite, poids in DEFAULT_KPIS:
            conn.execute(sa.text("""
                INSERT INTO kpi_definitions (code, libelle, categorie, unite, poids, actif)
                VALUES (:code, :libelle, :categorie, :unite, :poids, TRUE)
                ON CONFLICT (code) DO NOTHING
            """), {"code": code, "libelle": libelle, "categorie": categorie,
                   "unite": unite, "poids": poids})


def downgrade():
    op.drop_column("kpi_definitions", "poids")
