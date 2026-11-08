"""
Lecture d'EASYPHARM par le driver ODBC HyperFileSQL.

`pyodbc` n'est pas importé au chargement du module : les tests, et toute
machine qui n'est pas le poste Windows de l'officine, doivent pouvoir importer
l'agent sans driver installé.
"""
from __future__ import annotations

from datetime import datetime, timedelta
from typing import Any, Iterator, Protocol, Sequence

from .serialisation import ligne_json, nom_colonne


class Source(Protocol):
    """Ce dont le moteur de synchronisation a besoin. Permet de le tester."""

    def lire(self, table: str, cle: str, depuis: int, taille: int) -> Iterator[dict[str, Any]]:
        """Lecture incrémentale (depuis > 0) ou complète (depuis < 0)."""
        ...

    def lire_fenetre(
        self,
        table: str,
        cle: str,
        taille: int,
        fenetre_jours: int,
        champ_modif: str | None = None,
        condition_extra: str | None = None,
    ) -> Iterator[dict[str, Any]]:
        """Lecture par fenêtre glissante."""
        ...

    def max_cle(self, table: str, cle: str) -> int:
        """Retourne la valeur maximale de la clé."""
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

    def lire_fenetre(
        self,
        table: str,
        cle: str,
        taille: int,
        fenetre_jours: int,
        champ_modif: str | None = None,
        condition_extra: str | None = None,
    ) -> Iterator[dict[str, Any]]:
        """
        Lecture par fenêtre glissante.

        Récupère les enregistrements:
        - Avec date >= (aujourd'hui - fenetre_jours)
        - OU avec champ_modif > 0 (si spécifié)
        - OU vérifiant condition_extra (si spécifiée)
        """
        curseur = self._connexion().cursor()
        try:
            # Date au format HFSQL (YYYYMMDD)
            date_limite = (datetime.now() - timedelta(days=fenetre_jours)).strftime('%Y%m%d')

            conditions = [f"date >= '{date_limite}'"]

            if champ_modif:
                conditions.append(f"{champ_modif} > 0")

            if condition_extra:
                conditions.append(condition_extra)

            where_clause = " OR ".join(conditions)
            requete = f"SELECT * FROM {table} WHERE {where_clause} ORDER BY {cle}"

            curseur.execute(requete)
            colonnes: Sequence[str] = [c[0] for c in curseur.description]
            while True:
                lignes = curseur.fetchmany(taille)
                if not lignes:
                    return
                for ligne in lignes:
                    yield ligne_json(colonnes, ligne)
        finally:
            curseur.close()

    def lire_tout(self, table: str, cle: str, taille: int) -> Iterator[dict[str, Any]]:
        """Alias pour lecture complète."""
        yield from self.lire(table, cle, -1, taille)

    def colonnes(self, table: str) -> list[str]:
        """Colonnes de `table`, normalisées comme dans les lignes envoyées."""
        curseur = self._connexion().cursor()
        try:
            curseur.execute(f"SELECT TOP 1 * FROM {table}")
            return [nom_colonne(c[0]) for c in curseur.description]
        finally:
            curseur.close()

    def lister_tables(self) -> list[str]:
        """Tables exposées par le DSN, d'après le catalogue ODBC."""
        curseur = self._connexion().cursor()
        try:
            return sorted(t.table_name for t in curseur.tables(tableType="TABLE"))
        finally:
            curseur.close()

    def compter(self, table: str) -> int:
        """Retourne le nombre total d'enregistrements."""
        curseur = self._connexion().cursor()
        try:
            curseur.execute(f"SELECT COUNT(*) FROM {table}")
            return curseur.fetchone()[0] or 0
        finally:
            curseur.close()
