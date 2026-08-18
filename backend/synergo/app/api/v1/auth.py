"""
Auth endpoints — Login, profil utilisateur, gestion des comptes
"""
from fastapi import APIRouter, Depends, HTTPException, status, Body
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from pydantic import BaseModel
from typing import Optional
from loguru import logger

from app.core.database import get_db
from app.core.security import (
    verify_password, hash_password,
    create_access_token, get_current_user,
)
from app.models.user import User
from app.models.config_tables import Groupware
from app.schemas.auth import TokenResponse
from app.core.config import settings

router = APIRouter(tags=["auth"])


# ── Helpers ───────────────────────────────────────────────────────────────────

def _groupware_role(gw: Groupware) -> str:
    """id=1 (Administrator) → admin, tout le reste → employee."""
    return "admin" if gw.id == 1 else "employee"


async def _require_admin(current: dict = Depends(get_current_user)):
    if current.get("role") not in ("admin",):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès réservé aux administrateurs",
        )
    return current


async def _upsert_user_from_groupware(db: AsyncSession, gw: Groupware, plain_password: str):
    """
    Crée ou met à jour l'entrée dans `users` à partir des données groupware.
    Appelé à la connexion et lors du sync nightly.
    """
    if not gw.utilisateur or not plain_password:
        return
    pwd_safe = plain_password.encode("utf-8")[:72].decode("utf-8", errors="ignore")
    stmt = (
        pg_insert(User.__table__)
        .values(
            username=gw.utilisateur,
            hashed_password=hash_password(pwd_safe),
            is_active=(gw.actif == 1) if gw.actif is not None else True,
            role=_groupware_role(gw),
        )
        .on_conflict_do_update(
            index_elements=["username"],
            set_={
                "hashed_password": hash_password(pwd_safe),
                "is_active": (gw.actif == 1) if gw.actif is not None else True,
                "role": _groupware_role(gw),
            },
        )
    )
    await db.execute(stmt)
    await db.commit()


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.get("/auth/me")
async def me(
    db: AsyncSession = Depends(get_db),
    current: dict = Depends(get_current_user),
):
    """Retourne le profil de l'utilisateur connecté."""
    username = current.get("username")
    role = current.get("role", "employee")

    gw = await db.execute(
        select(Groupware).where(Groupware.utilisateur == username)
    )
    gw_row = gw.scalar_one_or_none()

    return {
        "username": username,
        "role": role,
        "nom": gw_row.nom if gw_row else None,
        "prenom": gw_row.prenom if gw_row else None,
    }


@router.post("/auth/login", response_model=TokenResponse)
async def login(
    form: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db),
):
    """
    Authentification — 3 sources par ordre de priorité :
    1. Sync agent (credentials statiques dans .env)
    2. Table `users`  (mot de passe bcrypt hashé)
    3. Table `groupware` (mot de passe en clair depuis HFSQL)
       → crée/met à jour automatiquement l'entrée dans `users`
    """
    # ── 1. Sync agent ──────────────────────────────────────────────────────
    if (
        form.username == settings.sync_agent_username
        and form.password == settings.sync_agent_password
    ):
        logger.info(f"[login] '{form.username}' → OK (sync_agent)")
        token = create_access_token({"sub": form.username, "role": "sync_agent"})
        return TokenResponse(access_token=token)

    # ── 2. Table users (bcrypt) ────────────────────────────────────────────
    user_res = await db.execute(
        select(User).where(User.username == form.username)
    )
    user = user_res.scalar_one_or_none()

    if user:
        if not verify_password(form.password, user.hashed_password):
            logger.warning(f"[login] '{form.username}' → 401 mauvais mot de passe")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Identifiants incorrects",
                headers={"WWW-Authenticate": "Bearer"},
            )
        if not user.is_active:
            logger.warning(f"[login] '{form.username}' → 403 compte désactivé")
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Compte désactivé",
            )
        logger.info(f"[login] '{form.username}' → OK role={user.role}")
        token = create_access_token({"sub": user.username, "role": user.role})
        return TokenResponse(access_token=token)

    # ── 3. Table groupware (mot de passe en clair) ─────────────────────────
    gw_res = await db.execute(
        select(Groupware).where(Groupware.utilisateur == form.username)
    )
    gw = gw_res.scalar_one_or_none()

    if not gw or gw.mot_de_passe != form.password:
        logger.warning(f"[login] '{form.username}' → 401 identifiants incorrects")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Identifiants incorrects",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if gw.actif == 0:
        logger.warning(f"[login] '{form.username}' → 403 compte désactivé")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Compte désactivé",
        )

    # Auto-créer l'entrée hachée dans `users` pour les prochaines connexions
    await _upsert_user_from_groupware(db, gw, form.password)

    role = _groupware_role(gw)
    logger.info(f"[login] '{form.username}' → OK role={role} (groupware fallback)")
    token = create_access_token({"sub": gw.utilisateur, "role": role})
    return TokenResponse(access_token=token)


# ── Gestion des utilisateurs (admin) ──────────────────────────────────────────

class CreateUserRequest(BaseModel):
    username: str
    password: str
    role: str = "employee"
    is_active: bool = True


@router.get("/auth/users")
async def list_users(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(_require_admin),
):
    """Liste tous les comptes utilisateurs (admin uniquement)."""
    res = await db.execute(select(User).order_by(User.username))
    users = res.scalars().all()

    # Enrichir avec les données groupware (nom/prénom)
    gw_res = await db.execute(select(Groupware))
    gw_map = {g.utilisateur: g for g in gw_res.scalars().all()}

    return [
        {
            "id": u.id,
            "username": u.username,
            "role": u.role,
            "is_active": u.is_active,
            "nom": gw_map[u.username].nom if u.username in gw_map else None,
            "prenom": gw_map[u.username].prenom if u.username in gw_map else None,
        }
        for u in users
    ]


@router.post("/auth/users", status_code=status.HTTP_201_CREATED)
async def create_user(
    body: CreateUserRequest,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(_require_admin),
):
    """Crée un compte utilisateur (admin uniquement)."""
    existing = await db.execute(
        select(User).where(User.username == body.username)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"L'utilisateur '{body.username}' existe déjà",
        )

    new_user = User(
        username=body.username,
        hashed_password=hash_password(body.password),
        role=body.role,
        is_active=body.is_active,
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)

    return {"id": new_user.id, "username": new_user.username, "role": new_user.role}


@router.patch("/auth/users/{user_id}")
async def update_user(
    user_id: int,
    password: Optional[str] = Body(None),
    role: Optional[str] = Body(None),
    is_active: Optional[bool] = Body(None),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(_require_admin),
):
    """Met à jour un compte utilisateur (admin uniquement)."""
    res = await db.execute(select(User).where(User.id == user_id))
    user = res.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable")

    if password:
        user.hashed_password = hash_password(password)
    if role:
        user.role = role
    if is_active is not None:
        user.is_active = is_active

    await db.commit()
    return {"id": user.id, "username": user.username, "role": user.role, "is_active": user.is_active}
