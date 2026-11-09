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


def normaliser_heure(valeur: Any) -> str | None:
    """
    Heure HFSQL → `HH:MM:SS`, zéro-paddé.

    Le type « Heure » de HFSQL sort de l'OLE DB sous plusieurs formes selon
    la version : horodatage complet, `HH:MM:SS:CC` (centièmes), `HHMMSSCC`.
    PostgreSQL le stocke en `VARCHAR(10)`, et `grh_presence.py` fait
    `MIN(heure)` puis `heure[:5]` : il faut donc un format fixe, trié
    correctement en ordre lexicographique. Une forme inconnue est laissée
    telle quelle, et le serveur la signalera.
    """
    if valeur is None:
        return None
    if isinstance(valeur, (dt.datetime, dt.time)):
        return valeur.strftime("%H:%M:%S")
    texte = valeur_json(valeur)
    if not isinstance(texte, str):
        texte = str(texte)
    texte = texte.strip()
    if not texte:
        return None
    if "T" in texte or " " in texte:
        texte = texte.replace("T", " ").split(" ")[-1]
    texte = texte.split(".")[0].split("+")[0]
    morceaux = texte.split(":")
    if len(morceaux) >= 2 and all(m.isdigit() for m in morceaux):
        h, m = int(morceaux[0]), int(morceaux[1])
        sec = int(morceaux[2]) if len(morceaux) > 2 else 0
        return f"{h:02d}:{m:02d}:{sec:02d}"
    if texte.isdigit() and len(texte) in (4, 6, 8):
        sec = texte[4:6] or "00"
        return f"{texte[0:2]}:{texte[2:4]}:{sec}"
    return texte


def _est_heure(nom: str) -> bool:
    # heure, heure_debut, heure_fin, heure_ouverture…
    return nom == "heure" or nom.startswith("heure_")


def ligne_json(colonnes: Sequence[str], ligne: Sequence[Any]) -> dict[str, Any]:
    resultat = {}
    for col, val in zip(colonnes, ligne):
        nom = nom_colonne(col)
        resultat[nom] = normaliser_heure(val) if _est_heure(nom) else valeur_json(val)
    return resultat
