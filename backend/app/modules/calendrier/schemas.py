"""Schémas du calendrier de l'officine : gardes, fêtes, jours fériés."""
from __future__ import annotations

from datetime import date, datetime
from typing import Any, Generic, Literal, Optional, TypeVar

from pydantic import BaseModel, Field

TypeGarde = Literal["soiree", "24h", "jour"]
TypeEvenement = Literal["ramadan", "aid_fitr", "aid_adha"]

T = TypeVar("T")


class Erreur(BaseModel):
    code: str
    message: str


class Reponse(BaseModel, Generic[T]):
    """Enveloppe des nouveaux modules : { data, error }."""
    data: Optional[T] = None
    error: Optional[Erreur] = None


class Garde(BaseModel):
    date: date
    type: TypeGarde
    source: Literal["saisie", "detection"]
    confirme: bool
    note: Optional[str] = None
    modifie_le: Optional[datetime] = None
    modifie_par: Optional[str] = None


class GardeSaisie(BaseModel):
    type: TypeGarde
    note: Optional[str] = Field(None, max_length=200)


class Evenement(BaseModel):
    id: int
    type: TypeEvenement
    date_debut: date
    date_fin: date
    a_verifier: bool
    modifie_le: Optional[datetime] = None
    modifie_par: Optional[str] = None


class EvenementSaisie(BaseModel):
    type: TypeEvenement
    date_debut: date
    date_fin: date


class Ferie(BaseModel):
    id: int
    date: date
    label: Optional[str] = None


class FerieSaisie(BaseModel):
    date: date
    label: str = Field(..., min_length=1, max_length=100)


Donnees = dict[str, Any]
