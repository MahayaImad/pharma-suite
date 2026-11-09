"""
Modèles SQLAlchemy — Achats / Fournisseurs
Tables: entrees, entrees_produits, fournisseurs, commandes_fournisseurs, commandes_fournisseurs_produits
"""
from sqlalchemy import BigInteger, Column, Date, Integer, Numeric, SmallInteger, String, Text
from app.models.base import Base


class Entree(Base):
    __tablename__ = "entrees"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    type = Column(String(5))
    date = Column(Date, index=True)
    heure = Column(String(10))
    date_piece = Column(Date)
    id_fournisseur = Column(BigInteger, index=True)
    fournisseur = Column(String(100))
    total_ht = Column(Numeric(15, 4))
    total_tva = Column(Numeric(15, 4))
    total_ttc = Column(Numeric(15, 4))
    remise = Column(Numeric(15, 4))
    total_a_payer = Column(Numeric(15, 4))
    total_ppa = Column(Numeric(15, 4))
    total_shp = Column(Numeric(15, 4))
    num_bl = Column(String(50))
    num_fact = Column(String(50))
    num_avoir = Column(String(30))
    motif_avoir = Column(String(200))
    attach_bc = Column(String(50))
    echeance = Column(Date)
    reglement = Column(Numeric(15, 4))
    montant_facture = Column(Numeric(15, 4))
    montant_difference = Column(Numeric(15, 4))
    type_achat = Column(String(10))
    type_psy = Column(SmallInteger)
    avoir_financier = Column(SmallInteger)
    utilisateur = Column(String(50))
    poste = Column(Integer)
    modif = Column(SmallInteger)
    ouverte = Column(SmallInteger)
    observations = Column(String(1000))


class EntreeProduit(Base):
    __tablename__ = "entrees_produits"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    id_entree = Column(BigInteger, index=True)
    date_entree = Column(Date)
    type_entree = Column(String(10))
    id_fournisseur = Column(Integer)
    fournisseur = Column(String(100))
    id_nom = Column(BigInteger)
    nom = Column(String(150), index=True)
    marge = Column(Numeric(15, 4))
    id_famille = Column(Integer)
    famille = Column(String(50))
    prix_achat = Column(Numeric(15, 4))
    prix_vente = Column(Numeric(15, 4))
    qte_entree = Column(BigInteger)
    code_barre = Column(String(30), index=True)
    num_bl = Column(String(50))
    num_fact = Column(String(50))
    poste = Column(Integer)
    utilisateur = Column(String(50))
    observation = Column(String(100))
    stock = Column(BigInteger)
    peremption = Column(String(10))
    lot = Column(String(50))
    shp = Column(Numeric(15, 4))
    tva = Column(Numeric(15, 4))
    prix_achat_ttc = Column(Numeric(15, 4))
    id_cnas = Column(BigInteger)
    id_produit = Column(Numeric(15, 4))
    peremption_date = Column(Date)
    indice = Column(String(200))
    ppa = Column(Numeric(15, 4))
    id_echange = Column(BigInteger)
    type_achat = Column(String(10))
    psychotrope = Column(SmallInteger)
    num_avoir = Column(String(30))
    de_equiv = Column(String(20), index=True)
    date_piece = Column(Date)
    bloque = Column(SmallInteger)
    last_modif_inv_tourn = Column(BigInteger)
    labo = Column(String(200))
    heure = Column(String(10))
    cls_trp = Column(String(200))

    # Colonnes HFSQL ajoutées par la migration 002 (relevées par --verifier)
    id_gst = Column(Text)


class Fournisseur(Base):
    __tablename__ = "fournisseurs"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    fournisseur = Column(String(100), index=True)
    adresse = Column(String(200))
    ville = Column(String(100))
    telephone = Column(String(100))
    fax = Column(String(100))
    mobile = Column(String(100))
    email = Column(String(100))
    banque = Column(String(100))
    achats = Column(Numeric(15, 4))
    avoirs = Column(Numeric(15, 4))
    versements = Column(Numeric(15, 4))
    remboursements = Column(Numeric(15, 4))
    solde_actuel = Column(Numeric(15, 4))
    solde_initial = Column(Numeric(15, 4))
    mode_qr = Column(SmallInteger)
    code_efacture = Column(SmallInteger)
    filiale_efacture = Column(String(20))


class CommandeFournisseur(Base):
    __tablename__ = "commandes_fournisseurs"

    id = Column(Integer, primary_key=True, autoincrement=False)
    ref = Column(String(20))
    fournisseur = Column(String(100))
    date = Column(Date)
    utilisateur = Column(String(50))
    poste = Column(SmallInteger)
    observation = Column(String(200))
    type_psy = Column(SmallInteger)
    nbr_prod = Column(Integer)
    sync = Column(SmallInteger)


class CommandeFournisseurProduit(Base):
    __tablename__ = "commandes_fournisseurs_produits"

    id = Column(Integer, primary_key=True, autoincrement=False)
    id_commande = Column(BigInteger, index=True)
    ref_commande = Column(String(20))
    date_commande = Column(Date)
    fournisseur = Column(String(100))
    produit = Column(String(200))
    quantite = Column(BigInteger)
    utilisateur = Column(String(50))
    poste = Column(Integer)
    type_psy = Column(SmallInteger)
    stock = Column(Numeric(15, 4))
    offsettt = Column(Integer)
    per = Column(String(10))
    p_achat = Column(Numeric(15, 4))
    taux_ug = Column(Numeric(15, 4))
