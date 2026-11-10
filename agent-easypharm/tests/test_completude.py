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

def test_table_optionnelle_absente_ne_fait_pas_echouer_la_passe(tmp_path, monkeypatch):
    from pharmasuite_agent import runner
    absente = Table(cible="absente", source="absente", strategie="full", optionnelle=True)
    presente = Table(cible="familles", source="familles", strategie="full")
    monkeypatch.setattr(runner, "TABLES", (absente, presente))
    source = SourceFactice({"familles": [{"id": 1}]})

    def lire(table, cle, depuis, taille):
        if table not in source.lignes:
            raise RuntimeError("Fichier de données introuvable")
        yield from SourceFactice.lire(source, table, cle, depuis, taille)
    source.lire = lire

    bilan = passe(source, ClientFactice(), Etat(tmp_path / "e.json"), 500, 12)

    assert bilan.tables_en_erreur == 0
    assert bilan.tables_absentes == ["absente"]
    assert bilan.tables_ok == 1


def test_noms_hfsql_attestes():
    """Noms relevés sur le dossier de données EASYPHARM (2026-11-09)."""
    assert par_nom("entrees").source == "entrées"
    assert par_nom("entrees_produits").source == "entrées_produits"
    assert par_nom("operations").source == "opérations"
    assert par_nom("depenses").source == "dépenses"
    assert par_nom("caisses_regies").source == "caisses_régies"
    assert not any(t.optionnelle for t in TABLES)


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


# ── Erreurs de connexion ──────────────────────────────────────────────────────

from pharmasuite_agent.source import _message_hfsql  # noqa: E402

_ERREUR_70207 = (
    "(com_error(-2147352567, 'Une exception s’est produite.', (0, None, \"Que s'est-il passé ?"
    "\\r\\nLe fichier <Bordereau> est déjà décrit.\\r\\n\\r\\nCode erreur : 70207\\r\\nNiveau : "
    "erreur non fatale (EL_ONRETURN)\\r\\nVersion=<17.0.111.5>\", None, 0, -2147467259), None), "
    "'Error opening connection to \"Provider=PCSOFT.HFSQL; Extended Properties=\"Password=*:s3cret;\"\"')"
)


def test_erreur_de_connexion_ne_montre_pas_le_mot_de_passe():
    message = _message_hfsql(RuntimeError(_ERREUR_70207), ["s3cret"])
    assert "s3cret" not in message


def test_erreur_70207_lisible_avec_piste():
    message = _message_hfsql(RuntimeError(_ERREUR_70207), ["s3cret"])
    assert message.startswith("Le fichier <Bordereau> est déjà décrit. — code HFSQL 70207 — provider 17.0.111.5")
    assert "même nom logique" in message


def test_erreur_inconnue_tronquee_et_masquee():
    message = _message_hfsql(RuntimeError("boom Password=*:s3cret;"), ["s3cret"])
    assert message == "boom Password=*:****;"


def test_proprietes_extra_ajoutees():
    source = SourceHFSQL("srv", "BASE", password="p", proprietes_extra="Analysis=C:\\A\\X.wdd")
    assert source._build_provider_string().endswith('Extended Properties="Password=*:p;Analysis=C:\\A\\X.wdd;"')


# ── Correspondances de colonnes relevées par --verifier ──────────────────────

def test_motif_instance_renomme_en_motif():
    source = SourceFactice({"motif_instance": [{"id": 1, "motif_instance": "Rupture"}]})
    client = ClientFactice()
    synchroniser_table(par_nom("motif_instance"), source, client)
    assert client.pousses[0][1] == [{"id": 1, "motif": "Rupture"}]


def test_verifier_tient_compte_renommage_et_empaquetage():
    source = SourceFactice({
        "motif_instance": [{"id": 1, "motif_instance": "x"}],
        "groupware": [{"id": 1, "utilisateur": "a", "vnt_hist": 1}],
        "nomenclature": [{"id": 1, "nom": "A"}],
    })
    schema = [
        {"table": "motif_instance", "columns": ["id", "motif"], "count": 1},
        {"table": "groupware", "columns": ["id", "utilisateur", "droits", "nom"], "count": 1},
        {"table": "nomenclature", "columns": ["id", "nom", "segment_abc", "categorie"], "count": 1},
    ]
    lignes = {l.table: l for l in verifier(source, ClientSchema(schema)).lignes}
    for nom in ("motif_instance", "groupware", "nomenclature"):
        assert lignes[nom].colonnes_perdues == [], nom
        assert lignes[nom].colonnes_jamais_remplies == [], nom


def test_erreur_serveur_sur_trt_n_est_pas_masquee():
    from pharmasuite_agent.client import ErreurApi

    class ClientTrtEnPanne(ClientFactice):
        def pousser_instance_produits_trt(self, enregistrements):
            raise ErreurApi("POST /sync/instance_produits_trt a échoué après 5 tentatives : HTTP 500")

    source = SourceFactice({"instance_produits": [{"id": 1}], "instance_produits_trt": [{"id": 2}]})
    with pytest.raises(ErreurApi):
        synchroniser_table(par_nom("instance_produits"), source, ClientTrtEnPanne())


# ── Heures HFSQL ──────────────────────────────────────────────────────────────

import datetime as _dt  # noqa: E402
from pharmasuite_agent.serialisation import normaliser_heure  # noqa: E402


@pytest.mark.parametrize("entree, attendu", [
    (_dt.datetime(2026, 11, 10, 8, 5, 3), "08:05:03"),
    (_dt.time(8, 5, 3), "08:05:03"),
    ("2026-11-10T08:05:03", "08:05:03"),
    ("08:05:03:45", "08:05:03"),      # centièmes HFSQL
    ("8:05", "08:05:00"),
    ("08050345", "08:05:03"),         # HHMMSSCC natif
    ("0805", "08:05:00"),
    ("", None),
    (None, None),
])
def test_heure_normalisee(entree, attendu):
    assert normaliser_heure(entree) == attendu


def test_ligne_normalise_seulement_les_colonnes_heure():
    ligne = ligne_json(["id", "Heure", "heure_fin", "date"],
                       [1, "2026-11-10T08:05:03", "17:30:00:00", _dt.date(2026, 11, 10)])
    assert ligne == {"id": 1, "heure": "08:05:03", "heure_fin": "17:30:00", "date": "2026-11-10"}


def test_lot_rejete_nomme_la_colonne():
    erreur = LotRejete("sorties", {
        "errors": 1, "rejected": [{"id": 1, "erreur": "value too long"}],
        "invalid_values": [{"id": 1, "colonne": "heure", "erreur": "trop long pour VARCHAR(10) : 'x'"}],
    })
    assert "colonnes en cause : heure" in str(erreur)


def test_verifier_compte_les_instances_traitees():
    """PostgreSQL réunit instance_produits et instance_produits_trt."""
    source = SourceFactice({
        "instance_produits": [{"id": 1}, {"id": 2}],
        "instance_produits_trt": [{"id": 3}, {"id": 4}, {"id": 5}],
    })
    schema = [{"table": "instance_produits", "columns": ["id"], "count": 5}]
    ligne = next(l for l in verifier(source, ClientSchema(schema)).lignes if l.table == "instance_produits")
    assert ligne.lignes_hfsql == 5 and ligne.ecart == 0


def test_connexion_fermee_apres_une_passe_en_erreur(tmp_path):
    """Sinon une connexion HFSQL morte ferait échouer toutes les passes suivantes."""
    source = SourceFactice({t.source: [{"id": 1}] for t in TABLES} | {"instance_produits_trt": []})
    source.fermetures = 0

    def fermer():
        source.fermetures += 1
    source.fermer = fermer

    passe(source, ClientFactice(), Etat(tmp_path / "e.json"), 500, 12)
    assert source.fermetures == 0

    passe(source, ClientFactice(casse_sur="sorties"), Etat(tmp_path / "e.json"), 500, 12)
    assert source.fermetures == 1


# ── Lots : le stock change sur place ──────────────────────────────────────────

def _passe_lots(source, client, etat):
    return synchroniser_table(par_nom("entrees_produits"), source, client, etat)


def test_lots_premier_lancement_relit_tout(tmp_path):
    source = SourceFactice({"entrées_produits": [
        {"id": 1, "stock": 0}, {"id": 2, "stock": 5}, {"id": 3, "stock": 2}]})
    client, etat = ClientFactice(), Etat(tmp_path / "e.json")

    assert _passe_lots(source, client, etat) == 3
    assert etat.lots_en_stock["entrees_produits"] == [2, 3]
    assert client.majs[-1][:2] == ("entrees_produits", 3)


def test_lot_epuise_est_remis_a_zero(tmp_path):
    """Avant : la table était incrémentale, le stock restait figé au chargement."""
    lignes = [{"id": 1, "stock": 0}, {"id": 2, "stock": 5}, {"id": 3, "stock": 2}]
    source = SourceFactice({"entrées_produits": lignes})
    client, etat = ClientFactice(statuts={"entrees_produits": 3}), Etat(tmp_path / "e.json")
    etat.lots_en_stock["entrees_produits"] = [2, 3]

    lignes[1]["stock"] = 4          # une vente sur le lot 2
    lignes[2]["stock"] = 0          # le lot 3 est épuisé
    lignes.append({"id": 4, "stock": 9})   # une réception

    _passe_lots(source, client, etat)

    envoye = {l["id"]: l["stock"] for _, lot in client.pousses for l in lot}
    assert envoye == {2: 4, 3: 0, 4: 9}        # le lot 1, inchangé à zéro, n'est pas relu
    assert etat.lots_en_stock["entrees_produits"] == [2, 4]


def test_lots_memoire_gardee_si_la_passe_echoue(tmp_path):
    source = SourceFactice({"entrées_produits": [{"id": 2, "stock": 5}]})
    etat = Etat(tmp_path / "e.json")
    etat.lots_en_stock["entrees_produits"] = [2, 3]
    with pytest.raises(LotRejete):
        _passe_lots(source, ClientQuiRefuse(), etat)
    assert etat.lots_en_stock["entrees_produits"] == [2, 3]


def test_memoire_des_lots_persistee(tmp_path):
    chemin = tmp_path / "e.json"
    etat = Etat(chemin)
    etat.lots_en_stock["entrees_produits"] = [2, 3]
    etat.enregistrer()
    assert Etat(chemin).lots_en_stock == {"entrees_produits": [2, 3]}


def test_stock_recalcule_cote_serveur_apres_la_passe(tmp_path):
    source = SourceFactice({t.source: [{"id": 1}] for t in TABLES} | {"instance_produits_trt": []})
    client = ClientFactice()
    passe(source, client, Etat(tmp_path / "e.json"), 500, 12)
    assert client.rafraichissements == 1
