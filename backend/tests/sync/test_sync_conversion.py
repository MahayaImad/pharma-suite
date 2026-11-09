"""
Contrat de réception du sync EASYPHARM — sans postgres.

Ce qui est verrouillé ici : aucune valeur source ne doit disparaître en
silence. Une date au format HFSQL est convertie, une date illisible est
signalée, une ligne refusée par PostgreSQL est rendue avec son id.
"""
from __future__ import annotations

import datetime as dt
from decimal import Decimal

import pytest
from sqlalchemy.dialects import postgresql

from app.api.v1 import sync
from app.api.v1.sync import (
    ValeurInvalide, _clean_record, _colonnes_ignorees, _homogeneiser,
    _params_instance, _parse_date, _parse_entier, _upsert_batch,
)
from app.models.pharma import InstanceProduit
from app.models.ventes import SortieProduit


# ── Dates ─────────────────────────────────────────────────────────────────────

@pytest.mark.parametrize("entree", [
    "2026-08-19",
    "2026-08-19T00:00:00",      # ce que ADO rend pour une colonne date HFSQL
    "2026-08-19 00:00:00",
    "20260819",                 # format natif HFSQL
    "19/08/2026",
    dt.date(2026, 8, 19),
    dt.datetime(2026, 8, 19, 10, 30),
])
def test_formats_de_date_acceptes(entree):
    assert _parse_date(entree) == dt.date(2026, 8, 19)


@pytest.mark.parametrize("vide", ["", "00000000", "  "])
def test_date_vide_windev_devient_null(vide):
    assert _parse_date(vide) is None


def test_date_illisible_leve_au_lieu_de_disparaitre():
    with pytest.raises(ValeurInvalide):
        _parse_date("19 août")


# ── Nombres ───────────────────────────────────────────────────────────────────

def test_identifiant_type_decimal_par_hfsql():
    """entrees_produits.id_produit arrive en « Décimal 9 » : '123.0000'."""
    assert _parse_entier("123.0000") == 123
    assert _parse_entier(Decimal("42")) == 42


def test_entier_avec_decimales_refuse():
    with pytest.raises(ValeurInvalide):
        _parse_entier("12.5")


# ── Nettoyage d'une ligne ─────────────────────────────────────────────────────

def test_clean_record_type_chaque_colonne():
    anomalies: list = []
    propre = _clean_record({
        "id": "10.0000", "date": "2026-08-19T00:00:00",
        "prix_vente": "310.5000", "nom": 1234, "colonne_inconnue": "x",
    }, SortieProduit, anomalies)

    assert propre["id"] == 10
    assert propre["date"] == dt.date(2026, 8, 19)
    assert propre["prix_vente"] == Decimal("310.5000")
    assert isinstance(propre["prix_vente"], Decimal)
    assert propre["nom"] == "1234"
    assert "colonne_inconnue" not in propre
    assert anomalies == []


def test_valeur_invalide_consignee():
    anomalies: list = []
    propre = _clean_record({"id": 7, "date": "bientôt"}, SortieProduit, anomalies)
    assert propre["date"] is None
    assert anomalies == [{"id": 7, "colonne": "date", "erreur": "date illisible : 'bientôt'"}]


def test_colonnes_ignorees_listees():
    """Une colonne HFSQL accentuée non normalisée doit se voir, pas se perdre."""
    assert _colonnes_ignorees([{"id": 1, "clôturé": 0}, {"id": 2, "x": 1}], SortieProduit) == ["clôturé", "x"]


def test_homogeneiser_aligne_les_cles():
    lignes = _homogeneiser([{"id": 1}, {"id": 2, "nom": "A"}])
    assert lignes == [{"id": 1, "nom": None}, {"id": 2, "nom": "A"}]


def test_params_instance_complets_et_types():
    """Une clé manquante faisait échouer tout le lot en StatementError."""
    params = _params_instance({"id": 5, "date": "20260819", "prix_vente": "99.9900"}, [])
    assert set(params) == set(sync._COLONNES_INSTANCE)
    assert params["lot"] is None
    assert params["date"] == dt.date(2026, 8, 19)
    assert params["prix_vente"] == Decimal("99.9900")


# ── Upsert : reprise ligne par ligne ──────────────────────────────────────────

class SessionCapricieuse:
    """Refuse toute requête contenant la valeur `poison`."""

    def __init__(self, poison: str):
        self.poison = poison
        self.executions = 0

    async def execute(self, stmt):
        self.executions += 1
        params = stmt.compile(dialect=postgresql.dialect()).params
        if self.poison in params.values():
            raise RuntimeError("value too long for type character varying(150)")

    async def commit(self):
        pass

    async def rollback(self):
        pass


async def test_une_ligne_refusee_ne_fait_pas_perdre_le_lot():
    session = SessionCapricieuse(poison="TROP LONG")
    lignes = [{"id": i, "nom": "OK"} for i in range(1, 6)]
    lignes[2]["nom"] = "TROP LONG"

    synced, errors, rejets, _ = await _upsert_batch(session, SortieProduit, lignes)

    assert synced == 4
    assert errors == 1
    assert rejets[0]["id"] == 3
    assert "too long" in rejets[0]["erreur"]


async def test_ligne_sans_id_comptee_en_erreur():
    session = SessionCapricieuse(poison="__aucun__")
    synced, errors, rejets, _ = await _upsert_batch(session, SortieProduit, [{"id": 1}, {"nom": "x"}])
    assert (synced, errors) == (1, 1)
    assert rejets[0]["id"] is None


def test_droits_groupware_empaquetes():
    from app.api.v1.sync import _empaqueter_droits
    [ligne] = _empaqueter_droits([{"id": 1, "utilisateur": "imad", "vnt_hist": 1, "stk_inv": 0}])
    assert ligne == {"id": 1, "utilisateur": "imad", "droits": {"vnt_hist": 1, "stk_inv": 0}}


def test_texte_trop_long_signale_avec_sa_colonne():
    anomalies: list = []
    propre = _clean_record({"id": 1, "heure": "2026-11-10T08:05:03"}, SortieProduit, anomalies)
    assert propre["heure"] == "2026-11-10T08:05:03"   # jamais tronqué en silence
    assert anomalies == [{"id": 1, "colonne": "heure",
                          "erreur": "trop long pour VARCHAR(10) : '2026-11-10T08:05:03'"}]
