"""
Génériques d'une même DCI : lesquels commander — calcul pur.

Règle arrêtée avec l'officine le 2026-11-15 :

- Les produits de même code DCI (`nomenclature.de_equiv`, dosage et forme
  compris : 04B044, 06M198…) forment un **groupe**.
- Les 3 premiers caractères du code donnent la **classe thérapeutique**
  (« 14A » : antidiabétiques ; « 06M » : hypolipémiants). Une classe liée à une
  maladie chronique de la CNAS (table `classe_maladie`) est **chronique** :
  chaque patient est habitué à sa marque, **toutes** les marques restent
  commandées.
- Sinon (AINS…), on ne garde que les **marques les plus vendues** sur 12 mois,
  parmi les **disponibles** (en stock ou vendues récemment ; un générique
  introuvable depuis un moment est ignoré). Les autres ne sont plus
  commandées ; une fois leur stock épuisé, leur demande se reporte sur les
  marques gardées, au prorata de leurs ventes.
- Le titulaire peut forcer un groupe (« toutes » / « quelques ») et un
  produit (« garder » / « exclure »).
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Optional

TOUTES = "toutes"
QUELQUES = "quelques"


def normaliser(code: Optional[str]) -> Optional[str]:
    """« 06 M 198 » → « 06M198 » ; vide → None."""
    if code is None:
        return None
    c = "".join(code.split()).upper()
    return c or None


def classe(code: str) -> str:
    """Classe thérapeutique : les 3 premiers caractères (« 14A »)."""
    return code[:3]


@dataclass(frozen=True)
class Membre:
    id: int
    ventes: float          # quantité vendue sur 12 mois
    disponible: bool       # en stock ou vendu récemment
    choix: Optional[str] = None   # « garder » | « exclure » | None


@dataclass
class Statut:
    """Ce que la commande fait d'un produit de son groupe."""
    code: str
    mode: str                                   # toutes | quelques
    garde: bool
    remplace_par: list[int] = field(default_factory=list)   # si non gardé
    parts: dict[int, float] = field(default_factory=dict)   # si non gardé : part de chaque gardé


def mode_du_groupe(code: str, classes_chroniques: set[str], force: Optional[str] = None) -> str:
    if force in (TOUTES, QUELQUES):
        return force
    return TOUTES if classe(code) in classes_chroniques else QUELQUES


def choisir(code: str, membres: list[Membre], mode: str, nombre: int) -> dict[int, Statut]:
    """Statut de chaque membre d'un groupe."""
    if mode == TOUTES or len(membres) < 2:
        return {m.id: Statut(code, mode, garde=m.choix != "exclure") for m in membres}
    exclus = {m.id for m in membres if m.choix == "exclure"}
    forces = [m for m in membres if m.choix == "garder"]
    candidats = sorted((m for m in membres if m.disponible and m.id not in exclus and m.choix != "garder"),
                       key=lambda m: (-m.ventes, m.id))
    gardes = forces + candidats[:max(0, nombre - len(forces))]
    if not gardes:
        # Aucun générique disponible : on ne retire rien (sauf les exclus).
        return {m.id: Statut(code, mode, garde=m.id not in exclus) for m in membres}
    ids = [m.id for m in gardes]
    total = sum(m.ventes for m in gardes)
    parts = {m.id: (m.ventes / total if total > 0 else 1 / len(gardes)) for m in gardes}
    return {m.id: (Statut(code, mode, garde=True) if m.id in ids
                   else Statut(code, mode, garde=False, remplace_par=ids, parts=parts))
            for m in membres}
