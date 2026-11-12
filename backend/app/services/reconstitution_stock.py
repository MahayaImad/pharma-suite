"""
Reconstituer le stock passé d'un produit — deux méthodes, calcul pur.

Le stock du jour est un champ d'EASYPHARM (exact) ; le stock d'un jour passé
n'existe nulle part et se recalcule à rebours. Deux façons :

- **par produit** : stock(D) = stock actuel − Σ (entrées − sorties) des jours
  après D. Simple, mais toute entrée ou sortie mal typée (avoirs, retours,
  échanges, casse) fausse tous les jours antérieurs ;
- **par lot** (retenue) : un lot n'existe qu'à partir de sa date d'entrée ;
  son stock au jour D = son stock actuel + ses sorties après D (ventes,
  avoirs, échanges) − ses ajustements d'inventaire après D. Exact si les
  mouvements portent le bon numéro de lot.

Le diagnostic (`scripts/diagnostiquer_historique_stock.py`) mesure sur la
base réelle laquelle tient le mieux (jours à stock négatif, impossible) avant
d'en retenir une. Les deux renvoient le stock de fin de journée, jour par
jour, de [debut] à [fin] inclus.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date, timedelta


def _jours(debut: date, fin: date) -> list[date]:
    return [debut + timedelta(days=i) for i in range((fin - debut).days + 1)]


def par_produit(stock_actuel: float, net_par_jour: dict[date, float], debut: date, fin: date) -> dict[date, float]:
    """[net_par_jour] : entrées − sorties de chaque jour, de [debut] à
    aujourd'hui ([fin] = aujourd'hui, stock de fin de journée = stock actuel)."""
    serie: dict[date, float] = {}
    stock = stock_actuel
    for jour in reversed(_jours(debut, fin)):
        serie[jour] = stock
        stock -= net_par_jour.get(jour, 0.0)   # stock de la veille au soir
    return dict(sorted(serie.items()))


@dataclass
class LotHistorique:
    """Un lot et ses mouvements (docs/BUSINESS_LOGIC.md §3.4).

    sorties_par_jour      ventes (retours clients en négatif), avoirs
                          fournisseur, échanges vers une autre pharmacie
    ajustements_par_jour  écarts d'inventaire (stock réel − théorique), ±
    """
    entree: date
    stock_actuel: float
    sorties_par_jour: dict[date, float] = field(default_factory=dict)
    ajustements_par_jour: dict[date, float] = field(default_factory=dict)

    def ajouter_sortie(self, jour: date, qte: float) -> None:
        self.sorties_par_jour[jour] = self.sorties_par_jour.get(jour, 0.0) + qte

    def ajouter_ajustement(self, jour: date, ecart: float) -> None:
        self.ajustements_par_jour[jour] = self.ajustements_par_jour.get(jour, 0.0) + ecart


def par_lot(lots: list[LotHistorique], debut: date, fin: date) -> dict[date, float]:
    """À rebours : stock(veille au soir) = stock(soir) + sorties du jour −
    ajustements du jour. Avant sa date d'entrée, un lot n'existe pas."""
    serie = {j: 0.0 for j in _jours(debut, fin)}
    for lot in lots:
        stock = lot.stock_actuel
        for jour in reversed(_jours(debut, fin)):
            if jour < lot.entree:
                break                          # le lot n'existait pas encore
            serie[jour] += stock
            stock += lot.sorties_par_jour.get(jour, 0.0) - lot.ajustements_par_jour.get(jour, 0.0)
    return serie


@dataclass(frozen=True)
class Qualite:
    jours: int
    jours_negatifs: int
    jours_rupture: int

    @property
    def part_negative(self) -> float:
        return self.jours_negatifs / self.jours if self.jours else 0.0


def qualite(serie: dict[date, float]) -> Qualite:
    """Un stock négatif est impossible : sa fréquence mesure l'erreur."""
    valeurs = list(serie.values())
    return Qualite(len(valeurs), sum(1 for v in valeurs if v < -0.5), sum(1 for v in valeurs if v <= 0.5))


def accord_ruptures(a: dict[date, float], b: dict[date, float]) -> float:
    """Part des jours où les deux méthodes s'accordent sur « en rupture ou non »."""
    communs = a.keys() & b.keys()
    if not communs:
        return 0.0
    return sum(1 for j in communs if (a[j] <= 0.5) == (b[j] <= 0.5)) / len(communs)
