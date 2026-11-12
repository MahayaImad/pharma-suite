"""Calendrier de l'officine : gardes, fêtes à date mobile, jours fériés.

Réponses dans l'enveloppe { data, error } (architecture cible des nouveaux
modules). Lecture : tout utilisateur connecté ; écriture : administrateur.
"""
from __future__ import annotations

from datetime import date
from typing import Any, Awaitable, Optional

from fastapi import APIRouter, Depends, Query
from fastapi.encoders import jsonable_encoder
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.modules.calendrier import schemas as s
from app.modules.calendrier.repository import CalendrierRepository
from app.modules.calendrier.service import CalendrierService, ErreurCalendrier

router = APIRouter(prefix="/calendrier", tags=["calendrier"])


def _service(db: AsyncSession = Depends(get_db), utilisateur: dict = Depends(get_current_user)) -> CalendrierService:
    return CalendrierService(CalendrierRepository(db), utilisateur)


async def _repondre(appel: Awaitable[Any], statut: int = 200) -> JSONResponse:
    try:
        donnees = await appel
    except ErreurCalendrier as e:
        return JSONResponse({"data": None, "error": {"code": e.code, "message": e.message}}, status_code=e.statut)
    return JSONResponse({"data": jsonable_encoder(donnees), "error": None}, status_code=statut)


@router.get("/gardes", response_model=s.Reponse[list[s.Garde]])
async def lire_gardes(annee: Optional[int] = Query(None, ge=2000, le=2100), svc: CalendrierService = Depends(_service)):
    return await _repondre(svc.gardes(annee))


@router.post("/gardes/proposer", response_model=s.Reponse[list[s.Garde]])
async def proposer_gardes(mois: int = Query(3, ge=1, le=12), svc: CalendrierService = Depends(_service)):
    """Propose les gardes à venir d'après la rotation (à confirmer)."""
    return await _repondre(svc.proposer_gardes(mois))


@router.put("/gardes/{jour}", response_model=s.Reponse[s.Garde])
async def enregistrer_garde(jour: date, saisie: s.GardeSaisie, svc: CalendrierService = Depends(_service)):
    return await _repondre(svc.enregistrer_garde(jour, saisie))


@router.delete("/gardes/{jour}", response_model=s.Reponse[None])
async def supprimer_garde(jour: date, svc: CalendrierService = Depends(_service)):
    return await _repondre(svc.supprimer_garde(jour))


@router.get("/evenements", response_model=s.Reponse[list[s.Evenement]])
async def lire_evenements(svc: CalendrierService = Depends(_service)):
    return await _repondre(svc.evenements())


@router.post("/evenements", response_model=s.Reponse[s.Evenement], status_code=201)
async def creer_evenement(saisie: s.EvenementSaisie, svc: CalendrierService = Depends(_service)):
    return await _repondre(svc.creer_evenement(saisie), 201)


@router.put("/evenements/{id_}", response_model=s.Reponse[s.Evenement])
async def modifier_evenement(id_: int, saisie: s.EvenementSaisie, svc: CalendrierService = Depends(_service)):
    return await _repondre(svc.modifier_evenement(id_, saisie))


@router.delete("/evenements/{id_}", response_model=s.Reponse[None])
async def supprimer_evenement(id_: int, svc: CalendrierService = Depends(_service)):
    return await _repondre(svc.supprimer_evenement(id_))


@router.get("/feries", response_model=s.Reponse[list[s.Ferie]])
async def lire_feries(svc: CalendrierService = Depends(_service)):
    return await _repondre(svc.feries())


@router.post("/feries", response_model=s.Reponse[s.Ferie], status_code=201)
async def creer_ferie(saisie: s.FerieSaisie, svc: CalendrierService = Depends(_service)):
    return await _repondre(svc.creer_ferie(saisie), 201)


@router.delete("/feries/{id_}", response_model=s.Reponse[None])
async def supprimer_ferie(id_: int, svc: CalendrierService = Depends(_service)):
    return await _repondre(svc.supprimer_ferie(id_))
