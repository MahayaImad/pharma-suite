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


class ChoixGenerique(BaseModel):
    choix: Optional[Literal["garder", "exclure"]] = Field(None, description="None : automatique")


class ModeGroupe(BaseModel):
    mode: Optional[Literal["toutes", "quelques"]] = Field(None, description="None : d'après la classe")


class AjoutProduit(BaseModel):
    id_nom: int
    qte: Optional[int] = Field(None, ge=1, le=100000, description="None : quantité proposée ce soir (au moins 1)")


class Deplacement(BaseModel):
    de: int = Field(..., description="fournisseur d'origine")
    vers: int = Field(..., description="nouveau fournisseur")


class Remplacement(BaseModel):
    par: int = Field(..., description="id_nom du générique qui remplace la ligne")
