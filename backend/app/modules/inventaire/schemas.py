"""Schémas d'entrée de l'inventaire (réponses dans l'enveloppe { data, error })."""
from __future__ import annotations

import uuid
from typing import Literal, Optional

from pydantic import BaseModel, Field

Cause = Literal["casse", "perime", "saisie", "vol", "inconnu"]


class Comptage(BaseModel):
    id_nom: int
    stock_compte: int = Field(..., ge=0, le=1_000_000, description="boîtes comptées en rayon et en réserve")
    cause: Optional[Cause] = Field(None, description="cause de l'écart, si on la connaît")
    client_uuid: Optional[uuid.UUID] = Field(None, description="idempotence du futur hors-ligne")


class Correction(BaseModel):
    corrige: bool = Field(..., description="l'écart a été reporté dans EASYPHARM")
