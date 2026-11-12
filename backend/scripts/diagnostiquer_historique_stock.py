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
4. **Les méthodes** sur les produits les plus vendus, sur 12 mois : part des
   jours à stock négatif (impossible, donc erreur), produits touchés, jours
   de rupture. Par produit (avoirs ignorés ou en sortie) ; par lot (ventes
   seules, ou tous les mouvements du docs/BUSINESS_LOGIC.md §3.4 : avoirs,
   échanges, ajustements d'inventaire).

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
from app.services.historique_stock import INVENTAIRE_RESOLU
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

    ecrire("\nAchats et échanges reçus (`type_achat`) :\n")
    for r in await sql("""
        SELECT COALESCE(NULLIF(type_achat, ''), '(vide)') AS type_a, count(*) AS n,
               count(*) FILTER (WHERE prix_achat = 0) AS prix_nul
        FROM entrees_produits GROUP BY 1 ORDER BY 2 DESC"""):
        ecrire(f"- `{r.type_a}` : {r.n} lignes, dont {r.prix_nul} à prix d'achat nul")

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
    for r in await sql("""
        SELECT count(*) FILTER (WHERE ecart <> 0) AS n,
               COALESCE(sum(ecart) FILTER (WHERE ecart > 0), 0) AS plus,
               COALESCE(sum(ecart) FILTER (WHERE ecart < 0), 0) AS moins,
               count(*) FILTER (WHERE ecart <> 0 AND NULLIF(trim(lot), '') IS NULL) AS sans_lot
        FROM inventaires_produits WHERE date > :d""", d=debut):
        ecrire(f"- ajustements sur 12 mois : {r.n} lignes, +{int(r.plus)} / {int(r.moins)} unités, "
               f"{r.sans_lot} sans numéro de lot")

    ecrire("\n### Clé produit des lignes d'inventaire (12 mois)\n")
    ecrire("Hypothèses pour rattacher une ligne d'inventaire à son lot : `id_produit` = ligne de lot "
           "(`entrees_produits.id`), l'identifiant de ligne de stock partagé "
           "(`entrees_produits.id_produit`), ou le produit (`nomenclature.id`). La bonne retrouve "
           "le même nom et le même numéro de lot.\n")
    base = await sql("""
        SELECT count(*) AS n, count(*) FILTER (WHERE id_nom IS NULL) AS sans_id_nom,
               count(*) FILTER (WHERE id_produit IS NULL) AS sans_id_produit
        FROM inventaires_produits WHERE date > :d""", d=debut)
    n = base[0].n if base else 0
    if n:
        ecrire(f"- lignes : {n} ; id_nom vide {pc(base[0].sans_id_nom / n)} ; "
               f"id_produit vide {pc(base[0].sans_id_produit / n)}")
        for r in await sql("""
            SELECT count(*) AS lignes, count(DISTINCT code_barre) AS distincts
            FROM entrees_produits WHERE NULLIF(trim(code_barre), '') IS NOT NULL"""):
            if r.lignes:
                ecrire(f"- code-barres des lots : {r.distincts} distincts pour {r.lignes} lignes "
                       f"({pc(r.distincts / r.lignes)} uniques)")
        hypotheses = {
            "code-barres (entrees_produits.code_barre)":
                "LATERAL (SELECT * FROM entrees_produits x WHERE x.code_barre = ip.code_barre "
                "AND NULLIF(trim(ip.code_barre), '') IS NOT NULL ORDER BY x.id DESC LIMIT 1) e ON true",
            "ligne de lot (entrees_produits.id)": "entrees_produits e ON e.id = ip.id_produit",
            "ligne de stock (entrees_produits.id_produit)":
                "(SELECT DISTINCT ON (id_produit) * FROM entrees_produits ORDER BY id_produit, id DESC) e "
                "ON e.id_produit = ip.id_produit",
        }
        for nom, jointure in hypotheses.items():
            for r in await sql(f"""
                SELECT count(e.id) AS existe,
                       count(*) FILTER (WHERE e.id IS NOT NULL AND COALESCE(trim(e.lot), '') = COALESCE(trim(ip.lot), ''))
                           AS meme_lot,
                       count(*) FILTER (WHERE e.id IS NOT NULL AND nm.nom = ip.produit) AS meme_nom
                FROM inventaires_produits ip
                LEFT JOIN {jointure}
                LEFT JOIN nomenclature nm ON nm.id = e.id_nom
                WHERE ip.date > :d""", d=debut):
                ecrire(f"- {nom} : trouvée {pc(r.existe / n)}, même numéro de lot {pc(r.meme_lot / n)}, "
                       f"même nom {pc(r.meme_nom / n)}")
        for r in await sql("""
            SELECT count(nm.id) AS existe, count(*) FILTER (WHERE nm.nom = ip.produit) AS meme_nom
            FROM inventaires_produits ip LEFT JOIN nomenclature nm ON nm.id = ip.id_produit
            WHERE ip.date > :d""", d=debut):
            ecrire(f"- produit (nomenclature.id) : trouvé {pc(r.existe / n)}, même nom {pc(r.meme_nom / n)}")

    ecrire("\n### Ventes rattachées à leur lot par `id_produit` (12 mois)\n")
    for r in await sql("""
        SELECT count(*) AS n,
               count(*) FILTER (WHERE NULLIF(trim(sp.lot), '') IS NULL) AS sans_lot,
               count(*) FILTER (WHERE EXISTS (SELECT 1 FROM entrees_produits e
                                              WHERE e.id_produit = sp.id_produit AND e.id_nom = sp.id_nom)) AS par_id,
               count(*) FILTER (WHERE NULLIF(trim(sp.lot), '') IS NULL AND EXISTS (
                   SELECT 1 FROM entrees_produits e WHERE e.id_produit = sp.id_produit AND e.id_nom = sp.id_nom))
                   AS sans_lot_par_id
        FROM sorties_produits sp WHERE sp.date > :d AND sp.qte_sortie > 0""", d=debut):
        if r.n:
            ecrire(f"- ventes dont id_produit retrouve une ligne de stock du même produit : {pc(r.par_id / r.n)}")
            if r.sans_lot:
                ecrire(f"- parmi les {r.sans_lot} ventes sans numéro de lot : {pc(r.sans_lot_par_id / r.sans_lot)}")

    ecrire("\n### Motifs des ajustements (12 mois)\n")
    ecrire("| motif | lignes | unités en plus | unités en moins |")
    ecrire("|---|---:|---:|---:|")
    for r in await sql("""
        SELECT COALESCE(NULLIF(trim(motif), ''), '(vide)') AS m, count(*) AS n,
               COALESCE(sum(ecart) FILTER (WHERE ecart > 0), 0) AS plus,
               COALESCE(sum(ecart) FILTER (WHERE ecart < 0), 0) AS moins
        FROM inventaires_produits WHERE date > :d AND ecart <> 0 GROUP BY 1 ORDER BY 2 DESC LIMIT 15""", d=debut):
        ecrire(f"| {r.m} | {r.n} | {int(r.plus)} | {int(r.moins)} |")
    for r in await sql(f"""
        SELECT count(DISTINCT ip.id_nom) AS n, COALESCE(sum(-ip.ecart), 0) AS u
        FROM ({INVENTAIRE_RESOLU}) ip
        WHERE ip.date > :d AND ip.ecart < 0 AND ip.id_nom IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM sorties_produits sp WHERE sp.id_nom = ip.id_nom AND sp.qte_sortie > 0)""",
            d=debut):
        ecrire(f"\nProduits jamais vendus mais ajustés à la baisse (consommables donnés probables) : "
               f"{r.n} produits, {int(r.u)} unités")

    ecrire(f"\n## 4. Les méthodes sur les {a.produits} produits les plus vendus (12 mois)\n")
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

        # Méthode par lot (docs/BUSINESS_LOGIC.md §3.4). Un numéro de lot vide
        # regroupe les lots sans numéro du produit.
        def lots_du_produit(lignes_lots):
            return {r.lot: LotHistorique(r.entree, float(r.stock)) for r in lignes_lots}

        requete_lots = """
            SELECT COALESCE(trim(lot), '') AS lot, min(date_entree) AS entree, sum(stock) AS stock
            FROM entrees_produits
            WHERE id_nom = :i AND COALESCE(type_entree, '') <> 'AV' AND date_entree IS NOT NULL
            GROUP BY 1"""
        lignes_lots = await sql(requete_lots, i=id_nom)
        ventes_lot = await sql("""
            SELECT COALESCE(trim(lot), '') AS lot, date, sum(qte_sortie) AS q FROM sorties_produits
            WHERE id_nom = :i AND date > :d GROUP BY 1, 2""", i=id_nom, d=debut)
        avoirs_lot = await sql("""
            SELECT COALESCE(trim(lot), '') AS lot, date_entree AS date, sum(abs(qte_entree)) AS q
            FROM entrees_produits WHERE id_nom = :i AND type_entree = 'AV' AND date_entree > :d GROUP BY 1, 2""",
            i=id_nom, d=debut)
        echanges_lot = await sql("""
            SELECT COALESCE(trim(lot), '') AS lot, date_echange AS date, sum(qte) AS q
            FROM echanges_sorties_produits WHERE id_nom = :i AND date_echange > :d GROUP BY 1, 2""",
            i=id_nom, d=debut)
        ajustements_lot = await sql(f"""
            SELECT COALESCE(trim(lot), '') AS lot, date, sum(ecart) AS q FROM ({INVENTAIRE_RESOLU}) ir
            WHERE id_nom = :i AND date > :d AND ecart <> 0 GROUP BY 1, 2""", i=id_nom, d=debut)

        ventes_seules = lots_du_produit(lignes_lots)
        complet = lots_du_produit(lignes_lots)
        for r in ventes_lot:
            for lots in (ventes_seules, complet):
                if r.lot in lots:
                    lots[r.lot].ajouter_sortie(r.date, float(r.q))
        for r in list(avoirs_lot) + list(echanges_lot):
            if r.lot in complet:
                complet[r.lot].ajouter_sortie(r.date, float(r.q))
        for r in ajustements_lot:
            if r.lot in complet:
                complet[r.lot].ajouter_ajustement(r.date, float(r.q))
        s3 = par_lot(list(ventes_seules.values()), debut, aujourdhui)
        s4 = par_lot(list(complet.values()), debut, aujourdhui)
        for nom, s in (("par produit, avoirs ignorés", s1), ("par produit, avoirs en sortie", s2),
                       ("par lot, ventes seules", s3), ("par lot, tous les mouvements", s4)):
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
        accord = [accord_ruptures(a_[1], b_[1]) for a_, b_ in zip(resultats["par lot, ventes seules"],
                                                                  resultats["par lot, tous les mouvements"])]
        ecrire("\nAccord « par lot, ventes seules » / « par lot, tous les mouvements » sur les jours de "
               f"rupture : {pc(sum(accord) / len(accord))}")

    Path(a.sortie).parent.mkdir(parents=True, exist_ok=True)
    Path(a.sortie).write_text("\n".join(lignes), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
