"""Créer facture_anomalies et facture_rejets

Revision ID: 023
Revises: 022
Create Date: 2026-04-09

- facture_anomalies : erreurs signalées par l'employé vérificateur après clôture bordereau
  (utilisateur_erreur déduit depuis sorties.utilisateur via no_facture_chifa)
- facture_rejets : factures retournées par CNAS/CASNOS avec motif
"""
from alembic import op

revision = '023'
down_revision = '022'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
        CREATE TABLE IF NOT EXISTS facture_anomalies (
            id                      BIGSERIAL PRIMARY KEY,
            no_facture              VARCHAR(100) NOT NULL,
            no_bordereau            VARCHAR(100),
            type_anomalie           VARCHAR(50)  NOT NULL DEFAULT 'autre',
            description             TEXT,
            date_signalement        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
            utilisateur_signalement VARCHAR(50),
            utilisateur_erreur      VARCHAR(50),
            statut                  VARCHAR(20)  NOT NULL DEFAULT 'signalée'
        );

        CREATE INDEX IF NOT EXISTS ix_facture_anomalies_no_facture
            ON facture_anomalies (no_facture);
        CREATE INDEX IF NOT EXISTS ix_facture_anomalies_statut
            ON facture_anomalies (statut);
        CREATE INDEX IF NOT EXISTS ix_facture_anomalies_date
            ON facture_anomalies (date_signalement);
    """)

    op.execute("""
        CREATE TABLE IF NOT EXISTS facture_rejets (
            id              BIGSERIAL PRIMARY KEY,
            no_facture      VARCHAR(100) NOT NULL,
            no_bordereau    VARCHAR(100),
            caisse          VARCHAR(20)  NOT NULL DEFAULT 'CNAS',
            motif_rejet     TEXT,
            date_rejet      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
            montant_rejete  NUMERIC(15,4),
            statut          VARCHAR(20)  NOT NULL DEFAULT 'rejetée',
            date_traitement TIMESTAMPTZ
        );

        CREATE INDEX IF NOT EXISTS ix_facture_rejets_no_facture
            ON facture_rejets (no_facture);
        CREATE INDEX IF NOT EXISTS ix_facture_rejets_statut
            ON facture_rejets (statut);
        CREATE INDEX IF NOT EXISTS ix_facture_rejets_date
            ON facture_rejets (date_rejet);
    """)


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS facture_rejets;")
    op.execute("DROP TABLE IF EXISTS facture_anomalies;")
