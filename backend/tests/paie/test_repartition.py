"""Non-régression — répartition de l'enveloppe entre employés (Decimal, plancher)."""
from __future__ import annotations

from decimal import Decimal

import pytest

from app.services.paie.repartition import en_decimal, repartir, scores

D = Decimal


# ── Score distributif ─────────────────────────────────────────────────────────

def test_score_distributif_parts_d_equipe_ponderees():
    valeurs = {1: {"ca": 300, "ventes": 10}, 2: {"ca": 100, "ventes": 30}}
    s = scores(valeurs, {"ca": 20, "ventes": 10})
    assert s == {1: D(15) + D("2.5"), 2: D(5) + D("7.5")}   # 3/4 × 20 + 1/4 × 10, etc.
    assert all(isinstance(v, Decimal) for v in s.values())


def test_kpi_a_total_nul_ou_poids_nul_ignore():
    s = scores({1: {"ca": 0, "x": 5}, 2: {"ca": 0, "x": 5}}, {"ca": 50, "x": 0})
    assert s == {1: D(0), 2: D(0)}


def test_le_facteur_d_echelle_des_poids_s_annule():
    v = {1: {"a": 3, "b": 1}, 2: {"a": 1, "b": 1}}
    a, b = scores(v, {"a": 20, "b": 10}), scores(v, {"a": 40, "b": 20})
    r1, r2 = repartir(D(1000), a, [], 0), repartir(D(1000), b, [], 0)
    assert [r1[e]["prime"] for e in (1, 2)] == [r2[e]["prime"] for e in (1, 2)]


# ── Répartition au mérite seul (comportement historique) ──────────────────────

def test_sans_plancher_identique_a_l_ancien_calcul_au_centime():
    """L'ancien calcul (float) : prime = enveloppe × score ÷ Σ scores. Le nouveau
    donne le même résultat, arrondi au centime, sans float."""
    enveloppe, s = D("50000.00"), {1: D("45.123"), 2: D("35.4"), 3: D("19.477")}
    r = repartir(enveloppe, s, [1, 2, 3], taux_plancher=0)
    total = sum(s.values())
    for e in s:
        ancien = float(enveloppe) * float(s[e]) / float(total)
        assert abs(float(r[e]["prime"]) - ancien) < 0.01
    assert sum(x["prime"] for x in r.values()) == enveloppe


def test_la_somme_vaut_toujours_l_enveloppe_au_centime():
    r = repartir(D("100.00"), {1: 1, 2: 1, 3: 1}, [1, 2, 3], 0)
    assert sorted(x["prime"] for x in r.values()) == [D("33.33"), D("33.33"), D("33.34")]
    assert sum(x["prime"] for x in r.values()) == D("100.00")


# ── Plancher (règle 4) ────────────────────────────────────────────────────────

def test_exemple_du_plancher_50_pourcent():
    """Exemple présenté le 2026-11-18 : enveloppe 50 000, 3 présents, scores 45 / 35 / 20."""
    r = repartir(D(50000), {1: 45, 2: 35, 3: 20}, [1, 2, 3])
    assert [r[e]["plancher"] for e in (1, 2, 3)] == [D("8333.33")] * 3
    # 19 583,333… / 17 083,333… / 13 333,333… : un seul centime à rendre pour tomber juste.
    assert sorted(r[e]["prime"] - p for e, p in zip((1, 2, 3), (D("19583.33"), D("17083.33"), D("13333.33")))) \
        == [D(0), D(0), D("0.01")]
    assert sum(x["prime"] for x in r.values()) == D(50000)
    assert r[1]["merite"] + r[1]["plancher"] == r[1]["prime"]


def test_le_plancher_ne_va_qu_aux_presents():
    r = repartir(D(30000), {1: 50, 2: 50, 3: 0}, [1, 2])
    assert r[3]["prime"] == 0 and r[1]["plancher"] == D("7500.00")
    assert r[1]["prime"] == r[2]["prime"] == D("15000.00")


def test_plancher_garanti_meme_avec_un_score_nul():
    r = repartir(D(40000), {1: 100, 2: 0}, [1, 2])
    assert r[2]["prime"] == D("10000.00") and r[1]["prime"] == D("30000.00")


def test_aucun_score_le_reste_est_partage_entre_presents():
    r = repartir(D(9000), {1: 0, 2: 0, 3: 0}, [1, 2])
    assert (r[1]["prime"], r[2]["prime"], r[3]["prime"]) == (D("4500.00"), D("4500.00"), D(0))


def test_enveloppe_nulle_ou_sans_employe():
    assert repartir(D(0), {1: 5}, [1])[1]["prime"] == 0
    assert repartir(D(1000), {}, []) == {}


@pytest.mark.parametrize("v, attendu", [(None, D(0)), (3, D(3)), ("1.10", D("1.10")), (0.1, D("0.1"))])
def test_en_decimal_sans_imprecision(v, attendu):
    assert en_decimal(v) == attendu
