"""nomenclature classification schema

Revision ID: 005
Revises: 004
Create Date: 2026-03-29
"""
from alembic import op

revision = '005'
down_revision = '004'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── Création de la table ───────────────────────────────────────────────────
    op.execute("""
        CREATE TABLE IF NOT EXISTS nomenclature_classification (
            id          SERIAL PRIMARY KEY,
            prefix      VARCHAR(10) UNIQUE NOT NULL,
            designation VARCHAR(200),
            etagere     VARCHAR(50),
            employe_id  INTEGER REFERENCES employes(id) ON DELETE SET NULL
        );
    """)

    op.execute("""
        CREATE INDEX IF NOT EXISTS ix_nomenclature_classification_prefix
            ON nomenclature_classification(prefix);
    """)

    op.execute("""
        CREATE INDEX IF NOT EXISTS ix_nomenclature_classification_employe
            ON nomenclature_classification(employe_id);
    """)

    # ── Désignations prédéfinies des familles thérapeutiques ──────────────────
    op.execute("""
        INSERT INTO nomenclature_classification (prefix, designation) VALUES
            ('01A', 'Anesthesiques generaux'),
            ('01B', 'Anesthesiques locaux'),
            ('02A', 'Antiacides et antiulcereux'),
            ('03A', 'Antispasmodiques digestifs'),
            ('04A', 'Antihistaminiques'),
            ('05A', 'Antineoplasiques'),
            ('05B', 'Immunosuppresseurs'),
            ('05C', 'Therapies ciblees oncologiques'),
            ('06A', 'Antihypertenseurs'),
            ('06B', 'Diuretiques'),
            ('06C', 'Vasodilatateurs'),
            ('06D', 'Antiarythmiques'),
            ('07A', 'Antibiotiques'),
            ('07B', 'Antiviraux'),
            ('07C', 'Antifongiques'),
            ('07D', 'Antiparasitaires'),
            ('08A', 'Antalgiques'),
            ('08B', 'Anti-inflammatoires'),
            ('08C', 'Antipyretiques'),
            ('09A', 'Psychotropes'),
            ('09B', 'Anxiolytiques'),
            ('09C', 'Antidepresseurs'),
            ('10A', 'Hormones'),
            ('10B', 'Contraceptifs'),
            ('11A', 'Vitamines'),
            ('11B', 'Mineraux'),
            ('12A', 'Solutions injectables'),
            ('13A', 'Dermatologie'),
            ('14A', 'Antidiabetiques'),
            ('14B', 'Hypolipemiants'),
            ('14C', 'Traitement de l obesite'),
            ('15A', 'Appareil respiratoire'),
            ('16A', 'Ophtalmologie'),
            ('17A', 'ORL'),
            ('18A', 'Appareil locomoteur'),
            ('19A', 'Urologie'),
            ('20A', 'Divers')
        ON CONFLICT (prefix) DO UPDATE SET designation = EXCLUDED.designation;
    """)

    # ── Import des préfixes restants depuis nomenclature.de_equiv ─────────────
    op.execute("""
        INSERT INTO nomenclature_classification (prefix)
        SELECT DISTINCT LEFT(de_equiv, 3)
        FROM nomenclature
        WHERE de_equiv IS NOT NULL
          AND LENGTH(TRIM(de_equiv)) >= 3
        ON CONFLICT (prefix) DO NOTHING;
    """)


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS nomenclature_classification CASCADE;")
