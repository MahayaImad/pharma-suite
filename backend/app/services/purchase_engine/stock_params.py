"""
Calcul des paramètres de stock optimaux.

    SS  = Z(SL) × σ_d × √L
    ROP = d̄ × L + SS
    EOQ = √(2 × D_annuel × S_commande / (h × C))

Niveaux de service par segment ABC :
    A → 95%  (Z = 1.645)
    B → 90%  (Z = 1.282)
    C → 85%  (Z = 1.036)
"""

from __future__ import annotations

import math
from typing import Any

# Coût de passation d'une commande (DA) — paramètre par défaut
DEFAULT_ORDER_COST = 500.0
# Taux de possession annuel par défaut (20% de la valeur stock)
DEFAULT_HOLDING_PCT = 0.20

_Z_BY_SEGMENT = {"A": 1.645, "B": 1.282, "C": 1.036}


def compute_stock_params(
    demande_moy_j: float,           # demande journalière moyenne corrigée
    demande_std_j: float,           # écart-type journalier corrigé
    prix_achat: float,              # prix d'achat unitaire (DA)
    delai_livraison_j: float,       # délai fournisseur (jours)
    segment_abc: str | None = "B",
    holding_cost_pct: float = DEFAULT_HOLDING_PCT,
    order_cost: float = DEFAULT_ORDER_COST,
) -> dict[str, Any]:
    """
    Retourne SS, ROP, EOQ et le délai utilisé.
    Toutes les quantités sont arrondies à l'unité supérieure.
    """
    if demande_moy_j <= 0:
        return {"stock_securite": 0, "rop": 0, "eoq": 0, "holding_cost_pct": holding_cost_pct}

    z = _Z_BY_SEGMENT.get(segment_abc or "B", 1.282)

    # Stock de sécurité
    ss = z * demande_std_j * math.sqrt(max(delai_livraison_j, 1))
    ss = math.ceil(ss)

    # ROP
    rop = math.ceil(demande_moy_j * delai_livraison_j + ss)

    # EOQ (Wilson)
    D_annuel = demande_moy_j * 365
    h_annuel = holding_cost_pct * prix_achat
    if h_annuel > 0 and D_annuel > 0:
        eoq = math.ceil(math.sqrt(2 * D_annuel * order_cost / h_annuel))
    else:
        eoq = max(1, math.ceil(demande_moy_j * 30))  # fallback : 1 mois

    return {
        "stock_securite": ss,
        "rop": rop,
        "eoq": eoq,
        "holding_cost_pct": holding_cost_pct,
        "delai_utilise_j": delai_livraison_j,
        "z_service": z,
    }
