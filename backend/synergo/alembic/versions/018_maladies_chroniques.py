"""Créer maladies_chroniques (référentiel CNAS officiel) + classe_maladie

Revision ID: 018
Revises: 017
Create Date: 2026-04-08
"""
from alembic import op
import sqlalchemy as sa

revision = '018'
down_revision = '017'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── maladies_chroniques ───────────────────────────────────────────────────
    op.execute("""
    CREATE TABLE IF NOT EXISTS maladies_chroniques (
        id         SERIAL PRIMARY KEY,
        code       VARCHAR(10) NOT NULL UNIQUE,
        maladie    VARCHAR(150) NOT NULL,
        specialite VARCHAR(50),
        taux_cnas  INTEGER,
        type_cnas  VARCHAR(10)
    )
    """)

    op.execute("""
    INSERT INTO maladies_chroniques (id, code, maladie, specialite, taux_cnas, type_cnas) VALUES
    (1,'C001','Tuberculose (toutes formes)','Pneumologie',100,'100%'),
    (2,'C002','Psychonévroses graves','Psychiatrie',100,'100%'),
    (3,'C003','Maladies cancéreuses','Oncologie',100,'100%'),
    (4,'C004','Hémopathies','Hématologie',100,'100%'),
    (5,'C005','Sarcoïdose','Pneumologie',100,'100%'),
    (6,'C006','Hypertension artérielle maligne','Cardiologie',100,'100%'),
    (7,'C007','Angine de poitrine','Cardiologie',100,'100%'),
    (8,'C008','Infarctus du myocarde','Cardiologie',100,'100%'),
    (9,'C009','Accident vasculaire cérébral (AVC)','Neurologie',100,'100%'),
    (10,'C010','Remplacement valvulaire (prothèse)','Cardiologie',100,'100%'),
    (11,'C011','Sclérose en plaques (SEP)','Neurologie',100,'100%'),
    (12,'C012','Epilepsie','Neurologie',100,'100%'),
    (13,'C013','Maladies neuromusculaires graves','Neurologie',100,'100%'),
    (14,'C014','Lèpre et complications','Dermatologie',100,'100%'),
    (15,'C015','Maladies mentales chroniques','Psychiatrie',100,'100%'),
    (16,'C016','Insuffisance rénale chronique','Néphrologie',100,'100%'),
    (17,'C017','Affections ostéoarticulaires invalidantes','Rhumatologie',100,'100%'),
    (18,'C018','Affections oculaires graves','Ophtalmologie',100,'100%'),
    (19,'C019','Affections ORL graves','ORL',100,'100%'),
    (20,'C020','Insuffisance respiratoire chronique','Pneumologie',100,'100%'),
    (21,'C021','Poliomyélite antérieure aiguë','Neurologie',100,'100%'),
    (22,'C022','Diabète','Endocrinologie',100,'100%'),
    (23,'C023','Dysprotéïnémies','Hématologie',100,'100%'),
    (24,'C024','Dyslipoïdoses','Endocrinologie',100,'100%'),
    (25,'C025','Cardiopathies congénitales','Cardiologie',100,'100%'),
    (26,'C026','Affections endocriniennes complexes','Endocrinologie',100,'100%'),
    (27,'C027','Rhumatisme articulaire aigu','Rhumatologie',100,'100%'),
    (28,'C028','Ostéomyélite chronique','Orthopédie',100,'100%'),
    (29,'C029','Complications graves gastrectomie/ulcère','Gastro-entérologie',100,'100%'),
    (30,'C030','Cirrhose du foie','Hépatologie',100,'100%'),
    (31,'C031','Rectocolite hémorragique','Gastro-entérologie',100,'100%'),
    (32,'C032','Pemphigus malin','Dermatologie',100,'100%'),
    (33,'C033','Psoriasis','Dermatologie',100,'100%'),
    (34,'C034','Hydatidose et complications','Chirurgie',100,'100%'),
    (35,'C035','Asthme','Pneumologie',80,'80%'),
    (36,'C036','Hypothyroïdie','Endocrinologie',80,'80%'),
    (37,'C037','Hyperthyroïdie','Endocrinologie',80,'80%'),
    (38,'C038','Allergie chronique','Allergologie',80,'80%'),
    (39,'C039','Arthrose','Rhumatologie',80,'80%'),
    (40,'C040','Reflux gastro-oesophagien chronique','Gastro-entérologie',80,'80%'),
    (41,'C041','Dépression chronique','Psychiatrie',80,'80%'),
    (42,'C042','Obésité morbide','Endocrinologie',80,'80%'),
    (43,'C043','Goutte chronique','Rhumatologie',80,'80%'),
    (44,'C044','Maladie de Parkinson','Neurologie',80,'80%'),
    (45,'C045','Alzheimer','Neurologie',80,'80%'),
    (46,'C046','Glaucome','Ophtalmologie',80,'80%'),
    (47,'C047','BPCO (bronchite chronique obstructive)','Pneumologie',80,'80%'),
    (48,'C048','Insuffisance cardiaque chronique','Cardiologie',80,'80%'),
    (49,'C049','Fibrillation auriculaire','Cardiologie',80,'80%'),
    (50,'C050','Hépatite B chronique','Hépatologie',80,'80%'),
    (51,'C051','Hépatite C chronique','Hépatologie',80,'80%'),
    (52,'C052','Dyslipidémie','Endocrinologie',80,'80%'),
    (53,'C053','Hypertension artérielle (non maligne)','Cardiologie',80,'80%'),
    (54,'C054','Maladie de Crohn','Gastro-entérologie',80,'80%'),
    (55,'C055','Insuffisance veineuse chronique','Angiologie',80,'80%')
    ON CONFLICT (code) DO NOTHING
    """)

    # ── classe_maladie ────────────────────────────────────────────────────────
    op.execute("""
    CREATE TABLE IF NOT EXISTS classe_maladie (
        prefix       VARCHAR(10) NOT NULL,
        code_maladie VARCHAR(10) NOT NULL REFERENCES maladies_chroniques(code),
        PRIMARY KEY (prefix, code_maladie)
    )
    """)
    op.execute("""
    CREATE INDEX IF NOT EXISTS ix_classe_maladie_prefix ON classe_maladie (prefix)
    """)

    op.execute("""
    INSERT INTO classe_maladie (prefix, code_maladie) VALUES
    ('01 A','C038'),('01 D','C038'),('22 C','C038'),
    ('05 A','C003'),('05 B','C003'),('05 B','C011'),('05 B','C016'),
    ('06 B','C053'),('06 B','C006'),('06 B','C048'),
    ('06 C','C007'),('06 C','C006'),
    ('06 D','C049'),
    ('06 F','C053'),('06 F','C048'),('06 F','C007'),
    ('06 G','C048'),
    ('06 H','C053'),('06 H','C048'),('06 H','C016'),
    ('06 J','C007'),('06 J','C009'),
    ('06 M','C052'),('06 M','C024'),
    ('09 E','C037'),('09 H','C017'),('09 K','C036'),
    ('10 G','C040'),('10 N','C031'),('10 N','C054'),
    ('12 A','C007'),('12 A','C008'),('12 A','C049'),
    ('12 B','C008'),
    ('12 E','C004'),
    ('14 A','C022'),('14 B','C022'),
    ('15 A','C012'),('15 C','C013'),('15 D','C044'),
    ('15 F','C045'),('15 G','C011'),
    ('16 A','C041'),('16 D','C002'),('16 D','C015'),
    ('17 C','C046'),
    ('20 A','C035'),('20 A','C047'),('20 F','C035'),('20 F','C047'),
    ('21 B','C043'),('21 D','C017'),('21 D','C027'),('21 G','C017'),
    ('07 H','C033'),
    ('25 B','C016')
    ON CONFLICT DO NOTHING
    """)


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS classe_maladie")
    op.execute("DROP TABLE IF EXISTS maladies_chroniques")
