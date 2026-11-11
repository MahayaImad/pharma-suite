"""
Retrouver les gardes passées dans les heures de vente.

La pharmacie a des horaires réguliers ; une garde se voit à des ventes faites
hors de ces horaires :

    soiree  ventes tard le soir, au-delà des heures habituelles de ce jour
    24h     ventes en pleine nuit (0 h – 6 h), datées du LENDEMAIN de la garde
    jour    ventes un jour de la semaine où la pharmacie est d'habitude fermée

Les horaires habituels ne sont pas codés : ils sont appris du jour de la
semaine (une heure est « habituelle » si au moins 40 % de ces jours-là ont
une vente à cette heure). Le résultat est une liste de candidats, à
confirmer par l'officine.

Fonctions pures : entrée = nombre de tickets par (date, heure).
"""
from __future__ import annotations

import re
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import date, timedelta
from typing import Optional

PART_HABITUELLE = 0.4      # heure habituelle si ≥ 40 % des jours ont une vente
PART_OUVERTURE = 0.3       # jour de semaine ouvert si ≥ 30 % de ces jours ont des ventes
MIN_TICKETS_SOIREE = 3
MIN_TICKETS_NUIT = 2
MIN_TICKETS_JOUR = 10
HEURES_NUIT = range(0, 7)
HEURE_DEBUT_SOIREE = 18


def heure_de(texte: Optional[str]) -> Optional[int]:
    """Heure (0–23) d'un champ `heure` EASYPHARM : « 14:32 », « 14:32:05 »,
    « 143205 » ou « 14323512 » (HHMMSScc). None si illisible."""
    if not texte:
        return None
    t = texte.strip()
    m = re.match(r"^(\d{1,2})[:hH.]", t)
    if m:
        h = int(m.group(1))
    elif re.match(r"^\d{4,8}$", t):
        h = int(t[:2]) if len(t) in (4, 6, 8) else int(t[:1])
    else:
        return None
    return h if 0 <= h <= 23 else None


@dataclass(frozen=True)
class Garde:
    date: date
    type: str          # soiree | 24h | jour
    tickets_hors_horaires: int


def horaires_habituels(tickets: dict[tuple[date, int], int]) -> dict[int, set[int]]:
    """Heures habituelles de chaque jour de la semaine (lundi = 0)."""
    jours_par_semaine: dict[int, set[date]] = defaultdict(set)
    jours_avec_heure: dict[tuple[int, int], set[date]] = defaultdict(set)
    for (d, h), n in tickets.items():
        if n > 0:
            jours_par_semaine[d.weekday()].add(d)
            jours_avec_heure[(d.weekday(), h)].add(d)
    habituelles: dict[int, set[int]] = {j: set() for j in range(7)}
    for (j, h), jours in jours_avec_heure.items():
        if len(jours) >= PART_HABITUELLE * len(jours_par_semaine[j]):
            habituelles[j].add(h)
    return habituelles


def jours_ouverts(tickets: dict[tuple[date, int], int]) -> set[int]:
    """Jours de la semaine où la pharmacie est d'habitude ouverte."""
    dates = {d for (d, _h), n in tickets.items() if n > 0}
    if not dates:
        return set()
    debut, fin = min(dates), max(dates)
    total = Counter((debut + timedelta(days=i)).weekday() for i in range((fin - debut).days + 1))
    avec_ventes = Counter(d.weekday() for d in dates)
    return {j for j in range(7) if total[j] and avec_ventes[j] >= PART_OUVERTURE * total[j]}


def detecter_gardes(tickets: dict[tuple[date, int], int]) -> list[Garde]:
    ouverts = jours_ouverts(tickets)
    # Un jour d'habitude fermé n'a pas d'heures habituelles : ses rares
    # ventes sont justement celles des gardes.
    habituelles = {j: (h if j in ouverts else set()) for j, h in horaires_habituels(tickets).items()}
    par_jour: dict[date, dict[int, int]] = defaultdict(dict)
    for (d, h), n in tickets.items():
        par_jour[d][h] = par_jour[d].get(h, 0) + n

    gardes: dict[date, Garde] = {}
    for d, heures in par_jour.items():
        j = d.weekday()
        if j not in ouverts and sum(heures.values()) >= MIN_TICKETS_JOUR:
            gardes[d] = Garde(d, "jour", sum(heures.values()))
            continue
        soir = sum(n for h, n in heures.items()
                   if h >= HEURE_DEBUT_SOIREE and h not in habituelles[j])
        if soir >= MIN_TICKETS_SOIREE:
            gardes[d] = Garde(d, "soiree", soir)
    # Nuit : ventes de 0 h à 6 h hors habitudes → garde 24 h de la veille.
    for d, heures in par_jour.items():
        nuit = sum(n for h, n in heures.items() if h in HEURES_NUIT and h not in habituelles[d.weekday()])
        if nuit >= MIN_TICKETS_NUIT:
            veille = d - timedelta(days=1)
            avant = gardes.get(veille)
            gardes[veille] = Garde(veille, "24h", nuit + (avant.tickets_hors_horaires if avant else 0))
    return sorted(gardes.values(), key=lambda g: g.date)


def ecarts_frequents(gardes: list[Garde], nombre: int = 3) -> list[tuple[int, int]]:
    """Écarts en jours entre gardes successives les plus fréquents : une
    rotation régulière se voit ici (ex. [(28, 9)] = tous les 28 jours, 9 fois)."""
    dates = [g.date for g in gardes]
    return Counter((b - a).days for a, b in zip(dates, dates[1:])).most_common(nombre)
