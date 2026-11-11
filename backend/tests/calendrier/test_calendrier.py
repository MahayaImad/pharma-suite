"""Calendrier : gardes, fêtes, jours fériés — sur la base de test (_test)."""
from __future__ import annotations

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
from app.modules.calendrier.router import router

utilisateur = {"username": "titulaire", "role": "admin"}


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
        await db.execute(text("TRUNCATE gardes, evenements_calendrier, holidays"))
        await db.commit()
        app = FastAPI()
        app.include_router(router)

        async def _db():
            yield db

        app.dependency_overrides[get_db] = _db
        app.dependency_overrides[get_current_user] = lambda: utilisateur
        utilisateur.update(role="admin")
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://t") as client:
            client.db = db
            yield client
    await engine.dispose()


async def test_garde_saisie_corrigee_supprimee(api):
    r = await api.put("/calendrier/gardes/2026-11-17", json={"type": "soiree", "note": "rotation"})
    assert r.status_code == 200
    g = r.json()["data"]
    assert (g["type"], g["source"], g["confirme"], g["modifie_par"]) == ("soiree", "saisie", True, "titulaire")
    assert r.json()["error"] is None
    await api.put("/calendrier/gardes/2026-11-17", json={"type": "24h"})
    gardes = (await api.get("/calendrier/gardes", params={"annee": 2026})).json()["data"]
    assert [(x["date"], x["type"]) for x in gardes] == [("2026-11-17", "24h")]
    assert (await api.delete("/calendrier/gardes/2026-11-17")).status_code == 200
    r = await api.delete("/calendrier/gardes/2026-11-17")
    assert (r.status_code, r.json()["error"]["code"]) == (404, "introuvable")


async def test_confirmer_une_garde_detectee(api):
    """Une garde détectée, enregistrée par l'officine, devient confirmée et
    garde sa source d'origine."""
    await api.db.execute(text(
        "INSERT INTO gardes (date, type, source, confirme) VALUES ('2026-10-28', 'soiree', 'detection', false)"))
    await api.db.commit()
    avant = (await api.get("/calendrier/gardes", params={"annee": 2026})).json()["data"][0]
    assert (avant["source"], avant["confirme"]) == ("detection", False)
    g = (await api.put("/calendrier/gardes/2026-10-28", json={"type": "soiree"})).json()["data"]
    assert (g["source"], g["confirme"]) == ("detection", True)


async def test_fete_dates_controlees_et_verifiee_a_la_saisie(api):
    r = await api.post("/calendrier/evenements",
                       json={"type": "ramadan", "date_debut": "2027-02-08", "date_fin": "2027-03-09"})
    assert r.status_code == 201 and r.json()["data"]["a_verifier"] is False
    id_ = r.json()["data"]["id"]
    r = await api.post("/calendrier/evenements",
                       json={"type": "ramadan", "date_debut": "2027-02-08", "date_fin": "2027-03-09"})
    assert (r.status_code, r.json()["error"]["code"]) == (409, "doublon")
    r = await api.put(f"/calendrier/evenements/{id_}",
                      json={"type": "ramadan", "date_debut": "2027-03-09", "date_fin": "2027-02-08"})
    assert r.json()["error"]["message"] == "La fin est avant le début."
    r = await api.put(f"/calendrier/evenements/{id_}",
                      json={"type": "ramadan", "date_debut": "2027-01-01", "date_fin": "2027-03-01"})
    assert r.status_code == 422
    r = await api.put(f"/calendrier/evenements/{id_}",
                      json={"type": "ramadan", "date_debut": "2027-02-09", "date_fin": "2027-03-10"})
    assert r.json()["data"]["date_debut"] == "2027-02-09"


async def test_jours_feries(api):
    r = await api.post("/calendrier/feries", json={"date": "2027-01-12", "label": "Yennayer"})
    assert r.status_code == 201
    assert (await api.post("/calendrier/feries", json={"date": "2027-01-12", "label": "x"})).status_code == 409
    feries = (await api.get("/calendrier/feries")).json()["data"]
    assert [(f["date"], f["label"]) for f in feries] == [("2027-01-12", "Yennayer")]
    assert (await api.delete(f"/calendrier/feries/{feries[0]['id']}")).status_code == 200


async def test_lecture_pour_tous_ecriture_pour_le_titulaire(api):
    utilisateur.update(role="user")
    assert (await api.get("/calendrier/feries")).status_code == 200
    r = await api.put("/calendrier/gardes/2026-12-01", json={"type": "soiree"})
    assert (r.status_code, r.json()["error"]["code"]) == (403, "interdit")
    assert (await api.post("/calendrier/feries", json={"date": "2027-01-12", "label": "x"})).status_code == 403
