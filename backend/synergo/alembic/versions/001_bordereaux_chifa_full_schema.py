"""bordereaux_chifa full schema

Revision ID: 001
Revises:
Create Date: 2026-03-27
"""
from alembic import op
import sqlalchemy as sa

revision = '001'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Drop old simplified columns if they exist, then add all correct columns
    # Using ALTER TABLE to add missing columns and rename wrong ones

    # Check existing columns and migrate
    op.execute("""
        DO $$
        BEGIN
            -- Rename num_bordereau -> num_bord if exists
            IF EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_name='bordereaux_chifa' AND column_name='num_bordereau'
            ) THEN
                ALTER TABLE bordereaux_chifa RENAME COLUMN num_bordereau TO num_bord;
            END IF;

            -- Add num_bord if missing
            IF NOT EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_name='bordereaux_chifa' AND column_name='num_bord'
            ) THEN
                ALTER TABLE bordereaux_chifa ADD COLUMN num_bord VARCHAR(50);
            END IF;

            -- Remove old columns that no longer exist in schema
            IF EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_name='bordereaux_chifa' AND column_name='date'
            ) THEN
                ALTER TABLE bordereaux_chifa DROP COLUMN date;
            END IF;

            IF EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_name='bordereaux_chifa' AND column_name='total'
            ) THEN
                ALTER TABLE bordereaux_chifa DROP COLUMN total;
            END IF;

            IF EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_name='bordereaux_chifa' AND column_name='etat'
            ) THEN
                ALTER TABLE bordereaux_chifa DROP COLUMN etat;
            END IF;

            IF EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_name='bordereaux_chifa' AND column_name='utilisateur'
            ) THEN
                ALTER TABLE bordereaux_chifa DROP COLUMN utilisateur;
            END IF;

            -- Add all new columns if missing
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bordereaux_chifa' AND column_name='centre') THEN
                ALTER TABLE bordereaux_chifa ADD COLUMN centre VARCHAR(50);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bordereaux_chifa' AND column_name='nbr_fact') THEN
                ALTER TABLE bordereaux_chifa ADD COLUMN nbr_fact INTEGER;
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bordereaux_chifa' AND column_name='mnt_assure') THEN
                ALTER TABLE bordereaux_chifa ADD COLUMN mnt_assure NUMERIC(15,4);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bordereaux_chifa' AND column_name='mnt_officine') THEN
                ALTER TABLE bordereaux_chifa ADD COLUMN mnt_officine NUMERIC(15,4);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bordereaux_chifa' AND column_name='mnt_fae') THEN
                ALTER TABLE bordereaux_chifa ADD COLUMN mnt_fae NUMERIC(15,4);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bordereaux_chifa' AND column_name='mnt_majoration') THEN
                ALTER TABLE bordereaux_chifa ADD COLUMN mnt_majoration NUMERIC(15,4);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bordereaux_chifa' AND column_name='mnt_rej') THEN
                ALTER TABLE bordereaux_chifa ADD COLUMN mnt_rej NUMERIC(15,4);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bordereaux_chifa' AND column_name='versement') THEN
                ALTER TABLE bordereaux_chifa ADD COLUMN versement NUMERIC(15,4);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bordereaux_chifa' AND column_name='observation') THEN
                ALTER TABLE bordereaux_chifa ADD COLUMN observation VARCHAR(200);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bordereaux_chifa' AND column_name='dt_cloture') THEN
                ALTER TABLE bordereaux_chifa ADD COLUMN dt_cloture DATE;
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bordereaux_chifa' AND column_name='dt_validation') THEN
                ALTER TABLE bordereaux_chifa ADD COLUMN dt_validation DATE;
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bordereaux_chifa' AND column_name='dt_encaisse') THEN
                ALTER TABLE bordereaux_chifa ADD COLUMN dt_encaisse DATE;
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bordereaux_chifa' AND column_name='dt_depot') THEN
                ALTER TABLE bordereaux_chifa ADD COLUMN dt_depot DATE;
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bordereaux_chifa' AND column_name='archive') THEN
                ALTER TABLE bordereaux_chifa ADD COLUMN archive SMALLINT;
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bordereaux_chifa' AND column_name='dt_creation') THEN
                ALTER TABLE bordereaux_chifa ADD COLUMN dt_creation DATE;
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bordereaux_chifa' AND column_name='statut') THEN
                ALTER TABLE bordereaux_chifa ADD COLUMN statut VARCHAR(50);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bordereaux_chifa' AND column_name='extra') THEN
                ALTER TABLE bordereaux_chifa ADD COLUMN extra VARCHAR(2000);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bordereaux_chifa' AND column_name='obs_creation') THEN
                ALTER TABLE bordereaux_chifa ADD COLUMN obs_creation VARCHAR(200);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bordereaux_chifa' AND column_name='obs_cloture') THEN
                ALTER TABLE bordereaux_chifa ADD COLUMN obs_cloture VARCHAR(200);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bordereaux_chifa' AND column_name='obs_depot') THEN
                ALTER TABLE bordereaux_chifa ADD COLUMN obs_depot VARCHAR(200);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bordereaux_chifa' AND column_name='obs_validation') THEN
                ALTER TABLE bordereaux_chifa ADD COLUMN obs_validation VARCHAR(200);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bordereaux_chifa' AND column_name='obs_encaissement') THEN
                ALTER TABLE bordereaux_chifa ADD COLUMN obs_encaissement VARCHAR(200);
            END IF;

            -- Add indexes
            IF NOT EXISTS (
                SELECT 1 FROM pg_indexes WHERE tablename='bordereaux_chifa' AND indexname='ix_bordereaux_chifa_num_bord'
            ) THEN
                CREATE INDEX ix_bordereaux_chifa_num_bord ON bordereaux_chifa (num_bord);
            END IF;
            IF NOT EXISTS (
                SELECT 1 FROM pg_indexes WHERE tablename='bordereaux_chifa' AND indexname='ix_bordereaux_chifa_centre'
            ) THEN
                CREATE INDEX ix_bordereaux_chifa_centre ON bordereaux_chifa (centre);
            END IF;
        END$$;
    """)


def downgrade() -> None:
    pass
