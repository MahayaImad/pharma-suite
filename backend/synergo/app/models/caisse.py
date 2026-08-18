"""
Modèles SQLAlchemy — Caisse & Comptabilité
Tables: caisses, caisses_regies, suivi_caisses, operations, depenses, comptes_bancaires
"""
from sqlalchemy import BigInteger, Column, Date, Integer, Numeric, SmallInteger, String
from app.models.base import Base


class Caisse(Base):
    __tablename__ = "caisses"

    id = Column(Integer, primary_key=True, autoincrement=False)
    caisse = Column(String(50), index=True)
    date_creation = Column(Date)
    etat = Column(SmallInteger)


class CaisseRegie(Base):
    __tablename__ = "caisses_regies"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    date_debut = Column(Date)
    heure_debut = Column(String(10))
    date_fin = Column(Date)
    heure_fin = Column(String(10))
    fond_de_caisse = Column(Numeric(15, 4))
    total_calcule = Column(Numeric(15, 4))
    total_reel = Column(Numeric(15, 4))
    etat_cloture = Column(SmallInteger)
    poste = Column(Integer)
    modif = Column(SmallInteger)
    util_ouvre = Column(String(50))
    util_cloture = Column(String(50))
    ventes = Column(Numeric(15, 4))
    retours = Column(Numeric(15, 4))
    versements_clients = Column(Numeric(15, 4))
    remboursements_clients = Column(Numeric(15, 4))
    versements_fournisseurs = Column(Numeric(15, 4))
    remboursements_fournisseurs = Column(Numeric(15, 4))
    alimentations = Column(Numeric(15, 4))
    depenses = Column(Numeric(15, 4))
    virement_de_fond_entrant = Column(Numeric(15, 4))
    virement_de_fond_sortant = Column(Numeric(15, 4))
    indice_ouverture = Column(Numeric(10, 4))


class SuiviCaisse(Base):
    __tablename__ = "suivi_caisses"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    date_debut = Column(Date)
    heure_debut = Column(String(10))
    date_fin = Column(Date)
    heure_fin = Column(String(10))
    fond_de_caisse = Column(Numeric(15, 4))
    total_calcule = Column(Numeric(15, 4))
    total_reel = Column(Numeric(15, 4))
    etat_cloture = Column(SmallInteger)
    util_ouvre = Column(String(50))
    util_cloture = Column(String(50))
    ventes = Column(Numeric(15, 4))
    retours = Column(Numeric(15, 4))
    versements_clients = Column(Numeric(15, 4))
    remboursements_clients = Column(Numeric(15, 4))
    versements_fournisseurs = Column(Numeric(15, 4))
    remboursements_fournisseurs = Column(Numeric(15, 4))
    alimentations = Column(Numeric(15, 4))
    depenses = Column(Numeric(15, 4))
    virement_de_fond_entrant = Column(Numeric(15, 4))
    virement_de_fond_sortant = Column(Numeric(15, 4))
    indice_ouverture = Column(Numeric(10, 4))
    caisse = Column(String(50), index=True)
    ecart = Column(Numeric(15, 4))


class Operation(Base):
    __tablename__ = "operations"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    date = Column(Date, index=True)
    operation = Column(String(50))
    montant = Column(Numeric(15, 4))
    observation = Column(String(100))
    utilisateur = Column(String(50))
    id_relatif = Column(Numeric(15, 4))
    modif = Column(SmallInteger)
    origine = Column(String(100))
    destinataire = Column(String(100))
    heure = Column(String(10))
    id_tier = Column(BigInteger)
    mode = Column(String(50))
    ref = Column(String(50))
    n_assure = Column(String(50), index=True)
    n_facture_chifa = Column(String(30))
    n_bordereau_chifa = Column(String(30))
    cloture = Column(SmallInteger)
    indice_creation = Column(Numeric(20, 0))
    mois_cvm = Column(String(10))
    num_bord_pharmnos = Column(String(30))
    num_fact_cvm_4eme = Column(Integer)
    id_session = Column(BigInteger, index=True)
    id_ph_echange = Column(Integer)


class Depense(Base):
    __tablename__ = "depenses"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    depense = Column(String(100))


class CompteBancaire(Base):
    __tablename__ = "comptes_bancaires"

    id = Column(Integer, primary_key=True, autoincrement=False)
    compte = Column(String(500))
    date_creation = Column(Date)
