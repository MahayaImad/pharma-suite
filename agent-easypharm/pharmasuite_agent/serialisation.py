"""
Conversion des lignes HyperFileSQL en JSON acceptable par l'API.

Le contrat côté backend (`_clean_record` dans `app/api/v1/sync.py`) est
explicite : les décimaux arrivent en **chaînes**, jamais en float. Un montant
qui passerait par un float perdrait de la précision avant même d'atteindre
PostgreSQL — voir la règle « Argent » du CLAUDE.md.

Les noms de colonnes sont normalisés : HFSQL accepte les accents
(`clôturé`, `n_assuré`, `bloqué`), PostgreSQL n'en a aucun (`cloture`,
`n_assure`, `bloque`). Sans cette normalisation, le serveur ignore la colonne
et la valeur est perdue.
"""
from __future__ import annotations

import datetime as dt
import unicodedata
from decimal import Decimal
from typing import Any, Sequence


def nom_colonne(nom: str) -> str:
    """`Clôturé` → `cloture` : minuscules, sans accents, sans espaces autour."""
    decompose = unicodedata.normalize("NFKD", nom.strip())
    sans_accents = "".join(c for c in decompose if not unicodedata.combining(c))
    return sans_accents.lower()


def _decoder(octets: bytes) -> str:
    # HFSQL stocke le texte en ANSI (cp1252) sur un poste Windows français ;
    # l'UTF-8 d'abord, au cas où le fichier a été converti en Unicode.
    try:
        return octets.decode("utf-8")
    except UnicodeDecodeError:
        return octets.decode("cp1252", errors="replace")


def valeur_json(valeur: Any) -> Any:
    """Rend une valeur lue par ADO sérialisable, sans jamais passer par float."""
    if valeur is None:
        return None
    if isinstance(valeur, bool):
        return int(valeur)
    if isinstance(valeur, Decimal):
        return str(valeur)
    if isinstance(valeur, float):
        # Le driver ne devrait pas en rendre pour un montant ; si c'est le
        # cas, on part de la représentation décimale la plus courte.
        return repr(valeur)
    if isinstance(valeur, dt.datetime):
        return valeur.isoformat()
    if isinstance(valeur, dt.date):
        return valeur.isoformat()
    if isinstance(valeur, dt.time):
        return valeur.isoformat()
    if isinstance(valeur, (bytes, bytearray, memoryview)):
        return _decoder(bytes(valeur)).rstrip()
    if isinstance(valeur, str):
        # HyperFileSQL complète les CHAR à taille fixe avec des espaces.
        return valeur.rstrip()
    return valeur


def ligne_json(colonnes: Sequence[str], ligne: Sequence[Any]) -> dict[str, Any]:
    return {nom_colonne(col): valeur_json(val) for col, val in zip(colonnes, ligne)}
