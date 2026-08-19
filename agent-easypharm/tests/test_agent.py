"""
Tests de l'agent — sans driver ODBC ni réseau.

La source et le client sont remplacés par des doublures ; ce qui est vérifié
ici, c'est la logique de reprise, le découpage en lots et la sérialisation.
"""
from __future__ import annotations

import datetime as dt
from decimal import Decimal

import pytest

from pharmasuite_agent.runner import Etat, _doit_tout_relire, passe, synchroniser_table
from pharmasuite_agent.serialisation import ligne_json, valeur_json
from pharmasuite_agent.tables import TABLES, par_nom


# ── Doublures ─────────────────────────────────────────────────────────────────

class SourceFactice:
    def __init__(self, lignes_par_table=None):
        self.lignes = lignes_par_table or {}
        self.lectures: list[tuple[str, int]] = []

    def lire(self, table, cle, depuis, taille):
        self.lectures.append((table, depuis))
        for ligne in self.lignes.get(table, []):
            if depuis < 0 or ligne[cle] > depuis:
                yield dict(ligne)

    def max_cle(self, table, cle):
        lignes = self.lignes.get(table, [])
        return max((l[cle] for l in lignes), default=0)


class ClientFactice:
    def __init__(self, statuts=None, casse_sur=None):
        self.statuts = statuts or {}
        self.casse_sur = casse_sur
        self.pousses: list[tuple[str, list]] = []
        self.majs: list[tuple[str, int, int]] = []

    def statut(self, table):
        return self.statuts.get(table, 0)

    def pousser(self, table, enregistrements):
        if table == self.casse_sur:
            raise RuntimeError("réseau coupé")
        self.pousses.append((table, list(enregistrements)))
        return {"table": table, "synced": len(enregistrements), "errors": 0}

    def maj_statut(self, table, last_id, count):
        self.majs.append((table, last_id, count))


# ── Sérialisation ─────────────────────────────────────────────────────────────

def test_decimal_serialise_en_chaine():
    """Un montant ne doit jamais transiter en float."""
    resultat = valeur_json(Decimal("1234.5678"))
    assert resultat == "1234.5678"
    assert isinstance(resultat, str)


def test_dates_en_iso():
    assert valeur_json(dt.date(2026, 7, 1)) == "2026-07-01"
    assert valeur_json(dt.datetime(2026, 7, 1, 14, 30)) == "2026-07-01T14:30:00"


def test_padding_hfsql_retire():
    """HyperFileSQL complète les CHAR avec des espaces."""
    assert valeur_json("DOLIPRANE 1000   ") == "DOLIPRANE 1000"


def test_ligne_complete():
    ligne = ligne_json(
        ["id", "prix_vente", "date", "nom"],
        [42, Decimal("310.0000"), dt.date(2026, 7, 1), "AMOXIL  "],
    )
    assert ligne == {"id": 42, "prix_vente": "310.0000",
                     "date": "2026-07-01", "nom": "AMOXIL"}


# ── Reprise incrémentale ──────────────────────────────────────────────────────

def test_reprend_au_dernier_id_connu_du_serveur():
    source = SourceFactice({"sorties": [{"id": i} for i in range(1, 11)]})
    client = ClientFactice(statuts={"sorties": 7})

    envoyees = synchroniser_table(par_nom("sorties"), source, client, 500, False)

    assert envoyees == 3                      # ids 8, 9, 10
    assert source.lectures == [("sorties", 7)]
    assert [r["id"] for r in client.pousses[0][1]] == [8, 9, 10]


def test_curseur_avance_au_max_recu():
    source = SourceFactice({"sorties": [{"id": i} for i in range(1, 6)]})
    client = ClientFactice()

    synchroniser_table(par_nom("sorties"), source, client, 500, False)

    assert client.majs == [("sorties", 5, 5)]


def test_rien_a_faire_ne_pousse_rien():
    source = SourceFactice({"sorties": [{"id": 1}]})
    client = ClientFactice(statuts={"sorties": 1})

    assert synchroniser_table(par_nom("sorties"), source, client, 500, False) == 0
    assert client.pousses == []
    assert client.majs == []


def test_decoupage_en_lots_et_curseur_par_lot():
    """
    Le curseur avance après chaque lot : une coupure ne fait reperdre que le
    lot en cours, pas toute la table.
    """
    source = SourceFactice({"sorties": [{"id": i} for i in range(1, 8)]})
    client = ClientFactice()

    synchroniser_table(par_nom("sorties"), source, client, 3, False)

    assert [len(lot) for _, lot in client.pousses] == [3, 3, 1]
    assert client.majs == [("sorties", 3, 3), ("sorties", 6, 3), ("sorties", 7, 1)]


def test_relecture_complete_ignore_le_curseur():
    source = SourceFactice({"nomenclature": [{"id": i} for i in range(1, 4)]})
    client = ClientFactice(statuts={"nomenclature": 99})

    envoyees = synchroniser_table(par_nom("nomenclature"), source, client, 500, True)

    assert envoyees == 3
    assert source.lectures == [("nomenclature", -1)]


# ── Passes ────────────────────────────────────────────────────────────────────

def test_full_resync_seulement_sur_les_tables_completes():
    assert _doit_tout_relire(par_nom("nomenclature"), 0, 12) is True
    assert _doit_tout_relire(par_nom("nomenclature"), 3, 12) is False
    assert _doit_tout_relire(par_nom("sorties"), 0, 12) is False


def test_une_table_en_erreur_n_arrete_pas_les_autres(tmp_path):
    source = SourceFactice({t.source: [{"id": 1}] for t in TABLES})
    client = ClientFactice(casse_sur="sorties")
    etat = Etat(tmp_path / "etat.json")

    bilan = passe(source, client, etat, 500, 12)

    assert bilan.tables_en_erreur == 1
    assert bilan.tables_ok == len(TABLES) - 1
    assert any("sorties" in e for e in bilan.erreurs)


def test_etat_persiste_entre_deux_passes(tmp_path):
    chemin = tmp_path / "etat.json"
    source = SourceFactice()
    client = ClientFactice()

    passe(source, client, Etat(chemin), 500, 12)
    assert Etat(chemin).passes == 1

    passe(source, client, Etat(chemin), 500, 12)
    assert Etat(chemin).passes == 2


def test_etat_illisible_repart_de_zero(tmp_path):
    chemin = tmp_path / "etat.json"
    chemin.write_text("ceci n'est pas du json")
    assert Etat(chemin).passes == 0


# ── Registre des tables ───────────────────────────────────────────────────────

def test_pas_de_doublon_de_cible():
    cibles = [t.cible for t in TABLES]
    assert len(cibles) == len(set(cibles))


def test_referentiels_avant_mouvements():
    """Les dépendances doivent être poussées avant ce qui les référence."""
    ordre = [t.cible for t in TABLES]
    for amont, aval in [("clients", "sorties"), ("nomenclature", "sorties_produits"),
                        ("fournisseurs", "entrees"), ("sorties", "sorties_produits")]:
        assert ordre.index(amont) < ordre.index(aval), f"{amont} doit précéder {aval}"


def test_table_inconnue_leve():
    with pytest.raises(KeyError):
        par_nom("table_qui_nexiste_pas")
