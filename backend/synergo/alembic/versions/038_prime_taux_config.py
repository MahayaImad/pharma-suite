"""prime_taux_config — taux de prime par catégorie de produit

Revision ID: 038
Revises: 037
Create Date: 2026-04-26
"""
from alembic import op
import sqlalchemy as sa

revision = "038"
down_revision = "037"
branch_labels = None
depends_on = None


def upgrade():
    conn = op.get_bind()

    # Créer la table seulement si elle n'existe pas déjà
    conn.execute(sa.text("""
        CREATE TABLE IF NOT EXISTS prime_taux_config (
            id             SERIAL PRIMARY KEY,
            nom            VARCHAR(100) NOT NULL UNIQUE,
            taux_pct       NUMERIC(5, 3) NOT NULL DEFAULT 0,
            filtre_famille VARCHAR(200),
            actif          BOOLEAN NOT NULL DEFAULT TRUE,
            updated_at     TIMESTAMP WITH TIME ZONE DEFAULT now()
        )
    """))

    # Seed des 3 catégories par défaut
    # filtre_famille utilise le préfixe 'gentype:' pour filtrer via nomenclature.generique
    conn.execute(sa.text("""
        INSERT INTO prime_taux_config (nom, taux_pct, filtre_famille, actif) VALUES
            ('Princeps',     0.500, :p1, TRUE),
            ('Générique',    1.000, :p2, TRUE),
            ('Générique++',  3.000, :p3, TRUE)
        ON CONFLICT (nom) DO NOTHING
    """), {"p1": "gentype:princeps", "p2": "gentype:generique", "p3": "gentype:generique_remb"})


def downgrade():
    op.drop_table("prime_taux_config")
