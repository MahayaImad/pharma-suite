"""
Tests des correctifs « ne rien perdre » de la synchronisation.

Chaque test correspond à une façon dont une donnée HFSQL pouvait ne jamais
atteindre PostgreSQL, sans erreur visible.
"""
from __future__ import annotations

import re
from pathlib import Path

import pytest

from pharmasuite_agent.client import ClientPharmaSuite, LotRejete
from pharmasuite_agent.runner import Etat, passe, synchroniser_table
from pharmasuite_agent.serialisation import ligne_json, nom_colonne, valeur_json
from pharmasuite_agent.tables import TABLES, Table, par_nom
from pharmasuite_agent.verification import verifier

from tests.test_agent import ClientFactice, SourceFactice


# ── Noms de colonnes ──────────────────────────────────────────────────────────

@pytest.mark.parametrize("hfsql, postgres", [
    ("cloturé", "cloture"),
    ("n_assuré", "n_assure"),
    ("Bloqué", "bloque"),
    ("ID", "id"),
    ("prix_vente", "prix_vente"),
])
def test_noms_de_colonnes_normalises(hfsql, postgres):
    """Sans ça, le serveur ignorait la colonne et la valeur était perdue."""
    assert nom_colonne(hfsql) == postgres


def test_ligne_json_normalise_les_cles():
    assert ligne_json(["ID", "Clôturé"], [1, 0]) == {"id": 1, "cloture": 0}


def test_texte_ansi_decode_en_cp1252():
    assert valeur_json("Pharmacie Médéa".encode("cp1252")) == "Pharmacie Médéa"
    assert valeur_json("Médéa".encode("utf-8")) == "Médéa"


def test_float_jamais_envoye_en_nombre():
    assert valeur_json(1450.1) == "1450.1"


# ── Fenêtre glissante : l'historique complet ──────────────────────────────────

def test_premier_lancement_window_charge_tout_l_historique():
    """
    Avant : seule la fenêtre de 30 jours était lue, l'historique des ventes
    n'arrivait jamais. Maintenant le rattrapage part du curseur serveur (0).
    """
    source = SourceFactice({"sorties": [{"id": i} for i in range(1, 6)]})
    source.lire_fenetre = lambda *a, **k: iter([])  # rien de récent
    client = ClientFactice()

    envoyees = synchroniser_table(par_nom("sorties"), source, client)

    assert envoyees == 5
    assert ("sorties", 0) in source.lectures
    assert client.majs[-1][:2] == ("sorties", 5)


def test_window_relit_la_fenetre_sans_doublon():
    source = SourceFactice({"sorties": [{"id": i} for i in range(1, 6)]})
    client = ClientFactice(statuts={"sorties": 3})

    synchroniser_table(par_nom("sorties"), source, client)

    ids_envoyes = [l["id"] for _, lot in client.pousses for l in lot]
    # 4 et 5 par le rattrapage, 1 à 3 par la fenêtre — chacun une seule fois.
    assert sorted(ids_envoyes) == [1, 2, 3, 4, 5]


# ── Lots refusés ──────────────────────────────────────────────────────────────

class ClientQuiRefuse(ClientFactice):
    def pousser(self, table, enregistrements):
        raise LotRejete(table, {"errors": 1, "rejected": [{"id": 2, "erreur": "too long"}]})


def test_lot_refuse_n_avance_pas_le_curseur():
    """Avant : errors > 0 arrivait en HTTP 200, le curseur avançait quand même."""
    source = SourceFactice({"sorties_produits": [{"id": i} for i in range(1, 4)]})
    client = ClientQuiRefuse()

    with pytest.raises(LotRejete):
        synchroniser_table(par_nom("sorties_produits"), source, client)

    assert client.majs == []


def test_client_reel_leve_sur_errors():
    client = ClientPharmaSuite("http://serveur.invalide", "u", "p")
    try:
        with pytest.raises(LotRejete, match="id=7"):
            client._controler("sorties", {"synced": 9, "errors": 1,
                                          "rejected": [{"id": 7, "erreur": "x"}]})
        assert client._controler("sorties", {"synced": 3, "errors": 0}) == {"synced": 3, "errors": 0}
    finally:
        client.fermer()


# ── Pipeline instance_produits ────────────────────────────────────────────────

def test_pipeline_passe_par_les_endpoints_dedies():
    """La route générique ne remet pas archive=FALSE : il faut /batch."""
    source = SourceFactice({
        "instance_produits": [{"id": 1}, {"id": 2}],
        "instance_produits_trt": [{"id": 3}],
    })
    client = ClientFactice()

    assert synchroniser_table(par_nom("instance_produits"), source, client) == 3
    assert [t for t, _ in client.pousses] == ["instance_produits/batch", "instance_produits_trt"]


# ── Tables optionnelles ───────────────────────────────────────────────────────

def test_table_optionnelle_absente_ne_fait_pas_echouer_la_passe(tmp_path):
    lignes = {t.source: [{"id": 1}] for t in TABLES if not t.optionnelle}
    lignes["instance_produits_trt"] = []
    source = SourceFactice(lignes)

    def lire(table, cle, depuis, taille):
        if table not in source.lignes:
            raise RuntimeError("Fichier de données introuvable")
        yield from SourceFactice.lire(source, table, cle, depuis, taille)
    source.lire = lire

    bilan = passe(source, ClientFactice(), Etat(tmp_path / "e.json"), 500, 12)

    assert bilan.tables_en_erreur == 0
    assert len(bilan.tables_absentes) == sum(t.optionnelle for t in TABLES)


# ── Couverture du registre serveur ────────────────────────────────────────────

def test_agent_couvre_toutes_les_tables_du_serveur():
    sync_py = Path(__file__).resolve().parents[2] / "backend/app/api/v1/sync.py"
    if not sync_py.exists():
        pytest.skip("backend absent")
    bloc = sync_py.read_text(encoding="utf-8").split("SYNC_REGISTRY")[1].split("}")[0]
    registre = set(re.findall(r'"(\w+)":', bloc))
    assert registre == {t.cible for t in TABLES}


# ── Vérification ──────────────────────────────────────────────────────────────

class ClientSchema(ClientFactice):
    def __init__(self, schema):
        super().__init__()
        self._schema = schema

    def schema(self):
        return self._schema


def test_verifier_signale_colonnes_perdues_et_ecarts():
    source = SourceFactice({
        "familles": [{"id": 1, "famille": "A", "couleur": "x"}, {"id": 2, "famille": "B", "couleur": "y"}],
        "table_oubliee": [],
    })
    schema = [{"table": "familles", "columns": ["id", "famille", "code"], "count": 1}]

    rapport = verifier(source, ClientSchema(schema))
    familles = next(l for l in rapport.lignes if l.table == "familles")

    assert familles.colonnes_perdues == ["couleur"]
    assert familles.colonnes_jamais_remplies == ["code"]
    assert familles.ecart == 1
    assert "table_oubliee" in rapport.tables_hfsql_non_lues
    assert not rapport.complet


# ── Connexion OLE DB ──────────────────────────────────────────────────────────

from pharmasuite_agent.config import SourceConfig  # noqa: E402
from pharmasuite_agent.source import SourceHFSQL  # noqa: E402


def test_chaine_provider_oledb():
    """Le mot de passe des fichiers passe en Extended Properties, pour toutes les tables."""
    source = SourceHFSQL.depuis_config(SourceConfig(
        server="192.168.1.5", port=4900, database="EASYPHARM", user="admin", password="s3cret",
    ))
    assert source._build_provider_string() == (
        'Provider=PCSOFT.HFSQL;'
        ' Data Source=192.168.1.5:4900;'
        ' Initial Catalog=EASYPHARM;'
        ' User ID=admin;'
        ' Password=;'
        ' Extended Properties="Password=*:s3cret;"'
    )


def test_description_ne_montre_pas_le_mot_de_passe():
    source = SourceHFSQL("srv", "BASE", password="s3cret")
    assert "s3cret" not in source.description


@pytest.mark.parametrize("mdp", ['a;b', 'a"b'])
def test_mot_de_passe_cassant_la_chaine_refuse(mdp):
    with pytest.raises(ValueError):
        SourceHFSQL("srv", "BASE", password=mdp)._build_provider_string()


def test_config_exemple_charge(tmp_path):
    from pharmasuite_agent.config import Config
    exemple = Path(__file__).resolve().parents[1] / "config.example.toml"
    config = Config.charger(exemple)
    assert config.source.port == 4900
    assert config.source.database
