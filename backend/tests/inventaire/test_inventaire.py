"""Inventaire tournant sur base de test : liste du jour figée, comptage, écarts à corriger."""
from sqlalchemy import text

from tests.commandes.test_module_commandes import JEUDI, api, utilisateur  # noqa: F401


async def _jour(api):
    r = await api.get("/inventaire/jour")
    assert r.status_code == 200, r.text
    return r.json()["data"]


async def _vider(api):
    pass


async def test_liste_figee_comptage_et_ecart_a_corriger(api):
    await _vider(api)
    j = await _jour(api)
    # Produits actifs, hors psychotrope (BETA) ; ruptures vendues hier (GAMMA, DELTA) suspectes.
    ids = [p["id_nom"] for p in j["a_compter"]]
    assert 2 not in ids and {1, 3, 4, 5} <= set(ids)
    assert next(p for p in j["a_compter"] if p["id_nom"] == 3)["raison"].startswith("en rupture")
    assert j["progression"] == {"total": len(ids), "comptes": 0, "ecarts": 0}

    # EPSILON : 100 dans EASYPHARM, 97 comptés → écart −3 valorisé au prix d'achat (100 DA).
    r = await api.post("/inventaire/comptages", json={"id_nom": 5, "stock_compte": 97, "cause": "casse"})
    assert r.status_code == 201, r.text
    c = r.json()["data"]
    assert (c["stock_theorique"], c["ecart"], float(c["valeur_ecart"]), c["cause"]) == (100, -3, -300.0, "casse")
    # ALPHA juste : pas de cause gardée.
    juste = (await api.post("/inventaire/comptages", json={"id_nom": 1, "stock_compte": 2, "cause": "vol"})).json()["data"]
    assert (juste["ecart"], juste["cause"]) == (0, None)

    j2 = await _jour(api)
    assert [p["id_nom"] for p in j2["a_compter"]] == [i for i in ids if i not in (1, 5)]   # liste figée
    assert j2["progression"]["comptes"] == 2 and j2["progression"]["ecarts"] == 1
    assert j2["exactitude"]["exactitude_pct"] == 50 and j2["exactitude"]["a_corriger"] == 1
    assert [x["id_nom"] for x in j2["a_corriger"]] == [5]

    # Recompter remplace ; marquer corrigé retire de la liste à corriger.
    c = (await api.post("/inventaire/comptages", json={"id_nom": 5, "stock_compte": 98})).json()["data"]
    assert c["ecart"] == -2
    r = await api.put(f"/inventaire/comptages/{c['id']}/corrige", json={"corrige": True})
    assert r.json()["data"]["corrige"] and r.json()["data"]["corrige_par"] == "titulaire"
    assert (await _jour(api))["a_corriger"] == []
    assert (await api.put(f"/inventaire/comptages/{juste['id']}/corrige", json={"corrige": True})).status_code == 409

    # Annuler un comptage : le produit revient dans la liste.
    assert (await api.delete(f"/inventaire/comptages/{juste['id']}")).status_code == 200
    assert 1 in [p["id_nom"] for p in (await _jour(api))["a_compter"]]


async def test_comptage_hors_liste_et_idempotence(api):
    await _vider(api)
    await _jour(api)
    u = "0b7c4a1e-2f7b-4f43-9c1e-5a3f2e7d9b10"
    a = (await api.post("/inventaire/comptages", json={"id_nom": 2, "stock_compte": 1, "client_uuid": u})).json()["data"]
    b = (await api.post("/inventaire/comptages", json={"id_nom": 2, "stock_compte": 5, "client_uuid": u})).json()["data"]
    assert a["id"] == b["id"] and b["stock_compte"] == 1 and a["dans_la_liste"] is False
    assert (await api.post("/inventaire/comptages", json={"id_nom": 999, "stock_compte": 1})).status_code == 404
    assert (await api.post("/inventaire/comptages", json={"id_nom": 1, "stock_compte": -1})).status_code == 422
