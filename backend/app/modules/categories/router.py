"""Catégories de prime. Réponses { data, error }."""
from __future__ import annotations

from typing import Any, Awaitable, Optional

from fastapi import APIRouter, Depends, Query
from fastapi.encoders import jsonable_encoder
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.modules.categories import schemas as s
from app.modules.categories.repository import CategoriesRepository
from app.modules.categories.service import CategoriesService, ErreurCategories

router = APIRouter(prefix="/categories", tags=["categories de prime"])


def _service(db: AsyncSession = Depends(get_db), utilisateur: dict = Depends(get_current_user)) -> CategoriesService:
    return CategoriesService(CategoriesRepository(db), utilisateur)


async def _repondre(appel: Awaitable[Any]) -> JSONResponse:
    try:
        donnees = await appel
    except ErreurCategories as e:
        return JSONResponse({"data": None, "error": {"code": e.code, "message": e.message}}, status_code=e.statut)
    return JSONResponse({"data": jsonable_encoder(donnees), "error": None})


@router.get("/{annee}/{mois}")
async def mois(annee: int, mois: int, svc: CategoriesService = Depends(_service)):
    """Enveloppe du mois, CA et montant par catégorie (sans catégorie : taux princeps), dernier classement."""
    return await _repondre(svc.mois(annee, mois))


@router.get("/{annee}/{mois}/laboratoires")
async def laboratoires(annee: int, mois: int, q: Optional[str] = None, limite: int = Query(6, ge=1, le=500),
                       svc: CategoriesService = Depends(_service)):
    """Laboratoires triés par CA du mois, marqués génériques ou non."""
    return await _repondre(svc.laboratoires(annee, mois, q, limite))


@router.get("/{annee}/{mois}/produits")
async def produits(annee: int, mois: int, limite: int = Query(10, ge=1, le=100),
                   svc: CategoriesService = Depends(_service)):
    """Produits vendus dans le mois sans catégorie, ou classés à la main, les plus vendus d'abord."""
    return await _repondre(svc.produits(annee, mois, limite))


@router.put("/laboratoires/{id_}")
async def marquer(id_: int, saisie: s.Laboratoire, svc: CategoriesService = Depends(_service)):
    """Marque un laboratoire générique (ou non)."""
    return await _repondre(svc.marquer_laboratoire(id_, saisie.generique))


@router.put("/produits/{id_nom}")
async def choisir(id_nom: int, saisie: s.ChoixProduit, svc: CategoriesService = Depends(_service)):
    """Catégorie choisie à la main (jamais écrasée) ; null la rend au classement automatique."""
    return await _repondre(svc.choisir(id_nom, saisie.categorie))


@router.post("/classer")
async def classer(saisie: s.Classement, svc: CategoriesService = Depends(_service)):
    """Classe les produits sans catégorie (ou tous avec `tout`), sauf les choix à la main."""
    return await _repondre(svc.classer(saisie.seuil_marge, saisie.tout))
