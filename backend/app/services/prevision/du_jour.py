"""
Proposition du soir pour tous les produits — calcul pur.

Mêmes données que le rejeu (`donnees.charger` avec un « rejeu » d'un jour :
le calendrier est appris sur tout l'historique avant aujourd'hui), même
décision (`proposition.decider`). Les ventes du jour, encore incomplètes,
ne comptent pas : le jour est traité comme inconnu (censuré).
"""
from __future__ import annotations

from dataclasses import replace

import numpy as np

from app.services.prevision import modele as m
from app.services.prevision.donnees import Donnees
from app.services.prevision.proposition import POLITIQUE, Decision, Politique, decider
from app.services.prevision.rejeu import FENETRE_DISPONIBLE, censure


def appliquer_generiques(d: Donnees, stocks: dict[int, float]) -> tuple[list, dict]:
    """Règle des génériques à aujourd'hui : une marque non gardée n'est plus
    commandée ; si elle est épuisée, ses ventes passées s'ajoutent à la
    prévision des marques gardées (au prorata)."""
    from app.services.prevision import generiques as g

    jour = len(d.dates) - 1
    groupes: dict[str, list] = {}
    for p in d.produits:
        code = g.normaliser(p.code_dci)
        if code:
            groupes.setdefault(code, []).append(p)
    statuts: dict[int, g.Statut] = {}
    produits = {p.id: p for p in d.produits}
    for code, membres in groupes.items():
        if len(membres) < 2:
            continue
        mode = g.mode_du_groupe(code, d.classes_chroniques, d.modes_forces.get(code))
        d0 = max(0, jour - FENETRE_DISPONIBLE)
        infos = [g.Membre(
            id=p.id, ventes=float(p.demande[max(0, jour - 365):jour].sum()),
            disponible=bool(stocks.get(p.id, 0) > 0 or p.demande[d0:jour].sum() > 0), choix=p.choix)
            for p in membres]
        st = g.choisir(code, infos, mode, d.nombre_generiques)
        statuts.update(st)
        for p in membres:
            s_ = st[p.id]
            if s_.garde:
                continue
            produits[p.id] = replace(produits[p.id], remplace=True)
            if stocks.get(p.id, 0) > 0:
                continue   # son stock sert encore ses patients
            for k, part in s_.parts.items():
                q = produits[k]
                produits[k] = replace(q, reports=[*q.reports, (part * p.demande, 0)])
    return [produits[p.id] for p in d.produits], statuts


def proposer_tous(d: Donnees, stocks: dict[int, float], en_cours: dict[int, float],
                  politique: Politique = POLITIQUE, generiques: bool = True) -> dict[int, Decision]:
    """Décision de ce soir (dernier jour de [d.dates]) pour chaque produit ;
    une marque remplacée (règle des génériques) reçoit une quantité nulle."""
    jour = len(d.dates) - 1
    produits = appliquer_generiques(d, stocks)[0] if generiques else d.produits
    resultat: dict[int, Decision] = {}
    for p in produits:
        if p.remplace:
            continue
        demande = p.serie_prevision(jour).copy()
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
