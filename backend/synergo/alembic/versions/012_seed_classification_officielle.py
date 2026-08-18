"""Classification pharmaceutique officielle DTC algérienne (hiérarchique)

Revision ID: 012
Revises: 011
Create Date: 2026-04-01

Remplace les préfixes incorrects (ex: '01A') par le format officiel :
  niveau 1 → 'NN'     ex: '01'  = ALLERGOLOGIE
  niveau 2 → 'NN X'   ex: '01 A'= ANTIHISTAMINIQUES
"""
from alembic import op

revision = '012'
down_revision = '011'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── 1. Ajouter la colonne niveau ──────────────────────────────────────────
    op.execute("""
        ALTER TABLE nomenclature_classification
        ADD COLUMN IF NOT EXISTS niveau SMALLINT NOT NULL DEFAULT 1;
    """)

    # ── 2. Supprimer les anciennes données incorrectes ────────────────────────
    op.execute("TRUNCATE TABLE nomenclature_classification RESTART IDENTITY;")

    # ── 3. Insérer la classification officielle ───────────────────────────────
    op.execute("""
        INSERT INTO nomenclature_classification (prefix, designation, niveau) VALUES

        -- 01 ALLERGOLOGIE
        ('01',   'ALLERGOLOGIE',                                       1),
        ('01 A', 'ANTIHISTAMINIQUES',                                  2),
        ('01 D', 'ALLERGENES A USAGE THERAPEUTIQUE',                   2),

        -- 02 ANESTHESIOLOGIE
        ('02',   'ANESTHESIOLOGIE',                                    1),
        ('02 C', 'ANESTHESIQUES LOCAUX ET REGIONAUX',                  2),

        -- 03 ANTALGIQUES
        ('03',   'ANTALGIQUES',                                        1),
        ('03 A', 'SALICYLES',                                          2),
        ('03 B', 'PARACETAMOL ET DERIVES',                             2),
        ('03 D', 'DEXTROPROPOXYPHENE',                                 2),
        ('03 F', 'AUTRES ANALGESIQUES',                                2),

        -- 04 ANTI-INFLAMMATOIRES
        ('04',   'ANTI-INFLAMMATOIRES',                                1),
        ('04 A', 'ANTI-INFLAMMATOIRES STEROIDIENS',                    2),
        ('04 B', 'ANTI-INFLAMMATOIRES NON STEROIDIENS',                2),

        -- 05 CANCEROLOGIE
        ('05',   'CANCEROLOGIE',                                       1),
        ('05 A', 'CYTOSTATIQUES',                                      2),
        ('05 B', 'IMMUNOSUPPRESSEURS',                                 2),

        -- 06 CARDIOLOGIE ET ANGEIOLOGIE
        ('06',   'CARDIOLOGIE ET ANGEIOLOGIE',                         1),
        ('06 A', 'ANALEPTIQUES CIRCULATOIRES ET ANTI-HYPOTENSEURS',    2),
        ('06 B', 'ANTAGONISTES',                                       2),
        ('06 C', 'ANTI-ANGOREUX',                                      2),
        ('06 D', 'ANTI-ARYTHMIQUES',                                   2),
        ('06 F', 'BETA-BLOQUANTS',                                     2),
        ('06 G', 'CARDIOTONIQUES ET CARDIO-ACCELERATEURS',             2),
        ('06 H', 'DIURETIQUES',                                        2),
        ('06 J', 'VASODILATATEURS ET ANTI-ISCHEMIQUES',                2),
        ('06 M', 'HYPOLIPIDEMIANTS',                                   2),

        -- 07 DERMATOLOGIE
        ('07',   'DERMATOLOGIE',                                       1),
        ('07 B', 'ANTI-ACNEIQUES, ANTI-ALOPECIQUES ET ANTI-SEBORRHEIQUES', 2),
        ('07 C', 'ANTI-BACTERIENS LOCAUX',                             2),
        ('07 D', 'ANTIFONGIQUES LOCAUX',                               2),
        ('07 E', 'ANTIHERPETIQUES ET ANTIVIRAUX',                      2),
        ('07 H', 'DERMOCORTICOIDES',                                   2),
        ('07 L', 'KERATOLYTIQUES ET REDUCTEURS',                       2),
        ('07 M', 'PHOTOSENSIBILISANTS',                                2),
        ('07 P', 'ANTISEPTIQUES',                                      2),
        ('07 R', 'ANTIPARASITAIRES',                                   2),

        -- 08 DIAGNOSTIC
        ('08',   'DIAGNOSTIC',                                         1),
        ('08 A', 'I.R.M',                                              2),
        ('08 B', 'OPACIFIANTS BARYTES',                                2),
        ('08 C', 'OPACIFIANTS IODES A ELIMINATION RENALE',             2),

        -- 09 ENDOCRINOLOGIE ET HORMONES
        ('09',   'ENDOCRINOLOGIE ET HORMONES',                         1),
        ('09 A', 'ANDROGENES ET ANTI-ANDROGENES',                      2),
        ('09 B', 'ANTI-OESTROGENES',                                   2),
        ('09 C', 'ANTI-GONADOTROPES',                                  2),
        ('09 D', 'ANTI-PROLACTINE',                                    2),
        ('09 E', 'ANTI-THYROIDIENS',                                   2),
        ('09 F', 'ANABOLISANTS',                                       2),
        ('09 G', 'OESTROGENES',                                        2),
        ('09 H', 'GLUCOCORTICOIDES',                                   2),
        ('09 J', 'HORMONES HYPOTHALAMIQUES ET HYPOPHYSAIRES',          2),
        ('09 K', 'HORMONES THYROIDIENNES',                             2),
        ('09 L', 'INDUCTEURS DE L''OVULATION',                         2),
        ('09 N', 'PROGESTATIFS (SAUF CONTRACEPTIFS)',                  2),
        ('09 P', 'DIVERS',                                             2),

        -- 10 GASTRO-ENTEROLOGIE
        ('10',   'GASTRO-ENTEROLOGIE',                                 1),
        ('10 A', 'ANTI-ULCEREUX ET ANTI-H2',                          2),
        ('10 B', 'ANTI-ACIDES ET PROTECTEURS GASTRO-INTESTINAUX',      2),
        ('10 C', 'ANTISEPTIQUES ET ANTI-INFECTIEUX INTESTINAUX',       2),
        ('10 D', 'ANTISPASMODIQUES, ANTISECRETOIRES, ANTICHOLINERGIQUES', 2),
        ('10 E', 'ANTISPASMODIQUES MUSCULOTROPES',                     2),
        ('10 F', 'MEDICAMENTS DE LA MOTRICITE DIGESTIVE',              2),
        ('10 G', 'ANTI-REFLUX GASTRO-OESOPHAGIEN',                     2),
        ('10 H', 'ANTIDIARRHEIQUES',                                   2),
        ('10 L', 'LAXATIFS',                                           2),
        ('10 M', 'MUCILAGES ET MEDICAMENTS DE LA CONSTIPATION',        2),
        ('10 N', 'MEDICAMENTS DE LA RECTOCOLITE HEMORRAGIQUE',         2),

        -- 11 GYNECOLOGIE
        ('11',   'GYNECOLOGIE',                                        1),
        ('11 A', 'ANTI-INFECTIEUX LOCAUX',                             2),
        ('11 C', 'UTEROTONIQUES',                                      2),
        ('11 D', 'OESTROPROGESTATIFS',                                 2),
        ('11 E', 'OCYTOCIQUES',                                        2),

        -- 12 HEMATOLOGIE ET HEMOSTASE
        ('12',   'HEMATOLOGIE ET HEMOSTASE',                           1),
        ('12 A', 'ANTICOAGULANTS ORAUX',                               2),
        ('12 B', 'ANTICOAGULANTS INJECTABLES',                         2),
        ('12 C', 'ANTIFIBRINOLYTIQUES',                                2),
        ('12 D', 'VITAMINES K',                                        2),
        ('12 E', 'ANTI-ANEMIQUES',                                     2),
        ('12 H', 'HEMOSTATIQUES GENERAUX',                             2),
        ('12 J', 'FACTEURS SANGUINS',                                  2),

        -- 13 INFECTIOLOGIE
        ('13',   'INFECTIOLOGIE',                                      1),
        ('13 A', 'AMINOSIDES',                                         2),
        ('13 B', 'CEPHALOSPORINES',                                    2),
        ('13 C', 'CYCLINES',                                           2),
        ('13 D', 'LINCOSAMIDES',                                       2),
        ('13 E', 'MACROLIDES ET SYNERGISTINES',                        2),
        ('13 F', 'NITRO-5-IMIDAZOLES',                                 2),
        ('13 G', 'PENICILLINES',                                       2),
        ('13 H', 'PHENICOLES',                                         2),
        ('13 L', 'NITROFURANES',                                       2),
        ('13 M', 'SULFAMIDES',                                         2),
        ('13 N', 'AUTRES ANTIBIOTIQUES ET ANTIBACTERIENS',             2),
        ('13 P', 'ANTIVIRAUX',                                         2),
        ('13 R', 'ANTIFONGIQUES SYSTEMIQUES',                          2),
        ('13 U', 'VACCINS',                                            2),

        -- 14 METABOLISME NUTRITION DIABETE
        ('14',   'METABOLISME NUTRITION DIABETE',                      1),
        ('14 A', 'ANTIDIABETIQUES ORAUX',                              2),
        ('14 B', 'INSULINES',                                          2),
        ('14 C', 'HYPERGLYCEMIANTS',                                   2),
        ('14 D', 'ANTI-HYPERKALIEMIANTS',                              2),
        ('14 G', 'ELEMENTS MINERAUX ET EQUILIBRE HYDRO-ELECTROLYTIQUE',2),
        ('14 H', 'VITAMINES',                                          2),
        ('14 J', 'NUTRITION ENTERALE',                                 2),
        ('14 L', 'LAITS ET FARINES',                                   2),

        -- 15 NEUROLOGIE
        ('15',   'NEUROLOGIE',                                         1),
        ('15 A', 'ANTI-EPILEPTIQUES ET ANTI-CONVULSIVANTS',            2),
        ('15 B', 'ANTIMIGRAINEUX',                                     2),
        ('15 C', 'ANTIMYASTHENIQUES',                                  2),
        ('15 D', 'ANTIPARKINSONIENS',                                  2),
        ('15 F', 'MALADIE D''ALZHEIMER',                               2),
        ('15 G', 'SCLEROSE EN PLAQUE',                                 2),

        -- 16 PSYCHIATRIE
        ('16',   'PSYCHIATRIE',                                        1),
        ('16 A', 'ANTIDEPRESSEURS',                                    2),
        ('16 B', 'ANXIOLYTIQUES',                                      2),
        ('16 C', 'HYPNOTIQUES',                                        2),
        ('16 D', 'NEUROLEPTIQUES',                                     2),

        -- 17 OPHTALMOLOGIE
        ('17',   'OPHTALMOLOGIE',                                      1),
        ('17 A', 'ANESTHESIQUES LOCAUX',                               2),
        ('17 B', 'ANTI-ALLERGIQUES LOCAUX',                            2),
        ('17 C', 'ANTI-GLAUCOMATEUX',                                  2),
        ('17 D', 'ANTI-INFECTIEUX LOCAUX',                             2),
        ('17 E', 'ANTISEPTIQUES LOCAUX',                               2),
        ('17 F', 'ANTIVIRAUX LOCAUX',                                  2),
        ('17 G', 'CORTICOIDES LOCAUX',                                 2),
        ('17 H', 'MYDRIATIQUES',                                       2),
        ('17 J', 'PRODUITS POUR CRISTALLIN',                           2),
        ('17 K', 'DIVERS',                                             2),
        ('17 L', 'MEDICAMENTS PAR VOIE ORALE',                         2),
        ('17 N', 'SUPPLEANCE LACRYMALE',                               2),

        -- 18 OTOLOGIE
        ('18',   'OTOLOGIE',                                           1),
        ('18 A', 'ANTI-INFECTIEUX SANS CORTICOIDES',                   2),
        ('18 B', 'ANTI-INFECTIEUX AVEC CORTICOIDES',                   2),
        ('18 C', 'ANTIVERTIGINEUX',                                    2),
        ('18 D', 'PRODUITS LOCAUX',                                    2),

        -- 19 PARASITOLOGIE
        ('19',   'PARASITOLOGIE',                                      1),
        ('19 B', 'ANTI-HELMINTIQUES',                                  2),
        ('19 C', 'ANTI-PALUDEENS',                                     2),
        ('19 D', 'AUTRES ANTI-PARASITAIRES',                           2),

        -- 20 PNEUMOLOGIE
        ('20',   'PNEUMOLOGIE',                                        1),
        ('20 A', 'BRONCHODILATATEURS ET ANTI-ASTHMATIQUES',            2),
        ('20 B', 'ANTITUSSIFS OPIACES',                                2),
        ('20 C', 'ANTITUSSIFS NON OPIACES',                            2),
        ('20 F', 'CORTICOIDES AVEC BRONCHODILATATEURS',                2),

        -- 21 RHUMATOLOGIE
        ('21',   'RHUMATOLOGIE',                                       1),
        ('21 A', 'ANALGESIQUES ANTIRHUMATISMAUX EXTERNES BAUMES REVULSIFS', 2),
        ('21 B', 'ANTIGOUTTEUX',                                       2),
        ('21 C', 'ANTIPAGETIQUES',                                     2),
        ('21 D', 'ANTIRHUMATISMAUX DIVERS',                            2),
        ('21 E', 'MYORELAXANTS',                                       2),
        ('21 G', 'OSTEOPOROSES',                                       2),

        -- 22 RHINOLOGIE
        ('22',   'RHINOLOGIE',                                         1),
        ('22 C', 'IMMUNOTHERAPIE ET ANTIALLERGIQUES',                  2),
        ('22 E', 'PRODUITS LOCAUX',                                    2),

        -- 23 STOMATOLOGIE
        ('23',   'STOMATOLOGIE',                                       1),
        ('23 A', 'CORRECTEURS DES HYPOSYALIES',                        2),

        -- 24 TOXICOLOGIE
        ('24',   'TOXICOLOGIE',                                        1),
        ('24 D', 'CHELATEURS',                                         2),

        -- 25 UROLOGIE ET NEPHROLOGIE
        ('25',   'UROLOGIE ET NEPHROLOGIE',                            1),
        ('25 B', 'MEDICAMENTS DE L''ADENOME PROSTATIQUE',              2),
        ('25 E', 'ANTI-INFECTIEUX URINAIRES',                          2),
        ('25 L', 'AUTRES',                                             2)

        ON CONFLICT (prefix) DO UPDATE
            SET designation = EXCLUDED.designation,
                niveau      = EXCLUDED.niveau;
    """)


def downgrade() -> None:
    op.execute("TRUNCATE TABLE nomenclature_classification RESTART IDENTITY;")
    op.execute("""
        ALTER TABLE nomenclature_classification
        DROP COLUMN IF EXISTS niveau;
    """)
