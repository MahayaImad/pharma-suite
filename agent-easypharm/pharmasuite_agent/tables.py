"""
Tables synchronisées depuis EASYPHARM.

L'ordre compte : une table n'est poussée qu'après celles dont elle dépend,
sinon les clés étrangères côté PostgreSQL peuvent pointer dans le vide.

Quatre stratégies :

- ``incremental`` : la table ne fait que grossir (ventes, achats, mouvements).
  On ne relit que les lignes dont l'id dépasse le dernier synchronisé.
- ``window`` : en-têtes modifiés sur place (sorties ouvertes, etc.). Chaque
  passe rattrape d'abord tout ce qui dépasse le curseur (``id > last_id``,
  donc **tout l'historique** au premier lancement), puis relit la fenêtre
  glissante (date récente, ``modif > 0``, ``condition_extra``) pour capter
  les modifications.
- ``full`` : la table est modifiée sur place sans que l'id change (stock d'un
  produit, solde d'un client). L'incrémental raterait ces mises à jour, donc
  on la relit en entier — moins souvent, via ``full_resync_every``.
- ``pipeline`` : cas spécial instance_produits (seule table avec DELETE).
- ``lots`` : lignes de stock (entrees_produits). L'id ne change pas mais la
  quantité restante baisse à chaque vente. Chaque passe lit les nouveaux
  lots, puis tous les lots dont le stock n'est pas nul, puis ceux qui
  avaient du stock à la passe précédente et n'en ont plus — sans quoi un lot
  épuisé resterait « en stock » côté PostgreSQL.

Le nom cible est celui attendu par ``POST /sync/{table}`` ; il ne coïncide pas
toujours avec le nom HyperFileSQL d'origine.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Literal

Strategie = Literal["incremental", "window", "full", "pipeline", "lots"]


@dataclass(frozen=True)
class Table:
    cible: str                          # nom attendu par l'API PharmaSuite
    source: str                         # nom du fichier HyperFileSQL
    strategie: Strategie
    cle: str = "id"                     # colonne d'incrément
    intervalle_minutes: int = 60        # fréquence de sync
    taille_lot: int = 500               # batch size
    fenetre_jours: int = 30             # pour stratégie window
    champ_date: str = "date"            # colonne de date de la fenêtre glissante
    champ_modif: str | None = None      # champ indiquant une modification
    condition_extra: str | None = None  # condition SQL supplémentaire
    sensible: bool = False              # données RGPD
    # Table dont l'existence côté HFSQL n'est pas attestée : un échec de
    # lecture est un avertissement, pas une erreur de passe. Aucune ne l'est
    # aujourd'hui — les 39 noms sont vérifiés sur le listing du 2026-11-09.
    optionnelle: bool = False
    # Colonnes nommées autrement côté PostgreSQL : {nom HFSQL normalisé: nom PG}.
    renommer: tuple[tuple[str, str], ...] = ()
    # Stratégie « lots » : colonne de quantité restante, modifiée sur place.
    champ_stock: str | None = None

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

    @property
    def lots(self) -> bool:
        return self.strategie == "lots"


# =============================================================================
# TABLES SYNCHRONISÉES — les 39 tables miroir de SYNC_REGISTRY (backend)
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
        source="entrées_produits",  # Nom HFSQL avec accent
        # Pas « incremental » : chaque vente décrémente `stock` sur la ligne
        # du lot, sans changer son id. Voir la stratégie « lots ».
        strategie="lots",
        champ_stock="stock",
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
        source="entrées",  # Nom HFSQL avec accent
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
        champ_date="date_fact",   # ce fichier n'a pas de rubrique « date »
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
        # HFSQL nomme la colonne comme la table ; PostgreSQL l'appelle motif.
        renommer=(("motif_instance", "motif"),),
        strategie="full",
        intervalle_minutes=1440,
    ),

    # ── COMPLÉMENTS — noms attestés par le listing du dossier HFSQL ─────────
    # Lignes de détail en insertion pure (docs/02-sync-contrat.md §2.10).
    Table(
        cible="chifa_rejet_partiel",
        source="chifa_rejet_partiel",
        strategie="incremental",
        intervalle_minutes=60,
    ),
    Table(
        cible="mouchard_details",
        source="mouchard_details",
        strategie="incremental",
        intervalle_minutes=60,
        taille_lot=1000,
    ),
    Table(
        cible="reg_client_association",
        source="reg_client_association",
        strategie="incremental",
        intervalle_minutes=60,
    ),
    Table(
        cible="reg_fourn_association",
        source="reg_fourn_association",
        strategie="incremental",
        intervalle_minutes=60,
    ),
    Table(
        cible="pharmnos_factures",
        source="pharmnos_factures",
        strategie="full",
        intervalle_minutes=240,
    ),
    # Signalées vides par docs/SYNC_MAPPING.md §5, mais le listing du
    # 2026-11-09 montre inventaires_produits à 15 Mo : elles sont alimentées.
    Table(
        cible="caisses_regies",
        source="caisses_régies",  # Nom HFSQL avec accent
        strategie="full",
        intervalle_minutes=1440,
    ),
    Table(
        cible="inventaires",
        source="inventaires",
        strategie="full",
        intervalle_minutes=1440,
    ),
    Table(
        cible="inventaires_produits",
        source="inventaires_produits",
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
