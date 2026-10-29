"""
Lecture d'EASYPHARM par le driver ODBC HyperFileSQL.

`pyodbc` n'est pas importé au chargement du module : les tests, et toute
machine qui n'est pas le poste Windows de l'officine, doivent pouvoir importer
l'agent sans driver installé.
"""
from __future__ import annotations

from typing import Any, Iterator, Protocol, Sequence

from .serialisation import ligne_json


class Source(Protocol):
    """Ce dont le moteur de synchronisation a besoin. Permet de le tester."""

    def lire(self, table: str, cle: str, depuis: int, taille: int) -> Iterator[dict[str, Any]]:
        ...

    def max_cle(self, table: str, cle: str) -> int:
        ...


class SourceHFSQL:
    """Source réelle, adossée au DSN ODBC du poste Windows."""

    def __init__(self, dsn: str, user: str = "", password: str = "", fetch_size: int = 500):
        self._dsn = dsn
        self._user = user
        self._password = password
        self._fetch_size = fetch_size
        self._cnx = None

    def _connexion(self):
        if self._cnx is None:
            import pyodbc  # importé tard : absent hors du poste Windows

            morceaux = [f"DSN={self._dsn}"]
            if self._user:
                morceaux.append(f"UID={self._user}")
            if self._password:
                morceaux.append(f"PWD={self._password}")
            self._cnx = pyodbc.connect(";".join(morceaux), autocommit=True)
        return self._cnx

    def fermer(self) -> None:
        if self._cnx is not None:
            self._cnx.close()
            self._cnx = None

    def max_cle(self, table: str, cle: str) -> int:
        curseur = self._connexion().cursor()
        try:
            curseur.execute(f"SELECT MAX({cle}) FROM {table}")
            valeur = curseur.fetchone()[0]
            return int(valeur) if valeur is not None else 0
        finally:
            curseur.close()

    def lire(self, table: str, cle: str, depuis: int, taille: int) -> Iterator[dict[str, Any]]:
        """
        Rend les lignes de `table` dont `cle` dépasse `depuis`, par paquets.

        `depuis < 0` signifie « tout relire » (stratégie full).

        Le nom de table et celui de la colonne viennent de `tables.py`, jamais
        d'une entrée utilisateur : ils sont interpolés parce que l'ODBC HFSQL
        n'accepte pas d'identifiant paramétré. La borne, elle, est liée.
        """
        curseur = self._connexion().cursor()
        try:
            if depuis < 0:
                curseur.execute(f"SELECT * FROM {table} ORDER BY {cle}")
            else:
                curseur.execute(
                    f"SELECT * FROM {table} WHERE {cle} > ? ORDER BY {cle}", depuis
                )
            colonnes: Sequence[str] = [c[0] for c in curseur.description]
            while True:
                lignes = curseur.fetchmany(taille)
                if not lignes:
                    return
                for ligne in lignes:
                    yield ligne_json(colonnes, ligne)
        finally:
            curseur.close()
