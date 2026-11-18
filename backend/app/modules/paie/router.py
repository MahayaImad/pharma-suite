"""Paie (brut) : part fixe, heures supplémentaires, bulletins. Titulaire seulement. Réponses { data, error }."""
from __future__ import annotations

from typing import Any, Awaitable

from fastapi import APIRouter, Depends
from fastapi.encoders import jsonable_encoder
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.modules.paie import schemas as s
from app.modules.paie.repository import PaieRepository
from app.modules.paie.service import ErreurPaie, PaieService

router = APIRouter(prefix="/paie", tags=["paie"])


def _service(db: AsyncSession = Depends(get_db), utilisateur: dict = Depends(get_current_user)) -> PaieService:
    return PaieService(PaieRepository(db), utilisateur)


async def _repondre(appel: Awaitable[Any], statut: int = 200) -> JSONResponse:
    try:
        donnees = await appel
    except ErreurPaie as e:
        return JSONResponse({"data": None, "error": {"code": e.code, "message": e.message}}, status_code=e.statut)
    return JSONResponse({"data": jsonable_encoder(donnees), "error": None}, status_code=statut)


@router.get("/postes")
async def postes(svc: PaieService = Depends(_service)):
    """Postes de travail et salaire de base."""
    return await _repondre(svc.postes())


@router.get("/{annee}/{mois}")
async def paie_du_mois(annee: int, mois: int, svc: PaieService = Depends(_service)):
    """Brut de chaque employé : part fixe ligne par ligne, prime de rendement, points à vérifier."""
    return await _repondre(svc.mois(annee, mois))


@router.put("/{annee}/{mois}/heures-sup/{employe_id}")
async def heures_sup(annee: int, mois: int, employe_id: int, saisie: s.HeuresSup,
                     svc: PaieService = Depends(_service)):
    """Heures supplémentaires du mois (arrondies au quart d'heure) ; 0 les retire."""
    return await _repondre(svc.saisir_heures_sup(employe_id, annee, mois, saisie.heures, saisie.note))


@router.post("/{annee}/{mois}/valider")
async def valider(annee: int, mois: int, svc: PaieService = Depends(_service)):
    """Fige les bulletins bruts du mois (nouvelle version, l'ancienne est gardée)."""
    return await _repondre(svc.valider(annee, mois))


@router.get("/{annee}/{mois}/bulletins/{employe_id}")
async def bulletins(annee: int, mois: int, employe_id: int, svc: PaieService = Depends(_service)):
    """Toutes les versions validées du bulletin d'un employé, la plus récente d'abord."""
    return await _repondre(svc.bulletins(employe_id, annee, mois))


@router.put("/employes/{employe_id}")
async def fiche(employe_id: int, saisie: s.FicheEmploye, svc: PaieService = Depends(_service)):
    """Poste, date d'entrée et date de sortie d'un employé."""
    return await _repondre(svc.modifier_employe(employe_id, saisie.model_dump(exclude_unset=True)))
