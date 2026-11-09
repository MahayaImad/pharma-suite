"""
Tests du pilote ADO — avec un faux objet COM, sans Windows.
"""
from __future__ import annotations

import datetime as dt
from decimal import Decimal

from pharmasuite_agent.ado import connecter


class _Champ:
    def __init__(self, nom, valeur=None):
        self.Name = nom
        self.Value = valeur


class _Champs:
    def __init__(self, champs):
        self._champs = champs
        self.Count = len(champs)

    def Item(self, cle):
        if isinstance(cle, int):
            return self._champs[cle]
        return next(c for c in self._champs if c.Name == cle)


class FauxRecordset:
    def __init__(self, noms, lignes):
        self._noms = noms
        self._lignes = list(lignes)
        self._pos = 0
        self.State = 1
        self.demandes = []

    @property
    def EOF(self):
        return self._pos >= len(self._lignes)

    @property
    def Fields(self):
        ligne = self._lignes[self._pos] if not self.EOF else [None] * len(self._noms)
        return _Champs([_Champ(n, v) for n, v in zip(self._noms, ligne)])

    def GetRows(self, n):
        self.demandes.append(n)
        lot = self._lignes[self._pos:self._pos + n]
        self._pos += len(lot)
        return tuple(zip(*lot))  # ADO rend les données en colonnes

    def MoveNext(self):
        self._pos += 1

    def Close(self):
        self.State = 0


class FausseConnexion:
    def __init__(self, recordsets):
        self.recordsets = recordsets
        self.ouverte_avec = None
        self.requetes = []
        self.State = 0

    def Open(self, chaine):
        self.ouverte_avec = chaine
        self.State = 1

    def Execute(self, requete):
        self.requetes.append(requete)
        return (self.recordsets.pop(0), 0)

    def OpenSchema(self, _type):
        return self.recordsets.pop(0)

    def Close(self):
        self.State = 0


def _connexion(*recordsets):
    faux = FausseConnexion(list(recordsets))
    return connecter("Provider=PCSOFT.HFSQL;", dispatch=lambda progid: faux), faux


def test_ouvre_sans_lire_de_proprietes():
    """adodbapi lisait « DBMS Name » après Open : le provider HFSQL ne l'a pas."""
    cnx, faux = _connexion()
    assert faux.ouverte_avec == "Provider=PCSOFT.HFSQL;"


def test_lecture_par_paquets_transpose_les_colonnes():
    rs = FauxRecordset(["id", "nom"], [(1, "A"), (2, "B"), (3, "C")])
    cnx, _ = _connexion(rs)
    cur = cnx.cursor().execute("SELECT * FROM familles")

    assert [d[0] for d in cur.description] == ["id", "nom"]
    assert cur.fetchmany(2) == [(1, "A"), (2, "B")]
    assert cur.fetchmany(2) == [(3, "C")]
    assert cur.fetchmany(2) == []
    assert rs.demandes == [2, 2]


def test_types_com_normalises():
    utc = dt.timezone.utc
    rs = FauxRecordset(["d", "vide", "m"], [(
        dt.datetime(2026, 8, 19, tzinfo=utc),
        dt.datetime(1899, 12, 30, tzinfo=utc),   # date WinDev non saisie
        Decimal("310.5000"),
    )])
    cnx, _ = _connexion(rs)
    ligne = cnx.cursor().execute("SELECT 1").fetchone()
    assert ligne == (dt.datetime(2026, 8, 19), None, Decimal("310.5000"))
    assert ligne[0].tzinfo is None


def test_liste_des_tables_par_le_schema():
    schema = FauxRecordset(["TABLE_NAME", "TABLE_TYPE"],
                           [("sorties", "TABLE"), ("entrées", "TABLE"), ("vue_x", "VIEW")])
    cnx, _ = _connexion(schema)
    assert cnx.get_table_names() == ["sorties", "entrées"]


def test_cache_aligne_sur_les_paquets():
    """CacheSize=1 par défaut ferait un aller-retour HFSQL par ligne."""
    rs = FauxRecordset(["id"], [(1,)])
    rs.CacheSize = 1
    cnx, _ = _connexion(rs)
    cnx.cursor().execute("SELECT id FROM sorties")
    assert rs.CacheSize == 1000


def test_heure_seule_sur_date_zero_ole_conservee():
    utc = dt.timezone.utc
    rs = FauxRecordset(["heure"], [(dt.datetime(1899, 12, 30, 8, 5, 3, tzinfo=utc),)])
    cnx, _ = _connexion(rs)
    assert cnx.cursor().execute("SELECT heure FROM sorties").fetchone() == (dt.time(8, 5, 3),)
