"""
Pourquoi cette quantité ? Détail du calcul de la commande du soir pour un
produit (lecture seule).

    cd docker
    docker compose run --rm api python -m scripts.expliquer_quantite "ZOLIFY 10"

Affiche, pour chaque produit dont le nom contient le texte : le type de
demande, la fenêtre utilisée, les jours retenus et ceux exclus pour rupture,
le rythme qui en sort, à comparer à la moyenne sur 12 mois (CMM), les plus
grosses ventes de la fenêtre et la décision du soir.
"""
from __future__ import annotations

import asyncio
import sys

from sqlalchemy import text

from app.core.database import AsyncSessionLocal
from app.modules.commandes.repository import CommandesRepository
from app.modules.commandes.service import CommandesService, ErreurCommandes


def _d(x: float) -> str:
    return f"{x:.2f}".replace(".", ",")


async def main(motif: str) -> int:
    async with AsyncSessionLocal() as db:
        ids = [(r.id, r.nom) for r in await db.execute(text(
            "SELECT id, nom FROM nomenclature WHERE nom ILIKE :m AND archive = false ORDER BY nom LIMIT 5"),
            {"m": f"%{motif}%"})]
        if not ids:
            print(f"Aucun produit ne contient « {motif} ».")
            return 1
        svc = CommandesService(CommandesRepository(db), {"username": "script", "role": "admin"})
        for id_nom, nom in ids:
            print(f"\n=== {nom} (id {id_nom}) ===")
            try:
                c = await svc.calcul(id_nom)
            except ErreurCommandes as e:
                print("  ", e.message)
                continue
            print(f"  type de demande      : {c['type']} ({c['jours_vente_12m']} jours de vente sur 12 mois)")
            print(f"  fenêtre              : {c['fenetre_jours']} jours depuis le {c['debut_fenetre']}")
            print(f"  jours ouverts        : {c['jours_ouverts']}")
            print(f"  exclus (rupture)     : {c['jours_exclus_rupture']}  "
                  f"(stock nul dans l'historique : {c['jours_stock_nul']} j, sans historique : "
                  f"{c['jours_sans_historique']} j)")
            print(f"  jours retenus        : {c['jours_retenus']}")
            print(f"  vendu sur la fenêtre : {_d(c['vendu_fenetre'])} (dont jours retenus : "
                  f"{_d(c['vendu_jours_retenus'])}) ; repris de génériques : {_d(c['repris_generiques'])}")
            print(f"  RYTHME               : {_d(c['rythme'])} / jour ouvert  (hors ruptures "
                  f"{_d(c['moyenne_hors_ruptures'])}, brute {_d(c['moyenne_brute'])}, ramené vers la brute "
                  f"avec un poids de 14 jours)" if c["type"] != "lent" else
                  "  RYTHME               : produit lent : 1 boîte en rayon s'il s'est vendu dans les 6 mois")
            print(f"  12 mois              : {_d(c['ventes_12m'])} vendus, CMM {_d(c['cmm'])}, "
                  f"soit {_d(c['moyenne_12m_jour_ouvert'])} / jour ouvert")
            print("  plus grosses ventes  : " + ", ".join(f"{v['date']} : {_d(v['qte'])}"
                                                        for v in c["plus_grosses_ventes"]))
            if c["generique"]:
                print(f"  générique            : groupe {c['generique']['code']}, mode {c['generique']['mode']}, "
                      f"{'gardé' if c['generique']['garde'] else 'remplacé'}")
            d = c["decision"]
            if d:
                print(f"  décision             : {d['quantite']} boîtes = prévu {_d(d['prevu'])} sur "
                      f"{d['jours_couverts']} j + sécurité {_d(d['securite'])} − stock {_d(d['stock'])} "
                      f"− en cours {_d(d['en_cours'])}")
    return 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        raise SystemExit(2)
    raise SystemExit(asyncio.run(main(" ".join(sys.argv[1:]))))
