"""Commandes fournisseurs : proposition du soir, brouillons, validation, bon.

Réponses dans l'enveloppe { data, error }. Préparer et corriger : tout
utilisateur connecté ; valider : titulaire ou employé désigné ; réglages
(fournisseurs, valideurs) : titulaire.
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
from app.modules.commandes import schemas as s
from app.modules.commandes.repository import CommandesRepository
from app.modules.commandes.service import CommandesService, ErreurCommandes

router = APIRouter(prefix="/commandes", tags=["commandes"])


def _service(db: AsyncSession = Depends(get_db), utilisateur: dict = Depends(get_current_user)) -> CommandesService:
    return CommandesService(CommandesRepository(db), utilisateur)


async def _repondre(appel: Awaitable[Any], statut: int = 200) -> JSONResponse:
    try:
        donnees = await appel
    except ErreurCommandes as e:
        return JSONResponse({"data": None, "error": {"code": e.code, "message": e.message}}, status_code=e.statut)
    return JSONResponse({"data": jsonable_encoder(donnees), "error": None}, status_code=statut)


@router.get("/jour")
async def journee(jour: Optional[date] = Query(None), svc: CommandesService = Depends(_service)):
    """Paniers du jour par fournisseur : brouillons enregistrés, sinon proposition."""
    return await _repondre(svc.journee(jour))


@router.post("/preparer")
async def preparer(svc: CommandesService = Depends(_service)):
    """Enregistre la proposition du jour en brouillons (un par fournisseur)."""
    return await _repondre(svc.preparer())


@router.put("/{id_commande}/lignes/{id_nom}")
async def modifier_ligne(id_commande: int, id_nom: int, saisie: s.LigneSaisie,
                         svc: CommandesService = Depends(_service)):
    return await _repondre(svc.modifier_ligne(id_commande, id_nom, saisie.qte))


@router.post("/{id_commande}/valider")
async def valider(id_commande: int, svc: CommandesService = Depends(_service)):
    return await _repondre(svc.valider(id_commande))


@router.post("/{id_commande}/rouvrir")
async def rouvrir(id_commande: int, svc: CommandesService = Depends(_service)):
    return await _repondre(svc.rouvrir(id_commande))


@router.post("/{id_commande}/envoyer")
async def envoyer(id_commande: int, svc: CommandesService = Depends(_service)):
    """Marque envoyée ; renvoie le bon à coller dans WhatsApp."""
    return await _repondre(svc.envoyer(id_commande))


@router.post("/{id_commande}/annuler")
async def annuler(id_commande: int, svc: CommandesService = Depends(_service)):
    return await _repondre(svc.annuler(id_commande))


@router.get("/{id_commande}/bon")
async def bon(id_commande: int, svc: CommandesService = Depends(_service)):
    return await _repondre(svc.bon(id_commande))


@router.get("/reglages/fournisseurs")
async def fournisseurs(svc: CommandesService = Depends(_service)):
    return await _repondre(svc.fournisseurs())


@router.put("/reglages/fournisseurs/{id_fournisseur}")
async def regler_fournisseur(id_fournisseur: int, saisie: s.FournisseurSaisie,
                             svc: CommandesService = Depends(_service)):
    return await _repondre(svc.regler_fournisseur(id_fournisseur, saisie.type, saisie.actif, saisie.whatsapp))


@router.get("/reglages/valideurs")
async def valideurs(svc: CommandesService = Depends(_service)):
    return await _repondre(svc.valideurs())


@router.post("/reglages/valideurs")
async def ajouter_valideur(saisie: s.ValideurSaisie, svc: CommandesService = Depends(_service)):
    return await _repondre(svc.ajouter_valideur(saisie.username))


@router.delete("/reglages/valideurs/{username}")
async def retirer_valideur(username: str, svc: CommandesService = Depends(_service)):
    return await _repondre(svc.retirer_valideur(username))
