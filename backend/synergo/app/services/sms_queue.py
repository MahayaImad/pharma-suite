"""
File d'attente SMS en mémoire.

Cycle de vie d'un job :
    enqueue()  →  queue (pending)
    get_next() →  in-flight (_pending dict)
    ack()      →  retiré (_pending)
    nack()     →  remis dans queue si retries < MAX_RETRIES

Un seul gateway Android connecté à la fois.
"""

from __future__ import annotations

import asyncio
import logging
import uuid
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Optional

logger = logging.getLogger(__name__)

MAX_RETRIES = 3


@dataclass
class SmsJob:
    sms_id: str
    phone: str
    message: str
    created_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    retries: int = 0

    def to_dict(self) -> dict:
        return {
            "sms_id":  self.sms_id,
            "phone":   self.phone,
            "message": self.message,
        }


# ── État global ────────────────────────────────────────────────────────────────

_queue: asyncio.Queue[SmsJob] = asyncio.Queue()
_pending: dict[str, SmsJob] = {}   # sms_id → job envoyé mais pas encore acquitté
_gateway_connected: bool = False


# ── API publique ───────────────────────────────────────────────────────────────

async def enqueue(phone: str, message: str) -> str:
    """Ajoute un SMS dans la file. Retourne son sms_id."""
    sms_id = str(uuid.uuid4())
    await _queue.put(SmsJob(sms_id=sms_id, phone=phone, message=message))
    logger.info("[QUEUE] enqueue sms_id=%s phone=%s queue_size=%d", sms_id, phone, _queue.qsize())
    return sms_id


async def enqueue_with_id(sms_id: str, phone: str, message: str) -> None:
    """Remet en queue un SMS existant (redémarrage). N'alloue pas un nouvel UUID."""
    await _queue.put(SmsJob(sms_id=sms_id, phone=phone, message=message))
    logger.info("[QUEUE] enqueue_with_id sms_id=%s phone=%s queue_size=%d", sms_id, phone, _queue.qsize())


async def get_next(timeout: float = 30.0) -> Optional[SmsJob]:
    """
    Attend le prochain job (timeout secondes).
    Retourne None si aucun job dans le délai.
    """
    try:
        job = await asyncio.wait_for(_queue.get(), timeout=timeout)
        _pending[job.sms_id] = job
        logger.info("[QUEUE] get_next → sms_id=%s retries=%d pending_count=%d",
                    job.sms_id, job.retries, len(_pending))
        return job
    except asyncio.TimeoutError:
        return None


def ack(sms_id: str) -> Optional[SmsJob]:
    """Acquittement : le SMS a bien été envoyé."""
    job = _pending.pop(sms_id, None)
    if job is not None:
        logger.info("[QUEUE] ack sms_id=%s pending_remaining=%d", sms_id, len(_pending))
    else:
        logger.warning("[QUEUE] ack sms_id=%s introuvable dans _pending", sms_id)
    return job


def nack(sms_id: str) -> Optional[SmsJob]:
    """
    Échec : remet le job dans la queue si retries < MAX_RETRIES,
    sinon le supprime (sera marqué failed en DB par l'appelant).
    """
    job = _pending.pop(sms_id, None)
    if job is None:
        logger.warning("[QUEUE] nack sms_id=%s introuvable dans _pending", sms_id)
        return None
    job.retries += 1
    if job.retries < MAX_RETRIES:
        _queue.put_nowait(job)
        logger.info("[QUEUE] nack sms_id=%s → re-enqueued (retry %d/%d)", sms_id, job.retries, MAX_RETRIES)
        return job
    logger.warning("[QUEUE] nack sms_id=%s → abandon (retries épuisés %d)", sms_id, job.retries)
    return None  # abandon


def requeue_all_pending() -> int:
    """
    Remet tous les jobs in-flight dans la queue (appelé à la déconnexion).
    Retourne le nombre de jobs remis.
    """
    count = 0
    for job in list(_pending.values()):
        del _pending[job.sms_id]
        job.retries += 1
        if job.retries < MAX_RETRIES:
            _queue.put_nowait(job)
            count += 1
    return count


def drain_pending() -> list[str]:
    """
    Vide les jobs in-flight sans les remettre en queue.
    Retourne la liste des sms_id abandonnés (à marquer failed en DB).
    Utilisé pour éviter les double-envois après déconnexion.
    """
    ids = list(_pending.keys())
    _pending.clear()
    return ids


def set_gateway_connected(state: bool) -> None:
    global _gateway_connected
    _gateway_connected = state


def is_gateway_connected() -> bool:
    return _gateway_connected


def queue_size() -> int:
    return _queue.qsize()


def pending_count() -> int:
    return len(_pending)
