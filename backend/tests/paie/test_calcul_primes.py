"""Calcul des primes du mois, de bout en bout sur la base de test (_test).

Les KPIs et l'enveloppe sont simulés : on vérifie l'enchaînement — scores,
répartition en Decimal, enregistrement dans performance_mensuelle.
"""
from __future__ import annotations

from decimal import Decimal

import pytest
import pytest_asyncio
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.pool import NullPool

from app.api.v1 import performance
from app.core.config import settings
from app.core.database import get_db
from app.core.security import get_current_user

KPIS = {"ana": {"ca_realise": 300000, "nb_ventes": 400}, "brahim": {"ca_realise": 100000, "nb_ventes": 600}}


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

    async def kpis(db, username, annee, mois):
        return dict(KPIS[username])

    async def enveloppe(db, annee, mois):
        return Decimal("50000.00")

    monkeypatch.setattr(performance, "_calc_kpis_employe", kpis)
    monkeypatch.setattr(performance, "_calc_enveloppe_prime", enveloppe)
    async with AsyncSession(engine, expire_on_commit=False) as db:
        await db.execute(text("TRUNCATE performance_mensuelle, employes RESTART IDENTITY CASCADE"))
        await db.execute(text("""
            INSERT INTO employes (username, nom, poste, actif, eligible_prime) VALUES
            ('ana', 'Ana', 'Caissier', true, true), ('brahim', 'Brahim', 'Caissier', true, true),
            ('vente', 'VENTE', NULL, true, false)
        """))
        await db.execute(text("UPDATE kpi_definitions SET actif = false"))
        await db.execute(text("UPDATE kpi_definitions SET actif = true, poids = 20 WHERE code = 'ca_realise'"))
        await db.execute(text("UPDATE kpi_definitions SET actif = true, poids = 12 WHERE code = 'nb_ventes'"))
        await db.commit()
        app = FastAPI()
        app.include_router(performance.router)

        async def _db():
            yield db

        app.dependency_overrides[get_db] = _db
        app.dependency_overrides[get_current_user] = lambda: {"username": "titulaire", "role": "admin"}
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://t") as client:
            client.db = db
            yield client
    await engine.dispose()


async def _presences(api, jours: dict[str, int]):
    """Une vente par jour de présence, du 1er au N octobre 2026, pour chaque vendeur."""
    await api.db.execute(text("DELETE FROM sorties WHERE utilisateur IN ('ana', 'brahim')"))
    for u, n in jours.items():
        await api.db.execute(text("""
            INSERT INTO sorties (id, date, heure, utilisateur, type)
            SELECT (SELECT COALESCE(max(id), 0) FROM sorties) + k, DATE '2026-10-01' + k - 1, '08:30', :u, 'V'
            FROM generate_series(1, :n) k
        """), {"u": u, "n": n})
    await api.db.commit()


async def test_primes_du_mois_en_decimal_et_somme_exacte(api):
    await _presences(api, {"ana": 20, "brahim": 20})
    r = await api.post("/performance/primes/2026/10/calculer")
    assert r.status_code == 200, r.text
    d = r.json()
    assert d["nb_employes"] == 2
    # ana : 3/4 × 20 + 2/5 × 12 = 19,8 ; brahim : 1/4 × 20 + 3/5 × 12 = 12,2 ; total 32.
    # Plancher : 50 000 ÷ 2 × 50 % = 12 500 chacun ; reste 25 000 au mérite.
    primes = {x["username"]: Decimal(str(x["prime_calculee"])) for x in d["resultats"]}
    assert primes == {"ana": Decimal("27968.75"), "brahim": Decimal("22031.25")}
    assert {x["username"]: x["plancher"] for x in d["resultats"]} == {"ana": 12500.0, "brahim": 12500.0}
    lignes = (await api.db.execute(text(
        "SELECT e.username, p.prime_calculee, p.score_global, p.kpis FROM performance_mensuelle p "
        "JOIN employes e ON e.id = p.employe_id ORDER BY e.username"))).all()
    assert sum(l.prime_calculee for l in lignes) == Decimal("50000.00")
    assert lignes[0].score_global == Decimal("19.80") and lignes[0].kpis["ca_realise"]["score"] == "15.000"


async def test_pas_de_plancher_pour_un_employe_absent_tout_le_mois(api):
    await _presences(api, {"ana": 20, "brahim": 0})
    KPIS_AVANT = dict(KPIS)
    KPIS["brahim"] = {"ca_realise": 0, "nb_ventes": 0}
    try:
        d = (await api.post("/performance/primes/2026/10/calculer")).json()
    finally:
        KPIS.update(KPIS_AVANT)
    r = {x["username"]: x for x in d["resultats"]}
    # Seule ana est présente : plancher 50 000 × 50 % = 25 000, plus tout le mérite.
    assert r["ana"]["prime_calculee"] == 50000.0 and r["brahim"]["prime_calculee"] == 0.0
