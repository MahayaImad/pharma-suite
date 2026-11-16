"""Alertes : ce qui demande une action aujourd'hui. Réponse { data, error }."""
from __future__ import annotations

from fastapi import APIRouter, Depends
from fastapi.encoders import jsonable_encoder
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.modules.alertes.service import AlertesService

router = APIRouter(prefix="/alertes", tags=["alertes"])


@router.get("")
async def alertes(db: AsyncSession = Depends(get_db), utilisateur: dict = Depends(get_current_user)):
    """Alertes du jour, de la plus urgente à la moins urgente, avec leur action."""
    donnees = await AlertesService(db, utilisateur).liste()
    return JSONResponse({"data": jsonable_encoder(donnees), "error": None})
