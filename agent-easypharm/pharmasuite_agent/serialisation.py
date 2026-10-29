"""
Conversion des lignes HyperFileSQL en JSON acceptable par l'API.

Le contrat côté backend (`_clean_record` dans `app/api/v1/sync.py`) est
explicite : les dates arrivent en « YYYY-MM-DD » et les décimaux en
**chaînes**, jamais en float. Un montant qui passerait par un float perdrait
de la précision avant même d'atteindre PostgreSQL — voir la règle « Argent »
du CLAUDE.md.
"""
from __future__ import annotations

import datetime as dt
from decimal import Decimal
from typing import Any, Sequence


def valeur_json(valeur: Any) -> Any:
    """Rend une valeur ODBC sérialisable, sans jamais passer par float."""
    if valeur is None:
        return None
    if isinstance(valeur, Decimal):
        return str(valeur)
    if isinstance(valeur, dt.datetime):
        return valeur.isoformat()
    if isinstance(valeur, dt.date):
        return valeur.isoformat()
    if isinstance(valeur, dt.time):
        return valeur.isoformat()
    if isinstance(valeur, (bytes, bytearray)):
        return valeur.decode("utf-8", errors="replace")
    if isinstance(valeur, str):
        # HyperFileSQL complète les CHAR à taille fixe avec des espaces.
        return valeur.rstrip()
    return valeur


def ligne_json(colonnes: Sequence[str], ligne: Sequence[Any]) -> dict[str, Any]:
    return {col: valeur_json(val) for col, val in zip(colonnes, ligne)}
