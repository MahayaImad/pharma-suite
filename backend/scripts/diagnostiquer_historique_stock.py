"""
Diagnostic avant de reconstituer le stock passé (lecture seule).

    cd docker
    docker compose run --rm api python -m scripts.diagnostiquer_historique_stock

1. **Entrées** par type (`type_entree`) : nombre, quantités, quantités
   négatives — comment sont saisis les avoirs fournisseur (`AV`) et les lignes
   sans type.
2. **Ventes** des 12 derniers mois : part des lignes dont le numéro de lot
   retrouve un lot d'entrée (condition de la méthode « par lot »).
3. **Échanges** entre pharmacies et **inventaires** : volumes.
4. **Les deux méthodes** sur les produits les plus vendus, sur 12 mois : part
   des jours à stock négatif (impossible, donc erreur), produits touchés,
   accord des deux méthodes sur les jours de rupture. Pour la méthode par
   produit, deux variantes : avoirs ignorés, ou comptés comme sorties.

Le rapport ne contient que des comptages et des pourcentages : ni nom, ni
montant, ni identifiant de produit. Écrit aussi dans
`logs/diagnostic_historique_stock.md`.
"""
from __future__ import annotations

import argparse
import asyncio
from collections import defaultdict
from datetime import date, timedelta
from pathlib import Path
from statistics import median

from sqlalchemy import text

from app.core.database import AsyncSessionLocal
from app.services.reconstitution_stock import LotHistorique, accord_ruptures, par_lot, par_produit, qualite

lignes: list[str] = []


def ecrire(t: str = "") -> None:
    print(t)
    lignes.append(t)


async def sql(requete: str, **params) -> list:
    """Une session par requête : une colonne absente ne casse pas la suite."""
    async with AsyncSessionLocal() as db:
        try:
            return (await db.execute(text(requete), params)).all()
        except Exception as erreur:
            ecrire(f"> requête impossible : {str(erreur).splitlines()[0][:120]}")
            return []


def pc(x: float) -> str:
    return f"{100 * x:.1f} %".replace(".", ",")


async def main() -> int:
    p = argparse.ArgumentParser(description="Diagnostic de l'historique du stock.")
    p.add_argument("--produits", type=int, default=150, help="produits les plus vendus testés")
    p.add_argument("--sortie", default="logs/diagnostic_historique_stock.md")
    a = p.parse_args()
    aujourdhui = date.today()
    debut = aujourdhui - timedelta(days=365)

    ecrire("# Diagnostic de l'historique du stock\n")

    ecrire("## 1. Entrées par type\n")
    ecrire("| type | lignes | quantité totale | lignes à quantité < 0 |")
    ecrire("|---|---:|---:|---:|")
    for r in await sql("""
        SELECT COALESCE(NULLIF(type_entree, ''), '(vide)') AS type_e, count(*) AS n,
               COALESCE(sum(qte_entree), 0) AS q, count(*) FILTER (WHERE qte_entree < 0) AS neg
        FROM entrees_produits GROUP BY 1 ORDER BY 2 DESC"""):
        ecrire(f"| {r.type_e} | {r.n} | {int(r.q)} | {r.neg} |")

    ecrire("\n## 2. Ventes des 12 derniers mois et numéro de lot\n")
    v = await sql("""
        SELECT count(*) AS n,
               count(*) FILTER (WHERE NULLIF(trim(lot), '') IS NULL) AS sans_lot,
               count(*) FILTER (WHERE EXISTS (
                   SELECT 1 FROM entrees_produits ep WHERE ep.id_nom = sp.id_nom AND ep.lot = sp.lot)) AS lot_trouve
        FROM sorties_produits sp WHERE sp.date > :d AND sp.qte_sortie > 0""", d=debut)
    if v and v[0].n:
        r = v[0]
        ecrire(f"- lignes de vente : {r.n}")
        ecrire(f"- sans numéro de lot : {r.sans_lot} ({pc(r.sans_lot / r.n)})")
        ecrire(f"- lot retrouvé parmi les entrées : {r.lot_trouve} ({pc(r.lot_trouve / r.n)})")

    ecrire("\n## 3. Échanges et inventaires\n")
    for r in await sql("""
        SELECT COALESCE(e.type, '(vide)') AS type_e, count(*) AS n, COALESCE(sum(esp.qte), 0) AS q
        FROM echanges_sorties_produits esp LEFT JOIN echanges e ON e.id = esp.id_echange
        WHERE esp.date_echange > :d GROUP BY 1""", d=debut):
        ecrire(f"- échanges type {r.type_e} : {r.n} lignes, quantité {int(r.q)} (12 mois)")
    for r in await sql("SELECT count(*) AS n, min(date) AS de, max(date) AS a FROM inventaires_produits"):
        ecrire(f"- lignes d'inventaire : {r.n} (du {r.de} au {r.a})")

    ecrire(f"\n## 4. Les deux méthodes sur les {a.produits} produits les plus vendus (12 mois)\n")
    produits = [r.id_nom for r in await sql("""
        SELECT sp.id_nom FROM sorties_produits sp JOIN mv_stock_produits mv ON mv.id_nom = sp.id_nom
        WHERE sp.date > :d GROUP BY sp.id_nom ORDER BY sum(sp.qte_sortie) DESC LIMIT :n""", d=debut, n=a.produits)]
    resultats = defaultdict(list)   # méthode → [(qualité, série)]
    for id_nom in produits:
        stock = (await sql("SELECT stock_actuel FROM mv_stock_produits WHERE id_nom = :i", i=id_nom))[0].stock_actuel
        ventes = {r.date: float(r.q) for r in await sql(
            "SELECT date, sum(qte_sortie) AS q FROM sorties_produits WHERE id_nom = :i AND date > :d GROUP BY date",
            i=id_nom, d=debut)}
        entrees = await sql("""
            SELECT date_entree AS j,
                   COALESCE(sum(qte_entree) FILTER (WHERE COALESCE(type_entree, '') <> 'AV'), 0) AS achats,
                   COALESCE(sum(abs(qte_entree)) FILTER (WHERE type_entree = 'AV'), 0) AS avoirs
            FROM entrees_produits WHERE id_nom = :i AND date_entree > :d GROUP BY date_entree""", i=id_nom, d=debut)
        net_sans_av = {j: -q for j, q in ventes.items()}
        net_av_sortie = dict(net_sans_av)
        for e in entrees:
            net_sans_av[e.j] = net_sans_av.get(e.j, 0.0) + float(e.achats)
            net_av_sortie[e.j] = net_av_sortie.get(e.j, 0.0) + float(e.achats) - float(e.avoirs)
        s1 = par_produit(float(stock), net_sans_av, debut, aujourdhui)
        s2 = par_produit(float(stock), net_av_sortie, debut, aujourdhui)

        lots = {r.lot: LotHistorique(r.entree, float(r.stock)) for r in await sql("""
            SELECT lot, min(date_entree) AS entree, sum(stock) AS stock FROM entrees_produits
            WHERE id_nom = :i AND COALESCE(type_entree, '') <> 'AV' AND lot IS NOT NULL AND date_entree IS NOT NULL
            GROUP BY lot""", i=id_nom)}
        for r in await sql("""
            SELECT lot, date, sum(qte_sortie) AS q FROM sorties_produits
            WHERE id_nom = :i AND date > :d GROUP BY lot, date""", i=id_nom, d=debut):
            if r.lot in lots:
                lots[r.lot].ventes_par_jour[r.date] = float(r.q)
        s3 = par_lot(list(lots.values()), debut, aujourdhui)
        for nom, s in (("par produit, avoirs ignorés", s1), ("par produit, avoirs en sortie", s2), ("par lot", s3)):
            resultats[nom].append((qualite(s), s))

    if not produits:
        ecrire("Aucun produit vendu sur la période.")
    else:
        ecrire("| méthode | jours à stock négatif | produits touchés | médiane des jours en rupture |")
        ecrire("|---|---:|---:|---:|")
        for nom, liste in resultats.items():
            jours = sum(q.jours for q, _ in liste)
            negatifs = sum(q.jours_negatifs for q, _ in liste)
            touches = sum(1 for q, _ in liste if q.jours_negatifs)
            ecrire(f"| {nom} | {pc(negatifs / jours)} | {touches} / {len(liste)} | "
                   f"{median(q.jours_rupture for q, _ in liste):.0f} j |")
        accord = [accord_ruptures(a_[1], b_[1]) for a_, b_ in zip(resultats["par produit, avoirs ignorés"],
                                                                  resultats["par lot"])]
        ecrire(f"\nAccord « par produit » / « par lot » sur les jours de rupture : {pc(sum(accord) / len(accord))}")

    Path(a.sortie).parent.mkdir(parents=True, exist_ok=True)
    Path(a.sortie).write_text("\n".join(lignes), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
