"""Modèles SQLAlchemy pour l'assistant achat."""

from datetime import datetime
from decimal import Decimal
from typing import Optional

from sqlalchemy import BigInteger, DateTime, Integer, Numeric, String, func, text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class ParametresStock(Base):
    """Cache des paramètres de stock calculés par produit."""

    __tablename__ = "parametres_stock"

    id_nom: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    delai_moyen_j: Mapped[Optional[Decimal]] = mapped_column(Numeric(8, 2))
    demande_moy_j: Mapped[Optional[Decimal]] = mapped_column(Numeric(10, 4))
    demande_std_j: Mapped[Optional[Decimal]] = mapped_column(Numeric(10, 4))
    stock_securite: Mapped[Optional[Decimal]] = mapped_column(Numeric(10, 2))
    rop: Mapped[Optional[Decimal]] = mapped_column(Numeric(10, 2))
    eoq: Mapped[Optional[Decimal]] = mapped_column(Numeric(10, 2))
    holding_cost_pct: Mapped[Optional[Decimal]] = mapped_column(
        Numeric(5, 4), server_default=text("0.20")
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )


class PrevisionDemande(Base):
    """Cache des prévisions de demande par produit."""

    __tablename__ = "previsions_demande"

    id_nom: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    modele: Mapped[Optional[str]] = mapped_column(String(30))
    prevision_30j: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2))
    prevision_90j: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2))
    mape_holdout: Mapped[Optional[Decimal]] = mapped_column(Numeric(7, 4))
    serie_corrigee: Mapped[Optional[dict]] = mapped_column(JSONB)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
