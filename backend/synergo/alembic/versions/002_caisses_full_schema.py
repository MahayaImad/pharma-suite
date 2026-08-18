"""caisses and caisses_regies full schema matching HFSQL

Revision ID: 002
Revises: 001
Create Date: 2026-03-27
"""
from alembic import op
import sqlalchemy as sa

revision = '002'
down_revision = '001'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
        DO $$
        BEGIN
            -- ── caisses ──────────────────────────────────────────────────────────
            -- Remove columns that don't exist in HFSQL
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses' AND column_name='solde') THEN
                ALTER TABLE caisses DROP COLUMN solde;
            END IF;
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses' AND column_name='solde_initial') THEN
                ALTER TABLE caisses DROP COLUMN solde_initial;
            END IF;
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses' AND column_name='actif') THEN
                ALTER TABLE caisses DROP COLUMN actif;
            END IF;
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses' AND column_name='poste_associe') THEN
                ALTER TABLE caisses DROP COLUMN poste_associe;
            END IF;

            -- Fix caisse column length
            ALTER TABLE caisses ALTER COLUMN caisse TYPE VARCHAR(50);

            -- Add missing HFSQL columns
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses' AND column_name='date_creation') THEN
                ALTER TABLE caisses ADD COLUMN date_creation DATE;
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses' AND column_name='etat') THEN
                ALTER TABLE caisses ADD COLUMN etat SMALLINT;
            END IF;

            -- Add index on caisse
            IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE tablename='caisses' AND indexname='ix_caisses_caisse') THEN
                CREATE INDEX ix_caisses_caisse ON caisses (caisse);
            END IF;

            -- ── caisses_regies ───────────────────────────────────────────────────
            -- Remove wrong columns
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='caisse') THEN
                ALTER TABLE caisses_regies DROP COLUMN caisse;
            END IF;
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='solde') THEN
                ALTER TABLE caisses_regies DROP COLUMN solde;
            END IF;
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='solde_initial') THEN
                ALTER TABLE caisses_regies DROP COLUMN solde_initial;
            END IF;
            IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='actif') THEN
                ALTER TABLE caisses_regies DROP COLUMN actif;
            END IF;

            -- Add all HFSQL columns
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='date_debut') THEN
                ALTER TABLE caisses_regies ADD COLUMN date_debut DATE;
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='heure_debut') THEN
                ALTER TABLE caisses_regies ADD COLUMN heure_debut VARCHAR(10);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='date_fin') THEN
                ALTER TABLE caisses_regies ADD COLUMN date_fin DATE;
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='heure_fin') THEN
                ALTER TABLE caisses_regies ADD COLUMN heure_fin VARCHAR(10);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='fond_de_caisse') THEN
                ALTER TABLE caisses_regies ADD COLUMN fond_de_caisse NUMERIC(15,4);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='total_calcule') THEN
                ALTER TABLE caisses_regies ADD COLUMN total_calcule NUMERIC(15,4);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='total_reel') THEN
                ALTER TABLE caisses_regies ADD COLUMN total_reel NUMERIC(15,4);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='etat_cloture') THEN
                ALTER TABLE caisses_regies ADD COLUMN etat_cloture SMALLINT;
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='poste') THEN
                ALTER TABLE caisses_regies ADD COLUMN poste INTEGER;
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='modif') THEN
                ALTER TABLE caisses_regies ADD COLUMN modif SMALLINT;
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='util_ouvre') THEN
                ALTER TABLE caisses_regies ADD COLUMN util_ouvre VARCHAR(50);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='util_cloture') THEN
                ALTER TABLE caisses_regies ADD COLUMN util_cloture VARCHAR(50);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='ventes') THEN
                ALTER TABLE caisses_regies ADD COLUMN ventes NUMERIC(15,4);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='retours') THEN
                ALTER TABLE caisses_regies ADD COLUMN retours NUMERIC(15,4);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='versements_clients') THEN
                ALTER TABLE caisses_regies ADD COLUMN versements_clients NUMERIC(15,4);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='remboursements_clients') THEN
                ALTER TABLE caisses_regies ADD COLUMN remboursements_clients NUMERIC(15,4);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='versements_fournisseurs') THEN
                ALTER TABLE caisses_regies ADD COLUMN versements_fournisseurs NUMERIC(15,4);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='remboursements_fournisseurs') THEN
                ALTER TABLE caisses_regies ADD COLUMN remboursements_fournisseurs NUMERIC(15,4);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='alimentations') THEN
                ALTER TABLE caisses_regies ADD COLUMN alimentations NUMERIC(15,4);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='depenses') THEN
                ALTER TABLE caisses_regies ADD COLUMN depenses NUMERIC(15,4);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='virement_de_fond_entrant') THEN
                ALTER TABLE caisses_regies ADD COLUMN virement_de_fond_entrant NUMERIC(15,4);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='virement_de_fond_sortant') THEN
                ALTER TABLE caisses_regies ADD COLUMN virement_de_fond_sortant NUMERIC(15,4);
            END IF;
            IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='caisses_regies' AND column_name='indice_ouverture') THEN
                ALTER TABLE caisses_regies ADD COLUMN indice_ouverture NUMERIC(10,4);
            END IF;
        END$$;
    """)


def downgrade() -> None:
    pass
