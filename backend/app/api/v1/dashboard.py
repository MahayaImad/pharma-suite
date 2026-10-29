"""
Dashboard & KPI endpoints
Tableaux de bord collectif et individuel — Pharmacie PharmaSuite
"""
from datetime import date, timedelta
from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, desc, text
from loguru import logger

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.ventes import Sortie, SortieProduit
from app.models.achats import Entree, Fournisseur, CommandeFournisseur
from app.models.pharma import Nomenclature, InstanceProduit
from app.models.clients import Client
from app.models.caisse import SuiviCaisse
from app.models.chifa import FactureChifa, ChifaRejetPartiel
from app.models.config_tables import Groupware

router = APIRouter(prefix="/dashboard", tags=["dashboard"])

# ── Helpers ───────────────────────────────────────────────────────────────────

PERIOD_ENUM = ["today", "week", "month", "year", "last_month"]


def _period_dates(period: str) -> tuple[date, date]:
    """Retourne (date_debut, date_fin) selon la période."""
    today = date.today()
    if period == "today":
        return today, today
    if period == "week":
        return today - timedelta(days=today.weekday()), today
    if period == "month":
        return today.replace(day=1), today
    if period == "year":
        return today.replace(month=1, day=1), today
    if period == "last_month":
        first_this = today.replace(day=1)
        last_prev = first_this - timedelta(days=1)
        return last_prev.replace(day=1), last_prev
    return today.replace(day=1), today


def _prev_period(date_from: date, date_to: date) -> tuple[date, date]:
    """Retourne la période précédente de même durée."""
    delta = (date_to - date_from).days + 1
    return date_from - timedelta(days=delta), date_from - timedelta(days=1)


def _f(val) -> float:
    return float(val) if val is not None else 0.0


def _pct_delta(current: float, previous: float) -> Optional[float]:
    if previous <= 0:
        return None
    return round((current - previous) / previous * 100, 1)


# ── 1. Vue d'ensemble des ventes (KPIs 1-7) ──────────────────────────────────

@router.get("/overview")
async def sales_overview(
    period: str = Query("month"),
    date_from: Optional[date] = Query(None, alias="from"),
    date_to: Optional[date] = Query(None, alias="to"),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    KPIs principaux des ventes pour la période sélectionnée.

    Retourne :
    - ca            : Chiffre d'affaires (total_a_payer des ventes)
    - transactions  : Nombre de ventes
    - avg_basket    : Panier moyen (CA / transactions)
    - benefices     : Marge brute totale
    - margin_rate   : Taux de marge en %
    - retours       : Nombre et montant des avoirs/retours
    - vs_previous   : Comparaison avec la période équivalente précédente (delta %)
    """
    if date_from is None or date_to is None:
        date_from, date_to = _period_dates(period)
    prev_from, prev_to = _prev_period(date_from, date_to)

    async def _fetch_sales(d_from: date, d_to: date, exclude_type: str = "AV"):
        res = await db.execute(
            select(
                func.count(Sortie.id).label("cnt"),
                func.coalesce(func.sum(Sortie.total_a_payer), 0).label("ca"),
                func.coalesce(func.sum(Sortie.benefices), 0).label("benefices"),
                func.coalesce(func.avg(Sortie.total_a_payer), 0).label("avg_basket"),
                func.coalesce(func.sum(Sortie.majoration), 0).label("majoration"),
            ).where(
                and_(
                    Sortie.date >= d_from,
                    Sortie.date <= d_to,
                    Sortie.type != exclude_type,
                )
            )
        )
        return res.one()

    async def _fetch_returns(d_from: date, d_to: date):
        res = await db.execute(
            select(
                func.count(Sortie.id).label("cnt"),
                func.coalesce(func.sum(Sortie.total_a_payer), 0).label("total"),
            ).where(
                and_(
                    Sortie.date >= d_from,
                    Sortie.date <= d_to,
                    Sortie.type == "AV",
                )
            )
        )
        return res.one()

    row = await _fetch_sales(date_from, date_to)
    prev_row = await _fetch_sales(prev_from, prev_to)
    ret_row = await _fetch_returns(date_from, date_to)

    ca = _f(row.ca)
    benefices = _f(row.benefices)
    majoration = _f(row.majoration)
    benefices_total = benefices + majoration
    prev_ca = _f(prev_row.ca)
    prev_benefices_total = _f(prev_row.benefices) + _f(prev_row.majoration)

    return {
        "period": period,
        "date_from": date_from.isoformat(),
        "date_to": date_to.isoformat(),
        "ca": ca,
        "transactions": row.cnt,
        "avg_basket": round(_f(row.avg_basket), 2),
        "benefices": benefices,
        # majoration : supplément versé par les caisses sociales (CNAS/CHIFA/CVM)
        # c'est un bénéfice supplémentaire net, distinct de la marge commerciale
        "majoration": majoration,
        "benefices_total": benefices_total,
        "margin_rate": round(benefices_total / ca * 100, 2) if ca > 0 else 0.0,
        "retours": {
            "count": ret_row.cnt,
            "total": _f(ret_row.total),
        },
        "vs_previous_period": {
            "ca": prev_ca,
            "transactions": prev_row.cnt,
            "ca_delta_pct": _pct_delta(ca, prev_ca),
            "benefices_delta_pct": _pct_delta(benefices_total, prev_benefices_total),
        },
    }


# ── 2. Stock — alertes & valeur (KPIs 8-11) ──────────────────────────────────

@router.get("/stock")
async def stock_kpis(
    expiry_days: int = Query(90, ge=1, le=365),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    KPIs de gestion du stock :
    - ruptures      : Produits avec stock <= 0 (ventes perdues directes)
    - alertes       : Produits entre 0 et le seuil d'alerte (à réapprovisionner vite)
    - expirant      : Produits dont la péremption arrive dans <expiry_days> jours
    - valeur_stock  : Capital immobilisé = SUM(stock × prix_achat_moyen)
    - detail_ruptures, detail_alertes : listes des produits concernés (top 20)
    """
    # Ruptures (stock <= 0, alerte non désactivée)
    ruptures_res = await db.execute(
        select(func.count(Nomenclature.id)).where(
            and_(Nomenclature.stock <= 0, Nomenclature.desactiv_alrt_rup == 0)
        )
    )
    ruptures_count = ruptures_res.scalar() or 0

    # Produits sous seuil d'alerte (stock positif mais < qte_alerte)
    alertes_res = await db.execute(
        select(func.count(Nomenclature.id)).where(
            and_(
                Nomenclature.stock > 0,
                Nomenclature.qte_alerte > 0,
                Nomenclature.stock < Nomenclature.qte_alerte,
                Nomenclature.desactiv_alrt_rup == 0,
            )
        )
    )
    alertes_count = alertes_res.scalar() or 0

    # Valeur totale du stock
    valeur_res = await db.execute(
        select(
            func.coalesce(
                func.sum(Nomenclature.stock * Nomenclature.prix_achat_moyen), 0
            )
        ).where(Nomenclature.stock > 0)
    )
    valeur_stock = _f(valeur_res.scalar())

    # Produits expirant bientôt — péremption au format MM/YYYY
    expiry_limit = date.today() + timedelta(days=expiry_days)
    expiring_query = text("""
        SELECT ip.id, ip.nom, ip.peremption,
               COALESCE(mv.stock_actuel, 0) AS stock
        FROM instance_produits ip
        LEFT JOIN mv_stock_produits mv ON mv.id_nom = ip.id_nom
        WHERE ip.archive = FALSE
          AND ip.peremption ~ '^[0-9]{2}/[0-9]{4}$'
          AND TO_DATE(ip.peremption, 'MM/YYYY') <= :expiry_limit
        ORDER BY TO_DATE(ip.peremption, 'MM/YYYY') ASC
        LIMIT 50
    """)
    expiring_res = await db.execute(expiring_query, {"expiry_limit": expiry_limit})
    expiring_rows = expiring_res.fetchall()

    # Detail ruptures (top 20)
    detail_ruptures = await db.execute(
        select(Nomenclature.id, Nomenclature.nom, Nomenclature.stock, Nomenclature.famille)
        .where(and_(Nomenclature.stock <= 0, Nomenclature.desactiv_alrt_rup == 0))
        .order_by(Nomenclature.nom)
        .limit(20)
    )

    # Detail alertes (top 20 — les plus proches de la rupture)
    detail_alertes = await db.execute(
        select(
            Nomenclature.id,
            Nomenclature.nom,
            Nomenclature.stock,
            Nomenclature.qte_alerte,
            Nomenclature.famille,
        )
        .where(
            and_(
                Nomenclature.stock > 0,
                Nomenclature.qte_alerte > 0,
                Nomenclature.stock < Nomenclature.qte_alerte,
                Nomenclature.desactiv_alrt_rup == 0,
            )
        )
        .order_by(Nomenclature.stock / Nomenclature.qte_alerte)
        .limit(20)
    )

    return {
        "ruptures": ruptures_count,
        "alertes": alertes_count,
        "valeur_stock": valeur_stock,
        "expirant": {
            "horizon_jours": expiry_days,
            "count": len(expiring_rows),
            "items": [
                {"id": r.id, "nom": r.nom, "stock": _f(r.stock), "peremption": r.peremption}
                for r in expiring_rows
            ],
        },
        "detail_ruptures": [
            {"id": r.id, "nom": r.nom, "stock": _f(r.stock), "famille": r.famille}
            for r in detail_ruptures.fetchall()
        ],
        "detail_alertes": [
            {
                "id": r.id,
                "nom": r.nom,
                "stock": _f(r.stock),
                "qte_alerte": r.qte_alerte,
                "famille": r.famille,
            }
            for r in detail_alertes.fetchall()
        ],
    }


# ── 3. Position financière (KPIs 12-15) ───────────────────────────────────────

@router.get("/financial")
async def financial_kpis(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Position financière globale de la pharmacie :
    - solde_caisses       : Trésorerie estimée (sessions ouvertes, total calculé)
    - dette_fournisseurs  : Total dû aux fournisseurs (solde_actuel > 0)
    - creances_clients    : Total dû par les clients (crédit accordé)
    - achats_mois         : Montant des achats du mois en cours
    - commandes_en_cours  : Nombre de commandes fournisseurs en cours
    """
    today = date.today()
    month_start = today.replace(day=1)

    # Solde caisses : somme des sessions ouvertes (etat_cloture = 0)
    caisses_res = await db.execute(
        select(func.coalesce(func.sum(SuiviCaisse.total_calcule), 0)).where(
            SuiviCaisse.etat_cloture == 0
        )
    )
    solde_caisses = _f(caisses_res.scalar())

    # Dettes fournisseurs (solde_actuel positif = on leur doit de l'argent)
    dette_res = await db.execute(
        select(func.coalesce(func.sum(Fournisseur.solde_actuel), 0)).where(
            Fournisseur.solde_actuel > 0
        )
    )
    dette_fournisseurs = _f(dette_res.scalar())

    # Créances clients (crédit = montant dû par le client)
    creances_res = await db.execute(
        select(func.coalesce(func.sum(Client.credit), 0)).where(Client.credit > 0)
    )
    creances_clients = _f(creances_res.scalar())

    # Achats du mois (entrées type 'A')
    achats_res = await db.execute(
        select(func.coalesce(func.sum(Entree.total_ttc), 0)).where(
            and_(
                Entree.date >= month_start,
                Entree.date <= today,
                Entree.type == "A",
            )
        )
    )
    achats_mois = _f(achats_res.scalar())

    # Commandes fournisseurs en cours (toutes, pas de champ etat dans le modèle actuel)
    cmd_res = await db.execute(
        select(func.count(CommandeFournisseur.id).label("cnt")).where(
            and_(
                CommandeFournisseur.date >= month_start,
                CommandeFournisseur.date <= today,
            )
        )
    )
    cmd_row = cmd_res.one()

    # Top 5 fournisseurs créditeurs (les plus gros soldes dus)
    top_fournisseurs = await db.execute(
        select(Fournisseur.fournisseur, Fournisseur.solde_actuel)
        .where(Fournisseur.solde_actuel > 0)
        .order_by(desc(Fournisseur.solde_actuel))
        .limit(5)
    )

    return {
        "solde_caisses": solde_caisses,
        "dette_fournisseurs": dette_fournisseurs,
        "creances_clients": creances_clients,
        "achats_mois": achats_mois,
        "commandes_mois": {
            "count": cmd_row.cnt,
        },
        "top_fournisseurs_solde": [
            {"fournisseur": r.fournisseur, "solde": _f(r.solde_actuel)}
            for r in top_fournisseurs.fetchall()
        ],
    }


# ── 4. CHIFA / CNAS (KPI 16) ──────────────────────────────────────────────────

@router.get("/chifa")
async def chifa_kpis(
    period: str = Query("month", enum=PERIOD_ENUM),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Suivi des remboursements CHIFA (CNAS) :
    - total_factures    : Nombre de factures CHIFA émises
    - montant_ppa       : Montant total au Prix Public Algérien
    - montant_remb      : Part remboursée par la CNAS
    - montant_non_remb  : Part payée par le patient
    - taux_remboursement: % moyen de remboursement
    - rejets_count      : Nombre de lignes rejetées partiellement
    - montant_rejete    : Montant total des rejets CNAS
    """
    date_from, date_to = _period_dates(period)

    # mt_officine = part CNAS (remboursée), mt_assure = part patient (non remboursée)
    # PPA total = mt_officine + mt_assure, majoration = mt_maj
    factures_res = await db.execute(
        select(
            func.count(FactureChifa.id).label("cnt"),
            func.coalesce(func.sum(FactureChifa.mt_officine + FactureChifa.mt_assure), 0).label("ppa"),
            func.coalesce(func.sum(FactureChifa.mt_officine), 0).label("remb"),
            func.coalesce(func.sum(FactureChifa.mt_assure), 0).label("non_remb"),
            func.coalesce(func.sum(FactureChifa.mt_maj), 0).label("majoration_facture"),
        ).where(
            and_(FactureChifa.date_fact >= date_from, FactureChifa.date_fact <= date_to)
        )
    )
    row = factures_res.one()

    # Rejets : jointure via num_facture / no_facture (pas d'id_facture dans le modèle actuel)
    rejets_res = await db.execute(
        select(
            func.count(ChifaRejetPartiel.id).label("cnt"),
            func.coalesce(func.sum(ChifaRejetPartiel.montant), 0).label("total"),
        ).join(
            FactureChifa, FactureChifa.no_facture == ChifaRejetPartiel.num_facture
        ).where(
            and_(FactureChifa.date_fact >= date_from, FactureChifa.date_fact <= date_to)
        )
    )
    rej_row = rejets_res.one()

    # Majoration côté sorties : ventes avec no_facture_chifa renseigné
    # (supplément versé par la caisse sociale sur la vente elle-même)
    maj_sorties_res = await db.execute(
        select(
            func.coalesce(func.sum(Sortie.majoration), 0).label("total"),
            func.count(Sortie.id).label("cnt"),
        ).where(
            and_(
                Sortie.date >= date_from,
                Sortie.date <= date_to,
                Sortie.no_facture_chifa != None,
                Sortie.majoration > 0,
            )
        )
    )
    maj_row = maj_sorties_res.one()

    ppa = _f(row.ppa)
    remb = _f(row.remb)
    majoration_facture = _f(row.majoration_facture)
    majoration_ventes = _f(maj_row.total)
    majoration_total = majoration_facture + majoration_ventes

    return {
        "period": period,
        "date_from": date_from.isoformat(),
        "date_to": date_to.isoformat(),
        "total_factures": row.cnt,
        "montant_ppa": ppa,
        "montant_remb": remb,
        "montant_non_remb": _f(row.non_remb),
        "taux_remboursement": round(remb / ppa * 100, 2) if ppa > 0 else 0.0,
        # majoration : bénéfice supplémentaire versé par les caisses sociales
        # = supplément sur factures CHIFA + supplément sur ventes CHIFA directes
        "majoration": {
            "total": majoration_total,
            "sur_factures_chifa": majoration_facture,
            "sur_ventes_chifa": majoration_ventes,
            "nb_ventes_avec_majoration": maj_row.cnt,
        },
        "rejets": {
            "count": rej_row.cnt,
            "montant": _f(rej_row.total),
            "taux_rejet": round(_f(rej_row.total) / ppa * 100, 2) if ppa > 0 else 0.0,
        },
    }


# ── 5. Tendance des ventes — données pour graphiques (KPI 17) ─────────────────

@router.get("/trends")
async def sales_trends(
    days: int = Query(30, ge=7, le=365),
    utilisateur: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Série temporelle des ventes jour par jour pour les <days> derniers jours.
    Sert à alimenter les graphiques d'évolution du dashboard.
    Filtrable par utilisateur pour la vue individuelle.
    """
    date_to = date.today()
    date_from = date_to - timedelta(days=days - 1)

    conditions = [
        Sortie.date >= date_from,
        Sortie.date <= date_to,
        Sortie.type != "AV",
    ]
    if utilisateur:
        conditions.append(Sortie.utilisateur == utilisateur)

    res = await db.execute(
        select(
            Sortie.date.label("day"),
            func.count(Sortie.id).label("transactions"),
            func.coalesce(func.sum(Sortie.total_a_payer), 0).label("ca"),
            func.coalesce(func.sum(Sortie.benefices), 0).label("benefices"),
        )
        .where(and_(*conditions))
        .group_by(Sortie.date)
        .order_by(Sortie.date)
    )
    rows = res.fetchall()

    # Fill missing days with zeros
    data_map = {r.day: r for r in rows}
    result = []
    for i in range(days):
        d = date_from + timedelta(days=i)
        if d in data_map:
            r = data_map[d]
            result.append({
                "date": d.isoformat(),
                "ca": _f(r.ca),
                "transactions": r.transactions,
                "benefices": _f(r.benefices),
            })
        else:
            result.append({"date": d.isoformat(), "ca": 0.0, "transactions": 0, "benefices": 0.0})

    return {"days": days, "utilisateur": utilisateur, "data": result}


# ── 6. Top produits & top clients (KPIs 18-19) ────────────────────────────────

@router.get("/top-products")
async def top_products(
    period: str = Query("month", enum=PERIOD_ENUM),
    limit: int = Query(10, ge=1, le=50),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Top produits par quantité vendue sur la période.
    Utile pour optimiser les achats et le réassort.
    """
    date_from, date_to = _period_dates(period)

    res = await db.execute(
        select(
            SortieProduit.id_nom,
            SortieProduit.nom,
            SortieProduit.famille,
            func.coalesce(func.sum(SortieProduit.qte_sortie), 0).label("qte_vendue"),
            func.coalesce(
                func.sum(SortieProduit.qte_sortie * SortieProduit.prix_vente), 0
            ).label("ca"),
        )
        .where(
            and_(
                SortieProduit.date >= date_from,
                SortieProduit.date <= date_to,
            )
        )
        .group_by(SortieProduit.id_nom, SortieProduit.nom, SortieProduit.famille)
        .order_by(desc("qte_vendue"))
        .limit(limit)
    )

    return {
        "period": period,
        "date_from": date_from.isoformat(),
        "date_to": date_to.isoformat(),
        "items": [
            {
                "id_nom": r.id_nom,
                "nom": r.nom,
                "famille": r.famille,
                "qte_vendue": _f(r.qte_vendue),
                "ca": _f(r.ca),
            }
            for r in res.fetchall()
        ],
    }


@router.get("/top-clients")
async def top_clients(
    period: str = Query("month", enum=PERIOD_ENUM),
    limit: int = Query(10, ge=1, le=50),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Top clients par CA sur la période.
    Identifie les clients VIP pour fidélisation et gestion du crédit.
    """
    date_from, date_to = _period_dates(period)

    res = await db.execute(
        select(
            Sortie.id_client,
            Sortie.client,
            func.count(Sortie.id).label("transactions"),
            func.coalesce(func.sum(Sortie.total_a_payer), 0).label("ca"),
            func.coalesce(func.sum(Sortie.benefices), 0).label("benefices"),
        )
        .where(
            and_(
                Sortie.date >= date_from,
                Sortie.date <= date_to,
                Sortie.type != "AV",
                Sortie.id_client != None,
            )
        )
        .group_by(Sortie.id_client, Sortie.client)
        .order_by(desc("ca"))
        .limit(limit)
    )

    return {
        "period": period,
        "items": [
            {
                "id_client": r.id_client,
                "client": r.client,
                "transactions": r.transactions,
                "ca": _f(r.ca),
                "benefices": _f(r.benefices),
            }
            for r in res.fetchall()
        ],
    }


# ── 7. Performance collective de l'équipe (KPI 20) ───────────────────────────

@router.get("/team")
async def team_performance(
    period: str = Query("month", enum=PERIOD_ENUM),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    KPIs par utilisateur (pharmacien/vendeur) pour comparer les performances.
    Croise les ventes avec la table groupware pour obtenir nom/prénom.
    Inclut : CA, transactions, panier moyen, marge, taux de marge.
    """
    date_from, date_to = _period_dates(period)

    # Agrégats de ventes par utilisateur
    sales_res = await db.execute(
        select(
            Sortie.utilisateur,
            func.count(Sortie.id).label("transactions"),
            func.coalesce(func.sum(Sortie.total_a_payer), 0).label("ca"),
            func.coalesce(func.sum(Sortie.benefices), 0).label("benefices"),
            func.coalesce(func.avg(Sortie.total_a_payer), 0).label("avg_basket"),
        )
        .where(
            and_(
                Sortie.date >= date_from,
                Sortie.date <= date_to,
                Sortie.type != "AV",
                Sortie.utilisateur != None,
            )
        )
        .group_by(Sortie.utilisateur)
        .order_by(desc("ca"))
    )
    sales_rows = sales_res.fetchall()

    # Info utilisateurs depuis groupware
    users_res = await db.execute(
        select(Groupware.utilisateur, Groupware.nom, Groupware.prenom, Groupware.role)
        .where(Groupware.actif == 1)
    )
    users_map = {r.utilisateur: r for r in users_res.fetchall()}

    result = []
    for row in sales_rows:
        ca = _f(row.ca)
        benefices = _f(row.benefices)
        user_info = users_map.get(row.utilisateur)
        result.append({
            "utilisateur": row.utilisateur,
            "nom": user_info.nom if user_info else None,
            "prenom": user_info.prenom if user_info else None,
            "role": user_info.role if user_info else None,
            "transactions": row.transactions,
            "ca": ca,
            "benefices": benefices,
            "avg_basket": round(_f(row.avg_basket), 2),
            "margin_rate": round(benefices / ca * 100, 2) if ca > 0 else 0.0,
        })

    return {
        "period": period,
        "date_from": date_from.isoformat(),
        "date_to": date_to.isoformat(),
        "team": result,
    }


# ── 8. Dashboard individuel (KPIs 21-22) ─────────────────────────────────────

@router.get("/individual/{utilisateur}")
async def individual_dashboard(
    utilisateur: str,
    period: str = Query("month", enum=PERIOD_ENUM),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Dashboard personnel d'un utilisateur :
    - Ses KPIs de vente (CA, transactions, marge) sur la période
    - Comparaison avec la période précédente
    - Tendance sur les 7 derniers jours
    - Activité par heure (pour identifier ses heures de pointe)
    - Top 5 produits qu'il vend le plus
    """
    date_from, date_to = _period_dates(period)
    prev_from, prev_to = _prev_period(date_from, date_to)

    # Infos utilisateur
    user_res = await db.execute(
        select(Groupware).where(Groupware.utilisateur == utilisateur)
    )
    user = user_res.scalar_one_or_none()

    # KPIs période courante
    current_res = await db.execute(
        select(
            func.count(Sortie.id).label("transactions"),
            func.coalesce(func.sum(Sortie.total_a_payer), 0).label("ca"),
            func.coalesce(func.sum(Sortie.benefices), 0).label("benefices"),
            func.coalesce(func.avg(Sortie.total_a_payer), 0).label("avg_basket"),
        ).where(
            and_(
                Sortie.utilisateur == utilisateur,
                Sortie.date >= date_from,
                Sortie.date <= date_to,
                Sortie.type != "AV",
            )
        )
    )
    cur = current_res.one()

    # KPIs période précédente
    prev_res = await db.execute(
        select(
            func.coalesce(func.sum(Sortie.total_a_payer), 0).label("ca"),
            func.count(Sortie.id).label("transactions"),
        ).where(
            and_(
                Sortie.utilisateur == utilisateur,
                Sortie.date >= prev_from,
                Sortie.date <= prev_to,
                Sortie.type != "AV",
            )
        )
    )
    prev = prev_res.one()

    # Tendance 7 jours
    trend_from = date.today() - timedelta(days=6)
    trend_res = await db.execute(
        select(
            Sortie.date.label("day"),
            func.count(Sortie.id).label("transactions"),
            func.coalesce(func.sum(Sortie.total_a_payer), 0).label("ca"),
        )
        .where(
            and_(
                Sortie.utilisateur == utilisateur,
                Sortie.date >= trend_from,
                Sortie.date <= date.today(),
                Sortie.type != "AV",
            )
        )
        .group_by(Sortie.date)
        .order_by(Sortie.date)
    )
    trend_map = {r.day: r for r in trend_res.fetchall()}
    trend_7d = []
    for i in range(7):
        d = trend_from + timedelta(days=i)
        r = trend_map.get(d)
        trend_7d.append({
            "date": d.isoformat(),
            "ca": _f(r.ca) if r else 0.0,
            "transactions": r.transactions if r else 0,
        })

    # Activité par heure
    hour_res = await db.execute(
        select(
            Sortie.heure.label("heure"),
            func.count(Sortie.id).label("transactions"),
            func.coalesce(func.sum(Sortie.total_a_payer), 0).label("ca"),
        )
        .where(
            and_(
                Sortie.utilisateur == utilisateur,
                Sortie.date >= date_from,
                Sortie.date <= date_to,
                Sortie.type != "AV",
                Sortie.heure != None,
            )
        )
        .group_by(Sortie.heure)
        .order_by(Sortie.heure)
    )

    # Top 5 produits vendus par cet utilisateur
    top5_res = await db.execute(
        select(
            SortieProduit.nom,
            func.coalesce(func.sum(SortieProduit.qte_sortie), 0).label("qte"),
        )
        .where(
            and_(
                SortieProduit.utilisateur == utilisateur,
                SortieProduit.date >= date_from,
                SortieProduit.date <= date_to,
            )
        )
        .group_by(SortieProduit.nom)
        .order_by(desc("qte"))
        .limit(5)
    )

    ca = _f(cur.ca)
    benefices = _f(cur.benefices)
    prev_ca = _f(prev.ca)

    return {
        "utilisateur": utilisateur,
        "nom": user.nom if user else None,
        "prenom": user.prenom if user else None,
        "period": period,
        "date_from": date_from.isoformat(),
        "date_to": date_to.isoformat(),
        "kpis": {
            "ca": ca,
            "transactions": cur.transactions,
            "avg_basket": round(_f(cur.avg_basket), 2),
            "benefices": benefices,
            "margin_rate": round(benefices / ca * 100, 2) if ca > 0 else 0.0,
        },
        "vs_previous": {
            "ca": prev_ca,
            "ca_delta_pct": _pct_delta(ca, prev_ca),
            "transactions": prev.transactions,
        },
        "trend_7d": trend_7d,
        "activity_by_hour": [
            {"heure": r.heure, "transactions": r.transactions, "ca": _f(r.ca)}
            for r in hour_res.fetchall()
        ],
        "top_5_produits": [
            {"nom": r.nom, "qte_vendue": _f(r.qte)}
            for r in top5_res.fetchall()
        ],
    }


# ── 9. Activité par heure — planification équipe (KPI 22) ────────────────────

@router.get("/activity-by-hour")
async def activity_by_hour(
    period: str = Query("month", enum=PERIOD_ENUM),
    utilisateur: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Distribution des ventes par heure de la journée.
    Permet de planifier les équipes sur les heures de pointe.
    Filtrable par utilisateur.
    """
    date_from, date_to = _period_dates(period)

    conditions = [
        Sortie.date >= date_from,
        Sortie.date <= date_to,
        Sortie.type != "AV",
        Sortie.heure != None,
    ]
    if utilisateur:
        conditions.append(Sortie.utilisateur == utilisateur)

    res = await db.execute(
        select(
            Sortie.heure.label("heure"),
            func.count(Sortie.id).label("transactions"),
            func.coalesce(func.sum(Sortie.total_a_payer), 0).label("ca"),
        )
        .where(and_(*conditions))
        .group_by(Sortie.heure)
        .order_by(Sortie.heure)
    )

    return {
        "period": period,
        "utilisateur": utilisateur,
        "data": [
            {"heure": r.heure, "transactions": r.transactions, "ca": _f(r.ca)}
            for r in res.fetchall()
        ],
    }


# ── 10. CRM — Gestion de la relation client ────────────────────────────────────

@router.get("/crm/overview")
async def crm_overview(
    period: str = Query("month", enum=PERIOD_ENUM),
    inactive_days: int = Query(90, ge=30, le=365),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Vue d'ensemble CRM :
    - clients_actifs      : Clients ayant acheté dans la période
    - nouveaux_clients    : Clients dont c'est le premier achat (acquisition)
    - clients_inactifs    : Clients sans achat depuis <inactive_days> jours (churn)
    - freq_achat_moy      : Nombre moyen de visites par client actif
    - ca_moyen_client     : CA moyen par client actif sur la période
    - total_clients_bd    : Total clients en base (référentiel)
    - clients_chroniques  : Patients avec maladie chronique (segment fidèle)
    - clients_avec_credit : Clients ayant un solde débiteur (crédit accordé)
    - total_creances      : Montant total des créances clients
    """
    date_from, date_to = _period_dates(period)
    today = date.today()

    # Clients actifs sur la période (ont fait au moins un achat)
    actifs_res = await db.execute(
        select(
            func.count(func.distinct(Sortie.id_client)).label("cnt"),
            func.coalesce(func.sum(Sortie.total_a_payer), 0).label("ca"),
            func.count(Sortie.id).label("transactions"),
        ).where(
            and_(
                Sortie.date >= date_from,
                Sortie.date <= date_to,
                Sortie.type != "AV",
                Sortie.id_client != None,
            )
        )
    )
    actifs_row = actifs_res.one()
    clients_actifs = actifs_row.cnt
    ca_periode = _f(actifs_row.ca)

    # Nouveaux clients : premier achat dans la période
    # (leur date min d'achat tombe dans date_from..date_to)
    nouveaux_res = await db.execute(
        text("""
            SELECT COUNT(*) FROM (
                SELECT id_client
                FROM sorties
                WHERE id_client IS NOT NULL
                  AND type != 'AV'
                GROUP BY id_client
                HAVING MIN(date) BETWEEN :d_from AND :d_to
            ) sub
        """),
        {"d_from": date_from, "d_to": date_to},
    )
    nouveaux_clients = nouveaux_res.scalar() or 0

    # Clients inactifs : ont déjà acheté, mais pas depuis inactive_days jours
    inactif_cutoff = today - timedelta(days=inactive_days)
    inactifs_res = await db.execute(
        text("""
            SELECT COUNT(*) FROM (
                SELECT id_client
                FROM sorties
                WHERE id_client IS NOT NULL
                  AND type != 'AV'
                GROUP BY id_client
                HAVING MAX(date) < :cutoff
            ) sub
        """),
        {"cutoff": inactif_cutoff},
    )
    clients_inactifs = inactifs_res.scalar() or 0

    # Total clients en base
    total_res = await db.execute(select(func.count(Client.id)))
    total_clients = total_res.scalar() or 0

    # Clients chroniques
    chroniques_res = await db.execute(
        select(func.count(Client.id)).where(Client.chronique == 1)
    )
    clients_chroniques = chroniques_res.scalar() or 0

    # Clients avec crédit en cours
    credit_res = await db.execute(
        select(
            func.count(Client.id).label("cnt"),
            func.coalesce(func.sum(Client.credit), 0).label("total"),
        ).where(Client.credit > 0)
    )
    credit_row = credit_res.one()

    freq_moy = round(actifs_row.transactions / clients_actifs, 1) if clients_actifs > 0 else 0.0
    ca_moy = round(ca_periode / clients_actifs, 2) if clients_actifs > 0 else 0.0

    return {
        "period": period,
        "date_from": date_from.isoformat(),
        "date_to": date_to.isoformat(),
        "clients_actifs": clients_actifs,
        "nouveaux_clients": nouveaux_clients,
        "clients_inactifs": {
            "count": clients_inactifs,
            "horizon_jours": inactive_days,
        },
        "freq_achat_moy": freq_moy,
        "ca_moyen_client": ca_moy,
        "total_clients_bd": total_clients,
        "clients_chroniques": clients_chroniques,
        "clients_avec_credit": {
            "count": credit_row.cnt,
            "total_creances": _f(credit_row.total),
        },
    }


@router.get("/crm/debtors")
async def crm_debtors(
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Top clients débiteurs (solde crédit non réglé).
    Permet de prioriser les relances et gérer le risque de crédit.
    Inclut : crédit restant, solde max autorisé, % d'utilisation du plafond.
    """
    res = await db.execute(
        select(
            Client.id,
            Client.client,
            Client.telephone,
            Client.credit,
            Client.solde_max,
            Client.activer_solde_max,
            Client.ventes,
            Client.versements,
        )
        .where(Client.credit > 0)
        .order_by(desc(Client.credit))
        .limit(limit)
    )

    items = []
    for r in res.fetchall():
        credit = _f(r.credit)
        solde_max = _f(r.solde_max)
        items.append({
            "id": r.id,
            "client": r.client,
            "telephone": r.telephone,
            "credit": credit,
            "solde_max": solde_max if r.activer_solde_max else None,
            "pct_plafond": round(credit / solde_max * 100, 1) if (r.activer_solde_max and solde_max > 0) else None,
            "total_ventes": _f(r.ventes),
            "total_versements": _f(r.versements),
        })

    return {"items": items}


@router.get("/crm/segments")
async def crm_segments(
    period: str = Query("month", enum=PERIOD_ENUM),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Segmentation des clients par type de prise en charge :
    - comptoir       : Clients sans prise en charge (paiement direct)
    - chifa          : Assurés CNAS/CHIFA
    - cvm            : Ayants droit militaires (CVM)
    - chroniques     : Patients avec maladies chroniques (fidèles, CA régulier)
    Chaque segment : nombre de clients, CA, transactions sur la période.
    Permet de comprendre la structure du portefeuille clients.
    """
    date_from, date_to = _period_dates(period)

    async def _seg_stats(condition):
        r = await db.execute(
            select(
                func.count(func.distinct(Sortie.id_client)).label("clients"),
                func.count(Sortie.id).label("transactions"),
                func.coalesce(func.sum(Sortie.total_a_payer), 0).label("ca"),
            ).where(
                and_(
                    Sortie.date >= date_from,
                    Sortie.date <= date_to,
                    Sortie.type != "AV",
                    condition,
                )
            )
        )
        row = r.one()
        return {
            "clients": row.clients,
            "transactions": row.transactions,
            "ca": _f(row.ca),
        }

    chifa = await _seg_stats(Sortie.no_facture_chifa != None)
    cvm = await _seg_stats(Sortie.num_assure_cvm != None)
    # comptoir = pas de no_facture_chifa ni num_assure_cvm
    comptoir = await _seg_stats(
        and_(Sortie.no_facture_chifa == None, Sortie.num_assure_cvm == None)
    )

    # Chroniques : clients avec chronique=True ayant acheté dans la période
    chron_res = await db.execute(
        select(
            func.count(func.distinct(Sortie.id_client)).label("clients"),
            func.coalesce(func.sum(Sortie.total_a_payer), 0).label("ca"),
        ).join(Client, Client.id == Sortie.id_client).where(
            and_(
                Sortie.date >= date_from,
                Sortie.date <= date_to,
                Sortie.type != "AV",
                Client.chronique == 1,
            )
        )
    )
    chron_row = chron_res.one()

    return {
        "period": period,
        "date_from": date_from.isoformat(),
        "date_to": date_to.isoformat(),
        "comptoir": comptoir,
        "chifa": chifa,
        "cvm": cvm,
        "chroniques": {
            "clients": chron_row.clients,
            "ca": _f(chron_row.ca),
        },
    }


@router.get("/crm/retention")
async def crm_retention(
    months: int = Query(6, ge=2, le=24),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Rétention mensuelle des clients sur les <months> derniers mois.
    Pour chaque mois : clients actifs, nouveaux, perdus (pas revenus le mois suivant).
    Permet de mesurer la fidélité et détecter les tendances de churn.
    """
    today = date.today()
    result = []

    for i in range(months - 1, -1, -1):
        # Début du mois i mois en arrière
        m_date = today.replace(day=1) - timedelta(days=i * 28)
        m_start = m_date.replace(day=1)
        # Fin du mois
        if m_start.month == 12:
            m_end = m_start.replace(year=m_start.year + 1, month=1, day=1) - timedelta(days=1)
        else:
            m_end = m_start.replace(month=m_start.month + 1, day=1) - timedelta(days=1)

        actifs_res = await db.execute(
            select(func.count(func.distinct(Sortie.id_client))).where(
                and_(
                    Sortie.date >= m_start,
                    Sortie.date <= m_end,
                    Sortie.type != "AV",
                    Sortie.id_client != None,
                )
            )
        )
        actifs = actifs_res.scalar() or 0

        nouveaux_res = await db.execute(
            text("""
                SELECT COUNT(*) FROM (
                    SELECT id_client
                    FROM sorties
                    WHERE id_client IS NOT NULL AND type != 'AV'
                    GROUP BY id_client
                    HAVING MIN(date) BETWEEN :d_from AND :d_to
                ) sub
            """),
            {"d_from": m_start, "d_to": m_end},
        )
        nouveaux = nouveaux_res.scalar() or 0

        ca_res = await db.execute(
            select(func.coalesce(func.sum(Sortie.total_a_payer), 0)).where(
                and_(
                    Sortie.date >= m_start,
                    Sortie.date <= m_end,
                    Sortie.type != "AV",
                )
            )
        )

        result.append({
            "mois": m_start.strftime("%Y-%m"),
            "clients_actifs": actifs,
            "nouveaux_clients": nouveaux,
            "ca": _f(ca_res.scalar()),
        })

    return {"months": months, "data": result}


@router.get("/crm/client/{client_id}")
async def crm_client_profile(
    client_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Profil complet d'un client :
    - Informations de base (nom, téléphone, solde)
    - Historique d'achat : CA total, nombre de visites, panier moyen
    - Dernière visite
    - Segmentation (chronique, CHIFA, CVM)
    - Tendance 6 mois (CA par mois)
    """
    client_res = await db.execute(select(Client).where(Client.id == client_id))
    client = client_res.scalar_one_or_none()
    if not client:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Client introuvable")

    # Historique global
    hist_res = await db.execute(
        select(
            func.count(Sortie.id).label("transactions"),
            func.coalesce(func.sum(Sortie.total_a_payer), 0).label("ca_total"),
            func.coalesce(func.avg(Sortie.total_a_payer), 0).label("avg_basket"),
            func.max(Sortie.date).label("derniere_visite"),
            func.min(Sortie.date).label("premiere_visite"),
        ).where(
            and_(Sortie.id_client == client_id, Sortie.type != "AV")
        )
    )
    hist = hist_res.one()

    # Tendance 6 derniers mois
    today = date.today()
    trend = []
    for i in range(5, -1, -1):
        m_date = today.replace(day=1) - timedelta(days=i * 28)
        m_start = m_date.replace(day=1)
        if m_start.month == 12:
            m_end = m_start.replace(year=m_start.year + 1, month=1, day=1) - timedelta(days=1)
        else:
            m_end = m_start.replace(month=m_start.month + 1, day=1) - timedelta(days=1)

        m_res = await db.execute(
            select(
                func.count(Sortie.id).label("cnt"),
                func.coalesce(func.sum(Sortie.total_a_payer), 0).label("ca"),
            ).where(
                and_(
                    Sortie.id_client == client_id,
                    Sortie.date >= m_start,
                    Sortie.date <= m_end,
                    Sortie.type != "AV",
                )
            )
        )
        m_row = m_res.one()
        trend.append({
            "mois": m_start.strftime("%Y-%m"),
            "transactions": m_row.cnt,
            "ca": _f(m_row.ca),
        })

    return {
        "id": client.id,
        "client": client.client,
        "telephone": client.telephone,
        "adresse": client.adresse,
        "credit": _f(client.credit),
        "solde_max": _f(client.solde_max) if client.activer_solde_max else None,
        "n_assure_chifa": client.n_assure_chifa,
        "num_assure_cvm": client.num_assure_cvm,
        "chronique": client.chronique,
        "pathologie": client.pathologie,
        "historique": {
            "transactions": hist.transactions,
            "ca_total": _f(hist.ca_total),
            "avg_basket": round(_f(hist.avg_basket), 2),
            "premiere_visite": hist.premiere_visite.isoformat() if hist.premiere_visite else None,
            "derniere_visite": hist.derniere_visite.isoformat() if hist.derniere_visite else None,
        },
        "trend_6_mois": trend,
    }
