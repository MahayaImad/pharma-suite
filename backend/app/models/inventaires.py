"""
Modèles SQLAlchemy — Inventaires
Tables: inventaires, inventaires_produits
"""
from sqlalchemy import BigInteger, Column, Date, Integer, Numeric, SmallInteger, String, Text
from app.models.base import Base


class Inventaire(Base):
    __tablename__ = "inventaires"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    date = Column(Date, index=True)
    heure = Column(String(10))
    utilisateur = Column(String(50))
    poste = Column(Integer)
    etat = Column(SmallInteger)   # 0=ouvert, 1=validé
    observations = Column(String(500))

    # Colonnes HFSQL ajoutées par la migration 002 (relevées par --verifier)
    date_ouverture = Column(Date)
    date_cloture = Column(Date)
    description = Column(Text)
    valeur_achat_initiale = Column(Numeric(15, 4))
    valeur_achat_inventaire = Column(Numeric(15, 4))
    valeur_ppa_initiale = Column(Numeric(15, 4))
    valeur_ppa_inventaire = Column(Numeric(15, 4))
    ecart_achat = Column(Numeric(15, 4))
    ecart_ppa = Column(Numeric(15, 4))


class InventaireProduit(Base):
    __tablename__ = "inventaires_produits"

    id = Column(BigInteger, primary_key=True, autoincrement=False)
    id_inventaire = Column(BigInteger, index=True)
    date = Column(Date, index=True)
    id_nom = Column(BigInteger)
    nom = Column(String(150))
    id_famille = Column(Integer)
    famille = Column(String(50))
    code_barre = Column(String(30))
    lot = Column(String(50))
    peremption = Column(String(10))
    peremption_date = Column(Date)
    stock_theorique = Column(BigInteger)
    stock_reel = Column(BigInteger)
    ecart = Column(BigInteger)        # stock_reel - stock_theorique (négatif = perte)
    prix_achat_ttc = Column(Numeric(15, 4))
    prix_vente = Column(Numeric(15, 4))
    motif = Column(String(200))       # 'Péremption', 'Vol', 'Casse', etc.
    utilisateur = Column(String(50))
    poste = Column(Integer)

    # Colonnes HFSQL ajoutées par la migration 002 (relevées par --verifier)
    id_produit = Column(BigInteger)
    produit = Column(Text)
    heure = Column(Text)
    quantite_theorique = Column(Numeric(15, 4))
    quantite_physique = Column(Numeric(15, 4))
    ppa = Column(Numeric(15, 4))
    edite = Column(SmallInteger)
    observation = Column(Text)
