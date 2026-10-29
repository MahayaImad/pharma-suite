"""
Gestion des tâches — planning journalier pour la pharmacie.

Endpoints :
    GET    /tasks/board              Tableau de bord gérant (vue admin)
    GET    /tasks/my                 Tâches du jour pour l'employé connecté
    GET    /tasks/templates          Liste des modèles
    POST   /tasks/templates          Créer un modèle
    PATCH  /tasks/templates/{id}     Modifier un modèle
    DELETE /tasks/templates/{id}     Supprimer un modèle
    POST   /tasks/assignments        Créer une assignation manuelle
    PATCH  /tasks/assignments/{id}   Mettre à jour statut / réassigner
    DELETE /tasks/assignments/{id}   Supprimer une assignation
    POST   /tasks/auto-assign        Attribution automatique (aujourd'hui)
"""

from __future__ import annotations

import uuid
from datetime import date, datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user

router = APIRouter(prefix="/tasks", tags=["tasks"])


# ── Schémas ────────────────────────────────────────────────────────────────────

class TemplateCreate(BaseModel):
    title: str
    category: str          # stock | accueil | administrative | maintenance
    duration_min: int = 30
    recurrence: str = "manual"   # manual | daily | weekly | monthly
    auto_assign: bool = False
    day_of_week: Optional[int] = None
    day_of_month: Optional[int] = None
    priority: str = "normal"


class TemplateUpdate(BaseModel):
    title: Optional[str] = None
    category: Optional[str] = None
    duration_min: Optional[int] = None
    recurrence: Optional[str] = None
    auto_assign: Optional[bool] = None
    day_of_week: Optional[int] = None
    day_of_month: Optional[int] = None
    priority: Optional[str] = None
    is_active: Optional[bool] = None


class AssignmentCreate(BaseModel):
    template_id: Optional[str] = None
    title: str
    category: str
    duration_min: int = 30
    priority: str = "normal"
    assigned_to: int           # user.id
    assigned_date: Optional[date] = None
    scheduled_time: Optional[str] = None   # "HH:MM"


class AssignmentUpdate(BaseModel):
    status: Optional[str] = None        # pending | in_progress | done | skipped
    assigned_to: Optional[int] = None
    scheduled_time: Optional[str] = None
    note: Optional[str] = None


# ── GET /tasks/templates ───────────────────────────────────────────────────────

@router.get("/templates")
async def list_templates(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    rows = (await db.execute(text("""
        SELECT t.*, u.username AS created_by_name
        FROM task_templates t
        LEFT JOIN users u ON u.id = t.created_by
        WHERE t.is_active = true
        ORDER BY t.category, t.title
    """))).fetchall()
    return [dict(r._mapping) for r in rows]


# ── POST /tasks/templates ──────────────────────────────────────────────────────

@router.post("/templates", status_code=201)
async def create_template(
    body: TemplateCreate,
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    tid = str(uuid.uuid4())
    # Résoudre l'id de l'utilisateur créateur depuis son username
    creator = (await db.execute(
        text("SELECT id FROM users WHERE username = :u"),
        {"u": user.get("username")},
    )).fetchone()
    await db.execute(text("""
        INSERT INTO task_templates
          (id, title, category, duration_min, recurrence,
           auto_assign, day_of_week, day_of_month, priority, created_by)
        VALUES
          (:id, :title, :category, :duration_min, :recurrence,
           :auto_assign, :day_of_week, :day_of_month, :priority, :created_by)
    """), {
        "id": tid, **body.model_dump(),
        "created_by": creator.id if creator else None,
    })
    await db.commit()
    return {"id": tid}


# ── PATCH /tasks/templates/{id} ────────────────────────────────────────────────

@router.patch("/templates/{tid}")
async def update_template(
    tid: str,
    body: TemplateUpdate,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    updates = {k: v for k, v in body.model_dump().items() if v is not None}
    if not updates:
        raise HTTPException(status_code=400, detail="Aucune donnée à modifier")

    set_clause = ", ".join(f"{k} = :{k}" for k in updates)
    updates["tid"] = tid
    await db.execute(
        text(f"UPDATE task_templates SET {set_clause} WHERE id = :tid"),
        updates,
    )
    await db.commit()
    return {"ok": True}


# ── DELETE /tasks/templates/{id} ───────────────────────────────────────────────

@router.delete("/templates/{tid}")
async def delete_template(
    tid: str,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    await db.execute(
        text("UPDATE task_templates SET is_active = false WHERE id = :id"),
        {"id": tid},
    )
    await db.commit()
    return {"ok": True}


# ── POST /tasks/assignments ────────────────────────────────────────────────────

@router.post("/assignments", status_code=201)
async def create_assignment(
    body: AssignmentCreate,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    aid = str(uuid.uuid4())
    d   = body.assigned_date or date.today()
    await db.execute(text("""
        INSERT INTO task_assignments
          (id, template_id, title, category, duration_min, priority,
           assigned_to, assigned_date, scheduled_time)
        VALUES
          (:id, :template_id, :title, :category, :duration_min, :priority,
           :assigned_to, :assigned_date, :scheduled_time::time)
    """), {
        "id": aid,
        "template_id": body.template_id,
        "title": body.title,
        "category": body.category,
        "duration_min": body.duration_min,
        "priority": body.priority,
        "assigned_to": body.assigned_to,
        "assigned_date": d,
        "scheduled_time": body.scheduled_time,
    })
    await db.commit()
    return {"id": aid}


# ── PATCH /tasks/assignments/{id} ─────────────────────────────────────────────

@router.patch("/assignments/{aid}")
async def update_assignment(
    aid: str,
    body: AssignmentUpdate,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    now = datetime.now(timezone.utc)

    extra_sql = ""
    if body.status == "in_progress":
        extra_sql = ", started_at = NOW()"
    elif body.status == "done":
        extra_sql = ", completed_at = NOW()"

    updates: dict = {}
    if body.status       is not None: updates["status"]         = body.status
    if body.assigned_to  is not None: updates["assigned_to"]    = body.assigned_to
    if body.note         is not None: updates["note"]           = body.note
    if body.scheduled_time is not None: updates["scheduled_time"] = body.scheduled_time

    if not updates and not extra_sql:
        raise HTTPException(status_code=400, detail="Aucune donnée à modifier")

    set_clause = ", ".join(f"{k} = :{k}" for k in updates) + extra_sql
    updates["aid"] = aid
    await db.execute(
        text(f"UPDATE task_assignments SET {set_clause} WHERE id = :aid"),
        updates,
    )
    await db.commit()
    return {"ok": True}


# ── DELETE /tasks/assignments/{id} ────────────────────────────────────────────

@router.delete("/assignments/{aid}")
async def delete_assignment(
    aid: str,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    await db.execute(
        text("DELETE FROM task_assignments WHERE id = :id"),
        {"id": aid},
    )
    await db.commit()
    return {"ok": True}


# ── GET /tasks/my ─────────────────────────────────────────────────────────────

@router.get("/my")
async def my_tasks(
    db: AsyncSession = Depends(get_db),
    user: dict = Depends(get_current_user),
):
    """Tâches du jour pour l'utilisateur connecté."""
    me = (await db.execute(
        text("SELECT id FROM users WHERE username = :u"),
        {"u": user.get("username")},
    )).fetchone()
    if not me:
        return []
    rows = (await db.execute(text("""
        SELECT a.*
        FROM task_assignments a
        WHERE a.assigned_to  = :uid
          AND a.assigned_date = CURRENT_DATE
        ORDER BY
          CASE a.status
            WHEN 'in_progress' THEN 1
            WHEN 'pending'     THEN 2
            WHEN 'done'        THEN 3
            WHEN 'skipped'     THEN 4
          END,
          a.scheduled_time NULLS LAST
    """), {"uid": me.id})).fetchall()
    return [dict(r._mapping) for r in rows]


# ── GET /tasks/board ──────────────────────────────────────────────────────────

@router.get("/board")
async def board(
    board_date: Optional[date] = None,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Tableau de bord gérant : stats globales + vue par employé."""
    d = board_date or date.today()

    # Stats globales
    stats_row = (await db.execute(text("""
        SELECT
          COUNT(*)                                       AS total,
          COUNT(*) FILTER (WHERE status = 'done')       AS done,
          COUNT(*) FILTER (WHERE status = 'in_progress') AS in_progress,
          COUNT(*) FILTER (WHERE status = 'pending')    AS pending,
          COUNT(*) FILTER (WHERE status = 'skipped')    AS skipped
        FROM task_assignments
        WHERE assigned_date = :d
    """), {"d": d})).fetchone()

    # Par employé — avec flag is_eligible (actif + last_seen_at < 1h + eligible_prime)
    emp_rows = (await db.execute(text("""
        SELECT
          u.id, u.username, u.last_seen_at,
          COALESCE(e.nom || ' ' || COALESCE(e.prenom, ''), u.username) AS display_name,
          -- is_eligible = présent (eligible_prime) ET inactif (disponible pour tâches)
          (u.is_active = true
           AND COALESCE(e.eligible_prime, false) = true
           AND (u.last_seen_at IS NULL
                OR u.last_seen_at < NOW() - INTERVAL '1 hour'))        AS is_eligible,
          COUNT(a.id)                                                   AS total,
          COUNT(a.id) FILTER (WHERE a.status = 'done')                 AS done,
          COUNT(a.id) FILTER (WHERE a.status = 'in_progress')          AS in_progress,
          COUNT(a.id) FILTER (WHERE a.status = 'pending')              AS pending
        FROM users u
        LEFT JOIN employes e ON e.user_id = u.id
        LEFT JOIN task_assignments a
          ON a.assigned_to = u.id AND a.assigned_date = :d
        WHERE u.is_active = true
          AND u.role != 'admin'
          AND COALESCE(e.eligible_prime, false) = true
        GROUP BY u.id, u.username, u.last_seen_at, e.nom, e.prenom, e.eligible_prime
        ORDER BY is_eligible DESC, u.username
    """), {"d": d})).fetchall()

    # Assignations du jour avec détail
    assign_rows = (await db.execute(text("""
        SELECT a.*, u.username AS employee_name
        FROM task_assignments a
        JOIN users u ON u.id = a.assigned_to
        WHERE a.assigned_date = :d
        ORDER BY a.assigned_to, a.scheduled_time NULLS LAST
    """), {"d": d})).fetchall()

    assignments = [dict(r._mapping) for r in assign_rows]

    employees = []
    for e in emp_rows:
        ed = dict(e._mapping)
        ed["assignments"] = [a for a in assignments if a["assigned_to"] == ed["id"]]
        employees.append(ed)

    return {
        "date":      d.isoformat(),
        "stats":     dict(stats_row._mapping) if stats_row else {},
        "employees": employees,
    }


# ── POST /tasks/auto-assign ───────────────────────────────────────────────────

@router.post("/auto-assign")
async def auto_assign(
    target_date: Optional[date] = None,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Attribution automatique des tâches récurrentes pour la date cible.
    - Vérifie si le jour est férié (skip global).
    - Pour chaque employé actif, crée les assignations manquantes.
    - Évite les doublons (ON CONFLICT DO NOTHING via check).
    """
    d = target_date or date.today()

    # Vérifier férié
    holiday = (await db.execute(
        text("SELECT label FROM holidays WHERE date = :d"),
        {"d": d},
    )).fetchone()
    if holiday:
        return {"skipped": True, "reason": f"Jour férié : {holiday.label}"}

    # Employés cibles : présents (eligible_prime=true) ET inactifs depuis >= 1h
    # Un employé inactif = pas occupé → on lui donne des tâches à faire
    employees = (await db.execute(text("""
        SELECT u.id FROM users u
        JOIN employes e ON e.user_id = u.id
        WHERE u.is_active = true
          AND u.role != 'admin'
          AND e.eligible_prime = true
          AND (
            u.last_seen_at IS NULL
            OR u.last_seen_at < NOW() - INTERVAL '1 hour'
          )
    """))).fetchall()
    if not employees:
        return {"created": 0, "message": "Aucun employé inactif éligible pour l'instant"}

    # Templates auto-assign pour ce jour
    weekday  = d.weekday()    # 0=lundi
    monthday = d.day

    templates = (await db.execute(text("""
        SELECT * FROM task_templates
        WHERE is_active = true AND auto_assign = true
          AND recurrence != 'manual'
          AND (
            recurrence = 'daily'
            OR (recurrence = 'weekly'  AND day_of_week  = :weekday)
            OR (recurrence = 'monthly' AND day_of_month = :monthday)
          )
    """), {"weekday": weekday, "monthday": monthday})).fetchall()

    # Assignations déjà existantes (template+employee+date)
    existing = set()
    ex_rows = (await db.execute(text("""
        SELECT template_id, assigned_to
        FROM task_assignments
        WHERE assigned_date = :d AND template_id IS NOT NULL
    """), {"d": d})).fetchall()
    for r in ex_rows:
        existing.add((r.template_id, r.assigned_to))

    created = 0
    emp_ids = [e.id for e in employees]

    for tmpl in templates:
        for emp_id in emp_ids:
            if (tmpl.id, emp_id) in existing:
                continue
            aid = str(uuid.uuid4())
            await db.execute(text("""
                INSERT INTO task_assignments
                  (id, template_id, title, category, duration_min, priority,
                   assigned_to, assigned_date)
                VALUES
                  (:id, :template_id, :title, :category, :duration_min, :priority,
                   :assigned_to, :assigned_date)
            """), {
                "id": aid,
                "template_id": tmpl.id,
                "title": tmpl.title,
                "category": tmpl.category,
                "duration_min": tmpl.duration_min,
                "priority": tmpl.priority,
                "assigned_to": emp_id,
                "assigned_date": d,
            })
            created += 1

    await db.commit()
    return {"created": created, "date": d.isoformat()}
