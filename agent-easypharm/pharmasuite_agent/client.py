"""Client HTTP de l'API PharmaSuite."""
from __future__ import annotations

import logging
import time
from typing import Any

import httpx

logger = logging.getLogger(__name__)

_TENTATIVES = 5
_ATTENTE_INITIALE = 2.0


class ErreurApi(RuntimeError):
    pass


class LotRejete(ErreurApi):
    """
    Le serveur a accepté la requête mais refusé des lignes du lot.

    Levée pour que le curseur n'avance pas : sinon les lignes refusées
    seraient sautées pour toujours, sans trace.
    """

    def __init__(self, table: str, reponse: dict):
        self.table = table
        self.rejets = reponse.get("rejected") or []
        exemples = "; ".join(f"id={r.get('id')}: {r.get('erreur')}" for r in self.rejets[:3])
        # Le serveur nomme les colonnes en cause (texte trop long…), ce que
        # l'erreur PostgreSQL ne fait pas.
        causes = sorted({
            f"{a.get('colonne')} ({a.get('erreur')})"
            for a in (reponse.get("invalid_values") or [])[:20] if a.get("colonne")
        })
        super().__init__(
            f"{reponse.get('errors')} ligne(s) refusée(s) par le serveur sur {table}"
            + (f" — colonnes en cause : {'; '.join(causes[:3])}" if causes else "")
            + (f" — {exemples}" if exemples else "")
        )


class ClientPharmaSuite:
    """
    Enveloppe les endpoints dont l'agent a besoin.

    Le jeton JWT expire (60 min par défaut) : un 401 déclenche une
    reconnexion et un seul réessai, pour ne pas boucler sur de vrais
    identifiants invalides.
    """

    def __init__(self, base_url: str, username: str, password: str, timeout: int = 60):
        self._base = base_url.rstrip("/")
        self._username = username
        self._password = password
        self._http = httpx.Client(timeout=timeout)
        self._jeton: str | None = None
        # Un avertissement par table et par colonne, pas un par lot.
        self._colonnes_signalees: set[tuple[str, str]] = set()

    def fermer(self) -> None:
        self._http.close()

    # ── Authentification ─────────────────────────────────────────────────────

    def _connecter(self) -> None:
        reponse = self._http.post(
            f"{self._base}/auth/login",
            data={"username": self._username, "password": self._password},
        )
        if reponse.status_code != 200:
            raise ErreurApi(
                f"Authentification refusée ({reponse.status_code}). "
                "Vérifier api.username / api.password dans config.toml."
            )
        self._jeton = reponse.json()["access_token"]
        logger.info("Authentifié auprès de %s", self._base)

    def _entetes(self) -> dict[str, str]:
        if self._jeton is None:
            self._connecter()
        return {"Authorization": f"Bearer {self._jeton}"}

    # ── Appels ───────────────────────────────────────────────────────────────

    def _appeler(self, methode: str, chemin: str, **kwargs) -> Any:
        url = f"{self._base}{chemin}"
        attente = _ATTENTE_INITIALE
        derniere: Exception | None = None

        for tentative in range(1, _TENTATIVES + 1):
            try:
                reponse = self._http.request(methode, url, headers=self._entetes(), **kwargs)

                if reponse.status_code == 401:
                    # Jeton expiré : on se reconnecte et on retente une fois.
                    logger.info("Jeton expiré, reconnexion")
                    self._jeton = None
                    reponse = self._http.request(
                        methode, url, headers=self._entetes(), **kwargs
                    )

                if reponse.status_code >= 500:
                    raise httpx.HTTPError(f"HTTP {reponse.status_code}")
                if reponse.status_code >= 400:
                    # 4xx : une erreur de notre côté, réessayer n'aide pas.
                    raise ErreurApi(f"HTTP {reponse.status_code} sur {chemin} : {reponse.text[:200]}")

                return reponse.json()

            except (httpx.HTTPError, httpx.TransportError) as erreur:
                derniere = erreur
                if tentative == _TENTATIVES:
                    break
                logger.warning(
                    "%s %s a échoué (%s), nouvelle tentative dans %.0fs [%d/%d]",
                    methode, chemin, erreur, attente, tentative, _TENTATIVES,
                )
                time.sleep(attente)
                attente *= 2

        raise ErreurApi(f"{methode} {chemin} a échoué après {_TENTATIVES} tentatives : {derniere}")

    # ── Endpoints ────────────────────────────────────────────────────────────

    def statut(self, table: str) -> int:
        """Dernier id synchronisé pour cette table, 0 si jamais synchronisée."""
        return int(self._appeler("GET", f"/sync/status/{table}")["last_id"])

    def _controler(self, table: str, reponse: dict) -> dict:
        """Lit le bilan du lot : `errors > 0` arrive avec un HTTP 200."""
        for colonne in reponse.get("ignored_columns") or []:
            if (table, colonne) not in self._colonnes_signalees:
                self._colonnes_signalees.add((table, colonne))
                logger.warning("[%s] colonne HFSQL sans équivalent PostgreSQL, non importée : %s",
                               table, colonne)
        for anomalie in (reponse.get("invalid_values") or [])[:5]:
            logger.warning("[%s] valeur invalide écrite à NULL : %s", table, anomalie)
        if reponse.get("errors"):
            raise LotRejete(table, reponse)
        return reponse

    def pousser(self, table: str, enregistrements: list[dict]) -> dict:
        """Envoie un lot d'enregistrements."""
        reponse = self._appeler("POST", f"/sync/{table}", json={"records": enregistrements})
        return self._controler(table, reponse)

    def schema(self) -> list[dict]:
        """Colonnes et nombre de lignes de chaque table miroir côté serveur."""
        return self._appeler("GET", "/sync/schema")

    def maj_statut(self, table: str, last_id: int, count: int) -> None:
        """Met à jour le curseur de synchronisation."""
        self._appeler(
            "POST", f"/sync/status/{table}", json={"last_id": last_id, "count": count}
        )

    # ── Endpoints spéciaux ───────────────────────────────────────────────────

    def pousser_instance_produits(self, enregistrements: list[dict]) -> dict:
        """Endpoint dédié pour instance_produits (gère le pipeline)."""
        reponse = self._appeler(
            "POST", "/sync/instance_produits/batch",
            json={"records": enregistrements}
        )
        return self._controler("instance_produits", reponse)

    def pousser_instance_produits_trt(self, enregistrements: list[dict]) -> dict:
        """Endpoint pour les instances archivées."""
        reponse = self._appeler(
            "POST", "/sync/instance_produits_trt",
            json={"records": enregistrements}
        )
        return self._controler("instance_produits_trt", reponse)
