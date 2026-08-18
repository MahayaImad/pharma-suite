"""
Modèles SQLAlchemy — CHIFA (Sécurité sociale / CNAS)
Tables: bordereaux_chifa, factures_chifa, factures_chifa_produits, chifa_rejet_partiel,
        facture_anomalies, facture_rejets
"""
from sqlalchemy import BigInteger, Column, Date, DateTime, Integer, Numeric, SmallInteger, String, Text
from app.models.base import Base


class BordereauChifa(Base):
    __tablename__ = "bordereaux_chifa"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    num_bord = Column(String(50), index=True)
    centre = Column(String(50), index=True)
    nbr_fact = Column(Integer)
    mnt_assure = Column(Numeric(15, 4))
    mnt_officine = Column(Numeric(15, 4))
    mnt_fae = Column(Numeric(15, 4))
    mnt_majoration = Column(Numeric(15, 4))
    mnt_rej = Column(Numeric(15, 4))
    versement = Column(Numeric(15, 4))
    observation = Column(String(200))
    dt_cloture = Column(Date)
    dt_validation = Column(Date)
    dt_encaisse = Column(Date)
    dt_depot = Column(Date)
    archive = Column(SmallInteger)
    dt_creation = Column(Date)
    statut = Column(String(50))
    extra = Column(String(2000))
    obs_creation = Column(String(200))
    obs_cloture = Column(String(200))
    obs_depot = Column(String(200))
    obs_validation = Column(String(200))
    obs_encaissement = Column(String(200))


class FactureChifa(Base):
    __tablename__ = "factures_chifa"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    officine = Column(String(100))
    centre = Column(String(100))
    centre_as = Column(String(100))
    no_assure = Column(String(100))
    rang_ad = Column(String(100))
    d_soins = Column(Date)
    no_bordereau_fact = Column(String(100))
    mt_assure = Column(Numeric(15, 4))
    mt_officine = Column(Numeric(15, 4))
    maj_fact = Column(Numeric(15, 4))
    mt_maj = Column(Numeric(15, 4))
    type_maj = Column(String(100))
    date_fact = Column(Date)
    no_facture = Column(String(100), index=True)
    destocke = Column(SmallInteger)
    signature = Column(String(20))
    annule = Column(SmallInteger)
    code_affect = Column(String(10))
    rej = Column(SmallInteger)
    txt_prod = Column(String(10000))
    motif_annulation = Column(String(100))
    trace_destockage = Column(String(20))


class FactureChifaProduit(Base):
    __tablename__ = "factures_chifa_produits"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    num_enr = Column(BigInteger)
    prix_ppa = Column(Numeric(15, 4))
    quantite = Column(BigInteger)
    mt_assure = Column(Numeric(15, 4))
    mt_officine = Column(Numeric(15, 4))
    num_enr_prescrit = Column(BigInteger)
    no_fact = Column(String(50))


class ChifaRejetPartiel(Base):
    __tablename__ = "chifa_rejet_partiel"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    num_bordereau = Column(String(30))
    num_facture = Column(String(30))
    montant = Column(Numeric(15, 4))
    observation = Column(String(500))


class FactureAnomalie(Base):
    __tablename__ = "facture_anomalies"

    id                      = Column(BigInteger, primary_key=True, autoincrement=True)
    no_facture              = Column(String(100), nullable=False, index=True)
    no_bordereau            = Column(String(100))
    type_anomalie           = Column(String(50), nullable=False, default="autre")
    description             = Column(Text)
    date_signalement        = Column(DateTime(timezone=True))
    utilisateur_signalement = Column(String(50))
    utilisateur_erreur      = Column(String(50))
    statut                  = Column(String(20), nullable=False, default="signalée")


class FactureRejet(Base):
    __tablename__ = "facture_rejets"

    id              = Column(BigInteger, primary_key=True, autoincrement=True)
    no_facture      = Column(String(100), nullable=False, index=True)
    no_bordereau    = Column(String(100))
    caisse          = Column(String(20), nullable=False, default="CNAS")
    motif_rejet     = Column(Text)
    date_rejet      = Column(DateTime(timezone=True))
    montant_rejete  = Column(Numeric(15, 4))
    statut          = Column(String(20), nullable=False, default="rejetée")
    date_traitement = Column(DateTime(timezone=True))
