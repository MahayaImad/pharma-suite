"""
Modèles SQLAlchemy — Référentiel pharmaceutique
Tables: nomenclature, familles, formes, laboratoires, instance_produits, nomenclature_chifa
"""
from sqlalchemy import BigInteger, Boolean, Column, Date, DateTime, Integer, Numeric, SmallInteger, String, Text
from app.models.base import Base

# Valeurs valides pour disponibilite
DISPONIBILITE_OUI     = 'oui'
DISPONIBILITE_RUPTURE = 'rupture'
DISPONIBILITE_QUOTA   = 'quota'


class Nomenclature(Base):
    __tablename__ = "nomenclature"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    nom = Column(String(150), index=True)
    id_famille = Column(BigInteger)
    famille = Column(String(100))
    prix_vente = Column(Numeric(15, 4))
    prix_achat_moyen = Column(Numeric(15, 4))
    quantite_entree = Column(Numeric(15, 4))
    quantite_sortie = Column(Numeric(15, 4))
    stock = Column(Numeric(15, 4))
    dci = Column(String(200))
    dosage = Column(String(200))
    conditionnement = Column(String(200))
    id_forme = Column(BigInteger)
    forme = Column(String(200))
    forme_abr = Column(String(200))
    id_cnas = Column(BigInteger)
    psychotrope = Column(SmallInteger)
    qte_alerte = Column(BigInteger)
    de_equiv = Column(String(20))
    remb_cvm = Column(SmallInteger)
    code_barre_original = Column(String(50))
    cle_compo_nom_cdb = Column(String(200), index=True)
    desactiv_alrt_rup = Column(SmallInteger)
    ord_trois_souche = Column(SmallInteger)
    labo = Column(String(200))
    cls_trp = Column(String(200))
    generique = Column(SmallInteger, default=0)  # 0=non, 1=oui
    etagere = Column(String(50))  # responsable étagère
    # ── Champs PostgreSQL-only (non écrasés lors du sync HFSQL) ───────────────
    archive      = Column(Boolean,    nullable=False, default=False, server_default='false')
    segment_abc  = Column(String(1),  nullable=True)   # A / B / C
    segment_xyz  = Column(String(1),  nullable=True)   # X / Y / Z
    disponibilite = Column(String(10), nullable=False, default='oui', server_default="'oui'")
    categorie    = Column(String(20), nullable=True)   # princeps | generique | promotion


class Famille(Base):
    __tablename__ = "familles"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    famille = Column(String(100))


class Forme(Base):
    __tablename__ = "formes"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    forme = Column(String(200))
    forme_abr = Column(String(200))

    # Colonnes HFSQL ajoutées par la migration 002 (relevées par --verifier)
    id_forme = Column(Text)


class Laboratoire(Base):
    __tablename__ = "laboratoires"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    labo = Column(String(200))
    is_generique = Column(Boolean, nullable=False, default=False, server_default='false')


class InstanceProduit(Base):
    __tablename__ = "instance_produits"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    date = Column(Date)
    id_client = Column(BigInteger)
    client = Column(String(100), index=True)
    id_nom = Column(BigInteger)
    nom = Column(String(150))
    id_famille = Column(Integer)
    famille = Column(String(50))
    prix_vente = Column(Numeric(15, 4))
    qte_sortie = Column(BigInteger)
    heure = Column(String(10))
    prix_achat_ttc = Column(Numeric(15, 4))
    id_produit = Column(BigInteger)
    lot = Column(String(50))
    peremption = Column(String(10))
    psychotrope = Column(SmallInteger)
    type = Column(SmallInteger)
    n_assure_chifa = Column(String(30))
    n_assure_cvm = Column(String(30))
    utilisateur = Column(String(50))
    motif = Column(String(200))
    echeance = Column(Date)
    indice = Column(String(10))
    # Champs PostgreSQL uniquement
    archive = Column(Boolean, nullable=False, default=False, server_default="false")
    date_archive = Column(DateTime(timezone=True), nullable=True)
    utilisateur_validation = Column(String(50), nullable=True)
    archive_trace = Column(String(50), nullable=True)


class NomenclatureChifa(Base):
    __tablename__ = "nomenclature_chifa"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    nom = Column(String(150), index=True)
    id_famille = Column(BigInteger)
    famille = Column(String(100))
    prix_vente = Column(Numeric(15, 4))
    prix_achat_moyen = Column(Numeric(15, 4))
    quantite_entree = Column(Numeric(15, 4))
    quantite_sortie = Column(Numeric(15, 4))
    stock = Column(Numeric(15, 4))
    dci = Column(String(200))
    dosage = Column(String(200))
    conditionnement = Column(String(200))
    id_forme = Column(BigInteger)
    forme = Column(String(200))
    forme_abr = Column(String(200))
    id_cnas = Column(BigInteger, index=True)
    psychotrope = Column(SmallInteger)
    qte_alerte = Column(BigInteger)
    nom_court = Column(String(150))
    de_equiv = Column(String(20))
    tarif_ref = Column(Numeric(15, 4))
    date_fin_remb = Column(Date)
