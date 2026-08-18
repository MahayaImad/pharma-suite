"""Ajoute sous-classes manquantes dans nomenclature_classification

Revision ID: 029
Revises: 028
Create Date: 2026-04-24
"""
from alembic import op

revision = '029'
down_revision = '028'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
        INSERT INTO nomenclature_classification (prefix, designation, niveau) VALUES
        ('06 E', 'ANTI-HYPERTENSEURS',                              2),
        ('07 A', 'ADJUVANTS DE LA CICATRISATION',                   2),
        ('07 G', 'ANTIPRURIGINEUX',                                 2),
        ('07 S', 'DIVERS',                                          2),
        ('10 K', 'ENZYMES DIGESTIVES',                              2),
        ('10 P', 'PROCTOLOGIE',                                     2),
        ('10 T', 'DIVERS',                                          2),
        ('13 K', 'QUINOLONES',                                      2),
        ('14 F', 'OREXIGENES',                                      2),
        ('15 K', 'ANTIMIGRAINEUX',                                  2),
        ('20 D', 'FLUIDIFIANTS BRONCHIQUES ET MUCOREGULATEURS',     2),
        ('22 A', 'ANTICORYZA PAR VOIE GENERALE',                    2)
        ON CONFLICT (prefix) DO UPDATE
            SET designation = EXCLUDED.designation,
                niveau      = EXCLUDED.niveau;
    """)


def downgrade() -> None:
    op.execute("""
        DELETE FROM nomenclature_classification
        WHERE prefix IN (
            '06 E', '07 A', '07 G', '07 S',
            '10 K', '10 P', '10 T',
            '13 K', '14 F', '15 K',
            '20 D', '22 A'
        );
    """)
