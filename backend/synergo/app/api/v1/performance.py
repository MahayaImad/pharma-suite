"""
Module Performance — Bénéfice mensuel, KPIs employés, Primes de rendement
"""
from datetime import date as PyDate
from typing import Optional, List
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, func, extract, text, and_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.dialects.postgresql import insert as pg_insert
from pydantic import BaseModel
from loguru import logger

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.ventes import Sortie, SortieProduit
from app.models.achats import Entree, EntreeProduit
from app.models.inventaires import InventaireProduit
from app.models.caisse import Operation
from app.models.performance import Employe, ObjectifMensuel, KpiDefinition, PerformanceMensuelle, PrimeTauxConfig
from app.models.config_tables import Groupware

router = APIRouter(tags=["performance"])

# Utilisateurs exclus des primes (noms dans groupware.utilisateur)
EXCLUS_PRIME = {"VENTE", "amine", "azzedine", "administrateur", "Administrateur"}


# ── Helpers ──────────────────────────────────────────────────────────────────

def _month_filter(model, annee: int, mois: int):
    return and_(
        extract("year", model.date) == annee,
        extract("month", model.date) == mois,
    )


async def _calc_benefice(db: AsyncSession, annee: int, mois: int) -> dict:
    """Calcule le bénéfice net du mois."""

    # 1. SUM(sorties.benefices)
    r1 = await db.execute(
        select(func.coalesce(func.sum(Sortie.benefices), 0))
        .where(_month_filter(Sortie, annee, mois))
    )
    benefices_ventes = r1.scalar() or Decimal(0)

    # 2. Avoirs financiers fournisseurs (type='AVF')
    r2 = await db.execute(
        select(func.coalesce(func.sum(Entree.total_ttc), 0))
        .where(_month_filter(Entree, annee, mois))
        .where(Entree.type == "AVF")
    )
    avoirs_financiers = r2.scalar() or Decimal(0)

    # 3. Remises fournisseurs sur achats normaux
    r3 = await db.execute(
        select(func.coalesce(func.sum(Entree.remise), 0))
        .where(_month_filter(Entree, annee, mois))
        .where(Entree.type != "AVF")
    )
    remises_fourn = r3.scalar() or Decimal(0)

    # 4. Dépenses opérationnelles
    r4 = await db.execute(
        select(func.coalesce(func.sum(Operation.montant), 0))
        .where(_month_filter(Operation, annee, mois))
        .where(func.lower(Operation.operation) == "dépense")
    )
    depenses = r4.scalar() or Decimal(0)

    # 5. Pertes inventaire (motif Péremption) — ecart négatif × prix_achat_ttc
    r5 = await db.execute(
        select(func.coalesce(
            func.sum(func.abs(InventaireProduit.ecart) * InventaireProduit.prix_achat_ttc), 0
        ))
        .where(_month_filter(InventaireProduit, annee, mois))
        .where(InventaireProduit.ecart < 0)
        .where(func.lower(InventaireProduit.motif).contains("p"))  # Péremption
    )
    pertes_peremption = r5.scalar() or Decimal(0)

    # CA ventes (pour affichage)
    r6 = await db.execute(
        select(func.coalesce(func.sum(Sortie.total_a_payer), 0))
        .where(_month_filter(Sortie, annee, mois))
    )
    ca_ventes = r6.scalar() or Decimal(0)

    benefice_net = (
        Decimal(str(benefices_ventes))
        + Decimal(str(avoirs_financiers))
        + Decimal(str(remises_fourn))
        - Decimal(str(depenses))
        - Decimal(str(pertes_peremption))
    )

    return {
        "annee": annee,
        "mois": mois,
        "ca_ventes": float(ca_ventes),
        "benefices_ventes": float(benefices_ventes),
        "avoirs_financiers": float(avoirs_financiers),
        "remises_fournisseurs": float(remises_fourn),
        "depenses": float(depenses),
        "pertes_peremption": float(pertes_peremption),
        "benefice_net": float(benefice_net),
    }


# ── Endpoints Bénéfice ────────────────────────────────────────────────────────

@router.get("/performance/benefice/{annee}/{mois}")
async def get_benefice(
    annee: int,
    mois: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Calcule le bénéfice net d'un mois donné."""
    return await _calc_benefice(db, annee, mois)


@router.get("/performance/benefice/{annee}/{mois}/yoy")
async def get_benefice_yoy(
    annee: int,
    mois: int,
    nb_annees: int = 3,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Comparaison YoY : mois courant vs mêmes mois des années précédentes."""
    results = []
    for y in range(annee, annee - nb_annees - 1, -1):
        b = await _calc_benefice(db, y, mois)
        results.append(b)

    # Calcul du delta N vs N-1
    if len(results) >= 2:
        delta = results[0]["benefice_net"] - results[1]["benefice_net"]
        delta_pct = (delta / results[1]["benefice_net"] * 100) if results[1]["benefice_net"] else 0
    else:
        delta = 0
        delta_pct = 0

    return {
        "comparatif": results,
        "delta_n_vs_n1": round(delta, 2),
        "delta_pct": round(delta_pct, 2),
    }


# ── Endpoints Employés ────────────────────────────────────────────────────────

class EmployeCreate(BaseModel):
    username: str
    nom: str
    prenom: Optional[str] = None
    poste: Optional[str] = None
    date_entree: Optional[PyDate] = None
    eligible_prime: bool = True


class EmployeUpdate(BaseModel):
    nom: Optional[str] = None
    prenom: Optional[str] = None
    poste: Optional[str] = None
    actif: Optional[bool] = None
    eligible_prime: Optional[bool] = None


@router.get("/performance/employes")
async def list_employes(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    res = await db.execute(select(Employe).order_by(Employe.nom))
    return [
        {
            "id": e.id,
            "username": e.username,
            "nom": e.nom,
            "prenom": e.prenom,
            "poste": e.poste,
            "actif": e.actif,
            "eligible_prime": e.eligible_prime,
            "date_entree": e.date_entree.isoformat() if e.date_entree else None,
        }
        for e in res.scalars().all()
    ]


@router.post("/performance/employes", status_code=201)
async def create_employe(
    body: EmployeCreate,
    db: AsyncSession = Depends(get_db),
    current: dict = Depends(get_current_user),
):
    if current.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Réservé aux administrateurs")

    emp = Employe(
        username=body.username,
        nom=body.nom,
        prenom=body.prenom,
        poste=body.poste,
        date_entree=body.date_entree,
        eligible_prime=body.eligible_prime,
    )
    db.add(emp)
    await db.commit()
    await db.refresh(emp)
    return {"id": emp.id, "username": emp.username}


@router.patch("/performance/employes/{employe_id}")
async def update_employe(
    employe_id: int,
    body: EmployeUpdate,
    db: AsyncSession = Depends(get_db),
    current: dict = Depends(get_current_user),
):
    if current.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Réservé aux administrateurs")

    res = await db.execute(select(Employe).where(Employe.id == employe_id))
    emp = res.scalar_one_or_none()
    if not emp:
        raise HTTPException(status_code=404, detail="Employé introuvable")

    if body.nom is not None: emp.nom = body.nom
    if body.prenom is not None: emp.prenom = body.prenom
    if body.poste is not None: emp.poste = body.poste
    if body.actif is not None: emp.actif = body.actif
    if body.eligible_prime is not None: emp.eligible_prime = body.eligible_prime

    await db.commit()
    return {"id": emp.id, "username": emp.username, "eligible_prime": emp.eligible_prime}


@router.post("/performance/employes/sync-groupware", status_code=200)
async def sync_employes_from_groupware(
    db: AsyncSession = Depends(get_db),
    current: dict = Depends(get_current_user),
):
    """Importe automatiquement les employés depuis groupware (exclut EXCLUS_PRIME)."""
    if current.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Réservé aux administrateurs")

    gw_res = await db.execute(select(Groupware))
    rows = gw_res.scalars().all()
    created = 0
    skipped = 0

    for gw in rows:
        if not gw.utilisateur:
            continue
        eligible = gw.utilisateur not in EXCLUS_PRIME
        stmt = pg_insert(Employe.__table__).values(
            username=gw.utilisateur,
            nom=gw.nom or gw.utilisateur,
            prenom=gw.prenom,
            actif=(gw.actif == 1) if gw.actif is not None else True,
            eligible_prime=eligible,
        ).on_conflict_do_update(
            index_elements=["username"],
            set_={
                "nom": pg_insert(Employe.__table__).excluded.nom,
                "prenom": pg_insert(Employe.__table__).excluded.prenom,
                "actif": pg_insert(Employe.__table__).excluded.actif,
            },
        )
        await db.execute(stmt)
        created += 1

    await db.commit()
    logger.info(f"[sync-employes] {created} employés synchronisés depuis groupware")
    return {"synced": created, "skipped": skipped}


# ── Endpoints Objectifs ───────────────────────────────────────────────────────

class ObjectifPayload(BaseModel):
    mode_prime: str = "yoy"          # 'yoy' ou 'fixe'
    objectif_benefice: Optional[float] = None
    pct_enveloppe_prime: float = 10.0
    notes: Optional[str] = None


@router.get("/performance/objectifs/{annee}/{mois}")
async def get_objectif(
    annee: int,
    mois: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    res = await db.execute(
        select(ObjectifMensuel)
        .where(ObjectifMensuel.annee == annee, ObjectifMensuel.mois == mois)
    )
    obj = res.scalar_one_or_none()
    if not obj:
        return {"annee": annee, "mois": mois, "configured": False}
    return {
        "annee": annee, "mois": mois, "configured": True,
        "mode_prime": obj.mode_prime,
        "objectif_benefice": float(obj.objectif_benefice) if obj.objectif_benefice else None,
        "pct_enveloppe_prime": float(obj.pct_enveloppe_prime),
        "enveloppe_calculee": float(obj.enveloppe_calculee) if obj.enveloppe_calculee else None,
        "notes": obj.notes,
    }


@router.post("/performance/objectifs/{annee}/{mois}")
async def set_objectif(
    annee: int,
    mois: int,
    body: ObjectifPayload,
    db: AsyncSession = Depends(get_db),
    current: dict = Depends(get_current_user),
):
    if current.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Réservé aux administrateurs")

    stmt = pg_insert(ObjectifMensuel.__table__).values(
        annee=annee, mois=mois,
        mode_prime=body.mode_prime,
        objectif_benefice=body.objectif_benefice,
        pct_enveloppe_prime=body.pct_enveloppe_prime,
        notes=body.notes,
    ).on_conflict_do_update(
        index_elements=["annee", "mois"],
        set_={
            "mode_prime": body.mode_prime,
            "objectif_benefice": body.objectif_benefice,
            "pct_enveloppe_prime": body.pct_enveloppe_prime,
            "notes": body.notes,
        },
    )
    await db.execute(stmt)
    await db.commit()
    return {"annee": annee, "mois": mois, "saved": True}


# ── Endpoints KPIs ────────────────────────────────────────────────────────────

class KpiDefinitionCreate(BaseModel):
    code: str
    libelle: str
    categorie: Optional[str] = None
    unite: Optional[str] = None
    description: Optional[str] = None
    poids: float = 0


class KpiDefinitionUpdate(BaseModel):
    libelle: Optional[str] = None
    categorie: Optional[str] = None
    unite: Optional[str] = None
    description: Optional[str] = None
    poids: Optional[float] = None
    actif: Optional[bool] = None


@router.get("/performance/kpis/definitions")
async def get_kpi_definitions(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    res = await db.execute(
        select(KpiDefinition).order_by(KpiDefinition.categorie, KpiDefinition.libelle)
    )
    return [
        {
            "id": k.id, "code": k.code, "libelle": k.libelle,
            "categorie": k.categorie, "unite": k.unite,
            "description": k.description,
            "poids": float(k.poids) if k.poids is not None else 0,
            "actif": k.actif,
        }
        for k in res.scalars().all()
    ]


@router.post("/performance/kpis/definitions", status_code=201)
async def create_kpi_definition(
    body: KpiDefinitionCreate,
    db: AsyncSession = Depends(get_db),
    current: dict = Depends(get_current_user),
):
    if current.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Réservé aux administrateurs")
    kpi = KpiDefinition(
        code=body.code, libelle=body.libelle, categorie=body.categorie,
        unite=body.unite, description=body.description, poids=body.poids,
    )
    db.add(kpi)
    await db.commit()
    await db.refresh(kpi)
    return {"id": kpi.id, "code": kpi.code}


@router.patch("/performance/kpis/definitions/{kpi_id}")
async def update_kpi_definition(
    kpi_id: int,
    body: KpiDefinitionUpdate,
    db: AsyncSession = Depends(get_db),
    current: dict = Depends(get_current_user),
):
    if current.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Réservé aux administrateurs")
    res = await db.execute(select(KpiDefinition).where(KpiDefinition.id == kpi_id))
    kpi = res.scalar_one_or_none()
    if not kpi:
        raise HTTPException(status_code=404, detail="KPI introuvable")
    if body.libelle is not None: kpi.libelle = body.libelle
    if body.categorie is not None: kpi.categorie = body.categorie
    if body.unite is not None: kpi.unite = body.unite
    if body.description is not None: kpi.description = body.description
    if body.poids is not None: kpi.poids = body.poids
    if body.actif is not None: kpi.actif = body.actif
    await db.commit()
    return {"id": kpi.id, "code": kpi.code, "poids": float(kpi.poids or 0)}


async def _calc_kpis_employe(db: AsyncSession, username: str, annee: int, mois: int) -> dict:
    """Calcule tous les KPIs réels d'un employé pour un mois. Retourne {code: valeur}."""
    kpis: dict = {}

    r = await db.execute(
        select(func.count(Sortie.id))
        .where(_month_filter(Sortie, annee, mois))
        .where(Sortie.utilisateur == username)
    )
    nb_ventes = r.scalar() or 0

    r = await db.execute(
        select(func.coalesce(func.sum(Sortie.total_a_payer), 0))
        .where(_month_filter(Sortie, annee, mois))
        .where(Sortie.utilisateur == username)
    )
    ca_realise = float(r.scalar() or 0)

    r = await db.execute(
        select(func.count(SortieProduit.id))
        .join(Sortie, SortieProduit.id_sortie == Sortie.id)
        .where(_month_filter(Sortie, annee, mois))
        .where(Sortie.utilisateur == username)
    )
    nb_lignes = r.scalar() or 0

    r = await db.execute(
        select(func.coalesce(func.sum(Sortie.benefices), 0))
        .where(_month_filter(Sortie, annee, mois))
        .where(Sortie.utilisateur == username)
    )
    benefice_brut = round(float(r.scalar() or 0), 2)

    panier_moyen = round(ca_realise / nb_ventes, 2) if nb_ventes else 0
    kpis["nb_ventes"]     = nb_ventes
    kpis["ca_realise"]    = round(ca_realise, 2)
    kpis["nb_lignes"]     = nb_lignes
    kpis["panier_moyen"]  = panier_moyen
    kpis["benefice_brut"] = benefice_brut

    r = await db.execute(
        select(func.coalesce(func.sum(SortieProduit.prix_vente * SortieProduit.qte_sortie), 0))
        .join(Sortie, SortieProduit.id_sortie == Sortie.id)
        .where(_month_filter(Sortie, annee, mois))
        .where(Sortie.utilisateur == username)
        .where(func.lower(SortieProduit.famille).contains("compl"))
    )
    kpis["ca_complement_alim"] = round(float(r.scalar() or 0), 2)

    for days_limit, code in [(90, "ventes_peremption_3"), (180, "ventes_peremption_6"), (270, "ventes_peremption_9")]:
        r = await db.execute(text("""
            SELECT COALESCE(SUM(sp.qte_sortie), 0)
            FROM sorties_produits sp
            JOIN sorties s ON sp.id_sortie = s.id
            WHERE EXTRACT(YEAR  FROM s.date) = :annee
              AND EXTRACT(MONTH FROM s.date) = :mois
              AND s.utilisateur = :username
              AND sp.peremption IS NOT NULL
              AND sp.peremption ~ '^[0-9]{2}/[0-9]{2}$'
              AND (to_date('01/' || sp.peremption, 'DD/MM/YY') - s.date)
                  BETWEEN 0 AND :days_limit
        """), {"annee": annee, "mois": mois, "username": username, "days_limit": days_limit})
        kpis[code] = int(r.scalar() or 0)

    rec = await db.execute(text("""
        SELECT
            COALESCE(SUM(
                GREATEST(s.total_a_payer - s.versement - COALESCE(s.reglement_ult, 0), 0)
            ), 0) AS creances_generees,
            COUNT(DISTINCT s.id_client) FILTER (
                WHERE GREATEST(s.total_a_payer - s.versement
                               - COALESCE(s.reglement_ult, 0), 0) > 0
            ) AS nb_clients_credit
        FROM sorties s
        WHERE EXTRACT(YEAR  FROM s.date) = :annee
          AND EXTRACT(MONTH FROM s.date) = :mois
          AND s.utilisateur = :username
          AND s.id_client NOT IN (1, 2, 3)
          AND s.type != 'RET'
          AND s.versement < s.total_a_payer
    """), {"annee": annee, "mois": mois, "username": username})
    rec_row = rec.mappings().first()

    enc = await db.execute(text("""
        SELECT COALESCE(SUM(o.montant), 0) AS encaissements
        FROM operations o
        WHERE EXTRACT(YEAR  FROM o.date) = :annee
          AND EXTRACT(MONTH FROM o.date) = :mois
          AND o.utilisateur = :username
          AND o.operation ILIKE '%versement%client%'
    """), {"annee": annee, "mois": mois, "username": username})
    enc_row = enc.mappings().first()

    creances = float(rec_row["creances_generees"] or 0)
    encaissements = float(enc_row["encaissements"] or 0)
    kpis["creances_generees"]  = round(creances, 2)
    kpis["encaissements_mois"] = round(encaissements, 2)
    kpis["taux_recouvrement"]  = round(encaissements / creances * 100, 1) if creances > 0 else 0
    kpis["nb_clients_credit"]  = int(rec_row["nb_clients_credit"] or 0)

    impayees = await db.execute(text("""
        SELECT
            COUNT(*)                                   AS nb_creances_impayees_30j,
            COALESCE(SUM(
                s.total_a_payer - s.versement - COALESCE(r.tranches_payees, 0)
            ), 0)                                      AS montant_creances_impayees_30j
        FROM sorties s
        LEFT JOIN (
            SELECT id_vente, SUM(tranche) AS tranches_payees
            FROM reg_client_association
            GROUP BY id_vente
        ) r ON r.id_vente = s.id
        WHERE s.utilisateur    = :username
          AND s.id_client NOT IN (1, 2, 3)
          AND s.type           != 'RET'
          AND (CURRENT_DATE - s.date) > 30
          AND (s.total_a_payer - s.versement - COALESCE(r.tranches_payees, 0)) > 0
    """), {"username": username})
    imp_row = impayees.mappings().first()
    kpis["nb_creances_impayees_30j"]      = int(imp_row["nb_creances_impayees_30j"] or 0)
    kpis["montant_creances_impayees_30j"] = round(float(imp_row["montant_creances_impayees_30j"] or 0), 2)

    inst = await db.execute(text("""
        SELECT
            COUNT(*)                                       AS nb_instances_30j,
            COALESCE(SUM(i.prix_vente * i.qte_sortie), 0) AS montant_instances_30j
        FROM instance_produits i
        WHERE i.utilisateur = :username
          AND i.archive     = FALSE
          AND (CURRENT_DATE - i.date) > 30
    """), {"username": username})
    inst_row = inst.mappings().first()
    kpis["nb_instances_30j"]      = int(inst_row["nb_instances_30j"] or 0)
    kpis["montant_instances_30j"] = round(float(inst_row["montant_instances_30j"] or 0), 2)

    crm = await db.execute(text("""
        WITH first_mois AS (
            SELECT DISTINCT ON (id_client) id_client, date
            FROM sorties
            WHERE type != 'A'
              AND EXTRACT(YEAR  FROM date) = :annee
              AND EXTRACT(MONTH FROM date) = :mois
              AND utilisateur = :username
            ORDER BY id_client, date ASC
        ),
        last_before AS (
            SELECT DISTINCT ON (id_client) id_client, date AS last_date
            FROM sorties
            WHERE type != 'A'
              AND (EXTRACT(YEAR FROM date) < :annee
                   OR (EXTRACT(YEAR FROM date) = :annee
                       AND EXTRACT(MONTH FROM date) < :mois))
            ORDER BY id_client, date DESC
        )
        SELECT
            (SELECT COUNT(*) FROM first_mois fm
             WHERE NOT EXISTS (
                 SELECT 1 FROM last_before lb WHERE lb.id_client = fm.id_client
             )) AS nouveaux_clients,
            (SELECT COUNT(*) FROM first_mois fm
             JOIN last_before lb ON lb.id_client = fm.id_client
             WHERE fm.date - lb.last_date > 180
            ) AS clients_recuperes
    """), {"annee": annee, "mois": mois, "username": username})
    crm_row = crm.mappings().first()
    kpis["nouveaux_clients"]  = int(crm_row["nouveaux_clients"] or 0)
    kpis["clients_recuperes"] = int(crm_row["clients_recuperes"] or 0)

    perem = await db.execute(text("""
        WITH perem AS (
            SELECT
                (sp.prix_vente * sp.qte_sortie)                        AS valeur,
                (to_date('01/' || sp.peremption, 'DD/MM/YY') - s.date) AS jours
            FROM sorties_produits sp
            JOIN sorties s ON sp.id_sortie = s.id
            WHERE EXTRACT(YEAR  FROM s.date) = :annee
              AND EXTRACT(MONTH FROM s.date) = :mois
              AND s.utilisateur = :username
              AND sp.peremption IS NOT NULL
              AND sp.peremption ~ '^[0-9]{2}/[0-9]{2}$'
              AND (to_date('01/' || sp.peremption, 'DD/MM/YY') - s.date) BETWEEN 0 AND 270
        )
        SELECT ROUND((
            COALESCE(SUM(CASE WHEN jours BETWEEN   0 AND  90 THEN valeur * 3 ELSE 0 END), 0)
          + COALESCE(SUM(CASE WHEN jours BETWEEN  91 AND 180 THEN valeur * 2 ELSE 0 END), 0)
          + COALESCE(SUM(CASE WHEN jours BETWEEN 181 AND 270 THEN valeur * 1 ELSE 0 END), 0)
        ) / 100) AS score
        FROM perem
    """), {"annee": annee, "mois": mois, "username": username})
    kpis["score_peremption"] = int(perem.scalar() or 0)

    ald = await db.execute(text("""
        WITH first_mois AS (
            SELECT DISTINCT ON (id_client) id_client, date
            FROM sorties
            WHERE type != 'A'
              AND EXTRACT(YEAR  FROM date) = :annee
              AND EXTRACT(MONTH FROM date) = :mois
              AND utilisateur = :username
            ORDER BY id_client, date ASC
        ),
        last_before AS (
            SELECT DISTINCT ON (id_client) id_client, date AS last_date
            FROM sorties
            WHERE type != 'A'
              AND (EXTRACT(YEAR FROM date) < :annee
                   OR (EXTRACT(YEAR FROM date) = :annee
                       AND EXTRACT(MONTH FROM date) < :mois))
            ORDER BY id_client, date DESC
        ),
        crm_clients AS (
            SELECT id_client FROM first_mois fm
            WHERE NOT EXISTS (SELECT 1 FROM last_before lb WHERE lb.id_client = fm.id_client)
            UNION
            SELECT fm.id_client FROM first_mois fm
            JOIN last_before lb ON lb.id_client = fm.id_client
            WHERE fm.date - lb.last_date > 180
        ),
        client_points AS (
            SELECT cc.id_client,
                COALESCE(MAX(CASE
                    WHEN mc.specialite ILIKE '%interferon%'                     THEN 10
                    WHEN mc.specialite ILIKE '%insul%'
                      OR mc.specialite ILIKE '%diabet%'                         THEN  5
                    WHEN mc.specialite ILIKE '%cardio%'
                      OR mc.specialite ILIKE '%psychiatr%'                      THEN  3
                    WHEN mc.specialite IS NOT NULL AND mc.specialite != ''      THEN  1
                    ELSE 0
                END), 0) AS pts
            FROM crm_clients cc
            JOIN clients c ON c.id = cc.id_client
            LEFT JOIN patients_chifa p ON p.no_assure = c.n_assure_chifa AND p.rang_ad = '00'
            LEFT JOIN LATERAL (SELECT UNNEST(p.maladies) AS code) m ON p.maladies IS NOT NULL
            LEFT JOIN maladies_chroniques mc ON mc.code = m.code
            GROUP BY cc.id_client
        )
        SELECT COALESCE(SUM(pts), 0) AS score FROM client_points
    """), {"annee": annee, "mois": mois, "username": username})
    kpis["score_crm_ald"] = int(ald.scalar() or 0)

    return kpis


_BASE_CA_SQL = """
    SELECT COALESCE(SUM(sp.qte_sortie * sp.prix_vente), 0) AS ca
    FROM sorties_produits sp
    JOIN sorties s ON sp.id_sortie = s.id
    LEFT JOIN nomenclature n ON n.id = sp.id_nom
    WHERE EXTRACT(YEAR  FROM s.date) = :annee
      AND EXTRACT(MONTH FROM s.date) = :mois
      AND s.type != 'A'
"""


async def _calc_enveloppe_prime(db: AsyncSession, annee: int, mois: int) -> float:
    """
    Enveloppe = Σ (CA par catégorie × taux%) sur les catégories actives.

    filtre_famille values:
      NULL                  → tous les produits
      'gentype:princeps'    → nomenclature.generique = 0
      'gentype:generique'   → nomenclature.generique = 1
      'gentype:generique_remb' → generique = 1 AND remb_cvm = 1  (Générique++)
      '%...'                → ILIKE sur sorties_produits.famille (catégorie commerciale)
    """
    configs_res = await db.execute(
        select(PrimeTauxConfig).where(PrimeTauxConfig.actif == True)
    )
    configs = configs_res.scalars().all()
    if not configs:
        return 0.0

    total = Decimal(0)
    for cfg in configs:
        f = cfg.filtre_famille
        params: dict = {"annee": annee, "mois": mois}

        if not f:
            sql = _BASE_CA_SQL
        elif f == "gentype:princeps":
            sql = _BASE_CA_SQL + " AND n.categorie = 'princeps'"
        elif f == "gentype:generique_remb":
            sql = _BASE_CA_SQL + " AND n.categorie = 'generique++'"
        elif f == "gentype:generique":
            sql = _BASE_CA_SQL + " AND n.categorie = 'generique'"
        else:
            sql = _BASE_CA_SQL + " AND sp.famille ILIKE :filtre"
            params["filtre"] = f

        r = await db.execute(text(sql), params)
        ca = Decimal(str(r.scalar() or 0))
        total += ca * Decimal(str(cfg.taux_pct)) / 100

    return float(total)


@router.get("/performance/kpis/{annee}/{mois}/{employe_id}")
async def get_kpis_employe(
    annee: int,
    mois: int,
    employe_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Calcule les KPIs réels d'un employé pour un mois donné."""
    emp_res = await db.execute(select(Employe).where(Employe.id == employe_id))
    emp = emp_res.scalar_one_or_none()
    if not emp:
        raise HTTPException(status_code=404, detail="Employé introuvable")

    raw = await _calc_kpis_employe(db, emp.username, annee, mois)
    return {
        "employe_id": employe_id,
        "username": emp.username,
        "annee": annee,
        "mois": mois,
        "kpis": {code: {"valeur": val} for code, val in raw.items()},
    }


# ── Prime Taux Config CRUD ────────────────────────────────────────────────────

class PrimeTauxConfigCreate(BaseModel):
    nom: str
    taux_pct: float
    filtre_famille: Optional[str] = None
    actif: bool = True


class PrimeTauxConfigUpdate(BaseModel):
    nom: Optional[str] = None
    taux_pct: Optional[float] = None
    filtre_famille: Optional[str] = None
    actif: Optional[bool] = None


@router.get("/performance/prime-config")
async def list_prime_config(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    res = await db.execute(select(PrimeTauxConfig).order_by(PrimeTauxConfig.id))
    return [
        {
            "id": c.id,
            "nom": c.nom,
            "taux_pct": float(c.taux_pct),
            "filtre_famille": c.filtre_famille,
            "actif": c.actif,
        }
        for c in res.scalars().all()
    ]


@router.post("/performance/prime-config", status_code=201)
async def create_prime_config(
    body: PrimeTauxConfigCreate,
    db: AsyncSession = Depends(get_db),
    current: dict = Depends(get_current_user),
):
    if current.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Réservé aux administrateurs")
    cfg = PrimeTauxConfig(
        nom=body.nom,
        taux_pct=body.taux_pct,
        filtre_famille=body.filtre_famille,
        actif=body.actif,
    )
    db.add(cfg)
    await db.commit()
    await db.refresh(cfg)
    return {"id": cfg.id, "nom": cfg.nom}


@router.patch("/performance/prime-config/{config_id}")
async def update_prime_config(
    config_id: int,
    body: PrimeTauxConfigUpdate,
    db: AsyncSession = Depends(get_db),
    current: dict = Depends(get_current_user),
):
    if current.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Réservé aux administrateurs")
    res = await db.execute(select(PrimeTauxConfig).where(PrimeTauxConfig.id == config_id))
    cfg = res.scalar_one_or_none()
    if not cfg:
        raise HTTPException(status_code=404, detail="Configuration introuvable")
    if body.nom is not None: cfg.nom = body.nom
    if body.taux_pct is not None: cfg.taux_pct = body.taux_pct
    if body.filtre_famille is not None: cfg.filtre_famille = body.filtre_famille
    if body.actif is not None: cfg.actif = body.actif
    await db.commit()
    return {"id": cfg.id, "nom": cfg.nom, "taux_pct": float(cfg.taux_pct)}


@router.delete("/performance/prime-config/{config_id}", status_code=204)
async def delete_prime_config(
    config_id: int,
    db: AsyncSession = Depends(get_db),
    current: dict = Depends(get_current_user),
):
    if current.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Réservé aux administrateurs")
    res = await db.execute(select(PrimeTauxConfig).where(PrimeTauxConfig.id == config_id))
    cfg = res.scalar_one_or_none()
    if not cfg:
        raise HTTPException(status_code=404, detail="Configuration introuvable")
    await db.delete(cfg)
    await db.commit()


# ── Calcul et validation des primes ──────────────────────────────────────────

@router.get("/performance/primes/{annee}/{mois}/debug")
async def debug_primes(
    annee: int,
    mois: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Diagnostic sans calcul : vérifie enveloppe, KPIs et employés éligibles."""
    enveloppe = await _calc_enveloppe_prime(db, annee, mois)

    configs_res = await db.execute(select(PrimeTauxConfig).where(PrimeTauxConfig.actif == True))
    configs = [{"nom": c.nom, "taux_pct": float(c.taux_pct), "filtre": c.filtre_famille}
               for c in configs_res.scalars().all()]

    kpis_res = await db.execute(
        select(KpiDefinition).where(KpiDefinition.actif == True, KpiDefinition.poids > 0)
    )
    kpis = [{"code": k.code, "poids": float(k.poids)} for k in kpis_res.scalars().all()]

    emp_res = await db.execute(
        select(Employe).where(Employe.actif == True, Employe.eligible_prime == True)
    )
    employes = [{"id": e.id, "username": e.username} for e in emp_res.scalars().all()]

    # Vérification CA par catégorie
    ca_par_config = []
    for cfg_row in await db.execute(select(PrimeTauxConfig).where(PrimeTauxConfig.actif == True)):
        cfg = cfg_row[0]
        f = cfg.filtre_famille
        params: dict = {"annee": annee, "mois": mois}
        if not f:
            sql = _BASE_CA_SQL
        elif f == "gentype:princeps":
            sql = _BASE_CA_SQL + " AND n.categorie = 'princeps'"
        elif f == "gentype:generique_remb":
            sql = _BASE_CA_SQL + " AND n.categorie = 'generique++'"
        elif f == "gentype:generique":
            sql = _BASE_CA_SQL + " AND n.categorie = 'generique'"
        else:
            sql = _BASE_CA_SQL + " AND sp.famille ILIKE :filtre"
            params["filtre"] = f
        r = await db.execute(text(sql), params)
        ca = float(r.scalar() or 0)
        ca_par_config.append({"nom": cfg.nom, "filtre": f, "ca": ca,
                               "contribution": round(ca * float(cfg.taux_pct) / 100, 2)})

    return {
        "annee": annee, "mois": mois,
        "enveloppe_totale": round(enveloppe, 2),
        "configs_actives": configs,
        "ca_par_config": ca_par_config,
        "nb_kpis_actifs": len(kpis),
        "kpis_actifs": kpis,
        "nb_employes_eligibles": len(employes),
        "employes_eligibles": employes,
        "bloquant": (
            "enveloppe_nulle" if enveloppe <= 0
            else "aucun_kpi" if not kpis
            else "aucun_employe" if not employes
            else None
        ),
    }


@router.post("/performance/primes/{annee}/{mois}/calculer")
async def calculer_primes(
    annee: int,
    mois: int,
    db: AsyncSession = Depends(get_db),
    current: dict = Depends(get_current_user),
):
    """
    Calcule les primes de rendement pour tous les employés éligibles du mois.
    Enveloppe = Σ (CA par catégorie × taux%) depuis prime_taux_config.
    Distribution = relative KPI scoring pondéré par kpi_definitions.poids.
    """
    if current.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Réservé aux administrateurs")

    # 1. Enveloppe basée sur les ventes produits du mois
    enveloppe = Decimal(str(await _calc_enveloppe_prime(db, annee, mois)))
    if enveloppe <= 0:
        raise HTTPException(
            status_code=400,
            detail="Enveloppe nulle : vérifiez les taux configurés dans prime_taux_config et les ventes du mois"
        )

    # 2. KPI definitions actives avec poids > 0
    kpis_def_res = await db.execute(
        select(KpiDefinition)
        .where(KpiDefinition.actif == True, KpiDefinition.poids > 0)
    )
    kpis_defs = kpis_def_res.scalars().all()
    if not kpis_defs:
        raise HTTPException(status_code=400, detail="Aucun KPI actif avec poids > 0")

    kpi_poids = {k.code: float(k.poids) for k in kpis_defs}

    # 3. Employés éligibles
    emp_res = await db.execute(
        select(Employe).where(Employe.actif == True, Employe.eligible_prime == True)
    )
    employes = emp_res.scalars().all()
    if not employes:
        raise HTTPException(status_code=400, detail="Aucun employé éligible trouvé")

    # 4. Calculer les KPIs réels pour chaque employé
    emp_kpis: dict[int, dict] = {}
    for emp in employes:
        emp_kpis[emp.id] = await _calc_kpis_employe(db, emp.username, annee, mois)

    # 5. Pour chaque KPI, calculer le total de l'équipe puis le score relatif de chaque employé
    # score_kpi_i = (valeur_i / total_equipe) * poids  — si total_equipe > 0, sinon 0
    emp_scores: dict[int, float] = {emp.id: 0.0 for emp in employes}

    for code, poids in kpi_poids.items():
        team_total = sum(emp_kpis[emp.id].get(code, 0) for emp in employes)
        if team_total <= 0:
            continue
        for emp in employes:
            val = emp_kpis[emp.id].get(code, 0)
            emp_scores[emp.id] += (val / team_total) * poids

    # 6. Distribuer l'enveloppe proportionnellement aux scores totaux
    total_score = sum(emp_scores.values()) or 1

    # Sauvegarder l'enveloppe dans objectifs_mensuels si l'entrée existe
    await db.execute(
        ObjectifMensuel.__table__.update()
        .where(ObjectifMensuel.annee == annee, ObjectifMensuel.mois == mois)
        .values(enveloppe_calculee=enveloppe)
    )

    results = []
    for emp in employes:
        s = emp_scores.get(emp.id, 0.0)
        pct = (s / total_score * 100) if total_score else 0
        prime = enveloppe * Decimal(str(pct)) / 100

        kpis_data = {
            code: {
                "valeur": emp_kpis[emp.id].get(code, 0),
                "poids": poids,
                "score": round((emp_kpis[emp.id].get(code, 0) /
                                max(sum(emp_kpis[e.id].get(code, 0) for e in employes), 1)) * poids, 3),
            }
            for code, poids in kpi_poids.items()
        }

        stmt = pg_insert(PerformanceMensuelle.__table__).values(
            employe_id=emp.id,
            annee=annee,
            mois=mois,
            kpis=kpis_data,
            score_global=round(s, 4),
            pct_prime=round(pct, 4),
            prime_calculee=prime,
            valide=False,
        ).on_conflict_do_update(
            index_elements=["employe_id", "annee", "mois"],
            set_={
                "kpis": kpis_data,
                "score_global": round(s, 4),
                "pct_prime": round(pct, 4),
                "prime_calculee": prime,
                "valide": False,
            },
        )
        await db.execute(stmt)

        results.append({
            "employe_id": emp.id,
            "username": emp.username,
            "nom": emp.nom,
            "score_global": round(s, 2),
            "pct_prime": round(pct, 2),
            "prime_calculee": float(prime),
        })

    await db.commit()
    logger.info(
        f"[performance] Primes calculées: {annee}/{mois}, "
        f"enveloppe={float(enveloppe):.2f} DA, {len(employes)} employés"
    )

    return {
        "annee": annee,
        "mois": mois,
        "enveloppe_da": float(enveloppe),
        "nb_employes": len(employes),
        "resultats": results,
    }


@router.get("/performance/primes/{annee}/{mois}")
async def get_primes(
    annee: int,
    mois: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Retourne les primes calculées pour un mois."""
    res = await db.execute(
        select(PerformanceMensuelle, Employe)
        .join(Employe, PerformanceMensuelle.employe_id == Employe.id)
        .where(PerformanceMensuelle.annee == annee, PerformanceMensuelle.mois == mois)
        .order_by(PerformanceMensuelle.prime_calculee.desc())
    )
    rows = res.all()

    obj_res = await db.execute(
        select(ObjectifMensuel)
        .where(ObjectifMensuel.annee == annee, ObjectifMensuel.mois == mois)
    )
    obj = obj_res.scalar_one_or_none()

    return {
        "annee": annee,
        "mois": mois,
        "enveloppe_calculee": float(obj.enveloppe_calculee) if obj and obj.enveloppe_calculee else None,
        "primes": [
            {
                "employe_id": pm.id,
                "username": emp.username,
                "nom": emp.nom,
                "prenom": emp.prenom,
                "score_global": float(pm.score_global) if pm.score_global else 0,
                "pct_prime": float(pm.pct_prime) if pm.pct_prime else 0,
                "prime_calculee": float(pm.prime_calculee) if pm.prime_calculee else 0,
                "valide": pm.valide,
            }
            for pm, emp in rows
        ],
    }


@router.post("/performance/primes/{annee}/{mois}/valider")
async def valider_primes(
    annee: int,
    mois: int,
    db: AsyncSession = Depends(get_db),
    current: dict = Depends(get_current_user),
):
    """Valide les primes calculées (verrouille les montants)."""
    if current.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Réservé aux administrateurs")

    from datetime import datetime, timezone
    await db.execute(
        PerformanceMensuelle.__table__.update()
        .where(PerformanceMensuelle.annee == annee, PerformanceMensuelle.mois == mois)
        .values(valide=True, valide_par=current["username"], valide_le=datetime.now(timezone.utc))
    )
    await db.commit()
    return {"annee": annee, "mois": mois, "validated": True}
