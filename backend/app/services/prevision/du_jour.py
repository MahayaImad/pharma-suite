"""
Proposition du soir pour tous les produits — calcul pur.

Mêmes données que le rejeu (`donnees.charger` avec un « rejeu » d'un jour :
le calendrier est appris sur tout l'historique avant aujourd'hui), même
décision (`proposition.decider`). Les ventes du jour, encore incomplètes,
ne comptent pas : le jour est traité comme inconnu (censuré).
"""
from __future__ import annotations

import numpy as np

from app.services.prevision import modele as m
from app.services.prevision.donnees import Donnees
from app.services.prevision.proposition import POLITIQUE, Decision, Politique, decider
from app.services.prevision.rejeu import censure


def proposer_tous(d: Donnees, stocks: dict[int, float], en_cours: dict[int, float],
                  politique: Politique = POLITIQUE) -> dict[int, Decision]:
    """Décision de ce soir (dernier jour de [d.dates]) pour chaque produit."""
    jour = len(d.dates) - 1
    resultat: dict[int, Decision] = {}
    for p in d.produits:
        demande = p.demande.copy()
        demande[jour] = 0.0
        cens = censure(demande, p.stock_hist)
        cens[jour] = True
        ventes = np.flatnonzero(demande[:jour] > 0)
        premiere = int(ventes[0]) if ventes.size else None
        classe = m.classer(demande, cens, premiere, jour)
        resultat[p.id] = decider(demande, cens, d.ouvert, d.dates, jour, classe, premiere, p.classe_abc,
                                 p.delai_ouvres, d.calendrier, float(stocks.get(p.id, 0.0)),
                                 float(en_cours.get(p.id, 0.0)), p.saison, p.ramadan, politique)
    return resultat
