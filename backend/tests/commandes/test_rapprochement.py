"""Rapprochement des livraisons : attribution des réceptions aux lignes commandées."""
from datetime import date

from app.modules.commandes.rapprochement import (ATTENDUE, LIVREE, MANQUANTE, PARTIELLE, Ligne, Reception,
                                                  etat_commande, rapprocher)

J = date(2026, 11, 10)   # envoi ; livraison prévue le 11


def _ligne(i=1, qte=10, depuis=J, prevue=date(2026, 11, 11), f=1, p=7):
    return Ligne(i, f, p, qte, depuis, prevue)


def _r(jour, qte, f=1, p=7):
    return Reception(f, p, jour, qte)


def test_attendue_puis_livree():
    assert rapprocher([_ligne()], [], date(2026, 11, 11))[1].etat == ATTENDUE
    s = rapprocher([_ligne()], [_r(date(2026, 11, 11), 10)], date(2026, 11, 11))[1]
    assert (s.etat, s.recu, s.recu_le) == (LIVREE, 10, date(2026, 11, 11))


def test_partielle_et_manquante_apres_la_date_prevue():
    s = rapprocher([_ligne()], [_r(date(2026, 11, 11), 4)], date(2026, 11, 12))[1]
    assert (s.etat, s.recu, s.reste(_ligne())) == (PARTIELLE, 4, 6)
    assert rapprocher([_ligne()], [], date(2026, 11, 12))[1].etat == MANQUANTE
    # Reçu en partie mais date pas encore passée : toujours attendue.
    assert rapprocher([_ligne()], [_r(date(2026, 11, 11), 4)], date(2026, 11, 11))[1].etat == ATTENDUE


def test_seules_les_receptions_d_apres_l_envoi_du_meme_grossiste_comptent():
    recues = [_r(J, 10), _r(date(2026, 11, 11), 10, f=2), _r(date(2026, 11, 11), 10, p=8)]
    assert rapprocher([_ligne()], recues, date(2026, 11, 12))[1].recu == 0


def test_livraison_en_retard_dans_la_tolerance_puis_au_dela():
    assert rapprocher([_ligne()], [_r(date(2026, 11, 18), 10)], date(2026, 11, 20))[1].etat == LIVREE
    assert rapprocher([_ligne()], [_r(date(2026, 11, 19), 10)], date(2026, 11, 20))[1].etat == MANQUANTE


def test_deux_commandes_du_meme_produit_la_plus_ancienne_d_abord():
    a = _ligne(1, 10)
    b = _ligne(2, 10, depuis=date(2026, 11, 11), prevue=date(2026, 11, 12))
    s = rapprocher([b, a], [_r(date(2026, 11, 12), 14)], date(2026, 11, 13))
    assert (s[1].recu, s[1].etat) == (10, LIVREE) and (s[2].recu, s[2].etat) == (4, PARTIELLE)
    # Une réception ne sert qu'une fois, le surplus est ignoré.
    s = rapprocher([a], [_r(date(2026, 11, 11), 30)], date(2026, 11, 12))
    assert s[1].recu == 10


def test_une_reception_future_est_ignoree():
    assert rapprocher([_ligne()], [_r(date(2026, 11, 11), 10)], J)[1].recu == 0


def test_etat_d_une_commande():
    assert etat_commande([LIVREE, ATTENDUE]) == ATTENDUE
    assert etat_commande([LIVREE, LIVREE]) == LIVREE
    assert etat_commande([MANQUANTE, MANQUANTE]) == MANQUANTE
    assert etat_commande([LIVREE, MANQUANTE]) == PARTIELLE
    assert etat_commande([PARTIELLE]) == PARTIELLE
