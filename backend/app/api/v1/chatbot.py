"""
Chatbot IA — Text-to-SQL avec Claude API
L'utilisateur pose une question en français → Claude génère le SQL →
exécution PostgreSQL → Claude formate la réponse.
"""
import json
import re
from typing import Any

import anthropic
from fastapi import APIRouter, Depends, HTTPException
from loguru import logger
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import get_db
from app.core.security import get_current_user

router = APIRouter(prefix="/chatbot", tags=["chatbot"])

# ── Schéma condensé injecté dans le prompt système ───────────────────────────

_SCHEMA = """
## TABLES DE LA BASE DE DONNÉES (pharmacie algérienne — logiciel PharmaSuite)

─── VENTES ───────────────────────────────────────────────────────────────────

### sorties  (chaque ligne = une transaction de vente/retour)
id BIGINT PK, type VARCHAR(5), date DATE, id_client BIGINT, client VARCHAR,
total_a_payer NUMERIC (montant facturé TTC),
versement NUMERIC (encaissé immédiatement en comptant),
reglement_ult NUMERIC (encaissements ultérieurs),
utilisateur VARCHAR (employé), benefices NUMERIC, majoration NUMERIC,
no_facture_chifa VARCHAR, montant_cnas NUMERIC, montant_assure NUMERIC,
caisse VARCHAR, heure VARCHAR

### sorties_produits  (lignes de détail de chaque vente)
id BIGINT PK, id_sortie BIGINT→sorties.id, date DATE,
id_client BIGINT, client VARCHAR,
id_nom BIGINT→nomenclature.id, nom VARCHAR (produit),
id_famille INT, famille VARCHAR,
prix_vente NUMERIC, qte_sortie BIGINT,
prix_achat_ttc NUMERIC, utilisateur VARCHAR

─── CLIENTS ──────────────────────────────────────────────────────────────────

### clients
id BIGINT PK, client VARCHAR (nom), ventes NUMERIC (total historique),
versements NUMERIC, credit NUMERIC (encours de crédit actuel),
telephone VARCHAR, adresse VARCHAR, ville VARCHAR,
n_assure_chifa VARCHAR, solde_max NUMERIC

### reg_client_association  (paiements partiels de créances clients)
id BIGINT PK, id_vente BIGINT→sorties.id,
tranche NUMERIC (montant partiel encaissé ultérieurement),
date DATE, mode VARCHAR, utilisateur VARCHAR

─── ACHATS / FOURNISSEURS ───────────────────────────────────────────────────

### fournisseurs
id BIGINT PK, fournisseur VARCHAR, solde_actuel NUMERIC,
achats NUMERIC, versements NUMERIC, avoirs NUMERIC

### entrees  (réceptions / factures fournisseur)
id BIGINT PK, type VARCHAR, date DATE,
id_fournisseur BIGINT→fournisseurs.id, fournisseur VARCHAR,
total_a_payer NUMERIC, reglement NUMERIC, echeance DATE,
utilisateur VARCHAR, num_fact VARCHAR, num_bl VARCHAR

### entrees_produits  (lignes de détail de chaque réception)
id BIGINT PK, id_entree BIGINT→entrees.id,
id_nom BIGINT→nomenclature.id, nom VARCHAR,
famille VARCHAR, prix_achat NUMERIC, prix_vente NUMERIC,
qte_entree BIGINT, peremption_date DATE, lot VARCHAR, labo VARCHAR

### reg_fourn_association  (paiements partiels de dettes fournisseurs)
id BIGINT PK, id_entree BIGINT→entrees.id,
tranche NUMERIC (montant partiel payé), date DATE, utilisateur VARCHAR

─── CATALOGUE / STOCK ────────────────────────────────────────────────────────

### nomenclature  (catalogue complet des produits)
id BIGINT PK, nom VARCHAR (dénomination commerciale),
famille VARCHAR, id_famille BIGINT,
stock NUMERIC (stock actuel en boîtes),
prix_vente NUMERIC, prix_achat_moyen NUMERIC,
qte_alerte BIGINT (seuil alerte stock faible),
dci VARCHAR (dénomination commune internationale),
dosage VARCHAR, conditionnement VARCHAR,
forme VARCHAR, labo VARCHAR,
generique SMALLINT (0=princeps 1=générique),
psychotrope SMALLINT (0=non 1=oui),
etagere VARCHAR (responsable de l'étagère),
de_equiv VARCHAR (code équivalent DCI)

### familles
id BIGINT PK, famille VARCHAR

### laboratoires
id BIGINT PK, labo VARCHAR

### nomenclature_classification  (classification pharmaceutique officielle DTC algérienne, hiérarchique)
id INT PK, prefix VARCHAR(10) UNIQUE,
  niveau SMALLINT (1=spécialité médicale, 2=sous-famille),
  designation VARCHAR (libellé officiel)
  -- Hiérarchie : niveau 1 → prefix "NN" ex: "01"=ALLERGOLOGIE, "06"=CARDIOLOGIE
  --              niveau 2 → prefix "NN X" ex: "01 A"=ANTIHISTAMINIQUES, "06 F"=BETA-BLOQUANTS
  -- 25 spécialités (01→25), chacune avec sous-familles
  -- Parent d'une sous-famille : LEFT(prefix, 2) donne le prefix niveau 1
  -- Jointure avec nomenclature : via nomenclature.famille ou nomenclature_classification.prefix IN (famille)

### nomenclature_chifa  (référentiel CNAS remboursable)
id BIGINT PK, nom VARCHAR, tarif_ref NUMERIC (tarif de référence CNAS),
stock NUMERIC, dci VARCHAR, dosage VARCHAR, conditionnement VARCHAR

─── CHIFA / SÉCURITÉ SOCIALE ─────────────────────────────────────────────────

### bordereaux_chifa  (bordereaux de remboursement CNAS)
id BIGINT PK, num_bord VARCHAR (numéro bordereau), centre VARCHAR (centre CNAS),
nbr_fact INT (nombre de factures), mnt_assure NUMERIC (part assuré),
mnt_officine NUMERIC (part officine à rembourser),
mnt_fae NUMERIC (forfait accessoires éducation), mnt_majoration NUMERIC,
mnt_rej NUMERIC (montant rejeté), versement NUMERIC (montant encaissé),
dt_depot DATE, dt_validation DATE, dt_encaisse DATE, dt_cloture DATE,
statut VARCHAR (ex: 'en cours', 'validé', 'encaissé', 'rejeté'), archive SMALLINT

### factures_chifa  (factures individuelles CHIFA)
id BIGINT PK, no_facture VARCHAR, no_assure VARCHAR, date_fact DATE,
mt_assure NUMERIC, mt_officine NUMERIC, mt_maj NUMERIC,
annule SMALLINT (0=active 1=annulée), rej SMALLINT (0=ok 1=rejetée),
no_bordereau_fact VARCHAR→bordereaux_chifa.num_bord

### instance_produits  (ventes CHIFA en attente d'ordonnance)
id BIGINT PK, date DATE, id_client BIGINT, client VARCHAR,
id_nom BIGINT→nomenclature.id, nom VARCHAR,
prix_vente NUMERIC, qte_sortie BIGINT, utilisateur VARCHAR,
archive BOOLEAN (TRUE=clôturée/ordonnance reçue, FALSE=en attente)

─── CAISSE ───────────────────────────────────────────────────────────────────

### operations  (mouvements de caisse individuels)
id BIGINT PK, date DATE, operation VARCHAR, montant NUMERIC,
utilisateur VARCHAR, origine VARCHAR, destinataire VARCHAR,
mode VARCHAR (espèces, chèque, virement…), ref VARCHAR

### suivi_caisses  (récapitulatif par session de caisse)
id BIGINT PK, date_debut DATE, date_fin DATE, caisse VARCHAR,
ventes NUMERIC, retours NUMERIC, total_reel NUMERIC,
versements_clients NUMERIC, versements_fournisseurs NUMERIC,
depenses NUMERIC, alimentations NUMERIC

### depenses  (table de référence : catégories de dépenses)
id BIGINT PK, depense VARCHAR (libellé catégorie)

─── RESSOURCES HUMAINES / PERFORMANCE ───────────────────────────────────────

### employes
id INT PK, username VARCHAR (= groupware.utilisateur),
nom VARCHAR, prenom VARCHAR, poste VARCHAR (ex: Pharmacien, Caissier),
date_entree DATE, actif BOOLEAN, eligible_prime BOOLEAN

### kpi_definitions  (définition des KPIs de performance)
id INT PK, code VARCHAR UNIQUE (ex: 'ca_realise', 'taux_recouvrement'),
libelle VARCHAR, description TEXT, categorie VARCHAR,
unite VARCHAR ('%', 'DA', 'nb', 'score'),
poids NUMERIC (poids en % pour le score global), actif BOOLEAN

### performance_mensuelle  (résultats KPI par employé et par mois)
id INT PK, employe_id INT→employes.id, annee INT, mois INT (1-12),
kpis JSONB (ex: {"ca_realise": {"valeur": 150000, "score": 80}}),
score_global NUMERIC (0-100), pct_prime NUMERIC,
prime_calculee NUMERIC, valide BOOLEAN

### objectifs_mensuels  (objectifs et enveloppe de primes par mois)
id INT PK, annee INT, mois INT, mode_prime VARCHAR ('yoy' ou 'fixe'),
objectif_benefice NUMERIC, pct_enveloppe_prime NUMERIC,
enveloppe_calculee NUMERIC

─── PARAMÉTRAGE ──────────────────────────────────────────────────────────────

### groupware  (comptes utilisateurs du logiciel)
id BIGINT PK, utilisateur VARCHAR, nom VARCHAR, prenom VARCHAR,
role INT (1=admin, autres=rôles limités), actif SMALLINT (1=actif 0=inactif)
"""

_BUSINESS_RULES = """
## RÈGLES MÉTIER IMPORTANTES

1. sorties.type :
   Toutes les lignes ont type = 'V' — ne pas filtrer sur ce champ.
   Un retour client se reconnaît par qte_sortie < 0 dans sorties_produits
   ET total_a_payer < 0 dans sorties (valeurs déjà signées, pas de traitement spécial).
   Pour le CA réel : sommer directement total_a_payer ou qte_sortie * prix_vente
   sans filtre ni signe inversé — les retours se soustraient naturellement.

2. Clients anonymes : id IN (1, 2, 3) → exclure des analyses clients nominatifs.

3. Créance d'une sortie = total_a_payer - versement - COALESCE(SUM(reg_client_association.tranche),0)
   Une créance est impayée si ce résultat > 0.

4. Stock : nomenclature.stock est le stock temps-réel en boîtes.
   Rupture = stock <= 0. Alerte = stock > 0 AND stock < qte_alerte.

5. instance_produits.archive = FALSE → instance en cours (patient attend ordonnance).
   archive = TRUE → clôturée (ordonnance fournie ou annulée).

6. Pour les bénéfices : sorties.benefices + sorties.majoration = marge brute totale.

7. Les dates sont au format DATE PostgreSQL (YYYY-MM-DD).
   Utiliser CURRENT_DATE, DATE_TRUNC, EXTRACT selon les besoins.

8. Toujours ajouter LIMIT 200 sauf si la question porte sur des agrégats (COUNT, SUM, AVG...).

9. nomenclature.de_equiv — code de classification DTC intégré au produit.
   Format : "NNXnnn"  ex: "10A167"
     - NN  (2 chiffres) = numéro de spécialité médicale  → ex: "10" = GASTRO-ENTEROLOGIE
     - X   (1 lettre)   = code de sous-famille            → ex: "A"  = ANTI-ULCEREUX ET ANTI-H2
     - nnn (chiffres)   = numéro séquentiel du produit
   Jointures utiles :
     -- sous-famille (niveau 2) :
        LEFT(n.de_equiv, 2) || ' ' || SUBSTR(n.de_equiv, 3, 1) = nc.prefix
     -- spécialité (niveau 1) :
        LEFT(n.de_equiv, 2) = nc.prefix
   Exemple : de_equiv = '10A167' → nc.prefix '10 A' (ANTI-ULCEREUX) ou '10' (GASTRO-ENTEROLOGIE)
   Note : de_equiv peut être NULL pour les produits non classifiés DTC.

10. Jointure produits ↔ classification DTC :
    Les tables de détail (lignes de ventes, achats, stock) se lient à nomenclature via id_nom,
    puis à nomenclature_classification via de_equiv :

      sorties_produits    sp  JOIN nomenclature n ON n.id = sp.id_nom
      entrees_produits    ep  JOIN nomenclature n ON n.id = ep.id_nom
      instance_produits   ip  JOIN nomenclature n ON n.id = ip.id_nom
      nomenclature_chifa  nc2 JOIN nomenclature n ON n.id = nc2.id  (même id)

    Puis classification niveau 2 : JOIN nomenclature_classification nc
        ON nc.prefix = LEFT(n.de_equiv, 2) || ' ' || SUBSTR(n.de_equiv, 3, 1)
         AND nc.niveau = 2

    Ou classification niveau 1 (spécialité) : JOIN nomenclature_classification nc
        ON nc.prefix = LEFT(n.de_equiv, 2)
         AND nc.niveau = 1

    Exemple — CA par spécialité médicale :
      SELECT nc.designation, SUM(sp.prix_vente * sp.qte_sortie) AS ca
      FROM sorties_produits sp
      JOIN nomenclature n ON n.id = sp.id_nom
      JOIN nomenclature_classification nc ON nc.prefix = LEFT(n.de_equiv, 2) AND nc.niveau = 1
      JOIN sorties s ON s.id = sp.id_sortie
      GROUP BY nc.designation ORDER BY ca DESC;

11. Catégories produits (nomenclature.categorie) :
    - 'princeps'    = médicament de marque (marge basse, labo non générique)
    - 'generique'   = générique (laboratoire marqué is_generique=true dans table laboratoires)
    - 'generique++' = marge moyenne élevée (calculée depuis entrees_produits, lots avec stock > 0)
    Calcul marge lot : (prix_vente - prix_achat) / prix_vente * 100
    Marge moyenne produit : AVG sur tous les lots WHERE stock > 0
    Pour filtrer par catégorie :
      JOIN nomenclature n ON n.id = sp.id_nom WHERE n.categorie = 'generique++'
    Jointure laboratoires génériques :
      JOIN laboratoires l ON LOWER(TRIM(l.labo)) = LOWER(TRIM(n.labo))
      WHERE l.is_generique = true
    Attention : le champ labo est texte libre, toujours normaliser la casse.

12. CHIFA vs vente libre :
    CHIFA = sorties.no_facture_chifa IS NOT NULL AND no_facture_chifa != ''
    Libre = no_facture_chifa IS NULL OR no_facture_chifa = ''
    Les montants CHIFA : montant_cnas (part CNAS) + montant_assure (part patient).

13. Responsable d'une classification (héritage) :
    Une sous-classe (niveau=2) sans employe_id hérite du responsable de sa classe parente (niveau=1).
    Classe parente : nomenclature_classification WHERE niveau=1 AND prefix = LEFT(sc.prefix, 2)
    Employé effectif : COALESCE(sc.employe_id, parent.employe_id)
    Exemple :
      SELECT COALESCE(sc.employe_id, p.employe_id) AS employe_effectif
      FROM nomenclature_classification sc
      LEFT JOIN nomenclature_classification p
             ON p.niveau = 1 AND p.prefix = LEFT(sc.prefix, 2)
      WHERE sc.niveau = 2

14. Périodes péremption — tranches exclusives (pas cumulatives) :
    < 3 mois   : ep.peremption_date > CURRENT_DATE
                 AND ep.peremption_date <= CURRENT_DATE + INTERVAL '90 days'
    3 à 6 mois : ep.peremption_date > CURRENT_DATE + INTERVAL '90 days'
                 AND ep.peremption_date <= CURRENT_DATE + INTERVAL '180 days'
    7 à 9 mois : ep.peremption_date > CURRENT_DATE + INTERVAL '180 days'
                 AND ep.peremption_date <= CURRENT_DATE + INTERVAL '270 days'
    Source : entrees_produits WHERE stock > 0 AND bloque = 0
"""

_SQL_SYSTEM = f"""Tu es un expert SQL PostgreSQL pour une pharmacie algérienne (logiciel PharmaSuite).
Ta SEULE tâche est de générer une requête SELECT PostgreSQL valide et optimisée.

CONTRAINTES ABSOLUES :
- Retourne UNIQUEMENT le SQL brut, sans explications, sans markdown, sans ```sql.
- La requête doit commencer par SELECT ou WITH.
- N'utilise que des tables et colonnes qui existent dans le schéma ci-dessous.
- Ajoute LIMIT 200 sur toute requête qui retourne des lignes (sauf agrégats purs).
- Utilise des alias clairs (AS ca_total, AS nb_ventes, etc.).
- En cas d'ambiguïté, privilégie l'interprétation la plus utile pour un pharmacien.

{_SCHEMA}
{_BUSINESS_RULES}"""

_FORMAT_SYSTEM = """Tu es l'assistant analytique de la pharmacie PharmaSuite.
Tu reçois une question en français, la requête SQL exécutée, et les résultats bruts.
Formule une réponse claire, concise et utile en français.
- Mets en valeur les chiffres importants.
- Si les résultats sont vides, explique ce que cela signifie métier.
- Ne montre pas le SQL dans ta réponse (sauf si l'utilisateur le demande explicitement).
- Sois direct : commence par la réponse, puis les détails si nécessaire.
- Pour les montants, utilise le format "1 234 567 DA"."""


# ── Modèles Pydantic ──────────────────────────────────────────────────────────

class ChatMessage(BaseModel):
    role: str   # "user" | "assistant"
    content: str

class ChatRequest(BaseModel):
    question: str
    history: list[ChatMessage] = []

class ChatResponse(BaseModel):
    answer: str
    sql: str
    rows_count: int
    error: str | None = None


# ── Helpers ───────────────────────────────────────────────────────────────────

_FORBIDDEN = re.compile(
    r'\b(INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|TRUNCATE|GRANT|REVOKE|COPY|EXECUTE)\b',
    re.IGNORECASE,
)

def _validate_sql(sql: str) -> None:
    """Lève ValueError si le SQL n'est pas un SELECT safe."""
    stripped = sql.strip().upper()
    if not (stripped.startswith("SELECT") or stripped.startswith("WITH")):
        raise ValueError("La requête doit commencer par SELECT ou WITH.")
    if _FORBIDDEN.search(sql):
        raise ValueError("Requête non autorisée (modification de données interdite).")


def _serialize(rows: list[dict]) -> str:
    """Sérialise les résultats pour le prompt (Decimal, date, etc.)."""
    return json.dumps(rows, default=str, ensure_ascii=False, indent=None)


def _build_history_messages(history: list[ChatMessage]) -> list[dict]:
    """Garde les 6 derniers échanges pour le contexte."""
    return [{"role": m.role, "content": m.content} for m in history[-6:]]


# ── Endpoint ──────────────────────────────────────────────────────────────────

@router.post("/query", response_model=ChatResponse)
async def chatbot_query(
    req: ChatRequest,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    if not settings.anthropic_api_key:
        raise HTTPException(status_code=503, detail="Clé API Claude non configurée.")

    client = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)

    # ── Étape 1 : générer le SQL ──────────────────────────────────────────────
    history_msgs = _build_history_messages(req.history)
    step1_messages = history_msgs + [{"role": "user", "content": req.question}]

    try:
        sql_response = await client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=1024,
            temperature=0,
            system=_SQL_SYSTEM,
            messages=step1_messages,
        )
        sql = sql_response.content[0].text.strip()
    except Exception as e:
        logger.error(f"Chatbot step1 error: {e}")
        raise HTTPException(status_code=502, detail=f"Erreur Claude API : {e}")

    # ── Validation SQL ────────────────────────────────────────────────────────
    try:
        _validate_sql(sql)
    except ValueError as e:
        return ChatResponse(
            answer=f"Je n'ai pas pu générer une requête sécurisée pour cette question. ({e})",
            sql=sql,
            rows_count=0,
            error=str(e),
        )

    # ── Étape 2 : exécuter le SQL ─────────────────────────────────────────────
    rows: list[dict[str, Any]] = []
    db_error: str | None = None
    try:
        result = await db.execute(text(sql))
        keys = list(result.keys())
        rows = [dict(zip(keys, row)) for row in result.fetchall()]
    except Exception as e:
        db_error = str(e)
        logger.warning(f"Chatbot SQL error: {e}\nSQL: {sql}")

    if db_error:
        # Tenter une correction automatique
        try:
            fix_response = await client.messages.create(
                model="claude-sonnet-4-6",
                max_tokens=1024,
                temperature=0,
                system=_SQL_SYSTEM,
                messages=step1_messages + [
                    {"role": "assistant", "content": sql},
                    {"role": "user", "content": f"Cette requête a produit l'erreur PostgreSQL suivante : {db_error}\nCorrige-la et retourne uniquement le SQL corrigé."},
                ],
            )
            sql = fix_response.content[0].text.strip()
            _validate_sql(sql)
            result = await db.execute(text(sql))
            keys = list(result.keys())
            rows = [dict(zip(keys, row)) for row in result.fetchall()]
            db_error = None
        except Exception as e2:
            logger.error(f"Chatbot SQL correction failed: {e2}")
            return ChatResponse(
                answer="Je n'ai pas réussi à exécuter la requête sur la base de données. Essayez de reformuler votre question.",
                sql=sql,
                rows_count=0,
                error=str(e2),
            )

    # ── Étape 3 : formater la réponse ─────────────────────────────────────────
    results_text = _serialize(rows[:50])  # max 50 lignes dans le prompt
    format_user_content = (
        f"Question : {req.question}\n\n"
        f"SQL exécuté :\n{sql}\n\n"
        f"Résultats ({len(rows)} ligne(s)) :\n{results_text}"
    )

    try:
        format_response = await client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=1024,
            temperature=0.3,
            system=_FORMAT_SYSTEM,
            messages=[{"role": "user", "content": format_user_content}],
        )
        answer = format_response.content[0].text.strip()
    except Exception as e:
        logger.error(f"Chatbot step3 error: {e}")
        answer = f"Requête exécutée ({len(rows)} résultat(s)), mais impossible de formater la réponse."

    return ChatResponse(answer=answer, sql=sql, rows_count=len(rows))
