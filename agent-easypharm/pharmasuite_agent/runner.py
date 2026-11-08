"""
Moteur de synchronisation.

Une passe parcourt les tables dans l'ordre de `tables.py`. Pour chacune :

  1. on demande à PharmaSuite le dernier id reçu (le serveur est la référence,
     pas un fichier local — si l'agent est réinstallé, rien n'est reperdu) ;
  2. on lit EASYPHARM à partir de cet id ;
  3. on pousse par lots, et on avance le curseur **après** chaque lot accepté.

Ce dernier point est ce qui rend l'agent reprenable : une coupure réseau au
milieu d'une grosse table ne fait reperdre que le lot en cours. Les upserts
étant idempotents côté serveur, rejouer un lot est sans conséquence.

Stratégies supportées :
- incremental : id > last_id
- window : fenêtre glissante (date + modif)
- full : relecture complète périodique
- pipeline : spécial instance_produits (avec archive)
"""
from __future__ import annotations

import json
import logging
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterator, Any

from .client import ClientPharmaSuite
from .source import Source
from .tables import TABLES, Table

logger = logging.getLogger(__name__)


@dataclass
class Bilan:
    tables_ok: int = 0
    tables_en_erreur: int = 0
    lignes: int = 0
    erreurs: list[str] = field(default_factory=list)

    def resume(self) -> str:
        base = f"{self.lignes} ligne(s) sur {self.tables_ok} table(s)"
        if self.tables_en_erreur:
            return f"{base}, {self.tables_en_erreur} table(s) en erreur"
        return base


class Etat:
    """Compteur de passes et dernière sync par table."""

    def __init__(self, chemin: str | Path):
        self._chemin = Path(chemin)
        self.passes = 0
        self.derniere_sync: dict[str, float] = {}
        if self._chemin.exists():
            try:
                donnees = json.loads(self._chemin.read_text())
                self.passes = donnees.get("passes", 0)
                self.derniere_sync = donnees.get("derniere_sync", {})
            except (ValueError, OSError):
                logger.warning("État illisible, on repart de zéro : %s", self._chemin)

    def enregistrer(self) -> None:
        try:
            self._chemin.write_text(
                json.dumps({
                    "passes": self.passes,
                    "derniere_sync": self.derniere_sync,
                }),
                encoding="utf-8"
            )
        except OSError as erreur:
            logger.warning("Impossible d'écrire l'état : %s", erreur)

    def doit_synchroniser(self, table: Table) -> bool:
        """Vérifie si la table doit être synchronisée selon son intervalle."""
        import time
        derniere = self.derniere_sync.get(table.cible, 0)
        maintenant = time.time()
        return (maintenant - derniere) >= (table.intervalle_minutes * 60)

    def marquer_synchronise(self, table: Table) -> None:
        """Marque la table comme synchronisée."""
        import time
        self.derniere_sync[table.cible] = time.time()


def _doit_tout_relire(table: Table, passes: int, tous_les: int) -> bool:
    """Une table 'full' n'est relue en entier que toutes les `tous_les` passes."""
    if table.incrementale:
        return False
    if tous_les <= 1:
        return True
    return passes % tous_les == 0


# =============================================================================
# SYNCHRONISATION PAR STRATÉGIE
# =============================================================================

def _sync_incremental(
    table: Table,
    source: Source,
    client: ClientPharmaSuite,
) -> int:
    """Synchronisation incrémentale (id > last_id)."""
    depuis = client.statut(table.cible)
    logger.info("[%s] lecture incrémentale depuis id > %d", table.cible, depuis)

    envoyees = 0
    lot: list[dict] = []
    dernier_id = max(depuis, 0)

    def vider() -> None:
        nonlocal lot, envoyees, dernier_id
        if not lot:
            return
        client.pousser(table.cible, lot)
        envoyees += len(lot)
        client.maj_statut(table.cible, dernier_id, len(lot))
        lot = []

    for enregistrement in source.lire(table.source, table.cle, depuis, table.taille_lot):
        valeur_cle = enregistrement.get(table.cle)
        if valeur_cle is not None:
            try:
                dernier_id = max(dernier_id, int(valeur_cle))
            except (TypeError, ValueError):
                pass
        lot.append(enregistrement)
        if len(lot) >= table.taille_lot:
            vider()

    vider()
    logger.info("[%s] %d ligne(s) synchronisée(s)", table.cible, envoyees)
    return envoyees


def _sync_window(
    table: Table,
    source: Source,
    client: ClientPharmaSuite,
) -> int:
    """Synchronisation par fenêtre glissante."""
    logger.info(
        "[%s] lecture fenêtre glissante (%d jours, modif=%s)",
        table.cible, table.fenetre_jours, table.champ_modif
    )

    envoyees = 0
    lot: list[dict] = []
    dernier_id = 0

    def vider() -> None:
        nonlocal lot, envoyees
        if not lot:
            return
        client.pousser(table.cible, lot)
        envoyees += len(lot)
        lot = []

    for enregistrement in source.lire_fenetre(
        table.source,
        table.cle,
        table.taille_lot,
        table.fenetre_jours,
        table.champ_modif,
        table.condition_extra,
    ):
        valeur_cle = enregistrement.get(table.cle)
        if valeur_cle is not None:
            try:
                dernier_id = max(dernier_id, int(valeur_cle))
            except (TypeError, ValueError):
                pass
        lot.append(enregistrement)
        if len(lot) >= table.taille_lot:
            vider()

    vider()

    # Mettre à jour le statut avec le dernier id vu
    if envoyees > 0 and dernier_id > 0:
        client.maj_statut(table.cible, dernier_id, envoyees)

    logger.info("[%s] %d ligne(s) synchronisée(s) (fenêtre)", table.cible, envoyees)
    return envoyees


def _sync_full(
    table: Table,
    source: Source,
    client: ClientPharmaSuite,
) -> int:
    """Synchronisation complète."""
    logger.info("[%s] lecture complète", table.cible)

    envoyees = 0
    lot: list[dict] = []
    dernier_id = 0

    def vider() -> None:
        nonlocal lot, envoyees
        if not lot:
            return
        client.pousser(table.cible, lot)
        envoyees += len(lot)
        lot = []

    for enregistrement in source.lire(table.source, table.cle, -1, table.taille_lot):
        valeur_cle = enregistrement.get(table.cle)
        if valeur_cle is not None:
            try:
                dernier_id = max(dernier_id, int(valeur_cle))
            except (TypeError, ValueError):
                pass
        lot.append(enregistrement)
        if len(lot) >= table.taille_lot:
            vider()

    vider()

    # Mettre à jour le statut
    if envoyees > 0 and dernier_id > 0:
        client.maj_statut(table.cible, dernier_id, envoyees)

    logger.info("[%s] %d ligne(s) synchronisée(s) (full)", table.cible, envoyees)
    return envoyees


def _sync_pipeline(
    table: Table,
    source: Source,
    client: ClientPharmaSuite,
) -> int:
    """
    Pipeline spécial pour instance_produits.

    Cette table est la SEULE où des enregistrements sont SUPPRIMÉS
    (déplacés vers instance_produits_trt après vente).

    1. Sync des instances actives (instance_produits)
    2. Sync des instances traitées (instance_produits_trt)
    """
    logger.info("[%s] pipeline instance_produits", table.cible)

    total = 0

    # 1. Instances actives
    envoyees = 0
    lot: list[dict] = []

    def vider() -> None:
        nonlocal lot, envoyees
        if not lot:
            return
        client.pousser(table.cible, lot)
        envoyees += len(lot)
        lot = []

    for enregistrement in source.lire(table.source, table.cle, -1, table.taille_lot):
        lot.append(enregistrement)
        if len(lot) >= table.taille_lot:
            vider()

    vider()
    total += envoyees
    logger.info("[instance_produits] %d instances actives", envoyees)

    # 2. Instances traitées (archive)
    try:
        envoyees_trt = 0
        lot_trt: list[dict] = []

        def vider_trt() -> None:
            nonlocal lot_trt, envoyees_trt
            if not lot_trt:
                return
            client.pousser("instance_produits_trt", lot_trt)
            envoyees_trt += len(lot_trt)
            lot_trt = []

        for enregistrement in source.lire("instance_produits_trt", table.cle, -1, table.taille_lot):
            lot_trt.append(enregistrement)
            if len(lot_trt) >= table.taille_lot:
                vider_trt()

        vider_trt()
        total += envoyees_trt
        logger.info("[instance_produits_trt] %d instances archivées", envoyees_trt)
    except Exception as erreur:
        logger.warning("[instance_produits_trt] non disponible : %s", erreur)

    return total


def synchroniser_table(
    table: Table,
    source: Source,
    client: ClientPharmaSuite,
) -> int:
    """Synchronise une table selon sa stratégie."""
    if table.incrementale:
        return _sync_incremental(table, source, client)
    elif table.fenetre:
        return _sync_window(table, source, client)
    elif table.pipeline:
        return _sync_pipeline(table, source, client)
    else:  # full
        return _sync_full(table, source, client)


def passe(
    source: Source,
    client: ClientPharmaSuite,
    etat: Etat,
    taille_lot: int,
    full_resync_every: int,
    respecter_intervalles: bool = False,
) -> Bilan:
    """
    Une passe complète sur toutes les tables.

    L'échec d'une table n'interrompt pas les suivantes : une table verrouillée
    par EASYPHARM ne doit pas bloquer la synchronisation des ventes.

    Args:
        source: Source HFSQL
        client: Client API PharmaSuite
        etat: État local de l'agent
        taille_lot: Taille des lots (ignoré, on utilise table.taille_lot)
        full_resync_every: Nombre de passes entre full syncs (mode legacy)
        respecter_intervalles: Si True, respecte les intervalles par table
    """
    bilan = Bilan()

    for table in TABLES:
        # Vérifier si la table doit être synchronisée
        if respecter_intervalles and not etat.doit_synchroniser(table):
            continue

        try:
            bilan.lignes += synchroniser_table(table, source, client)
            bilan.tables_ok += 1
            etat.marquer_synchronise(table)
        except Exception as erreur:
            bilan.tables_en_erreur += 1
            bilan.erreurs.append(f"{table.cible}: {erreur}")
            logger.error("[%s] échec : %s", table.cible, erreur)

    etat.passes += 1
    etat.enregistrer()
    return bilan


def synchroniser_une_table(
    nom_table: str,
    source: Source,
    client: ClientPharmaSuite,
) -> int:
    """Synchronise une table spécifique par son nom."""
    from .tables import par_nom
    table = par_nom(nom_table)
    return synchroniser_table(table, source, client)
