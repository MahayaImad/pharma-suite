"""
Reconstituer l'historique du stock (par lot) dans `historique_stock_jour`.

    cd docker
    docker compose run --rm api python -m scripts.reconstituer_historique_stock --essai
    docker compose run --rm api python -m scripts.reconstituer_historique_stock

`--essai` calcule tout et donne le rapport sans rien écrire. Sans lui, écrit
le stock de fin de journée de chaque produit actif ou en stock, chaque jour
depuis `--depuis` (défaut : 2024-01-01 ; les lots d'avant 2023 n'étant pas
dans la base, 2023 serait sous-estimé). Les photos du soir ne sont jamais
remplacées. Relançable sans risque : chaque jour est réécrit.

Rapport : comptages et pourcentages seulement. Aussi dans
`logs/reconstitution_historique_stock.md`.
"""
from __future__ import annotations

import argparse
import asyncio
import time
from datetime import date
from pathlib import Path

from app.core.database import AsyncSessionLocal
from app.services.historique_stock import reconstituer


def pc(x: float) -> str:
    return f"{100 * x:.1f} %".replace(".", ",")


async def main() -> int:
    p = argparse.ArgumentParser(description="Reconstitue l'historique du stock par lot.")
    p.add_argument("--depuis", type=date.fromisoformat, default=date(2024, 1, 1))
    p.add_argument("--essai", action="store_true", help="calculer sans écrire")
    p.add_argument("--sortie", default="logs/reconstitution_historique_stock.md")
    a = p.parse_args()

    debut = time.monotonic()
    async with AsyncSessionLocal() as db:
        r = (await reconstituer(db, a.depuis, date.today(), ecrire=not a.essai)).resume()
    duree = time.monotonic() - debut

    lignes = [
        "# Reconstitution de l'historique du stock (par lot)\n",
        f"- période : du {r['debut']} au {r['fin']}",
        f"- produits : {r['produits']}",
        f"- jours {'calculés' if a.essai else 'écrits'} : {r['jours_ecrits']}"
        + (" (essai : rien n'est écrit)" if a.essai else ""),
        f"- photos du soir conservées : {r['photos_preservees']}",
        f"- jours à stock négatif (ramenés à 0) : {pc(r['part_jours_negatifs'])}, "
        f"sur {r['produits_avec_negatif']} produits",
        f"- jours en rupture : {pc(r['part_jours_en_rupture'])}",
        f"- durée : {duree:.0f} s",
    ]
    texte = "\n".join(lignes)
    print(texte)
    Path(a.sortie).parent.mkdir(parents=True, exist_ok=True)
    Path(a.sortie).write_text(texte, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
