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

Un seul composant : `backend/synergo/` — une API FastAPI, ~98 fichiers Python.

```
backend/synergo/
├── Dockerfile
├── docker-compose.yml        # postgres 16-alpine + api + pgadmin
├── requirements.txt
├── alembic.ini
├── alembic/versions/         # 39 migrations, 001 → 039
└── app/
    ├── main.py               # app FastAPI, logging loguru, scheduler APScheduler
    ├── core/                 # config.py, database.py, security.py
    ├── api/v1/               # 19 routers (~11 500 lignes)
    ├── models/               # 16 modules SQLAlchemy (~1 240 lignes)
    ├── schemas/              # auth.py, sync.py uniquement (38 lignes)
    └── services/             # sms_queue, stock_segmentation, purchase_engine/
```

**N'existe pas** (ne pas y faire référence, ne pas supposer que ça marche) :
`Makefile` · `docs/` · `mobile/` · `ml/` · aucun test, aucun pytest, aucune CI.

## Commandes réelles

```bash
cd backend/synergo
docker compose up -d               # postgres + api + pgadmin
docker compose logs -f api
alembic upgrade head               # migrations
alembic current                    # révision courante
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
- **Migrations écrites à la main**, numérotées séquentiellement
  (`039_...py`, `revision = "039"`, `down_revision = "038"`). Deux styles
  cohabitent : les ops Alembic (`op.create_table`, `op.add_column`) et le SQL
  brut via `conn.execute(sa.text(...))` avec `CREATE TABLE IF NOT EXISTS` /
  `ADD COLUMN IF NOT EXISTS` pour rester idempotentes. Autogenerate n'est pas
  utilisé : suivre le style du voisin et continuer la numérotation.
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

- **`main.py` appelle `Base.metadata.create_all` au démarrage** en plus
  d'Alembic. Les deux mécanismes coexistent : un modèle ajouté crée sa table
  au boot, sans migration. Ne pas s'appuyer là-dessus pour une modification de
  schéma — écrire la migration.
- **`.gitignore` contient `lib/` sans slash initial**, hérité du template
  Python. Ce motif ignorerait `mobile/lib/` en entier le jour où le front
  Flutter arrive. À corriger en `/lib/` avant de créer `mobile/`.
- **CORS `allow_origins=["*"]`** avec `allow_credentials=True` dans `main.py`.
- **`app/core/config.py` porte des secrets par défaut fonctionnels**
  (`secret_key`, `sync_agent_password`). Une clé API Anthropic y a été
  committée en clair dans le commit initial : elle est à révoquer et l'entrée
  doit être vidée et lue depuis `.env`.
- **`_calc_enveloppe_prime` renvoie un `float`** (`performance.py`), alors que
  tout le reste de la chaîne est en `Decimal`.
- **Le chatbot envoie des données à l'API Anthropic** : schéma complet de la
  base, SQL généré et jusqu'à 50 lignes de résultats, sur des tables qui
  contiennent des noms de clients et des instances d'ordonnance. C'est en
  contradiction directe avec la règle de confidentialité ci-dessous — voir
  « Décisions à trancher ».

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
  aujourd'hui — voir « Décisions à trancher ».*
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
- **Code existant.** Le code de `backend/synergo/` encode la connaissance du
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
- **Plancher** : un employé éligible ne peut pas tomber à 0 de part variable.
- **Plafond** : la part variable peut dépasser une cible, il n'y a pas de
  plafond dur.
- **Contestation** : l'historique des recalculs doit être conservé. Seule la
  validation est tracée aujourd'hui (`valide_par`, `valide_le`) ;
  `performance_mensuelle` est unique par (employé, année, mois) et écrase le
  calcul précédent. L'historisation reste à faire.

## ⛔ Décisions à trancher — ne pas implémenter sans réponse

Ces points sont ambigus ou contradictoires. **Demander l'arbitrage avant
d'écrire du code qui en dépend**, ne pas choisir une valeur par défaut.

1. **Prime d'ancienneté.** La formule notée « 1000 % par année, plafonnée à
   15 000 » est incohérente. 1 000 DA par année d'ancienneté, plafond
   15 000 DA (soit 15 ans) ? Ou un pourcentage du salaire de base ?
2. **Taux de prime par catégorie.** La base contient 0,5 / 1 / 3 %
   (migration 038). Une note antérieure mentionnait 2 / 1 / 0,5 %. Laquelle
   fait foi, et à quoi correspond le troisième taux ?
3. **Poids des critères.** Une répartition CA 50 % / tâches 30 % /
   ponctualité 10 % / autre 10 % a été évoquée, mais les poids réels vivent
   dans `kpi_definitions.poids`. Faut-il aligner la base sur cette
   répartition, et que recouvre exactement « autre » ?
4. **Plancher de la part variable.** Un employé ne peut pas tomber à 0 : quel
   est alors le minimum garanti, en montant ou en % de l'enveloppe ?
5. **Absence non justifiée.** L'impact sur la part fixe est acté dans le
   principe, pas dans le calcul. Retenue de 1/30ᵉ par jour, ou autre règle ?
6. **Chatbot et données patient.** Soit la règle de confidentialité
   s'applique et il faut restreindre ou anonymiser ce que `chatbot.py` envoie
   à l'API Anthropic, soit elle est assouplie et il faut l'écrire ici.
7. **Part fixe.** Rien n'est implémenté aujourd'hui : ni salaire de base, ni
   ancienneté, ni transport, ni panier. Seule la part variable existe.

---

## Étiquette Git

- Branches : `feat/<module>-<sujet>`, `fix/<module>-<sujet>`
- Commits conventionnels (`feat:`, `fix:`, `chore:`), rédigés en anglais.
- Un commit = un changement logique.
