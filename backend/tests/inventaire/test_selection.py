"""Choix des produits à compter : suspects d'abord, puis les plus en retard selon leur classe."""
from datetime import date, timedelta

from app.modules.inventaire.selection import Candidat, choisir

J = date(2026, 11, 17)
FREQ = {"A": 30, "B": 90, "C": 180}


def c(i, classe="A", stock=10, valeur=100.0, vente=5, compte=None):
    return Candidat(i, classe, stock, valeur, None if vente is None else J - timedelta(days=vente),
                    None if compte is None else J - timedelta(days=compte))


def test_jamais_comptes_d_abord_classe_a_puis_valeur():
    r = choisir([c(1, "C", valeur=999), c(2, "A", valeur=10), c(3, "A", valeur=50)], J, 10, FREQ)
    assert [i for i, _ in r] == [3, 2, 1] and r[0][1] == "jamais compté"


def test_frequence_par_classe():
    # A compté il y a 31 j : échu ; B compté il y a 60 j : pas encore ; C il y a 200 j : échu.
    r = choisir([c(1, "A", compte=31), c(2, "B", compte=60), c(3, "C", compte=200), c(4, "A", compte=10)], J, 10, FREQ)
    assert {i for i, _ in r} == {1, 3}
    assert dict(r)[1] == "dernier comptage il y a 31 jours"


def test_le_plus_en_retard_d_abord_et_nombre_limite():
    r = choisir([c(1, "A", compte=35), c(2, "A", compte=90), c(3, "C", compte=200)], J, 2, FREQ)
    assert [i for i, _ in r] == [2, 1]   # 90/30 = 3 fois en retard, puis 35/30


def test_suspects_rupture_vendue_recemment_au_plus_la_moitie():
    cands = [c(10 + k, stock=0, vente=3) for k in range(6)] + [c(1, compte=40), c(2, compte=50)]
    r = choisir(cands, J, 4, FREQ)
    assert len(r) == 4 and sum("vérifier le rayon" in m for _, m in r) == 2
    # Rupture sans vente récente, ou recomptée il y a 5 jours : pas suspecte, et sans stock pas échue.
    assert choisir([c(1, stock=0, vente=60), c(2, stock=0, vente=2, compte=5)], J, 4, FREQ) == []
