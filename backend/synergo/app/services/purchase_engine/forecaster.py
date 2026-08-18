"""
Prévision de la demande — sélection automatique du meilleur modèle.

Modèles disponibles :
    - croston          : demande intermittente (CV > 0.5 ET zeros > 20%)
    - holt_winters     : saisonnalité détectée (CV < 0.5)
    - ols              : régression linéaire avec variables exogènes (AX/AY, histo > 180j)
    - moyenne_mobile   : fallback simple

Sélection :
    Holdout = 30 derniers jours.
    MAPE calculé pour chaque modèle applicable.
    Retourne le modèle avec MAPE minimal.
"""

from __future__ import annotations

import logging
import warnings
from typing import Any

import numpy as np
import pandas as pd

logger = logging.getLogger(__name__)

HOLDOUT_DAYS = 30
MIN_HISTORY_OLS = 180   # jours minimum pour OLS
SEASON_PERIOD_SHORT = 7
SEASON_PERIOD_LONG = 30


# ── Entrée publique ────────────────────────────────────────────────────────────

def forecast_product(
    serie_corrigee: dict[str, float],
    segment_abc: str | None,
    segment_xyz: str | None,
    nb_jours_historique: int,
) -> dict[str, Any]:
    """
    Sélectionne et applique le meilleur modèle de prévision.

    Retourne :
        {
          "modele": str,
          "prevision_30j": float,
          "prevision_90j": float,
          "mape_holdout": float,
          "details": {...}   # métriques intermédiaires
        }
    """
    if not serie_corrigee:
        return _empty_forecast()

    series = _parse_series(serie_corrigee)
    if len(series) < 14:
        return _fallback_moving_average(series)

    cv, zero_rate = _series_stats(series)
    eligible_models = _eligible_models(
        cv, zero_rate, segment_abc, segment_xyz, nb_jours_historique
    )

    # Holdout split
    train = series.iloc[:-HOLDOUT_DAYS] if len(series) > HOLDOUT_DAYS else series
    test  = series.iloc[-HOLDOUT_DAYS:] if len(series) > HOLDOUT_DAYS else series.iloc[-1:]

    results: list[dict] = []
    for model_name in eligible_models:
        try:
            res = _fit_and_evaluate(model_name, train, test, series)
            if res is not None:
                results.append(res)
        except Exception as exc:
            logger.warning("Modèle %s échoué : %s", model_name, exc)

    if not results:
        return _fallback_moving_average(series)

    best = min(results, key=lambda r: r["mape_holdout"])
    return best


# ── Sélection des modèles éligibles ────────────────────────────────────────────

def _eligible_models(
    cv: float,
    zero_rate: float,
    abc: str | None,
    xyz: str | None,
    nb_jours: int,
) -> list[str]:
    models = []

    # Croston : uniquement pour demande vraiment intermittente (zero_rate élevé)
    # Exclu si zero_rate > 80% (produit quasi-mort → moyenne_mobile suffit)
    if cv > 0.5 and 0.20 < zero_rate <= 0.80:
        models.append("croston")

    # Holt-Winters : élargi à cv < 1.0 (gère la variabilité modérée à haute)
    # Requiert au moins 2 périodes d'historique
    if cv < 1.0 and nb_jours >= 30:
        models.append("holt_winters")

    # OLS : élargi aux segments A/B avec historique suffisant
    if abc in ("A", "B") and nb_jours >= MIN_HISTORY_OLS:
        models.append("ols")

    models.append("moyenne_mobile")  # toujours éligible (fallback)
    return models


# ── Ajustement et évaluation ────────────────────────────────────────────────────

def _fit_and_evaluate(
    model_name: str,
    train: pd.Series,
    test: pd.Series,
    full_series: pd.Series,
) -> dict[str, Any] | None:
    if model_name == "croston":
        return _fit_croston(train, test, full_series)
    if model_name == "holt_winters":
        return _fit_holt_winters(train, test, full_series)
    if model_name == "ols":
        return _fit_ols(train, test, full_series)
    if model_name == "moyenne_mobile":
        return _fit_moving_average(train, test, full_series)
    return None


# ── Croston ────────────────────────────────────────────────────────────────────

def _fit_croston(
    train: pd.Series, test: pd.Series, full: pd.Series
) -> dict[str, Any]:
    """
    Méthode de Croston (SBA variant) pour demande intermittente.
    Prédit une demande journalière constante = a / p
    où a = lissage de la taille des demandes, p = lissage de l'inter-demande.
    """
    alpha = 0.3  # facteur de lissage
    data = train.values

    # Initialisation
    nz_idx = np.where(data > 0)[0]
    if len(nz_idx) == 0:
        return None

    a = float(data[nz_idx[0]])   # taille demande lissée
    p = float(nz_idx[0] + 1)     # inter-demande lissée (jours)
    last_demand_idx = nz_idx[0]

    for i in range(nz_idx[0] + 1, len(data)):
        if data[i] > 0:
            interval = i - last_demand_idx
            a = alpha * data[i] + (1 - alpha) * a
            p = alpha * interval + (1 - alpha) * p
            last_demand_idx = i

    # SBA correction : multiply by (1 - alpha/2)
    daily_forecast = (1 - alpha / 2) * a / p if p > 0 else 0.0

    # MAPE sur holdout
    pred_test = np.full(len(test), daily_forecast)
    mape = _mape(test.values, pred_test)

    return {
        "modele": "croston",
        "prevision_30j": round(daily_forecast * 30, 2),
        "prevision_90j": round(daily_forecast * 90, 2),
        "mape_holdout": round(mape, 4),
        "details": {"daily_forecast": round(daily_forecast, 4), "a": round(a, 4), "p": round(p, 4)},
    }


# ── Holt-Winters ───────────────────────────────────────────────────────────────

def _fit_holt_winters(
    train: pd.Series, test: pd.Series, full: pd.Series
) -> dict[str, Any] | None:
    try:
        from statsmodels.tsa.holtwinters import ExponentialSmoothing
    except ImportError:
        logger.error("statsmodels non installé")
        return None

    period = SEASON_PERIOD_SHORT if len(train) < 90 else SEASON_PERIOD_LONG
    if len(train) < period * 2:
        return None

    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        model = ExponentialSmoothing(
            train.values,
            trend="add",
            seasonal="add",
            seasonal_periods=period,
            initialization_method="estimated",
        ).fit(optimized=True)

    # Holdout forecast
    pred_test = model.forecast(len(test))
    pred_test = np.maximum(pred_test, 0)
    mape = _mape(test.values, pred_test)

    # Forecast horizon
    pred_30 = float(np.maximum(model.forecast(30), 0).sum())
    pred_90 = float(np.maximum(model.forecast(90), 0).sum())

    return {
        "modele": "holt_winters",
        "prevision_30j": round(pred_30, 2),
        "prevision_90j": round(pred_90, 2),
        "mape_holdout": round(mape, 4),
        "details": {"seasonal_period": period},
    }


# ── OLS ────────────────────────────────────────────────────────────────────────

def _fit_ols(
    train: pd.Series, test: pd.Series, full: pd.Series
) -> dict[str, Any] | None:
    try:
        import statsmodels.api as sm
    except ImportError:
        logger.error("statsmodels non installé")
        return None

    def _build_features(idx: pd.DatetimeIndex) -> pd.DataFrame:
        df = pd.DataFrame(index=idx)
        df["mois"] = idx.month
        df["jour_semaine"] = idx.dayofweek
        # Ramadan approximatif (variable booléenne simple par mois)
        df["ramadan"] = idx.month.isin([3, 4]).astype(float)
        # Saison grippe : octobre–février
        df["grippe"] = idx.month.isin([10, 11, 12, 1, 2]).astype(float)
        df["const"] = 1.0
        return df

    X_train = _build_features(train.index)
    X_test  = _build_features(test.index)

    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        ols = sm.OLS(train.values, X_train.values).fit()

    pred_test = np.maximum(ols.predict(X_test.values), 0)
    mape = _mape(test.values, pred_test)

    # Forecast 30 / 90 jours à partir du dernier jour de la série complète
    last_date = full.index[-1]
    future_30  = pd.date_range(last_date + pd.Timedelta(days=1), periods=30,  freq="D")
    future_90  = pd.date_range(last_date + pd.Timedelta(days=1), periods=90,  freq="D")
    pred_30 = float(np.maximum(ols.predict(_build_features(future_30).values),  0).sum())
    pred_90 = float(np.maximum(ols.predict(_build_features(future_90).values),  0).sum())

    return {
        "modele": "ols",
        "prevision_30j": round(pred_30, 2),
        "prevision_90j": round(pred_90, 2),
        "mape_holdout": round(mape, 4),
        "details": {"r_squared": round(float(ols.rsquared), 4)},
    }


# ── Moyenne mobile ────────────────────────────────────────────────────────────

def _fit_moving_average(
    train: pd.Series, test: pd.Series, full: pd.Series
) -> dict[str, Any]:
    window = min(30, len(train))
    daily = float(train.iloc[-window:].mean())
    daily = max(daily, 0.0)

    pred_test = np.full(len(test), daily)
    mape = _mape(test.values, pred_test)

    return {
        "modele": "moyenne_mobile",
        "prevision_30j": round(daily * 30, 2),
        "prevision_90j": round(daily * 90, 2),
        "mape_holdout": round(mape, 4),
        "details": {"window": window, "daily_mean": round(daily, 4)},
    }


def _fallback_moving_average(series: pd.Series) -> dict[str, Any]:
    daily = float(series.mean()) if len(series) > 0 else 0.0
    return {
        "modele": "moyenne_mobile",
        "prevision_30j": round(daily * 30, 2),
        "prevision_90j": round(daily * 90, 2),
        "mape_holdout": None,
        "details": {"window": len(series), "daily_mean": round(daily, 4)},
    }


# ── Helpers ────────────────────────────────────────────────────────────────────

def _parse_series(serie_dict: dict[str, float]) -> pd.Series:
    s = pd.Series(serie_dict)
    s.index = pd.to_datetime(s.index)
    s = s.sort_index().astype(float)
    # Remplir les jours manquants par 0
    if len(s) > 1:
        full_idx = pd.date_range(s.index.min(), s.index.max(), freq="D")
        s = s.reindex(full_idx, fill_value=0.0)
    return s


def _series_stats(series: pd.Series) -> tuple[float, float]:
    """Retourne (CV, taux_zéros)."""
    mean = series.mean()
    std  = series.std()
    cv = float(std / mean) if mean > 0 else float("inf")
    zero_rate = float((series == 0).sum() / len(series))
    return cv, zero_rate


def _mape(actual: np.ndarray, predicted: np.ndarray) -> float:
    """Mean Absolute Percentage Error — ignore les zéros en actual."""
    mask = actual > 0
    if not mask.any():
        return float("inf")
    return float(np.mean(np.abs((actual[mask] - predicted[mask]) / actual[mask])))


def _empty_forecast() -> dict[str, Any]:
    return {
        "modele": None,
        "prevision_30j": 0.0,
        "prevision_90j": 0.0,
        "mape_holdout": None,
        "details": {},
    }
