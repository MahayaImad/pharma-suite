"""seed nomenclature_classification designations

Revision ID: 006
Revises: 005
Create Date: 2026-03-29
"""
from alembic import op

revision = '006'
down_revision = '005'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Insère (ou met à jour) les 37 familles thérapeutiques prédéfinies
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


def downgrade() -> None:
    op.execute("""
        DELETE FROM nomenclature_classification
        WHERE prefix IN (
            '01A','01B','02A','03A','04A','05A','05B','05C',
            '06A','06B','06C','06D','07A','07B','07C','07D',
            '08A','08B','08C','09A','09B','09C','10A','10B',
            '11A','11B','12A','13A','14A','14B','14C',
            '15A','16A','17A','18A','19A','20A'
        );
    """)
