"""
Détection des gardes dans les heures de vente — données construites.

Pharmacie ouverte du samedi au jeudi de 8 h à 20 h (dernier ticket à 19 h),
fermée le vendredi, sur 12 semaines à partir du samedi 2026-08-15. Gardes
placées :

    jeudi 2026-10-01   24 h   (ventes la nuit, datées du vendredi 02/10)
    samedi 2026-11-07  soirée (ventes de 20 h à 22 h)
    vendredi 2026-10-23 jour  (ouverture un jour de fermeture)
"""
from datetime import date, timedelta

from app.services.gardes import Garde, detecter_gardes, ecarts_frequents, heure_de, horaires_habituels, jours_ouverts

DEBUT = date(2026, 8, 15)  # samedi


def _jeu():
    t = {}
    for i in range(7 * 13):
        d = DEBUT + timedelta(days=i)
        if d.weekday() == 4:   # vendredi fermé
            continue
        for h in range(8, 20):
            t[(d, h)] = 5
    for h in (20, 21, 22):
        t[(date(2026, 11, 7), h)] = 4
    for h in (1, 3, 5):
        t[(date(2026, 10, 2), h)] = 2
    for h in range(9, 19):
        t[(date(2026, 10, 23), h)] = 3
    return t


def test_horaires_appris():
    t = _jeu()
    assert horaires_habituels(t)[5] == set(range(8, 20))     # samedi
    assert jours_ouverts(t) == {0, 1, 2, 3, 5, 6}               # tout sauf vendredi


def test_les_trois_gardes_sont_retrouvees():
    assert detecter_gardes(_jeu()) == [
        Garde(date(2026, 10, 1), "24h", 6),
        Garde(date(2026, 10, 23), "jour", 30),
        Garde(date(2026, 11, 7), "soiree", 12),
    ]


def test_un_ticket_isole_tard_ne_fait_pas_une_garde():
    t = _jeu()
    t[(date(2026, 9, 9), 20)] = 1        # client servi à la fermeture
    assert date(2026, 9, 9) not in [g.date for g in detecter_gardes(t)]


def test_ecarts():
    g = [Garde(date(2026, 1, 1) + timedelta(days=28 * i), "soiree", 5) for i in range(4)]
    assert ecarts_frequents(g) == [(28, 3)]


def test_lecture_de_l_heure():
    assert [heure_de(x) for x in ("14:32", "8:05:10", "143205", "08050012", "", None, "abc", "25:00")] == [
        14, 8, 14, 8, None, None, None, None]
