"""
Finance & Profitabilité — endpoints Revenus, Dépenses et Tableau de bord.
"""
import calendar
from datetime import date

from fastapi import APIRouter, Depends, Query
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user

router = APIRouter(prefix="/finance", tags=["finance"])


def _f(v) -> float:
    return float(v) if v is not None else 0.0


# ── GET /finance/revenus/{annee}/{mois} ───────────────────────────────────────

@router.get("/revenus/{annee}/{mois}")
async def get_revenus(
    annee: int,
    mois: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Retourne pour le mois donné :
      - kpis          : CA, nb ventes, panier moyen, taux CHIFA, taux crédit
      - evolution     : CA journalier (tous les jours du mois)
      - repartition   : comptant / CHIFA / crédit (CA + %)
      - top_produits  : top 10 produits par CA
    """

    # ── 1. KPIs globaux ──────────────────────────────────────────────────────
    kpi_res = await db.execute(text("""
        SELECT
            COUNT(*)                                                       AS nb_ventes,
            COALESCE(SUM(total_a_payer),  0)                              AS ca,
            COALESCE(AVG(total_a_payer),  0)                              AS panier_moyen,
            COALESCE(SUM(montant_cnas),   0)                              AS ca_chifa,
            COALESCE(SUM(
                GREATEST(total_a_payer - versement - COALESCE(montant_cnas, 0), 0)
            ), 0)                                                          AS ca_credit,
            COALESCE(SUM(versement),      0)                              AS ca_comptant
        FROM sorties
        WHERE EXTRACT(YEAR  FROM date) = :annee
          AND EXTRACT(MONTH FROM date) = :mois
          AND type NOT IN ('AV', 'RET')
    """), {"annee": annee, "mois": mois})
    k = kpi_res.fetchone()

    ca           = _f(k.ca)
    ca_chifa     = _f(k.ca_chifa)
    ca_credit    = _f(k.ca_credit)
    ca_comptant  = _f(k.ca_comptant)

    taux_chifa   = round(ca_chifa  / ca * 100, 1) if ca > 0 else 0.0
    taux_credit  = round(ca_credit / ca * 100, 1) if ca > 0 else 0.0
    taux_comptant = round(100 - taux_chifa - taux_credit, 1)

    kpis = {
        "ca":           round(ca, 2),
        "nb_ventes":    int(k.nb_ventes),
        "panier_moyen": round(_f(k.panier_moyen), 2),
        "taux_chifa":   taux_chifa,
        "taux_credit":  taux_credit,
        "taux_comptant": taux_comptant,
        "annee": annee,
        "mois":  mois,
    }

    # ── 2. Évolution journalière ──────────────────────────────────────────────
    evo_res = await db.execute(text("""
        SELECT
            date,
            COUNT(*)                        AS nb_ventes,
            COALESCE(SUM(total_a_payer), 0) AS ca
        FROM sorties
        WHERE EXTRACT(YEAR  FROM date) = :annee
          AND EXTRACT(MONTH FROM date) = :mois
          AND type NOT IN ('AV', 'RET')
        GROUP BY date
        ORDER BY date
    """), {"annee": annee, "mois": mois})

    daily_map = {
        str(r.date): {"ca": _f(r.ca), "nb_ventes": int(r.nb_ventes)}
        for r in evo_res.fetchall()
    }

    # Remplir tous les jours du mois (y compris sans ventes → 0)
    nb_days = calendar.monthrange(annee, mois)[1]
    evolution = []
    for day in range(1, nb_days + 1):
        d = date(annee, mois, day).isoformat()
        evolution.append({
            "date":      d,
            "ca":        daily_map.get(d, {}).get("ca", 0.0),
            "nb_ventes": daily_map.get(d, {}).get("nb_ventes", 0),
        })

    # ── 3. Répartition comptant / CHIFA / crédit ─────────────────────────────
    repartition = [
        {
            "label": "Comptant",
            "ca":    round(ca_comptant, 2),
            "pct":   round(taux_comptant, 1),
            "color": "#2563EB",
        },
        {
            "label": "CHIFA",
            "ca":    round(ca_chifa, 2),
            "pct":   round(taux_chifa, 1),
            "color": "#7C3AED",
        },
        {
            "label": "Crédit",
            "ca":    round(ca_credit, 2),
            "pct":   round(taux_credit, 1),
            "color": "#F59E0B",
        },
    ]

    # ── 4. Top 10 produits par CA ─────────────────────────────────────────────
    top_res = await db.execute(text("""
        SELECT
            n.nom,
            n.famille,
            SUM(sp.prix_vente * sp.qte_sortie) AS ca,
            SUM(sp.qte_sortie)                 AS nb
        FROM sorties_produits sp
        JOIN nomenclature n ON n.id = sp.id_nom
        JOIN sorties s      ON s.id = sp.id_sortie
        WHERE EXTRACT(YEAR  FROM sp.date) = :annee
          AND EXTRACT(MONTH FROM sp.date) = :mois
          AND s.type NOT IN ('AV', 'RET')
        GROUP BY n.id, n.nom, n.famille
        ORDER BY ca DESC
        LIMIT 10
    """), {"annee": annee, "mois": mois})

    top_produits = [
        {
            "nom":     r.nom,
            "famille": r.famille,
            "ca":      round(_f(r.ca), 2),
            "nb":      int(r.nb),
        }
        for r in top_res.fetchall()
    ]

    return {
        "kpis":         kpis,
        "evolution":    evolution,
        "repartition":  repartition,
        "top_produits": top_produits,
    }


# ── GET /finance/depenses/{annee}/{mois} ──────────────────────────────────────

@router.get("/depenses/{annee}/{mois}")
async def get_depenses(
    annee: int,
    mois: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Retourne pour le mois donné :
      - kpis          : dépenses opé, coût achats, total charges, ratio charges/CA
      - evolution     : dépenses opé + achats par semaine du mois
      - detail_ope    : liste des dépenses opérationnelles (date, montant, ref, utilisateur)
      - top_fourn     : top 5 fournisseurs par coût achats
    """

    # ── 1. KPIs ───────────────────────────────────────────────────────────────
    # Dépenses opérationnelles
    dep_res = await db.execute(text("""
        SELECT COALESCE(SUM(montant), 0) AS total
        FROM operations
        WHERE EXTRACT(YEAR  FROM date) = :annee
          AND EXTRACT(MONTH FROM date) = :mois
          AND LOWER(operation) = 'dépense'
    """), {"annee": annee, "mois": mois})
    depenses_ope = _f(dep_res.scalar())

    # Coût achats fournisseurs (réceptions hors avoirs)
    achat_res = await db.execute(text("""
        SELECT COALESCE(SUM(total_a_payer), 0) AS total
        FROM entrees
        WHERE EXTRACT(YEAR  FROM date) = :annee
          AND EXTRACT(MONTH FROM date) = :mois
          AND type != 'AVF'
    """), {"annee": annee, "mois": mois})
    cout_achats = _f(achat_res.scalar())

    # CA du mois (pour ratio)
    ca_res = await db.execute(text("""
        SELECT COALESCE(SUM(total_a_payer), 0) AS ca
        FROM sorties
        WHERE EXTRACT(YEAR  FROM date) = :annee
          AND EXTRACT(MONTH FROM date) = :mois
          AND type NOT IN ('AV', 'RET')
    """), {"annee": annee, "mois": mois})
    ca = _f(ca_res.scalar())

    total_charges = depenses_ope + cout_achats
    ratio_charges = round(total_charges / ca * 100, 1) if ca > 0 else 0.0

    kpis = {
        "depenses_ope":  round(depenses_ope, 2),
        "cout_achats":   round(cout_achats, 2),
        "total_charges": round(total_charges, 2),
        "ratio_charges": ratio_charges,
        "annee": annee,
        "mois":  mois,
    }

    # ── 2. Évolution hebdomadaire ─────────────────────────────────────────────
    # On calcule les 5 semaines possibles dans le mois (lun-dim)
    evo_dep_res = await db.execute(text("""
        SELECT
            DATE_TRUNC('week', date)::date      AS semaine,
            COALESCE(SUM(montant), 0)           AS montant
        FROM operations
        WHERE EXTRACT(YEAR  FROM date) = :annee
          AND EXTRACT(MONTH FROM date) = :mois
          AND LOWER(operation) = 'dépense'
        GROUP BY semaine
        ORDER BY semaine
    """), {"annee": annee, "mois": mois})

    evo_ach_res = await db.execute(text("""
        SELECT
            DATE_TRUNC('week', date)::date      AS semaine,
            COALESCE(SUM(total_a_payer), 0)     AS montant
        FROM entrees
        WHERE EXTRACT(YEAR  FROM date) = :annee
          AND EXTRACT(MONTH FROM date) = :mois
          AND type != 'AVF'
        GROUP BY semaine
        ORDER BY semaine
    """), {"annee": annee, "mois": mois})

    dep_by_week  = {str(r.semaine): _f(r.montant) for r in evo_dep_res.fetchall()}
    ach_by_week  = {str(r.semaine): _f(r.montant) for r in evo_ach_res.fetchall()}
    all_weeks    = sorted(set(dep_by_week) | set(ach_by_week))

    evolution = [
        {
            "semaine":      w,
            "depenses_ope": round(dep_by_week.get(w, 0.0), 2),
            "cout_achats":  round(ach_by_week.get(w, 0.0), 2),
        }
        for w in all_weeks
    ]

    # ── 3. Détail dépenses opérationnelles ───────────────────────────────────
    detail_res = await db.execute(text("""
        SELECT
            date,
            montant,
            COALESCE(destinataire, ref, '')  AS categorie,
            COALESCE(ref, '')                AS ref,
            COALESCE(utilisateur, '')        AS utilisateur,
            COALESCE(mode, '')               AS mode
        FROM operations
        WHERE EXTRACT(YEAR  FROM date) = :annee
          AND EXTRACT(MONTH FROM date) = :mois
          AND LOWER(operation) = 'dépense'
        ORDER BY date DESC, id DESC
        LIMIT 100
    """), {"annee": annee, "mois": mois})

    detail_ope = [
        {
            "date":        str(r.date),
            "montant":     round(_f(r.montant), 2),
            "categorie":   r.categorie,
            "ref":         r.ref,
            "utilisateur": r.utilisateur,
            "mode":        r.mode,
        }
        for r in detail_res.fetchall()
    ]

    # ── 4. Top 5 fournisseurs par coût achats ─────────────────────────────────
    fourn_res = await db.execute(text("""
        SELECT
            fournisseur,
            COUNT(*)                        AS nb_entrees,
            COALESCE(SUM(total_a_payer), 0) AS total
        FROM entrees
        WHERE EXTRACT(YEAR  FROM date) = :annee
          AND EXTRACT(MONTH FROM date) = :mois
          AND type != 'AVF'
        GROUP BY fournisseur
        ORDER BY total DESC
        LIMIT 5
    """), {"annee": annee, "mois": mois})

    top_fourn = [
        {
            "fournisseur": r.fournisseur,
            "nb_entrees":  int(r.nb_entrees),
            "total":       round(_f(r.total), 2),
            "pct": round(_f(r.total) / cout_achats * 100, 1) if cout_achats > 0 else 0.0,
        }
        for r in fourn_res.fetchall()
    ]

    return {
        "kpis":       kpis,
        "evolution":  evolution,
        "detail_ope": detail_ope,
        "top_fourn":  top_fourn,
    }


# ── GET /finance/tableau-de-bord/{annee}/{mois} ───────────────────────────────

@router.get("/tableau-de-bord/{annee}/{mois}")
async def get_tableau_de_bord(
    annee: int,
    mois: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Retourne :
      - scorecard   : 6 KPIs du mois avec delta vs mois précédent
      - tendance    : CA / bénéfice brut / charges sur les 12 derniers mois
      - alertes     : alertes financières automatiques
    """
    # Mois précédent
    prev_annee = annee if mois > 1 else annee - 1
    prev_mois  = mois - 1 if mois > 1 else 12

    def _pct_delta(cur: float, prev: float) -> float | None:
        if prev == 0:
            return None
        return round((cur - prev) / prev * 100, 1)

    # ── 1. Scorecard (mois courant + mois précédent) ──────────────────────────

    ventes_res = await db.execute(text("""
        SELECT
            COALESCE(SUM(total_a_payer) FILTER (
                WHERE EXTRACT(YEAR FROM date)=:a AND EXTRACT(MONTH FROM date)=:m
            ), 0) AS ca,
            COALESCE(SUM(benefices + COALESCE(majoration,0)) FILTER (
                WHERE EXTRACT(YEAR FROM date)=:a AND EXTRACT(MONTH FROM date)=:m
            ), 0) AS benef_brut,
            COALESCE(SUM(total_a_payer) FILTER (
                WHERE EXTRACT(YEAR FROM date)=:pa AND EXTRACT(MONTH FROM date)=:pm
            ), 0) AS ca_prev,
            COALESCE(SUM(benefices + COALESCE(majoration,0)) FILTER (
                WHERE EXTRACT(YEAR FROM date)=:pa AND EXTRACT(MONTH FROM date)=:pm
            ), 0) AS benef_brut_prev
        FROM sorties
        WHERE type NOT IN ('AV','RET')
          AND (
            (EXTRACT(YEAR FROM date)=:a  AND EXTRACT(MONTH FROM date)=:m)  OR
            (EXTRACT(YEAR FROM date)=:pa AND EXTRACT(MONTH FROM date)=:pm)
          )
    """), {"a": annee, "m": mois, "pa": prev_annee, "pm": prev_mois})
    v = ventes_res.fetchone()

    dep_res = await db.execute(text("""
        SELECT
            COALESCE(SUM(montant) FILTER (
                WHERE EXTRACT(YEAR FROM date)=:a AND EXTRACT(MONTH FROM date)=:m
            ), 0) AS dep,
            COALESCE(SUM(montant) FILTER (
                WHERE EXTRACT(YEAR FROM date)=:pa AND EXTRACT(MONTH FROM date)=:pm
            ), 0) AS dep_prev
        FROM operations
        WHERE LOWER(operation) = 'dépense'
          AND (
            (EXTRACT(YEAR FROM date)=:a  AND EXTRACT(MONTH FROM date)=:m)  OR
            (EXTRACT(YEAR FROM date)=:pa AND EXTRACT(MONTH FROM date)=:pm)
          )
    """), {"a": annee, "m": mois, "pa": prev_annee, "pm": prev_mois})
    d = dep_res.fetchone()

    ach_res = await db.execute(text("""
        SELECT
            COALESCE(SUM(total_a_payer) FILTER (
                WHERE EXTRACT(YEAR FROM date)=:a AND EXTRACT(MONTH FROM date)=:m
            ), 0) AS ach,
            COALESCE(SUM(total_a_payer) FILTER (
                WHERE EXTRACT(YEAR FROM date)=:pa AND EXTRACT(MONTH FROM date)=:pm
            ), 0) AS ach_prev
        FROM entrees
        WHERE type != 'AVF'
          AND (
            (EXTRACT(YEAR FROM date)=:a  AND EXTRACT(MONTH FROM date)=:m)  OR
            (EXTRACT(YEAR FROM date)=:pa AND EXTRACT(MONTH FROM date)=:pm)
          )
    """), {"a": annee, "m": mois, "pa": prev_annee, "pm": prev_mois})
    a = ach_res.fetchone()

    # Créances et dettes en temps réel
    cr_res = await db.execute(text(
        "SELECT COALESCE(SUM(credit), 0) FROM clients WHERE credit > 0"
    ))
    dette_res = await db.execute(text(
        "SELECT COALESCE(SUM(solde_actuel), 0) FROM fournisseurs WHERE solde_actuel > 0"
    ))

    ca         = _f(v.ca);          ca_prev    = _f(v.ca_prev)
    benef_brut = _f(v.benef_brut);  benef_prev = _f(v.benef_brut_prev)
    dep        = _f(d.dep);         dep_prev   = _f(d.dep_prev)
    ach        = _f(a.ach);         ach_prev   = _f(a.ach_prev)
    charges        = dep + ach
    charges_prev   = dep_prev + ach_prev
    benef_net      = benef_brut - dep          # approx (sans pertes inventaire)
    benef_net_prev = benef_prev - dep_prev
    taux_marge     = round(benef_net / ca * 100, 1) if ca > 0 else 0.0
    taux_prev      = round(benef_net_prev / ca_prev * 100, 1) if ca_prev > 0 else 0.0
    creances       = _f(cr_res.scalar())
    dettes         = _f(dette_res.scalar())

    scorecard = [
        {
            "label":     "Chiffre d'affaires",
            "valeur":    round(ca, 2),
            "delta_pct": _pct_delta(ca, ca_prev),
            "unite":     "DA",
            "color":     "#2563EB",
            "good_up":   True,
        },
        {
            "label":     "Bénéfice net",
            "valeur":    round(benef_net, 2),
            "delta_pct": _pct_delta(benef_net, benef_net_prev),
            "unite":     "DA",
            "color":     "#10B981" if benef_net >= 0 else "#EF4444",
            "good_up":   True,
        },
        {
            "label":     "Total charges",
            "valeur":    round(charges, 2),
            "delta_pct": _pct_delta(charges, charges_prev),
            "unite":     "DA",
            "color":     "#F59E0B",
            "good_up":   False,
        },
        {
            "label":     "Taux de marge",
            "valeur":    taux_marge,
            "delta_pct": _pct_delta(taux_marge, taux_prev),
            "unite":     "%",
            "color":     "#8B5CF6",
            "good_up":   True,
        },
        {
            "label":     "Créances clients",
            "valeur":    round(creances, 2),
            "delta_pct": None,
            "unite":     "DA",
            "color":     "#DC2626",
            "good_up":   False,
        },
        {
            "label":     "Dettes fournisseurs",
            "valeur":    round(dettes, 2),
            "delta_pct": None,
            "unite":     "DA",
            "color":     "#7C3AED",
            "good_up":   False,
        },
    ]

    # ── 2. Tendance 12 mois ───────────────────────────────────────────────────
    # Générer les 12 mois (de annee/mois inclus, en remontant)
    months_12 = []
    y, m = annee, mois
    for _ in range(12):
        months_12.insert(0, (y, m))
        m -= 1
        if m == 0:
            m = 12
            y -= 1

    start_period = months_12[0][0] * 100 + months_12[0][1]
    end_period   = annee * 100 + mois

    trend_v = await db.execute(text("""
        SELECT
            EXTRACT(YEAR  FROM date)::int AS annee,
            EXTRACT(MONTH FROM date)::int AS mois,
            COALESCE(SUM(total_a_payer), 0)                              AS ca,
            COALESCE(SUM(benefices + COALESCE(majoration,0)), 0)         AS benef_brut
        FROM sorties
        WHERE type NOT IN ('AV','RET')
          AND (EXTRACT(YEAR FROM date)*100 + EXTRACT(MONTH FROM date))
              BETWEEN :s AND :e
        GROUP BY annee, mois
    """), {"s": start_period, "e": end_period})

    trend_d = await db.execute(text("""
        SELECT
            EXTRACT(YEAR  FROM date)::int AS annee,
            EXTRACT(MONTH FROM date)::int AS mois,
            COALESCE(SUM(montant), 0) AS dep
        FROM operations
        WHERE LOWER(operation) = 'dépense'
          AND (EXTRACT(YEAR FROM date)*100 + EXTRACT(MONTH FROM date))
              BETWEEN :s AND :e
        GROUP BY annee, mois
    """), {"s": start_period, "e": end_period})

    trend_a = await db.execute(text("""
        SELECT
            EXTRACT(YEAR  FROM date)::int AS annee,
            EXTRACT(MONTH FROM date)::int AS mois,
            COALESCE(SUM(total_a_payer), 0) AS ach
        FROM entrees
        WHERE type != 'AVF'
          AND (EXTRACT(YEAR FROM date)*100 + EXTRACT(MONTH FROM date))
              BETWEEN :s AND :e
        GROUP BY annee, mois
    """), {"s": start_period, "e": end_period})

    v_map = {(r.annee, r.mois): (_f(r.ca), _f(r.benef_brut)) for r in trend_v.fetchall()}
    d_map = {(r.annee, r.mois): _f(r.dep) for r in trend_d.fetchall()}
    a_map = {(r.annee, r.mois): _f(r.ach) for r in trend_a.fetchall()}

    mois_labels = ['', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
                   'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc']

    tendance = []
    for (ty, tm) in months_12:
        ca_t, bb_t = v_map.get((ty, tm), (0.0, 0.0))
        dep_t = d_map.get((ty, tm), 0.0)
        ach_t = a_map.get((ty, tm), 0.0)
        tendance.append({
            "label":    f"{mois_labels[tm]} {str(ty)[2:]}",
            "ca":       round(ca_t, 2),
            "benefice": round(bb_t - dep_t, 2),
            "charges":  round(dep_t + ach_t, 2),
        })

    # ── 3. Alertes ────────────────────────────────────────────────────────────
    alertes = []
    ratio_charges = charges / ca * 100 if ca > 0 else 0.0

    if benef_net < 0:
        alertes.append({
            "severity": "error",
            "icon":     "alert_triangle",
            "message":  f"Bénéfice net négatif ce mois : {round(benef_net):,} DA",
        })
    if ratio_charges > 90:
        alertes.append({
            "severity": "error",
            "icon":     "alert_triangle",
            "message":  f"Ratio charges/CA critique : {ratio_charges:.1f} %",
        })
    elif ratio_charges > 75:
        alertes.append({
            "severity": "warning",
            "icon":     "alert_circle",
            "message":  f"Ratio charges/CA élevé : {ratio_charges:.1f} %",
        })
    if creances > 1_000_000:
        alertes.append({
            "severity": "warning",
            "icon":     "people",
            "message":  f"Créances clients importantes : {round(creances):,} DA",
        })
    if dettes > 5_000_000:
        alertes.append({
            "severity": "warning",
            "icon":     "archive",
            "message":  f"Dettes fournisseurs élevées : {round(dettes):,} DA",
        })
    if not alertes:
        alertes.append({
            "severity": "success",
            "icon":     "checkmark_circle",
            "message":  "Aucune alerte financière ce mois. Situation saine.",
        })

    return {
        "scorecard": scorecard,
        "tendance":  tendance,
        "alertes":   alertes,
        "meta": {"annee": annee, "mois": mois},
    }
