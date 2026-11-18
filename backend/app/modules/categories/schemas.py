"""Catégories de prime : saisies."""
from __future__ import annotations

from decimal import Decimal
from typing import Literal, Optional

from pydantic import BaseModel, Field


class Laboratoire(BaseModel):
    generique: bool


class ChoixProduit(BaseModel):
    categorie: Optional[Literal["princeps", "generique", "generique++"]] = Field(
        None, description="null rend le produit au classement automatique")


class Classement(BaseModel):
    seuil_marge: Decimal = Field(Decimal(50), ge=0, le=1000, description="marge moyenne (%) pour générique++")
    tout: bool = Field(False, description="reclasser aussi les produits déjà classés (sauf choix à la main)")
