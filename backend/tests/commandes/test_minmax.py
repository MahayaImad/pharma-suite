"""Mini / maxi (2026-11-16) : les trois cas de l'officine, et les génériques
interchangeables calculés ensemble."""
from datetime import date, timedelta

import numpy as np
import pytest

from app.services.prevision import modele as m
from app.services.prevision.proposition import MINMAX, decider_minmax

JEUDI_N = 400
DATES = [date(2025, 10, 9) + timedelta(days=i) for i in range(JEUDI_N + 1)]   # dernier jour : un jeudi
OUVERT = np.array([d.weekday() != 4 for d in DATES])
CAL = m.Calendrier(m.profil_semaine(np.where(OUVERT, 5.0, 0.0), DATES), {}, {}, [])
SANS = np.zeros(JEUDI_N + 1, dtype=bool)


def _decider(demande, stock, abc="B", **k):
    jour = JEUDI_N
    ventes = np.flatnonzero(demande[:jour] > 0)
    premiere = int(ventes[0]) if ventes.size else None
    classe = m.classer(demande, SANS, premiere, jour)
    return classe, decider_minmax(demande, SANS, OUVERT, DATES, jour, classe, premiere, abc, 1, CAL, stock, 0.0,
                                  politique=MINMAX, **k)


def test_spiriva_vente_rare_par_ordonnance_de_3():
    d = np.zeros(JEUDI_N + 1)
    d[np.arange(20, JEUDI_N, 33)] = 3.0          # une ordonnance de 3 boîtes par mois environ
    classe, dec = _decider(d, 0.0, ordonnance=3)
    assert classe.type == "lent"
    assert (dec.mini, dec.maxi, dec.quantite) == (3.0, 3.0, 3)
    assert _decider(d, 3.0, ordonnance=3)[1].quantite == 0


def test_clofenal_forte_rotation_lot_de_30_et_rien_au_dessus_du_mini():
    d = np.where(OUVERT, 2.0, 0.0)
    d[JEUDI_N] = 0.0
    _, haut = _decider(d, 20.0, abc="A", lot=30)
    assert haut.quantite == 0 and haut.mini < 20                       # au-dessus du mini : rien
    _, bas = _decider(d, 2.0, abc="A", lot=30)
    assert bas.mini > 2 and bas.quantite == 30 and bas.lot == 30        # sous le mini : le lot habituel
    assert bas.maxi == pytest.approx(bas.mini + 2.0 * 13, abs=2.5)     # + 15 j de couverture (13 jours ouverts)


def test_lot_habituel_plafonne_a_90_jours_de_vente():
    d = np.where(OUVERT, 0.2, 0.0)
    _, dec = _decider(d, 0.0, abc="C", lot=100)
    assert dec.quantite <= int(np.ceil(0.2 * 90)) + 1


def test_xaria_en_tension_on_complete_meme_avec_du_stock():
    d = np.where(np.arange(JEUDI_N + 1) % 4 == 0, 2.0, 0.0)     # 0,5 par jour
    _, normal = _decider(d, 3.0, abc="B")
    _, tension = _decider(d, 3.0, abc="B", tension=True)
    assert tension.couverture == 60 and tension.tension
    assert tension.quantite > 20 and tension.quantite > normal.quantite


def test_peremption_courte_reduit_la_couverture():
    d = np.where(OUVERT, 1.0, 0.0)
    _, dec = _decider(d, 0.0, abc="C", vie_jours=20)
    assert dec.couverture == 16                                  # 80 % de 20 jours


def test_lent_et_cher_commande_a_la_demande():
    """Menopur : vendu par 5 de temps en temps, 10 000 DA la boîte → pas de stock."""
    d = np.zeros(JEUDI_N + 1)
    d[np.arange(30, JEUDI_N, 60)] = 5.0
    _, cher = _decider(d, 0.0, ordonnance=5, prix=10_000)
    assert cher.sur_demande and cher.quantite == 0 and cher.maxi == 0
    _, bon_marche = _decider(d, 0.0, ordonnance=5, prix=300)
    assert not bon_marche.sur_demande and bon_marche.quantite == 5
    _, tension = _decider(d, 0.0, ordonnance=5, prix=10_000, tension=True)
    assert not tension.sur_demande and tension.quantite > 0
