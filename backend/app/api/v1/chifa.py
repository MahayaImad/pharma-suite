"""
CHIFA endpoints — Factures & Bordereaux CNAS + Patients chroniques + Contrôle qualité
"""
from typing import Optional, List
from datetime import date, timedelta
from fastapi import APIRouter, Depends, Query, BackgroundTasks
from pydantic import BaseModel as PydanticBaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, desc, text

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.chifa import FactureChifa, BordereauChifa, FactureAnomalie, FactureRejet
from app.models.chroniques import PatientChifa, MaladieChronique

router = APIRouter(prefix="/chifa", tags=["chifa"])


def _f(val) -> float:
    return float(val) if val is not None else 0.0


@router.get("/factures")
async def list_factures(
    no_assure: Optional[str] = Query(None),
    centre: Optional[str] = Query(None),
    no_bordereau: Optional[str] = Query(None),
    date_from: Optional[date] = Query(None),
    date_to: Optional[date] = Query(None),
    annule: Optional[int] = Query(None, ge=0, le=1),
    rej: Optional[int] = Query(None, ge=0, le=1),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Liste paginée des factures CHIFA."""
    conditions = []
    if no_assure:
        conditions.append(FactureChifa.no_assure.ilike(f"%{no_assure}%"))
    if centre:
        conditions.append(FactureChifa.centre.ilike(f"%{centre}%"))
    if no_bordereau:
        conditions.append(FactureChifa.no_bordereau_fact == no_bordereau)
    if date_from:
        conditions.append(FactureChifa.date_fact >= date_from)
    if date_to:
        conditions.append(FactureChifa.date_fact <= date_to)
    if annule is not None:
        conditions.append(FactureChifa.annule == annule)
    if rej is not None:
        conditions.append(FactureChifa.rej == rej)

    where = and_(*conditions) if conditions else True

    total_res = await db.execute(select(func.count(FactureChifa.id)).where(where))
    total = total_res.scalar() or 0

    res = await db.execute(
        select(
            FactureChifa.id, FactureChifa.no_facture,
            FactureChifa.no_assure, FactureChifa.rang_ad,
            FactureChifa.centre, FactureChifa.centre_as,
            FactureChifa.d_soins, FactureChifa.date_fact,
            FactureChifa.no_bordereau_fact,
            FactureChifa.mt_assure, FactureChifa.mt_officine,
            FactureChifa.maj_fact, FactureChifa.mt_maj,
            FactureChifa.annule, FactureChifa.rej,
            FactureChifa.destocke, FactureChifa.code_affect,
        )
        .where(where)
        .order_by(desc(FactureChifa.date_fact), desc(FactureChifa.id))
        .limit(limit)
        .offset(offset)
    )

    items = [
        {
            "id": r.id,
            "no_facture": r.no_facture,
            "no_assure": r.no_assure,
            "rang_ad": r.rang_ad,
            "centre": r.centre,
            "centre_as": r.centre_as,
            "d_soins": r.d_soins.isoformat() if r.d_soins else None,
            "date_fact": r.date_fact.isoformat() if r.date_fact else None,
            "no_bordereau_fact": r.no_bordereau_fact,
            "mt_assure": _f(r.mt_assure),
            "mt_officine": _f(r.mt_officine),
            "maj_fact": _f(r.maj_fact),
            "mt_maj": _f(r.mt_maj),
            "ppa": _f(r.mt_assure) + _f(r.mt_officine),
            "annule": r.annule,
            "rej": r.rej,
            "destocke": r.destocke,
            "code_affect": r.code_affect,
        }
        for r in res.fetchall()
    ]

    return {"total": total, "limit": limit, "offset": offset, "items": items}


@router.get("/bordereaux")
async def list_bordereaux(
    centre: Optional[str] = Query(None),
    statut: Optional[str] = Query(None),
    date_from: Optional[date] = Query(None),
    date_to: Optional[date] = Query(None),
    archive: Optional[int] = Query(None, ge=0, le=1),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Liste paginée des bordereaux CHIFA soumis à la CNAS."""
    conditions = []
    if centre:
        conditions.append(BordereauChifa.centre == centre)
    if statut:
        conditions.append(BordereauChifa.statut == statut)
    if date_from:
        conditions.append(BordereauChifa.dt_creation >= date_from)
    if date_to:
        conditions.append(BordereauChifa.dt_creation <= date_to)
    if archive is not None:
        conditions.append(BordereauChifa.archive == archive)

    where = and_(*conditions) if conditions else True

    total_res = await db.execute(select(func.count(BordereauChifa.id)).where(where))
    total = total_res.scalar() or 0

    res = await db.execute(
        select(
            BordereauChifa.id, BordereauChifa.num_bord,
            BordereauChifa.centre, BordereauChifa.nbr_fact,
            BordereauChifa.mnt_assure, BordereauChifa.mnt_officine,
            BordereauChifa.mnt_fae, BordereauChifa.mnt_majoration,
            BordereauChifa.mnt_rej, BordereauChifa.versement,
            BordereauChifa.dt_creation, BordereauChifa.dt_cloture,
            BordereauChifa.dt_depot, BordereauChifa.dt_validation,
            BordereauChifa.dt_encaisse,
            BordereauChifa.statut, BordereauChifa.archive,
            BordereauChifa.observation,
        )
        .where(where)
        .order_by(desc(BordereauChifa.dt_creation), desc(BordereauChifa.id))
        .limit(limit)
        .offset(offset)
    )

    items = [
        {
            "id": r.id,
            "num_bord": r.num_bord,
            "centre": r.centre,
            "nbr_fact": r.nbr_fact,
            "mnt_assure": _f(r.mnt_assure),
            "mnt_officine": _f(r.mnt_officine),
            "mnt_fae": _f(r.mnt_fae),
            "mnt_majoration": _f(r.mnt_majoration),
            "mnt_rej": _f(r.mnt_rej),
            "versement": _f(r.versement),
            "dt_creation": r.dt_creation.isoformat() if r.dt_creation else None,
            "dt_cloture": r.dt_cloture.isoformat() if r.dt_cloture else None,
            "dt_depot": r.dt_depot.isoformat() if r.dt_depot else None,
            "dt_validation": r.dt_validation.isoformat() if r.dt_validation else None,
            "dt_encaisse": r.dt_encaisse.isoformat() if r.dt_encaisse else None,
            "statut": r.statut,
            "archive": r.archive,
            "observation": r.observation,
        }
        for r in res.fetchall()
    ]

    return {"total": total, "limit": limit, "offset": offset, "items": items}


# ─────────────────────────────────────────────────────────────────────────────
#  PATIENTS CHRONIQUES
# ─────────────────────────────────────────────────────────────────────────────

def _type_beneficiaire(rang_ad: str) -> str:
    if rang_ad == "00":
        return "assure"
    if rang_ad == "80":
        return "conjoint"
    return "enfant"


def _statut(premiere_visite: date, derniere_visite: date, nb_12m: int) -> str:
    """
    Détermine le statut — mêmes définitions que la segmentation CRM :
    - perdu      : dernière visite > 18 mois
    - dormant    : dernière visite entre 6 et 18 mois
    - nouveau    : première visite < 90 jours
    - actif      : ≥ 4 visites dans les 12 derniers mois
    - occasionnel : actif mais < 4 visites / an
    """
    today = date.today()
    jours_abs = (today - derniere_visite).days

    if jours_abs > 540:                               # > 18 mois
        return "perdu"
    if jours_abs > 180:                               # 6 – 18 mois
        return "dormant"
    if (today - premiere_visite).days <= 90:          # < 90 jours
        return "nouveau"
    if nb_12m >= 4:
        return "actif"
    return "occasionnel"


async def _recalcul_patients(db: AsyncSession) -> dict:
    """
    Calcule / recalcule toute la table patients_chifa depuis factures_chifa.

    Algorithme :
      1. Identifier les patients "chroniques" : au moins 2 factures non annulées
         dont au moins un produit appartient à une classe médicamenteuse liée
         à une maladie chronique CNAS.
      2. Pour chaque patient (no_assure, rang_ad) agréger les métriques.
      3. Détecter les maladies via nomenclature → nomenclature_classification →
         classe_maladie → maladies_chroniques.
      4. Upsert dans patients_chifa.
    """

    # ── Requête unique : patients + maladies agrégées en une passe ───────────
    #
    # txt_prod encodé HFSQL : [a[a[ID_CNAS|prix|...|&]}ID_CNAS|...]a]a]
    # On extrait les id_cnas (5 chiffres avec zéros), on joint nomenclature.id_cnas,
    # puis de_equiv (ex: '14A188') → prefix '14 A' → classe_maladie → maladies_chroniques
    #
    sql_patients = text("""
    WITH drug_lines AS (
        -- Extraire chaque médicament depuis la section [a[a[...]a]a] de txt_prod
        -- Format par ligne : id_cnas|prix|qte|O|...|N|duree_trt|...|&]
        -- Position 1 = id_cnas, Position 12 = duree_trt (jours)
        SELECT
            f.no_assure,
            f.rang_ad,
            f.centre,
            f.date_fact,
            f.mt_assure,
            f.mt_officine,
            TRIM(split_part(drug_record, '|', 1))  AS id_cnas,
            TRIM(split_part(drug_record, '|', 12)) AS duree_trt_str
        FROM factures_chifa f,
        LATERAL (
            SELECT unnest(
                string_to_array(
                    substring(f.txt_prod FROM '\\[a\\[a\\[(.*)\\]a\\]a\\]'),
                    '}'
                )
            ) AS drug_record
        ) t
        WHERE f.annule = 0
          AND f.no_assure IS NOT NULL AND f.no_assure != ''
          AND f.txt_prod ~ '\\[a\\[a\\['
          AND TRIM(split_part(drug_record, '|', 1)) ~ '^[0-9]+$'
    ),
    -- Filtrer duree_trt >= 60 jours (condition de chronicité)
    drug_chroniques AS (
        SELECT *
        FROM drug_lines
        WHERE duree_trt_str ~ '^[0-9]+$'
          AND duree_trt_str::integer >= 60
    ),
    -- Joindre nomenclature + classes médicamenteuses + spécialités
    drug_with_classes AS (
        SELECT DISTINCT
            dc.no_assure,
            dc.rang_ad,
            dc.centre,
            dc.date_fact,
            dc.mt_assure,
            dc.mt_officine,
            cm.code_maladie,
            cm.prefix        AS classe,
            mc.specialite,
            n.nom            AS medicament_nom
        FROM drug_chroniques dc
        JOIN nomenclature n
            ON LPAD(n.id_cnas::text, 5, '0') = dc.id_cnas
           AND n.de_equiv IS NOT NULL AND n.de_equiv != ''
        JOIN nomenclature_classification nc
            ON nc.prefix = SUBSTRING(n.de_equiv, 1, 2) || ' ' || SUBSTRING(n.de_equiv, 3, 1)
        JOIN classe_maladie cm ON cm.prefix = nc.prefix
        JOIN maladies_chroniques mc ON mc.code = cm.code_maladie
    ),
    -- Agréger : métriques + maladies + classes + spécialités + médicaments
    patients_retenus AS (
        SELECT
            dwc.no_assure,
            dwc.rang_ad,
            COUNT(DISTINCT dwc.date_fact)           AS nb_visites,
            MIN(dwc.date_fact)                      AS premiere_visite,
            MAX(dwc.date_fact)                      AS derniere_visite,
            MAX(dwc.centre)                         AS centre,
            SUM(dwc.mt_assure)                      AS mt_total_assure,
            SUM(dwc.mt_officine)                    AS mt_total_officine,
            COUNT(DISTINCT CASE WHEN dwc.date_fact >= CURRENT_DATE - INTERVAL '12 months'
                               THEN dwc.date_fact END)    AS nb_12m,
            ARRAY_AGG(DISTINCT dwc.code_maladie)    AS maladies,
            ARRAY_AGG(DISTINCT dwc.classe)          AS classes_medicaments,
            ARRAY_AGG(DISTINCT dwc.specialite)      AS specialites,
            ARRAY_AGG(DISTINCT dwc.medicament_nom)  AS medicaments
        FROM drug_with_classes dwc
        GROUP BY dwc.no_assure, dwc.rang_ad
        HAVING COUNT(DISTINCT dwc.date_fact) >= 2
    )
    SELECT * FROM patients_retenus
    ORDER BY no_assure, rang_ad
    """)

    rows = (await db.execute(sql_patients)).fetchall()

    # ── Vider la table avant de réinsérer (recalcul complet propre) ───────────
    await db.execute(text("TRUNCATE TABLE patients_chifa RESTART IDENTITY"))

    # ── Insérer les patients recalculés ───────────────────────────────────────
    nb_inserts = 0

    for row in rows:
        nb_v = int(row.nb_visites)
        nb_12m = int(row.nb_12m or 0)
        prem = row.premiere_visite
        dern = row.derniere_visite

        intervalle = (
            (dern - prem).days / (nb_v - 1)
            if nb_v >= 2 and prem and dern else None
        )

        prochain = (
            dern + timedelta(days=float(intervalle))
            if intervalle and dern else None
        )

        mt_assure   = float(row.mt_total_assure   or 0)
        mt_officine = float(row.mt_total_officine or 0)
        total_mt    = mt_assure + mt_officine
        taux_remb   = round(mt_officine / total_mt * 100, 2) if total_mt > 0 else None

        statut = _statut(prem, dern, nb_12m)
        type_b = _type_beneficiaire(str(row.rang_ad))

        maladies_list    = sorted(row.maladies or [])
        classes_list     = sorted(row.classes_medicaments or [])
        specialites_list = sorted(row.specialites or [])
        medicaments_list = sorted(row.medicaments or [])

        await db.execute(
            text("""
            INSERT INTO patients_chifa (
                no_assure, rang_ad, type_beneficiaire, centre,
                premiere_visite, derniere_visite, nb_visites,
                intervalle_moyen, prochain_visite_est, statut,
                mt_total_assure, mt_total_officine, taux_remb_moyen,
                maladies, classes_medicaments, specialites, medicaments, calcule_le
            ) VALUES (
                :no_assure, :rang_ad, :tb, :centre,
                :prem, :dern, :nb_v,
                :interv, :prochain, :statut,
                :mt_a, :mt_o, :taux,
                :maladies, :classes, :specialites, :medicaments, NOW()
            )
            """),
            {
                "no_assure": row.no_assure, "rang_ad": row.rang_ad,
                "tb": type_b, "centre": row.centre,
                "prem": prem, "dern": dern, "nb_v": nb_v,
                "interv": intervalle, "prochain": prochain,
                "statut": statut,
                "mt_a": mt_assure, "mt_o": mt_officine, "taux": taux_remb,
                "maladies": maladies_list, "classes": classes_list,
                "specialites": specialites_list, "medicaments": medicaments_list,
            }
        )
        nb_inserts += 1

    await db.commit()
    return {"inserts": nb_inserts, "total": nb_inserts}


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.post("/recalcul-patients", status_code=202)
async def recalcul_patients(
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Déclenche le calcul/recalcul de la table patients_chifa en arrière-plan."""
    async def _run():
        await _recalcul_patients(db)

    background_tasks.add_task(_run)
    return {"message": "Recalcul lancé en arrière-plan"}


@router.get("/patients")
async def list_patients(
    statut:  Optional[str]  = Query(None),
    maladie: Optional[str]  = Query(None),
    type_b:  Optional[str]  = Query(None),
    alerte:  Optional[bool] = Query(None),
    limit:   int            = Query(50, ge=1, le=200),
    offset:  int            = Query(0, ge=0),
    db:      AsyncSession   = Depends(get_db),
    _:       dict           = Depends(get_current_user),
):
    """Liste paginée des patients chroniques identifiés."""
    conditions = []
    if statut:
        conditions.append(PatientChifa.statut == statut)
    if type_b:
        conditions.append(PatientChifa.type_beneficiaire == type_b)
    if maladie:
        conditions.append(PatientChifa.maladies.contains([maladie]))
    if alerte is True:
        conditions.append(
            and_(
                PatientChifa.prochain_visite_est.isnot(None),
                PatientChifa.prochain_visite_est < date.today(),
            )
        )

    where = and_(*conditions) if conditions else True

    total_res = await db.execute(select(func.count(PatientChifa.id)).where(where))
    total = total_res.scalar() or 0

    res = await db.execute(
        select(PatientChifa)
        .where(where)
        .order_by(desc(PatientChifa.derniere_visite))
        .limit(limit)
        .offset(offset)
    )
    rows_p = res.scalars().all()

    def _fmt(p: PatientChifa) -> dict:
        return {
            "id":                  p.id,
            "no_assure":           p.no_assure,
            "rang_ad":             p.rang_ad,
            "type_beneficiaire":   p.type_beneficiaire,
            "centre":              p.centre,
            "premiere_visite":     p.premiere_visite.isoformat() if p.premiere_visite else None,
            "derniere_visite":     p.derniere_visite.isoformat() if p.derniere_visite else None,
            "nb_visites":          p.nb_visites,
            "intervalle_moyen":    float(p.intervalle_moyen) if p.intervalle_moyen else None,
            "prochain_visite_est": p.prochain_visite_est.isoformat() if p.prochain_visite_est else None,
            "statut":              p.statut,
            "mt_total_assure":     float(p.mt_total_assure   or 0),
            "mt_total_officine":   float(p.mt_total_officine or 0),
            "taux_remb_moyen":     float(p.taux_remb_moyen) if p.taux_remb_moyen else None,
            "maladies":            p.maladies or [],
            "classes_medicaments": p.classes_medicaments or [],
            "specialites":         p.specialites or [],
            "medicaments":         p.medicaments or [],
            "calcule_le":          p.calcule_le.isoformat() if p.calcule_le else None,
            "en_alerte":           bool(
                p.prochain_visite_est and p.prochain_visite_est < date.today()
            ),
        }

    return {"total": total, "limit": limit, "offset": offset, "items": [_fmt(p) for p in rows_p]}


@router.get("/stats-cycle-de-vie")
async def stats_cycle_de_vie(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """KPIs cycle de vie : comptages par statut + alertes + maladies fréquentes."""
    sql = text("""
    SELECT
        COUNT(*)                                          AS total,
        COUNT(*) FILTER (WHERE statut = 'nouveau')       AS nouveau,
        COUNT(*) FILTER (WHERE statut = 'actif')         AS actif,
        COUNT(*) FILTER (WHERE statut = 'occasionnel')   AS occasionnel,
        COUNT(*) FILTER (WHERE statut = 'dormant')       AS dormant,
        COUNT(*) FILTER (WHERE statut = 'perdu')         AS perdu,
        COUNT(*) FILTER (
            WHERE prochain_visite_est IS NOT NULL
              AND prochain_visite_est < CURRENT_DATE
              AND statut IN ('actif', 'nouveau', 'occasionnel')
        )                                                 AS en_alerte,
        COUNT(*) FILTER (WHERE 'C022' = ANY(maladies))   AS diabetiques,
        COUNT(*) FILTER (WHERE 'C053' = ANY(maladies))   AS hypertendus,
        COUNT(*) FILTER (WHERE 'C003' = ANY(maladies))   AS cancereux,
        ROUND(AVG(nb_visites), 1)                        AS moy_visites,
        ROUND(AVG(taux_remb_moyen), 1)                   AS moy_taux_remb
    FROM patients_chifa
    """)

    r = (await db.execute(sql)).fetchone()
    if not r:
        return {}

    return {
        "total":         int(r.total or 0),
        "nouveau":       int(r.nouveau or 0),
        "actif":         int(r.actif or 0),
        "occasionnel":   int(r.occasionnel or 0),
        "dormant":       int(r.dormant or 0),
        "perdu":         int(r.perdu or 0),
        "en_alerte":     int(r.en_alerte or 0),
        "diabetiques":   int(r.diabetiques or 0),
        "hypertendus":   int(r.hypertendus or 0),
        "cancereux":     int(r.cancereux or 0),
        "moy_visites":   float(r.moy_visites or 0),
        "moy_taux_remb": float(r.moy_taux_remb or 0),
    }


@router.get("/alertes")
async def alertes_patients(
    limit:  int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db:     AsyncSession = Depends(get_db),
    _:      dict = Depends(get_current_user),
):
    """Patients dont la prochaine visite estimée est dépassée."""
    where = and_(
        PatientChifa.prochain_visite_est.isnot(None),
        PatientChifa.prochain_visite_est < date.today(),
        PatientChifa.statut.in_(["actif", "nouveau", "occasionnel"]),
    )

    total_res = await db.execute(select(func.count(PatientChifa.id)).where(where))
    total = total_res.scalar() or 0

    res = await db.execute(
        select(PatientChifa)
        .where(where)
        .order_by(PatientChifa.prochain_visite_est)
        .limit(limit)
        .offset(offset)
    )
    rows_a = res.scalars().all()

    items = []
    for p in rows_a:
        retard = (date.today() - p.prochain_visite_est).days if p.prochain_visite_est else None
        items.append({
            "id":                  p.id,
            "no_assure":           p.no_assure,
            "rang_ad":             p.rang_ad,
            "type_beneficiaire":   p.type_beneficiaire,
            "derniere_visite":     p.derniere_visite.isoformat() if p.derniere_visite else None,
            "prochain_visite_est": p.prochain_visite_est.isoformat() if p.prochain_visite_est else None,
            "retard_jours":        retard,
            "nb_visites":          p.nb_visites,
            "maladies":            p.maladies or [],
            "statut":              p.statut,
        })

    return {"total": total, "limit": limit, "offset": offset, "items": items}


@router.get("/repartition-maladies")
async def repartition_maladies(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Répartition des patients par maladie chronique détectée."""
    sql = text("""
    SELECT
        mc.code,
        mc.maladie,
        mc.specialite,
        mc.taux_cnas,
        COUNT(p.id) AS nb_patients
    FROM maladies_chroniques mc
    JOIN patients_chifa p ON mc.code = ANY(p.maladies)
    GROUP BY mc.code, mc.maladie, mc.specialite, mc.taux_cnas
    ORDER BY nb_patients DESC
    """)

    rows = (await db.execute(sql)).fetchall()
    return [
        {
            "code":        r.code,
            "maladie":     r.maladie,
            "specialite":  r.specialite,
            "taux_cnas":   r.taux_cnas,
            "nb_patients": int(r.nb_patients),
        }
        for r in rows
    ]


@router.get("/repartition-specialites")
async def repartition_specialites(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Répartition des patients chroniques par spécialité médicale."""
    sql = text("""
    SELECT
        specialite,
        COUNT(DISTINCT p.id) AS nb_patients
    FROM patients_chifa p,
    LATERAL unnest(p.specialites) AS specialite
    WHERE p.specialites IS NOT NULL
    GROUP BY specialite
    ORDER BY nb_patients DESC
    """)

    rows = (await db.execute(sql)).fetchall()
    return [
        {
            "specialite":  r.specialite,
            "nb_patients": int(r.nb_patients),
        }
        for r in rows
    ]

# ── Schémas entrée ─────────────────────────────────────────────────────────────

class AnomalieCreate(PydanticBaseModel):
    no_facture:              str
    no_bordereau:            str | None = None
    type_anomalie:           str = "autre"
    description:             str | None = None
    utilisateur_signalement: str | None = None


class RejetCreate(PydanticBaseModel):
    no_facture:     str
    no_bordereau:   str | None = None
    caisse:         str = "CNAS"
    motif_rejet:    str | None = None
    date_rejet:     date | None = None
    montant_rejete: float | None = None


# ── KPIs contrôle qualité ──────────────────────────────────────────────────────

@router.get("/kpis-controle")
async def kpis_controle(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    a = (await db.execute(text("""
        SELECT
            COUNT(*) FILTER (WHERE statut = 'signalee') AS nb_anomalies_ouvertes,
            COUNT(*) FILTER (WHERE statut = 'corrigee') AS nb_anomalies_corrigees
        FROM facture_anomalies
    """))).fetchone()

    r = (await db.execute(text("""
        SELECT
            COUNT(*) FILTER (WHERE statut = 'rejetee')    AS nb_rejets_ouverts,
            COUNT(*) FILTER (WHERE statut = 'contestee')  AS nb_rejets_contestes
        FROM facture_rejets
    """))).fetchone()

    top_rows = (await db.execute(text("""
        SELECT
            COALESCE(utilisateur_erreur, 'inconnu') AS employe,
            COUNT(*) AS nb_anomalies
        FROM facture_anomalies
        WHERE statut = 'signalee' AND utilisateur_erreur IS NOT NULL
        GROUP BY utilisateur_erreur
        ORDER BY nb_anomalies DESC
        LIMIT 5
    """))).fetchall()

    return {
        "nb_anomalies_ouvertes":  int(a.nb_anomalies_ouvertes  or 0),
        "nb_anomalies_corrigees": int(a.nb_anomalies_corrigees or 0),
        "nb_rejets_ouverts":      int(r.nb_rejets_ouverts      or 0),
        "nb_rejets_contestes":    int(r.nb_rejets_contestes    or 0),
        "top_erreurs_employes": [
            {"employe": row.employe, "nb_anomalies": int(row.nb_anomalies)}
            for row in top_rows
        ],
    }


# ── Anomalies ──────────────────────────────────────────────────────────────────

@router.post("/anomalies", status_code=201)
async def create_anomalie(
    payload: AnomalieCreate,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    employe_erreur = (await db.execute(text("""
        SELECT utilisateur FROM sorties
        WHERE no_facture_chifa = :no_facture AND utilisateur IS NOT NULL
        ORDER BY id DESC LIMIT 1
    """), {"no_facture": payload.no_facture})).scalar()

    anomalie = FactureAnomalie(
        no_facture=payload.no_facture,
        no_bordereau=payload.no_bordereau,
        type_anomalie=payload.type_anomalie,
        description=payload.description,
        utilisateur_signalement=payload.utilisateur_signalement,
        utilisateur_erreur=employe_erreur,
    )
    db.add(anomalie)
    await db.commit()
    await db.refresh(anomalie)
    return {
        "id":                      anomalie.id,
        "no_facture":              anomalie.no_facture,
        "utilisateur_erreur":      anomalie.utilisateur_erreur,
        "utilisateur_signalement": anomalie.utilisateur_signalement,
        "statut":                  anomalie.statut,
    }


@router.get("/anomalies")
async def list_anomalies(
    no_bordereau: str | None = Query(None),
    statut:       str | None = Query(None),
    employe:      str | None = Query(None),
    limit:        int = Query(50, ge=1, le=200),
    offset:       int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    conds = ["1=1"]
    params: dict = {"limit": limit, "offset": offset}
    if no_bordereau:
        conds.append("a.no_bordereau = :no_bordereau"); params["no_bordereau"] = no_bordereau
    if statut:
        conds.append("a.statut = :statut"); params["statut"] = statut
    if employe:
        conds.append("(a.utilisateur_erreur = :employe OR a.utilisateur_signalement = :employe)")
        params["employe"] = employe

    where = " AND ".join(conds)
    rows = (await db.execute(text(f"""
        SELECT * FROM facture_anomalies a
        WHERE {where}
        ORDER BY a.date_signalement DESC
        LIMIT :limit OFFSET :offset
    """), params)).fetchall()
    total = (await db.execute(text(f"SELECT COUNT(*) FROM facture_anomalies a WHERE {where}"), params)).scalar()

    return {
        "total": int(total or 0),
        "items": [
            {
                "id": r.id, "no_facture": r.no_facture, "no_bordereau": r.no_bordereau,
                "type_anomalie": r.type_anomalie, "description": r.description,
                "date_signalement": r.date_signalement.isoformat() if r.date_signalement else None,
                "utilisateur_signalement": r.utilisateur_signalement,
                "utilisateur_erreur": r.utilisateur_erreur, "statut": r.statut,
            }
            for r in rows
        ],
    }


@router.patch("/anomalies/{anomalie_id}/statut")
async def update_anomalie_statut(
    anomalie_id: int,
    statut: str = Query(..., description="signalee | corrigee | annulee"),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    await db.execute(text("UPDATE facture_anomalies SET statut=:statut WHERE id=:id"),
                     {"statut": statut, "id": anomalie_id})
    await db.commit()
    return {"id": anomalie_id, "statut": statut}


# ── Rejets CNAS/CASNOS ────────────────────────────────────────────────────────

@router.post("/rejets", status_code=201)
async def create_rejet(
    payload: RejetCreate,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    from datetime import datetime, timezone
    rejet = FactureRejet(
        no_facture=payload.no_facture,
        no_bordereau=payload.no_bordereau,
        caisse=payload.caisse,
        motif_rejet=payload.motif_rejet,
        date_rejet=(datetime.combine(payload.date_rejet, datetime.min.time()).replace(tzinfo=timezone.utc)
                    if payload.date_rejet else datetime.now(timezone.utc)),
        montant_rejete=payload.montant_rejete,
    )
    db.add(rejet)
    await db.commit()
    await db.refresh(rejet)
    return {
        "id": rejet.id, "no_facture": rejet.no_facture,
        "caisse": rejet.caisse, "statut": rejet.statut,
        "date_rejet": rejet.date_rejet.isoformat() if rejet.date_rejet else None,
    }


@router.get("/rejets")
async def list_rejets(
    no_bordereau: str | None = Query(None),
    caisse:       str | None = Query(None),
    statut:       str | None = Query(None),
    limit:        int = Query(50, ge=1, le=200),
    offset:       int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    conds = ["1=1"]
    params: dict = {"limit": limit, "offset": offset}
    if no_bordereau:
        conds.append("no_bordereau = :no_bordereau"); params["no_bordereau"] = no_bordereau
    if caisse:
        conds.append("caisse = :caisse"); params["caisse"] = caisse
    if statut:
        conds.append("statut = :statut"); params["statut"] = statut

    where = " AND ".join(conds)
    rows = (await db.execute(text(f"""
        SELECT * FROM facture_rejets WHERE {where}
        ORDER BY date_rejet DESC LIMIT :limit OFFSET :offset
    """), params)).fetchall()
    total = (await db.execute(text(f"SELECT COUNT(*) FROM facture_rejets WHERE {where}"), params)).scalar()

    return {
        "total": int(total or 0),
        "items": [
            {
                "id": r.id, "no_facture": r.no_facture, "no_bordereau": r.no_bordereau,
                "caisse": r.caisse, "motif_rejet": r.motif_rejet,
                "date_rejet": r.date_rejet.isoformat() if r.date_rejet else None,
                "montant_rejete": float(r.montant_rejete) if r.montant_rejete else None,
                "statut": r.statut,
            }
            for r in rows
        ],
    }


@router.patch("/rejets/{rejet_id}/statut")
async def update_rejet_statut(
    rejet_id: int,
    statut: str = Query(..., description="rejetee | contestee | acceptee"),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    await db.execute(text("""
        UPDATE facture_rejets SET statut=:statut, date_traitement=NOW() WHERE id=:id
    """), {"statut": statut, "id": rejet_id})
    await db.commit()
    return {"id": rejet_id, "statut": statut}
