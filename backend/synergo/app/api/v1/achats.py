"""
Achats endpoints — Entrées, Fournisseurs, Commandes
"""
from typing import Optional
from datetime import date
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, or_, desc

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.achats import Entree, EntreeProduit, Fournisseur, CommandeFournisseur, CommandeFournisseurProduit

router = APIRouter(prefix="/achats", tags=["achats"])


def _f(val) -> float:
    return float(val) if val is not None else 0.0


# ── Entrées ───────────────────────────────────────────────────────────────────

@router.get("")
async def list_achats(
    date_from: Optional[date] = Query(None),
    date_to: Optional[date] = Query(None),
    fournisseur: Optional[str] = Query(None),
    type: Optional[str] = Query(None, description="FA=facture, AV=avoir, etc."),
    num_fact: Optional[str] = Query(None),
    utilisateur: Optional[str] = Query(None),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Liste paginée des entrées (réceptions de marchandises)."""
    conditions = []
    if date_from:
        conditions.append(Entree.date >= date_from)
    if date_to:
        conditions.append(Entree.date <= date_to)
    if fournisseur:
        conditions.append(Entree.fournisseur.ilike(f"%{fournisseur}%"))
    if type:
        conditions.append(Entree.type == type)
    if num_fact:
        conditions.append(Entree.num_fact == num_fact)
    if utilisateur:
        conditions.append(Entree.utilisateur == utilisateur)

    where = and_(*conditions) if conditions else True

    total_res = await db.execute(select(func.count(Entree.id)).where(where))
    total = total_res.scalar() or 0

    res = await db.execute(
        select(
            Entree.id, Entree.date, Entree.heure, Entree.type,
            Entree.id_fournisseur, Entree.fournisseur,
            Entree.num_bl, Entree.num_fact, Entree.num_avoir,
            Entree.total_ht, Entree.total_tva, Entree.total_ttc,
            Entree.remise, Entree.total_a_payer,
            Entree.echeance, Entree.reglement,
            Entree.type_achat, Entree.utilisateur, Entree.ouverte,
        )
        .where(where)
        .order_by(desc(Entree.date), desc(Entree.id))
        .limit(limit)
        .offset(offset)
    )

    items = [
        {
            "id": r.id,
            "date": r.date.isoformat() if r.date else None,
            "heure": r.heure,
            "type": r.type,
            "id_fournisseur": r.id_fournisseur,
            "fournisseur": r.fournisseur,
            "num_bl": r.num_bl,
            "num_fact": r.num_fact,
            "num_avoir": r.num_avoir,
            "total_ht": _f(r.total_ht),
            "total_tva": _f(r.total_tva),
            "total_ttc": _f(r.total_ttc),
            "remise": _f(r.remise),
            "total_a_payer": _f(r.total_a_payer),
            "echeance": r.echeance.isoformat() if r.echeance else None,
            "reglement": _f(r.reglement),
            "type_achat": r.type_achat,
            "utilisateur": r.utilisateur,
            "ouverte": r.ouverte,
        }
        for r in res.fetchall()
    ]

    return {"total": total, "limit": limit, "offset": offset, "items": items}


@router.get("/{achat_id}/detail")
async def get_achat_detail(
    achat_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Détail d'une réception : en-tête + lignes produits."""
    entree_res = await db.execute(select(Entree).where(Entree.id == achat_id))
    entree = entree_res.scalar_one_or_none()
    if not entree:
        raise HTTPException(status_code=404, detail="Entrée introuvable")

    lignes_res = await db.execute(
        select(
            EntreeProduit.id, EntreeProduit.id_nom, EntreeProduit.nom,
            EntreeProduit.famille, EntreeProduit.lot, EntreeProduit.peremption,
            EntreeProduit.qte_entree, EntreeProduit.prix_achat, EntreeProduit.prix_vente,
            EntreeProduit.ppa, EntreeProduit.tva, EntreeProduit.prix_achat_ttc,
            EntreeProduit.psychotrope,
        ).where(EntreeProduit.id_entree == achat_id)
    )

    return {
        "entree": {
            "id": entree.id,
            "date": entree.date.isoformat() if entree.date else None,
            "heure": entree.heure,
            "type": entree.type,
            "fournisseur": entree.fournisseur,
            "num_bl": entree.num_bl,
            "num_fact": entree.num_fact,
            "total_ht": _f(entree.total_ht),
            "total_tva": _f(entree.total_tva),
            "total_ttc": _f(entree.total_ttc),
            "remise": _f(entree.remise),
            "total_a_payer": _f(entree.total_a_payer),
            "echeance": entree.echeance.isoformat() if entree.echeance else None,
            "reglement": _f(entree.reglement),
            "utilisateur": entree.utilisateur,
            "observations": entree.observations,
        },
        "produits": [
            {
                "id": r.id,
                "id_nom": r.id_nom,
                "nom": r.nom,
                "famille": r.famille,
                "lot": r.lot,
                "peremption": r.peremption,
                "qte_entree": r.qte_entree,
                "prix_achat": _f(r.prix_achat),
                "prix_vente": _f(r.prix_vente),
                "ppa": _f(r.ppa),
                "tva": _f(r.tva),
                "prix_achat_ttc": _f(r.prix_achat_ttc),
                "psychotrope": r.psychotrope,
            }
            for r in lignes_res.fetchall()
        ],
    }


# ── Fournisseurs ──────────────────────────────────────────────────────────────

@router.get("/fournisseurs")
async def list_fournisseurs(
    q: Optional[str] = Query(None, description="Recherche nom, ville, email"),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Liste paginée des fournisseurs."""
    conditions = []
    if q:
        conditions.append(or_(
            Fournisseur.fournisseur.ilike(f"%{q}%"),
            Fournisseur.ville.ilike(f"%{q}%"),
            Fournisseur.email.ilike(f"%{q}%"),
        ))

    where = and_(*conditions) if conditions else True

    total_res = await db.execute(select(func.count(Fournisseur.id)).where(where))
    total = total_res.scalar() or 0

    res = await db.execute(
        select(
            Fournisseur.id, Fournisseur.fournisseur,
            Fournisseur.adresse, Fournisseur.ville,
            Fournisseur.telephone, Fournisseur.mobile, Fournisseur.email,
            Fournisseur.achats, Fournisseur.avoirs,
            Fournisseur.versements, Fournisseur.remboursements,
            Fournisseur.solde_actuel,
        )
        .where(where)
        .order_by(Fournisseur.fournisseur)
        .limit(limit)
        .offset(offset)
    )

    items = [
        {
            "id": r.id,
            "fournisseur": r.fournisseur,
            "adresse": r.adresse,
            "ville": r.ville,
            "telephone": r.telephone,
            "mobile": r.mobile,
            "email": r.email,
            "achats": _f(r.achats),
            "avoirs": _f(r.avoirs),
            "versements": _f(r.versements),
            "remboursements": _f(r.remboursements),
            "solde_actuel": _f(r.solde_actuel),
        }
        for r in res.fetchall()
    ]

    return {"total": total, "limit": limit, "offset": offset, "items": items}


# ── Commandes fournisseurs ────────────────────────────────────────────────────

@router.get("/commandes")
async def list_commandes(
    fournisseur: Optional[str] = Query(None),
    date_from: Optional[date] = Query(None),
    date_to: Optional[date] = Query(None),
    ref: Optional[str] = Query(None),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Liste paginée des commandes fournisseurs."""
    conditions = []
    if fournisseur:
        conditions.append(CommandeFournisseur.fournisseur.ilike(f"%{fournisseur}%"))
    if date_from:
        conditions.append(CommandeFournisseur.date >= date_from)
    if date_to:
        conditions.append(CommandeFournisseur.date <= date_to)
    if ref:
        conditions.append(CommandeFournisseur.ref == ref)

    where = and_(*conditions) if conditions else True

    total_res = await db.execute(select(func.count(CommandeFournisseur.id)).where(where))
    total = total_res.scalar() or 0

    res = await db.execute(
        select(
            CommandeFournisseur.id, CommandeFournisseur.ref,
            CommandeFournisseur.fournisseur, CommandeFournisseur.date,
            CommandeFournisseur.utilisateur, CommandeFournisseur.observation,
            CommandeFournisseur.nbr_prod, CommandeFournisseur.type_psy,
        )
        .where(where)
        .order_by(desc(CommandeFournisseur.date), desc(CommandeFournisseur.id))
        .limit(limit)
        .offset(offset)
    )

    items = [
        {
            "id": r.id,
            "ref": r.ref,
            "fournisseur": r.fournisseur,
            "date": r.date.isoformat() if r.date else None,
            "utilisateur": r.utilisateur,
            "observation": r.observation,
            "nbr_prod": r.nbr_prod,
            "type_psy": r.type_psy,
        }
        for r in res.fetchall()
    ]

    return {"total": total, "limit": limit, "offset": offset, "items": items}
