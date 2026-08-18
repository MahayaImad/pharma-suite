"""
Modèles SQLAlchemy — Divers
Tables: mouchard, mouchard_details, ordonnancier, echanges, echanges_sorties_produits,
        reg_client_association, reg_fourn_association, pharmnos_factures
"""
from sqlalchemy import BigInteger, Column, Date, Integer, Numeric, SmallInteger, String
from app.models.base import Base


class Mouchard(Base):
    __tablename__ = "mouchard"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    date = Column(Date, index=True)
    heure = Column(String(10))
    utilisateur = Column(String(50))
    poste = Column(Integer)
    action = Column(String(100))
    description = Column(String(200))
    vnt_tier_ini = Column(String(100))
    vnt_montant_ini = Column(Numeric(15, 4))
    vnt_versement_ini = Column(Numeric(15, 4))
    vnt_tier_fin = Column(String(100))
    vnt_montant_fin = Column(Numeric(15, 4))
    vnt_versement_fin = Column(Numeric(15, 4))
    ach_date_ini = Column(Date)
    ach_fournisseur_ini = Column(String(100))
    ach_type_ini = Column(String(20))
    ach_num_fact_ini = Column(String(50))
    ach_num_bl_ini = Column(String(50))
    ach_total_ppa_ini = Column(Numeric(15, 4))
    ach_total_a_payer_ini = Column(Numeric(15, 4))
    ach_remise_ini = Column(Numeric(15, 4))
    ach_ech_ini = Column(Date)
    ach_date_fin = Column(Date)
    ach_fournisseur_fin = Column(String(100))
    ach_type_fin = Column(String(20))
    ach_num_fact_fin = Column(String(50))
    ach_num_bl_fin = Column(String(50))
    ach_total_ppa_fin = Column(Numeric(15, 4))
    ach_total_a_payer_fin = Column(Numeric(15, 4))
    ach_remise_fin = Column(Numeric(15, 4))
    ach_ech_fin = Column(Date)
    stk_ppa_ini = Column(Numeric(15, 4))
    stk_lot_ini = Column(String(50))
    stk_per_ini = Column(String(10))
    stk_cdb_ini = Column(String(50))
    stk_ppa_fin = Column(Numeric(15, 4))
    stk_lot_fin = Column(String(50))
    stk_per_fin = Column(String(10))
    stk_cdb_fin = Column(String(50))
    stk_prod = Column(String(200))
    op_caisse_ini = Column(String(100))
    op_tier_ini = Column(String(150))
    op_montant_ini = Column(Numeric(15, 4))
    op_mode_ini = Column(String(50))
    op_ref_ini = Column(String(50))
    op_obs_ini = Column(String(200))
    op_caisse_fin = Column(String(100))
    op_tier_fin = Column(String(150))
    op_montant_fin = Column(Numeric(15, 4))
    op_mode_fin = Column(String(50))
    op_ref_fin = Column(String(50))
    op_obs_fin = Column(String(200))
    stk_blok_ini = Column(SmallInteger)
    stk_blok_fin = Column(SmallInteger)


class MouchardDetails(Base):
    __tablename__ = "mouchard_details"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    id_mouchard = Column(BigInteger, index=True)
    produit = Column(String(200))
    prix_achat_ttc = Column(Numeric(15, 4))
    ppa = Column(Numeric(15, 4))
    lot = Column(String(50))
    per = Column(String(10))
    sts = Column(String(5))
    qte = Column(Integer)


class Ordonnancier(Base):
    __tablename__ = "ordonnancier"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    num = Column(BigInteger)
    date = Column(Date, index=True)
    ordonnateur = Column(String(50))
    client = Column(String(50))
    adresse = Column(String(50))
    num_cin = Column(String(20))
    observation = Column(String(200))
    utilisateur = Column(String(30))
    id_vente = Column(Numeric(15, 4))
    adresse_medecin = Column(String(50))
    type = Column(SmallInteger)
    porteur = Column(String(200))
    porteur_adresse = Column(String(50))
    porteur_cin = Column(String(20))
    date_soin = Column(Date)
    id_vente_2 = Column(BigInteger)
    txt_duree = Column(String(5000))
    age_malade = Column(SmallInteger)
    taille_malade = Column(String(10))
    poids_malade = Column(String(10))
    structure_ordo = Column(String(100))
    num_serie_ordo = Column(String(20))
    mld_lui_meme = Column(SmallInteger)
    prescripteur_ordre = Column(String(20))


class Echange(Base):
    __tablename__ = "echanges"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    type = Column(String(5))
    date = Column(Date)
    id_pharmacie = Column(BigInteger)
    pharmacie = Column(String(100))
    total = Column(Numeric(15, 4))
    utilisateur = Column(String(50))
    poste = Column(Integer)
    modif = Column(SmallInteger)
    contient_psy = Column(SmallInteger)
    heure = Column(String(10))


class EchangeSortieProduit(Base):
    __tablename__ = "echanges_sorties_produits"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    id_produit = Column(BigInteger)
    id_nom = Column(Numeric(15, 4))
    nom = Column(String(150))
    id_famille = Column(SmallInteger)
    famille = Column(String(50))
    prix_achat_ttc = Column(Numeric(15, 4))
    prix_vente = Column(Numeric(15, 4))
    qte = Column(BigInteger)
    lot = Column(String(50))
    peremption = Column(String(10))
    id_echange = Column(BigInteger, index=True)
    id_pharmacie = Column(BigInteger)
    pharmacie = Column(String(100))
    date_echange = Column(Date)
    psychotrope = Column(SmallInteger)
    heure = Column(String(10))


class RegClientAssociation(Base):
    __tablename__ = "reg_client_association"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    id_operation = Column(BigInteger)
    id_vente = Column(BigInteger)
    tranche = Column(Numeric(15, 4))
    date = Column(Date)
    mode = Column(String(50))
    ref = Column(String(50))
    observation = Column(String(100))
    utilisateur = Column(String(50))


class RegFournAssociation(Base):
    __tablename__ = "reg_fourn_association"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    id_operation = Column(BigInteger)
    id_entree = Column(BigInteger)
    tranche = Column(Numeric(15, 4))
    date = Column(Date)
    mode = Column(String(50))
    ref = Column(String(50))
    observation = Column(String(100))
    utilisateur = Column(String(50))


class PharmnosFacture(Base):
    __tablename__ = "pharmnos_factures"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    matricule = Column(String(20))
    num_dec = Column(String(20), index=True)
    date_soin = Column(Date)
    taux = Column(Integer)
    total_ppa = Column(Numeric(15, 4))
    total_remb = Column(Numeric(15, 4))
    total_non_remb = Column(Numeric(15, 4))
    num_brd = Column(String(20))
    date_dec = Column(Date)
    destocke = Column(SmallInteger)
    annule = Column(SmallInteger)
    majoration = Column(Numeric(15, 4))
    fae = Column(Numeric(15, 4))
