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


class ClientPharmaSuite:
    """
    Enveloppe les trois endpoints dont l'agent a besoin.

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

    def pousser(self, table: str, enregistrements: list[dict]) -> dict:
        return self._appeler("POST", f"/sync/{table}", json={"records": enregistrements})

    def maj_statut(self, table: str, last_id: int, count: int) -> None:
        self._appeler(
            "POST", f"/sync/status/{table}", json={"last_id": last_id, "count": count}
        )
