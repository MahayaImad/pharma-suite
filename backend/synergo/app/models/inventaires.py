"""
Modèles SQLAlchemy — Inventaires
Tables: inventaires, inventaires_produits
"""
from sqlalchemy import BigInteger, Column, Date, Integer, Numeric, SmallInteger, String
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
