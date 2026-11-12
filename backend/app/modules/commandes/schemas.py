"""Schémas d'entrée des commandes (les réponses sont dans l'enveloppe { data, error })."""
from __future__ import annotations

from typing import Literal, Optional

from pydantic import BaseModel, Field


class LigneSaisie(BaseModel):
    qte: int = Field(..., ge=0, le=100000, description="boîtes ; 0 retire la ligne")


class FournisseurSaisie(BaseModel):
    type: Literal["pharma", "para"]
    actif: bool = True
    whatsapp: Optional[str] = Field(None, max_length=30)


class ValideurSaisie(BaseModel):
    username: str = Field(..., min_length=1, max_length=100)
