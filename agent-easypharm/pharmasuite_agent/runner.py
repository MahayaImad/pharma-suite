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
- window : rattrapage id > last_id, puis fenêtre glissante (date + modif)
- full : relecture complète périodique
- pipeline : spécial instance_produits (avec archive)
"""
from __future__ import annotations

import json
import logging
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable, Iterable, Iterator

from .client import ClientPharmaSuite, ErreurApi, LotRejete
from .source import Source
from .tables import TABLES, Table

logger = logging.getLogger(__name__)


@dataclass
class Bilan:
    tables_ok: int = 0
    tables_en_erreur: int = 0
    lignes: int = 0
    erreurs: list[str] = field(default_factory=list)
    tables_absentes: list[str] = field(default_factory=list)

    def resume(self) -> str:
        base = f"{self.lignes} ligne(s) sur {self.tables_ok} table(s)"
        if self.tables_absentes:
            base += f", {len(self.tables_absentes)} table(s) optionnelle(s) absente(s)"
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

def _cle_entiere(enregistrement: dict, cle: str) -> int | None:
    valeur = enregistrement.get(cle)
    if valeur is None:
        return None
    try:
        return int(float(valeur)) if isinstance(valeur, str) else int(valeur)
    except (TypeError, ValueError):
        return None


def _pousser_par_lots(
    lignes: Iterable[dict],
    taille_lot: int,
    envoyer: Callable[[list[dict]], Any],
    cle: str = "id",
    avancer: Callable[[int, int], None] | None = None,
) -> int:
    """
    Envoie `lignes` par lots. Si `avancer` est fourni, il est appelé avec
    (plus grand id du lot, taille du lot) **après** chaque lot accepté : c'est
    ce qui rend la reprise sûre. Un lot refusé lève avant d'avancer.
    """
    envoyees = 0
    lot: list[dict] = []
    plus_grand = 0

    def vider() -> None:
        nonlocal lot, envoyees
        if not lot:
            return
        envoyer(lot)
        envoyees += len(lot)
        if avancer is not None and plus_grand > 0:
            avancer(plus_grand, len(lot))
        lot = []

    for enregistrement in lignes:
        valeur = _cle_entiere(enregistrement, cle)
        if valeur is not None:
            plus_grand = max(plus_grand, valeur)
        lot.append(enregistrement)
        if len(lot) >= taille_lot:
            vider()
    vider()
    return envoyees


def _renommer(table: Table, lignes: Iterable[dict]) -> Iterator[dict]:
    """Applique `table.renommer` à chaque ligne lue."""
    if not table.renommer:
        yield from lignes
        return
    correspondance = dict(table.renommer)
    for ligne in lignes:
        yield {correspondance.get(k, k): v for k, v in ligne.items()}


def _rattraper(table: Table, source: Source, client: ClientPharmaSuite) -> tuple[int, int]:
    """
    Lit tout ce qui dépasse le curseur serveur et avance ce curseur lot par lot.
    Rend (curseur de départ, lignes envoyées).
    """
    depuis = max(client.statut(table.cible), 0)
    logger.info("[%s] rattrapage depuis id > %d", table.cible, depuis)
    envoyees = _pousser_par_lots(
        _renommer(table, source.lire(table.source, table.cle, depuis, table.taille_lot)),
        table.taille_lot,
        lambda lot: client.pousser(table.cible, lot),
        table.cle,
        lambda dernier, n: client.maj_statut(table.cible, dernier, n),
    )
    return depuis, envoyees


def _sync_incremental(table: Table, source: Source, client: ClientPharmaSuite) -> int:
    """Synchronisation incrémentale (id > last_id)."""
    _, envoyees = _rattraper(table, source, client)
    logger.info("[%s] %d ligne(s) synchronisée(s)", table.cible, envoyees)
    return envoyees


def _sync_window(table: Table, source: Source, client: ClientPharmaSuite) -> int:
    """
    Fenêtre glissante, en deux temps :

    1. rattrapage ``id > last_id`` — au premier lancement, c'est **tout
       l'historique** ; ensuite, les seules nouvelles lignes ;
    2. relecture de la fenêtre (date récente, ``modif > 0``,
       ``condition_extra``) pour capter les en-têtes modifiés sur place.
       Les lignes déjà envoyées à l'étape 1 sont sautées.
    """
    depuis, envoyees = _rattraper(table, source, client)

    def deja_connues() -> Iterator[dict]:
        for enregistrement in _renommer(table, source.lire_fenetre(
            table.source, table.cle, table.taille_lot, table.fenetre_jours,
            table.champ_modif, table.condition_extra,
        )):
            valeur = _cle_entiere(enregistrement, table.cle)
            if valeur is None or valeur <= depuis:
                yield enregistrement

    relues = _pousser_par_lots(
        deja_connues(), table.taille_lot,
        lambda lot: client.pousser(table.cible, lot), table.cle,
    )
    logger.info("[%s] %d nouvelle(s), %d relue(s) dans la fenêtre de %d jours",
                table.cible, envoyees, relues, table.fenetre_jours)
    return envoyees + relues


def _sync_full(table: Table, source: Source, client: ClientPharmaSuite) -> int:
    """Synchronisation complète."""
    logger.info("[%s] lecture complète", table.cible)
    envoyees = _pousser_par_lots(
        _renommer(table, source.lire(table.source, table.cle, -1, table.taille_lot)),
        table.taille_lot,
        lambda lot: client.pousser(table.cible, lot),
        table.cle,
    )
    logger.info("[%s] %d ligne(s) synchronisée(s) (full)", table.cible, envoyees)
    return envoyees


def _sync_pipeline(table: Table, source: Source, client: ClientPharmaSuite) -> int:
    """
    Pipeline spécial pour instance_produits.

    Cette table est la SEULE où des enregistrements sont SUPPRIMÉS
    (déplacés vers instance_produits_trt après vente). Chaque étape a son
    endpoint dédié :

    1. instances actives → ``/sync/instance_produits/batch`` (archive=FALSE) ;
    2. instances traitées → ``/sync/instance_produits_trt`` (archive=TRUE).

    La route générique ne doit pas servir ici : elle ne remet pas
    ``archive`` à FALSE pour une instance réactivée.
    """
    logger.info("[%s] pipeline instance_produits", table.cible)

    actives = _pousser_par_lots(
        source.lire(table.source, table.cle, -1, table.taille_lot),
        table.taille_lot, client.pousser_instance_produits, table.cle,
    )
    logger.info("[instance_produits] %d instance(s) active(s)", actives)

    try:
        lignes_trt = source.lire("instance_produits_trt", table.cle, -1, table.taille_lot)
        traitees = _pousser_par_lots(
            lignes_trt, table.taille_lot, client.pousser_instance_produits_trt, table.cle,
        )
    except LotRejete:
        raise
    except Exception as erreur:
        logger.warning("[instance_produits_trt] non disponible : %s", erreur)
        traitees = 0
    logger.info("[instance_produits_trt] %d instance(s) traitée(s)", traitees)

    return actives + traitees


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
            if table.optionnelle and not isinstance(erreur, (LotRejete, ErreurApi)):
                # Erreur de lecture HFSQL sur une table non attestée : sans
                # doute absente. On le dit, sans faire échouer la passe.
                logger.warning("[%s] table optionnelle illisible côté HFSQL : %s",
                               table.cible, erreur)
                bilan.tables_absentes.append(table.cible)
                etat.marquer_synchronise(table)
                continue
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
