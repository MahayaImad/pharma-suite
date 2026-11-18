"""Schémas d'entrée de la paie (réponses dans l'enveloppe { data, error })."""
from __future__ import annotations

from datetime import date
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, Field


class HeuresSup(BaseModel):
    heures: Decimal = Field(..., ge=0, le=200, description="heures supplémentaires du mois, arrondies au quart d'heure")
    note: Optional[str] = Field(None, max_length=200)


class FicheEmploye(BaseModel):
    poste_code: Optional[str] = Field(None, max_length=30)
    date_entree: Optional[date] = None
    date_sortie: Optional[date] = None
