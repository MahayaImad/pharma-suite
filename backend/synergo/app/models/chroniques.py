"""
Modèles SQLAlchemy — maladies chroniques CNAS + patients CHIFA
"""
from sqlalchemy import (
    Column, Integer, String, Numeric, Date, DateTime,
    ForeignKey, UniqueConstraint, Index,
)
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.sql import func

from app.models.base import Base


class MaladieChronique(Base):
    """Référentiel officiel CNAS des 55 maladies chroniques (ALD)."""
    __tablename__ = "maladies_chroniques"

    id         = Column(Integer, primary_key=True)
    code       = Column(String(10), nullable=False, unique=True)   # C001…C055
    maladie    = Column(String(150), nullable=False)
    specialite = Column(String(50))
    taux_cnas  = Column(Integer)    # 100 ou 80
    type_cnas  = Column(String(10)) # '100%' ou '80%'


class ClasseMaladie(Base):
    """Mapping prefix de nomenclature_classification → code maladie CNAS."""
    __tablename__ = "classe_maladie"
    __table_args__ = (
        UniqueConstraint('prefix', 'code_maladie', name='uq_classe_maladie'),
        Index('ix_classe_maladie_prefix', 'prefix'),
    )

    prefix       = Column(String(10), nullable=False, primary_key=True)
    code_maladie = Column(
        String(10),
        ForeignKey('maladies_chroniques.code'),
        nullable=False,
        primary_key=True,
    )


class PatientChifa(Base):
    """Patient chronique identifié depuis les factures CHIFA."""
    __tablename__ = "patients_chifa"
    __table_args__ = (
        UniqueConstraint('no_assure', 'rang_ad', name='uq_patient_chifa'),
        Index('ix_patients_chifa_statut',         'statut'),
        Index('ix_patients_chifa_derniere_visite', 'derniere_visite'),
        Index('ix_patients_chifa_no_assure',       'no_assure'),
    )

    id                  = Column(Integer, primary_key=True, autoincrement=True)
    # Identité CNAS
    no_assure           = Column(String(20), nullable=False)
    rang_ad             = Column(String(4),  nullable=False)
    type_beneficiaire   = Column(String(20))   # 'assure'|'conjoint'|'enfant'
    centre              = Column(String(50))
    # Cycle de vie
    premiere_visite     = Column(Date)
    derniere_visite     = Column(Date)
    nb_visites          = Column(Integer, default=0)
    intervalle_moyen    = Column(Numeric(6, 1))   # jours entre visites
    prochain_visite_est = Column(Date)            # estimation prochain passage
    # Statut (machine d'états)
    statut              = Column(String(20), nullable=False, default='actif')
    # Finance
    mt_total_assure     = Column(Numeric(12, 2), default=0)
    mt_total_officine   = Column(Numeric(12, 2), default=0)
    taux_remb_moyen     = Column(Numeric(5, 2))   # %
    # Pathologies & classes médicamenteuses détectées
    maladies            = Column(ARRAY(String(10)))   # ex: ['C022','C053']
    classes_medicaments = Column(ARRAY(String(10)))   # ex: ['14 A','06 F']
    specialites         = Column(ARRAY(String(50)))   # ex: ['Endocrinologie','Cardiologie']
    medicaments         = Column(ARRAY(String(200)))  # noms des médicaments chroniques détectés
    # Métadonnées
    calcule_le          = Column(DateTime(timezone=True), server_default=func.now())
