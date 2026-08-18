"""
Clients endpoints
"""
from datetime import date as date_cls
from typing import Optional
from fastapi import APIRouter, Depends, Query, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, or_, desc, text

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.clients import Client
from app.models.ventes import Sortie

router = APIRouter(prefix="/clients", tags=["clients"])


def _f(val) -> float:
    return float(val) if val is not None else 0.0


class ArchiveRequest(BaseModel):
    motif: str


@router.get("")
async def list_clients(
    q: Optional[str] = Query(None, description="Recherche nom, téléphone, n° assuré"),
    chronique: Optional[int] = Query(None, ge=0, le=1),
    ville: Optional[str] = Query(None),
    has_credit: Optional[bool] = Query(None, description="true=avec crédit, false=sans crédit"),
    show_archived: bool = Query(False, description="Inclure les clients archivés"),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Liste paginée des clients avec recherche multi-champ. Exclut les archivés par défaut."""
    conditions = []
    if not show_archived:
        conditions.append(or_(Client.is_archive.is_(None), Client.is_archive == False))
    if q:
        conditions.append(or_(
            Client.client.ilike(f"%{q}%"),
            Client.telephone.ilike(f"%{q}%"),
            Client.n_assure_chifa.ilike(f"%{q}%"),
            Client.num_assure_cvm.ilike(f"%{q}%"),
        ))
    if chronique is not None:
        conditions.append(Client.chronique == chronique)
    if ville:
        conditions.append(Client.ville == ville)
    if has_credit is True:
        conditions.append(Client.credit > 0)
    elif has_credit is False:
        conditions.append(or_(Client.credit.is_(None), Client.credit <= 0))

    where = and_(*conditions) if conditions else True

    total_res = await db.execute(select(func.count(Client.id)).where(where))
    total = total_res.scalar() or 0

    # Construire le WHERE SQL pour la requête raw (même filtres)
    conds_sql = ["1=1"]
    if not show_archived:
        conds_sql.append("c.is_archive IS NOT TRUE")
    params: dict = {"limit": limit, "offset": offset}
    if q:
        conds_sql.append(
            "(c.client ILIKE :q OR c.telephone ILIKE :q "
            "OR c.n_assure_chifa ILIKE :q OR c.num_assure_cvm ILIKE :q)"
        )
        params["q"] = f"%{q}%"
    if chronique is not None:
        conds_sql.append("c.chronique = :chronique")
        params["chronique"] = chronique
    if ville:
        conds_sql.append("c.ville = :ville")
        params["ville"] = ville
    if has_credit is True:
        conds_sql.append("c.credit > 0")
    elif has_credit is False:
        conds_sql.append("(c.credit IS NULL OR c.credit <= 0)")
    where_sql = " AND ".join(conds_sql)

    # JOIN LATERAL patients_chifa pour récupérer les rangs chroniques
    res = await db.execute(text(f"""
        SELECT
            c.id, c.client, c.adresse, c.ville, c.telephone, c.email,
            c.ventes, c.credit,
            c.n_assure_chifa, c.num_assure_cvm,
            c.chronique, c.pathologie,
            c.date_exp_droits,
            c.blk_comptoir, c.blk_chifa,
            c.is_archive, c.motif_archive,
            pc.rangs_chroniques
        FROM clients c
        LEFT JOIN LATERAL (
            SELECT ARRAY_AGG(DISTINCT p.rang_ad ORDER BY p.rang_ad) AS rangs_chroniques
            FROM patients_chifa p
            WHERE p.no_assure = c.n_assure_chifa
        ) pc ON TRUE
        WHERE {where_sql}
        ORDER BY c.client
        LIMIT :limit OFFSET :offset
    """), params)

    items = [
        {
            "id": r.id,
            "client": r.client,
            "adresse": r.adresse,
            "ville": r.ville,
            "telephone": r.telephone,
            "email": r.email,
            "ventes": _f(r.ventes),
            "credit": _f(r.credit),
            "n_assure_chifa": r.n_assure_chifa,
            "num_assure_cvm": r.num_assure_cvm,
            "chronique": r.chronique,
            "pathologie": r.pathologie,
            "date_exp_droits": r.date_exp_droits.isoformat() if r.date_exp_droits else None,
            "blk_comptoir": r.blk_comptoir,
            "blk_chifa": r.blk_chifa,
            # Liste des rang_ad chroniques pour ce n_assure (ex: ['00','80'])
            "rangs_chroniques": list(r.rangs_chroniques) if r.rangs_chroniques else [],
            "is_archive":    bool(r.is_archive),
            "motif_archive": r.motif_archive,
        }
        for r in res.fetchall()
    ]

    return {"total": total, "limit": limit, "offset": offset, "items": items}


@router.get("/{client_id}")
async def get_client(
    client_id: int,
    include_recent_sales: bool = Query(False),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Fiche complète d'un client, avec optionnellement ses dernières ventes."""
    client_res = await db.execute(select(Client).where(Client.id == client_id))
    client = client_res.scalar_one_or_none()
    if not client:
        raise HTTPException(status_code=404, detail="Client introuvable")

    data = {
        "id": client.id,
        "client": client.client,
        "adresse": client.adresse,
        "ville": client.ville,
        "telephone": client.telephone,
        "fax": client.fax,
        "email": client.email,
        "ventes": _f(client.ventes),
        "versements": _f(client.versements),
        "credit": _f(client.credit),
        "solde_initial": _f(client.solde_initial),
        "solde_max": _f(client.solde_max),
        "activer_solde_max": client.activer_solde_max,
        "n_assure_chifa": client.n_assure_chifa,
        "num_assure_cvm": client.num_assure_cvm,
        "num_assure_pharmnos": client.num_assure_pharmnos,
        "chronique": client.chronique,
        "pathologie": client.pathologie,
        "date_exp_droits": client.date_exp_droits.isoformat() if client.date_exp_droits else None,
        "num_carte_chronique": client.num_carte_chronique,
        "date_naissance": client.date_naissance.isoformat() if client.date_naissance else None,
        "sexe": client.sexe,
        "blk_comptoir": client.blk_comptoir,
        "blk_chifa": client.blk_chifa,
        "blk_cvm": client.blk_cvm,
    }

    data["is_archive"]    = bool(client.is_archive)
    data["date_archive"]  = client.date_archive.isoformat() if client.date_archive else None
    data["motif_archive"] = client.motif_archive

    if include_recent_sales:
        sales_res = await db.execute(
            select(
                Sortie.id, Sortie.date, Sortie.heure,
                Sortie.type, Sortie.total_a_payer, Sortie.type_versement,
                Sortie.utilisateur,
            )
            .where(and_(Sortie.id_client == client_id, Sortie.type != "AV"))
            .order_by(desc(Sortie.date), desc(Sortie.id))
            .limit(10)
        )
        data["recent_sales"] = [
            {
                "id": r.id,
                "date": r.date.isoformat() if r.date else None,
                "heure": r.heure,
                "type": r.type,
                "total_a_payer": _f(r.total_a_payer),
                "type_versement": r.type_versement,
                "utilisateur": r.utilisateur,
            }
            for r in sales_res.fetchall()
        ]

    return data


# ── Archivage client ───────────────────────────────────────────────────────────

@router.patch("/{client_id}/archive")
async def archive_client(
    client_id: int,
    body: ArchiveRequest,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Archive un client (décédé, doublon…). L'exclut de toutes les vues CRM."""
    res = await db.execute(select(Client).where(Client.id == client_id))
    client = res.scalar_one_or_none()
    if not client:
        raise HTTPException(status_code=404, detail="Client introuvable")

    client.is_archive    = True
    client.date_archive  = date_cls.today()
    client.motif_archive = body.motif
    await db.commit()
    return {"ok": True, "is_archive": True, "motif_archive": body.motif}


@router.patch("/{client_id}/unarchive")
async def unarchive_client(
    client_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Désarchive un client (erreur, réactivation)."""
    res = await db.execute(select(Client).where(Client.id == client_id))
    client = res.scalar_one_or_none()
    if not client:
        raise HTTPException(status_code=404, detail="Client introuvable")

    client.is_archive    = False
    client.date_archive  = None
    client.motif_archive = None
    await db.commit()
    return {"ok": True, "is_archive": False}
