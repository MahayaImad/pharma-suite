"""
Ventes endpoints — Sorties & SortieProduits
"""
from typing import Optional
from datetime import date
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, desc, text

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.ventes import Sortie, SortieProduit

router = APIRouter(prefix="/ventes", tags=["ventes"])


def _f(val) -> float:
    return float(val) if val is not None else 0.0


@router.get("")
async def list_ventes(
    date_from: Optional[date] = Query(None),
    date_to: Optional[date] = Query(None),
    client: Optional[str] = Query(None, description="Recherche par nom client"),
    type: Optional[str] = Query(None, description="VT=vente, AV=avoir/retour"),
    caisse: Optional[str] = Query(None),
    utilisateur: Optional[str] = Query(None),
    n_assure: Optional[str] = Query(None, description="Numéro assuré CHIFA"),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Liste paginée des sorties (ventes & avoirs)."""
    conditions = []
    if date_from:
        conditions.append(Sortie.date >= date_from)
    if date_to:
        conditions.append(Sortie.date <= date_to)
    if client:
        conditions.append(Sortie.client.ilike(f"%{client}%"))
    if type:
        # Mapping frontend (VT/AV) → valeurs réelles en base (V/A)
        db_type = {'VT': 'V', 'AV': 'A'}.get(type, type)
        conditions.append(Sortie.type == db_type)
    if caisse:
        conditions.append(Sortie.caisse == caisse)
    if utilisateur:
        conditions.append(Sortie.utilisateur == utilisateur)
    if n_assure:
        conditions.append(Sortie.n_assure == n_assure)

    where = and_(*conditions) if conditions else True

    total_res = await db.execute(select(func.count(Sortie.id)).where(where))
    total = total_res.scalar() or 0

    res = await db.execute(
        select(
            Sortie.id,
            Sortie.date,
            Sortie.heure,
            Sortie.type,
            Sortie.id_client,
            Sortie.client,
            Sortie.total,
            Sortie.remise,
            Sortie.total_a_payer,
            Sortie.versement,
            Sortie.type_versement,
            Sortie.benefices,
            Sortie.majoration,
            Sortie.caisse,
            Sortie.utilisateur,
            Sortie.poste,
            Sortie.no_facture_chifa,
            Sortie.n_assure,
            Sortie.num_assure_cvm,
            Sortie.num_fact,
        )
        .where(where)
        .order_by(desc(Sortie.date), desc(Sortie.id))
        .limit(limit)
        .offset(offset)
    )

    items = [
        {
            "id": r.id,
            "date": r.date.isoformat() if r.date else None,
            "heure": r.heure,
            "type": r.type,
            "id_client": r.id_client,
            "client": r.client,
            "total": _f(r.total),
            "remise": _f(r.remise),
            "total_a_payer": _f(r.total_a_payer),
            "versement": _f(r.versement),
            "type_versement": r.type_versement,
            "benefices": _f(r.benefices),
            "majoration": _f(r.majoration),
            "caisse": r.caisse,
            "utilisateur": r.utilisateur,
            "poste": r.poste,
            "no_facture_chifa": r.no_facture_chifa,
            "n_assure": r.n_assure,
            "num_assure_cvm": r.num_assure_cvm,
            "num_fact": r.num_fact,
        }
        for r in res.fetchall()
    ]

    return {"total": total, "limit": limit, "offset": offset, "items": items}


@router.get("/{vente_id}/detail")
async def get_vente_detail(
    vente_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Détail d'une vente : en-tête + lignes produits."""
    sortie_res = await db.execute(select(Sortie).where(Sortie.id == vente_id))
    sortie = sortie_res.scalar_one_or_none()
    if not sortie:
        raise HTTPException(status_code=404, detail="Vente introuvable")

    produits_res = await db.execute(
        select(
            SortieProduit.id,
            SortieProduit.id_nom,
            SortieProduit.nom,
            SortieProduit.famille,
            SortieProduit.lot,
            SortieProduit.peremption,
            SortieProduit.qte_sortie,
            SortieProduit.prix_vente,
            SortieProduit.prix_achat_ttc,
            SortieProduit.psychotrope,
            SortieProduit.no_facture_chifa,
            SortieProduit.remb_cvm,
        ).where(SortieProduit.id_sortie == vente_id)
    )

    return {
        "sortie": {
            "id": sortie.id,
            "date": sortie.date.isoformat() if sortie.date else None,
            "heure": sortie.heure,
            "type": sortie.type,
            "id_client": sortie.id_client,
            "client": sortie.client,
            "total": _f(sortie.total),
            "remise": _f(sortie.remise),
            "total_a_payer": _f(sortie.total_a_payer),
            "versement": _f(sortie.versement),
            "type_versement": sortie.type_versement,
            "benefices": _f(sortie.benefices),
            "majoration": _f(sortie.majoration),
            "caisse": sortie.caisse,
            "utilisateur": sortie.utilisateur,
            "no_facture_chifa": sortie.no_facture_chifa,
            "montant_cnas": _f(sortie.montant_cnas),
            "montant_assure": _f(sortie.montant_assure),
            "n_assure": sortie.n_assure,
            "num_assure_cvm": sortie.num_assure_cvm,
            "num_fact": sortie.num_fact,
            "observation": sortie.observation,
        },
        "produits": [
            {
                "id": r.id,
                "id_nom": r.id_nom,
                "nom": r.nom,
                "famille": r.famille,
                "lot": r.lot,
                "peremption": r.peremption,
                "qte_sortie": r.qte_sortie,
                "prix_vente": _f(r.prix_vente),
                "prix_achat_ttc": _f(r.prix_achat_ttc),
                "psychotrope": r.psychotrope,
                "no_facture_chifa": r.no_facture_chifa,
                "remb_cvm": r.remb_cvm,
            }
            for r in produits_res.fetchall()
        ],
    }


# ── Helpers listes de filtres ──────────────────────────────────────────────────

@router.get("/employes")
async def list_ventes_employes(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Utilisateurs distincts présents dans les ventes."""
    res = await db.execute(text("""
        SELECT DISTINCT utilisateur
        FROM sorties
        WHERE utilisateur IS NOT NULL AND utilisateur != ''
        ORDER BY utilisateur
    """))
    return [r.utilisateur for r in res.fetchall()]


@router.get("/familles")
async def list_ventes_familles(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Familles distinctes dans les lignes de vente."""
    res = await db.execute(text("""
        SELECT DISTINCT famille
        FROM sorties_produits
        WHERE famille IS NOT NULL AND famille != ''
        ORDER BY famille
    """))
    return [r.famille for r in res.fetchall()]


# ── Tableau de bord ────────────────────────────────────────────────────────────

@router.get("/dashboard")
async def ventes_dashboard(
    date_mode: str = Query("mois", description="mois | jour"),
    sel_date: Optional[date] = Query(None, alias="date", description="Date précise (mode jour)"),
    annee: Optional[int] = Query(None),
    mois: Optional[int] = Query(None),
    employe: Optional[str] = Query(None),
    famille: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Tableau de bord ventes : KPIs, répartitions catégorie / famille / CHIFA."""
    from datetime import date as date_cls
    today = date_cls.today()
    params: dict = {}

    # ── Filtre date ───────────────────────────────────────────────────────
    if date_mode == "jour":
        d = sel_date or today
        params["sel_date"] = d
        date_where = "s.date = :sel_date"
    else:
        a = annee or today.year
        params["annee"] = a
        if mois:
            params["mois"] = mois
            date_where = "EXTRACT(YEAR FROM s.date)=:annee AND EXTRACT(MONTH FROM s.date)=:mois"
        else:
            date_where = "EXTRACT(YEAR FROM s.date)=:annee"

    # ── Filtre employé ────────────────────────────────────────────────────
    emp_where = ""
    if employe:
        emp_where = "AND s.utilisateur = :employe"
        params["employe"] = employe

    # ── Filtre famille ────────────────────────────────────────────────────
    fam_where_s = ""
    fam_where_sp = ""
    if famille:
        fam_where_s = "AND EXISTS (SELECT 1 FROM sorties_produits sp0 WHERE sp0.id_sortie = s.id AND sp0.famille = :famille)"
        fam_where_sp = "AND sp.famille = :famille"
        params["famille"] = famille

    # ── KPIs principaux ───────────────────────────────────────────────────
    kpi_res = await db.execute(text(f"""
        SELECT
            COALESCE(SUM(s.total_a_payer), 0) AS ca,
            COUNT(DISTINCT s.id)               AS nb_factures,
            COUNT(DISTINCT CASE
                WHEN s.no_facture_chifa IS NOT NULL AND s.no_facture_chifa != ''
                THEN s.id END)                 AS nb_factures_chifa
        FROM sorties s
        WHERE {date_where}
          {emp_where}
          {fam_where_s}
    """), params)
    kpi = kpi_res.fetchone()
    ca           = float(kpi.ca or 0)
    nb_factures  = int(kpi.nb_factures or 0)
    nb_fc        = int(kpi.nb_factures_chifa or 0)
    panier_moyen = round(ca / nb_factures, 2) if nb_factures > 0 else 0.0

    # ── Nb lignes ─────────────────────────────────────────────────────────
    lignes_res = await db.execute(text(f"""
        SELECT COUNT(sp.id) AS nb
        FROM sorties_produits sp
        JOIN sorties s ON s.id = sp.id_sortie
        WHERE {date_where}
          {emp_where}
          {fam_where_sp}
    """), params)
    nb_lignes = int(lignes_res.scalar() or 0)

    # ── KPIs CHIFA (quota psychotropes + taux recouvrement) ──────────────
    chifa_res = await db.execute(text(f"""
        SELECT
            COALESCE(SUM(CASE WHEN sp.psychotrope = 1 THEN sp.qte_sortie ELSE 0 END), 0) AS nb_quota,
            CASE
                WHEN COALESCE(SUM(s.montant_cnas), 0) + COALESCE(SUM(s.montant_assure), 0) > 0
                THEN COALESCE(SUM(s.montant_cnas), 0)
                     / (COALESCE(SUM(s.montant_cnas), 0) + COALESCE(SUM(s.montant_assure), 0))
                     * 100
                ELSE 0
            END AS taux_recouvrement
        FROM sorties_produits sp
        JOIN sorties s ON s.id = sp.id_sortie
        WHERE s.no_facture_chifa IS NOT NULL AND s.no_facture_chifa != ''
          AND {date_where}
          {emp_where}
          {fam_where_s}
    """), params)
    chifa = chifa_res.fetchone()

    # ── KPIs instances (filtre date sur ip.date = date de création) ───────
    # Construire le filtre date pour instance_produits (préfixe ip.)
    if date_mode == "jour":
        inst_date_where = "ip.date = :sel_date"
    elif mois:
        inst_date_where = "EXTRACT(YEAR FROM ip.date)=:annee AND EXTRACT(MONTH FROM ip.date)=:mois"
    else:
        inst_date_where = "EXTRACT(YEAR FROM ip.date)=:annee"
    inst_emp_where = "AND ip.utilisateur = :employe" if employe else ""

    inst_res = await db.execute(text(f"""
        SELECT
            COUNT(DISTINCT (ip.id_client, ip.date, ip.heure))
                FILTER (WHERE ip.archive = FALSE)                       AS nb_instances,
            COUNT(DISTINCT (ip.id_client, ip.date, ip.heure))
                FILTER (WHERE ip.archive = TRUE)                        AS nb_instances_validees,
            COUNT(DISTINCT ip.utilisateur_validation)
                FILTER (WHERE ip.archive = TRUE)                        AS nb_valideurs
        FROM instance_produits ip
        WHERE {inst_date_where}
          {inst_emp_where}
    """), params)
    inst = inst_res.fetchone()

    # ── Répartition catégorie ─────────────────────────────────────────────
    ca_safe = ca if ca > 0 else 1
    cat_res = await db.execute(text(f"""
        SELECT
            COALESCE(n.categorie, 'non défini') AS categorie,
            COUNT(sp.id)                         AS nb_lignes,
            COALESCE(SUM(sp.qte_sortie * sp.prix_vente), 0) AS ca
        FROM sorties_produits sp
        JOIN sorties s ON s.id = sp.id_sortie
        LEFT JOIN nomenclature n ON n.id = sp.id_nom
        WHERE {date_where}
          {emp_where}
          {fam_where_sp}
        GROUP BY COALESCE(n.categorie, 'non défini')
        ORDER BY ca DESC
    """), params)
    repartition_categorie = [
        {
            "categorie": r.categorie,
            "nb_lignes":  int(r.nb_lignes),
            "ca":         float(r.ca),
            "pct":        round(float(r.ca) / ca_safe * 100, 1),
        }
        for r in cat_res.fetchall()
    ]

    # ── Répartition famille (top 10) ──────────────────────────────────────
    fam_res = await db.execute(text(f"""
        SELECT
            COALESCE(sp.famille, 'Autre') AS famille,
            COALESCE(SUM(sp.qte_sortie * sp.prix_vente), 0) AS ca
        FROM sorties_produits sp
        JOIN sorties s ON s.id = sp.id_sortie
        WHERE {date_where}
          {emp_where}
          {fam_where_sp}
        GROUP BY COALESCE(sp.famille, 'Autre')
        ORDER BY ca DESC
        LIMIT 10
    """), params)
    repartition_famille = [
        {
            "famille": r.famille,
            "ca":      float(r.ca),
            "pct":     round(float(r.ca) / ca_safe * 100, 1),
        }
        for r in fam_res.fetchall()
    ]

    # ── Répartition CHIFA vs vente libre ──────────────────────────────────
    cl_res = await db.execute(text(f"""
        SELECT
            CASE WHEN s.no_facture_chifa IS NOT NULL AND s.no_facture_chifa != ''
                 THEN 'chifa' ELSE 'libre' END AS canal,
            COUNT(DISTINCT s.id)               AS nb_factures,
            COALESCE(SUM(s.total_a_payer), 0)  AS ca
        FROM sorties s
        WHERE {date_where}
          {emp_where}
          {fam_where_s}
        GROUP BY canal
    """), params)
    chifa_libre: dict = {"chifa": {"nb": 0, "ca": 0.0}, "libre": {"nb": 0, "ca": 0.0}}
    for r in cl_res.fetchall():
        chifa_libre[r.canal] = {"nb": int(r.nb_factures), "ca": float(r.ca)}

    return {
        "kpis": {
            "ca":                ca,
            "nb_lignes":         nb_lignes,
            "nb_factures":       nb_factures,
            "panier_moyen":      panier_moyen,
            "nb_factures_chifa": nb_fc,
        },
        "chifa_kpis": {
            "nb_quota":               int(chifa.nb_quota or 0),
            "taux_recouvrement":      round(float(chifa.taux_recouvrement or 0), 1),
        },
        "instances_kpis": {
            "nb_instances":           int(inst.nb_instances or 0),
            "nb_instances_validees":  int(inst.nb_instances_validees or 0),
        },
        "repartition_categorie": repartition_categorie,
        "repartition_famille":   repartition_famille,
        "repartition_chifa":     chifa_libre,
    }


# ── Instances par employé ──────────────────────────────────────────────────────

@router.get("/instances/employes")
async def instances_par_employe(
    date_mode: str = Query("mois", description="mois | jour"),
    sel_date: Optional[date] = Query(None, alias="date"),
    annee: Optional[int] = Query(None),
    mois: Optional[int] = Query(None),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Statistiques instances par employé :
    - nb_instances_crees    : instances créées (toutes, groupées par client/date/heure)
    - nb_instances_validees : instances validées (archive=True, par utilisateur_validation)
    """
    from datetime import date as date_cls
    today = date_cls.today()
    params: dict = {}

    if date_mode == "jour":
        d = sel_date or today
        params["sel_date"] = d
        date_where = "ip.date = :sel_date"
    else:
        a = annee or today.year
        params["annee"] = a
        if mois:
            params["mois"] = mois
            date_where = "EXTRACT(YEAR FROM ip.date)=:annee AND EXTRACT(MONTH FROM ip.date)=:mois"
        else:
            date_where = "EXTRACT(YEAR FROM ip.date)=:annee"

    res = await db.execute(text(f"""
        WITH groupes AS (
            -- Chaque groupe unique (id_client, date, heure) = 1 instance
            SELECT
                ip.utilisateur,
                ip.utilisateur_validation,
                ip.archive,
                MIN(ip.id) AS first_id   -- représentant du groupe
            FROM instance_produits ip
            WHERE {date_where}
            GROUP BY ip.id_client, ip.date, ip.heure, ip.utilisateur, ip.utilisateur_validation, ip.archive
        )
        SELECT
            e.employe,
            COALESCE(c.nb_crees, 0)    AS nb_instances_crees,
            COALESCE(v.nb_validees, 0) AS nb_instances_validees
        FROM (
            SELECT utilisateur AS employe FROM groupes WHERE utilisateur IS NOT NULL
            UNION
            SELECT utilisateur_validation FROM groupes WHERE utilisateur_validation IS NOT NULL
        ) e
        LEFT JOIN (
            SELECT utilisateur AS employe, COUNT(*) AS nb_crees
            FROM groupes
            WHERE utilisateur IS NOT NULL
            GROUP BY utilisateur
        ) c ON c.employe = e.employe
        LEFT JOIN (
            SELECT utilisateur_validation AS employe, COUNT(*) AS nb_validees
            FROM groupes
            WHERE archive = TRUE AND utilisateur_validation IS NOT NULL
            GROUP BY utilisateur_validation
        ) v ON v.employe = e.employe
        ORDER BY (COALESCE(c.nb_crees, 0) + COALESCE(v.nb_validees, 0)) DESC
    """), params)

    return [
        {
            "employe":               r.employe,
            "nb_instances_crees":    int(r.nb_instances_crees),
            "nb_instances_validees": int(r.nb_instances_validees),
        }
        for r in res.fetchall()
    ]


# ── Radar employés ─────────────────────────────────────────────────────────────

@router.get("/radar")
async def ventes_radar(
    date_mode: str = Query("mois", description="mois | jour"),
    sel_date: Optional[date] = Query(None, alias="date"),
    annee: Optional[int] = Query(None),
    mois: Optional[int] = Query(None),
    famille: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """KPIs par employé + moyenne — pour le graphique spider."""
    from datetime import date as date_cls
    today = date_cls.today()
    params: dict = {}

    if date_mode == "jour":
        d = sel_date or today
        params["sel_date"] = d
        date_where = "s.date = :sel_date"
    else:
        a = annee or today.year
        params["annee"] = a
        if mois:
            params["mois"] = mois
            date_where = "EXTRACT(YEAR FROM s.date)=:annee AND EXTRACT(MONTH FROM s.date)=:mois"
        else:
            date_where = "EXTRACT(YEAR FROM s.date)=:annee"

    fam_where = ""
    if famille:
        fam_where = "AND EXISTS (SELECT 1 FROM sorties_produits sp0 WHERE sp0.id_sortie = s.id AND sp0.famille = :famille)"
        params["famille"] = famille

    res = await db.execute(text(f"""
        SELECT
            s.utilisateur                                                                AS nom,
            COALESCE(e.eligible_prime, true)                                             AS eligible_prime,
            COALESCE(SUM(s.total_a_payer), 0)                                           AS ca,
            COUNT(DISTINCT s.id)                                                         AS nb_factures,
            COUNT(sp.id)                                                                 AS nb_lignes,
            COUNT(DISTINCT CASE
                WHEN s.no_facture_chifa IS NOT NULL AND s.no_facture_chifa != ''
                THEN s.id END)                                                           AS nb_factures_chifa
        FROM sorties s
        LEFT JOIN sorties_produits sp ON sp.id_sortie = s.id
        LEFT JOIN employes e ON LOWER(e.username) = LOWER(s.utilisateur)
        WHERE s.utilisateur IS NOT NULL AND s.utilisateur != ''
          AND COALESCE(e.eligible_prime, true) = true
          AND {date_where}
          {fam_where}
        GROUP BY s.utilisateur, e.eligible_prime
        ORDER BY ca DESC
    """), params)

    rows = res.fetchall()
    employes_list = []
    for r in rows:
        nb_f = int(r.nb_factures or 0)
        ca   = float(r.ca or 0)
        employes_list.append({
            "nom":               r.nom,
            "eligible_prime":    bool(r.eligible_prime),
            "ca":                ca,
            "nb_factures":       nb_f,
            "nb_lignes":         int(r.nb_lignes or 0),
            "panier_moyen":      round(ca / nb_f, 2) if nb_f > 0 else 0.0,
            "nb_factures_chifa": int(r.nb_factures_chifa or 0),
        })

    # Moyenne calculée uniquement sur les éligibles à la prime
    mean_base = [e for e in employes_list if e["eligible_prime"]]
    n = len(mean_base)
    if n > 0:
        mean = {
            "ca":                sum(e["ca"]                for e in mean_base) / n,
            "nb_factures":       sum(e["nb_factures"]       for e in mean_base) / n,
            "nb_lignes":         sum(e["nb_lignes"]         for e in mean_base) / n,
            "panier_moyen":      sum(e["panier_moyen"]      for e in mean_base) / n,
            "nb_factures_chifa": sum(e["nb_factures_chifa"] for e in mean_base) / n,
        }
    else:
        mean = {"ca": 0.0, "nb_factures": 0.0, "nb_lignes": 0.0,
                "panier_moyen": 0.0, "nb_factures_chifa": 0.0}

    return {"employes": employes_list, "mean": mean}
