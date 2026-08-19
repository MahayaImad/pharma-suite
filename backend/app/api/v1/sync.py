"""
Endpoints génériques de synchronisation.

Le sync agent envoie :
  POST /sync/{table_name}      → upsert batch d'enregistrements
  GET  /sync/status/{table}    → récupérer le dernier ID synchronisé
  POST /sync/status/{table}    → mettre à jour le statut
"""
from typing import Any
from datetime import date as PyDate, datetime as PyDatetime

from typing import List
from pydantic import BaseModel as PydanticBaseModel
from fastapi import APIRouter, Depends, HTTPException, status
from decimal import Decimal as PyDecimal
from sqlalchemy import select, text, update, Date as SADate, Numeric as SANumeric
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession
from loguru import logger

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.sync_status import SyncStatus
from app.schemas.sync import SyncBatchPayload, SyncBatchResult, SyncStatusResponse, SyncStatusUpdate

# ── Import de tous les modèles SQLAlchemy ─────────────────────────────────────
from app.models.pharma import Nomenclature, Famille, Forme, Laboratoire, InstanceProduit, NomenclatureChifa
from app.models.ventes import Sortie, SortieProduit
from app.models.achats import Entree, EntreeProduit, Fournisseur, CommandeFournisseur, CommandeFournisseurProduit
from app.models.clients import Client
from app.models.caisse import Caisse, CaisseRegie, SuiviCaisse, Operation, Depense, CompteBancaire
from app.models.chifa import BordereauChifa, FactureChifa, FactureChifaProduit, ChifaRejetPartiel
from app.models.config_tables import Pharmacie, Poste, Groupware, Prestation, MotifInstance
from app.models.user import User
from app.core.security import hash_password
from app.models.autres import (
    Mouchard, MouchardDetails, Ordonnancier,
    Echange, EchangeSortieProduit,
    RegClientAssociation, RegFournAssociation,
    PharmnosFacture,
)
from app.models.inventaires import Inventaire, InventaireProduit

router = APIRouter(tags=["sync"])

# ── Registre table → modèle SQLAlchemy ────────────────────────────────────────
SYNC_REGISTRY: dict[str, Any] = {
    # Référentiel pharmaceutique
    "nomenclature":             Nomenclature,
    "familles":                 Famille,
    "formes":                   Forme,
    "laboratoires":             Laboratoire,
    "instance_produits":        InstanceProduit,
    "nomenclature_chifa":       NomenclatureChifa,
    # Ventes
    "sorties":                  Sortie,
    "sorties_produits":         SortieProduit,
    # Achats
    "entrees":                  Entree,
    "entrees_produits":         EntreeProduit,
    "fournisseurs":             Fournisseur,
    "commandes_fournisseurs":           CommandeFournisseur,
    "commandes_fournisseurs_produits":  CommandeFournisseurProduit,
    # Clients
    "clients":                  Client,
    # Caisse
    "caisses":                  Caisse,
    "caisses_regies":           CaisseRegie,
    "suivi_caisses":            SuiviCaisse,
    "operations":               Operation,
    "depenses":                 Depense,
    "comptes_bancaires":        CompteBancaire,
    # CHIFA
    "bordereaux_chifa":         BordereauChifa,
    "factures_chifa":           FactureChifa,
    "factures_chifa_produits":  FactureChifaProduit,
    "chifa_rejet_partiel":      ChifaRejetPartiel,
    # Configuration
    "pharmacies":               Pharmacie,
    "postes":                   Poste,
    "groupware":                Groupware,
    "prestations":              Prestation,
    "motif_instance":           MotifInstance,
    # Divers
    "mouchard":                 Mouchard,
    "mouchard_details":         MouchardDetails,
    "ordonnancier":             Ordonnancier,
    "echanges":                 Echange,
    "echanges_sorties_produits": EchangeSortieProduit,
    "reg_client_association":   RegClientAssociation,
    "reg_fourn_association":    RegFournAssociation,
    "pharmnos_factures":        PharmnosFacture,
    # Inventaires
    "inventaires":          Inventaire,
    "inventaires_produits": InventaireProduit,
}


def _clean_record(record: dict, model) -> dict:
    """
    Filtre les clés non présentes dans le modèle.
    Convertit :
    - les strings ISO en datetime.date  pour les colonnes Date
    - les strings en Decimal            pour les colonnes Numeric
    car model_dump(mode='json') de Pydantic v2 sérialise Decimal→str et
    asyncpg attend des objets Python natifs (datetime.date, Decimal).
    """
    valid_cols = {col.name for col in model.__table__.columns}
    date_cols = {
        col.name
        for col in model.__table__.columns
        if isinstance(col.type, SADate)
    }
    numeric_cols = {
        col.name
        for col in model.__table__.columns
        if isinstance(col.type, SANumeric)
    }
    result = {}
    for k, v in record.items():
        if k not in valid_cols:
            continue
        if v is None:
            result[k] = None
        elif k in date_cols and isinstance(v, str):
            try:
                result[k] = PyDatetime.strptime(v, "%Y-%m-%d").date()
            except (ValueError, TypeError):
                result[k] = None
        elif k in numeric_cols and isinstance(v, str):
            try:
                result[k] = PyDecimal(v)
            except Exception:
                result[k] = None
        else:
            result[k] = v
    return result


async def _upsert_batch(db: AsyncSession, model, records: list[dict]) -> tuple[int, int]:
    """
    Effectue un upsert PostgreSQL (INSERT … ON CONFLICT DO UPDATE).
    Découpe en sous-lots pour ne pas dépasser la limite de 65 535 paramètres PostgreSQL.

    Returns:
        (synced, errors)
    """
    synced = 0
    errors = 0

    # Nettoyer les enregistrements
    cleaned = []
    for r in records:
        try:
            cleaned.append(_clean_record(r, model))
        except Exception as e:
            logger.warning(f"Erreur nettoyage enregistrement: {e}")
            errors += 1

    if not cleaned:
        return 0, errors

    # Calcul de la taille de sous-lot pour rester sous 65 535 paramètres PostgreSQL
    num_cols = len(model.__table__.columns)
    chunk_size = max(1, 65000 // num_cols)

    # Seules les colonnes présentes dans le payload sont mises à jour en cas de conflit.
    # Les colonnes PostgreSQL-only (ex: archive) ne sont pas dans le payload → non écrasées.
    payload_cols = set(cleaned[0].keys()) if cleaned else set()

    for i in range(0, len(cleaned), chunk_size):
        chunk = cleaned[i:i + chunk_size]
        try:
            stmt = pg_insert(model.__table__).values(chunk)
            update_cols = {
                col.name: stmt.excluded[col.name]
                for col in model.__table__.columns
                if col.name != "id" and col.name in payload_cols
            }
            stmt = stmt.on_conflict_do_update(index_elements=["id"], set_=update_cols)
            await db.execute(stmt)
            await db.commit()
            synced += len(chunk)
        except Exception as e:
            await db.rollback()
            logger.error(f"Erreur upsert {model.__tablename__} (chunk {i}–{i+len(chunk)}): {e}")
            errors += len(chunk)

    return synced, errors


async def _sync_groupware_to_users(db: AsyncSession) -> None:
    """
    Propage toutes les entrées groupware valides (utilisateur + mot_de_passe non vides)
    vers la table `users` avec hachage bcrypt.
    Appelé automatiquement après chaque batch sync de la table groupware.
    """
    try:
        gw_res = await db.execute(select(Groupware))
        rows = gw_res.scalars().all()
        logger.info(f"[sync/groupware→users] {len(rows)} lignes groupware trouvées")

        entries = []
        for gw in rows:
            if not gw.utilisateur:
                continue
            pwd = (gw.mot_de_passe or "").strip()
            if not pwd:
                continue
            # bcrypt hard limit — truncate at byte level before hashing
            pwd_safe = pwd.encode("utf-8")[:72].decode("utf-8", errors="ignore")
            try:
                hashed = hash_password(pwd_safe)
            except Exception as hash_err:
                logger.error(f"[sync/groupware→users] '{gw.utilisateur}' hash FAILED: {hash_err}")
                continue
            entries.append({
                "username": gw.utilisateur,
                "hashed_password": hashed,
                "is_active": (gw.actif == 1) if gw.actif is not None else True,
                "role": "admin" if gw.id == 1 else "employee",
            })

        if not entries:
            logger.warning("[sync/groupware→users] Aucun compte à synchroniser (tous sans mot de passe?)")
            return
        ins = pg_insert(User.__table__).values(entries)
        stmt = ins.on_conflict_do_update(
            index_elements=["username"],
            set_={
                "hashed_password": ins.excluded.hashed_password,
                "is_active": ins.excluded.is_active,
                "role": ins.excluded.role,
            },
        )
        await db.execute(stmt)
        await db.commit()
        logger.info(f"[sync/groupware→users] {len(entries)} comptes synchronisés")
    except Exception as e:
        await db.rollback()
        logger.error(f"[sync/groupware→users] Erreur: {e}")


# ── Routes ─────────────────────────────────────────────────────────────────────

class InstanceFinalizePayload(PydanticBaseModel):
    active_ids: List[int]


class InstanceFinalizeResult(PydanticBaseModel):
    archived: int    # enregistrements passés à archive=True
    restored: int    # enregistrements remis à archive=False


@router.post("/sync/instance_produits/batch", response_model=SyncBatchResult)
async def sync_instance_produits_batch(
    payload: SyncBatchPayload,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Upsert des instances ACTIVES (provenant de HFSQL instance_produits).
    Force archive=FALSE et efface les métadonnées d'archivage.
    Appelé par instance_produits_sync — étape 1 du full sync séquentiel.
    """
    from decimal import Decimal as _Dec

    def _d(val):
        if val is None:
            return None
        if isinstance(val, PyDate):
            return val
        try:
            return PyDate.fromisoformat(str(val))
        except Exception:
            return None

    def _dec(val):
        if val is None:
            return None
        try:
            return _Dec(str(val))
        except Exception:
            return None

    synced = 0
    for rec in payload.records:
        if not rec.get("id"):
            continue
        params = {
            **rec,
            "date":          _d(rec.get("date")),
            "echeance":      _d(rec.get("echeance")),
            "prix_vente":    _dec(rec.get("prix_vente")),
            "prix_achat_ttc": _dec(rec.get("prix_achat_ttc")),
        }
        await db.execute(text("""
            INSERT INTO instance_produits (
                id, date, id_client, client, id_nom, nom, id_famille, famille,
                prix_vente, qte_sortie, heure, prix_achat_ttc, id_produit, lot,
                peremption, psychotrope, type, n_assure_chifa, n_assure_cvm,
                utilisateur, motif, echeance, indice,
                archive, date_archive, utilisateur_validation, archive_trace
            ) VALUES (
                :id, :date, :id_client, :client, :id_nom, :nom, :id_famille, :famille,
                :prix_vente, :qte_sortie, :heure, :prix_achat_ttc, :id_produit, :lot,
                :peremption, :psychotrope, :type, :n_assure_chifa, :n_assure_cvm,
                :utilisateur, :motif, :echeance, :indice,
                FALSE, NULL, NULL, NULL
            )
            ON CONFLICT (id) DO UPDATE SET
                date                   = EXCLUDED.date,
                id_client              = EXCLUDED.id_client,
                client                 = EXCLUDED.client,
                id_nom                 = EXCLUDED.id_nom,
                nom                    = EXCLUDED.nom,
                id_famille             = EXCLUDED.id_famille,
                famille                = EXCLUDED.famille,
                prix_vente             = EXCLUDED.prix_vente,
                qte_sortie             = EXCLUDED.qte_sortie,
                heure                  = EXCLUDED.heure,
                prix_achat_ttc         = EXCLUDED.prix_achat_ttc,
                id_produit             = EXCLUDED.id_produit,
                lot                    = EXCLUDED.lot,
                peremption             = EXCLUDED.peremption,
                psychotrope            = EXCLUDED.psychotrope,
                type                   = EXCLUDED.type,
                n_assure_chifa         = EXCLUDED.n_assure_chifa,
                n_assure_cvm           = EXCLUDED.n_assure_cvm,
                utilisateur            = EXCLUDED.utilisateur,
                motif                  = EXCLUDED.motif,
                echeance               = EXCLUDED.echeance,
                indice                 = EXCLUDED.indice,
                archive                = FALSE,
                date_archive           = NULL,
                utilisateur_validation = NULL,
                archive_trace          = NULL
        """), params)
        synced += 1

    await db.commit()
    logger.info(f"[sync/instance_produits/batch] {synced} actifs upsertés (archive=FALSE)")
    return SyncBatchResult(table="instance_produits", synced=synced)


@router.post("/sync/instance_produits/finalize", response_model=InstanceFinalizeResult)
async def finalize_instance_produits(
    payload: InstanceFinalizePayload,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Outil de récupération manuelle (non appelé par le sync automatique).
    Restaure archive=FALSE pour les IDs passés en active_ids.
    """
    from app.models.pharma import InstanceProduit

    active_ids = payload.active_ids

    res_restored = await db.execute(
        update(InstanceProduit.__table__)
        .where(InstanceProduit.id.in_(active_ids))
        .where(InstanceProduit.archive == True)           # noqa: E712
        .values(archive=False)
    )
    restored = res_restored.rowcount

    await db.commit()
    logger.info(f"[sync/instance_produits/finalize] {restored} restaurés")
    return InstanceFinalizeResult(archived=0, restored=restored)


@router.post("/sync/instance_produits_trt", response_model=SyncBatchResult)
async def sync_instance_produits_trt(
    payload: SyncBatchPayload,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Reçoit les instances traitées depuis HFSQL instance_produits_trt.
    Upsert dans instance_produits avec archive=True et les champs
    archive_trace, date_archive, utilisateur_validation parsés depuis info_trt.
    """
    from datetime import datetime as _dt

    synced = 0
    for rec in payload.records:
        rid = rec.get("id")
        if not rid:
            continue

        # Champs parsés par le sync-agent depuis info_trt
        archive_trace        = rec.get("archive_trace")
        utilisateur_val      = rec.get("utilisateur_validation")
        date_archive_raw     = rec.get("date_archive")

        date_archive_dt = None
        if date_archive_raw:
            try:
                date_archive_dt = _dt.fromisoformat(date_archive_raw)
            except Exception:
                pass

        # Construire les champs standard (même liste que instance_produits)
        standard_fields = {
            k: v for k, v in rec.items()
            if k not in ("archive_trace", "date_archive", "utilisateur_validation")
        }

        await db.execute(text("""
            INSERT INTO instance_produits (
                id, date, id_client, client, id_nom, nom, id_famille, famille,
                prix_vente, qte_sortie, heure, prix_achat_ttc, id_produit, lot,
                peremption, psychotrope, type, n_assure_chifa, n_assure_cvm,
                utilisateur, motif, echeance, indice,
                archive, date_archive, utilisateur_validation, archive_trace
            ) VALUES (
                :id, :date, :id_client, :client, :id_nom, :nom, :id_famille, :famille,
                :prix_vente, :qte_sortie, :heure, :prix_achat_ttc, :id_produit, :lot,
                :peremption, :psychotrope, :type, :n_assure_chifa, :n_assure_cvm,
                :utilisateur, :motif, :echeance, :indice,
                TRUE, :date_archive, :utilisateur_validation, :archive_trace
            )
            ON CONFLICT (id) DO UPDATE SET
                date                   = EXCLUDED.date,
                id_client              = EXCLUDED.id_client,
                client                 = EXCLUDED.client,
                id_nom                 = EXCLUDED.id_nom,
                nom                    = EXCLUDED.nom,
                id_famille             = EXCLUDED.id_famille,
                famille                = EXCLUDED.famille,
                prix_vente             = EXCLUDED.prix_vente,
                qte_sortie             = EXCLUDED.qte_sortie,
                heure                  = EXCLUDED.heure,
                prix_achat_ttc         = EXCLUDED.prix_achat_ttc,
                id_produit             = EXCLUDED.id_produit,
                lot                    = EXCLUDED.lot,
                peremption             = EXCLUDED.peremption,
                psychotrope            = EXCLUDED.psychotrope,
                type                   = EXCLUDED.type,
                n_assure_chifa         = EXCLUDED.n_assure_chifa,
                n_assure_cvm           = EXCLUDED.n_assure_cvm,
                utilisateur            = EXCLUDED.utilisateur,
                motif                  = EXCLUDED.motif,
                echeance               = EXCLUDED.echeance,
                indice                 = EXCLUDED.indice,
                archive                = TRUE,
                date_archive           = COALESCE(EXCLUDED.date_archive, instance_produits.date_archive),
                utilisateur_validation = COALESCE(EXCLUDED.utilisateur_validation, instance_produits.utilisateur_validation),
                archive_trace          = COALESCE(EXCLUDED.archive_trace, instance_produits.archive_trace)
        """), {
            **standard_fields,
            "date_archive":          date_archive_dt,
            "utilisateur_validation": utilisateur_val,
            "archive_trace":          archive_trace,
        })
        synced += 1

    await db.commit()
    logger.info(f"[sync/instance_produits_trt] {synced} enregistrements upsertés")
    return SyncBatchResult(table="instance_produits_trt", synced=synced)


@router.post("/sync/{table_name}", response_model=SyncBatchResult)
async def sync_table(
    table_name: str,
    payload: SyncBatchPayload,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Reçoit un batch d'enregistrements depuis le sync agent et fait un upsert."""
    model = SYNC_REGISTRY.get(table_name)
    if not model:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Table '{table_name}' inconnue. Tables disponibles: {sorted(SYNC_REGISTRY.keys())}",
        )

    if not payload.records:
        return SyncBatchResult(table=table_name, synced=0)

    synced, errors = await _upsert_batch(db, model, payload.records)
    logger.info(f"[sync/{table_name}] {synced} upserts, {errors} erreurs")

    # Post-hook : propager groupware → users après chaque batch groupware
    if table_name == "groupware":
        await _sync_groupware_to_users(db)

    return SyncBatchResult(table=table_name, synced=synced, errors=errors)


@router.get("/sync/status/{table_name}", response_model=SyncStatusResponse)
async def get_sync_status(
    table_name: str,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Retourne le dernier ID synchronisé pour une table."""
    result = await db.execute(
        select(SyncStatus).where(SyncStatus.table_name == table_name)
    )
    status_row = result.scalar_one_or_none()

    if not status_row:
        return SyncStatusResponse(table=table_name, last_id=0, total_synced=0)

    return SyncStatusResponse(
        table=table_name,
        last_id=status_row.last_id,
        total_synced=status_row.total_synced,
    )


@router.post("/sync/status/{table_name}", response_model=SyncStatusResponse)
async def update_sync_status(
    table_name: str,
    payload: SyncStatusUpdate,
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """Met à jour le statut de synchronisation d'une table."""
    stmt = pg_insert(SyncStatus.__table__).values(
        table_name=table_name,
        last_id=payload.last_id,
        total_synced=payload.count,
    )
    stmt = stmt.on_conflict_do_update(
        index_elements=["table_name"],
        set_={
            "last_id": stmt.excluded.last_id,
            "total_synced": SyncStatus.total_synced + payload.count,
        },
    )
    await db.execute(stmt)
    await db.commit()

    return SyncStatusResponse(
        table=table_name,
        last_id=payload.last_id,
        total_synced=payload.count,
    )
