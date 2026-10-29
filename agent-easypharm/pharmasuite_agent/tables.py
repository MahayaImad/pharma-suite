"""
Tables synchronisées depuis EASYPHARM.

L'ordre compte : une table n'est poussée qu'après celles dont elle dépend,
sinon les clés étrangères côté PostgreSQL peuvent pointer dans le vide.

Deux stratégies :

- ``incremental`` : la table ne fait que grossir (ventes, achats, mouvements).
  On ne relit que les lignes dont l'id dépasse le dernier synchronisé.
- ``full`` : la table est modifiée sur place sans que l'id change (stock d'un
  produit, solde d'un client). L'incrémental raterait ces mises à jour, donc
  on la relit en entier — moins souvent, via ``full_resync_every``.

Le nom cible est celui attendu par ``POST /sync/{table}`` ; il ne coïncide pas
toujours avec le nom HyperFileSQL d'origine.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

Strategie = Literal["incremental", "full"]


@dataclass(frozen=True)
class Table:
    cible: str          # nom attendu par l'API PharmaSuite
    source: str         # nom du fichier HyperFileSQL
    strategie: Strategie
    cle: str = "id"     # colonne d'incrément

    @property
    def incrementale(self) -> bool:
        return self.strategie == "incremental"


# Référentiels et configuration d'abord, mouvements ensuite.
TABLES: tuple[Table, ...] = (
    # ── Configuration ────────────────────────────────────────────────────────
    Table("pharmacies",   "pharmacies",   "full"),
    Table("postes",       "postes",       "full"),
    Table("groupware",    "groupware",    "full"),
    Table("prestations",  "prestations",  "full"),
    Table("motif_instance", "motif_instance", "full"),

    # ── Référentiel produit ──────────────────────────────────────────────────
    Table("familles",      "familles",      "full"),
    Table("formes",        "formes",        "full"),
    Table("laboratoires",  "laboratoires",  "full"),
    Table("nomenclature",  "nomenclature",  "full"),
    Table("nomenclature_chifa", "nomenclature_chifa", "full"),

    # ── Tiers ────────────────────────────────────────────────────────────────
    Table("clients",      "clients",      "full"),
    Table("fournisseurs", "fournisseurs", "full"),

    # ── Ventes ───────────────────────────────────────────────────────────────
    Table("sorties",          "sorties",          "incremental"),
    Table("sorties_produits", "sorties_produits", "incremental"),
    Table("instance_produits", "instance_produits", "incremental"),

    # ── Achats ───────────────────────────────────────────────────────────────
    Table("entrees",          "entrees",          "incremental"),
    Table("entrees_produits", "entrees_produits", "incremental"),
    Table("commandes_fournisseurs",          "commandes_fournisseurs",          "incremental"),
    Table("commandes_fournisseurs_produits", "commandes_fournisseurs_produits", "incremental"),

    # ── Caisse ───────────────────────────────────────────────────────────────
    Table("caisses",          "caisses",          "incremental"),
    Table("caisses_regies",   "caisses_regies",   "incremental"),
    Table("suivi_caisses",    "suivi_caisses",    "incremental"),
    Table("operations",       "operations",       "incremental"),
    Table("depenses",         "depenses",         "incremental"),
    Table("comptes_bancaires", "comptes_bancaires", "full"),

    # ── CHIFA ────────────────────────────────────────────────────────────────
    Table("bordereaux_chifa",        "bordereaux_chifa",        "incremental"),
    Table("factures_chifa",          "factures_chifa",          "incremental"),
    Table("factures_chifa_produits", "factures_chifa_produits", "incremental"),

    # ── Divers ───────────────────────────────────────────────────────────────
    Table("mouchard",         "mouchard",         "incremental"),
    Table("mouchard_details", "mouchard_details", "incremental"),
    Table("ordonnancier",     "ordonnancier",     "incremental"),
    Table("echanges",                 "echanges",                 "incremental"),
    Table("echanges_sorties_produits", "echanges_sorties_produits", "incremental"),
    Table("reg_client_association", "reg_client_association", "incremental"),
    Table("reg_fourn_association",  "reg_fourn_association",  "incremental"),
    Table("pharmnos_factures",      "pharmnos_factures",      "incremental"),

    # ── Inventaires ──────────────────────────────────────────────────────────
    Table("inventaires",          "inventaires",          "incremental"),
    Table("inventaires_produits", "inventaires_produits", "incremental"),
)


def par_nom(cible: str) -> Table:
    for t in TABLES:
        if t.cible == cible:
            return t
    raise KeyError(f"table inconnue : {cible}")
