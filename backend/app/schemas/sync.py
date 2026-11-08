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
    # Lignes refusées par PostgreSQL, avec leur id et la cause. L'agent ne
    # doit pas avancer son curseur tant que cette liste n'est pas vide.
    rejected: list[dict[str, Any]] = []
    # Valeurs inconvertibles (date illisible…), écrites à NULL.
    invalid_values: list[dict[str, Any]] = []
    # Clés reçues sans colonne PostgreSQL correspondante : perdues à l'import.
    ignored_columns: list[str] = []


class SyncStatusResponse(BaseModel):
    """Statut de synchronisation d'une table."""
    table: str
    last_id: int
    total_synced: int


class SyncStatusUpdate(BaseModel):
    """Mise à jour du statut de synchronisation."""
    last_id: int
    count: int


class SyncTableSchema(BaseModel):
    """Colonnes et volumétrie d'une table miroir, pour la vérification."""
    table: str
    columns: list[str]
    count: int
