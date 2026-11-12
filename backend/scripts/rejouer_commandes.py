"""
Rejouer les 12 derniers mois comme si PharmaSuite avait commandé (lecture seule).

    cd docker
    docker compose run --rm api python -m scripts.rejouer_commandes

Pour chaque produit actif (consommables confirmés exclus), jour par jour :
la demande est celle réellement vendue, les commandes sont celles que la
méthode aurait passées chaque soir (sauf le vendredi), livrées après le délai
du fournisseur (jeudi → dimanche). Comparaison avec la réalité, tirée de
l'historique du stock :

- jours de rupture (stock nul en fin de journée), réels et simulés ;
- stock moyen immobilisé, au prix d'achat moyen, réel et simulé ;
- part de la demande servie par la méthode ;
- nombre de lignes de commande.

Par type de demande et par classe ABC. Le rapport ne contient que des
comptages, des pourcentages et des montants agrégés. Aussi dans
`logs/rejeu_commandes.md`. Rien n'est écrit en base.
"""
from __future__ import annotations

import argparse
import asyncio
import time
from collections import defaultdict
from datetime import date, datetime, timedelta, timezone
from decimal import Decimal
from pathlib import Path
from zoneinfo import ZoneInfo

from app.core.database import AsyncSessionLocal
from app.services.prevision.donnees import charger
from app.services.prevision.rejeu import Resultat, simuler

lignes: list[str] = []


def ecrire(t: str = "") -> None:
    print(t)
    lignes.append(t)


def pc(x: float) -> str:
    return f"{100 * x:.1f} %".replace(".", ",")


def da(x: Decimal) -> str:
    return f"{int(x.quantize(Decimal(1))):,} DA".replace(",", " ")


def tableau(titre: str, groupes: dict[str, list[Resultat]], prix: dict[int, Decimal]) -> None:
    ecrire(f"\n## {titre}\n")
    ecrire("| groupe | produits | rupture réelle | rupture simulée | stock moyen réel | stock moyen simulé "
           "| demande servie | lignes de commande |")
    ecrire("|---|---:|---:|---:|---:|---:|---:|---:|")
    for nom, rs in groupes.items():
        jours = sum(r.jours for r in rs) or 1
        demande = sum(r.demande for r in rs)
        servie = sum(r.servie for r in rs)
        reel = sum((Decimal(str(round(r.stock_moyen_reel, 4))) * prix[r.id] for r in rs), Decimal(0))
        simule = sum((Decimal(str(round(r.stock_moyen_simule, 4))) * prix[r.id] for r in rs), Decimal(0))
        ecrire(f"| {nom} | {len(rs)} | {pc(sum(r.rupture_reelle for r in rs) / jours)} | "
               f"{pc(sum(r.rupture_simulee for r in rs) / jours)} | {da(reel)} | {da(simule)} | "
               f"{pc(servie / demande) if demande else '—'} | {sum(r.commandes for r in rs)} |")


async def main() -> int:
    p = argparse.ArgumentParser(description="Rejoue 12 mois de commandes.")
    p.add_argument("--jours", type=int, default=365)
    p.add_argument("--produits", type=int, default=None, help="limiter aux N produits les plus vendus")
    p.add_argument("--sortie", default="logs/rejeu_commandes.md")
    a = p.parse_args()

    depart = time.monotonic()
    hier = datetime.now(timezone.utc).astimezone(ZoneInfo("Africa/Algiers")).date() - timedelta(days=1)
    async with AsyncSessionLocal() as db:
        donnees = await charger(db, hier, a.jours, a.produits)
    resultats = [simuler(pr, donnees.dates, donnees.debut_rejeu, donnees.calendrier, donnees.ouvert)
                 for pr in donnees.produits]
    duree = time.monotonic() - depart

    ecrire("# Rejeu des commandes\n")
    ecrire(f"- période rejouée : du {donnees.dates[donnees.debut_rejeu]} au {donnees.dates[-1]}")
    ecrire(f"- produits : {len(resultats)} (consommables confirmés exclus)")
    ecrire(f"- gardes connues : {len(donnees.calendrier.gardes)} ; effet des gardes : "
           + (", ".join(f"{t} × {f:.2f}".replace(".", ",") for t, f in sorted(donnees.calendrier.facteurs_garde.items()))
              or "aucune garde avant le rejeu"))
    ecrire("- profil de la semaine (lundi → dimanche) : "
           + " · ".join(f"{x:.2f}".replace(".", ",") for x in donnees.calendrier.semaine))
    saisonniers = sum(1 for pr in donnees.produits if pr.saison is not None)
    ecrire(f"- produits saisonniers reconnus : {saisonniers}")
    ecrire(f"- durée : {duree:.0f} s")

    tableau("Ensemble", {"tous les produits": resultats}, donnees.prix)
    par_type: dict[str, list[Resultat]] = defaultdict(list)
    par_abc: dict[str, list[Resultat]] = defaultdict(list)
    for r in resultats:
        par_type[r.type].append(r)
        par_abc[r.classe_abc or "non classé"].append(r)
    ordre_types = ["regulier", "irregulier", "intermittent", "sporadique", "lent", "nouveau"]
    tableau("Par type de demande", {t: par_type[t] for t in ordre_types if par_type.get(t)}, donnees.prix)
    tableau("Par classe ABC", {c: par_abc[c] for c in sorted(par_abc)}, donnees.prix)

    ecrire("\nLecture : la rupture réelle vient de l'historique du stock ; la demande des jours de rupture "
           "réelle est inconnue (souvent plus forte que les ventes enregistrées), ce qui avantage un peu "
           "la réalité dans la comparaison.")
    Path(a.sortie).parent.mkdir(parents=True, exist_ok=True)
    Path(a.sortie).write_text("\n".join(lignes), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
