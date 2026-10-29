"""
GRH — Module Présence
Option C : auto-détection depuis sorties.utilisateur + overrides manuels.

Endpoints :
    GET    /grh/presence              Grille mensuelle complète
    POST   /grh/presence/override     Créer / modifier un override
    DELETE /grh/presence/override     Supprimer un override (revenir à l'auto)
"""
from __future__ import annotations

import calendar
import datetime as _dt
from datetime import date as PyDate
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user

router = APIRouter(prefix="/grh/presence", tags=["grh"])

STATUTS_VALIDES = {"present", "absent", "conge", "retard", "maladie"}

# Jours fériés fixes en Algérie (mois, jour)
_FERIES_FIXES = {(1, 1), (5, 1), (6, 19), (7, 5), (11, 1)}


class OverrideRequest(BaseModel):
    employe_id: int
    date: PyDate
    statut: str
    note: Optional[str] = None




# ── GET /grh/presence ─────────────────────────────────────────────────────────

@router.get("")
async def get_presence_mois(
    annee: Optional[int] = Query(None),
    mois: Optional[int] = Query(None),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    today = PyDate.today()
    a = annee or today.year
    m = mois or today.month

    nb_jours = calendar.monthrange(a, m)[1]
    dates = [PyDate(a, m, d) for d in range(1, nb_jours + 1)]
    date_min, date_max = dates[0], dates[-1]

    # ── Employés actifs ────────────────────────────────────────────────────────
    emp_rows = (await db.execute(text("""
        SELECT id, username, nom, prenom, poste
        FROM employes
        WHERE actif = TRUE AND eligible_prime = TRUE
        ORDER BY nom, prenom
    """))).fetchall()

    if not emp_rows:
        return {"annee": a, "mois": m, "nb_jours": nb_jours, "employes": []}

    # ── Activité auto depuis sorties ───────────────────────────────────────────
    act_rows = (await db.execute(text("""
        SELECT
            LOWER(utilisateur)  AS username,
            date                AS jour,
            MIN(heure)          AS premiere_vente,
            MAX(heure)          AS derniere_vente,
            COUNT(*)            AS nb_ventes
        FROM sorties
        WHERE type != 'A'
          AND date >= :date_min
          AND date <= :date_max
          AND utilisateur IS NOT NULL
          AND utilisateur != ''
        GROUP BY LOWER(utilisateur), date
    """), {"date_min": date_min, "date_max": date_max})).fetchall()

    # (username_lower, date) → info
    activity: dict[tuple, dict] = {}
    for r in act_rows:
        pv = (r.premiere_vente or "")[:5] or None
        dv = (r.derniere_vente or "")[:5] or None
        activity[(r.username, r.jour)] = {
            "premiere_vente": pv,
            "derniere_vente": dv,
            "nb_ventes": int(r.nb_ventes),
        }

    # ── Overrides manuels ──────────────────────────────────────────────────────
    ov_rows = (await db.execute(text("""
        SELECT employe_id, date, statut, note
        FROM presences_overrides
        WHERE date >= :date_min AND date <= :date_max
    """), {"date_min": date_min, "date_max": date_max})).fetchall()

    overrides: dict[tuple, dict] = {}
    for r in ov_rows:
        overrides[(r.employe_id, r.date)] = {"statut": r.statut, "note": r.note}

    # ── Congés approuvés — expand les plages en jours individuels ─────────────
    conge_rows = (await db.execute(text("""
        SELECT employe_id, date_debut, date_fin
        FROM demandes_conge
        WHERE statut = 'approuve'
          AND date_fin   >= :date_min
          AND date_debut <= :date_max
    """), {"date_min": date_min, "date_max": date_max})).fetchall()

    conges_approuves: set[tuple] = set()
    for r in conge_rows:
        cur = max(r.date_debut, date_min)
        end = min(r.date_fin,   date_max)
        while cur <= end:
            conges_approuves.add((r.employe_id, cur))
            cur += _dt.timedelta(days=1)

    # ── Construction de la grille ──────────────────────────────────────────────
    feries_mois = {PyDate(a, mm, dd) for (mm, dd) in _FERIES_FIXES if mm == m}

    result = []
    for emp in emp_rows:
        jours: dict[str, dict] = {}
        totaux = {s: 0 for s in ("present", "absent", "conge", "retard", "maladie", "weekend", "ferie")}
        uname = (emp.username or "").lower()

        for jour in dates:
            jour_str = jour.isoformat()
            # weekday(): 4=Vendredi uniquement (pharmacie ouverte le samedi)
            is_weekend = jour.weekday() == 4
            is_ferie   = jour in feries_mois

            ov = overrides.get((emp.id, jour))
            if ov:
                statut = ov["statut"]
                cell: dict = {"statut": statut, "source": "override"}
                if ov["note"]:
                    cell["note"] = ov["note"]
                totaux[statut] = totaux.get(statut, 0) + 1
            elif is_weekend:
                cell = {"statut": "weekend", "source": "systeme"}
                totaux["weekend"] += 1
            elif is_ferie:
                cell = {"statut": "ferie", "source": "systeme"}
                totaux["ferie"] += 1
            elif (emp.id, jour) in conges_approuves:
                cell = {"statut": "conge", "source": "demande"}
                totaux["conge"] += 1
            else:
                act = activity.get((uname, jour))
                if act:
                    cell = {"statut": "present", "source": "auto", **act}
                    totaux["present"] += 1
                else:
                    cell = {"statut": "absent", "source": "auto"}
                    totaux["absent"] += 1

            jours[jour_str] = cell

        result.append({
            "id":      emp.id,
            "username": emp.username or "",
            "nom":     emp.nom,
            "prenom":  emp.prenom or "",
            "poste":   emp.poste or "",
            "jours":   jours,
            "totaux":  totaux,
        })

    return {"annee": a, "mois": m, "nb_jours": nb_jours, "employes": result}


# ── POST /grh/presence/override ───────────────────────────────────────────────

@router.post("/override")
async def upsert_override(
    req: OverrideRequest,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if req.statut not in STATUTS_VALIDES:
        raise HTTPException(400, f"Statut invalide. Valeurs acceptées : {STATUTS_VALIDES}")

    await db.execute(text("""
        INSERT INTO presences_overrides (employe_id, date, statut, note, created_by)
        VALUES (:employe_id, :date, :statut, :note, :created_by)
        ON CONFLICT (employe_id, date)
        DO UPDATE SET
            statut     = EXCLUDED.statut,
            note       = EXCLUDED.note,
            created_by = EXCLUDED.created_by,
            created_at = NOW()
    """), {
        "employe_id": req.employe_id,
        "date":       req.date,
        "statut":     req.statut,
        "note":       req.note,
        "created_by": current_user.get("username", ""),
    })
    await db.commit()
    return {"ok": True}


# ── DELETE /grh/presence/override ────────────────────────────────────────────

@router.delete("/override")
async def delete_override(
    employe_id: int = Query(...),
    date: PyDate = Query(...),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    await db.execute(text("""
        DELETE FROM presences_overrides
        WHERE employe_id = :employe_id AND date = :date
    """), {"employe_id": employe_id, "date": date})
    await db.commit()
    return {"ok": True}
