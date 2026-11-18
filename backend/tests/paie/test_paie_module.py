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
        await db.execute(text("TRUNCATE performance_mensuelle, primes_calculs, employes, paie_heures_sup, paie_bulletins, "
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


# ── Grille de présence : retard d'après la première vente, fériés du Calendrier ──

from app.api.v1.grh_presence import grille_presence  # noqa: E402


async def _jours_ana(api):
    g = await grille_presence(api.db, 2026, 11)
    return next(e for e in g["employes"] if e["username"] == "ana")["jours"]


async def test_retard_detecte_d_apres_la_premiere_vente(api):
    # Première vente à 9 h 20 le 3 (50 min après 8 h 30) et à 9 h 10 le 4 (40 min : toléré).
    await api.db.execute(text("UPDATE sorties SET heure = '09:20:00' WHERE utilisateur = 'ana' AND date = '2026-11-03'"))
    await api.db.execute(text("UPDATE sorties SET heure = '09:10:00' WHERE utilisateur = 'ana' AND date = '2026-11-04'"))
    await api.db.commit()
    j = await _jours_ana(api)
    assert (j["2026-11-03"]["statut"], j["2026-11-03"]["retard_min"]) == ("retard", 50)
    assert j["2026-11-04"]["statut"] == "present"
    # Retard : payé comme présent (transport, panier), sans retenue.
    ana = (await _mois(api))["Ana"]
    assert ana["jours"]["presence"] == 24 and {l["code"]: l["montant"] for l in ana["lignes"]}["transport"] == 7200

    # Heure de début propre à l'employée : 9 h → le 3 n'est plus un retard.
    await api.db.execute(text("UPDATE employes SET heure_debut = '09:00' WHERE username = 'ana'"))
    await api.db.commit()
    assert (await _jours_ana(api))["2026-11-03"]["statut"] == "present"

    # Une correction du titulaire l'emporte toujours.
    await api.db.execute(text("UPDATE employes SET heure_debut = NULL WHERE username = 'ana'"))
    await api.db.execute(text("""
        INSERT INTO presences_overrides (employe_id, date, statut, created_by)
        SELECT id, DATE '2026-11-03', 'present', 'titulaire' FROM employes WHERE username = 'ana'"""))
    await api.db.commit()
    assert (await _jours_ana(api))["2026-11-03"]["statut"] == "present"


async def test_heure_de_ramadan(api):
    await api.db.execute(text("UPDATE sorties SET heure = '10:00:00' WHERE utilisateur = 'ana' AND date = '2026-11-03'"))
    await api.db.execute(text("UPDATE reglages_stock SET valeur = 570 WHERE cle = 'paie_heure_debut_ramadan'"))
    await api.db.execute(text("""
        INSERT INTO evenements_calendrier (type, date_debut, date_fin) VALUES ('ramadan', '2026-11-03', '2026-11-03')"""))
    await api.db.commit()
    try:
        assert (await _jours_ana(api))["2026-11-03"]["statut"] == "present"     # 9 h 30 + 45 min
    finally:
        await api.db.execute(text("DELETE FROM evenements_calendrier WHERE date_debut = '2026-11-03'"))
        await api.db.execute(text("UPDATE reglages_stock SET valeur = 510 WHERE cle = 'paie_heure_debut_ramadan'"))
        await api.db.commit()


async def test_feries_saisis_dans_le_calendrier_et_aid(api):
    await api.db.execute(text("INSERT INTO holidays (date, label) VALUES ('2026-11-05', 'Jour férié de test')"))
    await api.db.execute(text("""
        INSERT INTO evenements_calendrier (type, date_debut, date_fin) VALUES ('aid_fitr', '2026-11-11', '2026-11-12')"""))
    await api.db.commit()
    try:
        j = await _jours_ana(api)
        assert [j[d]["statut"] for d in ("2026-11-05", "2026-11-11", "2026-11-12")] == ["ferie"] * 3
        # Pas de transport ni de panier ces jours-là, pas de retenue non plus.
        assert (await _mois(api))["Ana"]["jours"]["presence"] == 21
    finally:
        await api.db.execute(text("DELETE FROM holidays WHERE date = '2026-11-05'"))
        await api.db.execute(text("DELETE FROM evenements_calendrier WHERE date_debut = '2026-11-11'"))
        await api.db.commit()


async def test_criteres_du_radar_face_a_la_moyenne(api):
    """Après un calcul des primes, chaque employé a ses critères et son indice (100 = moyenne)."""
    await api.db.execute(text(
        "INSERT INTO primes_calculs (id, annee, mois, enveloppe, calcule_par) VALUES (1, 2026, 11, 50000, 't')"))
    await api.db.execute(text("""
        INSERT INTO primes_calculs_lignes (id_calcul, employe_id, kpis, score_global, plancher, merite, prime)
        SELECT 1, id, CASE username
            WHEN 'ana' THEN '{"ca_realise": {"valeur": 300, "valeur_retenue": "300.00", "poids": "20.00"},
                              "nb_ventes": {"valeur": 10, "valeur_retenue": "10.00", "poids": "0"},
                              "_presence": {"a_confirmer": 0}}'
            ELSE '{"ca_realise": {"valeur": 100, "valeur_retenue": "100.00", "poids": "20.00"}}' END::jsonb,
            1, 12500, CASE username WHEN 'ana' THEN 20000 ELSE 5000 END,
            CASE username WHEN 'ana' THEN 32500 ELSE 17500 END
        FROM employes WHERE username IN ('ana', 'chafia');
    """))
    await api.db.commit()
    m = await _mois(api)
    p = m["Ana"]["prime"]
    assert (p["plancher"], p["merite"]) == (12500.0, 20000.0)
    assert [(c["code"], c["indice"], c["libelle"]) for c in p["criteres"]] == [("ca_realise", 150, "CA réalisé")]
    assert m["Chafia"]["prime"]["criteres"][0]["indice"] == 50
    assert m["Nadir"]["prime"] is None


async def test_importer_depuis_easypharm_et_retirer_de_la_paie(api):
    await api.db.execute(text("DELETE FROM groupware WHERE id IN (901, 902, 903)"))
    await api.db.execute(text("""
        INSERT INTO groupware (id, utilisateur, nom, prenom, actif) VALUES
        (901, 'ana', 'Benali', 'Ana', 1), (902, 'samir', 'Haddad', 'Samir', 1), (903, 'VENTE', NULL, NULL, 1)
    """))
    await api.db.commit()
    try:
        r = await api.post("/paie/employes/importer")
        assert r.status_code == 200 and r.json()["data"]["employes"] == 3
        m = await _mois(api)
        assert m["Samir"]["employe"]["poste_code"] is None and "VENTE" not in [x["employe"]["nom"] for x in m.values()]
        assert m["Ana"]["employe"]["poste_code"] == "caissier"          # la fiche existante garde son poste
        samir = m["Samir"]["employe"]["id"]
        r = await api.put(f"/paie/employes/{samir}", json={"eligible_prime": False})
        assert r.status_code == 200 and "Samir" not in await _mois(api)
        r = await api.put(f"/paie/employes/{m['Ana']['employe']['id']}", json={"heure_debut": "09:00"})
        assert (await _mois(api))["Ana"]["employe"]["heure_debut"] == "09:00:00"
    finally:
        await api.db.execute(text("DELETE FROM groupware WHERE id IN (901, 902, 903)"))
        await api.db.commit()
