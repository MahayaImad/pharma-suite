"""Génériques d'une même DCI : marques gardées, report de la demande."""
from datetime import date, timedelta

import numpy as np

from app.services.prevision import generiques as g
from app.services.prevision import modele as m
from app.services.prevision.rejeu import Produit, regrouper, simuler

CHRONIQUES = {"14A", "06M"}


def test_code_et_classe():
    assert g.normaliser(" 06 M 198 ") == "06M198"
    assert g.classe("14A224") == "14A"
    assert g.mode_du_groupe("14A224", CHRONIQUES) == g.TOUTES        # antidiabétique
    assert g.mode_du_groupe("04B044", CHRONIQUES) == g.QUELQUES      # AINS
    assert g.mode_du_groupe("04B044", CHRONIQUES, force="toutes") == g.TOUTES


def test_ains_on_garde_les_deux_plus_vendus_parmi_les_disponibles():
    membres = [
        g.Membre(1, ventes=300, disponible=True),
        g.Membre(2, ventes=500, disponible=False),   # introuvable depuis un moment : ignoré
        g.Membre(3, ventes=200, disponible=True),
        g.Membre(4, ventes=50, disponible=True),
    ]
    st = g.choisir("04B044", membres, g.QUELQUES, 2)
    assert [i for i, s in st.items() if s.garde] == [1, 3]
    assert st[4].remplace_par == [1, 3]
    assert st[4].parts == {1: 0.6, 3: 0.4}
    assert not st[2].garde


def test_choix_du_titulaire_garder_et_exclure():
    membres = [g.Membre(1, 300, True, choix="exclure"), g.Membre(2, 10, True, choix="garder"),
               g.Membre(3, 200, True), g.Membre(4, 100, True)]
    st = g.choisir("04B044", membres, g.QUELQUES, 2)
    assert {i for i, s in st.items() if s.garde} == {2, 3}


def test_chronique_toutes_les_marques():
    membres = [g.Membre(1, 300, True), g.Membre(2, 5, True), g.Membre(3, 1, False)]
    assert all(s.garde for s in g.choisir("06M198", membres, g.TOUTES, 2).values())


def test_aucun_disponible_on_ne_retire_rien():
    membres = [g.Membre(1, 300, False), g.Membre(2, 5, False)]
    assert all(s.garde for s in g.choisir("04B044", membres, g.QUELQUES, 1).values())


def _jours(n):
    return [date(2025, 1, 6) + timedelta(days=i) for i in range(n)]


def test_rejeu_la_marque_remplacee_s_ecoule_puis_sa_demande_passe_a_la_gardee():
    """Deux marques d'AINS, une gardée (1 marque) : la plus vendue garde tout.
    La remplacée a 10 boîtes au départ du rejeu : elle s'écoule (1/jour), puis
    sa demande est servie par la gardée."""
    n, debut = 300, 200
    dates = _jours(n)
    ouvert = np.array([d.weekday() != 4 for d in dates])
    forte = np.where(ouvert, 3.0, 0.0)
    faible = np.where(ouvert, 1.0, 0.0)
    cal = m.Calendrier(m.profil_semaine(np.where(ouvert, 5.0, 0.0), dates), {}, {}, [])
    a = Produit(1, forte, np.full(n, 10.0), "A", 1, code_dci="04B044")
    b = Produit(2, faible, np.full(n, 10.0), "B", 1, code_dci="04 B 044")
    produits, bilan, statuts = regrouper([a, b], debut, CHRONIQUES, {}, 1)
    assert (bilan.groupes, bilan.remplaces) == (1, 1)
    a2, b2 = produits
    assert b2.remplace and not a2.remplace
    assert a2.demande[debut + 5] == 3.0                  # B a encore du stock
    assert a2.demande[n - 1] == (4.0 if ouvert[n - 1] else 0.0)   # B épuisé : 3 + 1
    rb = simuler(b2, dates, debut, cal, ouvert)
    assert rb.commandes == 0 and rb.type == "remplacé" and rb.rupture_simulee == 0
    ra = simuler(a2, dates, debut, cal, ouvert)
    assert ra.taux_service > 0.95                         # la gardée suit la demande reportée
