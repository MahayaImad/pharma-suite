"""performance et inventaires schema

Revision ID: 004
Revises: 003
Create Date: 2026-03-28
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

revision = '004'
down_revision = '003'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
    DO $$
    BEGIN

    -- ── nomenclature: generique + etagere ─────────────────────────────────
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name='nomenclature' AND column_name='generique'
    ) THEN
        ALTER TABLE nomenclature ADD COLUMN generique SMALLINT DEFAULT 0;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name='nomenclature' AND column_name='etagere'
    ) THEN
        ALTER TABLE nomenclature ADD COLUMN etagere VARCHAR(50);
    END IF;

    -- ── inventaires ────────────────────────────────────────────────────────
    CREATE TABLE IF NOT EXISTS inventaires (
        id            BIGINT PRIMARY KEY,
        date          DATE,
        heure         VARCHAR(10),
        utilisateur   VARCHAR(50),
        poste         INTEGER,
        etat          SMALLINT,
        observations  VARCHAR(500)
    );
    CREATE INDEX IF NOT EXISTS ix_inventaires_date ON inventaires(date);

    -- ── inventaires_produits ───────────────────────────────────────────────
    CREATE TABLE IF NOT EXISTS inventaires_produits (
        id               BIGINT PRIMARY KEY,
        id_inventaire    BIGINT,
        date             DATE,
        id_nom           BIGINT,
        nom              VARCHAR(150),
        id_famille       INTEGER,
        famille          VARCHAR(50),
        code_barre       VARCHAR(30),
        lot              VARCHAR(50),
        peremption       VARCHAR(10),
        peremption_date  DATE,
        stock_theorique  BIGINT,
        stock_reel       BIGINT,
        ecart            BIGINT,
        prix_achat_ttc   NUMERIC(15,4),
        prix_vente       NUMERIC(15,4),
        motif            VARCHAR(200),
        utilisateur      VARCHAR(50),
        poste            INTEGER
    );
    CREATE INDEX IF NOT EXISTS ix_inventaires_produits_id_inventaire ON inventaires_produits(id_inventaire);
    CREATE INDEX IF NOT EXISTS ix_inventaires_produits_date ON inventaires_produits(date);

    -- ── employes ───────────────────────────────────────────────────────────
    CREATE TABLE IF NOT EXISTS employes (
        id              SERIAL PRIMARY KEY,
        user_id         INTEGER,
        username        VARCHAR(50) UNIQUE,
        nom             VARCHAR(100) NOT NULL,
        prenom          VARCHAR(100),
        poste           VARCHAR(100),
        date_entree     DATE,
        actif           BOOLEAN DEFAULT TRUE,
        eligible_prime  BOOLEAN DEFAULT TRUE,
        created_at      TIMESTAMPTZ DEFAULT NOW()
    );

    -- ── objectifs_mensuels ─────────────────────────────────────────────────
    CREATE TABLE IF NOT EXISTS objectifs_mensuels (
        id                   SERIAL PRIMARY KEY,
        annee                INTEGER NOT NULL,
        mois                 INTEGER NOT NULL,
        mode_prime           VARCHAR(10) DEFAULT 'yoy',
        objectif_benefice    NUMERIC(14,2),
        pct_enveloppe_prime  NUMERIC(5,2) DEFAULT 10,
        enveloppe_calculee   NUMERIC(14,2),
        notes                TEXT,
        UNIQUE(annee, mois)
    );

    -- ── kpi_definitions ────────────────────────────────────────────────────
    CREATE TABLE IF NOT EXISTS kpi_definitions (
        id          SERIAL PRIMARY KEY,
        code        VARCHAR(50) UNIQUE NOT NULL,
        libelle     VARCHAR(200) NOT NULL,
        description TEXT,
        categorie   VARCHAR(30),
        unite       VARCHAR(20),
        actif       BOOLEAN DEFAULT TRUE
    );

    -- Insérer les KPIs prédéfinis (idempotent)
    INSERT INTO kpi_definitions (code, libelle, description, categorie, unite) VALUES
        ('ca_realise',          'CA réalisé',                      'Chiffre d''affaires total réalisé par l''employé',                  'ventes',      'DA'),
        ('pct_generique',       '% Génériques',                    'Part des génériques dans les ventes en valeur',                     'ventes',      '%'),
        ('ca_complement_alim',  'CA Compléments alimentaires',     'CA sur la famille Compléments alimentaires',                        'ventes',      'DA'),
        ('taux_ventes_assoc',   'Taux ventes associées',           'Ratio de ventes contenant des produits associés (ex: probiotiques)','ventes',      '%'),
        ('taux_conv_promo',     'Taux conversion promotions',      'Part des produits en promotion vendus',                             'ventes',      '%'),
        ('nb_ventes',           'Nombre de ventes',                'Nombre total de transactions réalisées',                            'productivite','nb'),
        ('nb_lignes',           'Nombre de lignes de vente',       'Nombre total de lignes articles vendues',                           'productivite','nb'),
        ('panier_moyen',        'Panier moyen',                    'CA moyen par transaction',                                          'productivite','DA'),
        ('ventes_peremption_3', 'Ventes proche péremption <3 mois','Nb produits vendus avec péremption < 3 mois',                       'stock',       'nb'),
        ('ventes_peremption_6', 'Ventes proche péremption <6 mois','Nb produits vendus avec péremption < 6 mois',                       'stock',       'nb'),
        ('ventes_peremption_9', 'Ventes proche péremption <9 mois','Nb produits vendus avec péremption < 9 mois',                       'stock',       'nb'),
        ('scorecard_audit',     'Score audit organisation',        'Grille d''audit étagère — saisie manuelle admin (0-100)',            'audit',       'score')
    ON CONFLICT (code) DO NOTHING;

    -- ── performance_mensuelle ──────────────────────────────────────────────
    CREATE TABLE IF NOT EXISTS performance_mensuelle (
        id             SERIAL PRIMARY KEY,
        employe_id     INTEGER NOT NULL REFERENCES employes(id) ON DELETE CASCADE,
        annee          INTEGER NOT NULL,
        mois           INTEGER NOT NULL,
        kpis           JSONB,
        score_global   NUMERIC(5,2),
        pct_prime      NUMERIC(5,2),
        prime_calculee NUMERIC(14,2),
        valide         BOOLEAN DEFAULT FALSE,
        valide_par     VARCHAR(50),
        valide_le      TIMESTAMPTZ,
        UNIQUE(employe_id, annee, mois)
    );

    END $$;
    """)


def downgrade() -> None:
    op.execute("""
        DROP TABLE IF EXISTS performance_mensuelle CASCADE;
        DROP TABLE IF EXISTS kpi_definitions CASCADE;
        DROP TABLE IF EXISTS objectifs_mensuels CASCADE;
        DROP TABLE IF EXISTS employes CASCADE;
        DROP TABLE IF EXISTS inventaires_produits CASCADE;
        DROP TABLE IF EXISTS inventaires CASCADE;
        ALTER TABLE nomenclature DROP COLUMN IF EXISTS generique;
        ALTER TABLE nomenclature DROP COLUMN IF EXISTS etagere;
    """)
