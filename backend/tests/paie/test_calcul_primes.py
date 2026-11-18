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

KPIS = {"ana": {"ca_realise": 300000, "nb_ventes": 400}, "brahim": {"ca_realise": 100000, "nb_ventes": 600},
        "chafia": {"ca_realise": 0, "nb_ventes": 0, "taches_completees": 30}}


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
        await db.execute(text("TRUNCATE performance_mensuelle, primes_calculs, employes RESTART IDENTITY CASCADE"))
        await db.execute(text("""
            INSERT INTO employes (username, nom, poste, actif, eligible_prime) VALUES
            ('ana', 'Ana', 'Caissier', true, true), ('brahim', 'Brahim', 'Caissier', true, true),
            ('vente', 'VENTE', NULL, true, false)
        """))
        await db.execute(text("UPDATE kpi_definitions SET actif = false"))
        await db.execute(text("UPDATE kpi_definitions SET actif = true, poids = 20 WHERE code = 'ca_realise'"))
        await db.execute(text("UPDATE kpi_definitions SET actif = true, poids = 12 WHERE code = 'nb_ventes'"))
        await db.execute(text("UPDATE kpi_definitions SET actif = true WHERE code IN ('taches_completees', 'ponctualite')"))
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


async def _presences(api, jours: dict[str, object]):
    """Une vente par jour de présence en octobre 2026 : un nombre N (du 1er au N)
    ou la liste des jours."""
    await api.db.execute(text("DELETE FROM sorties WHERE utilisateur IN ('ana', 'brahim')"))
    for u, n in jours.items():
        liste = list(range(1, n + 1)) if isinstance(n, int) else list(n)
        await api.db.execute(text("""
            INSERT INTO sorties (id, date, heure, utilisateur, type)
            SELECT (SELECT COALESCE(max(id), 0) FROM sorties) + k, DATE '2026-09-30' + j, '08:30', :u, 'V'
            FROM unnest(CAST(:jours AS int[])) WITH ORDINALITY AS t(j, k)
        """), {"u": u, "jours": liste})
    await api.db.commit()


async def test_primes_du_mois_en_decimal_et_somme_exacte(api):
    await _presences(api, {"ana": 20, "brahim": 20})
    r = await api.post("/performance/primes/2026/10/calculer")
    assert r.status_code == 200, r.text
    d = r.json()
    assert d["nb_employes"] == 2
    # Ponctualité (poids 10) : tous deux à l'heure 17 jours (20 jours de vente moins
    # 3 vendredis), soit 5 points chacun.
    # ana : 3/4 × 20 + 2/5 × 12 + 5 = 24,8 ; brahim : 1/4 × 20 + 3/5 × 12 + 5 = 17,2 ; total 42.
    # Plancher : 50 000 ÷ 2 × 50 % = 12 500 chacun ; reste 25 000 au mérite.
    primes = {x["username"]: Decimal(str(x["prime_calculee"])) for x in d["resultats"]}
    assert primes == {"ana": Decimal("27261.90"), "brahim": Decimal("22738.10")}
    assert {x["username"]: x["plancher"] for x in d["resultats"]} == {"ana": 12500.0, "brahim": 12500.0}
    lignes = (await api.db.execute(text(
        "SELECT e.username, p.prime_calculee, p.score_global, p.kpis FROM performance_mensuelle p "
        "JOIN employes e ON e.id = p.employe_id ORDER BY e.username"))).all()
    assert sum(l.prime_calculee for l in lignes) == Decimal("50000.00")
    assert lignes[0].score_global == Decimal("24.80") and lignes[0].kpis["ca_realise"]["score"] == "15.000"


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


async def _preparatrice(api):
    """chafia, préparatrice : ne vend pas, notée sur ses tâches et sa ponctualité."""
    await api.db.execute(text(
        "INSERT INTO employes (username, nom, poste, poste_code, actif, eligible_prime) "
        "VALUES ('chafia', 'Chafia', 'Préparatrice', 'preparateur', true, true)"))
    await api.db.commit()


async def test_preparatrice_presente_sans_vendre_notee_sur_son_poste(api):
    await _presences(api, {"ana": 20, "brahim": 20})
    await _preparatrice(api)
    d = (await api.post("/performance/primes/2026/10/calculer")).json()
    r = {x["username"]: x for x in d["resultats"]}
    # Ses jours sans vente sont « à confirmer », pas « absent » : elle a le plancher.
    assert r["chafia"]["poste"] == "preparateur" and r["chafia"]["jours_a_confirmer"] == 26
    assert r["chafia"]["plancher"] == 8333.33
    # Seule à faire des tâches, seule à l'heure tous les jours ouvrés : elle a du mérite.
    assert r["chafia"]["merite"] > 0
    assert round(sum(x["prime_calculee"] for x in d["resultats"]), 2) == 50000.0
    kpis = (await api.db.execute(text(
        "SELECT kpis FROM performance_mensuelle p JOIN employes e ON e.id = p.employe_id "
        "WHERE e.username = 'chafia'"))).scalar()
    assert kpis["taches_completees"]["poids"] == "40.00" and kpis["ca_realise"]["poids"] == "0"
    assert kpis["_presence"]["a_confirmer"] == 26


async def test_un_conge_ne_fait_pas_baisser_la_prime(api):
    """Même rythme de vente (10 000 DA par jour), ana en congé du 12 au 23 : même prime que brahim.
    ana : 16 jours présents + 10 de congé ; brahim : 26 jours présents (vendredis exclus)."""
    await _presences(api, {"ana": [*range(1, 12), *range(24, 32)], "brahim": 31})
    await api.db.execute(text("""
        INSERT INTO demandes_conge (employe_id, date_debut, date_fin, nb_jours, statut, type)
        SELECT id, DATE '2026-10-12', DATE '2026-10-23', 10, 'approuve', 'annuel' FROM employes WHERE username = 'ana'
    """))
    await api.db.commit()
    avant = dict(KPIS)
    KPIS["ana"] = {"ca_realise": 160000, "nb_ventes": 480}
    KPIS["brahim"] = {"ca_realise": 260000, "nb_ventes": 780}
    try:
        d = (await api.post("/performance/primes/2026/10/calculer")).json()
    finally:
        KPIS.update(avant)
    r = {x["username"]: x["prime_calculee"] for x in d["resultats"]}
    assert r["ana"] == r["brahim"] == 25000.0


async def test_chaque_recalcul_est_garde(api):
    """Contestation : un recalcul n'efface plus le précédent."""
    await _presences(api, {"ana": 20, "brahim": 20})
    premier = (await api.post("/performance/primes/2026/10/calculer")).json()
    avant = dict(KPIS)
    KPIS["brahim"] = {"ca_realise": 300000, "nb_ventes": 600}
    try:
        second = (await api.post("/performance/primes/2026/10/calculer")).json()
    finally:
        KPIS.update(avant)
    h = (await api.get("/performance/primes/2026/10/historique")).json()
    assert [c["id"] for c in h] == [second["id_calcul"], premier["id_calcul"]]
    ana = lambda c: next(l["prime"] for l in c["lignes"] if l["nom"] == "Ana")  # noqa: E731
    assert ana(h[1]) == 27261.9 and ana(h[0]) < ana(h[1])     # le premier calcul est intact
    assert all(round(sum(l["prime"] for l in c["lignes"]), 2) == 50000.0 for c in h)
    assert h[0]["calcule_par"] == "titulaire"
