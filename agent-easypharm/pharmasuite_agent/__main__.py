"""
Point d'entrée de l'agent.

    python -m pharmasuite_agent --config config.toml
    python -m pharmasuite_agent --config config.toml --une-passe
    python -m pharmasuite_agent --config config.toml --table sorties
    python -m pharmasuite_agent --config config.toml --tester
    python -m pharmasuite_agent --config config.toml --lister
    python -m pharmasuite_agent --config config.toml --verifier
"""
from __future__ import annotations

import argparse
import logging
import sys
import time
from logging.handlers import RotatingFileHandler

from .client import ClientPharmaSuite
from .config import Config
from .runner import Etat, passe, synchroniser_une_table
from .verification import afficher, verifier
from .source import SourceHFSQL
from .tables import TABLES, par_nom

logger = logging.getLogger("pharmasuite_agent")


def _installer_logs(fichier: str) -> None:
    format_ = "%(asctime)s | %(levelname)-7s | %(name)s | %(message)s"
    # Sous pythonw.exe (tâche planifiée sans fenêtre), il n'y a pas de
    # console : sys.stdout vaut None et seul le fichier journal sert.
    handlers: list[logging.Handler] = []
    if sys.stdout is not None:
        handlers.append(logging.StreamHandler(sys.stdout))
    try:
        handlers.append(RotatingFileHandler(fichier, maxBytes=5_000_000, backupCount=5, encoding="utf-8"))
    except OSError as erreur:
        print(f"Journal fichier indisponible ({erreur}), sortie console seule.")
    logging.basicConfig(level=logging.INFO, format=format_, handlers=handlers)
    # Une ligne par requête HTTP noierait le journal pendant le premier
    # chargement (des milliers de lots) ; les échecs restent journalisés
    # par le client.
    logging.getLogger("httpx").setLevel(logging.WARNING)
    logging.getLogger("httpcore").setLevel(logging.WARNING)


def _tester(config: Config) -> int:
    """Vérifie séparément les deux extrémités, pour situer une panne."""
    ok = True

    source = SourceHFSQL.depuis_config(config.source)
    try:
        maximum = source.max_cle("sorties", "id")
        print(f"  EASYPHARM ({source.description}) : OK — sorties.id max = {maximum}")
    except Exception as erreur:
        print(f"  EASYPHARM ({source.description}) : ECHEC — {erreur}")
        ok = False
    finally:
        source.fermer()

    client = ClientPharmaSuite(config.api.base_url, config.api.username,
                               config.api.password, config.api.timeout_seconds)
    try:
        dernier = client.statut("sorties")
        print(f"  PharmaSuite ({config.api.base_url}) : OK — sorties last_id = {dernier}")
    except Exception as erreur:
        print(f"  PharmaSuite ({config.api.base_url}) : ECHEC — {erreur}")
        if "10061" in str(erreur) or "refused" in str(erreur).lower():
            print("    Piste : rien n'écoute à cette adresse. L'API est-elle démarrée "
                  "(cd docker && docker compose up -d api) et le port ouvert dans le "
                  "pare-feu du serveur ? Tester : curl http://<serveur>:8000/health")
        ok = False
    finally:
        client.fermer()

    return 0 if ok else 1


def _lister() -> int:
    """Affiche les tables configurées."""
    print(f"\nTables configurées ({len(TABLES)} tables):\n")
    print(f"{'Table':<35} {'Stratégie':<12} {'Intervalle':<12} {'Sensible'}")
    print("-" * 70)

    for table in TABLES:
        intervalle = f"{table.intervalle_minutes} min"
        sensible = "⚠️ RGPD" if table.sensible else ""
        if table.optionnelle:
            sensible = (sensible + " (optionnelle)").strip()
        print(f"{table.cible:<35} {table.strategie:<12} {intervalle:<12} {sensible}")

    print("\nStratégies:")
    print("  incremental : id > last_id (ventes, achats)")
    print("  window      : fenêtre glissante (date + modif)")
    print("  full        : relecture complète périodique")
    print("  pipeline    : spécial instance_produits")
    return 0


def main(argv: list[str] | None = None) -> int:
    parseur = argparse.ArgumentParser(prog="pharmasuite_agent",
                                      description="Synchronise EASYPHARM vers PharmaSuite.")
    parseur.add_argument("--config", default="config.toml")
    parseur.add_argument("--une-passe", action="store_true",
                         help="une seule passe puis sortie (pour le planificateur Windows)")
    parseur.add_argument("--tester", action="store_true",
                         help="teste les deux connexions et sort")
    parseur.add_argument("--lister", action="store_true",
                         help="affiche les tables configurées")
    parseur.add_argument("--verifier", action="store_true",
                         help="compare HFSQL et PostgreSQL (tables, colonnes, volumes) et sort")
    parseur.add_argument("--table", type=str,
                         help="synchronise une table spécifique (ex: sorties)")
    args = parseur.parse_args(argv)

    if args.lister:
        return _lister()

    config = Config.charger(args.config)
    _installer_logs(config.agent.log_file)

    if args.tester:
        return _tester(config)

    if args.verifier:
        source = SourceHFSQL.depuis_config(config.source)
        client = ClientPharmaSuite(config.api.base_url, config.api.username,
                                   config.api.password, config.api.timeout_seconds)
        try:
            rapport = verifier(source, client)
        finally:
            source.fermer()
            client.fermer()
        afficher(rapport)
        return 0 if rapport.complet else 1

    source = SourceHFSQL.depuis_config(config.source)
    client = ClientPharmaSuite(config.api.base_url, config.api.username,
                               config.api.password, config.api.timeout_seconds)
    etat = Etat(config.agent.state_file)

    try:
        # Mode table unique
        if args.table:
            try:
                table = par_nom(args.table)
                logger.info("Synchronisation de la table : %s", args.table)
                lignes = synchroniser_une_table(args.table, source, client)
                logger.info("Terminé : %d ligne(s)", lignes)
                return 0
            except KeyError:
                logger.error("Table inconnue : %s", args.table)
                print(f"Table inconnue : {args.table}")
                print("Utilisez --lister pour voir les tables disponibles.")
                return 1

        # Mode passe complète
        while True:
            debut = time.monotonic()
            bilan = passe(
                source, client, etat,
                config.api.batch_size,
                config.agent.full_resync_every,
                respecter_intervalles=config.agent.respecter_intervalles,
            )
            logger.info("Passe terminée en %.1fs — %s",
                        time.monotonic() - debut, bilan.resume())

            if args.une_passe:
                return 1 if bilan.tables_en_erreur else 0

            time.sleep(config.agent.interval_seconds)
    except KeyboardInterrupt:
        logger.info("Arrêt demandé.")
        return 0
    finally:
        source.fermer()
        client.fermer()


if __name__ == "__main__":
    raise SystemExit(main())
