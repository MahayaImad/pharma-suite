"""
Indicateurs de gestion pour tous les produits d'un coup.

Même définitions que la fiche (`GET /stock/products/{id}/indicateurs`, calculs
dans `indicateurs_stock.py`) ; cinq requêtes au lieu de cinq par produit.
Sert à l'écran « À traiter » (péremption à risque, surstock) et à la jauge
de la liste.

Le résultat ne change qu'avec les données (recalcul du stock après chaque
passe de l'agent), le jour ou les réglages : il est gardé en mémoire tant
que ces trois choses ne bougent pas.
"""
from __future__ import annotations

import math
from dataclasses import dataclass
from datetime import date, timedelta
from decimal import Decimal
from typing import Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.services import indicateurs_stock as ind


@dataclass(frozen=True)
class Indicateurs:
    id_nom: int
    stock: float
    cmm: float
    cmj: float
    stock_securite: int
    stock_maximum: int
    couverture_jours: Optional[int]
    qte_a_risque: int
    valeur_a_risque: Decimal
    # Stock au-delà du stock maximum, et sa valeur au prix d'achat moyen.
    qte_surstock: int
    valeur_surstock: Decimal


def ecart_type_depuis_sommes(somme: float, somme_carres: float, nb_jours: int) -> float:
    """σ des ventes journalières à partir de Σq et Σq² : les jours sans vente
    comptent pour 0, comme dans `ecart_type_journalier`."""
    if nb_jours <= 1:
        return 0.0
    moyenne = somme / nb_jours
    variance = (somme_carres - nb_jours * moyenne ** 2) / (nb_jours - 1)
    return math.sqrt(max(0.0, variance))


_cache: dict[tuple, dict[int, Indicateurs]] = {}


def vider_cache() -> None:
    _cache.clear()


async def calculer_tous(db: AsyncSession, jour: date) -> dict[int, Indicateurs]:
    """Indicateurs de chaque produit non archivé, actif ou en stock."""
    donnees_du = (await db.execute(text(
        "SELECT last_sync_at FROM sync_status WHERE table_name = 'mv_stock_produits'"
    ))).scalar()
    reglages = {r.cle: r.valeur for r in await db.execute(text("SELECT cle, valeur FROM reglages_stock"))}
    cle = (jour, donnees_du, tuple(sorted(reglages.items())))
    if cle in _cache:
        return _cache[cle]

    debut = jour - timedelta(days=365)
    produits = (await db.execute(text("""
        SELECT n.id, n.segment_abc, COALESCE(mv.stock_actuel, 0) AS stock,
               COALESCE(mv.valeur_achat, 0) AS valeur_achat
        FROM nomenclature n
        JOIN mv_stock_produits mv ON mv.id_nom = n.id
        WHERE n.archive = false AND (mv.actif OR mv.stock_actuel > 0)
    """))).fetchall()
    ventes = {r.id_nom: r for r in await db.execute(text("""
        SELECT id_nom, SUM(q) AS s, SUM(q * q) AS s2
        FROM (SELECT id_nom, date, SUM(qte_sortie)::float AS q
              FROM sorties_produits
              WHERE date > :debut AND date <= :jour
              GROUP BY id_nom, date) par_jour
        GROUP BY id_nom
    """), {"debut": debut, "jour": jour})}
    premieres = {r.id_nom: r.d for r in await db.execute(text(
        "SELECT id_nom, MIN(date) AS d FROM sorties_produits WHERE qte_sortie > 0 GROUP BY id_nom"))}
    delais = {r.id_nom: r.delai_livraison for r in await db.execute(text("""
        SELECT DISTINCT ON (ep.id_nom) ep.id_nom, f.delai_livraison
        FROM entrees_produits ep
        LEFT JOIN fournisseurs f ON f.id = ep.id_fournisseur
        WHERE COALESCE(ep.type_entree, '') <> 'AV' AND COALESCE(ep.type_achat, '') <> 'E'
        ORDER BY ep.id_nom, ep.date_entree DESC NULLS LAST, ep.id DESC
    """))}
    lots: dict[int, list[ind.LotFefo]] = {}
    for l in await db.execute(text(
            "SELECT id, id_nom, stock, peremption_date, prix_achat, bloque FROM entrees_produits WHERE stock > 0")):
        lots.setdefault(l.id_nom, []).append(ind.LotFefo(
            id=l.id, stock=int(l.stock), peremption=l.peremption_date,
            prix_achat=Decimal(l.prix_achat or 0), bloque=bool(l.bloque)))

    delai_defaut = int(reglages.get("delai_livraison_jours", Decimal(1)))
    periode = float(reglages.get("periode_commande_jours", Decimal(7)))
    resultat: dict[int, Indicateurs] = {}
    for p in produits:
        v = ventes.get(p.id)
        premiere = premieres.get(p.id)
        mois = ind.mois_historique(premiere, jour)
        cmm = ind.cmm(float(v.s) if v else 0.0, mois)
        cmj = ind.cmj(cmm)
        jours = min(365, (jour - premiere).days + 1) if premiere else 365
        sigma = ecart_type_depuis_sommes(float(v.s) if v else 0.0, float(v.s2) if v else 0.0, jours)
        delai_saisi = delais.get(p.id)
        delai = ind.delai_livraison(jour, int(delai_saisi) if delai_saisi is not None else delai_defaut)
        ss = ind.stock_securite(sigma, delai, p.segment_abc)
        smax = ind.stock_maximum(ss, cmm, periode)
        stock = float(p.stock)
        risques = ind.risques_fefo(lots.get(p.id, []), cmj, jour)
        surplus = max(0, int(stock) - smax)
        prix_moyen = (Decimal(p.valeur_achat) / Decimal(int(stock))) if stock > 0 else Decimal(0)
        resultat[p.id] = Indicateurs(
            id_nom=p.id, stock=stock, cmm=cmm, cmj=cmj, stock_securite=ss, stock_maximum=smax,
            couverture_jours=ind.couverture_jours(stock, cmj),
            qte_a_risque=sum(r.a_risque or 0 for r in risques),
            valeur_a_risque=sum((r.valeur_a_risque or Decimal(0) for r in risques), Decimal(0)),
            qte_surstock=surplus,
            valeur_surstock=(Decimal(surplus) * prix_moyen).quantize(Decimal("0.01")),
        )
    _cache.clear()  # une seule entrée : la plus récente
    _cache[cle] = resultat
    return resultat
