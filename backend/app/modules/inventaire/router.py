"""Inventaire tournant : liste du jour, comptages, écarts. Réponses { data, error }."""
from __future__ import annotations

from typing import Any, Awaitable

from fastapi import APIRouter, Depends
from fastapi.encoders import jsonable_encoder
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.modules.inventaire import schemas as s
from app.modules.inventaire.repository import InventaireRepository
from app.modules.inventaire.service import ErreurInventaire, InventaireService

router = APIRouter(prefix="/inventaire", tags=["inventaire"])


def _service(db: AsyncSession = Depends(get_db), utilisateur: dict = Depends(get_current_user)) -> InventaireService:
    return InventaireService(InventaireRepository(db), utilisateur)


async def _repondre(appel: Awaitable[Any], statut: int = 200) -> JSONResponse:
    try:
        donnees = await appel
    except ErreurInventaire as e:
        return JSONResponse({"data": None, "error": {"code": e.code, "message": e.message}}, status_code=e.statut)
    return JSONResponse({"data": jsonable_encoder(donnees), "error": None}, status_code=statut)


@router.get("/jour")
async def journee(svc: InventaireService = Depends(_service)):
    """Produits à compter aujourd'hui, comptages du jour, exactitude, écarts à corriger."""
    return await _repondre(svc.journee())


@router.post("/comptages")
async def compter(saisie: s.Comptage, svc: InventaireService = Depends(_service)):
    """Enregistre un comptage ; recompter le même produit le même jour remplace."""
    return await _repondre(svc.compter(saisie.id_nom, saisie.stock_compte, saisie.cause, saisie.client_uuid), 201)


@router.delete("/comptages/{id_}")
async def annuler(id_: int, svc: InventaireService = Depends(_service)):
    """Annule un comptage du jour."""
    return await _repondre(svc.annuler(id_))


@router.put("/comptages/{id_}/corrige")
async def corriger(id_: int, saisie: s.Correction, svc: InventaireService = Depends(_service)):
    """Marque l'écart comme reporté dans EASYPHARM."""
    return await _repondre(svc.corriger(id_, saisie.corrige))
