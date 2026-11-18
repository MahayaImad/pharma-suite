"""Non-régression — part fixe du salaire brut (règle 7, arbitrages du 2026-11-18)."""
from __future__ import annotations

from datetime import date, timedelta
from decimal import Decimal

from app.services.paie.part_fixe import Regles, annees_revolues, arrondi_quart_heure, calculer

D = Decimal


def _novembre(statut_du_jour) -> list[tuple[date, str]]:
    """Novembre 2026 (30 jours, vendredis 6, 13, 20, 27) : statut_du_jour(jour) → statut."""
    jours = [date(2026, 11, 1) + timedelta(days=k) for k in range(30)]
    return [(j, "weekend" if j.weekday() == 4 else statut_du_jour(j.day)) for j in jours]


def test_exemple_du_caissier():
    """Exemple présenté le 2026-11-18 : 40 000, 6 ans, 24 jours présents, 1 absence.
    40 000 + 6 000 + 7 200 + 14 400 − 1 333,33 = 66 266,67."""
    jours = _novembre(lambda d: "absent" if d == 10 else ("ferie" if d == 1 else "present"))
    p = calculer(2026, 11, 40000, jours, date_entree=date(2020, 9, 1))
    assert (p.presence_effective, p.absences, p.annees_anciennete) == (24, 1, 6)
    assert p.lignes == {"salaire_base": D("40000.00"), "anciennete": D("6000.00"), "transport": D("7200.00"),
                        "panier": D("14400.00"), "heures_sup": D("0.00"), "retenue_absences": D("-1333.33")}
    assert p.total == D("66266.67")


def test_conge_maladie_ferie_sans_transport_ni_panier_ni_retenue():
    jours = _novembre(lambda d: {2: "conge", 3: "maladie", 4: "ferie"}.get(d, "present"))
    p = calculer(2026, 11, 35000, jours)
    assert p.presence_effective == 23 and p.absences == 0
    assert p.lignes["transport"] == D(6900) and p.lignes["retenue_absences"] == 0


def test_retard_paye_comme_present_sans_retenue():
    p = calculer(2026, 11, 40000, _novembre(lambda d: "retard" if d < 5 else "present"))
    assert p.presence_effective == 26 and p.lignes["retenue_absences"] == 0


def test_jour_a_confirmer_ni_transport_ni_panier_ni_retenue():
    p = calculer(2026, 11, 35000, _novembre(lambda d: "a_confirmer" if d > 20 else "present"))
    assert (p.presence_effective, p.a_confirmer, p.absences) == (17, 9, 0)   # 21 au 30 sauf le vendredi 27
    assert p.lignes["panier"] == D(10200)


def test_arrivee_en_cours_de_mois_prorata_et_pas_d_absence_avant():
    """Arrivé le 16 novembre : 15 jours sur 30. Les jours d'avant, « absent » dans
    la grille faute de vente, ne sont pas des absences."""
    jours = _novembre(lambda d: "absent" if d < 16 else "present")
    p = calculer(2026, 11, 42000, jours, date_entree=date(2026, 11, 16))
    assert (p.jours_contrat, p.absences, p.annees_anciennete) == (15, 0, 0)
    assert p.lignes["salaire_base"] == D("21000.00") and p.lignes["transport"] == D(300 * 13)


def test_depart_en_cours_de_mois():
    p = calculer(2026, 11, 40000, _novembre(lambda d: "present"), date_entree=date(2010, 1, 1),
                 date_sortie=date(2026, 11, 10))
    assert p.jours_contrat == 10 and p.lignes["salaire_base"] == D("13333.33")
    assert p.annees_anciennete == 16 and p.lignes["anciennete"] == D("5000.00")    # plafond 15 000 × 10/30


def test_anciennete_plafonnee_et_annees_revolues():
    assert annees_revolues(date(2010, 12, 1), date(2026, 11, 30)) == 15
    assert annees_revolues(date(2010, 11, 30), date(2026, 11, 30)) == 16
    assert annees_revolues(None, date(2026, 11, 30)) == 0
    p = calculer(2026, 11, 40000, _novembre(lambda d: "present"), date_entree=date(2000, 1, 1))
    assert p.lignes["anciennete"] == D("15000.00")


def test_heures_sup_au_quart_d_heure_et_majorees():
    assert [arrondi_quart_heure(h) for h in (D("1.1"), D("1.13"), D("2.5"), 0)] == [D(1), D("1.25"), D("2.5"), 0]
    # 40 000 ÷ 173,33 × 1,5 × 10 h = 3 461,61
    p = calculer(2026, 11, 40000, _novembre(lambda d: "present"), heures_sup=D("10"))
    assert p.heures_sup == D(10) and p.lignes["heures_sup"] == D("3461.61")


def test_regles_reglables():
    r = Regles(transport_jour=D(400), panier_jour=D(0))
    p = calculer(2026, 11, 40000, _novembre(lambda d: "present"), regles=r)
    assert p.lignes["transport"] == D(400 * 26) and p.lignes["panier"] == 0
