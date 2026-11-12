"""
Prévision de la demande journalière d'un produit — calculs purs (numpy).

Choix arrêtés avec l'officine (2026-11-12) : une méthode par type de produit,
simple et explicable, mesurée par le rejeu avant tout usage.

1. **Classement** (Syntetos et Boylan) sur 12 mois, jours de rupture exclus :
   ADI = intervalle moyen entre deux jours de vente, CV² = variabilité des
   quantités vendues les jours de vente.

       régulier      ADI < 1,32 et CV² < 0,49
       irrégulier    ADI < 1,32 et CV² ≥ 0,49
       intermittent  ADI ≥ 1,32 et CV² < 0,49
       sporadique    ADI ≥ 1,32 et CV² ≥ 0,49
       lent          moins de 12 jours de vente sur 12 mois
       nouveau       moins de 90 jours depuis la première vente

2. **Rythme de base** : vente moyenne par jour ouvert sur une fenêtre récente
   (8 semaines pour régulier et irrégulier, 26 semaines sinon), **sans les
   jours où le produit était en rupture** (stock nul au matin et rien vendu :
   la demande y est inconnue, pas nulle).

3. **Effets du calendrier**, multiplicatifs :
   - jour de la semaine (profil de toute l'officine) ;
   - garde (soirée, 24 h, jour de fermeture) : rapport des ventes de
     l'officine un jour de garde à un jour ordinaire du même jour de semaine ;
   - saison : indice mensuel, seulement si le produit est **saisonnier**
     (profil mensuel marqué et semblable d'une année sur l'autre) ;
   - Ramadan : rapport des ventes du produit pendant le Ramadan précédent à
     celles des 4 semaines d'avant, ramené vers 1 selon le volume.
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import date, timedelta
from typing import Optional

import numpy as np

ADI_SEUIL = 1.32
CV2_SEUIL = 0.49
JOURS_VENTE_LENT = 12
JOURS_NOUVEAU = 90
FENETRE_COURTE = 56
FENETRE_LONGUE = 182


@dataclass(frozen=True)
class Classe:
    type: str        # regulier | irregulier | intermittent | sporadique | lent | nouveau
    adi: float
    cv2: float
    jours_vente: int


def classer(demande: np.ndarray, censure: np.ndarray, premiere_vente: Optional[int], jour: int) -> Classe:
    """Type de demande au jour [jour] (indice), sur les 365 jours précédents.

    [demande] : ventes nettes par jour (≥ 0) ; [censure] : True les jours en
    rupture (exclus) ; [premiere_vente] : indice du premier jour de vente."""
    debut = max(0, jour - 365)
    d, c = demande[debut:jour], censure[debut:jour]
    observes = d[~c]
    ventes = observes[observes > 0]
    n_vente = int(ventes.size)
    if premiere_vente is None or jour - premiere_vente < JOURS_NOUVEAU:
        return Classe("nouveau", 0.0, 0.0, n_vente)
    if n_vente < JOURS_VENTE_LENT:
        return Classe("lent", float("inf") if n_vente == 0 else observes.size / n_vente, 0.0, n_vente)
    adi = observes.size / n_vente
    cv2 = float((ventes.std() / ventes.mean()) ** 2) if ventes.mean() > 0 else 0.0
    if adi < ADI_SEUIL:
        return Classe("regulier" if cv2 < CV2_SEUIL else "irregulier", adi, cv2, n_vente)
    return Classe("intermittent" if cv2 < CV2_SEUIL else "sporadique", adi, cv2, n_vente)


def rythme(demande: np.ndarray, censure: np.ndarray, ouvert: np.ndarray, jour: int, type_: str,
           premiere_vente: Optional[int] = None) -> float:
    """Vente moyenne par jour ouvert, hors jours en rupture, sur la fenêtre du
    type. Un produit nouveau n'est compté qu'à partir de sa première vente :
    les semaines d'avant, il n'existait pas."""
    fenetre = FENETRE_COURTE if type_ in ("regulier", "irregulier") else FENETRE_LONGUE
    debut = max(0, jour - fenetre)
    if type_ == "nouveau" and premiere_vente is not None:
        debut = max(debut, premiere_vente)
    garde = (~censure[debut:jour]) & ouvert[debut:jour]
    if not garde.any():
        return 0.0
    return float(demande[debut:jour][garde].mean())


def ecart_type(demande: np.ndarray, censure: np.ndarray, ouvert: np.ndarray, jour: int) -> float:
    debut = max(0, jour - FENETRE_LONGUE)
    garde = (~censure[debut:jour]) & ouvert[debut:jour]
    valeurs = demande[debut:jour][garde]
    return float(valeurs.std(ddof=1)) if valeurs.size > 1 else 0.0


# ── Effets du calendrier ────────────────────────────────────────────────────

def profil_semaine(total: np.ndarray, dates: list[date], gardes: Optional[dict] = None) -> np.ndarray:
    """Poids de chaque jour de la semaine (lundi = 0), moyenne 1 sur les jours
    où l'officine vend ; 0 un jour de fermeture. Appris sur les jours
    ordinaires : une garde le vendredi ne rend pas le vendredi « ouvert »."""
    sommes, nombres = np.zeros(7), np.zeros(7)
    for v, d in zip(total, dates):
        if gardes and d in gardes:
            continue
        sommes[d.weekday()] += v
        nombres[d.weekday()] += 1
    moyennes = np.divide(sommes, nombres, out=np.zeros(7), where=nombres > 0)
    ouverts = moyennes > 0.15 * moyennes.max() if moyennes.max() > 0 else moyennes > 0
    if not ouverts.any():
        return np.ones(7)
    return np.where(ouverts, moyennes / moyennes[ouverts].mean(), 0.0)


def facteurs_garde(total: np.ndarray, dates: list[date], gardes: dict[date, str]) -> dict[str, float]:
    """Ventes de l'officine un jour de garde ÷ médiane des jours ordinaires du
    même jour de semaine. Un jour **de fermeture** ouvert en garde (le
    vendredi) est comparé à la médiane des jours **ouverts** : comparé aux
    vendredis ordinaires, presque sans vente, il donnait un facteur absurde
    (× 145 sur la base réelle le 2026-11-12)."""
    semaine = profil_semaine(total, dates, gardes)
    ordinaires: dict[int, list[float]] = {j: [] for j in range(7)}
    for v, d in zip(total, dates):
        if d not in gardes and v > 0:
            ordinaires[d.weekday()].append(v)
    ouverts = [v for j, vs in ordinaires.items() if semaine[j] > 0 for v in vs]
    reference_ouverte = float(np.median(ouverts)) if ouverts else 0.0
    rapports: dict[str, list[float]] = {}
    for v, d in zip(total, dates):
        type_ = gardes.get(d)
        if type_ is None:
            continue
        ferme = semaine[d.weekday()] == 0
        base = (reference_ouverte if ferme or not ordinaires[d.weekday()]
                else float(np.median(ordinaires[d.weekday()])))
        if base > 0:
            rapports.setdefault(type_, []).append(v / base)
    return {t: float(np.median(r)) for t, r in rapports.items()}


def indices_saison(demande: np.ndarray, dates: list[date], jusqu_a: int) -> Optional[np.ndarray]:
    """Indice de chaque mois (moyenne 1), si le produit est saisonnier : profil
    mensuel marqué (écart-type des indices ≥ 0,25) et semblable d'une année
    sur l'autre (corrélation ≥ 0,5 entre les deux dernières années pleines)."""
    par_an_mois: dict[tuple[int, int], list[float]] = {}
    for v, d in zip(demande[:jusqu_a], dates[:jusqu_a]):
        par_an_mois.setdefault((d.year, d.month), []).append(v)
    annees = sorted({a for a, m in par_an_mois if all((a, mm) in par_an_mois for mm in range(1, 13))})
    if len(annees) < 2:
        return None
    profils = []
    for a in annees[-2:]:
        moyennes = np.array([np.mean(par_an_mois[(a, m)]) for m in range(1, 13)])
        if moyennes.mean() <= 0:
            return None
        profils.append(moyennes / moyennes.mean())
    p1, p2 = profils
    if np.std(p1) == 0 or np.std(p2) == 0:
        return None
    correlation = float(np.corrcoef(p1, p2)[0, 1])
    indice = (p1 + p2) / 2
    if correlation < 0.5 or float(np.std(indice)) < 0.25:
        return None
    return indice


def facteur_periode(demande: np.ndarray, debut: int, fin: int, volume_plein: float = 30.0) -> float:
    """Rapport des ventes par jour pendant [debut, fin] à celles des 28 jours
    d'avant, ramené vers 1 quand le volume est faible (moins de [volume_plein]
    unités vendues pendant la période : estimation trop bruitée)."""
    if debut < 28 or fin <= debut:
        return 1.0
    pendant = demande[debut:fin + 1]
    avant = demande[debut - 28:debut]
    if avant.mean() <= 0:
        return 1.0
    brut = pendant.mean() / avant.mean()
    poids = min(1.0, pendant.sum() / volume_plein)
    return float(1.0 + poids * (brut - 1.0))


@dataclass
class Calendrier:
    """Effets du calendrier pour une prévision."""
    semaine: np.ndarray                         # 7 poids
    gardes: dict[date, str]
    facteurs_garde: dict[str, float]
    periodes_ramadan: list[tuple[date, date]]

    def poids(self, jour: date, saison: Optional[np.ndarray], ramadan: float) -> float:
        type_garde = self.gardes.get(jour)
        if type_garde is not None:
            base = 1.0 if self.semaine[jour.weekday()] == 0 else self.semaine[jour.weekday()]
            p = base * self.facteurs_garde.get(type_garde, 1.0)
        else:
            p = float(self.semaine[jour.weekday()])
        if saison is not None:
            p *= float(saison[jour.month - 1])
        if any(a <= jour <= b for a, b in self.periodes_ramadan):
            p *= ramadan
        return p


def demande_prevue(rythme_base: float, jours: list[date], cal: Calendrier,
                   saison: Optional[np.ndarray] = None, ramadan: float = 1.0) -> float:
    """Demande attendue sur [jours] : rythme × effets du calendrier."""
    return rythme_base * sum(cal.poids(j, saison, ramadan) for j in jours)


def jours_entre(debut: date, fin: date) -> list[date]:
    """Jours de [debut] à [fin] exclu."""
    return [debut + timedelta(days=i) for i in range((fin - debut).days)]
