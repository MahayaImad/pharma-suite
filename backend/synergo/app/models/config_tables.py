"""
Modèles SQLAlchemy — Configuration & Paramétrage
Tables: pharmacies, postes, groupware, prestations, motif_instance
"""
from sqlalchemy import BigInteger, Column, Integer, Numeric, SmallInteger, String
from app.models.base import Base


class Pharmacie(Base):
    __tablename__ = "pharmacies"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    pharmacie = Column(String(100))
    adresse = Column(String(200))
    ville = Column(String(100))
    telephone = Column(String(100))
    fax = Column(String(100))
    mobile = Column(String(100))
    email = Column(String(100))
    ecart_initial = Column(Numeric(15, 4))


class Poste(Base):
    __tablename__ = "postes"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    km = Column(BigInteger)
    langue = Column(String(10))
    enr = Column(BigInteger)
    etat_caisse = Column(SmallInteger)
    image_fond = Column(String(200))
    sauvegarde_a_partir_ce_poste = Column(SmallInteger)
    gerer_tiroir_caisse = Column(SmallInteger)
    port_tiroir_caisse = Column(SmallInteger)
    gerer_imp_tk = Column(SmallInteger)
    nom_imp_cdb = Column(String(50))
    type_impression_ticket = Column(SmallInteger)
    port_imp_tk = Column(SmallInteger)
    imprimante_tk = Column(String(100))
    dngl = Column(BigInteger)
    ouv_tir_caisse = Column(SmallInteger)
    recherche_vente = Column(SmallInteger)
    sur_comptoir = Column(SmallInteger)
    type_imp_cdb = Column(SmallInteger)
    chemin_chifa_local = Column(String(500))
    att_ect_1 = Column(Integer)
    att_ect_2 = Column(Integer)
    serveur_chifa = Column(SmallInteger)
    ent_easychifa = Column(SmallInteger)
    att_ect_3 = Column(Integer)
    ident_vend_chaq_vnt = Column(SmallInteger)
    nom_pc = Column(String(50))
    caisse_associee = Column(String(50))
    cim_test = Column(String(5000))
    quitter_agent_ect = Column(SmallInteger)
    att_ect_4 = Column(Integer)


class Groupware(Base):
    __tablename__ = "groupware"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    utilisateur = Column(String(50))
    mot_de_passe = Column(String(100))
    nom = Column(String(100))
    prenom = Column(String(100))
    role = Column(Integer)
    actif = Column(SmallInteger)


class Prestation(Base):
    __tablename__ = "prestations"

    id = Column(Integer, primary_key=True, autoincrement=False)
    prestation = Column(String(100))
    prix = Column(Numeric(15, 4))


class MotifInstance(Base):
    __tablename__ = "motif_instance"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    motif = Column(String(200))
