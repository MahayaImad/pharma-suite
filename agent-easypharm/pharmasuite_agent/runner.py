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
"""
from __future__ import annotations

import json
import logging
from dataclasses import dataclass, field
from pathlib import Path

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
    """Compteur de passes, pour savoir quand refaire un full resync."""

    def __init__(self, chemin: str | Path):
        self._chemin = Path(chemin)
        self.passes = 0
        if self._chemin.exists():
            try:
                self.passes = json.loads(self._chemin.read_text()).get("passes", 0)
            except (ValueError, OSError):
                logger.warning("État illisible, on repart de zéro : %s", self._chemin)

    def enregistrer(self) -> None:
        try:
            self._chemin.write_text(json.dumps({"passes": self.passes}), encoding="utf-8")
        except OSError as erreur:
            logger.warning("Impossible d'écrire l'état : %s", erreur)


def _doit_tout_relire(table: Table, passes: int, tous_les: int) -> bool:
    """Une table 'full' n'est relue en entier que toutes les `tous_les` passes."""
    if table.incrementale:
        return False
    if tous_les <= 1:
        return True
    return passes % tous_les == 0


def synchroniser_table(
    table: Table,
    source: Source,
    client: ClientPharmaSuite,
    taille_lot: int,
    tout_relire: bool,
) -> int:
    depuis = -1 if tout_relire else client.statut(table.cible)
    mode = "complète" if tout_relire else f"depuis id>{depuis}"
    logger.info("[%s] lecture %s", table.cible, mode)

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

    for enregistrement in source.lire(table.source, table.cle, depuis, taille_lot):
        valeur_cle = enregistrement.get(table.cle)
        if valeur_cle is not None:
            try:
                dernier_id = max(dernier_id, int(valeur_cle))
            except (TypeError, ValueError):
                pass
        lot.append(enregistrement)
        if len(lot) >= taille_lot:
            vider()

    vider()
    logger.info("[%s] %d ligne(s) synchronisée(s)", table.cible, envoyees)
    return envoyees


def passe(
    source: Source,
    client: ClientPharmaSuite,
    etat: Etat,
    taille_lot: int,
    full_resync_every: int,
) -> Bilan:
    """
    Une passe complète sur toutes les tables.

    L'échec d'une table n'interrompt pas les suivantes : une table verrouillée
    par EASYPHARM ne doit pas bloquer la synchronisation des ventes.
    """
    bilan = Bilan()

    for table in TABLES:
        tout_relire = _doit_tout_relire(table, etat.passes, full_resync_every)
        try:
            bilan.lignes += synchroniser_table(
                table, source, client, taille_lot, tout_relire
            )
            bilan.tables_ok += 1
        except Exception as erreur:  # une table qui casse ne doit pas arrêter les autres
            bilan.tables_en_erreur += 1
            bilan.erreurs.append(f"{table.cible}: {erreur}")
            logger.error("[%s] échec : %s", table.cible, erreur)

    etat.passes += 1
    etat.enregistrer()
    return bilan
