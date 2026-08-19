from contextlib import asynccontextmanager
import logging
import time

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
import sys

from jose import JWTError, jwt
from sqlalchemy import text

from app.core.config import settings
from app.core.database import engine, AsyncSessionLocal
from app.api.v1.router import router
from app.services.stock_segmentation import compute_abc, compute_xyz
from app.services import sms_queue

# ── Throttle last_seen_at : 1 écriture DB par user toutes les 5 minutes ───────
_activity_cache: dict[str, float] = {}   # username → epoch
_ACTIVITY_INTERVAL = 300                  # secondes


# ── Logging ────────────────────────────────────────────────────────────────────
logger.remove()
logger.add(sys.stderr, format="<green>{time:HH:mm:ss}</green> | <level>{level: <8}</level> | {message}", level="INFO")
logger.add("logs/api.log", rotation="10 MB", retention="30 days", level="DEBUG")

# Pont stdlib logging → loguru : capture les logs des modules qui utilisent
# logging.getLogger() (sms.py, sms_queue.py, uvicorn, sqlalchemy…)
class _InterceptHandler(logging.Handler):
    def emit(self, record: logging.LogRecord) -> None:
        try:
            level = logger.level(record.levelname).name
        except ValueError:
            level = record.levelno
        frame, depth = logging.currentframe(), 2
        while frame.f_code.co_filename == logging.__file__:
            frame = frame.f_back  # type: ignore[assignment]
            depth += 1
        logger.opt(depth=depth, exception=record.exc_info).log(level, record.getMessage())

logging.basicConfig(handlers=[_InterceptHandler()], level=logging.DEBUG, force=True)


# ── Scheduler ─────────────────────────────────────────────────────────────────

_scheduler = AsyncIOScheduler(timezone="Africa/Algiers")


async def _monthly_segmentation() -> None:
    """Calcule ABC + XYZ le 1er de chaque mois à 02h00."""
    logger.info("[Scheduler] Démarrage segmentation mensuelle ABC/XYZ...")
    async with AsyncSessionLocal() as db:
        await compute_abc(db)
        await compute_xyz(db)
    logger.info("[Scheduler] Segmentation mensuelle terminée.")


# ── Startup / Shutdown ─────────────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Pas de create_all ici : le schéma appartient à Alembic, et lui seul.
    # Les deux mécanismes ont longtemps coexisté, ce qui faisait échouer
    # 5 migrations sur une base neuve (la colonne existait déjà). Toute
    # modification de schéma passe désormais par une migration.
    logger.info("Démarrage de l'application.")

    # Remet en queue les SMS pending laissés par un redémarrage précédent
    async with AsyncSessionLocal() as db:
        rows = (await db.execute(
            text("SELECT id, phone, message FROM sms_logs WHERE status = 'pending' ORDER BY created_at")
        )).fetchall()
        if rows:
            for row in rows:
                await sms_queue.enqueue_with_id(row.id, row.phone, row.message)
            logger.info("[SMS] %d SMS pending remis en queue après redémarrage", len(rows))

    # Scheduler mensuel ABC/XYZ — 1er du mois à 02h00
    _scheduler.add_job(
        _monthly_segmentation,
        CronTrigger(day=1, hour=2, minute=0),
        id="monthly_abc_xyz",
        replace_existing=True,
    )
    _scheduler.start()
    logger.info("[Scheduler] Scheduler mensuel ABC/XYZ activé.")

    yield

    _scheduler.shutdown(wait=False)
    logger.info("Arrêt de l'application.")
    await engine.dispose()


# ── Application ────────────────────────────────────────────────────────────────
app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    docs_url=f"{settings.api_prefix}/docs",
    redoc_url=f"{settings.api_prefix}/redoc",
    openapi_url=f"{settings.api_prefix}/openapi.json",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router, prefix=settings.api_prefix)


# ── Middleware activité ────────────────────────────────────────────────────────

@app.middleware("http")
async def activity_middleware(request: Request, call_next):
    """
    Met à jour last_seen_at pour chaque utilisateur authentifié.
    Throttlé : 1 écriture DB par utilisateur toutes les 5 minutes.
    """
    response = await call_next(request)

    auth = request.headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        return response

    token = auth.removeprefix("Bearer ").strip()
    try:
        payload = jwt.decode(token, settings.secret_key,
                             algorithms=[settings.algorithm])
        username: str | None = payload.get("sub")
    except JWTError:
        return response

    if not username:
        return response

    now = time.time()
    if now - _activity_cache.get(username, 0) < _ACTIVITY_INTERVAL:
        return response   # pas besoin d'écrire, déjà récent

    _activity_cache[username] = now
    try:
        async with AsyncSessionLocal() as db:
            await db.execute(
                text("UPDATE users SET last_seen_at = NOW() WHERE username = :u"),
                {"u": username},
            )
            await db.commit()
    except Exception:
        pass   # ne jamais bloquer une réponse pour ça

    return response


@app.get("/health", tags=["health"])
async def health():
    return {"status": "ok", "app": settings.app_name}
