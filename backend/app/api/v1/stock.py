"""
Stock endpoints — Nomenclature & Instances produits
Stock réel calculé depuis entrees_produits via mv_stock_produits (vue matérialisée).
"""
from datetime import date as Date, datetime, timedelta, timezone
from decimal import Decimal
from typing import Optional, Literal
from zoneinfo import ZoneInfo
from fastapi import APIRouter, Depends, Query, HTTPException
from pydantic import BaseModel as PydanticBaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, or_, desc, text

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.pharma import Nomenclature, InstanceProduit, Laboratoire
from app.models.stock_responsabilite import NomenclatureClassification
from app.models.performance import Employe
from app.services.stock_segmentation import compute_abc, compute_xyz, update_disponibilite
from app.services import indicateurs_stock as ind
from app.services import indicateurs_stock_lot as ind_lot
from app.services.historique_stock import INVENTAIRE_RESOLU as _INVENTAIRE_RESOLU

router = APIRouter(prefix="/stock", tags=["stock"])

VUE_STOCK = "mv_stock_produits"

# La famille d'un produit se lit par id_famille dans la table familles, qui
# fait foi. nomenclature.famille n'en est qu'une copie texte (voir
# docs/BUSINESS_LOGIC.md §3.5) : elle ne sert que si l'id est inconnu.
_JOINTURE_FAMILLE = "LEFT JOIN familles f ON f.id = n.id_famille"
_NOM_FAMILLE = "COALESCE(f.famille, n.famille)"

# Ordres de tri proposés par la liste : clé publique → SQL fixe (jamais la
# valeur reçue telle quelle dans la requête).
_TRIS = {
    "nom": "n.nom",
    "stock": "COALESCE(mv.stock_actuel, 0) DESC, n.nom",
    "valeur": "COALESCE(mv.valeur_achat, 0) DESC, n.nom",
    "derniere_vente": "mv.derniere_vente DESC NULLS LAST, n.nom",
}

# État de stock d'un produit, tel que l'affichent les écrans : même règle
# que les alertes (une rupture ne concerne qu'un produit actif).
_ETATS = {
    "en_stock": "COALESCE(mv.stock_actuel, 0) > 0",
    "rupture": "COALESCE(mv.stock_actuel, 0) <= 0 AND COALESCE(mv.actif, false)",
    "sous_seuil": ("COALESCE(mv.stock_actuel, 0) > 0 AND n.qte_alerte > 0 "
                   "AND COALESCE(mv.stock_actuel, 0) < n.qte_alerte"),
}
# « À commander » : rupture ou sous le seuil EASYPHARM.
_ETATS["a_commander"] = f"(({_ETATS['rupture']}) OR ({_ETATS['sous_seuil']}))"
# États calculés en Python (indicateurs_stock_lot), pas en SQL.
_ETATS_CALCULES = {"a_risque", "surstock"}

_COLONNES_PRODUIT = f"""
            n.id, n.nom, n.dci, n.dosage, n.forme_abr, n.id_famille,
            {_NOM_FAMILLE} AS famille, n.labo,
            COALESCE(mv.prix_vente, 0) AS prix_vente,
            n.qte_alerte, n.psychotrope, n.conditionnement, n.code_barre_original,
            n.archive, n.segment_abc, n.segment_xyz, n.disponibilite, n.categorie,
            COALESCE(mv.stock_actuel,       0) AS stock,
            COALESCE(mv.prix_moyen_pondere, 0) AS prix_achat_moyen,
            COALESCE(mv.valeur_achat, 0)       AS valeur_achat,
            COALESCE(mv.actif, false)          AS actif,
            mv.derniere_vente
"""


def _item_produit(r, indic: "Optional[ind_lot.Indicateurs]") -> dict:
    """Une ligne de liste : le produit et ses indicateurs de gestion."""
    return {
        "id": r.id, "nom": r.nom, "dci": r.dci, "dosage": r.dosage,
        "forme_abr": r.forme_abr, "id_famille": r.id_famille, "famille": r.famille,
        "labo": r.labo,
        "prix_vente": _f(r.prix_vente), "prix_achat_moyen": _f(r.prix_achat_moyen),
        "valeur_achat": _f(r.valeur_achat), "stock": _f(r.stock),
        "qte_alerte": r.qte_alerte, "psychotrope": r.psychotrope,
        "conditionnement": r.conditionnement, "code_barre_original": r.code_barre_original,
        "archive": r.archive, "segment_abc": r.segment_abc, "segment_xyz": r.segment_xyz,
        "disponibilite": r.disponibilite, "categorie": r.categorie, "actif": r.actif,
        "derniere_vente": r.derniere_vente.isoformat() if r.derniere_vente else None,
        "cmm": round(indic.cmm, 2) if indic else 0,
        "stock_securite": indic.stock_securite if indic else 0,
        "stock_maximum": indic.stock_maximum if indic else 0,
        "couverture_jours": indic.couverture_jours if indic else None,
        "qte_a_risque": indic.qte_a_risque if indic else 0,
        "valeur_a_risque": _f(indic.valeur_a_risque) if indic else 0,
        "qte_surstock": indic.qte_surstock if indic else 0,
        "valeur_surstock": _f(indic.valeur_surstock) if indic else 0,
    }


def _f(val) -> float:
    return float(val) if val is not None else 0.0


# ── Cache ─────────────────────────────────────────────────────────────────────

@router.post("/refresh-cache")
async def refresh_stock_cache(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Rafraîchit la vue matérialisée mv_stock_produits puis met à jour la disponibilité.
    Appelé automatiquement par le sync-agent après chaque cycle de synchronisation.
    CONCURRENT = pas de verrou sur les lectures en cours.
    """
    # La vue est créée vide (WITH NO DATA) : CONCURRENTLY est refusé tant
    # qu'elle n'a pas été calculée une première fois.
    peuplee = (await db.execute(text(
        "SELECT relispopulated FROM pg_class WHERE relname = 'mv_stock_produits'"
    ))).scalar()
    mode = "CONCURRENTLY " if peuplee else ""
    await db.execute(text(f"REFRESH MATERIALIZED VIEW {mode}mv_stock_produits"))
    # PostgreSQL ne garde pas l'heure du dernier REFRESH : on la note dans
    # sync_status, sous le nom de la vue. C'est l'« horodatage des données »
    # affiché par les écrans stock (GET /stock/resume).
    await db.execute(text("""
        INSERT INTO sync_status (table_name, last_id, total_synced, last_sync_at)
        VALUES (:vue, 0, 0, now())
        ON CONFLICT (table_name) DO UPDATE SET last_sync_at = now()
    """), {"vue": VUE_STOCK})
    await db.commit()
    stats = await update_disponibilite(db)
    return {"status": "ok", "disponibilite": stats}


# ── Résumé ───────────────────────────────────────────────────────────────────

@router.get("/resume")
async def resume_stock(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """En-tête des écrans stock : chiffres globaux, familles, horodatage.

    - Les totaux portent sur les produits non archivés.
    - Chaque famille de la table familles est listée, même vide ; les produits
      sans famille connue sont regroupés sous id null.
    - donnees_du : heure du dernier calcul de mv_stock_produits (null si la
      vue n'a jamais été rafraîchie par POST /stock/refresh-cache).
    """
    totaux = (await db.execute(text("""
        SELECT count(*) FILTER (WHERE COALESCE(mv.stock_actuel, 0) > 0) AS en_stock,
               count(*) FILTER (WHERE COALESCE(mv.actif, false))         AS actifs,
               COALESCE(sum(mv.valeur_achat), 0)                         AS valeur_achat,
               COALESCE(sum(mv.valeur_vente), 0)                         AS valeur_vente
        FROM nomenclature n
        LEFT JOIN mv_stock_produits mv ON mv.id_nom = n.id
        WHERE n.archive = false
    """))).one()

    familles = await db.execute(text("""
        WITH par_famille AS (
            SELECT f.id AS id_famille,
                   count(*) FILTER (WHERE COALESCE(mv.actif, false))         AS actifs,
                   count(*) FILTER (WHERE COALESCE(mv.stock_actuel, 0) > 0) AS en_stock
            FROM nomenclature n
            LEFT JOIN familles f ON f.id = n.id_famille
            LEFT JOIN mv_stock_produits mv ON mv.id_nom = n.id
            WHERE n.archive = false
            GROUP BY f.id
        )
        SELECT f.id, f.famille, COALESCE(p.actifs, 0) AS actifs, COALESCE(p.en_stock, 0) AS en_stock
        FROM familles f
        LEFT JOIN par_famille p ON p.id_famille = f.id
        UNION ALL
        SELECT NULL, 'Sans famille', p.actifs, p.en_stock
        FROM par_famille p
        WHERE p.id_famille IS NULL AND p.actifs > 0
        ORDER BY 1 NULLS LAST
    """))

    donnees_du = (await db.execute(text(
        "SELECT last_sync_at FROM sync_status WHERE table_name = :vue"
    ), {"vue": VUE_STOCK})).scalar()

    return {
        "donnees_du": donnees_du.isoformat() if donnees_du else None,
        "produits_actifs": totaux.actifs,
        "produits_en_stock": totaux.en_stock,
        "valeur_achat": _f(totaux.valeur_achat),
        "valeur_vente": _f(totaux.valeur_vente),
        "familles": [
            {"id": r.id, "famille": r.famille, "produits_actifs": r.actifs,
             "produits_en_stock": r.en_stock}
            for r in familles
        ],
    }


# ── Produits ─────────────────────────────────────────────────────────────────

@router.get("/products")
async def list_products(
    q: Optional[str] = Query(None, description="Recherche sur nom, DCI, code-barre"),
    famille: Optional[str] = Query(None, description="Ancien filtre par nom ; préférer id_famille"),
    id_famille: Optional[int] = Query(None, description="Filtrer par famille (familles.id)"),
    etat: Optional[Literal["en_stock", "rupture", "sous_seuil", "a_commander", "a_risque", "surstock"]] = Query(None),
    tri: Literal["nom", "stock", "valeur", "derniere_vente"] = Query("nom"),
    forme: Optional[str] = Query(None),
    in_stock_only: bool = Query(False),
    psychotrope: Optional[int] = Query(None, ge=0, le=1),
    segment_abc: Optional[str] = Query(None, description="Filtrer par segment ABC (A, B ou C)"),
    segment_xyz: Optional[str] = Query(None, description="Filtrer par segment XYZ (X, Y ou Z)"),
    disponibilite: Optional[str] = Query(None, description="Filtrer par disponibilité (oui, rupture, inactif, quota)"),
    categorie: Optional[str] = Query(None, description="Filtrer par catégorie (princeps, generique, generique++)"),
    include_archived: bool = Query(False, description="Inclure les produits archivés"),
    actif: Optional[bool] = Query(
        None, description="true : produits actifs seulement (en stock ou vendus dans les "
                          "12 mois) ; false : inactifs seulement"),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Liste paginée de la nomenclature — stock depuis mv_stock_produits.
    Par défaut, les produits archivés sont exclus (include_archived=false).
    """
    conditions = ["1=1"]
    params: dict = {}

    # Filtre catégorie — utilise n.categorie (champ produit direct)
    cat_join = ""
    if categorie:
        conditions.append("n.categorie = :categorie")
        params["categorie"] = categorie.lower()

    if not include_archived:
        conditions.append("n.archive = false")
    if q:
        conditions.append(
            "(n.nom ILIKE :q OR n.dci ILIKE :q OR n.code_barre_original ILIKE :q)"
        )
        params["q"] = f"%{q}%"
    if famille:
        conditions.append(f"{_NOM_FAMILLE} = :famille")
        params["famille"] = famille
    if id_famille is not None:
        conditions.append("n.id_famille = :id_famille")
        params["id_famille"] = id_famille
    tous = await ind_lot.calculer_tous(db, _aujourdhui_alger())
    if etat in _ETATS_CALCULES:
        consommables = await _consommables(db)
        ids = [i for i, x in tous.items()
               if (x.qte_a_risque if etat == "a_risque" else x.qte_surstock) > 0 and i not in consommables]
        conditions.append("n.id = ANY(:ids_etat)")
        params["ids_etat"] = ids
    elif etat:
        conditions.append(_ETATS[etat])
    if forme:
        conditions.append("n.forme ILIKE :forme")
        params["forme"] = f"%{forme}%"
    if in_stock_only:
        conditions.append("COALESCE(mv.stock_actuel, 0) > 0")
    if psychotrope is not None:
        conditions.append("n.psychotrope = :psychotrope")
        params["psychotrope"] = psychotrope
    if segment_abc:
        conditions.append("n.segment_abc = :segment_abc")
        params["segment_abc"] = segment_abc.upper()
    if segment_xyz:
        conditions.append("n.segment_xyz = :segment_xyz")
        params["segment_xyz"] = segment_xyz.upper()
    if disponibilite:
        conditions.append("n.disponibilite = :disponibilite")
        params["disponibilite"] = disponibilite.lower()
    if actif is not None:
        conditions.append("COALESCE(mv.actif, false) = :actif")
        params["actif"] = actif

    where = " AND ".join(conditions)

    total = (await db.execute(text(f"""
        SELECT COUNT(*)
        FROM nomenclature n
        LEFT JOIN mv_stock_produits mv ON mv.id_nom = n.id
        {_JOINTURE_FAMILLE}
        WHERE {where}
    """), params)).scalar() or 0

    params["limit"] = limit
    params["offset"] = offset
    res = await db.execute(text(f"""
        SELECT {_COLONNES_PRODUIT}
        FROM nomenclature n
        LEFT JOIN mv_stock_produits mv ON mv.id_nom = n.id
        {_JOINTURE_FAMILLE}
        WHERE {where}
        ORDER BY {_TRIS[tri]}
        LIMIT :limit OFFSET :offset
    """), params)
    items = [_item_produit(r, tous.get(r.id)) for r in res.fetchall()]

    return {"total": total, "limit": limit, "offset": offset, "items": items}


async def _produits_par_ids(db: AsyncSession, ids: list[int], tous: dict) -> list[dict]:
    """Lignes de liste des produits [ids], dans cet ordre."""
    if not ids:
        return []
    lignes = {r.id: r for r in await db.execute(text(f"""
        SELECT {_COLONNES_PRODUIT}
        FROM nomenclature n
        LEFT JOIN mv_stock_produits mv ON mv.id_nom = n.id
        {_JOINTURE_FAMILLE}
        WHERE n.id = ANY(:ids)
    """), {"ids": ids})}
    return [_item_produit(lignes[i], tous.get(i)) for i in ids if i in lignes]


@router.get("/a-traiter")
async def a_traiter(
    limite: int = Query(5, ge=1, le=50, description="Produits montrés par groupe"),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Ce qui demande une action, par groupe, les plus importants d'abord.

    - a_commander : ruptures (produit actif à stock nul) et produits sous le
      seuil EASYPHARM ; classe A d'abord, puis la plus forte consommation ;
    - a_risque : lots qui périmeront avant d'être vendus (FEFO) ; plus forte
      valeur à risque d'abord ;
    - surstock : stock au-delà du stock maximum ; plus forte valeur
      excédentaire d'abord.
    """
    tous = await ind_lot.calculer_tous(db, _aujourdhui_alger())
    compte = (await db.execute(text(f"""
        SELECT count(*) FILTER (WHERE {_ETATS['rupture']})    AS ruptures,
               count(*) FILTER (WHERE {_ETATS['sous_seuil']}) AS sous_seuil
        FROM nomenclature n
        LEFT JOIN mv_stock_produits mv ON mv.id_nom = n.id
        WHERE n.archive = false
    """))).one()
    commander = [r.id for r in await db.execute(text(f"""
        SELECT n.id, n.segment_abc
        FROM nomenclature n
        LEFT JOIN mv_stock_produits mv ON mv.id_nom = n.id
        WHERE n.archive = false AND {_ETATS['a_commander']}
    """))]
    ordre_classe = {"A": 0, "B": 1, "C": 2}
    classes = {r.id: r.segment_abc for r in await db.execute(text(
        "SELECT id, segment_abc FROM nomenclature WHERE id = ANY(:ids)"), {"ids": commander})}
    commander.sort(key=lambda i: (ordre_classe.get(classes.get(i) or "", 3),
                                  -(tous[i].cmm if i in tous else 0), i))
    consommables = await _consommables(db)
    risque = sorted((x for x in tous.values() if x.qte_a_risque > 0 and x.id_nom not in consommables),
                    key=lambda x: (-x.valeur_a_risque, x.id_nom))
    surstock = sorted((x for x in tous.values() if x.qte_surstock > 0 and x.id_nom not in consommables),
                      key=lambda x: (-x.valeur_surstock, x.id_nom))
    return {
        "compteurs": {
            "ruptures": compte.ruptures,
            "sous_seuil": compte.sous_seuil,
            "a_commander": len(commander),
            "a_risque": len(risque),
            "valeur_a_risque": _f(sum((x.valeur_a_risque for x in risque), Decimal(0))),
            "surstock": len(surstock),
            "valeur_surstock": _f(sum((x.valeur_surstock for x in surstock), Decimal(0))),
        },
        "a_commander": await _produits_par_ids(db, commander[:limite], tous),
        "a_risque": await _produits_par_ids(db, [x.id_nom for x in risque[:limite]], tous),
        "surstock": await _produits_par_ids(db, [x.id_nom for x in surstock[:limite]], tous),
    }


@router.get("/products/{product_id}")
async def get_product(
    product_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Détail d'un produit — stock depuis mv_stock_produits."""
    res = await db.execute(text("""
        SELECT
            n.id, n.nom, n.dci, n.dosage, n.forme, n.forme_abr,
            n.id_famille, COALESCE(f.famille, n.famille) AS famille, n.labo,
            COALESCE(mv.prix_vente, 0) AS prix_vente,
            n.qte_alerte, n.psychotrope, n.conditionnement,
            n.code_barre_original, n.desactiv_alrt_rup, n.ord_trois_souche,
            n.de_equiv, n.remb_cvm, n.cls_trp,
            COALESCE(mv.stock_actuel,       0) AS stock,
            COALESCE(mv.prix_moyen_pondere, 0) AS prix_achat_moyen,
            COALESCE(mv.actif, false)          AS actif,
            mv.derniere_vente,
            COALESCE(mv.qte_vendue_12m, 0)     AS qte_vendue_12m,
            COALESCE(mv.valeur_achat, 0)       AS valeur_achat,
            COALESCE(mv.valeur_vente, 0)       AS valeur_vente,
            n.segment_abc, n.segment_xyz, n.categorie, n.disponibilite,
            pc.consommable, pc.confirme AS consommable_confirme
        FROM nomenclature n
        LEFT JOIN mv_stock_produits mv ON mv.id_nom = n.id
        LEFT JOIN familles f ON f.id = n.id_famille
        LEFT JOIN produits_consommables pc ON pc.id_nom = n.id
        WHERE n.id = :id
    """), {"id": product_id})
    p = res.fetchone()
    if not p:
        raise HTTPException(status_code=404, detail="Produit introuvable")

    return {
        "id": p.id, "nom": p.nom, "dci": p.dci, "dosage": p.dosage,
        "forme": p.forme, "forme_abr": p.forme_abr,
        "id_famille": p.id_famille, "famille": p.famille,
        "labo": p.labo, "prix_vente": _f(p.prix_vente),
        "prix_achat_moyen": _f(p.prix_achat_moyen),
        "stock": _f(p.stock), "qte_alerte": p.qte_alerte,
        "psychotrope": p.psychotrope, "conditionnement": p.conditionnement,
        "code_barre_original": p.code_barre_original,
        "desactiv_alrt_rup": p.desactiv_alrt_rup,
        "ord_trois_souche": p.ord_trois_souche,
        "de_equiv": p.de_equiv, "remb_cvm": p.remb_cvm,
        "cls_trp": p.cls_trp,
        "actif": p.actif,
        "derniere_vente": p.derniere_vente.isoformat() if p.derniere_vente else None,
        "qte_vendue_12m": int(p.qte_vendue_12m or 0),
        "valeur_achat": _f(p.valeur_achat),
        "valeur_vente": _f(p.valeur_vente),
        "segment_abc": p.segment_abc, "segment_xyz": p.segment_xyz,
        "categorie": p.categorie, "disponibilite": p.disponibilite,
        # Consommable donné (docs/BUSINESS_LOGIC.md §3.4) : décidé par le
        # titulaire, ou proposé par la détection et à confirmer.
        "consommable": bool(p.consommable and p.consommable_confirme),
        "consommable_propose": bool(p.consommable and not p.consommable_confirme),
    }


# ── Indicateurs de gestion d'un produit ───────────────────────────────────────

_ALGER = ZoneInfo("Africa/Algiers")


def _aujourdhui_alger() -> Date:
    return datetime.now(timezone.utc).astimezone(_ALGER).date()


async def _reglages(db: AsyncSession) -> dict[str, Decimal]:
    lignes = await db.execute(text("SELECT cle, valeur FROM reglages_stock"))
    return {r.cle: r.valeur for r in lignes}


# Un ajustement d'inventaire pour péremption (docs/BUSINESS_LOGIC.md §3.4) :
# motif « Péremption » (accent et casse indifférents), écart négatif. Les
# lignes sont rattachées à leur produit par le code-barres du lot.
_EST_PEREMPTION = "ip.motif ILIKE 'p_remption%' AND ip.ecart < 0"


@router.get("/peremption")
async def taux_peremption(
    mois: int = Query(12, ge=1, le=36),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Taux de péremption = valeur des périmés ÷ valeur des achats × 100.

    - Périmés : ajustements d'inventaire au motif « Péremption », écart négatif,
      valorisés au prix d'achat de la ligne d'inventaire (à défaut, prix
      moyen du produit).
    - Achats : entrées hors avoirs et hors échanges reçus ; les unités
      gratuites comptent pour 0.
    Objectif courant : sous 1 à 2 %.
    """
    debut = _aujourdhui_alger().replace(day=1)
    for _i in range(mois - 1):
        debut = (debut - timedelta(days=1)).replace(day=1)
    params = {"debut": debut}
    valeur_perimes = f"""-ip.ecart * COALESCE(NULLIF(ip.prix_achat_ttc, 0), mv.prix_moyen_pondere, 0)"""
    totaux = (await db.execute(text(f"""
        SELECT COALESCE(sum(-ip.ecart), 0) AS unites, COALESCE(sum({valeur_perimes}), 0) AS valeur
        FROM ({_INVENTAIRE_RESOLU}) ip LEFT JOIN mv_stock_produits mv ON mv.id_nom = ip.id_nom
        WHERE ip.date >= :debut AND {_EST_PEREMPTION}
    """), params)).one()
    achats = (await db.execute(text("""
        SELECT COALESCE(sum(qte_entree * prix_achat), 0) FROM entrees_produits
        WHERE date_entree >= :debut AND COALESCE(type_entree, '') <> 'AV' AND COALESCE(type_achat, '') <> 'E'
    """), params)).scalar()
    par_mois = await db.execute(text(f"""
        SELECT date_trunc('month', ip.date)::date AS m, sum(-ip.ecart) AS unites, sum({valeur_perimes}) AS valeur
        FROM ({_INVENTAIRE_RESOLU}) ip LEFT JOIN mv_stock_produits mv ON mv.id_nom = ip.id_nom
        WHERE ip.date >= :debut AND {_EST_PEREMPTION}
        GROUP BY 1 ORDER BY 1
    """), params)
    produits = await db.execute(text(f"""
        SELECT ip.id_nom, n.nom, sum(-ip.ecart) AS unites, sum({valeur_perimes}) AS valeur
        FROM ({_INVENTAIRE_RESOLU}) ip
        LEFT JOIN mv_stock_produits mv ON mv.id_nom = ip.id_nom
        LEFT JOIN nomenclature n ON n.id = ip.id_nom
        WHERE ip.date >= :debut AND {_EST_PEREMPTION}
        GROUP BY 1, 2 ORDER BY 4 DESC, 1 LIMIT 10
    """), params)
    valeur = Decimal(totaux.valeur)
    achats = Decimal(achats)
    return {
        "debut": debut.isoformat(),
        "mois": mois,
        "unites_perimees": int(totaux.unites),
        "valeur_perimee": _f(valeur.quantize(Decimal("0.01"))),
        "valeur_achats": _f(achats.quantize(Decimal("0.01"))),
        "taux_pct": _f((valeur / achats * 100).quantize(Decimal("0.01"))) if achats else None,
        "objectif_pct": 2,
        "par_mois": [{"mois": r.m.isoformat(), "unites": int(r.unites), "valeur": _f(r.valeur)} for r in par_mois],
        "produits": [{"id": r.id_nom, "nom": r.nom, "unites": int(r.unites), "valeur": _f(r.valeur)}
                     for r in produits],
    }


@router.post("/photo-du-jour")
async def photo_du_jour(
    db: AsyncSession = Depends(get_db),
    current: dict = Depends(get_current_user),
):
    """Relève tout de suite le stock du jour dans l'historique (prise aussi
    automatiquement chaque soir à 23 h 50). Administrateur uniquement."""
    if current.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Réservé aux administrateurs")
    from app.services.photo_stock import prendre_photo
    return await prendre_photo(db, _aujourdhui_alger())


@router.get("/reglages")
async def lire_reglages(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Constantes du calcul des indicateurs (table reglages_stock)."""
    lignes = await db.execute(text(
        "SELECT cle, valeur, description, modifie_le, modifie_par FROM reglages_stock ORDER BY cle"))
    return [
        {"cle": r.cle, "valeur": _f(r.valeur), "description": r.description,
         "modifie_le": r.modifie_le.isoformat() if r.modifie_le else None,
         "modifie_par": r.modifie_par}
        for r in lignes
    ]


@router.patch("/reglages")
async def modifier_reglages(
    valeurs: dict[str, Decimal],
    db: AsyncSession = Depends(get_db),
    current: dict = Depends(get_current_user),
):
    """Modifie une ou plusieurs constantes ; administrateur uniquement."""
    if current.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Réglages réservés aux administrateurs")
    connues = await _reglages(db)
    inconnues = sorted(set(valeurs) - set(connues))
    if inconnues:
        raise HTTPException(status_code=422, detail=f"Réglage inconnu : {', '.join(inconnues)}")
    if any(v < 0 for v in valeurs.values()):
        raise HTTPException(status_code=422, detail="Une valeur ne peut pas être négative")
    for cle, valeur in valeurs.items():
        await db.execute(text("""
            UPDATE reglages_stock SET valeur = :v, modifie_le = now(), modifie_par = :qui
            WHERE cle = :c
        """), {"v": valeur, "qui": current.get("username"), "c": cle})
    await db.commit()
    return await lire_reglages(db, current)


@router.get("/products/{product_id}/indicateurs")
async def indicateurs_produit(
    product_id: int,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """CMM, CMJ, délai de livraison, stock de sécurité, stock maximum,
    couverture, et quantité à risque de péremption de chaque lot (FEFO).
    Définitions : docs/05-stock-guide.md, section 5 ; calculs :
    app/services/indicateurs_stock.py.
    """
    produit = (await db.execute(text("""
        SELECT n.id, n.segment_abc, COALESCE(mv.stock_actuel, 0) AS stock
        FROM nomenclature n
        LEFT JOIN mv_stock_produits mv ON mv.id_nom = n.id
        WHERE n.id = :id
    """), {"id": product_id})).fetchone()
    if not produit:
        raise HTTPException(status_code=404, detail="Produit introuvable")

    jour = _aujourdhui_alger()
    debut = jour - timedelta(days=365)
    reglages = await _reglages(db)

    # Ventes nettes par jour sur 12 mois (les retours sont négatifs).
    ventes = (await db.execute(text("""
        SELECT date, SUM(qte_sortie) AS qte
        FROM sorties_produits
        WHERE id_nom = :id AND date > :debut AND date <= :jour
        GROUP BY date
    """), {"id": product_id, "debut": debut, "jour": jour})).fetchall()
    premiere_vente = (await db.execute(text(
        "SELECT MIN(date) FROM sorties_produits WHERE id_nom = :id AND qte_sortie > 0"
    ), {"id": product_id})).scalar()

    ventes_12_mois = float(sum(v.qte or 0 for v in ventes))
    mois = ind.mois_historique(premiere_vente, jour)
    cmm = ind.cmm(ventes_12_mois, mois)
    cmj = ind.cmj(cmm)
    # σ sur la même période que la CMM (jours sans vente comptés à zéro).
    jours_historique = min(365, (jour - premiere_vente).days + 1) if premiere_vente else 365
    sigma = ind.ecart_type_journalier([float(v.qte or 0) for v in ventes], jours_historique)

    # Fournisseur principal : celui du dernier vrai achat, ni avoir ni échange
    # reçu (docs/BUSINESS_LOGIC.md §3.6).
    fournisseur = (await db.execute(text("""
        SELECT ep.id_fournisseur, COALESCE(f.fournisseur, ep.fournisseur) AS nom, f.delai_livraison
        FROM entrees_produits ep
        LEFT JOIN fournisseurs f ON f.id = ep.id_fournisseur
        WHERE ep.id_nom = :id AND COALESCE(ep.type_entree, '') <> 'AV'
          -- Un échange reçu (type_achat 'E', prix 0) n'est pas un achat.
          AND COALESCE(ep.type_achat, '') <> 'E'
        ORDER BY ep.date_entree DESC NULLS LAST, ep.id DESC
        LIMIT 1
    """), {"id": product_id})).fetchone()
    delai_saisi = fournisseur is not None and fournisseur.delai_livraison is not None
    delai_ouvres = int(fournisseur.delai_livraison if delai_saisi
                       else reglages.get("delai_livraison_jours", Decimal(1)))
    delai = ind.delai_livraison(jour, delai_ouvres)

    ss = ind.stock_securite(sigma, delai, produit.segment_abc)
    delai_securite = float(reglages.get("delai_securite_jours", Decimal(2)))
    periode = float(reglages.get("periode_commande_jours", Decimal(7)))
    stock = float(produit.stock)

    lots = (await db.execute(text("""
        SELECT id, stock, peremption_date, prix_achat, bloque
        FROM entrees_produits
        WHERE id_nom = :id AND stock > 0
    """), {"id": product_id})).fetchall()
    risques = ind.risques_fefo(
        [ind.LotFefo(id=l.id, stock=int(l.stock), peremption=l.peremption_date,
                     prix_achat=Decimal(l.prix_achat or 0), bloque=bool(l.bloque)) for l in lots],
        cmj, jour)
    stocks_lots = {l.id: int(l.stock) for l in lots}
    qte_risque = sum(r.a_risque or 0 for r in risques)
    valeur_risque = sum((r.valeur_a_risque or Decimal(0) for r in risques), Decimal(0))
    dvr_connues = [r.dvr for r in risques if r.dvr is not None]
    couverture = ind.couverture_jours(stock, cmj)

    return {
        "date_calcul": jour.isoformat(),
        "ventes_12_mois": ventes_12_mois,
        "mois_historique": mois,
        "cmm": round(cmm, 2),
        "cmj": round(cmj, 3),
        "ecart_type_journalier": round(sigma, 3),
        "fournisseur": None if fournisseur is None else {
            "id": fournisseur.id_fournisseur, "nom": fournisseur.nom,
            "delai_jours_ouvres": delai_ouvres, "delai_saisi": delai_saisi,
        },
        "delai_livraison_jours": delai,
        "date_livraison": ind.date_livraison(jour, delai_ouvres).isoformat(),
        "classe_abc": produit.segment_abc,
        "z": ind.Z_PAR_CLASSE.get((produit.segment_abc or "").upper(), ind.Z_DEFAUT),
        "stock_securite": ss,
        "stock_securite_simple": ind.stock_securite_simple(cmj, delai_securite),
        "delai_securite_jours": delai_securite,
        "periode_commande_jours": periode,
        "stock_maximum": ind.stock_maximum(ss, cmm, periode),
        "stock": stock,
        "couverture_jours": couverture,
        # La couverture doit rester sous la DVR du lot le plus long : au-delà,
        # une partie du stock périmera avant d'être vendue.
        "dvr_max": max(dvr_connues) if dvr_connues else None,
        "qte_a_risque": qte_risque,
        "valeur_a_risque": _f(valeur_risque),
        "lots": [
            {"id": r.id, "stock": stocks_lots.get(r.id, 0), "dvr": r.dvr,
             "ecoulable": r.ecoulable, "a_risque": r.a_risque,
             "valeur_a_risque": None if r.valeur_a_risque is None else _f(r.valeur_a_risque)}
            for r in risques
        ],
    }


class ConsommableDecision(PydanticBaseModel):
    consommable: bool


@router.put("/products/{product_id}/consommable")
async def decider_consommable(
    product_id: int,
    decision: ConsommableDecision,
    db: AsyncSession = Depends(get_db),
    current: dict = Depends(get_current_user),
):
    """Le titulaire déclare (ou non) un produit consommable : donné, jamais
    vendu, sorti du stock par ajustement. La décision est définitive pour la
    détection : un refus n'est plus reproposé."""
    if current.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Réservé au titulaire")
    if not (await db.execute(text("SELECT 1 FROM nomenclature WHERE id = :i"), {"i": product_id})).first():
        raise HTTPException(status_code=404, detail="Produit introuvable")
    await db.execute(text("""
        INSERT INTO produits_consommables (id_nom, consommable, confirme, source, modifie_par)
        VALUES (:i, :c, true, 'saisie', :qui)
        ON CONFLICT (id_nom) DO UPDATE SET consommable = :c, confirme = true,
            modifie_le = now(), modifie_par = :qui
    """), {"i": product_id, "c": decision.consommable, "qui": current.get("username")})
    await db.commit()
    return {"id": product_id, "consommable": decision.consommable}


@router.get("/consommables")
async def lister_consommables(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Consommables confirmés et proposés (à confirmer)."""
    lignes = await db.execute(text("""
        SELECT pc.id_nom, n.nom, pc.consommable, pc.confirme, pc.source
        FROM produits_consommables pc JOIN nomenclature n ON n.id = pc.id_nom
        WHERE pc.consommable ORDER BY pc.confirme, n.nom
    """))
    return [{"id": r.id_nom, "nom": r.nom, "confirme": r.confirme, "source": r.source} for r in lignes]


async def _consommables(db: AsyncSession) -> set[int]:
    """Consommables confirmés : ni surstock ni péremption à risque, puisqu'ils
    ne se vendent pas."""
    return {r.id_nom for r in await db.execute(text(
        "SELECT id_nom FROM produits_consommables WHERE consommable AND confirme"))}


# ── Gestion archive / quota ───────────────────────────────────────────────────

class ProductFlagsUpdate(PydanticBaseModel):
    archive: Optional[bool] = None   # admin uniquement
    quota: Optional[bool] = None     # tout utilisateur connecté


@router.patch("/products/{product_id}/flags")
async def update_product_flags(
    product_id: int,
    body: ProductFlagsUpdate,
    db: AsyncSession = Depends(get_db),
    current: dict = Depends(get_current_user),
):
    """
    Modifie les flags manuels d'un produit :
    - archive : admin uniquement — retire le produit de tous les écrans stock
    - quota   : tout utilisateur — marque que le produit est soumis à quota fournisseur ;
                le système réinitialise automatiquement à 'oui' si stock > qte_alerte
    """
    res = await db.execute(select(Nomenclature).where(Nomenclature.id == product_id))
    produit = res.scalar_one_or_none()
    if not produit:
        raise HTTPException(status_code=404, detail="Produit introuvable")

    if body.archive is not None:
        if current.get("role") != "admin":
            raise HTTPException(status_code=403, detail="Archivage réservé aux administrateurs")
        produit.archive = body.archive

    if body.quota is not None:
        if body.quota:
            produit.disponibilite = 'quota'
        else:
            # Remise en état selon le stock actuel
            stock_res = await db.execute(text(
                "SELECT COALESCE(stock_actuel, 0) FROM mv_stock_produits WHERE id_nom = :id"
            ), {"id": product_id})
            stock_row = stock_res.fetchone()
            stock = float(stock_row[0]) if stock_row else 0.0
            produit.disponibilite = 'oui' if stock > 0 else 'rupture'

    await db.commit()
    return {
        "id": produit.id,
        "archive": produit.archive,
        "disponibilite": produit.disponibilite,
        "segment_abc": produit.segment_abc,
        "segment_xyz": produit.segment_xyz,
    }


# ── Segmentation manuelle ─────────────────────────────────────────────────────

@router.post("/segmentation/run")
async def run_segmentation(
    db: AsyncSession = Depends(get_db),
    current: dict = Depends(get_current_user),
):
    """
    Déclenche manuellement le calcul ABC/XYZ (normalement automatique le 1er du mois).
    Réservé aux administrateurs.
    """
    if current.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Réservé aux administrateurs")

    abc_updated = await compute_abc(db)
    xyz_updated = await compute_xyz(db)
    return {
        "status": "ok",
        "abc_updated": abc_updated,
        "xyz_updated": xyz_updated,
    }


# ── Instances (lots / péremptions) ────────────────────────────────────────────

@router.get("/instances")
async def list_instances(
    id_nom: Optional[int] = Query(None, description="Filtrer par produit"),
    lot: Optional[str] = Query(None),
    expiry_before: Optional[str] = Query(None, description="Péremption MM/YYYY — filtre les lots qui expirent avant cette date"),
    utilisateur: Optional[str] = Query(None),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Liste des instances produits (lots avec dates de péremption)."""
    conditions = [InstanceProduit.qte_sortie > 0]
    if id_nom:
        conditions.append(InstanceProduit.id_nom == id_nom)
    if lot:
        conditions.append(InstanceProduit.lot.ilike(f"%{lot}%"))
    if utilisateur:
        conditions.append(InstanceProduit.utilisateur == utilisateur)

    where = and_(*conditions)

    total_res = await db.execute(select(func.count(InstanceProduit.id)).where(where))
    total = total_res.scalar() or 0

    res = await db.execute(
        select(
            InstanceProduit.id,
            InstanceProduit.id_nom,
            InstanceProduit.nom,
            InstanceProduit.famille,
            InstanceProduit.lot,
            InstanceProduit.peremption,
            InstanceProduit.echeance,
            InstanceProduit.qte_sortie,
            InstanceProduit.prix_vente,
            InstanceProduit.prix_achat_ttc,
            InstanceProduit.psychotrope,
            InstanceProduit.utilisateur,
        )
        .where(where)
        .order_by(InstanceProduit.echeance)
        .limit(limit)
        .offset(offset)
    )

    items = [
        {
            "id": r.id,
            "id_nom": r.id_nom,
            "nom": r.nom,
            "famille": r.famille,
            "lot": r.lot,
            "peremption": r.peremption,
            "echeance": r.echeance.isoformat() if r.echeance else None,
            "qte_sortie": r.qte_sortie,
            "prix_vente": _f(r.prix_vente),
            "prix_achat_ttc": _f(r.prix_achat_ttc),
            "psychotrope": r.psychotrope,
            "utilisateur": r.utilisateur,
        }
        for r in res.fetchall()
    ]

    return {"total": total, "limit": limit, "offset": offset, "items": items}


# ── Alertes ───────────────────────────────────────────────────────────────────

@router.get("/alerts")
async def stock_alerts(
    alert_type: str = Query("all", enum=["rupture", "alerte", "all"]),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Produits en rupture ou sous le seuil d'alerte — stock depuis mv_stock_produits."""
    # Une rupture ne concerne qu'un produit actif : sans ce filtre, tout le
    # catalogue jamais ou plus vendu ressort « en rupture ».
    if alert_type == "rupture":
        where = ("COALESCE(mv.stock_actuel, 0) <= 0 AND COALESCE(mv.actif, false) "
                 "AND n.desactiv_alrt_rup = 0")
    elif alert_type == "alerte":
        where = (
            "COALESCE(mv.stock_actuel, 0) > 0 "
            "AND n.qte_alerte > 0 "
            "AND COALESCE(mv.stock_actuel, 0) < n.qte_alerte "
            "AND n.desactiv_alrt_rup = 0"
        )
    else:
        where = (
            "((COALESCE(mv.stock_actuel, 0) <= 0 AND COALESCE(mv.actif, false)) "
            " OR (n.qte_alerte > 0 AND COALESCE(mv.stock_actuel, 0) > 0 "
            "     AND COALESCE(mv.stock_actuel, 0) < n.qte_alerte)) "
            "AND n.desactiv_alrt_rup = 0"
        )

    params = {"limit": limit, "offset": offset}

    total = (await db.execute(text(f"""
        SELECT COUNT(*)
        FROM nomenclature n
        LEFT JOIN mv_stock_produits mv ON mv.id_nom = n.id
        WHERE {where}
    """), params)).scalar() or 0

    res = await db.execute(text(f"""
        SELECT
            n.id, n.nom, n.dci, n.forme_abr, n.famille,
            n.qte_alerte,
            COALESCE(mv.stock_actuel, 0) AS stock
        FROM nomenclature n
        LEFT JOIN mv_stock_produits mv ON mv.id_nom = n.id
        WHERE {where}
        ORDER BY COALESCE(mv.stock_actuel, 0)
        LIMIT :limit OFFSET :offset
    """), params)

    items = []
    for r in res.fetchall():
        stock = _f(r.stock)
        items.append({
            "id": r.id,
            "nom": r.nom,
            "dci": r.dci,
            "forme_abr": r.forme_abr,
            "famille": r.famille,
            "stock": stock,
            "qte_alerte": r.qte_alerte,
            "alert_level": "rupture" if stock <= 0 else "alerte",
        })

    return {"total": total, "limit": limit, "offset": offset, "items": items}


# ── Listes de référence ───────────────────────────────────────────────────────

@router.get("/familles")
async def list_familles(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Liste des familles de produits (pour les filtres dropdowns)."""
    from app.models.pharma import Famille
    res = await db.execute(select(Famille).order_by(Famille.famille))
    return [{"id": r.id, "famille": r.famille} for r in res.scalars().all()]


@router.get("/formes")
async def list_formes(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Liste des formes pharmaceutiques (pour les filtres dropdowns)."""
    from app.models.pharma import Forme
    res = await db.execute(select(Forme).order_by(Forme.forme))
    return [{"id": r.id, "forme": r.forme, "forme_abr": r.forme_abr} for r in res.scalars().all()]


# ── Classifications Nomenclature ──────────────────────────────────────────────

class ClassificationUpdate(PydanticBaseModel):
    designation: Optional[str] = None
    etagere: Optional[str] = None
    employe_id: Optional[int] = None
    categorie: Optional[str] = None  # princeps | generique | generique++ | None (clear)


@router.get("/classifications")
async def list_classifications(
    employe_id: Optional[int] = Query(None),
    etagere: Optional[str] = Query(None),
    q: Optional[str] = Query(None, description="Recherche prefix ou désignation"),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Liste toutes les classifications — valeur stock depuis mv_stock_produits."""
    stmt = """
        SELECT
            nc.id,
            nc.prefix,
            nc.niveau,
            nc.designation,
            nc.etagere,
            nc.categorie,
            nc.employe_id,
            e.nom    AS employe_nom,
            e.prenom AS employe_prenom,
            -- Employé hérité depuis la classe parente (niveau 1) si sous-classe sans responsable
            parent.employe_id  AS parent_employe_id,
            ep.nom             AS parent_employe_nom,
            ep.prenom          AS parent_employe_prenom,
            COUNT(DISTINCT n.id)                                  AS nb_produits,
            COALESCE(SUM(mv.valeur_vente), 0)      AS valeur_stock
        FROM nomenclature_classification nc
        LEFT JOIN employes e ON e.id = nc.employe_id
        -- Classe parente : même 2 premiers caractères, niveau 1
        LEFT JOIN nomenclature_classification parent
               ON nc.niveau = 2
              AND parent.niveau = 1
              AND LEFT(nc.prefix, 2) = parent.prefix
        LEFT JOIN employes ep ON ep.id = parent.employe_id
        LEFT JOIN nomenclature n ON (
            (nc.niveau = 2 AND LEFT(n.de_equiv, 2) || ' ' || SUBSTR(n.de_equiv, 3, 1) = nc.prefix)
            OR
            (nc.niveau = 1 AND LEFT(n.de_equiv, 2) = nc.prefix)
        )
        LEFT JOIN mv_stock_produits mv ON mv.id_nom = n.id
        WHERE 1=1
    """
    params: dict = {}
    if employe_id is not None:
        stmt += " AND nc.employe_id = :employe_id"
        params["employe_id"] = employe_id
    if etagere:
        stmt += " AND nc.etagere = :etagere"
        params["etagere"] = etagere
    if q:
        stmt += " AND (nc.prefix ILIKE :q OR nc.designation ILIKE :q)"
        params["q"] = f"%{q}%"
    stmt += (
        " GROUP BY nc.id, nc.prefix, nc.niveau, nc.designation, nc.etagere, nc.categorie,"
        " nc.employe_id, e.nom, e.prenom,"
        " parent.employe_id, ep.nom, ep.prenom"
        " ORDER BY nc.prefix"
    )

    res = await db.execute(text(stmt), params)
    rows = []
    for r in res.fetchall():
        # Employé effectif : propre > hérité de la classe parente
        eff_id  = r.employe_id  if r.employe_id  is not None else r.parent_employe_id
        eff_nom = r.employe_nom if r.employe_id  is not None else r.parent_employe_nom
        eff_prenom = r.employe_prenom if r.employe_id is not None else r.parent_employe_prenom
        rows.append({
            "id": r.id,
            "prefix": r.prefix,
            "niveau": r.niveau,
            "designation": r.designation,
            "etagere": r.etagere,
            "categorie": r.categorie,
            "employe_id": r.employe_id,
            "employe_nom": r.employe_nom,
            "employe_prenom": r.employe_prenom,
            "employe_effectif_id": eff_id,
            "employe_effectif_nom": eff_nom,
            "employe_effectif_prenom": eff_prenom,
            "employe_herite": r.employe_id is None and r.parent_employe_id is not None,
            "nb_produits": r.nb_produits,
            "valeur_stock": float(r.valeur_stock),
        })
    return rows


@router.patch("/classifications/{classification_id}")
async def update_classification(
    classification_id: int,
    body: ClassificationUpdate,
    db: AsyncSession = Depends(get_db),
    current: dict = Depends(get_current_user),
):
    if current.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Réservé aux administrateurs")

    res = await db.execute(
        select(NomenclatureClassification)
        .where(NomenclatureClassification.id == classification_id)
    )
    cls = res.scalar_one_or_none()
    if not cls:
        raise HTTPException(status_code=404, detail="Classification introuvable")

    if body.designation is not None:
        cls.designation = body.designation
    if body.etagere is not None:
        cls.etagere = body.etagere
    if "employe_id" in body.model_fields_set:
        cls.employe_id = body.employe_id
    if "categorie" in body.model_fields_set:
        new_cat = body.categorie or None
        cls.categorie = new_cat
        # Bulk-update nomenclature.categorie for all products in this prefix
        if cls.niveau == 2:
            prefix_cond = "LEFT(n.de_equiv, 2) || ' ' || SUBSTR(n.de_equiv, 3, 1) = :prefix"
        else:
            prefix_cond = "LEFT(n.de_equiv, 2) = :prefix"
        await db.execute(text(f"""
            UPDATE nomenclature n
            SET categorie = :cat
            WHERE {prefix_cond}
        """), {"cat": new_cat, "prefix": cls.prefix})

    await db.commit()
    return {"id": cls.id, "prefix": cls.prefix, "designation": cls.designation,
            "etagere": cls.etagere, "employe_id": cls.employe_id,
            "categorie": cls.categorie}


@router.post("/classifications/reimport")
async def reimport_classifications(
    db: AsyncSession = Depends(get_db),
    current: dict = Depends(get_current_user),
):
    """Importe les nouveaux préfixes DTC depuis nomenclature.de_equiv (format 'NN X')."""
    if current.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Réservé aux administrateurs")

    res = await db.execute(text("""
        INSERT INTO nomenclature_classification (prefix, niveau)
        SELECT DISTINCT LEFT(de_equiv, 2) || ' ' || SUBSTR(de_equiv, 3, 1), 2
        FROM nomenclature
        WHERE de_equiv IS NOT NULL AND LENGTH(TRIM(de_equiv)) >= 3
        ON CONFLICT (prefix) DO NOTHING
        RETURNING prefix
    """))
    new_prefixes = [r.prefix for r in res.fetchall()]
    await db.commit()
    return {"imported": len(new_prefixes), "new_prefixes": new_prefixes}


@router.get("/classifications/{prefix}/products")
async def list_classification_products(
    prefix: str,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Produits appartenant à une classification DTC (niveau 1 ou 2)."""
    res = await db.execute(text("""
        SELECT
            n.id, n.nom, n.dci, n.dosage, n.forme_abr, n.famille,
            COALESCE(mv.prix_vente, 0) AS prix_vente, n.qte_alerte,
            COALESCE(mv.stock_actuel,       0) AS stock,
            COALESCE(mv.prix_moyen_pondere, 0) AS prix_achat_moyen
        FROM nomenclature n
        LEFT JOIN mv_stock_produits mv ON mv.id_nom = n.id
        WHERE (
            (LENGTH(:prefix) > 2 AND LEFT(n.de_equiv, 2) || ' ' || SUBSTR(n.de_equiv, 3, 1) = :prefix)
            OR
            (LENGTH(:prefix) <= 2 AND LEFT(n.de_equiv, 2) = :prefix)
        )
        ORDER BY n.nom
    """), {"prefix": prefix.upper()})
    return [
        {
            "id": r.id, "nom": r.nom, "dci": r.dci, "dosage": r.dosage,
            "forme_abr": r.forme_abr, "famille": r.famille,
            "prix_vente": _f(r.prix_vente),
            "stock": _f(r.stock),
            "prix_achat_moyen": _f(r.prix_achat_moyen),
            "qte_alerte": r.qte_alerte,
        }
        for r in res.fetchall()
    ]


@router.get("/classifications/etageres")
async def list_etageres(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Liste les étagères uniques — valeur stock depuis mv_stock_produits."""
    res = await db.execute(text("""
        SELECT
            nc.etagere,
            nc.employe_id,
            e.nom AS employe_nom,
            COUNT(DISTINCT nc.id)                             AS nb_classes,
            COUNT(DISTINCT n.id)                              AS nb_produits,
            COALESCE(SUM(mv.valeur_vente), 0)  AS valeur_stock
        FROM nomenclature_classification nc
        LEFT JOIN employes e ON e.id = nc.employe_id
        LEFT JOIN nomenclature n ON (
            (nc.niveau = 2 AND LEFT(n.de_equiv, 2) || ' ' || SUBSTR(n.de_equiv, 3, 1) = nc.prefix)
            OR
            (nc.niveau = 1 AND LEFT(n.de_equiv, 2) = nc.prefix)
        )
        LEFT JOIN mv_stock_produits mv ON mv.id_nom = n.id
        WHERE nc.etagere IS NOT NULL AND nc.etagere != ''
        GROUP BY nc.etagere, nc.employe_id, e.nom
        ORDER BY nc.etagere
    """))
    return [
        {
            "etagere": r.etagere,
            "employe_id": r.employe_id,
            "employe_nom": r.employe_nom,
            "nb_classes": r.nb_classes,
            "nb_produits": r.nb_produits,
            "valeur_stock": float(r.valeur_stock),
        }
        for r in res.fetchall()
    ]


# ── KPIs Rotation Stock ────────────────────────────────────────────────────────

@router.get("/products/{product_id}/lots")
async def list_product_lots(
    product_id: int,
    in_stock_only: bool = Query(True, description="Ne retourner que les lots avec stock > 0"),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Lots (entrees_produits) d'un produit, triés par date de péremption."""
    extra = "AND ep.stock > 0" if in_stock_only else ""
    res = await db.execute(text(f"""
        SELECT
            ep.id,
            ep.lot,
            ep.peremption,
            ep.peremption_date,
            ep.stock,
            ep.qte_entree,
            ep.prix_achat,
            ep.prix_vente,
            ep.fournisseur,
            ep.date_entree,
            ep.num_bl,
            ep.bloque
        FROM entrees_produits ep
        WHERE ep.id_nom = :id_nom {extra}
        ORDER BY ep.peremption_date ASC NULLS LAST, ep.id DESC
    """), {"id_nom": product_id})
    return [
        {
            "id": r.id,
            "lot": r.lot,
            "peremption": r.peremption,
            "peremption_date": r.peremption_date.isoformat() if r.peremption_date else None,
            "stock": int(r.stock or 0),
            "qte_entree": int(r.qte_entree or 0),
            "prix_achat": _f(r.prix_achat),
            "prix_vente": _f(r.prix_vente),
            "fournisseur": r.fournisseur,
            "date_entree": r.date_entree.isoformat() if r.date_entree else None,
            "num_bl": r.num_bl,
            "bloque": r.bloque,
        }
        for r in res.fetchall()
    ]


@router.get("/dashboard/lots")
async def dashboard_lots(
    type: str = Query(..., description="rupture | alerte | peremption_3m | peremption_6m | peremption_9m | surstock"),
    employe_id: Optional[int] = Query(None),
    famille: Optional[str] = Query(None),
    limit: int = Query(200, ge=1, le=500),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Liste des produits/lots correspondant au KPI cliqué dans le tableau de bord stock.
    Filtrables par employé responsable et par famille.
    """
    if type not in ("rupture", "alerte", "peremption_3m", "peremption_6m", "peremption_9m", "surstock"):
        raise HTTPException(status_code=400, detail=f"type invalide : {type!r}")

    params: dict = {"limit": limit}
    id_conds = ["n.archive = false"]
    join_classif = ""

    if employe_id is not None:
        join_classif = """
            JOIN nomenclature_classification nc ON (
                (nc.niveau = 2 AND LEFT(n.de_equiv, 2) || ' ' || SUBSTR(n.de_equiv, 3, 1) = nc.prefix)
                OR (nc.niveau = 1 AND LEFT(n.de_equiv, 2) = nc.prefix)
            )
        """
        id_conds.append("nc.employe_id = :employe_id")
        params["employe_id"] = employe_id

    if famille:
        id_conds.append("n.famille = :famille")
        params["famille"] = famille

    id_where = " AND ".join(id_conds)

    filtered_ids_cte = f"""
        filtered_ids AS (
            SELECT DISTINCT n.id
            FROM nomenclature n
            {join_classif}
            WHERE {id_where}
        )
    """

    if type == "rupture":
        q = f"""
            WITH {filtered_ids_cte}
            SELECT n.id, n.nom, n.famille, n.dci, n.forme_abr,
                   n.segment_abc, n.segment_xyz, n.disponibilite,
                   n.qte_alerte, COALESCE(mv.prix_vente, 0) AS prix_vente,
                   COALESCE(mv.stock_actuel, 0) AS stock
            FROM nomenclature n
            LEFT JOIN mv_stock_produits mv ON mv.id_nom = n.id
            WHERE n.id IN (SELECT id FROM filtered_ids)
              AND COALESCE(mv.stock_actuel, 0) = 0
              AND COALESCE(mv.actif, false)
            ORDER BY n.nom LIMIT :limit
        """
    elif type == "alerte":
        q = f"""
            WITH {filtered_ids_cte}
            SELECT n.id, n.nom, n.famille, n.dci, n.forme_abr,
                   n.segment_abc, n.segment_xyz, n.disponibilite,
                   n.qte_alerte, COALESCE(mv.prix_vente, 0) AS prix_vente,
                   COALESCE(mv.stock_actuel, 0) AS stock
            FROM nomenclature n
            JOIN mv_stock_produits mv ON mv.id_nom = n.id
            WHERE n.id IN (SELECT id FROM filtered_ids)
              AND n.qte_alerte > 0
              AND mv.stock_actuel > 0
              AND mv.stock_actuel < n.qte_alerte
            ORDER BY mv.stock_actuel ASC LIMIT :limit
        """
    elif type in ("peremption_3m", "peremption_6m", "peremption_9m"):
        if type == "peremption_3m":
            date_min = "CURRENT_DATE"
            date_max = "CURRENT_DATE + INTERVAL '90 days'"
        elif type == "peremption_6m":   # tranche 3à6 mois
            date_min = "CURRENT_DATE + INTERVAL '90 days'"
            date_max = "CURRENT_DATE + INTERVAL '180 days'"
        else:                            # tranche 7à9 mois
            date_min = "CURRENT_DATE + INTERVAL '180 days'"
            date_max = "CURRENT_DATE + INTERVAL '270 days'"
        q = f"""
            WITH {filtered_ids_cte}
            SELECT ep.id, ep.id_nom, ep.lot,
                   n.nom, n.famille, n.dci, n.forme_abr,
                   n.segment_abc, n.segment_xyz,
                   ep.peremption, ep.peremption_date,
                   ep.stock AS stock_lot,
                   ep.prix_achat, ep.fournisseur
            FROM entrees_produits ep
            JOIN nomenclature n ON n.id = ep.id_nom
            WHERE ep.id_nom IN (SELECT id FROM filtered_ids)
              AND ep.peremption_date IS NOT NULL
              AND ep.peremption_date > {date_min}
              AND ep.peremption_date <= {date_max}
              AND ep.stock > 0 AND ep.bloque = 0
            ORDER BY ep.peremption_date ASC LIMIT :limit
        """
    else:  # surstock
        q = f"""
            WITH {filtered_ids_cte},
            ventes_moy AS (
                SELECT id_nom, SUM(qte_sortie) / 12.0 AS avg_monthly
                FROM sorties_produits
                WHERE date >= CURRENT_DATE - INTERVAL '12 months'
                  AND type_sortie NOT IN ('RET', 'AV')
                  AND id_nom IN (SELECT id FROM filtered_ids)
                GROUP BY id_nom
            )
            SELECT n.id, n.nom, n.famille, n.dci, n.forme_abr,
                   n.segment_abc, n.segment_xyz,
                   n.qte_alerte, COALESCE(mv.prix_vente, 0) AS prix_vente,
                   COALESCE(mv.stock_actuel, 0) AS stock,
                   ROUND(COALESCE(mv.stock_actuel, 0)::numeric / NULLIF(vm.avg_monthly, 0), 1) AS mois_stock
            FROM nomenclature n
            JOIN mv_stock_produits mv ON mv.id_nom = n.id
            JOIN ventes_moy vm ON vm.id_nom = n.id
            WHERE n.id IN (SELECT id FROM filtered_ids)
              AND vm.avg_monthly > 0
              AND mv.stock_actuel > vm.avg_monthly * 6
            ORDER BY mois_stock DESC LIMIT :limit
        """

    res = await db.execute(text(q), params)
    rows = res.mappings().all()

    def _row(r):
        d = dict(r)
        for k, v in d.items():
            from decimal import Decimal
            if isinstance(v, Decimal):
                d[k] = float(v)
        return d

    return [_row(r) for r in rows]


@router.get("/kpis/rotation")
async def get_rotation_kpis(
    annee: Optional[int] = Query(None),
    mois: Optional[int] = Query(None),
    employe_id: Optional[int] = Query(None),
    famille: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Rotation de stock par employé + globale.
    Filtrable par employé responsable et/ou famille.
    """
    from datetime import datetime
    if annee is None:
        annee = datetime.now().year
    if mois is None:
        mois = datetime.now().month

    params: dict = {"annee": annee, "mois": mois}
    id_conds = ["n.archive = false"]
    join_classif = ""

    if employe_id is not None:
        join_classif = """
            JOIN nomenclature_classification nc ON (
                (nc.niveau = 2 AND LEFT(n.de_equiv, 2) || ' ' || SUBSTR(n.de_equiv, 3, 1) = nc.prefix)
                OR (nc.niveau = 1 AND LEFT(n.de_equiv, 2) = nc.prefix)
            )
        """
        id_conds.append("nc.employe_id = :employe_id")
        params["employe_id"] = employe_id

    if famille:
        id_conds.append("n.famille = :famille")
        params["famille"] = famille

    id_where = " AND ".join(id_conds)

    filtered_ids_cte = f"""
        filtered_ids AS (
            SELECT DISTINCT n.id
            FROM nomenclature n
            {join_classif}
            WHERE {id_where}
        )
    """

    # ── Rotation globale (périmètre filtré) ───────────────────────────────────
    g = (await db.execute(text(f"""
        WITH {filtered_ids_cte}
        SELECT
            COALESCE(SUM(sp_agg.qte_vendue),        0) AS qte_vendue,
            COALESCE(SUM(mv.stock_actuel),          0) AS stock_total,
            COALESCE(SUM(mv.stock_actuel * mv.prix_moyen_pondere), 0) AS valeur_stock
        FROM filtered_ids fi
        JOIN mv_stock_produits mv ON mv.id_nom = fi.id
        LEFT JOIN (
            SELECT id_nom, SUM(qte_sortie) AS qte_vendue
            FROM sorties_produits
            WHERE EXTRACT(YEAR  FROM date) = :annee
              AND EXTRACT(MONTH FROM date) = :mois
            GROUP BY id_nom
        ) sp_agg ON sp_agg.id_nom = mv.id_nom
    """), params)).fetchone()

    global_rotation = (
        round(float(g.qte_vendue) / float(g.stock_total), 3)
        if g.stock_total and float(g.stock_total) > 0 else 0
    )

    # ── Rotation par employé ──────────────────────────────────────────────────
    emp_extra_where = ""
    if employe_id is not None:
        emp_extra_where += " AND e.id = :employe_id"
    if famille:
        emp_extra_where += " AND n.famille = :famille"

    per_emp_res = await db.execute(text(f"""
        SELECT
            e.id            AS employe_id,
            e.nom           AS employe_nom,
            e.prenom        AS employe_prenom,
            COUNT(DISTINCT n.id)                                            AS nb_produits,
            COALESCE(SUM(mv.stock_actuel),                       0)         AS stock_total,
            COALESCE(SUM(mv.stock_actuel * mv.prix_moyen_pondere), 0)       AS valeur_stock,
            COALESCE(SUM(sp_agg.qte_vendue),                     0)         AS qte_vendue
        FROM employes e
        JOIN nomenclature_classification nc ON nc.employe_id = e.id
        JOIN nomenclature n ON (
            (nc.niveau = 2 AND LEFT(n.de_equiv, 2) || ' ' || SUBSTR(n.de_equiv, 3, 1) = nc.prefix)
            OR
            (nc.niveau = 1 AND LEFT(n.de_equiv, 2) = nc.prefix)
        )
        JOIN mv_stock_produits mv ON mv.id_nom = n.id
        LEFT JOIN (
            SELECT id_nom, SUM(qte_sortie) AS qte_vendue
            FROM sorties_produits
            WHERE EXTRACT(YEAR  FROM date) = :annee
              AND EXTRACT(MONTH FROM date) = :mois
            GROUP BY id_nom
        ) sp_agg ON sp_agg.id_nom = n.id
        WHERE e.actif = TRUE{emp_extra_where}
        GROUP BY e.id, e.nom, e.prenom
        ORDER BY valeur_stock DESC
    """), params)

    per_employe = []
    for r in per_emp_res.fetchall():
        stock = float(r.stock_total)
        qte = float(r.qte_vendue)
        rotation = round(qte / stock, 3) if stock > 0 else 0
        per_employe.append({
            "employe_id": r.employe_id,
            "employe_nom": r.employe_nom,
            "employe_prenom": r.employe_prenom,
            "nb_produits": r.nb_produits,
            "stock_total": stock,
            "valeur_stock": float(r.valeur_stock),
            "qte_vendue": qte,
            "rotation": rotation,
        })

    return {
        "annee": annee,
        "mois": mois,
        "global": {
            "qte_vendue": float(g.qte_vendue),
            "stock_total": float(g.stock_total),
            "valeur_stock": float(g.valeur_stock),
            "rotation": global_rotation,
        },
        "par_employe": per_employe,
    }


@router.get("/kpis/segments")
async def get_segment_kpis(
    employe_id: Optional[int] = Query(None),
    famille: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Distribution ABC et XYZ + matrice croisée ABC×XYZ.
    Basé sur les colonnes segment_abc / segment_xyz calculées mensuellement.
    Filtrable par employé responsable et/ou famille.
    """
    params: dict = {}
    id_conds = ["n.archive = false"]
    join_classif = ""

    if employe_id is not None:
        join_classif = """
            JOIN nomenclature_classification nc ON (
                (nc.niveau = 2 AND LEFT(n.de_equiv, 2) || ' ' || SUBSTR(n.de_equiv, 3, 1) = nc.prefix)
                OR (nc.niveau = 1 AND LEFT(n.de_equiv, 2) = nc.prefix)
            )
        """
        id_conds.append("nc.employe_id = :employe_id")
        params["employe_id"] = employe_id

    if famille:
        id_conds.append("n.famille = :famille")
        params["famille"] = famille

    id_where = " AND ".join(id_conds)

    filtered_ids_cte = f"""
        filtered_ids AS (
            SELECT DISTINCT n.id
            FROM nomenclature n
            {join_classif}
            WHERE {id_where}
        )
    """

    # ── ABC : nb produits, valeur stock, CA 12 mois ───────────────────────────
    abc_res = await db.execute(text(f"""
        WITH {filtered_ids_cte},
        ca_12m AS (
            SELECT sp.id_nom, SUM(sp.qte_sortie * sp.prix_vente) AS ca
            FROM sorties_produits sp
            WHERE sp.date >= CURRENT_DATE - INTERVAL '12 months'
              AND sp.type_sortie NOT IN ('RET', 'AV')
              AND sp.id_nom IN (SELECT id FROM filtered_ids)
            GROUP BY sp.id_nom
        )
        SELECT
            COALESCE(n.segment_abc, '-')              AS segment,
            COUNT(DISTINCT n.id)                       AS nb_produits,
            COALESCE(SUM(mv.stock_actuel * mv.prix_moyen_pondere), 0) AS valeur_stock,
            COALESCE(SUM(c.ca), 0)                     AS ca_12m
        FROM nomenclature n
        LEFT JOIN mv_stock_produits mv ON mv.id_nom = n.id
        LEFT JOIN ca_12m c ON c.id_nom = n.id
        WHERE n.id IN (SELECT id FROM filtered_ids)
        GROUP BY COALESCE(n.segment_abc, '-')
        ORDER BY segment
    """), params)
    abc_rows = abc_res.fetchall()
    total_produits = sum(r.nb_produits for r in abc_rows) or 1
    total_ca = sum(float(r.ca_12m) for r in abc_rows) or 1
    abc = [
        {
            "segment": r.segment,
            "nb_produits": r.nb_produits,
            "valeur_stock": float(r.valeur_stock),
            "ca_12m": float(r.ca_12m),
            "pct_produits": round(r.nb_produits / total_produits * 100, 1),
            "pct_ca": round(float(r.ca_12m) / total_ca * 100, 1),
        }
        for r in abc_rows
    ]

    # ── XYZ : nb produits ─────────────────────────────────────────────────────
    xyz_res = await db.execute(text(f"""
        WITH {filtered_ids_cte}
        SELECT
            COALESCE(segment_xyz, '-') AS segment,
            COUNT(*)                    AS nb_produits
        FROM nomenclature
        WHERE id IN (SELECT id FROM filtered_ids)
        GROUP BY COALESCE(segment_xyz, '-')
        ORDER BY segment
    """), params)
    xyz_rows = xyz_res.fetchall()
    xyz = [
        {
            "segment": r.segment,
            "nb_produits": r.nb_produits,
            "pct_produits": round(r.nb_produits / total_produits * 100, 1),
        }
        for r in xyz_rows
    ]

    # ── Matrice ABC×XYZ ───────────────────────────────────────────────────────
    mat_res = await db.execute(text(f"""
        WITH {filtered_ids_cte}
        SELECT
            COALESCE(segment_abc, '-') AS seg_abc,
            COALESCE(segment_xyz, '-') AS seg_xyz,
            COUNT(*)                    AS nb_produits
        FROM nomenclature
        WHERE id IN (SELECT id FROM filtered_ids)
        GROUP BY COALESCE(segment_abc, '-'), COALESCE(segment_xyz, '-')
    """), params)
    matrice = [
        {
            "abc": r.seg_abc,
            "xyz": r.seg_xyz,
            "nb_produits": r.nb_produits,
        }
        for r in mat_res.fetchall()
    ]

    return {"abc": abc, "xyz": xyz, "matrice": matrice}


# ── KPIs Catégories (princeps / générique / promotion) ────────────────────────

_PROD_CAT_JOIN = """
    WITH prod_cat AS (
        SELECT DISTINCT ON (n.id)
            n.id          AS id_nom,
            nc.categorie
        FROM nomenclature n
        JOIN nomenclature_classification nc ON (
            (nc.niveau = 2 AND LEFT(n.de_equiv, 2) || ' ' || SUBSTR(n.de_equiv, 3, 1) = nc.prefix)
            OR (nc.niveau = 1 AND LEFT(n.de_equiv, 2) = nc.prefix)
        )
        WHERE nc.categorie IS NOT NULL
        ORDER BY n.id, nc.niveau DESC
    )
"""

@router.get("/kpis/categories")
async def get_categories_kpis(
    employe_id: Optional[int] = Query(None),
    famille: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Répartition valeur stock et CA 12 mois par catégorie (princeps/generique/promotion).
    Filtres optionnels : employe_id (produits assignés) et famille.
    """
    extra = ""
    params: dict = {}
    if employe_id is not None:
        extra += """
            AND n.id IN (
                SELECT DISTINCT n2.id FROM nomenclature n2
                JOIN nomenclature_classification nc2 ON (
                    (nc2.niveau = 2 AND LEFT(n2.de_equiv, 2) || ' ' || SUBSTR(n2.de_equiv, 3, 1) = nc2.prefix)
                    OR (nc2.niveau = 1 AND LEFT(n2.de_equiv, 2) = nc2.prefix)
                )
                WHERE nc2.employe_id = :employe_id
            )
        """
        params["employe_id"] = employe_id
    if famille:
        extra += " AND n.famille = :famille"
        params["famille"] = famille

    res = await db.execute(text(f"""
        WITH sales AS (
            SELECT id_nom,
                   SUM(qte_sortie * prix_vente *
                       CASE WHEN type_sortie IN ('RET','AV') THEN -1 ELSE 1 END
                   ) AS ca_12m
            FROM sorties_produits
            WHERE date >= CURRENT_DATE - INTERVAL '12 months'
            GROUP BY id_nom
        )
        SELECT
            n.categorie,
            COUNT(DISTINCT n.id)                               AS nb_produits,
            COALESCE(SUM(mv.valeur_vente), 0)   AS valeur_stock,
            COALESCE(SUM(sl.ca_12m), 0)                        AS ca_12m
        FROM nomenclature n
        LEFT JOIN mv_stock_produits mv ON mv.id_nom = n.id
        LEFT JOIN sales sl ON sl.id_nom = n.id
        WHERE n.categorie IS NOT NULL {extra}
        GROUP BY n.categorie
        ORDER BY ca_12m DESC
    """), params)

    rows = res.fetchall()
    total_ca = sum(float(r.ca_12m) for r in rows) or 1.0
    return [
        {
            "categorie": r.categorie,
            "nb_produits": r.nb_produits,
            "valeur_stock": float(r.valeur_stock),
            "ca_12m": float(r.ca_12m),
            "pct_ca": round(float(r.ca_12m) / total_ca * 100, 1),
        }
        for r in rows
    ]


@router.get("/kpis/performance-categories")
async def get_performance_categories(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Performance par employé × catégorie sur 12 mois.
    Retourne pour chaque employé : CA princeps / generique / promotion + assiette prime.
    L'assiette prime = CA_promotion × 1.5 + CA_generique × 1.2 + CA_princeps × 1.0
    """
    res = await db.execute(text("""
        SELECT
            e.id                                    AS employe_id,
            e.nom                                   AS employe_nom,
            e.prenom                                AS employe_prenom,
            n.categorie,
            COUNT(DISTINCT sp.id_nom)               AS nb_produits,
            COALESCE(SUM(
                sp.qte_sortie * sp.prix_vente *
                CASE WHEN sp.type_sortie IN ('RET','AV') THEN -1 ELSE 1 END
            ), 0)                                   AS ca
        FROM sorties_produits sp
        JOIN nomenclature n ON n.id = sp.id_nom
        JOIN LATERAL (
            SELECT DISTINCT nc2.employe_id
            FROM nomenclature_classification nc2
            WHERE (
                (nc2.niveau = 2 AND LEFT(n.de_equiv, 2) || ' ' || SUBSTR(n.de_equiv, 3, 1) = nc2.prefix)
                OR (nc2.niveau = 1 AND LEFT(n.de_equiv, 2) = nc2.prefix)
            )
            AND nc2.employe_id IS NOT NULL
            LIMIT 1
        ) emp ON true
        JOIN employes e ON e.id = emp.employe_id
        WHERE sp.date >= CURRENT_DATE - INTERVAL '12 months'
          AND n.categorie IS NOT NULL
        GROUP BY e.id, e.nom, e.prenom, n.categorie
        ORDER BY e.nom, n.categorie
    """))

    # Pivot par employé
    from collections import defaultdict
    emp_map: dict = defaultdict(lambda: {
        "employe_id": None, "employe_nom": "", "employe_prenom": "",
        "princeps": {"nb_produits": 0, "ca": 0.0},
        "generique": {"nb_produits": 0, "ca": 0.0},
        "generique++": {"nb_produits": 0, "ca": 0.0},
    })
    for r in res.fetchall():
        key = r.employe_id
        emp_map[key]["employe_id"] = r.employe_id
        emp_map[key]["employe_nom"] = r.employe_nom
        emp_map[key]["employe_prenom"] = r.employe_prenom
        cat = r.categorie
        if cat in emp_map[key]:
            emp_map[key][cat]["nb_produits"] = r.nb_produits
            emp_map[key][cat]["ca"] = float(r.ca)

    result = []
    for emp in emp_map.values():
        ca_p = emp["princeps"]["ca"]
        ca_g = emp["generique"]["ca"]
        ca_pr = emp["generique++"]["ca"]
        ca_total = ca_p + ca_g + ca_pr
        assiette = ca_pr * 1.5 + ca_g * 1.2 + ca_p * 1.0
        result.append({
            **emp,
            "ca_total": ca_total,
            "assiette_prime": round(assiette, 2),
        })
    result.sort(key=lambda x: x["employe_nom"])
    return result


# ── Laboratoires ──────────────────────────────────────────────────────────────

class LaboratoireUpdate(PydanticBaseModel):
    is_generique: bool


@router.get("/laboratoires")
async def list_laboratoires(
    q: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Liste des laboratoires avec flag is_generique."""
    stmt = "SELECT id, labo, is_generique FROM laboratoires WHERE labo IS NOT NULL"
    params: dict = {}
    if q:
        stmt += " AND labo ILIKE :q"
        params["q"] = f"%{q}%"
    stmt += " ORDER BY labo"
    res = await db.execute(text(stmt), params)
    return [
        {"id": r.id, "labo": r.labo, "is_generique": r.is_generique}
        for r in res.fetchall()
    ]


@router.patch("/laboratoires/{labo_id}")
async def update_laboratoire(
    labo_id: int,
    body: LaboratoireUpdate,
    db: AsyncSession = Depends(get_db),
    current: dict = Depends(get_current_user),
):
    if current.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Réservé aux administrateurs")
    res = await db.execute(select(Laboratoire).where(Laboratoire.id == labo_id))
    lab = res.scalar_one_or_none()
    if not lab:
        raise HTTPException(status_code=404, detail="Laboratoire introuvable")
    lab.is_generique = body.is_generique
    await db.commit()
    return {"id": lab.id, "labo": lab.labo, "is_generique": lab.is_generique}


# ── Auto-catégorisation ───────────────────────────────────────────────────────

@router.post("/classifications/auto-categorize")
async def auto_categorize(
    marge_promo: float = Query(50.0, ge=0, le=100, description="Seuil marge % pour Promotion"),
    db: AsyncSession = Depends(get_db),
    current: dict = Depends(get_current_user),
):
    """
    Assigne automatiquement nomenclature.categorie pour chaque produit en stock :
      - generique++ : marge pondérée > marge_promo %
                      = SUM(stock × (prix_vente - prix_achat) / prix_achat) / SUM(stock) × 100
      - generique   : non generique++ ET laboratoire.is_generique = true
      - princeps    : tout le reste
    """
    if current.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Réservé aux administrateurs")

    res = await db.execute(text("""
        WITH lot_margins AS (
            SELECT
                ep.id_nom,
                SUM(
                    CASE WHEN ep.prix_achat > 0
                         THEN ep.stock * (ep.prix_vente - ep.prix_achat) / ep.prix_achat
                         ELSE 0 END
                ) / NULLIF(SUM(
                    CASE WHEN ep.prix_achat > 0 THEN ep.stock ELSE 0 END
                ), 0) * 100 AS marge_moy
            FROM entrees_produits ep
            WHERE ep.stock > 0
            GROUP BY ep.id_nom
        ),
        updated AS (
            UPDATE nomenclature
            SET categorie = CASE
                WHEN lm.marge_moy > :marge_promo
                    THEN 'generique++'
                WHEN EXISTS (
                    SELECT 1 FROM laboratoires l
                    WHERE LOWER(TRIM(l.labo)) = LOWER(TRIM(nomenclature.labo))
                      AND l.is_generique = true
                )
                    THEN 'generique'
                ELSE 'princeps'
            END
            FROM lot_margins lm
            WHERE lm.id_nom = nomenclature.id
              AND nomenclature.archive = false
            RETURNING categorie
        )
        SELECT categorie, COUNT(*) AS nb
        FROM updated
        GROUP BY categorie
    """), {"marge_promo": marge_promo})

    counts = {r.categorie: r.nb for r in res.fetchall()}
    await db.commit()

    return {
        "generique++": counts.get("generique++", 0),
        "generique":  counts.get("generique",  0),
        "princeps":   counts.get("princeps",   0),
        "total":      sum(counts.values()),
    }


# ── GET /stock/psychotropes/historique ────────────────────────────────────────

_PSYCHOTROPES_HISTORY_SQL = """
WITH psychotropes AS (
    SELECT n.id AS id_nom, n.nom, n.dci,
           COALESCE(mv.stock_actuel, 0) AS stock_actuel
    FROM nomenclature n
    JOIN mv_stock_produits mv ON mv.id_nom = n.id
    WHERE n.psychotrope = 1
      AND n.archive = FALSE
      AND (CAST(:id_nom AS integer) IS NULL OR n.id = CAST(:id_nom AS integer))
),
mouvements AS (
    SELECT sp.id_nom, sp.date AS d, SUM(sp.qte_sortie) AS delta
    FROM sorties_produits sp
    JOIN psychotropes p ON p.id_nom = sp.id_nom
    WHERE sp.type_sortie NOT IN ('AV', 'R')
      AND sp.date >= :date_debut
    GROUP BY sp.id_nom, sp.date

    UNION ALL

    SELECT rsp.id_nom, rsp.date_echange AS d, SUM(rsp.qte) AS delta
    FROM echanges_sorties_produits rsp
    JOIN psychotropes p ON p.id_nom = rsp.id_nom
    WHERE rsp.date_echange >= :date_debut
    GROUP BY rsp.id_nom, rsp.date_echange

    UNION ALL

    SELECT ep.id_nom, ep.date_entree AS d, -SUM(ep.qte_entree) AS delta
    FROM entrees_produits ep
    JOIN psychotropes p ON p.id_nom = ep.id_nom
    WHERE ep.type_entree NOT IN ('AV')
      AND ep.date_entree >= :date_debut
    GROUP BY ep.id_nom, ep.date_entree

    UNION ALL

    SELECT ip.id_nom, ip.date AS d, -SUM(ip.ecart) AS delta
    FROM inventaires_produits ip
    JOIN inventaires inv ON inv.id = ip.id_inventaire AND inv.etat = 1
    JOIN psychotropes p ON p.id_nom = ip.id_nom
    WHERE ip.date >= :date_debut
    GROUP BY ip.id_nom, ip.date
),
par_jour AS (
    SELECT id_nom, d, SUM(delta) AS delta_jour
    FROM mouvements
    GROUP BY id_nom, d
),
avec_cumul AS (
    SELECT
        id_nom,
        d,
        SUM(delta_jour) OVER (
            PARTITION BY id_nom
            ORDER BY d DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS cumul_apres
    FROM par_jour
)
SELECT
    ac.id_nom,
    p.nom,
    p.dci,
    p.stock_actuel,
    ac.d                                              AS date,
    p.stock_actuel + COALESCE(ac.cumul_apres, 0)     AS stock_eod
FROM avec_cumul ac
JOIN psychotropes p ON p.id_nom = ac.id_nom
ORDER BY ac.id_nom, ac.d
"""


@router.get("/psychotropes/historique")
async def get_psychotropes_historique(
    date_debut: Optional[str] = Query(
        None,
        description="Date de début YYYY-MM-DD (défaut : 12 mois)",
    ),
    id_nom: Optional[int] = Query(None, description="Filtrer sur un seul produit"),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Retourne l'historique de stock reconstitué pour tous les psychotropes
    (nomenclature.psychotrope = 1), ou un seul si id_nom est fourni.

    Formule (remontée depuis le stock actuel) :
        stock(D) = stock_actuel
                 + Σ sorties[D+1 → auj]
                 + Σ échanges[D+1 → auj]
                 - Σ entrées[D+1 → auj]
                 - Σ ajustements_inventaire[D+1 → auj]
    """
    from datetime import date, timedelta

    if date_debut is None:
        date_debut_obj = date.today() - timedelta(days=365)
    else:
        try:
            date_debut_obj = date.fromisoformat(date_debut)
        except ValueError:
            raise HTTPException(status_code=422, detail="date_debut doit être au format YYYY-MM-DD")

    rows = (await db.execute(text(_PSYCHOTROPES_HISTORY_SQL), {
        "date_debut": date_debut_obj,
        "id_nom":     id_nom,
    })).fetchall()

    # Grouper par produit
    produits: dict[int, dict] = {}
    for r in rows:
        if r.id_nom not in produits:
            produits[r.id_nom] = {
                "id_nom":        r.id_nom,
                "nom":           r.nom,
                "dci":           r.dci,
                "stock_actuel":  _f(r.stock_actuel),
                "historique":    [],
            }
        produits[r.id_nom]["historique"].append({
            "date":      r.date.isoformat(),
            "stock_eod": _f(r.stock_eod),
        })

    return list(produits.values())


# ── GET /stock/psychotropes/snapshot ──────────────────────────────────────────

_PSYCHOTROPES_SNAPSHOT_SQL = """
WITH psychotropes AS (
    SELECT n.id AS id_nom, n.nom, n.dci,
           COALESCE(mv.stock_actuel, 0) AS stock_actuel
    FROM nomenclature n
    JOIN mv_stock_produits mv ON mv.id_nom = n.id
    WHERE n.psychotrope = 1
      AND n.archive = FALSE
      AND (CAST(:id_nom AS integer) IS NULL OR n.id = CAST(:id_nom AS integer))
),
delta_apres AS (
    -- Ventes APRÈS la date cible → stock remonté vers le passé (+)
    SELECT sp.id_nom, SUM(sp.qte_sortie) AS delta
    FROM sorties_produits sp
    JOIN psychotropes p ON p.id_nom = sp.id_nom
    WHERE sp.type_sortie NOT IN ('AV', 'R')
      AND sp.date > :date_cible
    GROUP BY sp.id_nom

    UNION ALL

    -- Échanges APRÈS la date cible (+)
    SELECT rsp.id_nom, SUM(rsp.qte) AS delta
    FROM echanges_sorties_produits rsp
    JOIN psychotropes p ON p.id_nom = rsp.id_nom
    WHERE rsp.date_echange > :date_cible
    GROUP BY rsp.id_nom

    UNION ALL

    -- Achats APRÈS la date cible → réduisent le stock passé (-)
    SELECT ep.id_nom, -SUM(ep.qte_entree) AS delta
    FROM entrees_produits ep
    JOIN psychotropes p ON p.id_nom = ep.id_nom
    WHERE ep.type_entree NOT IN ('AV')
      AND ep.date_entree > :date_cible
    GROUP BY ep.id_nom

    UNION ALL

    -- Ajustements inventaire validés APRÈS la date cible (signe inversé)
    SELECT ip.id_nom, -SUM(ip.ecart) AS delta
    FROM inventaires_produits ip
    JOIN inventaires inv ON inv.id = ip.id_inventaire AND inv.etat = 1
    JOIN psychotropes p ON p.id_nom = ip.id_nom
    WHERE ip.date > :date_cible
    GROUP BY ip.id_nom
),
totaux AS (
    SELECT id_nom, SUM(delta) AS delta_total
    FROM delta_apres
    GROUP BY id_nom
)
SELECT
    p.id_nom,
    p.nom,
    p.dci,
    p.stock_actuel + COALESCE(t.delta_total, 0) AS stock_a_date
FROM psychotropes p
LEFT JOIN totaux t ON t.id_nom = p.id_nom
ORDER BY p.nom
"""


@router.get("/psychotropes/snapshot")
async def get_psychotropes_snapshot(
    date: str = Query(..., description="Date cible YYYY-MM-DD (ex: 2015-10-30)"),
    id_nom: Optional[int] = Query(None, description="Filtrer sur un seul produit"),
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Retourne le stock estimé de chaque psychotrope à la fin d'une journée précise.

    Calcul :
        stock(D) = stock_actuel + Σ mouvements(D+1 → aujourd'hui)

    Un seul agrégat SQL — pas de série temporelle.
    """
    from datetime import date as date_type

    try:
        date_obj = date_type.fromisoformat(date)
    except ValueError:
        raise HTTPException(status_code=422, detail="date doit être au format YYYY-MM-DD")

    rows = (await db.execute(text(_PSYCHOTROPES_SNAPSHOT_SQL), {
        "date_cible": date_obj,
        "id_nom":     id_nom,
    })).fetchall()

    return [
        {
            "id_nom":       r.id_nom,
            "nom":          r.nom,
            "dci":          r.dci,
            "stock_a_date": _f(r.stock_a_date),
        }
        for r in rows
    ]
