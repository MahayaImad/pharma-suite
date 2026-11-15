"""Module commandes : proposition, brouillons, validation, bon — base de test (_test).

Jeu de données, au jeudi 2026-11-12 (livraison à 24 h → dimanche 15) :

    1 ALPHA    grossiste 1 (pharma)   4 / jour ouvert, stock 2   → proposé
    2 BETA     grossiste 1, psychotrope, 1 / jour, stock 0       → psychotropes
    3 GAMMA    grossiste 2 (para)     2 / jour ouvert, stock 0   → proposé
    4 DELTA    grossiste 3 (non réglé) 1 / jour, stock 0          → sans fournisseur
    5 EPSILON  grossiste 1            1 / jour, stock 100        → rien
"""
from __future__ import annotations

from datetime import date

import pytest
import pytest_asyncio
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.pool import NullPool

from app.core.config import settings
from app.core.database import get_db
from app.core.security import get_current_user
from app.modules.commandes import service
from app.modules.commandes.router import router

JEUDI = date(2026, 11, 12)
utilisateur = {"username": "titulaire", "role": "admin"}
TABLES = ("commandes_lignes", "commandes", "fournisseurs_commande", "commandes_valideurs", "fournisseurs",
          "sorties_produits", "entrees_produits", "nomenclature", "familles", "sync_status",
          "historique_stock_jour", "produits_consommables", "gardes", "generiques_groupes", "generiques_choix")


@pytest_asyncio.fixture
async def api(monkeypatch):
    if not settings.db_name.endswith("_test"):
        pytest.skip("base de test absente (DB_NAME doit se terminer par _test)")
    engine = create_async_engine(settings.database_url, poolclass=NullPool)
    try:
        async with engine.connect() as cnx:
            await cnx.execute(text("SELECT 1"))
    except Exception as erreur:
        await engine.dispose()
        pytest.skip(f"base de test injoignable : {str(erreur).splitlines()[0][:80]}")
    monkeypatch.setattr(service, "aujourdhui", lambda: JEUDI)
    service.vider_cache()
    async with AsyncSession(engine, expire_on_commit=False) as db:
        await db.execute(text(f"TRUNCATE {', '.join(TABLES)} RESTART IDENTITY"))
        for i, nom in ((1, "GROSSISTE A"), (2, "PARA B"), (3, "ANCIEN C")):
            await db.execute(text("INSERT INTO fournisseurs (id, fournisseur, mobile, delai_livraison) "
                                  "VALUES (:i, :n, '0550000000', 1)"), {"i": i, "n": nom})
        await db.execute(text("INSERT INTO fournisseurs_commande (id_fournisseur, type, whatsapp, modifie_par) "
                              "VALUES (1, 'pharma', '213550111111', 'titulaire'), (2, 'para', NULL, 'titulaire')"))
        produits = [  # id, nom, psychotrope, fournisseur, stock, vente par jour ouvert
            (1, "ALPHA", 0, 1, 2, 4), (2, "BETA", 1, 1, 0, 1), (3, "GAMMA", 0, 2, 0, 2),
            (4, "DELTA", 0, 3, 0, 1), (5, "EPSILON", 0, 1, 100, 1)]
        for i, nom, psy, f, stock, vente in produits:
            await db.execute(text(
                "INSERT INTO nomenclature (id, nom, psychotrope, archive, segment_abc, desactiv_alrt_rup) "
                "VALUES (:i, :nom, :psy, false, 'A', 0)"), {"i": i, "nom": nom, "psy": psy})
            await db.execute(text(
                "INSERT INTO entrees_produits (id, id_nom, id_fournisseur, date_entree, stock, qte_entree, "
                "prix_achat, prix_vente) VALUES (:i, :i, :f, CAST(:j AS date) - 400, :s, 500, 100, 150)"),
                {"i": i, "f": f, "s": stock, "j": JEUDI})
            await db.execute(text("""
                INSERT INTO sorties_produits (id, id_nom, id_produit, date, qte_sortie, prix_vente, type_sortie)
                SELECT :i * 10000 + k, :i, :i, CAST(:j AS date) - k, :v, 150, 'V'
                FROM generate_series(1, 400) k WHERE extract(isodow FROM CAST(:j AS date) - k) <> 5
            """), {"i": i, "v": vente, "j": JEUDI})
        await db.execute(text("REFRESH MATERIALIZED VIEW mv_stock_produits"))
        await db.execute(text("INSERT INTO sync_status (table_name, last_id, total_synced, last_sync_at) "
                              "VALUES ('mv_stock_produits', 0, 0, now())"))
        await db.execute(text("UPDATE reglages_stock SET valeur = 0 WHERE cle = 'budget_mensuel_commandes'"))
        await db.commit()

        app = FastAPI()
        app.include_router(router)

        async def _db():
            yield db

        app.dependency_overrides[get_db] = _db
        app.dependency_overrides[get_current_user] = lambda: utilisateur
        utilisateur.update(username="titulaire", role="admin")
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://t") as client:
            client.db = db
            yield client
    await engine.dispose()


async def _jour(api, **params):
    r = await api.get("/commandes/jour", params=params)
    assert r.status_code == 200, r.text
    return r.json()["data"]


def _panier(vue, nom):
    return next(p for p in vue["paniers"] if p["fournisseur"]["nom"] == nom)


async def test_proposition_du_soir_par_fournisseur(api):
    vue = await _jour(api)
    assert vue["jour"] == "2026-11-12" and not vue["ferme"] and vue["peut_valider"]
    assert [p["fournisseur"]["nom"] for p in vue["paniers"]] == ["GROSSISTE A", "PARA B"]
    a = _panier(vue, "GROSSISTE A")
    assert a["commande"] is None and a["livraison_prevue"] == "2026-11-15"   # jeudi → dimanche
    assert [l["nom"] for l in a["lignes"]] == ["ALPHA"]
    alpha = a["lignes"][0]
    r = alpha["raison"]
    assert r["rythme"] == pytest.approx(4.0) and r["stock"] == 2
    manque = r["cible"] - r["stock"] - r["en_cours"]          # raison arrondie à 0,01
    assert alpha["qte"] == alpha["qte_proposee"] and manque - 0.01 <= alpha["qte"] < manque + 1.01
    assert alpha["montant"] == pytest.approx(100 * alpha["qte"])
    assert _panier(vue, "PARA B")["fournisseur"]["type"] == "para"
    assert [l["nom"] for l in vue["psychotropes"]] == ["BETA"]
    assert [l["nom"] for l in vue["sans_fournisseur"]] == ["DELTA"]
    assert vue["budget"]["reste"] is None


async def test_pas_de_commande_le_vendredi(api):
    vue = await _jour(api, jour="2026-11-13")
    assert vue["ferme"] and vue["paniers"] == []


async def test_preparer_corriger_valider_envoyer(api):
    r = await api.post("/commandes/preparer")
    assert r.status_code == 200, r.text
    vue = r.json()["data"]
    a = _panier(vue, "GROSSISTE A")
    assert a["commande"]["statut"] == "brouillon" and a["commande"]["cree_par"] == "titulaire"
    qte_alpha = a["lignes"][0]["qte"]
    again = (await api.post("/commandes/preparer")).json()["data"]   # idempotent
    assert _panier(again, "GROSSISTE A")["commande"]["id"] == a["commande"]["id"]
    id_c = a["commande"]["id"]

    assert (await api.put(f"/commandes/{id_c}/lignes/5", json={"qte": 3})).status_code == 200
    assert (await api.put(f"/commandes/{id_c}/lignes/1", json={"qte": qte_alpha + 2})).status_code == 200
    lignes = {l["nom"]: l for l in _panier(await _jour(api), "GROSSISTE A")["lignes"]}
    assert lignes["EPSILON"]["qte"] == 3 and lignes["EPSILON"]["qte_proposee"] is None
    assert (lignes["ALPHA"]["qte"], lignes["ALPHA"]["qte_proposee"]) == (qte_alpha + 2, qte_alpha)

    utilisateur.update(username="karim", role="employee")
    r = await api.post(f"/commandes/{id_c}/valider")
    assert (r.status_code, r.json()["error"]["code"]) == (403, "interdit")
    utilisateur.update(username="titulaire", role="admin")
    assert (await api.post("/commandes/reglages/valideurs", json={"username": "karim"})).status_code == 200
    utilisateur.update(username="karim", role="employee")
    assert (await api.post(f"/commandes/{id_c}/valider")).status_code == 200
    r = await api.put(f"/commandes/{id_c}/lignes/1", json={"qte": 1})
    assert (r.status_code, r.json()["error"]["code"]) == (409, "statut")    # validée : figée

    r = await api.post(f"/commandes/{id_c}/envoyer")
    assert r.status_code == 200
    bon = r.json()["data"]
    assert bon["whatsapp"] == "213550111111"
    assert f"ALPHA — {qte_alpha + 2}" in bon["texte"] and "EPSILON — 3" in bon["texte"]
    assert "jeudi 12/11/2026" in bon["texte"] and "DA" not in bon["texte"]
    a = _panier(await _jour(api), "GROSSISTE A")
    assert (a["commande"]["statut"], a["commande"]["valide_par"]) == ("envoyee", "karim")

    # Samedi : la commande de jeudi (livrée dimanche) est en cours.
    samedi = await _jour(api, jour="2026-11-14")
    alpha = next((l for p in samedi["paniers"] for l in p["lignes"] if l["nom"] == "ALPHA"), None)
    if alpha is not None:
        assert alpha["raison"]["en_cours"] == qte_alpha + 2


async def test_budget_du_mois(api):
    await api.db.execute(text("UPDATE reglages_stock SET valeur = 100000 WHERE cle = 'budget_mensuel_commandes'"))
    await api.db.execute(text(
        "INSERT INTO entrees_produits (id, id_nom, id_fournisseur, date_entree, stock, qte_entree, prix_achat) "
        "VALUES (99, 1, 1, '2026-11-02', 0, 10, 250)"))   # 2 500 DA reçus ce mois
    await api.db.commit()
    b = (await _jour(api))["budget"]
    assert float(b["budget"]) == 100000 and float(b["recu"]) == 2500
    assert float(b["reste"]) == 97500 and float(b["propose"]) > 0


async def test_reglage_fournisseur_reserve_au_titulaire(api):
    utilisateur.update(username="karim", role="employee")
    r = await api.put("/commandes/reglages/fournisseurs/3", json={"type": "pharma", "actif": True})
    assert r.status_code == 403
    utilisateur.update(username="titulaire", role="admin")
    assert (await api.put("/commandes/reglages/fournisseurs/3", json={"type": "pharma", "actif": True})).status_code == 200
    service.vider_cache()
    vue = await _jour(api)
    assert vue["sans_fournisseur"] == [] and "ANCIEN C" in [p["fournisseur"]["nom"] for p in vue["paniers"]]
    fs = (await api.get("/commandes/reglages/fournisseurs")).json()["data"]
    assert [(f["nom"], f["actif"], f["auto"]) for f in fs] == [
        ("ANCIEN C", True, False), ("GROSSISTE A", True, False), ("PARA B", True, False)]


async def test_fournisseur_sans_commande_depuis_30_jours_inactif_par_defaut(api):
    fs = {f["nom"]: f for f in (await api.get("/commandes/reglages/fournisseurs")).json()["data"]}
    assert (fs["ANCIEN C"]["actif"], fs["ANCIEN C"]["auto"]) == (False, True)   # dernière livraison il y a 400 j
    assert fs["ANCIEN C"]["whatsapp"] == "0550000000"                            # mobile EASYPHARM par défaut
    assert list(fs)[-1] == "ANCIEN C"                                            # inactifs en dernier
    await api.db.execute(text(
        "INSERT INTO entrees_produits (id, id_nom, id_fournisseur, date_entree, stock, qte_entree, prix_achat) "
        "VALUES (98, 4, 3, '2026-11-01', 0, 5, 100)"))   # livré il y a 11 jours
    await api.db.commit()
    fs = {f["nom"]: f for f in (await api.get("/commandes/reglages/fournisseurs")).json()["data"]}
    assert (fs["ANCIEN C"]["actif"], fs["ANCIEN C"]["auto"]) == (True, True)


async def test_le_vendredi_on_prepare_la_commande_du_samedi(api, monkeypatch):
    monkeypatch.setattr(service, "aujourdhui", lambda: date(2026, 11, 13))
    vue = await _jour(api)
    assert vue["jour"] == "2026-11-14" and not vue["ferme"] and vue["paniers"]
    r = await api.post("/commandes/preparer")
    assert r.status_code == 200 and _panier(r.json()["data"], "GROSSISTE A")["commande"]["jour"] == "2026-11-14"


async def test_generiques_ains_une_marque_gardee_reprend_la_demande_de_l_autre(api):
    """ALPHA (4/j) et EPSILON (1/j) : même DCI d'AINS (04B044), 1 marque
    gardée. EPSILON épuisé n'est plus proposé ; ALPHA reprend sa demande."""
    await api.db.execute(text("UPDATE nomenclature SET de_equiv = CASE id WHEN 1 THEN '04B044' ELSE '04 B 044' END "
                              "WHERE id IN (1, 5)"))
    await api.db.execute(text("UPDATE entrees_produits SET stock = 0 WHERE id_nom = 5"))
    await api.db.execute(text("REFRESH MATERIALIZED VIEW mv_stock_produits"))
    await api.db.execute(text("UPDATE reglages_stock SET valeur = 1 WHERE cle = 'generiques_gardes'"))
    await api.db.commit()
    try:
        vue = await _jour(api)
        lignes = {l["nom"]: l for p in vue["paniers"] for l in p["lignes"]}
        assert "EPSILON" not in lignes
        assert lignes["ALPHA"]["raison"]["reprend"] == ["EPSILON"]
        assert lignes["ALPHA"]["raison"]["rythme"] == pytest.approx(5.0)

        g = (await api.get("/commandes/generiques/1")).json()["data"]
        assert (g["code"], g["classe"], g["mode"], g["chronique"]) == ("04B044", "04B", "quelques", False)
        assert [(x["nom"], x["garde"]) for x in g["membres"]] == [("ALPHA", True), ("EPSILON", False)]

        # Le titulaire force « toutes les marques » : EPSILON est de nouveau proposé.
        r = await api.put("/commandes/generiques/1/mode", json={"mode": "toutes"})
        assert r.status_code == 200 and r.json()["data"]["mode"] == "toutes"
        lignes = {l["nom"] for p in (await _jour(api))["paniers"] for l in p["lignes"]}
        assert "EPSILON" in lignes

        utilisateur.update(username="karim", role="employee")
        r = await api.put("/commandes/generiques/5/choix", json={"choix": "exclure"})
        assert r.status_code == 403
    finally:
        await api.db.execute(text("UPDATE reglages_stock SET valeur = 2 WHERE cle = 'generiques_gardes'"))
        await api.db.execute(text("TRUNCATE generiques_groupes, generiques_choix"))
        await api.db.commit()


async def test_generiques_classe_chronique_toutes_les_marques(api):
    """Même chose en classe 14A (antidiabétiques, chronique) : rien n'est retiré."""
    await api.db.execute(text("UPDATE nomenclature SET de_equiv = '14A224' WHERE id IN (1, 5)"))
    await api.db.execute(text("UPDATE entrees_produits SET stock = 0 WHERE id_nom = 5"))
    await api.db.execute(text("REFRESH MATERIALIZED VIEW mv_stock_produits"))
    await api.db.commit()
    lignes = {l["nom"]: l for p in (await _jour(api))["paniers"] for l in p["lignes"]}
    assert "EPSILON" in lignes and "reprend" not in lignes["ALPHA"]["raison"]
    g = (await api.get("/commandes/generiques/1")).json()["data"]
    assert (g["mode"], g["chronique"]) == ("toutes", True)
