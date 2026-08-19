"""
Correction de la demande censurée (ruptures de stock).

Méthode SBA (Syntetos-Boylan Approximation) :
    demand_corrigé[t] = demand_obs[t] / (1 - p_rupture[t])

Deux modes de détection des ruptures :

Mode PRÉCIS (si historique_stock_jour disponible) :
    Un jour est en rupture si stock_eod = 0 ce jour-là.
    Basé sur la reconstitution exacte du stock depuis entrees + sorties +
    inventaires + rechange_sorties.

Mode PROXY (fallback si pas d'historique reconstitué) :
    Heuristique : run de ≥ MIN_ZERO_RUN jours à 0 vente pendant un jour d'activité.
    Moins précis mais toujours utilisable.
"""

from __future__ import annotations

import logging
from typing import Any

import numpy as np
import pandas as pd

logger = logging.getLogger(__name__)

MIN_GLOBAL_SALES = 5      # ventes globales minimales pour considérer le jour "ouvert"
MIN_ZERO_RUN = 2          # min jours consécutifs à 0 pour qualifier de rupture
MIN_TOTAL_SALES_SBA = 20  # ventes totales minimales sur la période pour appliquer SBA
MAX_P_RUPTURE = 0.80      # cap pour éviter l'explosion de la correction SBA


def correct_censored_demand(
    product_series: pd.Series,      # index=date, values=qte vendue (peut contenir NaN)
    global_activity: pd.Series,     # index=date, values=nb_ventes_totales pharmacie
    stock_history: pd.Series | None = None,  # index=date, values=stock_eod reconstitué
) -> dict[str, Any]:
    """
    Corrige la demande censurée d'un produit.

    Retourne :
        {
          "serie_corrigee": {date_str: float, ...},
          "p_rupture": float,          # proportion de jours en rupture estimée
          "nb_jours_rupture": int,
          "nb_jours_total": int,
        }
    """
    # Aligner les deux séries sur les jours d'activité
    actifs = global_activity[global_activity >= MIN_GLOBAL_SALES].index
    if len(actifs) == 0:
        return _empty_result(product_series)

    prod = product_series.reindex(actifs).fillna(0).astype(float)

    # Pas assez de ventes totales pour que la correction SBA soit fiable
    if prod.sum() < MIN_TOTAL_SALES_SBA:
        serie_dict = {str(d.date()): round(float(v), 4) for d, v in prod.items()}
        return {
            "serie_corrigee": serie_dict,
            "p_rupture": 0.0,
            "nb_jours_rupture": 0,
            "nb_jours_total": len(prod),
        }

    # Détection des ruptures : mode précis si historique stock disponible
    if stock_history is not None and len(stock_history) > 0:
        stock_aligned = stock_history.reindex(actifs)  # NaN = pas de donnée ce jour-là
        # Couverture minimale : si < 20% des jours actifs ont une donnée → fallback heuristique
        coverage = stock_aligned.notna().mean()
        if coverage >= 0.20:
            # Mode précis : rupture UNIQUEMENT si on a une donnée ET stock <= 0 ET 0 vente
            rupture_flags = (stock_aligned <= 0) & stock_aligned.notna() & (prod == 0)
        else:
            rupture_flags = _detect_rupture_runs(prod)
    else:
        # Fallback : heuristique runs de zéros
        rupture_flags = _detect_rupture_runs(prod)

    nb_rupture = int(rupture_flags.sum())
    nb_total = len(prod)
    p_rupture = nb_rupture / nb_total if nb_total > 0 else 0.0
    p_rupture = min(p_rupture, MAX_P_RUPTURE)  # cap anti-explosion

    # Correction SBA : demand_corrigé = obs / (1 - p_rupture) sur les jours de rupture
    # Pour les jours non-rupture on garde la valeur observée
    corrected = prod.copy()
    if p_rupture > 0 and p_rupture < 1:
        # Estimer la demande journalière moyenne sur les jours sans rupture
        mean_non_zero = prod[~rupture_flags & (prod > 0)].mean()
        if np.isnan(mean_non_zero) or mean_non_zero == 0:
            mean_non_zero = prod[prod > 0].mean() if (prod > 0).any() else 0.0
        fill_value = mean_non_zero / (1 - p_rupture) if p_rupture < 1 else mean_non_zero
        corrected[rupture_flags] = fill_value

    serie_dict = {str(d.date()): round(float(v), 4) for d, v in corrected.items()}

    return {
        "serie_corrigee": serie_dict,
        "p_rupture": round(p_rupture, 4),
        "nb_jours_rupture": nb_rupture,
        "nb_jours_total": nb_total,
    }


def _detect_rupture_runs(series: pd.Series) -> pd.Series:
    """Marque True les jours de zéros consécutifs ≥ MIN_ZERO_RUN."""
    is_zero = series == 0
    flags = pd.Series(False, index=series.index)

    run_start = None
    run_len = 0
    for i, (idx, val) in enumerate(series.items()):
        if val == 0:
            if run_start is None:
                run_start = i
            run_len += 1
        else:
            if run_len >= MIN_ZERO_RUN and run_start is not None:
                flags.iloc[run_start: run_start + run_len] = True
            run_start = None
            run_len = 0
    # Dernier run
    if run_len >= MIN_ZERO_RUN and run_start is not None:
        flags.iloc[run_start: run_start + run_len] = True

    return flags


def _empty_result(series: pd.Series) -> dict[str, Any]:
    serie_dict = {str(d.date()): float(v) for d, v in series.fillna(0).items()}
    return {
        "serie_corrigee": serie_dict,
        "p_rupture": 0.0,
        "nb_jours_rupture": 0,
        "nb_jours_total": len(series),
    }
