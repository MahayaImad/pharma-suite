from typing import Any
from pydantic import BaseModel


class SyncBatchPayload(BaseModel):
    """Payload envoyé par le sync agent : liste d'enregistrements bruts."""
    records: list[dict[str, Any]]


class SyncBatchResult(BaseModel):
    """Réponse après un sync batch."""
    table: str
    synced: int
    errors: int = 0


class SyncStatusResponse(BaseModel):
    """Statut de synchronisation d'une table."""
    table: str
    last_id: int
    total_synced: int


class SyncStatusUpdate(BaseModel):
    """Mise à jour du statut de synchronisation."""
    last_id: int
    count: int
