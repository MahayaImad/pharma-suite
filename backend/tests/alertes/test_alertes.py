"""Alertes : liste par urgence, tirée du stock, des livraisons et des propositions à confirmer.

Jeu de données du module commandes (jeudi 2026-11-12) : ALPHA stock 2 à
4 / jour, BETA, GAMMA et DELTA en rupture, EPSILON stock 100 à 1 / jour.
"""
from datetime import date

from sqlalchemy import text

from tests.commandes.test_module_commandes import _commande_envoyee, api, utilisateur  # noqa: F401


async def _alertes(api):
    r = await api.get("/alertes")
    assert r.status_code == 200, r.text
    return r.json()["data"]


async def test_alertes_par_urgence_avec_leur_action(api):
    # GAMMA commandé le 10 chez PARA B, jamais arrivé ; un lot d'EPSILON périme ce mois ;
    # ALPHA proposé en tension ; un consommable et une garde à confirmer.
    id_c = await _commande_envoyee(api, date(2026, 11, 10), [(3, 20)], date(2026, 11, 11), fournisseur=2)
    await api.db.execute(text("UPDATE entrees_produits SET peremption_date = '2026-11-01' WHERE id = 5"))
    await api.db.execute(text("INSERT INTO produits_tension (id_nom, motif) VALUES (1, 'Commandé 2 fois, jamais livré')"))
    await api.db.execute(text("INSERT INTO produits_consommables (id_nom, consommable, confirme, source) VALUES (5, true, false, 'detection')"))
    await api.db.execute(text("INSERT INTO gardes (date, type, source, confirme) VALUES ('2026-11-06', 'soiree', 'detection', false)"))
    await api.db.commit()
    d = await _alertes(api)
    par_id = {a["id"]: a for a in d["alertes"]}
    niveaux = [a["niveau"] for a in d["alertes"]]
    assert niveaux == sorted(niveaux, key=["aujourdhui", "semaine", "surveiller"].index)

    gamma = par_id["rupture-3"]
    assert (gamma["niveau"], gamma["type"], gamma["action"]["sorte"]) == ("aujourdhui", "stock", "commander")
    assert (gamma["sujet"], gamma["titre"]) == ("GAMMA", "en rupture") and "non livré par Para B le 11/11" in gamma["detail"]
    assert "2 ventes par jour" in gamma["detail"]

    livraison = par_id[f"livraison-{id_c}"]
    assert (livraison["sujet"], livraison["titre"]) == ("PARA B", "rien reçu de la commande du 10/11")
    assert livraison["action"]["route"] == f"/commandes/livraisons/commandes/{id_c}"
    assert "2 000 DA non reçus" in livraison["detail"]

    assert par_id["peremption-mois"]["niveau"] == "aujourdhui" and "fin novembre" in par_id["peremption-mois"]["titre"]
    tension = par_id["tension-1"]
    assert (tension["niveau"], tension["action"]["sorte"], tension["id_nom"]) == ("semaine", "tension", 1)
    assert par_id["consommables"]["action"]["route"] == "/preferences/consommables"
    assert par_id["gardes"]["niveau"] == "surveiller"
    assert d["bref"]["commandes_non_livrees"] == 1 and d["bref"]["ruptures"] >= 3
    assert d["peut_decider"] is True


async def test_un_employe_ne_confirme_pas_une_tension_et_synchro_en_retard(api):
    await api.db.execute(text("INSERT INTO produits_tension (id_nom, motif) VALUES (1, 'x')"))
    await api.db.execute(text("UPDATE sync_status SET last_sync_at = now() - interval '5 hours'"))
    await api.db.commit()
    utilisateur.update(username="karim", role="employee")
    d = await _alertes(api)
    par_id = {a["id"]: a for a in d["alertes"]}
    assert d["peut_decider"] is False and par_id["tension-1"]["action"]["sorte"] == "ouvrir"
    assert d["alertes"][0]["id"] == "synchro"


async def test_rien_a_signaler(api):
    """Stock plein partout, rien en cours : aucune alerte urgente."""
    await api.db.execute(text("UPDATE entrees_produits SET stock = 40"))
    await api.db.execute(text("REFRESH MATERIALIZED VIEW mv_stock_produits"))
    await api.db.commit()
    from app.modules.commandes import service
    from app.services import indicateurs_stock_lot
    service.vider_cache()
    indicateurs_stock_lot.vider_cache()
    d = await _alertes(api)
    assert [a for a in d["alertes"] if a["niveau"] == "aujourdhui"] == []
    assert d["bref"]["ruptures"] == 0
