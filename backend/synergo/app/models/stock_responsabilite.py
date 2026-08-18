"""
Modèle SQLAlchemy — Classification nomenclature pour responsabilités étagères
"""
from sqlalchemy import Column, Integer, String, ForeignKey
from app.models.base import Base


class NomenclatureClassification(Base):
    __tablename__ = "nomenclature_classification"

    id = Column(Integer, primary_key=True, autoincrement=True)
    prefix = Column(String(10), unique=True, nullable=False, index=True)
    designation = Column(String(200))
    etagere = Column(String(50))
    employe_id = Column(Integer, ForeignKey("employes.id", ondelete="SET NULL"), nullable=True)
    categorie = Column(String(20), nullable=True)  # princeps | generique | promotion
