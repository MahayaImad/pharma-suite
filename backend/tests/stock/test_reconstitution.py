"""Reconstitution du stock passé — résultats calculés à la main (sans base)."""
from datetime import date

from app.services.reconstitution_stock import LotHistorique, accord_ruptures, par_lot, par_produit, qualite

J1, J2, J3, J4 = date(2026, 11, 1), date(2026, 11, 2), date(2026, 11, 3), date(2026, 11, 4)


def test_par_produit_remonte_les_mouvements():
    # Aujourd'hui (J4) : 10 en stock. J4 : vendu 2. J3 : reçu 6. J2 : vendu 4.
    s = par_produit(10, {J4: -2, J3: +6, J2: -4}, J1, J4)
    # fin J4 = 10 ; fin J3 = 10 + 2 = 12 ; fin J2 = 12 − 6 = 6 ; fin J1 = 6 + 4 = 10
    assert s == {J1: 10, J2: 6, J3: 12, J4: 10}


def test_par_lot_un_lot_n_existe_qu_a_partir_de_son_entree():
    ancien = LotHistorique(entree=date(2026, 1, 1), stock_actuel=3, ventes_par_jour={J2: 4, J4: 1})
    nouveau = LotHistorique(entree=J3, stock_actuel=6)
    s = par_lot([ancien, nouveau], J1, J4)
    # ancien : fin J4 = 3, J3 = 4, J2 = 4, J1 = 8 ; nouveau : 6 à partir de J3
    assert s == {J1: 8, J2: 4, J3: 10, J4: 9}


def test_qualite_et_accord():
    q = qualite({J1: -2, J2: 0, J3: 5, J4: 1})
    assert (q.jours, q.jours_negatifs, q.jours_rupture) == (4, 1, 2)
    assert q.part_negative == 0.25
    assert accord_ruptures({J1: 0, J2: 3}, {J1: -1, J2: 0}) == 0.5
