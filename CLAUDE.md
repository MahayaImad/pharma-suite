# Pharma-Suite

Application de gestion RH, pointage, paie variable et commandes pour une
pharmacie d'officine en Algérie. Coexiste avec un logiciel EASYPHARM de stock/trésorerie
existant et avec Chifa Officine (CNAS).

## Commandes

```bash
make dev              # docker compose : api, ml, db
make test             # pytest backend
make api-client       # régénère lib/data/api/generated depuis l'OpenAPI
cd mobile && flutter analyze
cd mobile && flutter test
cd mobile && dart run build_runner build --delete-conflicting-outputs
cd mobile && flutter build apk --release --split-per-abi
```

## Stack

- Backend : FastAPI, SQLAlchemy 2.0 (async), Alembic, Pydantic v2
- penser à un module qui va synchroniser les données EASYPHARM (dataset HyperFileSQL sur pc windows) et tous le reste (backend et frontend sera sur ubuntu).
- encien code copié déja sur schema et models va vous aider a comprendre la base de données essayer de preserver me max de ce code
- DB : PostgreSQL 16 (+ TimescaleDB pour les séries de ventes)
- ML serveur : service séparé dans `ml/`, appelé en HTTP
- ML embarqué : modèles TFLite dans `mobile/assets/models/`
- Front : Flutter 3.x — Android prioritaire, Flutter Web pour l'admin
- État : Riverpod. Navigation : go_router. Local : Drift. Réseau : Dio.

## Architecture Flutter

- Une feature = un dossier dans `lib/features/<nom>/` avec `presentation/`,
  `application/` (providers Riverpod), et rien d'autre.
- `lib/domain/` n'importe jamais `package:flutter`. Logique métier pure, testable.
- Un widget n'appelle jamais Dio ni Drift directement : il passe par un provider.
- Modèles de données : toujours `freezed` + `json_serializable`, jamais de
  classe écrite à la main.
- Chaque écran doit avoir un état vide, un état chargement et un état erreur.
  Utilise `AsyncValue.when` systématiquement.

## Architecture

- Un module = un dossier dans `backend/app/modules/<nom>/` contenant
  `router.py`, `service.py`, `models.py`, `schemas.py`, `repository.py`.
- Les routers ne contiennent aucune logique métier : ils appellent `service.py`.
- Toute écriture en base passe par `repository.py`. Pas de session SQLAlchemy
  dans les routers.
- Le backend n'importe jamais torch/tensorflow. Il appelle `ml/` en HTTP.
- Réponses API : `{ "data": ..., "error": null }` ou `{ "data": null, "error": {...} }`.
- L'UI est mobile-first : concevoir d'abord pour 390px de large.

## Domaine — à lire avant de toucher au métier

- Glossaire et règles métier : @docs/00-domaine.md
- Schéma de données : @docs/01-schema-db.md
- Règles de paie : @docs/03-paie-regles.md
- Intégration Chifa : @docs/02-chifa-integration.md


## Offline-first — non négociable

- L'app doit rester utilisable sans réseau en lecture ET en écriture.
- Toute mutation est d'abord écrite dans Drift, puis empilée dans la table
  `pending_ops` (pattern outbox), puis synchronisée par un worker.
- Chaque mutation porte un `client_uuid` pour l'idempotence côté serveur.
- Ne jamais bloquer l'UI sur un appel réseau.


## Règles non négociables

- Ne modifie JAMAIS le calcul de paie sans ajouter un test de non-régression
  dans `backend/tests/paie/`. La paie est la partie la plus sensible du projet.
- Toute somme d'argent est stockée en `Numeric(12, 2)`, jamais en float.
- Tous les horodatages sont stockés en UTC, affichés en Africa/Algiers.
- Aucune donnée patient/ordonnance ne sort du réseau local vers une API tierce.
  Pour tout traitement d'ordonnance, propose une solution locale (OCR on-premise).
- Ne commite jamais de `.env`, de dump SQL, ni de données réelles d'employés.
- Les migrations sont générées via Alembic, jamais écrites à la main.

## Interdits

- `mobile/lib/data/api/generated/` : régénéré par `make api-client`.
- `mobile/**/*.g.dart` et `*.freezed.dart` : générés par build_runner.

## Étiquette Git

- Branches : `feat/<module>-<sujet>`, `fix/<module>-<sujet>`
- Commits conventionnels (feat:, fix:, chore:), en anglais.
- Un commit = un changement logique.

# Règles de paie

## Part fixe
- Salaire de base par poste : pharmacien assistant = 42000 / préparateur = 35000 / caissier = 40000
- Prime d'ancienneté : 1000 % par année, plafonnée à 15000
- Primes forfaitaires existantes : (transport: 300/jour de travail, panier 600/jour de travail) 

## Part variable — la vraie question
- Enveloppe : montant fixe à répartir, ou % du CA ? Quel montant/pourcentage ? 2% ,1% et 0.5% selon la categorie des produits
- Critères et leur poids (total = 100 %) :
    - CA généré personnellement : 50 %
    - Tâches complétées dans les délais : 30 %
    - Ponctualité : 10 %
    - Autre : 10 %
- Plancher et plafond : un employé peut-il tomber à 0 ?non  Peut-il dépasser X ? oui

## Pointage
- Tolérance de retard avant sanction : 45 minutes
- Arrondi des heures : au quart d'heure
- Heures supplémentaires : majorées de 50 %
- Absence non justifiée : impact sur le fixe 

## Cas limites
- Employé arrivé/parti en cours de mois → au prorata des jours ? oui
- Congé annuel, maladie, jour férié → comptés comme travaillés pour le variable ? oui
- Oubli de badge → qui corrige, et avec quelle trace ? lignes de vente du logiciel
- Contestation d'un employé → qui arbitre, garde-t-on l'historique des recalculs ? oui