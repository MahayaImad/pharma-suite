"""
Tables synchronisées depuis EASYPHARM.

L'ordre compte : une table n'est poussée qu'après celles dont elle dépend,
sinon les clés étrangères côté PostgreSQL peuvent pointer dans le vide.

Quatre stratégies :

- ``incremental`` : la table ne fait que grossir (ventes, achats, mouvements).
  On ne relit que les lignes dont l'id dépasse le dernier synchronisé.
- ``window`` : fenêtre glissante sur la date + champ modif. Pour les tables
  dont les enregistrements sont modifiés sur place (sorties ouvertes, etc.)
- ``full`` : la table est modifiée sur place sans que l'id change (stock d'un
  produit, solde d'un client). L'incrémental raterait ces mises à jour, donc
  on la relit en entier — moins souvent, via ``full_resync_every``.
- ``pipeline`` : cas spécial instance_produits (seule table avec DELETE).

Le nom cible est celui attendu par ``POST /sync/{table}`` ; il ne coïncide pas
toujours avec le nom HyperFileSQL d'origine.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Literal

Strategie = Literal["incremental", "window", "full", "pipeline"]


@dataclass(frozen=True)
class Table:
    cible: str                          # nom attendu par l'API PharmaSuite
    source: str                         # nom du fichier HyperFileSQL
    strategie: Strategie
    cle: str = "id"                     # colonne d'incrément
    intervalle_minutes: int = 60        # fréquence de sync
    taille_lot: int = 500               # batch size
    fenetre_jours: int = 30             # pour stratégie window
    champ_modif: str | None = None      # champ indiquant une modification
    condition_extra: str | None = None  # condition SQL supplémentaire
    sensible: bool = False              # données RGPD

    @property
    def incrementale(self) -> bool:
        return self.strategie == "incremental"

    @property
    def fenetre(self) -> bool:
        return self.strategie == "window"

    @property
    def complete(self) -> bool:
        return self.strategie == "full"

    @property
    def pipeline(self) -> bool:
        return self.strategie == "pipeline"


# =============================================================================
# TABLES SYNCHRONISÉES (31 tables - version HFSQL correcte)
# =============================================================================
# Ordre respectant les dépendances FK

TABLES: tuple[Table, ...] = (
    # ── INCRÉMENTALES (15 min) ───────────────────────────────────────────────
    Table(
        cible="sorties_produits",
        source="sorties_produits",
        strategie="incremental",
        intervalle_minutes=15,
        taille_lot=1000,
    ),
    Table(
        cible="entrees_produits",
        source="entrees_produits",
        strategie="incremental",
        intervalle_minutes=15,
        taille_lot=1000,
    ),
    Table(
        cible="mouchard",
        source="mouchard",
        strategie="incremental",
        intervalle_minutes=15,
        taille_lot=500,  # 54 colonnes = lots plus petits
    ),
    Table(
        cible="factures_chifa_produits",
        source="factures_chifa_produits",
        strategie="incremental",
        intervalle_minutes=15,
        taille_lot=1000,
    ),
    Table(
        cible="ordonnancier",
        source="ordonnancier",
        strategie="incremental",
        intervalle_minutes=15,
        taille_lot=500,
        sensible=True,  # Données RGPD++
    ),
    Table(
        cible="commandes_fournisseurs_produits",
        source="commandes_fournisseurs_produits",
        strategie="incremental",
        intervalle_minutes=30,
        taille_lot=1000,
    ),
    Table(
        cible="echanges_sorties_produits",
        source="echanges_sorties_produits",
        strategie="incremental",
        intervalle_minutes=30,
        taille_lot=1000,
    ),

    # ── FENÊTRE GLISSANTE (30 min) ───────────────────────────────────────────
    Table(
        cible="sorties",
        source="sorties",
        strategie="window",
        intervalle_minutes=30,
        taille_lot=500,
        fenetre_jours=30,
        champ_modif="modif",
    ),
    Table(
        cible="entrees",
        source="entrees",
        strategie="window",
        intervalle_minutes=30,
        taille_lot=500,
        fenetre_jours=30,
        champ_modif="modif",
        condition_extra="ouverte = 1",
    ),
    Table(
        cible="operations",
        source="opérations",  # Nom HFSQL avec accent
        strategie="window",
        intervalle_minutes=30,
        taille_lot=500,
        fenetre_jours=30,
        champ_modif="modif",
        condition_extra="cloturé = 0",
    ),
    Table(
        cible="factures_chifa",
        source="factures_chifa",
        strategie="window",
        intervalle_minutes=30,
        taille_lot=500,
        fenetre_jours=30,
    ),
    Table(
        cible="commandes_fournisseurs",
        source="commandes_fournisseurs",
        strategie="window",
        intervalle_minutes=60,
        taille_lot=500,
        fenetre_jours=30,
    ),
    Table(
        cible="echanges",
        source="echanges",
        strategie="window",
        intervalle_minutes=60,
        taille_lot=500,
        fenetre_jours=30,
        champ_modif="modif",
    ),

    # ── FULL SYNC (4h) ───────────────────────────────────────────────────────
    Table(
        cible="nomenclature",
        source="nomenclature",
        strategie="full",
        intervalle_minutes=240,
    ),
    Table(
        cible="clients",
        source="clients",
        strategie="full",
        intervalle_minutes=240,
        sensible=True,
    ),
    Table(
        cible="fournisseurs",
        source="fournisseurs",
        strategie="full",
        intervalle_minutes=240,
    ),
    Table(
        cible="groupware",
        source="groupware",
        strategie="full",
        intervalle_minutes=240,
        taille_lot=100,
        sensible=True,  # Mots de passe
    ),
    Table(
        cible="bordereaux_chifa",
        source="bordereaux_chifa",
        strategie="full",
        intervalle_minutes=240,
    ),
    Table(
        cible="suivi_caisses",
        source="suivi_caisses",
        strategie="full",
        intervalle_minutes=240,
    ),

    # ── FULL SYNC (Nightly - 24h) ────────────────────────────────────────────
    Table(
        cible="familles",
        source="familles",
        strategie="full",
        intervalle_minutes=1440,
    ),
    Table(
        cible="formes",
        source="formes",
        strategie="full",
        intervalle_minutes=1440,
    ),
    Table(
        cible="laboratoires",
        source="laboratoires",
        strategie="full",
        intervalle_minutes=1440,
    ),
    Table(
        cible="nomenclature_chifa",
        source="nomenclature_chifa",
        strategie="full",
        intervalle_minutes=1440,
    ),
    Table(
        cible="caisses",
        source="caisses",
        strategie="full",
        intervalle_minutes=1440,
    ),
    Table(
        cible="pharmacies",
        source="pharmacies",
        strategie="full",
        intervalle_minutes=1440,
    ),
    Table(
        cible="postes",
        source="postes",
        strategie="full",
        intervalle_minutes=1440,
        taille_lot=100,
    ),
    Table(
        cible="prestations",
        source="prestations",
        strategie="full",
        intervalle_minutes=1440,
    ),
    Table(
        cible="comptes_bancaires",
        source="comptes_bancaires",
        strategie="full",
        intervalle_minutes=1440,
    ),
    Table(
        cible="depenses",
        source="dépenses",  # Nom HFSQL avec accent
        strategie="full",
        intervalle_minutes=1440,
    ),
    Table(
        cible="motif_instance",
        source="motif_instance",
        strategie="full",
        intervalle_minutes=1440,
    ),

    # ── PIPELINE DÉDIÉ (15 min) ──────────────────────────────────────────────
    Table(
        cible="instance_produits",
        source="instance_produits",
        strategie="pipeline",
        intervalle_minutes=15,
        sensible=True,
    ),
)


def par_nom(cible: str) -> Table:
    """Trouve une table par son nom cible."""
    for t in TABLES:
        if t.cible == cible:
            return t
    raise KeyError(f"table inconnue : {cible}")


def par_strategie(strategie: Strategie) -> tuple[Table, ...]:
    """Retourne toutes les tables d'une stratégie donnée."""
    return tuple(t for t in TABLES if t.strategie == strategie)


def par_intervalle(minutes: int) -> tuple[Table, ...]:
    """Retourne toutes les tables avec un intervalle donné."""
    return tuple(t for t in TABLES if t.intervalle_minutes == minutes)
