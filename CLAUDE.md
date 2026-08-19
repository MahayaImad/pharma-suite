# Pharma-Suite

Gestion RH, pointage, paie variable et commandes pour une pharmacie d'officine
en Algérie. Coexiste avec **EASYPHARM** (stock/trésorerie, HyperFileSQL sur PC
Windows) et **Chifa Officine** (CNAS).

---

## ⚠️ Comment lire ce fichier

Il est en deux parties, et la distinction est importante :

- **Partie 1 — État actuel** : ce qui existe réellement dans le dépôt
  aujourd'hui. C'est la vérité terrain. Les conventions décrites ici sont
  celles du code existant : les respecter quand on modifie l'existant.
- **Partie 2 — Cible** : ce qui est prévu mais **n'existe pas encore**. Ne
  jamais supposer qu'un fichier, dossier ou commande de cette partie est
  disponible. Vérifier avant d'utiliser.

En cas de contradiction entre les deux, **l'état actuel gagne** pour le code
existant, la cible gagne pour le code nouveau.

---

# PARTIE 1 — ÉTAT ACTUEL

## Ce que contient le dépôt

Un seul composant : `backend/` — une API FastAPI, ~98 fichiers Python.

```
backend/
├── Dockerfile
├── docker-compose.yml        # postgres 16-alpine + api + pgadmin
├── requirements.txt          # + requirements-dev.txt pour les tests
├── pytest.ini
├── alembic.ini
├── alembic/versions/
│   ├── 001_baseline.py       # migration de référence unique
│   └── baseline/             # schema.sql + seeds.sql
├── tests/paie/               # pytest, sans base : session simulée
└── app/
    ├── main.py               # app FastAPI, logging loguru, scheduler APScheduler
    ├── core/                 # config.py, database.py, security.py
    ├── api/v1/               # 19 routers (~11 500 lignes)
    ├── models/               # 16 modules SQLAlchemy (~1 240 lignes)
    ├── schemas/              # auth.py, sync.py uniquement (38 lignes)
    └── services/             # sms_queue, stock_segmentation, purchase_engine/
```

Le produit s'appelle **PharmaSuite**. Le nom « synergo » est mort : il ne doit
plus apparaître nulle part, sauf dans `SMS_GATEWAY_TOKEN`, dont la valeur est
un contrat avec le boîtier SMS.

**N'existe pas** (ne pas y faire référence, ne pas supposer que ça marche) :
`Makefile` · `docs/` · `mobile/` · `ml/` · aucune CI.

## Commandes réelles

```bash
cd backend
docker compose up -d               # postgres + api + pgadmin
docker compose logs -f api
alembic upgrade head               # schéma (baseline 001)
alembic current                    # révision courante

pip install -r requirements-dev.txt
pytest                             # tests, sans postgres
```

L'API expose `/api/v1/docs` (Swagger) et `/health`.
Il n'y a **pas** de `make dev` / `make test` / `make api-client`.

## Stack réelle

- FastAPI 0.115 · SQLAlchemy 2.0.35 (async, `asyncpg`) · Alembic 1.13 · Pydantic v2
- PostgreSQL 16 (pas de TimescaleDB installé aujourd'hui)
- Auth : JWT `python-jose`, mots de passe `passlib[bcrypt]`
- Logs : `loguru`, avec pont depuis `logging` stdlib
- Scheduler : `apscheduler`, timezone `Africa/Algiers` (segmentation ABC/XYZ mensuelle)
- Calcul : `numpy`, `pandas`, `statsmodels`, `scipy`, `PuLP` (moteur d'achat)
- `anthropic` (SDK) — utilisé par le chatbot texte→SQL

## Conventions du code existant

Ces conventions ne sont pas idéales, mais elles sont cohérentes sur les
19 routers. **Les suivre quand on modifie l'existant**, ne pas réécrire un
router au passage.

- **Un domaine = un fichier** dans `app/api/v1/<domaine>.py`, monté dans
  `app/api/v1/router.py`. Il n'y a pas de couche `service`/`repository` : les
  routers contiennent la logique métier et l'accès base.
- **SQL brut assumé.** Une grande partie des lectures passe par
  `await db.execute(text("""..."""))` avec paramètres nommés, pas par l'ORM.
  Les modèles SQLAlchemy servent surtout au sync et aux écritures.
  **Toujours** passer les valeurs en paramètres liés (`:param`), jamais en
  f-string.
- **Tout est `async def`.** Session via `Depends(get_db)`, auth via
  `Depends(get_current_user)`.
- **Réponses** : dict ou modèle Pydantic renvoyé nu. Il n'y a **pas**
  d'enveloppe `{data, error}` ; les erreurs sont des `HTTPException`.
- **Argent** :
  - tables miroir d'EASYPHARM (`sorties`, `entrees`, `achats`, `caisse`…) →
    `Numeric(15, 4)`, imposé par le format source, ne pas changer ;
  - tables propres au projet (`performance_mensuelle`, `objectifs_mensuels`) →
    `Numeric(14, 2)`.
- **Horodatages** : `DateTime(timezone=True)` + `server_default=func.now()`
  côté modèles ; `datetime.now(timezone.utc)` côté Python. Stockage UTC,
  affichage `Africa/Algiers`.
- **Migrations écrites à la main**, numérotées séquentiellement à partir de la
  baseline (`002_...py`, `revision = "002"`, `down_revision = "001"`). Les ops
  Alembic (`op.create_table`, `op.add_column`) comme le SQL brut via
  `conn.execute(sa.text(...))` sont acceptés. Autogenerate reste inutilisable :
  `alembic/env.py` n'importe que 10 des 16 modules de modèles, donc son
  `target_metadata` est incomplet.
- **`001_baseline.py` ne se rejoue jamais sur une base existante.** Elle fige
  le schéma issu des 39 migrations historiques. Base déjà en service :
  `alembic stamp 001`.
- **Langue** : docstrings, commentaires et noms de colonnes en français ;
  messages de commit en anglais.

## Modules métier existants

| Router | Rôle |
|---|---|
| `auth` | JWT, utilisateurs |
| `sync` | upsert batch générique depuis l'agent EASYPHARM (`POST /sync/{table}`) |
| `dashboard`, `kpis`, `finance` | agrégats CA, marge, trésorerie |
| `stock`, `ventes`, `achats` | miroir des données EASYPHARM |
| `clients`, `crm` | fichier client, relances SMS |
| `chifa` | bordereaux, factures, rejets CNAS |
| `caisse` | opérations, dépenses, comptes |
| `assistant_achat` | moteur de réappro (prévision + optimisation PuLP) |
| `performance` | KPIs employés, enveloppe et primes de rendement |
| `grh_employes` | fiches employés, demandes de congé |
| `grh_presence` | présence mensuelle auto-détectée + overrides manuels |
| `tasks` | tâches assignées aux employés |
| `sms` | passerelle SMS avec file d'attente |
| `chatbot` | question en français → SQL → réponse formatée |

## Pièges connus (ne pas se faire avoir)

- **`crm_clients` et `tasks` n'existent dans aucune migration ni aucun
  modèle**, alors que `crm.py` et `tasks.py` les interrogent. Sur une base
  reconstruite depuis la baseline, ces deux modules échouent. Les tables de
  production ont dû être créées à la main. À reprendre.
- **Sept tables n'ont aucun modèle SQLAlchemy** et ne vivent que par la
  baseline : `demandes_conge`, `historique_stock_jour`, `holidays`,
  `presences_overrides`, `sms_logs`, `task_assignments`, `task_templates`.
  Ne jamais supposer que les modèles décrivent le schéma en entier.
- **CORS `allow_origins=["*"]`** avec `allow_credentials=True` dans `main.py`.
- **`app/core/config.py` porte des secrets par défaut fonctionnels**
  (`secret_key`, `sync_agent_password`). Une clé API Anthropic y a été
  committée en clair dans le commit initial : elle est à révoquer et l'entrée
  doit être vidée et lue depuis `.env`.
- **`_calc_enveloppe_prime` renvoie un `float`** (`performance.py`), alors que
  tout le reste de la chaîne est en `Decimal`.
- **Le score de prime est *distributif*, pas absolu.** `performance.py` calcule
  `score_kpi = (valeur_employé / total_équipe) × poids`, puis
  `part = score / Σ scores`. Trois conséquences contre-intuitives :
  1. `score_global` n'est **pas** une note sur 100 — malgré le commentaire du
     modèle — mais un cumul de parts d'équipe, borné par Σ des poids ;
  2. la somme des poids **n'a pas besoin de faire 100** : le facteur d'échelle
     s'annule à la normalisation (aujourd'hui les 8 KPIs actifs totalisent 95) ;
  3. l'enveloppe est **toujours distribuée en entier**, même si toute l'équipe
     sous-performe. Il n'y a pas de mécanisme d'enveloppe non consommée.
- **Docstring fausse dans `_calc_enveloppe_prime`** : elle annonce
  `'gentype:generique_remb' → generique = 1 AND remb_cvm = 1`, alors que le SQL
  filtre sur `nomenclature.categorie = 'generique++'`.
- **Le chatbot envoie des données à l'API Anthropic** : schéma complet de la
  base, SQL généré et jusqu'à 50 lignes de résultats, sur des tables qui
  contiennent des noms de clients et des instances d'ordonnance. C'est en
  contradiction directe avec la règle de confidentialité ci-dessous —
  **tranché** : voir Partie 4, règle 6. `chatbot.py` n'est pas déployable en
  production tant que ce n'est pas corrigé.

---

# PARTIE 2 — CIBLE (n'existe pas encore)

Tout ce qui suit est une intention d'architecture. **Aucun de ces chemins
n'existe aujourd'hui.** Les créer au fur et à mesure, pas d'un coup.

## Backend cible

- Un module = `backend/app/modules/<nom>/` avec `router.py`, `service.py`,
  `models.py`, `schemas.py`, `repository.py`.
- Les routers n'appellent que `service.py` ; toute écriture passe par
  `repository.py`, aucune session SQLAlchemy dans un router.
- Enveloppe de réponse `{ "data": ..., "error": null }`.
- Le backend n'importe jamais torch/tensorflow : il appelle `ml/` en HTTP.

**Migration depuis l'existant** : appliquer ce découpage aux **nouveaux**
modules uniquement. Ne pas convertir `stock.py` (1 620 lignes) ou
`dashboard.py` (1 294 lignes) sans demande explicite — ce sont des chantiers à
part entière, pas des effets de bord.

## Front Flutter cible

- Flutter 3.x, Android prioritaire, Flutter Web pour l'admin.
- Riverpod (état) · go_router (navigation) · Drift (local) · Dio (réseau).
- Une feature = `mobile/lib/features/<nom>/` avec `presentation/` et
  `application/` (providers Riverpod), rien d'autre.
- `mobile/lib/domain/` n'importe jamais `package:flutter` : logique métier
  pure, testable.
- Un widget n'appelle jamais Dio ni Drift directement, toujours via un provider.
- Modèles : `freezed` + `json_serializable`, jamais de classe écrite à la main.
- Chaque écran a un état vide, un état chargement et un état erreur —
  `AsyncValue.when` systématiquement.
- UI mobile-first : concevoir d'abord pour 390 px de large.
- Générés, ne jamais éditer : `mobile/lib/data/api/generated/`,
  `**/*.g.dart`, `**/*.freezed.dart`.

## Offline-first cible — non négociable une fois le front démarré

- L'app reste utilisable sans réseau en lecture **et** en écriture.
- Toute mutation est écrite d'abord dans Drift, puis empilée dans `pending_ops`
  (pattern outbox), puis synchronisée par un worker.
- Chaque mutation porte un `client_uuid` pour l'idempotence côté serveur.
- Ne jamais bloquer l'UI sur un appel réseau.

## ML cible

- Service séparé `ml/`, appelé en HTTP par le backend.
- Modèles TFLite embarqués dans `mobile/assets/models/`.
- Aujourd'hui le calcul prédictif vit dans `app/services/purchase_engine/`
  (statsmodels/scipy/PuLP), en process.

## Outillage cible

- `Makefile` : `make dev`, `make test`, `make api-client`.
- `backend/tests/` avec pytest, dont `backend/tests/paie/`.
- `docs/00-domaine.md`, `01-schema-db.md`, `02-chifa-integration.md`,
  `03-paie-regles.md`. Tant qu'ils n'existent pas, la référence métier est la
  Partie 3 de ce fichier.

---

# PARTIE 3 — RÈGLES NON NÉGOCIABLES

Valables dans les deux parties, sans exception.

- **Confidentialité patient.** Aucune donnée patient ou d'ordonnance ne sort du
  réseau local vers une API tierce. Pour tout traitement d'ordonnance, proposer
  une solution locale (OCR on-premise). *Le chatbot viole cette règle
  aujourd'hui — correctif spécifié en Partie 4, règle 6.*
- **Secrets.** Ne jamais committer de `.env`, de dump SQL, de données réelles
  d'employés, ni de clé API en dur dans le code.
- **Argent.** Toujours `Numeric`, jamais `float`, ni en base ni dans les
  calculs intermédiaires. Précision : `Numeric(15, 4)` pour les tables miroir
  EASYPHARM, `Numeric(14, 2)` pour les tables propres au projet.
- **Temps.** Stockage UTC, affichage `Africa/Algiers`.
- **Paie.** Ne jamais modifier un calcul de paie ou de prime sans test de
  non-régression. Tant que `backend/tests/paie/` n'existe pas, le créer avec
  la première modification — pas après. La paie est la partie la plus sensible
  du projet.
- **Schéma.** Toute modification de schéma passe par une migration Alembic
  versionnée, jamais par `create_all` seul.
- **Code existant.** Le code de `backend/app/` encode la connaissance du
  schéma EASYPHARM/Chifa. En préserver le maximum : corriger et étendre plutôt
  que réécrire.

---

# PARTIE 4 — DOMAINE : PAIE ET POINTAGE

## Ce qui est déjà implémenté

**Part variable** (`app/api/v1/performance.py`, `app/models/performance.py`) :

- `prime_taux_config` : enveloppe = Σ (CA de la catégorie × `taux_pct`).
  Catégories seedées par la migration 038 :
  Princeps **0,5 %** · Générique **1 %** · Générique++ **3 %**.
  Configurable via `GET/POST/PATCH/DELETE /performance/prime-config`.
- `objectifs_mensuels` : mode `yoy` ou `fixe`, `pct_enveloppe_prime`.
- `kpi_definitions` : les critères et leurs poids (`poids`, en % du score)
  vivent **en base**, pas en dur dans le code. Le total doit faire 100 %.
- `performance_mensuelle` : `kpis` (JSONB), `score_global` /100, `pct_prime`,
  `prime_calculee`, plus `valide` / `valide_par` / `valide_le`.
- `employes.eligible_prime` exclut les comptes non nominatifs.

**Pointage** (`app/api/v1/grh_presence.py`) :

- Présence auto-détectée depuis `sorties.utilisateur` (les lignes de vente font
  foi en cas d'oubli de badge), corrigeable par override manuel horodaté et
  attribué. Statuts : `present`, `absent`, `conge`, `retard`, `maladie`.
- Jours fériés fixes algériens en dur : 1/1, 1/5, 19/6, 5/7, 1/11.

**Fiches employés** (`app/api/v1/grh_employes.py`) : poste, `date_entree`,
ancienneté calculée, demandes de congé avec workflow d'approbation.

## Règles métier convenues

- **Salaires de base par poste** : pharmacien assistant 42 000 · caissier
  40 000 · préparateur 35 000 (DA/mois).
- **Primes forfaitaires** : transport 300 DA/jour travaillé, panier
  600 DA/jour travaillé.
- **Tolérance de retard** avant sanction : 45 minutes.
- **Arrondi des heures** : au quart d'heure.
- **Heures supplémentaires** : majorées de 50 %.
- **Prorata** : employé arrivé ou parti en cours de mois → au prorata des jours.
- **Congé annuel, maladie, jour férié** : comptés comme travaillés pour le
  calcul de la part variable.
- **Plancher** : tout employé éligible et présent reçoit au minimum **50 % de
  la part égalitaire** (`enveloppe ÷ nombre d'éligibles`). Le solde de
  l'enveloppe est distribué au mérite.
- **Plafond** : la part variable peut dépasser une cible, il n'y a pas de
  plafond dur.
- **Contestation** : l'historique des recalculs doit être conservé. Seule la
  validation est tracée aujourd'hui (`valide_par`, `valide_le`) ;
  `performance_mensuelle` est unique par (employé, année, mois) et écrase le
  calcul précédent. L'historisation reste à faire.

## ✅ Règles arbitrées (2026-08-19)

Les sept points laissés ouverts sont tranchés. Ce qui suit fait foi ; en cas de
contradiction avec une note antérieure, **c'est ce fichier qui gagne**.

### 1. Prime d'ancienneté — **1 000 DA par année, plafond 15 000 DA**

Le « 1000 % » était une coquille. Plafond atteint à 15 ans d'ancienneté.
Ancienneté calculée depuis `employes.date_entree`, en années révolues.

### 2. Taux de prime par catégorie — **la base fait foi : 0,5 / 1 / 3 %**

`prime_taux_config` (migration 038) l'emporte sur la note « 2 / 1 / 0,5 % »,
pour deux raisons : c'est la source la plus récente, et c'est la seule
cohérente sur le plan économique — récompenser le générique plus que le
princeps va dans le sens de la substitution générique encouragée par la CNAS.
La note inversait l'incitation.

Le troisième taux, **Générique++ à 3 %**, correspond à la catégorie
`nomenclature.categorie = 'generique++'`, renommée depuis `'promotion'` par la
migration 017 : les génériques aux meilleures conditions commerciales.

Ces taux restent configurables à chaud via `/performance/prime-config` — le
code ne doit jamais les coder en dur.

### 3. Poids des critères — **ajouter tâches et ponctualité, rééquilibrer à 100**

La note (CA 50 / tâches 30 / ponctualité 10 / autre 10) n'était pas
applicable : aucun KPI `tâches` ni `ponctualité` n'existe dans
`kpi_definitions`, alors que les modules `tasks` et `grh_presence` ont les
données. On crée les deux KPIs manquants et on réduit les 8 existants au
prorata :

| Code | Poids | Source |
|---|---|---|
| `ca_realise` | 20 | existant |
| `taches_completees` | 20 | **à créer** — `tasks`, terminées dans les délais |
| `nb_ventes` | 12 | existant |
| `ponctualite` | 10 | **à créer** — `grh_presence`, tolérance 45 min |
| `panier_moyen` | 7 | existant |
| `ca_complement_alim` | 7 | existant |
| `ventes_peremption_3` | 7 | existant |
| `nouveaux_clients` | 7 | existant |
| `clients_recuperes` | 7 | existant |
| `taux_recouvrement` | 3 | existant |
| **Total** | **100** | |

Le total à 100 est une **convention de lisibilité, pas une contrainte du
code** : le scoring étant distributif, le facteur d'échelle s'annule (voir
« Pièges connus »). Les deux nouveaux KPIs doivent être « plus haut = mieux »
et positifs, comme tous les autres, sinon le calcul relatif est faussé.

### 4. Plancher de la part variable — **50 % de la part égalitaire**

```
part_egalitaire = enveloppe / nb_eligibles_presents
plancher_i      = part_egalitaire * 0.5
reste           = enveloppe - Σ plancher_i
prime_i         = plancher_i + (score_i / Σ scores) * reste
```

Le plancher n'est dû qu'aux employés **éligibles et présents** sur le mois. Il
divise mécaniquement par deux l'écart de mérite : c'est le prix à payer pour
la garantie, et c'est assumé.

### 5. Absence non justifiée — **retenue de 1/30ᵉ du salaire de base par jour**

Sur la **part fixe uniquement**, et sur le seul salaire de base. Ni transport
ni panier ne sont retenus : ils sont déjà calculés par jour travaillé, donc
une absence les annule d'elle-même. La part variable n'est pas pénalisée non
plus : un jour d'absence fait mécaniquement baisser les KPIs. Retenir sur les
trois reviendrait à sanctionner trois fois le même jour.

### 6. Chatbot et données patient — **la règle de confidentialité s'applique**

Elle n'est pas assouplie. `chatbot.py` doit cesser d'envoyer à l'API Anthropic
toute donnée nominative : noms de clients, `id_client`, et le contenu de
`instance_produits` (patients en attente d'ordonnance).

Le schéma de la base et le SQL généré peuvent continuer à sortir — ce sont des
métadonnées, pas des données patient. Ce sont **les résultats** qui doivent
être filtrés avant l'étape 3 de formatage. Deux pistes, à arbitrer au moment
de l'implémentation : liste blanche de colonnes autorisées, ou formatage local
des résultats sans troisième appel au modèle.

Tant que ce n'est pas corrigé, considérer `chatbot.py` comme **non déployable
en production**.

### 7. Part fixe — **débloquée, reste à implémenter**

Ce n'était pas un arbitrage mais un chantier, désormais spécifié en entier :

```
part_fixe = salaire_base_poste
          + prime_anciennete            (règle 1)
          + 300 * jours_travailles      (transport)
          + 600 * jours_travailles      (panier)
          - (salaire_base / 30) * jours_absence_injustifiee   (règle 5)
```

Au prorata des jours si l'employé arrive ou part en cours de mois. Congé,
maladie et jour férié comptent comme travaillés pour la part variable — mais
**pas** comme jours ouvrant droit à transport et panier, qui rémunèrent une
présence effective.

Rien de tout cela n'existe aujourd'hui : ni table, ni migration, ni endpoint.

---

## Travaux induits par ces arbitrages

Aucun n'est fait. Dans l'ordre de dépendance :

1. **Créer `backend/tests/paie/`** — préalable non négociable à tout le reste
   (voir Partie 3). La première modification de calcul l'accompagne, pas
   l'inverse.
2. Corriger `_calc_enveloppe_prime` : `Decimal` de bout en bout, plus de
   `float`.
3. Migration : KPIs `taches_completees` et `ponctualite`, plus les nouveaux
   poids du tableau de la règle 3.
4. Implémenter le plancher (règle 4) dans la distribution de `performance.py`.
5. Historiser les recalculs de `performance_mensuelle` (aujourd'hui écrasés).
6. Assainir `chatbot.py` (règle 6).
7. Part fixe (règle 7) : tables, migration, endpoints, calcul.

## Étiquette Git

- Branches : `feat/<module>-<sujet>`, `fix/<module>-<sujet>`
- Commits conventionnels (`feat:`, `fix:`, `chore:`), rédigés en anglais.
- Un commit = un changement logique.
