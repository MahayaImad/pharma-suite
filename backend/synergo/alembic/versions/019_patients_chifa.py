"""Créer patients_chifa — malades chroniques identifiés via HFSQL

Revision ID: 019
Revises: 018
Create Date: 2026-04-08
"""
from alembic import op

revision = '019'
down_revision = '018'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
    CREATE TABLE IF NOT EXISTS patients_chifa (
        id                  SERIAL PRIMARY KEY,
        no_assure           VARCHAR(20) NOT NULL,
        rang_ad             VARCHAR(4)  NOT NULL,
        type_beneficiaire   VARCHAR(20),
        centre              VARCHAR(50),
        premiere_visite     DATE,
        derniere_visite     DATE,
        nb_visites          INTEGER     DEFAULT 0,
        intervalle_moyen    NUMERIC(6,1),
        prochain_visite_est DATE,
        statut              VARCHAR(20) NOT NULL DEFAULT 'actif',
        mt_total_assure     NUMERIC(12,2) DEFAULT 0,
        mt_total_officine   NUMERIC(12,2) DEFAULT 0,
        taux_remb_moyen     NUMERIC(5,2),
        maladies            VARCHAR(10)[],
        classes_medicaments VARCHAR(10)[],
        calcule_le          TIMESTAMPTZ DEFAULT NOW(),
        CONSTRAINT uq_patient_chifa UNIQUE (no_assure, rang_ad)
    )
    """)

    op.execute("CREATE INDEX IF NOT EXISTS ix_patients_chifa_statut         ON patients_chifa (statut)")
    op.execute("CREATE INDEX IF NOT EXISTS ix_patients_chifa_derniere_visite ON patients_chifa (derniere_visite)")
    op.execute("CREATE INDEX IF NOT EXISTS ix_patients_chifa_no_assure       ON patients_chifa (no_assure)")


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS patients_chifa")
