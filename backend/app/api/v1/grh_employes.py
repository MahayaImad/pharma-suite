"""
GRH — Fiches employés & demandes de congé.

Endpoints :
    GET    /grh/employes                  Liste simplifiée (admin) ou self (employé)
    GET    /grh/employes/{id}/fiche       Fiche complète avec champs calculés
    PATCH  /grh/employes/{id}             Mise à jour admin (poste, dates, prime…)
    GET    /grh/demandes-conge            Liste des demandes (filtrées par employe_id)
    POST   /grh/demandes-conge            Soumettre une demande
    PATCH  /grh/demandes-conge/{id}       Approuver / rejeter (admin)
"""
from __future__ import annotations

from datetime import date as PyDate
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user

router = APIRouter(prefix="/grh", tags=["grh"])


# ── Schémas ───────────────────────────────────────────────────────────────────

class UpdateEmployeRequest(BaseModel):
    nom:             Optional[str]  = None
    prenom:          Optional[str]  = None
    poste:           Optional[str]  = None
    date_entree:     Optional[PyDate] = None
    conges_annuels:  Optional[int]  = None
    eligible_prime:  Optional[bool] = None
    actif:           Optional[bool] = None


class DemandeCongeRequest(BaseModel):
    employe_id: int
    date_debut: PyDate
    date_fin:   PyDate
    nb_jours:   int
    type:       str = "annuel"
    note:       Optional[str] = None


class ApprouverDemandeRequest(BaseModel):
    statut:     str           # 'approuve' | 'rejete'
    note_admin: Optional[str] = None


# ── GET /grh/employes ─────────────────────────────────────────────────────────

@router.get("/employes")
async def list_employes(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    is_admin = current_user.get("role") == "admin"
    username = current_user.get("username", "")

    if is_admin:
        rows = (await db.execute(text("""
            SELECT id, username, nom, prenom, poste, actif, eligible_prime
            FROM employes WHERE actif = TRUE
            ORDER BY nom, prenom
        """))).fetchall()
    else:
        rows = (await db.execute(text("""
            SELECT id, username, nom, prenom, poste, actif, eligible_prime
            FROM employes
            WHERE LOWER(username) = LOWER(:username) AND actif = TRUE
        """), {"username": username})).fetchall()

    return [dict(r._mapping) for r in rows]


# ── GET /grh/employes/{id}/fiche ──────────────────────────────────────────────

@router.get("/employes/{employe_id}/fiche")
async def get_fiche(
    employe_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    row = (await db.execute(text("""
        SELECT
            e.id, e.username, e.nom, e.prenom, e.poste,
            e.date_entree, e.actif, e.eligible_prime,
            COALESCE(e.conges_annuels, 30)                         AS conges_annuels,
            EXTRACT(YEAR  FROM AGE(CURRENT_DATE, e.date_entree))::int AS anciennete_annees,
            EXTRACT(MONTH FROM AGE(CURRENT_DATE, e.date_entree))::int AS anciennete_mois,
            COALESCE(cp.jours, 0)                                   AS conges_pris,
            COALESCE(e.conges_annuels, 30) - COALESCE(cp.jours, 0) AS conges_restants
        FROM employes e
        LEFT JOIN (
            SELECT employe_id, COALESCE(SUM(nb_jours), 0) AS jours
            FROM demandes_conge
            WHERE statut = 'approuve'
              AND EXTRACT(YEAR FROM date_debut) = EXTRACT(YEAR FROM CURRENT_DATE)
            GROUP BY employe_id
        ) cp ON cp.employe_id = e.id
        WHERE e.id = :id
    """), {"id": employe_id})).fetchone()

    if not row:
        raise HTTPException(404, "Employé introuvable")

    return dict(row._mapping)


# ── PATCH /grh/employes/{id} ──────────────────────────────────────────────────

@router.patch("/employes/{employe_id}")
async def update_employe(
    employe_id: int,
    req: UpdateEmployeRequest,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if not current_user.get("role") == "admin":
        raise HTTPException(403, "Réservé aux administrateurs")

    updates = {k: v for k, v in req.model_dump().items() if v is not None}
    if not updates:
        return {"ok": True}

    set_clause = ", ".join(f"{k} = :{k}" for k in updates)
    updates["id"] = employe_id
    await db.execute(text(f"UPDATE employes SET {set_clause} WHERE id = :id"), updates)
    await db.commit()
    return {"ok": True}


# ── GET /grh/demandes-conge ───────────────────────────────────────────────────

@router.get("/demandes-conge")
async def list_demandes(
    employe_id: Optional[int] = Query(None),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    where = "WHERE d.employe_id = :employe_id" if employe_id else ""
    params = {"employe_id": employe_id} if employe_id else {}
    rows = (await db.execute(text(f"""
        SELECT d.*, e.nom, e.prenom
        FROM demandes_conge d
        JOIN employes e ON e.id = d.employe_id
        {where}
        ORDER BY d.created_at DESC
    """), params)).fetchall()
    return [dict(r._mapping) for r in rows]


# ── POST /grh/demandes-conge ──────────────────────────────────────────────────

@router.post("/demandes-conge")
async def create_demande(
    req: DemandeCongeRequest,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    if req.date_fin < req.date_debut:
        raise HTTPException(400, "date_fin doit être >= date_debut")
    if req.nb_jours <= 0:
        raise HTTPException(400, "nb_jours doit être positif")

    result = await db.execute(text("""
        INSERT INTO demandes_conge
            (employe_id, date_debut, date_fin, nb_jours, type, note)
        VALUES (:employe_id, :date_debut, :date_fin, :nb_jours, :type, :note)
        RETURNING id
    """), {
        "employe_id": req.employe_id,
        "date_debut": req.date_debut,
        "date_fin":   req.date_fin,
        "nb_jours":   req.nb_jours,
        "type":       req.type,
        "note":       req.note,
    })
    await db.commit()
    new_id = result.scalar()
    return {"ok": True, "id": new_id}


# ── PATCH /grh/demandes-conge/{id} ───────────────────────────────────────────

@router.patch("/demandes-conge/{demande_id}")
async def approuver_demande(
    demande_id: int,
    req: ApprouverDemandeRequest,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if not current_user.get("role") == "admin":
        raise HTTPException(403, "Réservé aux administrateurs")
    if req.statut not in ("approuve", "rejete"):
        raise HTTPException(400, "statut invalide")

    await db.execute(text("""
        UPDATE demandes_conge
        SET statut = :statut, note_admin = :note_admin, updated_at = NOW()
        WHERE id = :id
    """), {"statut": req.statut, "note_admin": req.note_admin, "id": demande_id})
    await db.commit()
    return {"ok": True}
