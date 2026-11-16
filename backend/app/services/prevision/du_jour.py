"""
Proposition du soir pour tous les produits — calcul pur.

Mêmes données que le rejeu (`donnees.charger` avec un « rejeu » d'un jour :
le calendrier est appris sur tout l'historique avant aujourd'hui), même
décision (`proposition.decider`). Les ventes du jour, encore incomplètes,
ne comptent pas : le jour est traité comme inconnu (censuré).
"""
from __future__ import annotations

from dataclasses import replace
from typing import Optional

import numpy as np

from app.services.prevision import modele as m
from app.services.prevision.donnees import Donnees
from app.services.prevision.proposition import MINMAX, POLITIQUE, Decision, Politique, decider, decider_minmax
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


def _entrees(p, jour: int):
    demande = p.serie_prevision(jour).copy()
    demande[jour] = 0.0
    cens = censure(demande, p.stock_hist)
    cens[jour] = True
    ventes = np.flatnonzero(demande[:jour] > 0)
    premiere = int(ventes[0]) if ventes.size else None
    return demande, cens, premiere


def _repartir(quantite: int, cibles: list[float], positions: list[float]) -> list[int]:
    """Répartit [quantite] boîtes entre les marques gardées : d'abord vers
    celles qui sont le plus loin de leur part du maxi, au plus fort reste."""
    manques = [max(0.0, c - p) for c, p in zip(cibles, positions)]
    poids = manques if sum(manques) > 0 else [max(c, 1e-9) for c in cibles]
    total = sum(poids)
    brut = [quantite * w / total for w in poids]
    parts = [int(b) for b in brut]
    for i in sorted(range(len(brut)), key=lambda i: -(brut[i] - parts[i]))[:quantite - sum(parts)]:
        parts[i] += 1
    return parts


def proposer_tous(d: Donnees, stocks: dict[int, float], en_cours: dict[int, float],
                  politique: Optional[Politique] = None, generiques: bool = True,
                  statuts: Optional[dict] = None) -> dict[int, Decision]:
    """Décision de ce soir (dernier jour de [d.dates]) pour chaque produit ;
    une marque remplacée (règle des génériques) reçoit une quantité nulle.

    Mini / maxi (politique par défaut) : les marques gardées d'une DCI
    interchangeable sont calculées **ensemble** (ventes, stock et commandes
    en cours de toutes les marques gardées), puis la quantité est répartie
    entre elles selon leur part des ventes."""
    from app.services.prevision import generiques as g

    politique = politique or d.politique_minmax or MINMAX
    jour = len(d.dates) - 1
    if generiques:
        produits, statuts = appliquer_generiques(d, stocks)
    else:
        produits = d.produits
    statuts = statuts or {}
    # Les ventes d'aujourd'hui ne sont pas finies : le jour ne compte ni dans
    # le rythme ni dans sa moyenne brute.
    ouvert = d.ouvert.copy()
    ouvert[jour] = False
    resultat: dict[int, Decision] = {}
    par_id = {p.id: p for p in produits}

    groupes: dict[str, list] = {}
    if politique.minmax:
        for i, st in statuts.items():
            if st.mode == g.QUELQUES and st.garde and i in par_id:
                groupes.setdefault(st.code, []).append(par_id[i])
        groupes = {c: ps for c, ps in groupes.items() if len(ps) > 1}
    dans_un_groupe = {p.id for ps in groupes.values() for p in ps}

    for p in produits:
        if p.remplace or p.id in dans_un_groupe:
            continue
        demande, cens, premiere = _entrees(p, jour)
        classe = m.classer(demande, cens, premiere, jour)
        stock, cours = float(stocks.get(p.id, 0.0)), float(en_cours.get(p.id, 0.0))
        if politique.minmax:
            resultat[p.id] = decider_minmax(demande, cens, ouvert, d.dates, jour, classe, premiere, p.classe_abc,
                                            p.delai_ouvres, d.calendrier, stock, cours, p.saison, p.ramadan,
                                            politique, p.ordonnance, p.lot, p.tension, p.vie_jours)
        else:
            resultat[p.id] = decider(demande, cens, ouvert, d.dates, jour, classe, premiere, p.classe_abc,
                                     p.delai_ouvres, d.calendrier, stock, cours, p.saison, p.ramadan, politique)

    for code, membres in groupes.items():
        demande = sum(p.serie_prevision(jour) for p in membres).copy()
        demande[jour] = 0.0
        hist = sum(np.nan_to_num(p.stock_hist, nan=0.0) for p in membres)
        cens = censure(demande, hist)
        cens[jour] = True
        ventes = np.flatnonzero(demande[:jour] > 0)
        premiere = int(ventes[0]) if ventes.size else None
        classe = m.classer(demande, cens, premiere, jour)
        abc = min((p.classe_abc or "Z" for p in membres), default=None)
        positions = [float(stocks.get(p.id, 0.0)) + float(en_cours.get(p.id, 0.0)) for p in membres]
        dec = decider_minmax(
            demande, cens, ouvert, d.dates, jour, classe, premiere, None if abc == "Z" else abc,
            min(p.delai_ouvres for p in membres), d.calendrier,
            sum(float(stocks.get(p.id, 0.0)) for p in membres), sum(float(en_cours.get(p.id, 0.0)) for p in membres),
            None, membres[0].ramadan, politique, max(p.ordonnance for p in membres),
            max(p.lot for p in membres), any(p.tension for p in membres),
            min((p.vie_jours for p in membres if p.vie_jours), default=None))
        ventes_an = [float(p.serie_prevision(jour)[max(0, jour - 365):jour].sum()) for p in membres]
        total = sum(ventes_an)
        parts_ventes = [v / total if total > 0 else 1 / len(membres) for v in ventes_an]
        cibles = [dec.maxi * w for w in parts_ventes]
        quantites = _repartir(dec.quantite, cibles, positions) if dec.quantite > 0 else [0] * len(membres)
        for p, q, w in zip(membres, quantites, parts_ventes):
            resultat[p.id] = replace(dec, quantite=q, stock=float(stocks.get(p.id, 0.0)),
                                     en_cours=float(en_cours.get(p.id, 0.0)), groupe=code, part=round(w, 3),
                                     stock_groupe=dec.stock, maxi_groupe=dec.maxi)
    return resultat
