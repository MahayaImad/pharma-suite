"""
Lecture d'EASYPHARM par le connecteur **OLE DB HFSQL** (`PCSOFT.HFSQL`).

Pas d'ODBC : les fichiers EASYPHARM sont protégés par mot de passe, et seul le
provider OLE DB permet de le passer pour tous les fichiers d'un coup, via
`Extended Properties="Password=*:<mdp>;"` (`*` = toutes les tables).

L'accès passe par ADO, piloté directement par COM (`ado.py`, `win32com` de
`pywin32`) — pas par `adodbapi`, qui échoue sur des propriétés ADO que le
provider HFSQL n'expose pas. `win32com` n'est pas importé au chargement du
module : les tests, et toute
machine qui n'est pas le poste Windows de l'officine, doivent pouvoir importer
l'agent sans provider installé.
"""
from __future__ import annotations

import re
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
        champ_date: str = "date",
    ) -> Iterator[dict[str, Any]]:
        """Lecture par fenêtre glissante."""
        ...

    def max_cle(self, table: str, cle: str) -> int:
        """Retourne la valeur maximale de la clé."""
        ...


class ErreurSource(RuntimeError):
    """Échec côté HFSQL, avec un message lisible et sans mot de passe."""


# Codes d'erreur HFSQL fréquents à la connexion, avec la piste à suivre.
_PISTES = {
    "70207": (
        "deux fichiers de la base portent le même nom logique. Le provider OLE DB "
        "déclare automatiquement chaque fichier de la base : si deux d'entre eux "
        "(ou un fichier et un sous-dossier) aboutissent au même nom — casse ou "
        "accent près —, la connexion échoue. Vérifier dans le Centre de Contrôle "
        "HFSQL les fichiers dont le nom ressemble à celui cité, ou restreindre la "
        "description via `proprietes_extra` (config.toml)."
    ),
}


def _message_hfsql(erreur: Exception, secrets: list[str]) -> str:
    """
    Extrait d'une `com_error` ADO le texte utile de HFSQL (« Que s'est-il
    passé ? », code, fichier) et retire tout secret — l'erreur brute recopie
    la chaîne de connexion, mot de passe compris.
    """
    brut = str(erreur)
    for secret in secrets:
        if secret:
            brut = brut.replace(secret, "****")
    brut = brut.replace("\\r\\n", "\n").replace("\r\n", "\n")

    morceaux = []
    # Tout le paragraphe d'explication, jusqu'à la ligne vide ou au code :
    # la première ligne seule ne dit souvent que « Erreur renvoyée par le
    # serveur », la cause est sur les suivantes.
    quoi = re.search(r"Que s'est-il passé \?\s*\n?(.+?)(?:\n\s*\n|\n?Code erreur|$)", brut, re.S)
    if quoi:
        morceaux.append(" ".join(quoi.group(1).split()))
    code = re.search(r"Code erreur\s*:\s*(\d+)", brut)
    if code:
        morceaux.append(f"code HFSQL {code.group(1)}")
    module = re.search(r"Version=<([\d.]+)>", brut)
    if module:
        morceaux.append(f"provider {module.group(1)}")
    if not morceaux:
        return brut[:500]
    message = " — ".join(morceaux)
    if code and code.group(1) in _PISTES:
        message += f"\n    Piste : {_PISTES[code.group(1)]}"
    return message


def _echapper(valeur: str) -> str:
    """Une valeur contenant `;` ou `"` casserait la chaîne de connexion."""
    if any(c in valeur for c in ';"'):
        raise ValueError("les caractères ; et \" ne sont pas acceptés dans la configuration HFSQL")
    return valeur


class SourceHFSQL:
    """Source réelle : serveur HFSQL Client/Serveur, via le provider OLE DB."""

    def __init__(
        self,
        server: str,
        database: str,
        port: int = 4900,
        user: str = "admin",
        password: str = "",
        fetch_size: int = 500,
        proprietes_extra: str = "",
    ):
        self._server = server
        self._port = port
        self._database = database
        self._user = user
        self._password = password
        self._fetch_size = fetch_size
        self._proprietes_extra = proprietes_extra.strip()
        self._cnx = None

    @classmethod
    def depuis_config(cls, config) -> "SourceHFSQL":
        """Construit la source depuis la section [source] de config.toml."""
        return cls(
            server=config.server, port=config.port, database=config.database,
            user=config.user, password=config.password, fetch_size=config.fetch_size,
            proprietes_extra=config.proprietes_extra,
        )

    @property
    def description(self) -> str:
        """Pour les messages : jamais le mot de passe."""
        return f"OLE DB {self._server}:{self._port}/{self._database}"

    def _build_provider_string(self) -> str:
        """
        Chaîne Provider OLE DB.

        `Password=` de premier niveau est vide : c'est le mot de passe du
        compte. Le mot de passe des **fichiers** — exigé pour lire chaque
        table — passe dans `Extended Properties`, `*` valant pour toutes.
        """
        return (
            'Provider=PCSOFT.HFSQL;'
            f' Data Source={_echapper(self._server)}:{int(self._port)};'
            f' Initial Catalog={_echapper(self._database)};'
            f' User ID={_echapper(self._user)};'
            ' Password=;'
            f' Extended Properties="Password=*:{_echapper(self._password)};'
            f'{self._extra()}"'
        )

    def _extra(self) -> str:
        """Propriétés étendues supplémentaires, ajoutées telles quelles."""
        if not self._proprietes_extra:
            return ""
        if '"' in self._proprietes_extra:
            raise ValueError('le caractère " n\'est pas accepté dans proprietes_extra')
        extra = self._proprietes_extra
        return extra if extra.endswith(";") else extra + ";"

    def _connexion(self):
        if self._cnx is None:
            from .ado import connecter

            try:
                self._cnx = connecter(self._build_provider_string())
            except Exception as erreur:
                raise ErreurSource(_message_hfsql(erreur, [self._password])) from None
        return self._cnx

    @staticmethod
    def _executer(curseur, requete: str) -> None:
        """Exécute une requête ; une erreur HFSQL ressort en clair, avec la requête."""
        try:
            curseur.execute(requete)
        except Exception as erreur:
            raise ErreurSource(f"{_message_hfsql(erreur, [])} — requête : {requete[:200]}") from None

    def fermer(self) -> None:
        if self._cnx is not None:
            self._cnx.close()
            self._cnx = None

    def max_cle(self, table: str, cle: str) -> int:
        curseur = self._connexion().cursor()
        try:
            self._executer(curseur, f"SELECT MAX({cle}) FROM {table}")
            valeur = curseur.fetchone()[0]
            return int(valeur) if valeur is not None else 0
        finally:
            curseur.close()

    def lire(self, table: str, cle: str, depuis: int, taille: int) -> Iterator[dict[str, Any]]:
        """
        Rend les lignes de `table` dont `cle` dépasse `depuis`, par paquets.

        `depuis < 0` signifie « tout relire » (stratégie full).

        Le nom de table et celui de la colonne viennent de `tables.py`, jamais
        d'une entrée utilisateur : ils sont interpolés parce qu'aucun provider
        n'accepte d'identifiant paramétré. La borne est forcée en `int` avant
        d'être écrite dans la requête : rien d'autre qu'un entier ne peut y
        entrer, et on ne dépend pas du support des paramètres ADO par le
        provider HFSQL.
        """
        curseur = self._connexion().cursor()
        try:
            if depuis < 0:
                self._executer(curseur, f"SELECT * FROM {table} ORDER BY {cle}")
            else:
                self._executer(curseur, 
                    f"SELECT * FROM {table} WHERE {cle} > {int(depuis)} ORDER BY {cle}"
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
        champ_date: str = "date",
    ) -> Iterator[dict[str, Any]]:
        """
        Lecture par fenêtre glissante.

        Récupère les enregistrements:
        - Avec champ_date >= (aujourd'hui - fenetre_jours)
        - OU avec champ_modif > 0 (si spécifié)
        - OU vérifiant condition_extra (si spécifiée)
        """
        curseur = self._connexion().cursor()
        try:
            # Date au format HFSQL (YYYYMMDD)
            date_limite = (datetime.now() - timedelta(days=fenetre_jours)).strftime('%Y%m%d')

            conditions = [f"{champ_date} >= '{date_limite}'"]

            if champ_modif:
                conditions.append(f"{champ_modif} > 0")

            if condition_extra:
                conditions.append(condition_extra)

            where_clause = " OR ".join(conditions)
            requete = f"SELECT * FROM {table} WHERE {where_clause} ORDER BY {cle}"

            self._executer(curseur, requete)
            colonnes: Sequence[str] = [c[0] for c in curseur.description]
            while True:
                lignes = curseur.fetchmany(taille)
                if not lignes:
                    return
                for ligne in lignes:
                    yield ligne_json(colonnes, ligne)
        finally:
            curseur.close()

    def _lire_requete(self, requete: str, taille: int) -> Iterator[dict[str, Any]]:
        curseur = self._connexion().cursor()
        try:
            self._executer(curseur, requete)
            colonnes: Sequence[str] = [c[0] for c in curseur.description]
            while True:
                lignes = curseur.fetchmany(taille)
                if not lignes:
                    return
                for ligne in lignes:
                    yield ligne_json(colonnes, ligne)
        finally:
            curseur.close()

    def lire_non_nuls(self, table: str, cle: str, colonne: str, taille: int) -> Iterator[dict[str, Any]]:
        """Lignes dont `colonne` n'est pas nulle (lots ayant du stock, positif ou négatif)."""
        return self._lire_requete(
            f"SELECT * FROM {table} WHERE {colonne} <> 0 ORDER BY {cle}", taille)

    def lire_ids(self, table: str, cle: str, ids: Sequence[int], taille: int) -> Iterator[dict[str, Any]]:
        """Lignes d'identifiants donnés, par paquets pour garder des requêtes courtes."""
        ids = sorted(int(i) for i in ids)   # entiers uniquement : rien d'autre n'entre dans la requête
        for debut in range(0, len(ids), 200):
            liste = ", ".join(str(i) for i in ids[debut:debut + 200])
            yield from self._lire_requete(
                f"SELECT * FROM {table} WHERE {cle} IN ({liste}) ORDER BY {cle}", taille)

    def lire_tout(self, table: str, cle: str, taille: int) -> Iterator[dict[str, Any]]:
        """Alias pour lecture complète."""
        yield from self.lire(table, cle, -1, taille)

    def colonnes(self, table: str) -> list[str]:
        """Colonnes de `table`, normalisées comme dans les lignes envoyées."""
        curseur = self._connexion().cursor()
        try:
            self._executer(curseur, f"SELECT TOP 1 * FROM {table}")
            return [nom_colonne(c[0]) for c in curseur.description]
        finally:
            curseur.close()

    def lister_tables(self) -> list[str]:
        """Tables de l'analyse, d'après le catalogue OLE DB (schéma ADO)."""
        return sorted(self._connexion().get_table_names())

    def compter(self, table: str) -> int:
        """Retourne le nombre total d'enregistrements."""
        curseur = self._connexion().cursor()
        try:
            self._executer(curseur, f"SELECT COUNT(*) FROM {table}")
            return curseur.fetchone()[0] or 0
        finally:
            curseur.close()
