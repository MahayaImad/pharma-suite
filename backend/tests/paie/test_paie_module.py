"""Module paie sur la base de test (_test) : brut du mois, heures sup, bulletins versionnés.

Novembre 2026 : 30 jours, vendredis 6, 13, 20, 27 → 26 jours ouvrés.
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

from app.core.config import settings
from app.core.database import get_db
from app.core.security import get_current_user
from app.modules.paie.router import router

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
        await db.execute(text("TRUNCATE performance_mensuelle, employes, paie_heures_sup, paie_bulletins, "
                              "presences_overrides, demandes_conge RESTART IDENTITY CASCADE"))
        await db.execute(text("DELETE FROM sorties WHERE utilisateur IN ('ana', 'chafia')"))
        await db.execute(text("""
            INSERT INTO employes (username, nom, prenom, poste, poste_code, date_entree, actif, eligible_prime) VALUES
            ('ana', 'Benali', 'Ana', 'Caissière', 'caissier', DATE '2020-09-01', true, true),
            ('chafia', 'Saidi', 'Chafia', 'Préparatrice', 'preparateur', DATE '2026-11-16', true, true),
            ('nadir', 'Kaci', 'Nadir', 'Stagiaire', NULL, NULL, true, true)
        """))
        # ana vend tous les jours ouvrés sauf le 10 (absente) et le 1er novembre (férié).
        await db.execute(text("""
            INSERT INTO sorties (id, date, heure, utilisateur, type)
            SELECT 900000 + k, DATE '2026-10-31' + k, '08:30', 'ana', 'V' FROM generate_series(2, 30) k
            WHERE k <> 10 AND extract(isodow FROM DATE '2026-10-31' + k) <> 5
        """))
        await db.execute(text("""
            INSERT INTO performance_mensuelle (employe_id, annee, mois, prime_calculee, valide)
            SELECT id, 2026, 11, 12345.67, false FROM employes WHERE username = 'ana'
        """))
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


async def _mois(api):
    r = await api.get("/paie/2026/11")
    assert r.status_code == 200, r.text
    return {l["employe"]["prenom"]: l for l in r.json()["data"]["employes"]}


async def test_brut_du_mois_part_fixe_et_prime(api):
    m = await _mois(api)
    ana = m["Ana"]
    lignes = {l["code"]: Decimal(str(l["montant"])) for l in ana["lignes"]}
    # 24 jours présents (26 ouvrés − 1er novembre férié − absente le 10), 6 ans d'ancienneté.
    assert ana["jours"] == {"mois": 30, "contrat": 30, "presence": 24, "absences": 1, "a_confirmer": 0}
    assert lignes == {"salaire_base": Decimal("40000.00"), "anciennete": Decimal("6000.00"),
                      "transport": Decimal("7200.00"), "panier": Decimal("14400.00"),
                      "heures_sup": Decimal("0.00"), "retenue_absences": Decimal("-1333.33")}
    assert Decimal(str(ana["part_fixe"])) == Decimal("66266.67")
    assert Decimal(str(ana["brut"])) == Decimal("78612.34")      # + prime de rendement 12 345,67
    assert ana["a_verifier"] == []

    # chafia arrivée le 16, préparatrice : prorata, jours sans vente à confirmer, pas de prime calculée.
    chafia = m["Chafia"]
    assert chafia["jours"]["contrat"] == 15 and chafia["jours"]["a_confirmer"] == 13
    assert {l["code"]: l["montant"] for l in chafia["lignes"]}["salaire_base"] == 17500.0
    assert any("à confirmer" in a for a in chafia["a_verifier"])
    assert any("pas encore calculée" in a for a in chafia["a_verifier"])
    # nadir sans poste ni date d'entrée : signalé.
    assert any("Poste à renseigner" in a for a in m["Nadir"]["a_verifier"])


async def test_heures_sup_saisies_au_quart_d_heure(api):
    ana_id = (await _mois(api))["Ana"]["employe"]["id"]
    r = await api.put(f"/paie/2026/11/heures-sup/{ana_id}", json={"heures": "10.1", "note": "inventaire"})
    assert r.status_code == 200 and r.json()["data"]["heures"] == 10.0
    ana = (await _mois(api))["Ana"]
    assert {l["code"]: l["montant"] for l in ana["lignes"]}["heures_sup"] == 3461.61
    await api.put(f"/paie/2026/11/heures-sup/{ana_id}", json={"heures": 0})
    assert (await _mois(api))["Ana"]["heures_sup"] == 0.0


async def test_corriger_la_fiche_puis_valider_deux_fois(api):
    m = await _mois(api)
    nadir = m["Nadir"]["employe"]["id"]
    assert (await api.put(f"/paie/employes/{nadir}", json={"poste_code": "inconnu"})).status_code == 422
    assert (await api.put(f"/paie/employes/{nadir}", json={"poste_code": "caissier",
                                                           "date_entree": "2025-01-01"})).status_code == 200
    assert (await _mois(api))["Nadir"]["employe"]["poste_code"] == "caissier"

    r = await api.post("/paie/2026/11/valider")
    assert r.status_code == 200 and r.json()["data"]["bulletins"] == 3
    ana = (await _mois(api))["Ana"]
    assert ana["bulletin"]["version"] == 1 and ana["bulletin"]["a_jour"]
    # Après une correction, le bulletin validé n'est plus à jour ; revalider crée la version 2.
    await api.put(f"/paie/2026/11/heures-sup/{ana['employe']['id']}", json={"heures": 2})
    assert not (await _mois(api))["Ana"]["bulletin"]["a_jour"]
    await api.post("/paie/2026/11/valider")
    v = (await api.get(f"/paie/2026/11/bulletins/{ana['employe']['id']}")).json()["data"]
    assert [b["version"] for b in v] == [2, 1] and v[0]["brut"] > v[1]["brut"]
    assert v[1]["detail"]["lignes"][-1]["code"] == "part_variable"


async def test_reserve_au_titulaire(api):
    utilisateur.update(username="karim", role="employee")
    r = await api.get("/paie/2026/11")
    assert r.status_code == 403 and "titulaire" in r.json()["error"]["message"]
    assert (await api.post("/paie/2026/11/valider")).status_code == 403
