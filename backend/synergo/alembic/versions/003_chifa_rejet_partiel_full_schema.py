"""chifa_rejet_partiel full schema matching HFSQL

Revision ID: 003
Revises: 002
Create Date: 2026-03-27
"""
from alembic import op

revision = '003'
down_revision = '002'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
        DO $$
        BEGIN
            -- Remove wrong columns
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='chifa_rejet_partiel' AND column_name='id_facture') THEN
                ALTER TABLE chifa_rejet_partiel DROP COLUMN id_facture;
            END IF;
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='chifa_rejet_partiel' AND column_name='id_nom') THEN
                ALTER TABLE chifa_rejet_partiel DROP COLUMN id_nom;
            END IF;
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='chifa_rejet_partiel' AND column_name='nom') THEN
                ALTER TABLE chifa_rejet_partiel DROP COLUMN nom;
            END IF;
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='chifa_rejet_partiel' AND column_name='qte_rejetee') THEN
                ALTER TABLE chifa_rejet_partiel DROP COLUMN qte_rejetee;
            END IF;
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='chifa_rejet_partiel' AND column_name='montant_rejete') THEN
                ALTER TABLE chifa_rejet_partiel DROP COLUMN montant_rejete;
            END IF;
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='chifa_rejet_partiel' AND column_name='motif') THEN
                ALTER TABLE chifa_rejet_partiel DROP COLUMN motif;
            END IF;

            -- Add correct HFSQL columns
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='chifa_rejet_partiel' AND column_name='num_bordereau') THEN
                ALTER TABLE chifa_rejet_partiel ADD COLUMN num_bordereau VARCHAR(30);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='chifa_rejet_partiel' AND column_name='num_facture') THEN
                ALTER TABLE chifa_rejet_partiel ADD COLUMN num_facture VARCHAR(30);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='chifa_rejet_partiel' AND column_name='montant') THEN
                ALTER TABLE chifa_rejet_partiel ADD COLUMN montant NUMERIC(15,4);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='chifa_rejet_partiel' AND column_name='observation') THEN
                ALTER TABLE chifa_rejet_partiel ADD COLUMN observation VARCHAR(500);
            END IF;
        END$$;
    """)


def downgrade() -> None:
    pass
