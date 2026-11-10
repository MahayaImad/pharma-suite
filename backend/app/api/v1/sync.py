"""
Endpoints génériques de synchronisation.

Le sync agent envoie :
  POST /sync/{table_name}      → upsert batch d'enregistrements
  GET  /sync/status/{table}    → récupérer le dernier ID synchronisé
  POST /sync/status/{table}    → mettre à jour le statut
"""
from typing import Any, List
from datetime import date as PyDate, datetime as PyDatetime, timezone
from decimal import Decimal as PyDecimal, InvalidOperation

from pydantic import BaseModel as PydanticBaseModel
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import (
    func, select, text, update,
    Boolean as SABoolean, Date as SADate, DateTime as SADateTime,
    Integer as SAInteger, Numeric as SANumeric, String as SAString,
)
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession
from loguru import logger

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.sync_status import SyncStatus
from app.schemas.sync import (
    SyncBatchPayload, SyncBatchResult, SyncStatusResponse, SyncStatusUpdate, SyncTableSchema,
)

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


class ValeurInvalide(ValueError):
    """Une valeur source qui ne rentre pas dans le type de la colonne."""


# Formats de date rencontrés côté HFSQL / ADO. L'ordre compte : le format
# ISO strict d'abord, c'est celui que l'agent est censé produire.
_FORMATS_DATE = ("%Y-%m-%d", "%Y%m%d", "%d/%m/%Y", "%d/%m/%y")
# Valeurs « date vide » de WinDev : une date non saisie n'est pas une erreur.
_DATES_VIDES = {"", "00000000", "0000-00-00", "00/00/0000"}


def _parse_date(v: Any) -> PyDate | None:
    """
    Convertit une date source en `datetime.date`.

    Accepte `YYYY-MM-DD`, un horodatage ISO (`2026-08-19T00:00:00`, ce que
    l'agent envoie pour une colonne date HFSQL), `YYYYMMDD` (format natif HFSQL)
    et `DD/MM/YYYY`. Lève `ValeurInvalide` plutôt que de rendre `None` en
    silence : une date perdue ne se voit sinon qu'en aval, dans un KPI.
    """
    if isinstance(v, PyDatetime):
        return v.date()
    if isinstance(v, PyDate):
        return v
    s = str(v).strip()
    if s in _DATES_VIDES:
        return None
    if "T" in s or " " in s:
        try:
            return PyDatetime.fromisoformat(s).date()
        except ValueError:
            pass
    for fmt in _FORMATS_DATE:
        try:
            return PyDatetime.strptime(s, fmt).date()
        except ValueError:
            continue
    raise ValeurInvalide(f"date illisible : {s!r}")


def _parse_datetime(v: Any) -> PyDatetime | None:
    """Horodatage ISO ; une date seule devient minuit UTC."""
    if isinstance(v, PyDatetime):
        dt = v
    else:
        s = str(v).strip()
        if s in _DATES_VIDES:
            return None
        try:
            dt = PyDatetime.fromisoformat(s)
        except ValueError:
            d = _parse_date(s)
            if d is None:
                return None
            dt = PyDatetime(d.year, d.month, d.day)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


def _parse_decimal(v: Any) -> PyDecimal:
    if isinstance(v, PyDecimal):
        return v
    if isinstance(v, float):
        # Un float a déjà perdu sa précision ; on part de sa représentation
        # décimale la plus courte plutôt que de sa valeur binaire exacte.
        return PyDecimal(repr(v))
    try:
        return PyDecimal(str(v).strip().replace(",", "."))
    except InvalidOperation:
        raise ValeurInvalide(f"décimal illisible : {v!r}") from None


def _parse_entier(v: Any) -> int:
    """HFSQL type certains identifiants en décimal : `'123.0000'` → 123."""
    if isinstance(v, bool):
        return int(v)
    if isinstance(v, int):
        return v
    d = _parse_decimal(v)
    if d != d.to_integral_value():
        raise ValeurInvalide(f"entier attendu : {v!r}")
    return int(d)


def _convertisseur(col) -> Any:
    """Choisit la conversion à appliquer selon le type SQLAlchemy de la colonne."""
    t = col.type
    if isinstance(t, SADateTime):
        return _parse_datetime
    if isinstance(t, SADate):
        return _parse_date
    if isinstance(t, SANumeric):
        return _parse_decimal
    if isinstance(t, SAInteger):  # couvre BigInteger et SmallInteger
        return _parse_entier
    if isinstance(t, SABoolean):
        return lambda v: bool(_parse_entier(v))
    if isinstance(t, SAString):
        return lambda v: v if isinstance(v, str) else str(v)
    return None


def _clean_record(record: dict, model, anomalies: list | None = None) -> dict:
    """
    Garde les colonnes connues du modèle et convertit chaque valeur au type
    Python attendu par asyncpg (date, Decimal, int, str).

    Une valeur inconvertible devient `None` et est consignée dans
    `anomalies` — au lieu d'être perdue sans trace.
    """
    colonnes = {col.name: col for col in model.__table__.columns}
    result = {}
    for k, v in record.items():
        col = colonnes.get(k)
        if col is None:
            continue
        if v is None:
            result[k] = None
            continue
        conv = _convertisseur(col)
        if conv is None:
            result[k] = v
            continue
        try:
            result[k] = conv(v)
        except ValeurInvalide as e:
            result[k] = None
            if anomalies is not None:
                anomalies.append({"id": record.get("id"), "colonne": k, "erreur": str(e)})
            continue
        # Texte trop long : PostgreSQL refusera la ligne sans dire quelle
        # colonne déborde. On le dit ici ; la valeur est gardée telle quelle,
        # la ligne sera refusée et rendue dans `rejected`, jamais tronquée.
        longueur = getattr(col.type, "length", None)
        if (anomalies is not None and longueur and isinstance(result[k], str)
                and len(result[k]) > longueur):
            anomalies.append({
                "id": record.get("id"), "colonne": k,
                "erreur": f"trop long pour VARCHAR({longueur}) : {result[k][:40]!r}",
            })
    return result


def _colonnes_ignorees(records: list[dict], model) -> list[str]:
    """Clés envoyées par l'agent qui n'ont pas de colonne côté PostgreSQL."""
    valides = {col.name for col in model.__table__.columns}
    vues: set[str] = set()
    for r in records:
        vues.update(r.keys())
    return sorted(vues - valides)


def _homogeneiser(lignes: list[dict]) -> list[dict]:
    """
    `pg_insert(...).values(lot)` compile ses colonnes depuis la première ligne :
    une clé absente de celle-ci ferait échouer tout le lot. On aligne donc
    toutes les lignes sur l'union des clés.
    """
    cles: list[str] = []
    for ligne in lignes:
        for k in ligne:
            if k not in cles:
                cles.append(k)
    return [{k: ligne.get(k) for k in cles} for ligne in lignes]


def _requete_upsert(model, lignes: list[dict]):
    stmt = pg_insert(model.__table__).values(lignes)
    colonnes_payload = set(lignes[0].keys())
    # Seules les colonnes reçues sont mises à jour : les colonnes
    # PostgreSQL-only (ex. nomenclature.archive) ne sont jamais écrasées.
    update_cols = {
        col.name: stmt.excluded[col.name]
        for col in model.__table__.columns
        if col.name != "id" and col.name in colonnes_payload
    }
    if not update_cols:
        return stmt.on_conflict_do_nothing(index_elements=["id"])
    return stmt.on_conflict_do_update(index_elements=["id"], set_=update_cols)


async def _upsert_batch(
    db: AsyncSession, model, records: list[dict]
) -> tuple[int, int, list[dict], list[dict]]:
    """
    Upsert PostgreSQL (INSERT … ON CONFLICT DO UPDATE), par sous-lots pour
    rester sous la limite de 65 535 paramètres.

    Si un sous-lot échoue, il est rejoué ligne par ligne : les lignes saines
    passent, et chaque ligne rejetée est rendue avec son id et la cause, pour
    que l'agent puisse refuser d'avancer son curseur au lieu de perdre des
    données en silence.

    Returns:
        (synced, errors, rejets, anomalies)
    """
    anomalies: list[dict] = []
    rejets: list[dict] = []

    cleaned = [_clean_record(r, model, anomalies) for r in records]
    cleaned = [r for r in cleaned if r.get("id") is not None]
    sans_id = len(records) - len(cleaned)
    if sans_id:
        rejets.append({"id": None, "erreur": f"{sans_id} ligne(s) sans id"})
    if not cleaned:
        return 0, sans_id, rejets, anomalies

    cleaned = _homogeneiser(cleaned)
    chunk_size = max(1, 65000 // len(cleaned[0]))
    synced = 0

    for i in range(0, len(cleaned), chunk_size):
        chunk = cleaned[i:i + chunk_size]
        try:
            await db.execute(_requete_upsert(model, chunk))
            await db.commit()
            synced += len(chunk)
            continue
        except Exception as e:
            await db.rollback()
            logger.warning(
                f"Upsert {model.__tablename__} : sous-lot {i}–{i + len(chunk)} refusé "
                f"({str(e).splitlines()[0][:200]}), reprise ligne par ligne"
            )

        for ligne in chunk:
            try:
                await db.execute(_requete_upsert(model, [ligne]))
                await db.commit()
                synced += 1
            except Exception as e:
                await db.rollback()
                rejets.append({"id": ligne.get("id"), "erreur": str(e).splitlines()[0][:300]})

    errors = sans_id + sum(1 for r in rejets if r["id"] is not None)
    if rejets:
        logger.error(f"Upsert {model.__tablename__} : {errors} ligne(s) rejetée(s), ex. {rejets[:3]}")
    return synced, errors, rejets, anomalies


def _empaqueter_droits(records: list[dict]) -> list[dict]:
    """
    groupware : les ~300 drapeaux de droits EASYPHARM (ac_*, vnt_*, stk_*…)
    n'ont pas de colonne chacun ; tout ce qui n'est pas une colonne du modèle
    est regroupé dans le JSONB `droits`, au lieu d'être ignoré.
    """
    valides = {col.name for col in Groupware.__table__.columns}
    resultat = []
    for r in records:
        ligne = {k: v for k, v in r.items() if k in valides}
        ligne["droits"] = {k: v for k, v in r.items() if k not in valides} or None
        resultat.append(ligne)
    return resultat


# Les 23 colonnes HFSQL de instance_produits / instance_produits_trt.
_COLONNES_INSTANCE = (
    "id", "date", "id_client", "client", "id_nom", "nom", "id_famille", "famille",
    "prix_vente", "qte_sortie", "heure", "prix_achat_ttc", "id_produit", "lot",
    "peremption", "psychotrope", "type", "n_assure_chifa", "n_assure_cvm",
    "utilisateur", "motif", "echeance", "indice",
)


def _params_instance(rec: dict, anomalies: list) -> dict:
    """
    Paramètres typés pour le SQL brut des deux endpoints instance_produits.

    Toutes les colonnes sont présentes (`None` si absente du payload) : une clé
    manquante ferait sinon échouer tout le lot avec une `StatementError`.
    """
    propre = _clean_record(rec, InstanceProduit, anomalies)
    return {col: propre.get(col) for col in _COLONNES_INSTANCE}


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
    anomalies: list[dict] = []
    rejets: list[dict] = []
    synced = 0
    ignores = 0
    for rec in payload.records:
        if not rec.get("id"):
            ignores += 1
            continue
        params = _params_instance(rec, anomalies)
        try:
            # Point de sauvegarde par ligne : une ligne refusée (texte trop
            # long…) est rendue avec son id au lieu de faire échouer le lot.
            async with db.begin_nested():
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
        except Exception as e:
            rejets.append({"id": rec.get("id"), "erreur": str(e).splitlines()[0][:300]})

    await db.commit()
    logger.info(f"[sync/instance_produits/batch] {synced} actifs upsertés (archive=FALSE)")
    return SyncBatchResult(
        table="instance_produits", synced=synced, errors=ignores + len(rejets),
        rejected=([{"id": None, "erreur": f"{ignores} ligne(s) sans id"}] if ignores else []) + rejets[:50],
        invalid_values=anomalies[:50],
        ignored_columns=_colonnes_ignorees(payload.records, InstanceProduit),
    )


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
    anomalies: list[dict] = []
    rejets: list[dict] = []
    synced = 0
    ignores = 0
    for rec in payload.records:
        if not rec.get("id"):
            ignores += 1
            continue

        # Champs parsés par l'agent depuis info_trt, PostgreSQL-only.
        date_archive_dt = None
        if rec.get("date_archive"):
            try:
                date_archive_dt = _parse_datetime(rec["date_archive"])
            except ValeurInvalide as e:
                anomalies.append({"id": rec["id"], "colonne": "date_archive", "erreur": str(e)})

        try:
            # Point de sauvegarde par ligne : une ligne refusée (texte trop
            # long…) est rendue avec son id au lieu de faire échouer le lot.
            async with db.begin_nested():
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
                    **_params_instance(rec, anomalies),
                    "date_archive":           date_archive_dt,
                    "utilisateur_validation": rec.get("utilisateur_validation"),
                    "archive_trace":          rec.get("archive_trace"),
                })
            synced += 1
        except Exception as e:
            rejets.append({"id": rec.get("id"), "erreur": str(e).splitlines()[0][:300]})

    await db.commit()
    logger.info(f"[sync/instance_produits_trt] {synced} enregistrements upsertés")
    return SyncBatchResult(
        table="instance_produits_trt", synced=synced, errors=ignores + len(rejets),
        rejected=([{"id": None, "erreur": f"{ignores} ligne(s) sans id"}] if ignores else []) + rejets[:50],
        invalid_values=anomalies[:50],
        ignored_columns=_colonnes_ignorees(
            payload.records, InstanceProduit,
        ),
    )


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

    records = payload.records
    if table_name == "groupware":
        records = _empaqueter_droits(records)

    synced, errors, rejets, anomalies = await _upsert_batch(db, model, records)
    ignorees = _colonnes_ignorees(records, model)
    logger.info(f"[sync/{table_name}] {synced} upserts, {errors} erreurs, {len(anomalies)} valeurs invalides")
    if ignorees:
        logger.warning(f"[sync/{table_name}] colonnes sans équivalent PostgreSQL : {ignorees}")

    # Post-hook : propager groupware → users après chaque batch groupware
    if table_name == "groupware":
        await _sync_groupware_to_users(db)

    return SyncBatchResult(
        table=table_name, synced=synced, errors=errors,
        rejected=rejets[:50], invalid_values=anomalies[:50], ignored_columns=ignorees,
    )


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
            # onupdate ne s'applique pas à un ON CONFLICT : sans cette ligne
            # la date restait celle du tout premier lot.
            "last_sync_at": func.now(),
        },
    )
    await db.execute(stmt)
    await db.commit()

    return SyncStatusResponse(
        table=table_name,
        last_id=payload.last_id,
        total_synced=payload.count,
    )


@router.get("/sync/schema", response_model=list[SyncTableSchema])
async def get_sync_schema(
    db: AsyncSession = Depends(get_db),
    _: dict = Depends(get_current_user),
):
    """
    Colonnes attendues et nombre de lignes de chaque table miroir.

    Sert à l'agent (`--verifier`) pour comparer HFSQL et PostgreSQL : colonnes
    HFSQL sans équivalent (perdues à l'import), colonnes PostgreSQL jamais
    alimentées, et écart de volumétrie table par table.
    """
    resultat = []
    for nom, model in sorted(SYNC_REGISTRY.items()):
        total = (await db.execute(select(func.count()).select_from(model.__table__))).scalar()
        resultat.append(SyncTableSchema(
            table=nom,
            columns=[col.name for col in model.__table__.columns],
            count=total or 0,
        ))
    return resultat
