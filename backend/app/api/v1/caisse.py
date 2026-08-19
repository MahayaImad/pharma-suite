"""
Caisse endpoints — Sessions & Opérations
"""
from typing import Optional
from datetime import date
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, desc

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.caisse import SuiviCaisse, Operation

router = APIRouter(prefix="/caisse", tags=["caisse"])


def _f(val) -> float:
    return float(val) if val is not None else 0.0


@router.get("/sessions")
async def list_sessions(
    caisse: Optional[str] = Query(None),
    date_from: Optional[date] = Query(None),
    date_to: Optional[date] = Query(None),
    etat_cloture: Optional[int] = Query(None, ge=0, le=1, description="0=ouverte, 1=clôturée"),
    utilisateur: Optional[str] = Query(None),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Liste paginée des sessions de caisse."""
    conditions = []
    if caisse:
        conditions.append(SuiviCaisse.caisse == caisse)
    if date_from:
        conditions.append(SuiviCaisse.date_debut >= date_from)
    if date_to:
        conditions.append(SuiviCaisse.date_debut <= date_to)
    if etat_cloture is not None:
        conditions.append(SuiviCaisse.etat_cloture == etat_cloture)
    if utilisateur:
        conditions.append(SuiviCaisse.util_ouvre.ilike(f"%{utilisateur}%"))

    where = and_(*conditions) if conditions else True

    total_res = await db.execute(select(func.count(SuiviCaisse.id)).where(where))
    total = total_res.scalar() or 0

    res = await db.execute(
        select(
            SuiviCaisse.id, SuiviCaisse.caisse,
            SuiviCaisse.date_debut, SuiviCaisse.heure_debut,
            SuiviCaisse.date_fin, SuiviCaisse.heure_fin,
            SuiviCaisse.fond_de_caisse, SuiviCaisse.total_calcule,
            SuiviCaisse.total_reel, SuiviCaisse.ecart,
            SuiviCaisse.etat_cloture,
            SuiviCaisse.util_ouvre, SuiviCaisse.util_cloture,
            SuiviCaisse.ventes, SuiviCaisse.retours,
            SuiviCaisse.depenses, SuiviCaisse.alimentations,
            SuiviCaisse.versements_clients, SuiviCaisse.remboursements_clients,
            SuiviCaisse.versements_fournisseurs, SuiviCaisse.remboursements_fournisseurs,
        )
        .where(where)
        .order_by(desc(SuiviCaisse.date_debut), desc(SuiviCaisse.id))
        .limit(limit)
        .offset(offset)
    )

    items = [
        {
            "id": r.id,
            "caisse": r.caisse,
            "date_debut": r.date_debut.isoformat() if r.date_debut else None,
            "heure_debut": r.heure_debut,
            "date_fin": r.date_fin.isoformat() if r.date_fin else None,
            "heure_fin": r.heure_fin,
            "fond_de_caisse": _f(r.fond_de_caisse),
            "total_calcule": _f(r.total_calcule),
            "total_reel": _f(r.total_reel),
            "ecart": _f(r.ecart),
            "etat_cloture": r.etat_cloture,
            "util_ouvre": r.util_ouvre,
            "util_cloture": r.util_cloture,
            "ventes": _f(r.ventes),
            "retours": _f(r.retours),
            "depenses": _f(r.depenses),
            "alimentations": _f(r.alimentations),
            "versements_clients": _f(r.versements_clients),
            "remboursements_clients": _f(r.remboursements_clients),
            "versements_fournisseurs": _f(r.versements_fournisseurs),
            "remboursements_fournisseurs": _f(r.remboursements_fournisseurs),
        }
        for r in res.fetchall()
    ]

    return {"total": total, "limit": limit, "offset": offset, "items": items}


@router.get("/operations")
async def list_operations(
    date_from: Optional[date] = Query(None),
    date_to: Optional[date] = Query(None),
    operation: Optional[str] = Query(None, description="Type d'opération (ilike)"),
    utilisateur: Optional[str] = Query(None),
    id_session: Optional[int] = Query(None),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Liste paginée des opérations de caisse."""
    conditions = []
    if date_from:
        conditions.append(Operation.date >= date_from)
    if date_to:
        conditions.append(Operation.date <= date_to)
    if operation:
        conditions.append(Operation.operation.ilike(f"%{operation}%"))
    if utilisateur:
        conditions.append(Operation.utilisateur == utilisateur)
    if id_session is not None:
        conditions.append(Operation.id_session == id_session)

    where = and_(*conditions) if conditions else True

    total_res = await db.execute(select(func.count(Operation.id)).where(where))
    total = total_res.scalar() or 0

    res = await db.execute(
        select(
            Operation.id, Operation.date, Operation.heure,
            Operation.operation, Operation.montant, Operation.observation,
            Operation.utilisateur, Operation.origine, Operation.destinataire,
            Operation.mode, Operation.ref,
            Operation.n_assure, Operation.n_facture_chifa,
            Operation.id_session, Operation.id_tier,
        )
        .where(where)
        .order_by(desc(Operation.date), desc(Operation.id))
        .limit(limit)
        .offset(offset)
    )

    items = [
        {
            "id": r.id,
            "date": r.date.isoformat() if r.date else None,
            "heure": r.heure,
            "operation": r.operation,
            "montant": _f(r.montant),
            "observation": r.observation,
            "utilisateur": r.utilisateur,
            "origine": r.origine,
            "destinataire": r.destinataire,
            "mode": r.mode,
            "ref": r.ref,
            "n_assure": r.n_assure,
            "n_facture_chifa": r.n_facture_chifa,
            "id_session": r.id_session,
            "id_tier": r.id_tier,
        }
        for r in res.fetchall()
    ]

    return {"total": total, "limit": limit, "offset": offset, "items": items}
