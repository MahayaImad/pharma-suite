"""
Routes de lecture du stock : familles, états, tri, résumé et horodatage.

Jeu de données (stocks et prix choisis pour un calcul à la main) :

    famille 1 Médicaments, 3 Cosmétiques, 9 Compléments (vide)
    1 ALPHA   fam 1  lot 10 u à 100 DA (vente 150)   seuil 5  → en stock
    2 BETA    fam 1  lot  3 u à  50 DA (vente  80)   seuil 5  → sous le seuil
    3 GAMMA   fam 3  aucun lot, vendu il y a 1 mois           → rupture (actif)
    4 DELTA   fam 3  aucun lot, jamais vendu                  → inactif
    5 EPSILON fam 99 (absente de familles) « Ancienne »  lot 2 u à 10 DA
    6 ZETA    fam 1  archivé, lot 100 u                       → hors totaux
"""
from __future__ import annotations

import pytest_asyncio
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient
from sqlalchemy import text

from app.api.v1.stock import router
from app.core.database import get_db
from app.core.security import get_current_user


@pytest_asyncio.fixture
async def api(db):
    app = FastAPI()
    app.include_router(router)

    async def _db():
        yield db

    app.dependency_overrides[get_db] = _db
    app.dependency_overrides[get_current_user] = lambda: {"username": "test", "role": "admin"}

    for i, nom in ((1, "Médicaments"), (3, "Cosmétiques"), (9, "Compléments")):
        await db.execute(text("INSERT INTO familles (id, famille) VALUES (:i, :n)"), {"i": i, "n": nom})
    produits = [
        # id, nom, id_famille, copie texte de la famille, seuil, archivé
        (1, "ALPHA", 1, "Médicaments", 5, False),
        (2, "BETA", 1, "MEDICAMENT ancien libellé", 5, False),
        (3, "GAMMA", 3, "Cosmétiques", 0, False),
        (4, "DELTA", 3, "Cosmétiques", 0, False),
        (5, "EPSILON", 99, "Ancienne", 0, False),
        (6, "ZETA", 1, "Médicaments", 0, True),
    ]
    for i, nom, fam, texte, seuil, archive in produits:
        await db.execute(text(
            "INSERT INTO nomenclature (id, nom, id_famille, famille, qte_alerte, archive, desactiv_alrt_rup) "
            "VALUES (:i, :nom, :fam, :texte, :seuil, :archive, 0)"),
            {"i": i, "nom": nom, "fam": fam, "texte": texte, "seuil": seuil, "archive": archive})
    for i, id_nom, stock, achat, vente in ((1, 1, 10, 100, 150), (2, 2, 3, 50, 80),
                                           (3, 5, 2, 10, 15), (4, 6, 100, 1, 2)):
        await db.execute(text(
            "INSERT INTO entrees_produits (id, id_nom, stock, qte_entree, prix_achat, prix_vente) "
            "VALUES (:i, :n, :s, :s, :a, :v)"), {"i": i, "n": id_nom, "s": stock, "a": achat, "v": vente})
    await db.execute(text(
        "INSERT INTO sorties_produits (id, id_nom, date, qte_sortie, prix_vente, type_sortie) "
        "VALUES (1, 3, CURRENT_DATE - 30, 1, 10, 'V')"))
    await db.commit()

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://t") as client:
        yield client


async def _noms(api, **params):
    r = await api.get("/stock/products", params=params)
    assert r.status_code == 200, r.text
    return [p["nom"] for p in r.json()["items"]]


async def test_resume_avant_tout_calcul(api):
    r = (await api.get("/stock/resume")).json()
    assert r["donnees_du"] is None


async def test_resume_et_familles(api):
    await api.post("/stock/refresh-cache")
    r = (await api.get("/stock/resume")).json()

    assert r["donnees_du"] is not None
    # Archivé (ZETA) exclu ; en stock : ALPHA, BETA, EPSILON
    assert r["produits_en_stock"] == 3
    assert r["produits_actifs"] == 4                      # + GAMMA, vendu ce mois-ci
    assert r["valeur_achat"] == 10 * 100 + 3 * 50 + 2 * 10   # 1 170
    assert r["valeur_vente"] == 10 * 150 + 3 * 80 + 2 * 15   # 1 770

    assert r["familles"] == [
        {"id": 1, "famille": "Médicaments", "produits_actifs": 2, "produits_en_stock": 2},
        {"id": 3, "famille": "Cosmétiques", "produits_actifs": 1, "produits_en_stock": 0},
        {"id": 9, "famille": "Compléments", "produits_actifs": 0, "produits_en_stock": 0},
        {"id": None, "famille": "Sans famille", "produits_actifs": 1, "produits_en_stock": 1},
    ]


async def test_horodatage_avance_a_chaque_calcul(api, db):
    await api.post("/stock/refresh-cache")
    await db.execute(text("UPDATE sync_status SET last_sync_at = now() - interval '1 day'"))
    await db.commit()
    avant = (await api.get("/stock/resume")).json()["donnees_du"]
    await api.post("/stock/refresh-cache")
    assert (await api.get("/stock/resume")).json()["donnees_du"] > avant


async def test_famille_lue_dans_la_table_familles(api):
    await api.post("/stock/refresh-cache")
    items = (await api.get("/stock/products", params={"id_famille": 1})).json()["items"]
    # La copie texte de BETA est fausse : c'est la table familles qui fait foi.
    assert [(p["nom"], p["famille"], p["id_famille"]) for p in items] == [
        ("ALPHA", "Médicaments", 1), ("BETA", "Médicaments", 1)]
    # Famille inconnue de la table : on retombe sur la copie texte.
    fiche = (await api.get("/stock/products/5")).json()
    assert (fiche["id_famille"], fiche["famille"]) == (99, "Ancienne")


async def test_etats(api):
    await api.post("/stock/refresh-cache")
    assert await _noms(api, etat="en_stock") == ["ALPHA", "BETA", "EPSILON"]
    assert await _noms(api, etat="sous_seuil") == ["BETA"]       # 3 < 5 ; ALPHA 10 ≥ 5
    assert await _noms(api, etat="rupture") == ["GAMMA"]         # DELTA inactif : pas une rupture
    assert await _noms(api, actif=True) == ["ALPHA", "BETA", "EPSILON", "GAMMA"]


async def test_tri(api):
    await api.post("/stock/refresh-cache")
    assert await _noms(api, tri="stock", actif=True) == ["ALPHA", "BETA", "EPSILON", "GAMMA"]
    assert await _noms(api, tri="valeur", actif=True) == ["ALPHA", "BETA", "EPSILON", "GAMMA"]
    assert (await _noms(api, tri="derniere_vente"))[0] == "GAMMA"
    assert (await api.get("/stock/products", params={"tri": "x; DROP"})).status_code == 422


async def test_fiche_chiffres(api):
    await api.post("/stock/refresh-cache")
    p = (await api.get("/stock/products/1")).json()
    assert (p["stock"], p["prix_vente"], p["prix_achat_moyen"]) == (10, 150, 100)
    assert (p["valeur_achat"], p["valeur_vente"]) == (1000, 1500)
    assert "segment_abc" in p and "categorie" in p
