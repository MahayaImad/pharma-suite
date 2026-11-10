"""
Lance le classement ABC / XYZ et affiche sa répartition.

    cd docker
    docker compose run --rm api python -m scripts.calculer_segments

Le classement tourne aussi tout seul le 1er de chaque mois. Ce script sert à
le lancer une première fois, ou après une correction, et à lire le résultat.
Il n'écrit que `nomenclature.segment_abc` et `nomenclature.segment_xyz`.
Le rapport ne contient que des comptages et des montants, aucun nom.
"""
from __future__ import annotations

import asyncio

from sqlalchemy import text

from app.core.database import AsyncSessionLocal
from app.services.stock_segmentation import compute_abc, compute_xyz


async def tableau(db, titre: str, requete: str) -> None:
    print(f"\n**{titre}**\n")
    lignes = (await db.execute(text(requete))).all()
    if not lignes:
        print("- (aucune ligne)")
        return
    colonnes = list(lignes[0]._mapping.keys())
    print("| " + " | ".join(colonnes) + " |")
    print("|" + "---|" * len(colonnes))
    for ligne in lignes:
        print("| " + " | ".join("∅" if v is None else str(v) for v in ligne) + " |")


async def main() -> None:
    async with AsyncSessionLocal() as db:
        abc = await compute_abc(db)
        xyz = await compute_xyz(db)
        print(f"# Classement ABC / XYZ\n\n- Produits classés ABC : {abc}\n- Produits classés XYZ : {xyz}")

        await tableau(db, "Classe ABC — chiffre d'affaires net sur 12 mois", """
            WITH ca AS (
                SELECT id_nom, SUM(qte_sortie * prix_vente) AS ca
                FROM sorties_produits
                WHERE date >= CURRENT_DATE - INTERVAL '12 months'
                GROUP BY id_nom
            )
            SELECT COALESCE(n.segment_abc, 'sans classe') AS classe,
                   count(*) AS produits,
                   round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct_produits,
                   round(COALESCE(sum(ca.ca), 0), 0) AS ca_12m,
                   round(100.0 * COALESCE(sum(ca.ca), 0)
                         / NULLIF(sum(sum(ca.ca)) OVER (), 0), 1) AS pct_ca,
                   round(COALESCE(sum(mv.valeur_achat), 0), 0) AS valeur_stock_achat,
                   count(*) FILTER (WHERE mv.stock_actuel > 0) AS en_stock,
                   count(*) FILTER (WHERE mv.stock_actuel = 0 AND mv.actif) AS en_rupture
            FROM nomenclature n
            LEFT JOIN ca ON ca.id_nom = n.id
            LEFT JOIN mv_stock_produits mv ON mv.id_nom = n.id
            GROUP BY n.segment_abc
            ORDER BY n.segment_abc NULLS LAST
        """)

        await tableau(db, "Classe XYZ — régularité de la demande", """
            SELECT COALESCE(segment_xyz, 'sans classe') AS classe,
                   count(*) AS produits,
                   round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct_produits
            FROM nomenclature
            GROUP BY segment_xyz
            ORDER BY segment_xyz NULLS LAST
        """)

        await tableau(db, "Matrice ABC × XYZ (produits classés) : nombre, et dont en rupture", """
            SELECT n.segment_abc AS abc,
                   count(*) FILTER (WHERE n.segment_xyz = 'X') AS x,
                   count(*) FILTER (WHERE n.segment_xyz = 'X' AND mv.stock_actuel = 0) AS x_rupture,
                   count(*) FILTER (WHERE n.segment_xyz = 'Y') AS y,
                   count(*) FILTER (WHERE n.segment_xyz = 'Y' AND mv.stock_actuel = 0) AS y_rupture,
                   count(*) FILTER (WHERE n.segment_xyz = 'Z') AS z,
                   count(*) FILTER (WHERE n.segment_xyz = 'Z' AND mv.stock_actuel = 0) AS z_rupture
            FROM nomenclature n
            LEFT JOIN mv_stock_produits mv ON mv.id_nom = n.id
            WHERE n.segment_abc IS NOT NULL
            GROUP BY n.segment_abc
            ORDER BY n.segment_abc
        """)

        await tableau(db, "Produits sans classe", """
            SELECT count(*) AS total,
                   count(*) FILTER (WHERE mv.stock_actuel > 0) AS en_stock_sans_vente_12m,
                   round(COALESCE(sum(mv.valeur_achat) FILTER (WHERE mv.stock_actuel > 0), 0), 0)
                       AS valeur_achat_dormante,
                   count(*) FILTER (WHERE NOT COALESCE(mv.actif, false)) AS inactifs
            FROM nomenclature n
            LEFT JOIN mv_stock_produits mv ON mv.id_nom = n.id
            WHERE n.segment_abc IS NULL
        """)


if __name__ == "__main__":
    asyncio.run(main())
