"""
Contrôle de la synchronisation du stock sur 20 produits.

    cd docker
    docker compose run --rm api python -m scripts.controler_stock

Le stock d'EASYPHARM est un champ (`entrees_produits.stock`), pas un calcul
(docs/BUSINESS_LOGIC.md §3.3) : il n'y a pas de formule à valider, seulement
à vérifier que PharmaSuite a bien la valeur du moment. Ce script affiche 20
produits avec leurs lots ; on compare, produit par produit, à l'écran
d'EASYPHARM.

Les produits sont choisis là où une synchronisation en défaut se verrait :

    A  — 6 produits de classe A à plusieurs lots
    V  — 5 produits vendus aujourd'hui ou hier (stock qui vient de bouger)
    E  — 4 produits dont un lot vient d'être épuisé
    R  — 3 produits de classe A en rupture
    H  — 2 produits pris au hasard

⚠️ Ce rapport contient des **noms de produits** : il se lit sur le serveur,
il n'est pas fait pour être envoyé. Il ne modifie rien.

Faire la comparaison juste après une passe de l'agent, pharmacie calme :
une vente faite entre la passe et la lecture crée un écart normal.
"""
from __future__ import annotations

import argparse
import asyncio

from sqlalchemy import text

from app.core.database import AsyncSessionLocal

# Chaque groupe : (code, libellé, nombre, requête rendant des id de produits).
# ORDER BY random() : un tirage différent à chaque lancement.
GROUPES = [
    ("A", "classe A, plusieurs lots", 6, """
        SELECT n.id FROM nomenclature n
        JOIN entrees_produits ep ON ep.id_nom = n.id AND ep.stock > 0
        WHERE n.segment_abc = 'A'
        GROUP BY n.id HAVING count(*) >= 2
        ORDER BY random() LIMIT :n
    """),
    ("V", "vendu aujourd'hui ou hier", 5, """
        SELECT id_nom FROM sorties_produits
        WHERE date >= CURRENT_DATE - 1 AND id_nom IN (SELECT id FROM nomenclature)
        GROUP BY id_nom ORDER BY random() LIMIT :n
    """),
    ("E", "un lot récemment épuisé", 4, """
        SELECT ep.id_nom FROM entrees_produits ep
        JOIN sorties_produits sp ON sp.id_nom = ep.id_nom AND sp.date >= CURRENT_DATE - 3
        WHERE ep.stock = 0 AND ep.id_nom IN (SELECT id FROM nomenclature)
        GROUP BY ep.id_nom ORDER BY random() LIMIT :n
    """),
    ("R", "classe A en rupture", 3, """
        SELECT n.id FROM nomenclature n
        JOIN mv_stock_produits mv ON mv.id_nom = n.id
        WHERE n.segment_abc = 'A' AND mv.stock_actuel = 0
        ORDER BY random() LIMIT :n
    """),
    ("H", "au hasard", 2, """
        SELECT id_nom FROM mv_stock_produits WHERE actif ORDER BY random() LIMIT :n
    """),
]


async def choisir(db) -> list[tuple[int, str]]:
    choisis: dict[int, str] = {}
    for code, libelle, nombre, requete in GROUPES:
        # On en demande plus que nécessaire : un produit peut déjà être pris.
        ids = [l[0] for l in await db.execute(text(requete), {"n": nombre * 3})]
        pris = 0
        for i in ids:
            if i not in choisis and pris < nombre:
                choisis[i] = f"{code} — {libelle}"
                pris += 1
    return list(choisis.items())


async def main() -> None:
    parseur = argparse.ArgumentParser(description="Contrôle du stock sur 20 produits.")
    parseur.add_argument("--lots-epuises", type=int, default=3,
                         help="nombre de lots à stock nul affichés par produit (défaut 3)")
    args = parseur.parse_args()

    async with AsyncSessionLocal() as db:
        fraicheur = (await db.execute(text("""
            SELECT to_char(last_sync_at AT TIME ZONE 'Africa/Algiers', 'DD/MM/YYYY HH24:MI')
            FROM sync_status WHERE table_name = 'entrees_produits'
        """))).scalar()
        derniere_vente = (await db.execute(text(
            "SELECT max(date) FROM sorties_produits"))).scalar()

        print("# Contrôle du stock — à comparer à l'écran d'EASYPHARM\n")
        print(f"- Dernier nouveau lot reçu de l'agent : {fraicheur or 'inconnu'} (heure d'Alger)")
        print(f"- Dernière vente connue : {derniere_vente or 'aucune'}")
        print("- Comparer juste après une passe de l'agent (voir agent.log).\n")

        produits = await choisir(db)
        if not produits:
            print("Aucun produit à contrôler : la base est-elle chargée, le classement lancé ?")
            return

        for rang, (id_nom, groupe) in enumerate(produits, 1):
            p = (await db.execute(text("""
                SELECT n.nom, n.dci, n.dosage, n.forme_abr, n.code_barre_original,
                       n.segment_abc, n.segment_xyz,
                       mv.stock_actuel, mv.prix_vente, mv.derniere_vente
                FROM nomenclature n
                LEFT JOIN mv_stock_produits mv ON mv.id_nom = n.id
                WHERE n.id = :id
            """), {"id": id_nom})).one()
            classe = f"{p.segment_abc or '-'}{p.segment_xyz or '-'}"
            print(f"## {rang}. {p.nom}  [{groupe}]")
            detail = " ".join(x for x in (p.dci, p.dosage, p.forme_abr) if x) or "—"
            print(f"   id {id_nom} · {detail}"
                  + f" · code-barres {p.code_barre_original or '—'} · classe {classe}")
            print(f"   **STOCK TOTAL : {p.stock_actuel}**   prix de vente {p.prix_vente or 0:.2f}"
                  f"   dernière vente {p.derniere_vente or '—'}")

            lots = (await db.execute(text("""
                (SELECT id, lot, peremption, stock, prix_vente, date_entree, 0 AS ordre
                 FROM entrees_produits WHERE id_nom = :id AND stock <> 0)
                UNION ALL
                (SELECT id, lot, peremption, stock, prix_vente, date_entree, 1
                 FROM entrees_produits WHERE id_nom = :id AND stock = 0
                 ORDER BY id DESC LIMIT :epuises)
                ORDER BY ordre, id
            """), {"id": id_nom, "epuises": args.lots_epuises})).all()
            if not lots:
                print("   (aucun lot)")
            else:
                print("   | lot | péremption | stock | prix vente | entré le | id lot |")
                print("   |---|---|---|---|---|---|")
                for l in lots:
                    marque = "" if l.stock else " (épuisé)"
                    print(f"   | {l.lot or '—'} | {l.peremption or '—'} | **{l.stock}**{marque} "
                          f"| {l.prix_vente or 0:.2f} | {l.date_entree or '—'} | {l.id} |")
            print("   Conforme ☐   Écart ☐ : ______\n")

        print(f"{len(produits)} produit(s). Un écart sur un produit vendu depuis la dernière "
              "passe est normal ; tout autre écart est à signaler avec l'id du lot.")


if __name__ == "__main__":
    asyncio.run(main())
