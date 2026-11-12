"""
Indicateurs de gestion d'un produit — résultats calculés à la main.

Partie 1 : calculs purs (sans base). Partie 2 : la route, sur la base de test.
"""
from __future__ import annotations

import math
from datetime import date, timedelta
from decimal import Decimal

import pytest_asyncio
from fastapi import FastAPI
from httpx import ASGITransport, AsyncClient
from sqlalchemy import text

from app.services import indicateurs_stock as ind

MERCREDI = date(2026, 11, 11)
JEUDI = date(2026, 11, 12)


# ── Partie 1 : calculs ───────────────────────────────────────────────────────

def test_cmm_et_cmj():
    assert ind.cmm(360, 12) == 30          # 360 sur 12 mois
    assert ind.cmj(30) == 1                # 30 ÷ 30
    assert ind.cmm(-5, 12) == 0            # plus de retours que de ventes


def test_mois_historique():
    assert ind.mois_historique(None, MERCREDI) == 12
    assert ind.mois_historique(date(2020, 1, 1), MERCREDI) == 12
    # Référencé le 1er septembre : septembre, octobre, novembre entamé → 3 mois
    assert ind.mois_historique(date(2026, 9, 1), MERCREDI) == 3
    assert ind.mois_historique(date(2026, 11, 10), MERCREDI) == 1


def test_ecart_type_compte_les_jours_sans_vente():
    # 4 jours : 2, 0, 0, 2 → moyenne 1, Σ écarts² = 4, σ = √(4 / 3)
    assert math.isclose(ind.ecart_type_journalier([2, 2], 4), math.sqrt(4 / 3))
    assert ind.ecart_type_journalier([], 365) == 0


def test_delai_livraison_semaine_algerienne():
    assert ind.date_livraison(MERCREDI) == JEUDI                  # 24 h
    assert ind.date_livraison(JEUDI) == date(2026, 11, 15)        # jeudi → dimanche
    assert ind.delai_livraison(JEUDI) == 3
    assert ind.delai_livraison(MERCREDI, 2) == 4                  # jeudi, puis dimanche
    assert ind.delai_livraison(date(2026, 11, 13)) == 2           # vendredi → dimanche


def test_stock_de_securite_et_maximum():
    # A : Z = 1,645 ; σ = 2 ; L = 4 → 1,645 × 2 × 2 = 6,58 → 7
    assert ind.stock_securite(2, 4, "A") == 7
    # Non classé → Z de B (1,282) : 1,282 × 2 × 1 = 2,564 → 3
    assert ind.stock_securite(2, 1, None) == 3
    assert ind.stock_securite(0, 3, "A") == 0
    assert ind.stock_securite_simple(1.5, 2) == 3
    # SS 7 + CMM 30 × 7 / 30 = 7 + 7 = 14
    assert ind.stock_maximum(7, 30, 7) == 14


def test_couverture():
    assert ind.couverture_jours(45, 1.5) == 30
    assert ind.couverture_jours(10, 0) is None


def test_duree_de_vie_restante():
    assert ind.fin_de_validite(date(2026, 12, 1)) == date(2026, 12, 31)
    assert ind.fin_de_validite(date(2027, 2, 1)) == date(2027, 2, 28)
    assert ind.duree_vie_restante(date(2026, 11, 1), MERCREDI) == 19      # jusqu'au 30/11
    assert ind.duree_vie_restante(date(2026, 10, 1), MERCREDI) == 0       # périmé
    assert ind.duree_vie_restante(None, MERCREDI) is None


def _lot(i, stock, mois, prix=10, bloque=False):
    return ind.LotFefo(id=i, stock=stock, peremption=mois, prix_achat=Decimal(prix), bloque=bloque)


def test_fefo_un_lot_long_derriere_des_lots_courts():
    """CMJ = 2 ; DVR : novembre 19 j, décembre 50 j, janvier 81 j, février 109 j.

    A 30 u : vendu en 15 j (≤ 19)           → risque 0, t = 15
    B 40 u : 35 j disponibles, 20 j de vente → risque 0, t = 35
    C 100 u : 46 j disponibles → 92 vendus   → risque 8, t = 81
    D 10 u : 28 j disponibles, 5 j de vente  → risque 0

    Sans FEFO, C (CMJ × DVR = 162 ≥ 100) paraîtrait sans risque.
    """
    lots = [_lot(4, 10, date(2027, 2, 1)), _lot(3, 100, date(2027, 1, 1), prix=12),
            _lot(1, 30, date(2026, 11, 1)), _lot(2, 40, date(2026, 12, 1))]
    r = {x.id: x for x in ind.risques_fefo(lots, 2, MERCREDI)}
    assert [(r[i].dvr, r[i].ecoulable, r[i].a_risque) for i in (1, 2, 3, 4)] == [
        (19, 30, 0), (50, 40, 0), (81, 92, 8), (109, 10, 0)]
    assert r[3].valeur_a_risque == Decimal("96.00")      # 8 × 12 DA


def test_fefo_lot_perime_bloque_sans_date_sans_vente():
    lots = [_lot(1, 5, date(2026, 10, 1)), _lot(2, 7, date(2027, 6, 1), bloque=True),
            ind.LotFefo(id=3, stock=4, peremption=None)]
    r = {x.id: x for x in ind.risques_fefo(lots, 1, MERCREDI)}
    assert (r[1].dvr, r[1].ecoulable, r[1].a_risque) == (0, 0, 5)   # périmé : tout est perdu
    assert r[2].a_risque is None and r[3].a_risque is None           # hors calcul
    # Aucune vente : rien n'est écoulable
    seul = ind.risques_fefo([_lot(9, 6, date(2027, 6, 1))], 0, MERCREDI)[0]
    assert (seul.ecoulable, seul.a_risque) == (0, 6)


def test_fefo_un_lot_perime_ne_consomme_pas_de_temps():
    # Le lot périmé (DVR 0) ne retarde pas le suivant : 20 u en 19 j à CMJ 1 → 19 vendus
    lots = [_lot(1, 50, date(2026, 10, 1)), _lot(2, 20, date(2026, 11, 1))]
    r = {x.id: x for x in ind.risques_fefo(lots, 1, MERCREDI)}
    assert (r[2].ecoulable, r[2].a_risque) == (19, 1)


# ── Partie 2 : la route ──────────────────────────────────────────────────────

@pytest_asyncio.fixture
async def api(db, monkeypatch):
    from app.api.v1 import stock
    from app.core.database import get_db
    from app.core.security import get_current_user

    monkeypatch.setattr(stock, "_aujourdhui_alger", lambda: MERCREDI)
    app = FastAPI()
    app.include_router(stock.router)

    async def _db():
        yield db

    app.dependency_overrides[get_db] = _db
    app.dependency_overrides[get_current_user] = lambda: {"username": "chef", "role": "admin"}
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://t") as client:
        yield client


async def test_route_indicateurs(api, db):
    """Produit A vendu 3 unités tous les jours depuis plus d'un an.

    Ventes 12 mois : 365 j × 3 = 1 095 → CMM 91,25 ; CMJ 3,0417
    σ = 0 (ventes constantes) → SS = 0 ; SS simple = ⌈3,0417 × 2⌉ = 7
    Stock max = 0 + 91,25 × 7 / 30 = 21,29 → 22
    Fournisseur 7, délai saisi 2 jours ouvrés, commande un mercredi → 4 jours
    Lots : 60 u (11/26, DVR 19) et 50 u (12/26, DVR 50)
      lot 1 : 19 j × 3,0417 = 57 vendus → 3 à risque (× 100 DA = 300 DA)
      lot 2 : 31 j × 3,0417 = 94 ≥ 50  → 0
    Couverture : 110 ÷ 3,0417 = 36 jours
    """
    await db.execute(text("DELETE FROM fournisseurs WHERE id = 7"))
    await db.execute(text("INSERT INTO fournisseurs (id, fournisseur, delai_livraison) VALUES (7, 'GROSSISTE', 2)"))
    await db.execute(text("INSERT INTO nomenclature (id, nom, segment_abc, archive) VALUES (1, 'P', 'A', false)"))
    for i in range(400):
        await db.execute(text(
            "INSERT INTO sorties_produits (id, id_nom, date, qte_sortie, prix_vente, type_sortie) "
            "VALUES (:i, 1, :d, 3, 10, 'V')"), {"i": i + 1, "d": MERCREDI - timedelta(days=i)})
    await db.execute(text("""
        INSERT INTO entrees_produits (id, id_nom, stock, qte_entree, prix_achat, prix_vente,
                                      peremption_date, id_fournisseur, date_entree, type_entree)
        VALUES (1, 1, 60, 60, 100, 150, '2026-11-01', 7, '2026-01-10', 'A'),
               (2, 1, 50, 50, 100, 150, '2026-12-01', 7, '2026-06-10', 'A')
    """))
    await db.commit()
    await api.post("/stock/refresh-cache")

    r = (await api.get("/stock/products/1/indicateurs")).json()
    assert (r["ventes_12_mois"], r["mois_historique"], r["cmm"]) == (1095, 12, 91.25)
    assert r["cmj"] == 3.042
    assert r["fournisseur"] == {"id": 7, "nom": "GROSSISTE", "delai_jours_ouvres": 2, "delai_saisi": True}
    assert (r["delai_livraison_jours"], r["date_livraison"]) == (4, "2026-11-15")
    assert (r["stock_securite"], r["stock_securite_simple"], r["stock_maximum"]) == (0, 7, 22)
    assert (r["couverture_jours"], r["dvr_max"]) == (36, 50)
    lots = {l["id"]: l for l in r["lots"]}
    assert (lots[1]["ecoulable"], lots[1]["a_risque"], lots[1]["valeur_a_risque"]) == (57, 3, 300)
    assert lots[2]["a_risque"] == 0
    assert (r["qte_a_risque"], r["valeur_a_risque"]) == (3, 300)
    assert (await api.get("/stock/products/999/indicateurs")).status_code == 404


async def test_reglages_modifiables_par_un_administrateur(api, db):
    r = await api.patch("/stock/reglages", json={"periode_commande_jours": 14})
    assert r.status_code == 200
    ligne = next(x for x in r.json() if x["cle"] == "periode_commande_jours")
    assert (ligne["valeur"], ligne["modifie_par"]) == (14, "chef")
    assert (await api.patch("/stock/reglages", json={"inconnu": 1})).status_code == 422
    assert (await api.patch("/stock/reglages", json={"delai_securite_jours": -1})).status_code == 422
    # Remise en état : la table n'est pas vidée entre les tests.
    await api.patch("/stock/reglages", json={"periode_commande_jours": 7})


# ── Partie 3 : calcul pour tous les produits, et « à traiter » ───────────────

def test_ecart_type_depuis_sommes_egal_au_calcul_jour_par_jour():
    from app.services.indicateurs_stock_lot import ecart_type_depuis_sommes
    ventes = [3, 1, 4, 1, 5]
    assert math.isclose(ecart_type_depuis_sommes(sum(ventes), sum(v * v for v in ventes), 30),
                        ind.ecart_type_journalier(ventes, 30))


async def _jeu_a_traiter(db):
    """
    1 RUPT   classe A, stock 0, vendu 2/j      → rupture (à commander)
    2 SEUIL  classe B, stock 3 < seuil 5       → sous le seuil (à commander)
    3 LENT   stock 20 périmant fin novembre (DVR 19), vendu 1 tous les 10 j
             → CMJ ≈ 0,1 ; écoulable 1 → 19 à risque × 10 DA = 190 DA
    4 GROS   stock 500 longue date, vendu 1/j → 365 en 12 mois, CMM 30,42, SS 0,
             max ⌈30,42 × 7 ÷ 30⌉ = ⌈7,1⌉ = 8 → surstock 492 × 2 DA = 984 DA
    """
    await db.execute(text("""
        INSERT INTO nomenclature (id, nom, segment_abc, qte_alerte, archive, desactiv_alrt_rup) VALUES
        (1, 'RUPT', 'A', 0, false, 0), (2, 'SEUIL', 'B', 5, false, 0),
        (3, 'LENT', 'C', 0, false, 0), (4, 'GROS', 'B', 0, false, 0)
    """))
    n = 0
    for jour in range(400):
        d = MERCREDI - timedelta(days=jour)
        for id_nom, qte in ((1, 2), (2, 1), (4, 1)) + (((3, 1),) if jour % 10 == 0 else ()):
            n += 1
            await db.execute(text(
                "INSERT INTO sorties_produits (id, id_nom, date, qte_sortie, prix_vente, type_sortie) "
                "VALUES (:i, :n, :d, :q, 10, 'V')"), {"i": n, "n": id_nom, "d": d, "q": qte})
    await db.execute(text("""
        INSERT INTO entrees_produits (id, id_nom, stock, qte_entree, prix_achat, prix_vente, peremption_date) VALUES
        (1, 2, 3, 3, 10, 15, '2028-01-01'), (2, 3, 20, 20, 10, 15, '2026-11-01'),
        (3, 4, 500, 500, 2, 3, '2029-01-01')
    """))
    await db.commit()


async def test_a_traiter(api, db):
    await _jeu_a_traiter(db)
    await api.post("/stock/refresh-cache")
    r = (await api.get("/stock/a-traiter")).json()
    c = r["compteurs"]
    assert (c["ruptures"], c["sous_seuil"], c["a_commander"]) == (1, 1, 2)
    assert [p["nom"] for p in r["a_commander"]] == ["RUPT", "SEUIL"]      # classe A d'abord
    assert [p["nom"] for p in r["a_risque"]] == ["LENT"]
    lent = r["a_risque"][0]
    assert (lent["qte_a_risque"], lent["valeur_a_risque"]) == (19, 190)
    assert c["valeur_a_risque"] == 190
    gros = next(p for p in r["surstock"] if p["nom"] == "GROS")
    assert (gros["stock_maximum"], gros["qte_surstock"], gros["valeur_surstock"]) == (8, 492, 984)

    noms = lambda etat: api.get("/stock/products", params={"etat": etat})
    assert [p["nom"] for p in (await noms("a_risque")).json()["items"]] == ["LENT"]
    assert [p["nom"] for p in (await noms("a_commander")).json()["items"]] == ["RUPT", "SEUIL"]
    assert "GROS" in [p["nom"] for p in (await noms("surstock")).json()["items"]]


async def test_le_calcul_groupe_donne_les_memes_chiffres_que_la_fiche(api, db):
    await _jeu_a_traiter(db)
    await api.post("/stock/refresh-cache")
    liste = {p["id"]: p for p in (await api.get("/stock/products", params={"limit": 200})).json()["items"]}
    for id_nom in (1, 2, 3, 4):
        fiche = (await api.get(f"/stock/products/{id_nom}/indicateurs")).json()
        ligne = liste[id_nom]
        assert (ligne["stock_securite"], ligne["stock_maximum"], ligne["couverture_jours"],
                ligne["qte_a_risque"], ligne["cmm"]) == (
            fiche["stock_securite"], fiche["stock_maximum"], fiche["couverture_jours"],
            fiche["qte_a_risque"], fiche["cmm"]), id_nom


async def test_un_echange_recu_n_est_pas_le_fournisseur_principal(api, db):
    """Dernière entrée : un échange reçu d'une pharmacie voisine (type_achat
    'E', prix 0). Le fournisseur principal reste le grossiste du dernier achat."""
    await db.execute(text("DELETE FROM fournisseurs WHERE id IN (7, 8)"))
    await db.execute(text("""
        INSERT INTO fournisseurs (id, fournisseur, delai_livraison) VALUES (7, 'GROSSISTE', 1), (8, 'PHARMACIE VOISINE', 9)
    """))
    await db.execute(text("INSERT INTO nomenclature (id, nom, archive) VALUES (1, 'P', false)"))
    await db.execute(text("""
        INSERT INTO entrees_produits (id, id_nom, stock, qte_entree, prix_achat, prix_vente,
                                      id_fournisseur, date_entree, type_entree, type_achat)
        VALUES (1, 1, 10, 10, 100, 150, 7, '2026-10-01', 'A', 'N'),
               (2, 1, 2, 2, 0, 150, 8, '2026-11-05', 'A', 'E')
    """))
    await db.commit()
    await api.post("/stock/refresh-cache")
    r = (await api.get("/stock/products/1/indicateurs")).json()
    assert r["fournisseur"]["nom"] == "GROSSISTE"
    assert r["fournisseur"]["delai_jours_ouvres"] == 1
    # Le calcul groupé (liste) choisit le même fournisseur, donc le même délai.
    ligne = (await api.get("/stock/products")).json()["items"][0]
    assert ligne["stock_securite"] == r["stock_securite"]
