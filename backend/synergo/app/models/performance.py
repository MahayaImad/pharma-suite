"""
Modèles SQLAlchemy — Module Performance & Primes
Tables: employes, objectifs_mensuels, kpi_definitions, performance_mensuelle
"""
from sqlalchemy import (
    BigInteger, Boolean, Column, Date, Integer,
    Numeric, String, Text, UniqueConstraint
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.sql import func
from sqlalchemy import DateTime
from app.models.base import Base


class Employe(Base):
    __tablename__ = "employes"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, nullable=True)      # FK vers users.id (nullable)
    username = Column(String(50), unique=True)    # copie du groupware.utilisateur
    nom = Column(String(100), nullable=False)
    prenom = Column(String(100))
    poste = Column(String(100))                   # ex: "Pharmacien", "Caissier"
    date_entree = Column(Date)
    actif = Column(Boolean, default=True)
    eligible_prime = Column(Boolean, default=True)  # False pour VENTE, amine, azzedine, administrateur
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class ObjectifMensuel(Base):
    __tablename__ = "objectifs_mensuels"
    __table_args__ = (UniqueConstraint("annee", "mois"),)

    id = Column(Integer, primary_key=True, autoincrement=True)
    annee = Column(Integer, nullable=False)
    mois = Column(Integer, nullable=False)       # 1-12
    mode_prime = Column(String(10), default="yoy")  # 'yoy' ou 'fixe'
    objectif_benefice = Column(Numeric(14, 2))   # cible manuelle si mode='fixe'
    pct_enveloppe_prime = Column(Numeric(5, 2), default=10)  # % du delta attribué
    enveloppe_calculee = Column(Numeric(14, 2))  # calculé après clôture
    notes = Column(Text)


class KpiDefinition(Base):
    __tablename__ = "kpi_definitions"

    id = Column(Integer, primary_key=True, autoincrement=True)
    code = Column(String(50), unique=True, nullable=False)
    libelle = Column(String(200), nullable=False)
    description = Column(Text)
    categorie = Column(String(30))   # 'ventes', 'productivite', 'stock', 'audit'
    unite = Column(String(20))       # '%', 'DA', 'nb', 'score'
    poids = Column(Numeric(5, 2), default=0)   # % du score total (ex: 30 = 30 %)
    actif = Column(Boolean, default=True)


class PrimeTauxConfig(Base):
    __tablename__ = "prime_taux_config"

    id = Column(Integer, primary_key=True, autoincrement=True)
    nom = Column(String(100), nullable=False, unique=True)
    taux_pct = Column(Numeric(5, 3), nullable=False, default=0)
    filtre_famille = Column(String(200), nullable=True)   # ILIKE pattern on sorties_produits.famille
    actif = Column(Boolean, nullable=False, default=True)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())


class PerformanceMensuelle(Base):
    __tablename__ = "performance_mensuelle"
    __table_args__ = (UniqueConstraint("employe_id", "annee", "mois"),)

    id = Column(Integer, primary_key=True, autoincrement=True)
    employe_id = Column(Integer, nullable=False)
    annee = Column(Integer, nullable=False)
    mois = Column(Integer, nullable=False)
    kpis = Column(JSONB)             # {"ca_realise": {"valeur": 150000, "score": 80}, ...}
    score_global = Column(Numeric(5, 2))   # 0-100 pondéré
    pct_prime = Column(Numeric(5, 2))      # % de l'enveloppe attribué
    prime_calculee = Column(Numeric(14, 2))
    valide = Column(Boolean, default=False)
    valide_par = Column(String(50))
    valide_le = Column(DateTime(timezone=True))
