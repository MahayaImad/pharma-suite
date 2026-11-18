"""Catégories de prime : sur la base de test (DB_NAME en *_test), sinon ignoré."""
from __future__ import annotations

from decimal import Decimal

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
from app.modules.categories.router import router

utilisateur: dict = {}


async def _nettoyer(db) -> None:
    await db.execute(text("DELETE FROM sorties_produits WHERE id BETWEEN 980001 AND 980010"))
    await db.execute(text("DELETE FROM sorties WHERE id = 980000"))
    await db.execute(text("DELETE FROM entrees_produits WHERE id BETWEEN 980001 AND 980010"))
    await db.execute(text("DELETE FROM nomenclature WHERE id BETWEEN 980001 AND 980010"))
    await db.execute(text("DELETE FROM laboratoires WHERE id BETWEEN 980001 AND 980010"))
    await db.execute(text("DELETE FROM categories_classements"))
    await db.execute(text("UPDATE nomenclature SET categorie = NULL, categorie_manuelle = false"))
    await db.execute(text("UPDATE reglages_stock SET valeur = 50 WHERE cle = 'categories_seuil_generique_plus'"))
    await db.commit()


@pytest_asyncio.fixture
async def api():
    if not settings.db_name.endswith("_test"):
        pytest.skip("base de test absente (DB_NAME doit se terminer par _test)")
    engine = create_async_engine(settings.database_url, poolclass=NullPool)
    try:
        async with engine.connect() as cnx:
            await cnx.execute(text("SELECT 1"))
    except Exception as erreur:
        await engine.dispose()
        pytest.skip(f"base de test injoignable : {str(erreur).splitlines()[0][:80]}")
    async with AsyncSession(engine, expire_on_commit=False) as db:
        await _nettoyer(db)
        await db.execute(text("""
            INSERT INTO laboratoires (id, labo, is_generique) VALUES
            (980001, 'Numidia Pharma', false), (980002, 'Atlas Santé', false), (980003, 'Medisud', false)
        """))
        # 1 : générique (labo Numidia) · 2 : marge 60 % · 3 : princeps · 4 : classé à la main · 5 : déjà princeps
        await db.execute(text("""
            INSERT INTO nomenclature (id, nom, labo, categorie, categorie_manuelle) VALUES
            (980001, 'Metfor', 'NUMIDIA PHARMA ', NULL, false), (980002, 'Vitamine', 'Medisud', NULL, false),
            (980003, 'Doli', 'Atlas Santé', NULL, false), (980004, 'Lait', NULL, 'generique', true),
            (980005, 'Ancien', 'Numidia Pharma', 'princeps', false)
        """))
        await db.execute(text("""
            INSERT INTO entrees_produits (id, id_nom, prix_achat, prix_vente, stock, qte_entree, date_entree) VALUES
            (980001, 980002, 100, 160, 10, 10, CURRENT_DATE), (980002, 980003, 100, 120, 5, 5, CURRENT_DATE),
            (980003, 980001, 100, 130, 0, 20, CURRENT_DATE - 30)
        """))
        await db.execute(text("INSERT INTO sorties (id, date, type) VALUES (980000, DATE '2031-04-07', 'V')"))
        await db.execute(text("""
            INSERT INTO sorties_produits (id, id_sortie, id_nom, qte_sortie, prix_vente) VALUES
            (980001, 980000, 980001, 1, 20000), (980002, 980000, 980002, 1, 10000),
            (980003, 980000, 980003, 1, 40000), (980004, 980000, 980004, 1, 5000)
        """))
        await db.commit()
        app = FastAPI()
        app.include_router(router)

        async def _db():
            yield db

        app.dependency_overrides[get_db] = _db
        app.dependency_overrides[get_current_user] = lambda: utilisateur
        utilisateur.clear()
        utilisateur.update(username="titulaire", role="admin")
        try:
            async with AsyncClient(transport=ASGITransport(app=app), base_url="http://t") as client:
                yield client
        finally:
            await _nettoyer(db)
    await engine.dispose()


def _par_cat(data):
    return {c["categorie"]: c for c in data["categories"]}


async def test_enveloppe_du_mois_sans_categorie_au_taux_princeps(api):
    r = await api.get("/categories/2031/4")
    assert r.status_code == 200, r.text
    d = r.json()["data"]
    c = _par_cat(d)
    assert c[None]["ca"] == 70000 and c[None]["produits"] == 3 and c[None]["taux_pct"] == 0.5
    assert c["generique"]["ca"] == 5000 and c["generique"]["montant"] == 50
    # 70 000 × 0,5 % + 5 000 × 1 %
    assert d["enveloppe"] == 400 and d["ca"] == 75000
    assert d["seuil_marge"] == 50 and d["dernier_classement"] is None


async def test_laboratoires_tries_par_ca_et_marques_generiques(api):
    r = await api.get("/categories/2031/4/laboratoires", params={"limite": 2})
    d = r.json()["data"]
    assert [l["labo"] for l in d["laboratoires"]] == ["Atlas Santé", "Numidia Pharma"] and d["total"] >= 3
    assert d["laboratoires"][1]["produits"] == 2 and d["laboratoires"][0]["part_ca"] == 53.3
    r = await api.put("/categories/laboratoires/980001", json={"generique": True})
    assert r.status_code == 200
    d = (await api.get("/categories/2031/4/laboratoires", params={"q": "numid"})).json()["data"]
    assert d["laboratoires"][0]["is_generique"] is True and d["total"] == 1


async def test_classer_respecte_les_choix_a_la_main(api):
    await api.put("/categories/laboratoires/980001", json={"generique": True})
    r = await api.post("/categories/classer", json={"seuil_marge": 50})
    assert r.status_code == 200, r.text
    db_cat = {p["id"]: p for p in (await api.get("/categories/2031/4/produits")).json()["data"]}
    assert list(db_cat) == [980004]                    # seul reste le choix à la main
    d = (await api.get("/categories/2031/4")).json()["data"]
    c = _par_cat(d)
    assert c["generique++"]["ca"] == 10000 and c["generique"]["ca"] == 25000 and c["princeps"]["ca"] == 40000
    assert d["dernier_classement"]["par"] == "titulaire"
    # 980005 (déjà princeps, labo générique) n'est reclassé qu'avec « tout »
    r = await api.post("/categories/classer", json={"seuil_marge": 70, "tout": True})
    d = r.json()["data"]
    c = _par_cat((await api.get("/categories/2031/4")).json()["data"])
    assert c["generique++"]["ca"] == 0 and c["princeps"]["ca"] == 50000   # marge 60 % sous le seuil de 70
    assert (await api.get("/categories/2031/4")).json()["data"]["seuil_marge"] == 70


async def test_choix_a_la_main_puis_retour_au_classement(api):
    r = await api.put("/categories/produits/980003", json={"categorie": "generique++"})
    assert r.status_code == 200 and r.json()["data"]["manuelle"] is True
    p = {x["id"]: x for x in (await api.get("/categories/2031/4/produits")).json()["data"]}
    assert p[980003]["categorie"] == "generique++" and p[980003]["manuelle"] is True
    assert list(p)[0] == 980003                         # le plus vendu d'abord
    await api.put("/categories/produits/980003", json={"categorie": None})
    p = {x["id"]: x for x in (await api.get("/categories/2031/4/produits")).json()["data"]}
    assert p[980003]["categorie"] is None and p[980003]["manuelle"] is False
    assert (await api.put("/categories/produits/1", json={"categorie": "autre"})).status_code == 422


async def test_reserve_au_titulaire(api):
    utilisateur.update(role="employee")
    r = await api.get("/categories/2031/4")
    assert r.status_code == 403 and r.json()["error"]["code"] == "interdit"
