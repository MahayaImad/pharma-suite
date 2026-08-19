"""
SMS Gateway — API FastAPI.

Endpoints REST :
    POST   /sms/send              Enfile un SMS, retourne sms_id
    GET    /sms/{sms_id}          Statut d'un SMS
    GET    /sms/logs              Historique paginé
    GET    /sms/gateway-status    État de la connexion Android

WebSocket :
    WS     /sms/ws                Canal dédié à l'app Android gateway

Protocole WebSocket (JSON) :

    Backend → Android :
        { "type": "sms", "sms_id": "...", "phone": "...", "message": "..." }
        { "type": "ping" }

    Android → Backend :
        { "type": "ack",   "sms_id": "...", "status": "sent" }
        { "type": "ack",   "sms_id": "...", "status": "failed", "error": "..." }
        { "type": "pong" }
        { "type": "auth",  "token": "..." }
"""

from __future__ import annotations

import json
import logging
import os
import uuid
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, WebSocket, WebSocketDisconnect
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.services import sms_queue

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/sms", tags=["sms"])

# Token partagé entre le backend et l'app Android (variable d'environnement)
# Secret partagé avec le boîtier SMS : sa valeur est un contrat avec un
# appareil externe, elle ne suit pas le renommage du produit. À rotationner
# délibérément, via la variable d'environnement.
SMS_GATEWAY_TOKEN = os.getenv("SMS_GATEWAY_TOKEN", "synergo-sms-gateway-secret-2026")


# ── Schémas ────────────────────────────────────────────────────────────────────

class SendSmsRequest(BaseModel):
    phone: str
    message: str


# ── POST /sms/send ─────────────────────────────────────────────────────────────

@router.post("/send")
async def send_sms(
    req: SendSmsRequest,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    """
    Enfile un SMS pour envoi via le gateway Android.
    Retourne immédiatement le sms_id ; l'envoi est asynchrone.
    """
    if not req.phone or not req.message:
        raise HTTPException(status_code=400, detail="phone et message requis")

    sms_id = str(uuid.uuid4())
    utilisateur = current_user.get('sub', '') or ''
    logger.info("[SEND] début sms_id=%s phone=%s msg_len=%d gateway_connected=%s",
                sms_id, req.phone, len(req.message), sms_queue.is_gateway_connected())

    # INSERT en base AVANT l'enqueue : évite une race condition où le
    # WebSocket loop traite l'ack avant que la ligne existe en DB,
    # ce qui ferait échouer l'UPDATE et déconnecter le gateway.
    try:
        await db.execute(text("""
            INSERT INTO sms_logs (id, phone, message, status, utilisateur, created_at)
            VALUES (:id, :phone, :message, 'pending', :utilisateur, NOW())
        """), {"id": sms_id, "phone": req.phone, "message": req.message, "utilisateur": utilisateur})
        await db.commit()
        logger.info("[SEND] INSERT DB ok sms_id=%s", sms_id)
    except Exception:
        logger.exception("[SEND] ERREUR INSERT DB sms_id=%s", sms_id)
        raise

    await sms_queue.enqueue_with_id(sms_id, req.phone, req.message)
    logger.info("[SEND] enqueued sms_id=%s queue_size=%d", sms_id, sms_queue.queue_size())

    return {
        "sms_id":    sms_id,
        "status":    "pending",
        "gateway_connected": sms_queue.is_gateway_connected(),
        "queue_size": sms_queue.queue_size(),
    }


# ── GET /sms/logs ──────────────────────────────────────────────────────────────

@router.get("/logs")
async def get_sms_logs(
    status: Optional[str] = Query(None, description="pending|sent|failed"),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    extra = "AND status = :status" if status else ""
    params: dict = {"limit": limit, "offset": offset}
    if status:
        params["status"] = status

    rows = (await db.execute(text(f"""
        SELECT * FROM sms_logs
        WHERE 1=1 {extra}
        ORDER BY created_at DESC
        LIMIT :limit OFFSET :offset
    """), params)).fetchall()

    return [dict(r._mapping) for r in rows]


# ── GET /sms/gateway-status ────────────────────────────────────────────────────

@router.get("/gateway-status")
async def gateway_status(_: dict = Depends(get_current_user)):
    return {
        "connected":     sms_queue.is_gateway_connected(),
        "queue_size":    sms_queue.queue_size(),
        "pending_count": sms_queue.pending_count(),
    }


# ── GET /sms/{sms_id} — doit être EN DERNIER pour ne pas capturer /logs etc. ──

@router.get("/{sms_id}")
async def get_sms_status(
    sms_id: str,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    row = (await db.execute(
        text("SELECT * FROM sms_logs WHERE id = :id"),
        {"id": sms_id},
    )).fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="SMS introuvable")

    return dict(row._mapping)


# ── WebSocket /sms/ws ──────────────────────────────────────────────────────────

import asyncio as _asyncio

_session_id: int = 0   # incrémenté à chaque nouvelle connexion acceptée


@router.websocket("/ws")
async def sms_gateway_ws(websocket: WebSocket):
    """
    Canal WebSocket réservé à l'app Android SMS gateway.
    Chaque nouvelle connexion reçoit un session_id — l'ancienne boucle
    détecte qu'elle est dépassée et s'arrête proprement sans fermer la socket.
    """
    global _session_id

    await websocket.accept()
    logger.info("SMS gateway : nouvelle connexion WebSocket")

    # ── Authentification ───────────────────────────────────────────────────────
    try:
        raw = await _asyncio.wait_for(websocket.receive_text(), timeout=10.0)
        msg = json.loads(raw)
        if msg.get("type") != "auth" or msg.get("token") != SMS_GATEWAY_TOKEN:
            await websocket.send_text(json.dumps({"type": "error", "detail": "unauthorized"}))
            await websocket.close(code=4001)
            logger.warning("SMS gateway : authentification échouée")
            return
    except Exception:
        await websocket.close(code=4001)
        return

    # ── Connexion acceptée — cette session prend le dessus ────────────────────
    _session_id += 1
    my_session = _session_id
    sms_queue.set_gateway_connected(True)
    await websocket.send_text(json.dumps({"type": "ready"}))
    logger.info("[WS] session %d prête — gateway connecté", my_session)

    try:
        from app.core.database import AsyncSessionLocal

        while my_session == _session_id:
            logger.debug("[WS:%d] attente prochain job (queue=%d pending=%d)",
                         my_session, sms_queue.queue_size(), sms_queue.pending_count())
            job = await sms_queue.get_next(timeout=15.0)

            # Vérifier qu'on est toujours la session active
            if my_session != _session_id:
                logger.warning("[WS:%d] session dépassée (%d), sortie boucle", my_session, _session_id)
                break

            if job is None:
                # Keepalive ping
                logger.debug("[WS:%d] ping keepalive", my_session)
                try:
                    await websocket.send_text(json.dumps({"type": "ping"}))
                    raw_pong = await _asyncio.wait_for(websocket.receive_text(), timeout=15.0)
                    pong = json.loads(raw_pong)
                    logger.debug("[WS:%d] reçu après ping : %s", my_session, raw_pong[:200])
                    if pong.get("type") != "pong":
                        logger.info("[WS:%d] message non-pong reçu pendant keepalive : %s", my_session, raw_pong[:200])
                        await _process_ack(pong)
                except _asyncio.TimeoutError:
                    logger.warning("[WS:%d] timeout pong — fermeture 1001", my_session)
                    try:
                        await websocket.close(code=1001)
                    except Exception:
                        pass
                    break
                except Exception:
                    logger.exception("[WS:%d] erreur pendant keepalive", my_session)
                    break
                continue

            # Envoyer le SMS au téléphone
            logger.info("[WS:%d] envoi job sms_id=%s phone=%s", my_session, job.sms_id, job.phone)
            try:
                payload = json.dumps({"type": "sms", **job.to_dict()})
                await websocket.send_text(payload)
                logger.info("[WS:%d] job envoyé au gateway sms_id=%s — attente ack (45s)", my_session, job.sms_id)
            except Exception:
                logger.exception("[WS:%d] ERREUR envoi WS sms_id=%s — nack + sortie", my_session, job.sms_id)
                sms_queue.nack(job.sms_id)
                break

            # Attendre l'ack Android (45s max)
            try:
                raw_ack = await _asyncio.wait_for(websocket.receive_text(), timeout=45.0)
                logger.info("[WS:%d] ack reçu sms_id=%s raw=%s", my_session, job.sms_id, raw_ack[:500])
                try:
                    await _process_ack(json.loads(raw_ack))
                except Exception:
                    logger.exception("[WS:%d] ERREUR _process_ack sms_id=%s raw=%s — connexion maintenue",
                                     my_session, job.sms_id, raw_ack[:500])
            except _asyncio.TimeoutError:
                logger.warning("[WS:%d] TIMEOUT ack sms_id=%s (45s) — marqué failed, boucle continue",
                               my_session, job.sms_id)
                sms_queue.ack(job.sms_id)
                try:
                    from app.core.database import AsyncSessionLocal
                    async with AsyncSessionLocal() as _db:
                        await _update_status(_db, job.sms_id, "failed", "timeout ack Android (45 s)")
                except Exception:
                    logger.exception("[WS:%d] impossible de marquer failed sms_id=%s", my_session, job.sms_id)

    except WebSocketDisconnect:
        logger.info("[WS:%d] WebSocketDisconnect reçu", my_session)
    except Exception as exc:
        logger.exception("[WS:%d] EXCEPTION non gérée dans la boucle : %s", my_session, exc)
    finally:
        inflight = sms_queue.pending_count()
        logger.info("[WS:%d] finally — my_session=%d _session_id=%d inflight=%d",
                    my_session, my_session, _session_id, inflight)
        if my_session == _session_id:
            sms_queue.set_gateway_connected(False)
            pending = sms_queue.drain_pending()
            if pending:
                logger.warning("[WS:%d] %d jobs in-flight abandonnés : %s", my_session, len(pending), pending)
                from app.core.database import AsyncSessionLocal
                async with AsyncSessionLocal() as db:
                    for sms_id in pending:
                        await _update_status(db, sms_id, "failed", "connexion perdue avant ack")
            logger.info("[WS:%d] gateway marqué déconnecté", my_session)
        else:
            logger.info("[WS:%d] session obsolète, gateway toujours géré par session %d", my_session, _session_id)


async def _process_ack(msg: dict) -> None:
    """Traite un message ack/nack reçu de l'Android."""
    msg_type = msg.get("type")
    logger.info("[ACK] _process_ack type=%s sms_id=%s status=%s error=%s",
                msg_type, msg.get("sms_id"), msg.get("status"), msg.get("error"))

    if msg_type not in ("ack",):
        logger.debug("[ACK] type ignoré : %s", msg_type)
        return

    sms_id = msg.get("sms_id")
    status = msg.get("status")  # "sent" | "failed"
    error  = msg.get("error")

    if not sms_id:
        logger.error("[ACK] ack sans sms_id — message ignoré : %s", msg)
        return

    from app.core.database import AsyncSessionLocal
    async with AsyncSessionLocal() as db:
        if status == "sent":
            sms_queue.ack(sms_id)
            logger.info("[ACK] → UPDATE sms_id=%s status=sent", sms_id)
            await _update_status(db, sms_id, "sent")
        else:
            job = sms_queue.nack(sms_id)
            new_status = "pending" if job else "failed"
            logger.warning("[ACK] → ack failed sms_id=%s new_status=%s error=%s retries_left=%s",
                           sms_id, new_status, error, "oui" if job else "non")
            await _update_status(db, sms_id, new_status, error)


async def _update_status(db: AsyncSession, sms_id: str, status: str, error: str | None = None) -> None:
    sent_at_sql = ", sent_at = NOW()" if status == "sent" else ""
    logger.info("[DB] UPDATE sms_logs sms_id=%s status=%s error=%s", sms_id, status, error)
    try:
        await db.execute(text(f"""
            UPDATE sms_logs
            SET status = :status,
                error  = :error
                {sent_at_sql}
            WHERE id = :id
        """), {"id": sms_id, "status": status, "error": error})
        await db.commit()
        logger.info("[DB] UPDATE ok sms_id=%s", sms_id)
    except Exception:
        logger.exception("[DB] ERREUR UPDATE sms_id=%s status=%s", sms_id, status)
        raise
