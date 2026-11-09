"""
Accès ADO minimal, directement par COM (`win32com`, fourni par `pywin32`).

Pourquoi pas `adodbapi` : après `Open()`, il lit des propriétés ADO
(« DBMS Name », « Transaction DDL »…) que le provider `PCSOFT.HFSQL`
n'expose pas. La connexion réussit, puis `adodbapi` échoue sur
« Impossible de trouver l'objet dans la collection » (`adErrItemNotFound`).

On n'a besoin que de lire : ouvrir, exécuter un SELECT, parcourir le résultat
par paquets. Ce module fait exactement ça, avec l'interface de curseur DB-API
utilisée par `source.py` (`execute`, `description`, `fetchone`, `fetchmany`,
`close`).

Le curseur est **côté serveur, en avant seulement** (le défaut d'ADO) : sur
`sorties_produits` (plusieurs centaines de Mo), un curseur client chargerait
toute la table en mémoire avant de rendre la première ligne.
"""
from __future__ import annotations

import datetime as dt
from typing import Any, Callable, Sequence

_AD_STATE_OPEN = 1
_AD_SCHEMA_TABLES = 20
# Date zéro OLE (30/12/1899) : ce qu'ADO rend pour une date WinDev vide.
_DATE_ZERO_OLE = dt.date(1899, 12, 30)


def _dispatch_reel(progid: str):
    import win32com.client  # importé tard : absent hors du poste Windows

    return win32com.client.Dispatch(progid)


def _valeur(v: Any) -> Any:
    """
    Normalise une valeur COM.

    pywin32 rend les dates ADO en `pywintypes.datetime`, avec un fuseau UTC
    arbitraire : une date HFSQL n'a pas de fuseau, on le retire. La date zéro
    OLE devient `None`.
    """
    if isinstance(v, dt.datetime):
        if v.tzinfo is not None:
            v = v.replace(tzinfo=None)
        naive = dt.datetime(v.year, v.month, v.day, v.hour, v.minute, v.second, v.microsecond)
        if naive.date() == _DATE_ZERO_OLE:
            return None
        return naive
    return v


class CurseurADO:
    def __init__(self, connexion):
        self._cnx = connexion
        self._rs = None
        self.description: list[tuple] | None = None

    def execute(self, requete: str) -> "CurseurADO":
        self.close()
        # Execute rend un Recordset en avant seulement, lecture seule, côté
        # serveur. Le tuple renvoyé par pywin32 est (recordset, nb_affectés).
        resultat = self._cnx.Execute(requete)
        rs = resultat[0] if isinstance(resultat, tuple) else resultat
        self._rs = rs
        noms = [rs.Fields.Item(i).Name for i in range(rs.Fields.Count)]
        self.description = [(nom, None, None, None, None, None, None) for nom in noms]
        return self

    def fetchmany(self, taille: int) -> list[tuple]:
        rs = self._rs
        if rs is None or rs.State != _AD_STATE_OPEN or rs.EOF:
            return []
        # GetRows rend les données en colonnes : ((c1_l1, c1_l2…), (c2_l1…)).
        colonnes = rs.GetRows(taille)
        if not colonnes:
            return []
        return [tuple(_valeur(v) for v in ligne) for ligne in zip(*colonnes)]

    def fetchone(self) -> tuple | None:
        lignes = self.fetchmany(1)
        return lignes[0] if lignes else None

    def close(self) -> None:
        if self._rs is not None:
            try:
                if self._rs.State == _AD_STATE_OPEN:
                    self._rs.Close()
            except Exception:
                pass
            self._rs = None


class ConnexionADO:
    def __init__(self, chaine: str, dispatch: Callable[[str], Any] = _dispatch_reel):
        self._cnx = dispatch("ADODB.Connection")
        self._cnx.Open(chaine)

    def cursor(self) -> CurseurADO:
        return CurseurADO(self._cnx)

    def get_table_names(self) -> list[str]:
        """Tables utilisateur, via le schéma ADO adSchemaTables."""
        rs = self._cnx.OpenSchema(_AD_SCHEMA_TABLES)
        noms: list[str] = []
        try:
            while not rs.EOF:
                type_ = str(rs.Fields.Item("TABLE_TYPE").Value or "").upper()
                if type_ in ("", "TABLE"):
                    noms.append(str(rs.Fields.Item("TABLE_NAME").Value))
                rs.MoveNext()
        finally:
            rs.Close()
        return noms

    def close(self) -> None:
        try:
            if self._cnx.State == _AD_STATE_OPEN:
                self._cnx.Close()
        except Exception:
            pass


def connecter(chaine: str, dispatch: Callable[[str], Any] = _dispatch_reel) -> ConnexionADO:
    return ConnexionADO(chaine, dispatch)


__all__: Sequence[str] = ("ConnexionADO", "CurseurADO", "connecter")
