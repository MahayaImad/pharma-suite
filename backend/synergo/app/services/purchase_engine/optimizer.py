"""
Optimisation des quantités à commander — PuLP (LP à variables entières).

Objectif : minimiser le coût total d'achat Σ(qté_i × prix_i).

Contraintes :
    - budget_max : Σ(qté_i × prix_i) ≤ budget
    - qté_i ≥ qte_min_i  (= max(0, ROP - stock_actuel))
    - qté_i ≤ qte_max_i  (= 3 × EOQ_i)
    - qté_i ∈ ℤ≥0

Si le budget est None, pas de contrainte de budget (optimisation pure).
"""

from __future__ import annotations

import logging
from typing import Any

logger = logging.getLogger(__name__)


def optimize_order(
    produits: list[dict[str, Any]],
    budget_max: float | None = None,
) -> dict[str, Any]:
    """
    Paramètres produits (liste de dicts) :
        - id_nom        : int
        - nom           : str
        - prix_achat    : float  — prix unitaire d'achat
        - qte_min       : int    — quantité minimale (ROP - stock, ≥ 0)
        - qte_max       : int    — quantité maximale (3 × EOQ)
        - eoq           : int    — quantité économique

    Retourne :
        {
          "statut": "optimal" | "infeasible" | "erreur",
          "cout_total": float,
          "nb_produits": int,
          "lignes": [{"id_nom", "nom", "qte_commandee", "cout_ligne"}, ...]
        }
    """
    try:
        import pulp
    except ImportError:
        logger.error("PuLP non installé")
        return {"statut": "erreur", "message": "PuLP non disponible"}

    if not produits:
        return {"statut": "optimal", "cout_total": 0, "nb_produits": 0, "lignes": []}

    prob = pulp.LpProblem("commande_achat", pulp.LpMinimize)

    # Variables de décision : quantités entières
    vars_q = {
        p["id_nom"]: pulp.LpVariable(
            f"q_{p['id_nom']}",
            lowBound=int(p["qte_min"]),
            upBound=int(p["qte_max"]),
            cat="Integer",
        )
        for p in produits
    }

    # Objectif : minimiser le coût total
    prob += pulp.lpSum(vars_q[p["id_nom"]] * float(p["prix_achat"]) for p in produits)

    # Contrainte budget
    if budget_max is not None and budget_max > 0:
        prob += (
            pulp.lpSum(vars_q[p["id_nom"]] * float(p["prix_achat"]) for p in produits)
            <= budget_max,
            "budget_max",
        )

    # Résolution silencieuse
    solver = pulp.PULP_CBC_CMD(msg=0)
    prob.solve(solver)

    status = pulp.LpStatus[prob.status]
    if status not in ("Optimal", "Feasible"):
        logger.warning("LP status : %s", status)
        return {"statut": "infeasible", "message": f"Solveur : {status}"}

    lignes = []
    cout_total = 0.0
    prix_map = {p["id_nom"]: p for p in produits}

    for id_nom, var in vars_q.items():
        qte = int(round(pulp.value(var) or 0))
        if qte > 0:
            p = prix_map[id_nom]
            cout_ligne = qte * float(p["prix_achat"])
            cout_total += cout_ligne
            lignes.append({
                "id_nom": id_nom,
                "nom": p.get("nom", ""),
                "qte_commandee": qte,
                "cout_ligne": round(cout_ligne, 2),
            })

    lignes.sort(key=lambda x: x["cout_ligne"], reverse=True)

    return {
        "statut": "optimal",
        "cout_total": round(cout_total, 2),
        "nb_produits": len(lignes),
        "lignes": lignes,
    }
