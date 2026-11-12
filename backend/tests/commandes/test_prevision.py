"""Prévision et rejeu — cas construits, résultats calculés à la main."""
from datetime import date, timedelta

import numpy as np

from app.services.prevision import modele as m
from app.services.prevision.rejeu import Produit, censure, jour_de_commande_suivant, simuler

LUNDI = date(2025, 1, 6)


def _jours(n, depuis=LUNDI):
    return [depuis + timedelta(days=i) for i in range(n)]


def test_classement_syntetos_boylan():
    n = 400
    pas_de_censure = np.zeros(n, dtype=bool)
    regulier = np.full(n, 3.0)
    assert m.classer(regulier, pas_de_censure, 0, n).type == "regulier"
    irregulier = np.where(np.arange(n) % 2 == 0, 1.0, 9.0)            # CV² = 0,64
    assert m.classer(irregulier, pas_de_censure, 0, n).type == "irregulier"
    intermittent = np.where(np.arange(n) % 3 == 0, 2.0, 0.0)          # ADI 3, CV² 0
    assert m.classer(intermittent, pas_de_censure, 0, n).type == "intermittent"
    lent = np.zeros(n); lent[::40] = 1                                  # 10 jours de vente
    assert m.classer(lent, pas_de_censure, 0, n).type == "lent"
    assert m.classer(regulier, pas_de_censure, n - 30, n).type == "nouveau"


def test_les_jours_en_rupture_ne_comptent_pas_comme_zero():
    # 5 par jour, puis 10 jours de rupture (stock nul, rien vendu) : le rythme reste 5.
    demande = np.array([5.0] * 30 + [0.0] * 10)
    stock = np.array([20.0] * 29 + [0.0] * 11)
    cens = censure(demande, stock)
    assert cens[30:].all() and not cens[:30].any()
    ouvert = np.ones(40, dtype=bool)
    assert m.rythme(demande, cens, ouvert, 40, "regulier") == 5.0
    assert m.rythme(demande, np.zeros(40, dtype=bool), ouvert, 40, "regulier") == 150 / 40


def test_profil_semaine_et_garde():
    dates = _jours(28)
    # 10 par jour, vendredi fermé ; le samedi 18/01 (garde soirée) : 15
    total = np.array([0.0 if d.weekday() == 4 else (15.0 if d == date(2025, 1, 18) else 10.0) for d in dates])
    profil = m.profil_semaine(total, dates)
    assert profil[4] == 0 and abs(profil[0] - 1) < 0.05
    assert m.facteurs_garde(total, dates, {date(2025, 1, 18): "soiree"}) == {"soiree": 1.5}


def test_saison_detectee_seulement_si_stable():
    dates = [date(2023, 1, 1) + timedelta(days=i) for i in range(731)]
    hiver = np.array([10.0 if d.month in (12, 1, 2) else 2.0 for d in dates])
    indice = m.indices_saison(hiver, dates, len(dates))
    assert indice is not None and indice[0] > 2 and indice[6] < 0.7
    plat = np.full(len(dates), 3.0)
    assert m.indices_saison(plat, dates, len(dates)) is None


def test_facteur_ramadan_ramene_vers_1_si_peu_de_volume():
    demande = np.array([2.0] * 28 + [4.0] * 30)
    assert m.facteur_periode(demande, 28, 57) == 2.0                    # 120 unités : plein poids
    faible = np.array([0.2] * 28 + [0.4] * 30)                           # 12 unités → poids 0,4
    assert abs(m.facteur_periode(faible, 28, 57) - 1.4) < 1e-9


def test_jour_de_commande_suivant_saute_le_vendredi():
    assert jour_de_commande_suivant(date(2025, 1, 9)) == date(2025, 1, 11)   # jeudi → samedi
    assert jour_de_commande_suivant(date(2025, 1, 8)) == date(2025, 1, 9)


def test_rejeu_d_un_produit_regulier():
    """Demande de 4 par jour ouvert (fermé le vendredi), stock réel figé à 0
    pendant le rejeu (rupture permanente en réel). Le rejeu doit servir
    presque toute la demande dès que la première commande arrive."""
    n = 200
    dates = _jours(n)
    ouvert = np.array([d.weekday() != 4 for d in dates])
    demande = np.where(ouvert, 4.0, 0.0)
    stock_hist = np.concatenate([np.full(100, 30.0), np.zeros(100)])
    cal = m.Calendrier(m.profil_semaine(demande, dates), {}, {}, [])
    r = simuler(Produit(1, demande, stock_hist, "A", 1), dates, 100, cal, ouvert)
    assert r.type == "regulier"
    assert r.rupture_reelle == 100
    assert r.rupture_simulee <= 3          # au plus les premiers jours
    assert r.taux_service > 0.97
    assert 0 < r.stock_moyen_simule < 20   # pas de stock démesuré
