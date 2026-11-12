"""
Charger d'un coup ce qu'il faut au rejeu (lecture seule).

Ventes depuis le 2023-01-01 (deux années civiles pleines avant le rejeu, pour
reconnaître un produit saisonnier) ; historique du stock (2024 et après) ;
gardes non annulées ; périodes de Ramadan ; fournisseur principal et délai ;
classe ABC ; prix d'achat moyen. Les consommables confirmés sont écartés
(jamais vendus : la prévision par les ventes n'a pas de sens pour eux).
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import date, timedelta
from decimal import Decimal

import numpy as np
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.historique_stock import VENTES_RESOLUES
from app.services.prevision import modele as m
from app.services.prevision.rejeu import Produit

DEBUT_DONNEES = date(2023, 1, 1)


@dataclass
class Donnees:
    dates: list[date]
    debut_rejeu: int
    produits: list[Produit]
    prix: dict[int, Decimal]
    calendrier: m.Calendrier
    ouvert: np.ndarray


async def charger(db: AsyncSession, fin: date, jours_rejeu: int = 365, limite: int | None = None) -> Donnees:
    dates = [DEBUT_DONNEES + timedelta(days=i) for i in range((fin - DEBUT_DONNEES).days + 1)]
    index = {d: i for i, d in enumerate(dates)}
    n = len(dates)
    debut_rejeu = n - jours_rejeu
    params = {"debut": DEBUT_DONNEES, "fin": fin, "debut_rejeu": dates[debut_rejeu]}

    filtre_limite = "LIMIT :limite" if limite else ""
    if limite:
        params["limite"] = limite
    lignes = (await db.execute(text(f"""
        SELECT n.id, n.segment_abc,
               COALESCE(NULLIF(mv.prix_moyen_pondere, 0), (
                   SELECT e.prix_achat FROM entrees_produits e
                   WHERE e.id_nom = n.id AND e.prix_achat > 0 ORDER BY e.date_entree DESC NULLS LAST LIMIT 1
               ), 0) AS prix,
               COALESCE((SELECT sum(qte_sortie) FROM sorties_produits sp
                         WHERE sp.id_nom = n.id AND sp.date >= :debut_rejeu), 0) AS volume
        FROM nomenclature n
        JOIN mv_stock_produits mv ON mv.id_nom = n.id
        WHERE n.archive = false AND (mv.actif OR mv.stock_actuel > 0)
          AND NOT EXISTS (SELECT 1 FROM produits_consommables pc
                          WHERE pc.id_nom = n.id AND pc.consommable AND pc.confirme)
        ORDER BY volume DESC, n.id {filtre_limite}
    """), params)).all()
    ids = [r.id for r in lignes]
    params["ids"] = ids

    reglage = (await db.execute(text(
        "SELECT valeur FROM reglages_stock WHERE cle = 'delai_livraison_jours'"))).scalar()
    delai_defaut = int(reglage or 1)
    delais = {r.id_nom: r.delai_livraison for r in await db.execute(text("""
        SELECT DISTINCT ON (ep.id_nom) ep.id_nom, f.delai_livraison
        FROM entrees_produits ep LEFT JOIN fournisseurs f ON f.id = ep.id_fournisseur
        WHERE ep.id_nom = ANY(:ids) AND COALESCE(ep.type_entree, '') <> 'AV' AND COALESCE(ep.type_achat, '') <> 'E'
        ORDER BY ep.id_nom, ep.date_entree DESC NULLS LAST, ep.id DESC"""), params)}

    demande = {i: np.zeros(n) for i in ids}
    total = np.zeros(n)
    for r in await db.execute(text(f"""
        SELECT id_nom, date, sum(qte_sortie) AS q FROM ({VENTES_RESOLUES}) v
        WHERE date BETWEEN :debut AND :fin GROUP BY 1, 2"""), params):
        k = index.get(r.date)
        if k is None:
            continue
        q = max(0.0, float(r.q or 0))
        total[k] += q
        if r.id_nom in demande:
            demande[r.id_nom][k] = q

    stocks = {i: np.full(n, np.nan) for i in ids}
    for r in await db.execute(text("""
        SELECT id_nom, date, stock_eod FROM historique_stock_jour
        WHERE id_nom = ANY(:ids) AND date BETWEEN :debut AND :fin"""), params):
        stocks[r.id_nom][index[r.date]] = float(r.stock_eod)

    gardes = {r.date: r.type for r in await db.execute(text(
        "SELECT date, type FROM gardes WHERE NOT annulee AND date BETWEEN :debut AND :fin"), params)}
    ramadans = [(r.date_debut, r.date_fin) for r in await db.execute(text(
        "SELECT date_debut, date_fin FROM evenements_calendrier WHERE type = 'ramadan' ORDER BY date_debut"))]

    # Calendrier appris avant le rejeu seulement : le rejeu ne voit pas l'avenir.
    avant = slice(0, debut_rejeu)
    semaine = m.profil_semaine(total[avant], dates[avant], gardes)
    cal = m.Calendrier(semaine, gardes,
                       m.facteurs_garde(total[avant], dates[avant], {d: t for d, t in gardes.items()
                                                                     if d < dates[debut_rejeu]}),
                       ramadans)
    ouvert = np.array([semaine[d.weekday()] > 0 or d in gardes for d in dates])

    # Ramadan de référence : le dernier entièrement passé avant le rejeu.
    passes = [(a, b) for a, b in ramadans if b < dates[debut_rejeu] and a in index and b in index]
    produits = []
    for r in lignes:
        ramadan = 1.0
        if passes:
            a, b = passes[-1]
            ramadan = m.facteur_periode(demande[r.id], index[a], index[b])
        produits.append(Produit(
            id=r.id, demande=demande[r.id], stock_hist=stocks[r.id], classe_abc=r.segment_abc,
            delai_ouvres=int(delais[r.id]) if delais.get(r.id) is not None else delai_defaut,
            ramadan=ramadan, saison=m.indices_saison(demande[r.id], dates, debut_rejeu),
        ))
    return Donnees(dates, debut_rejeu, produits, {r.id: Decimal(r.prix) for r in lignes}, cal, ouvert)
