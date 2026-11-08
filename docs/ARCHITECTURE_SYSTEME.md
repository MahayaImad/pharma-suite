# Architecture Système - Synergo Pharmacy Management avec IA

## Table des matières
1. [Vue d'ensemble](#1-vue-densemble)
2. [Architecture existante](#2-architecture-existante)
3. [Architecture cible](#3-architecture-cible)
4. [Modules fonctionnels](#4-modules-fonctionnels)
5. [Base de données](#5-base-de-données)
6. [APIs REST](#6-apis-rest)
7. [Architecture IA](#7-architecture-ia)
8. [Sécurité](#8-sécurité)
9. [Déploiement](#9-déploiement)
10. [Roadmap](#10-roadmap)

---

## 1. Vue d'ensemble

### 1.1 Objectifs du système

| Objectif | Métrique cible |
|----------|---------------|
| Réduction ruptures stock | -30% |
| Optimisation commandes | -20% coûts |
| Productivité employés | +25% |
| ROI | 150-200% en 2 ans |

### 1.2 Principes architecturaux

```
┌─────────────────────────────────────────────────────────────────┐
│                    PRINCIPES KISS                                │
├─────────────────────────────────────────────────────────────────┤
│ 1. Simplicité > Complexité (code maintenable)                   │
│ 2. Modularité (modules indépendants et testables)               │
│ 3. Évolutivité (ajout de features sans refactoring majeur)      │
│ 4. Réutilisation (composants partagés)                          │
│ 5. Séparation des responsabilités (SRP)                         │
└─────────────────────────────────────────────────────────────────┘
```

### 1.3 Stack technique

| Couche | Technologie | Justification |
|--------|-------------|---------------|
| **Backend** | FastAPI (Python 3.11+) | Async natif, OpenAPI auto, typage fort, performances |
| **Base de données** | PostgreSQL 15 | JSONB, Full-text search, extensions ML |
| **Cache** | Redis 7 | Sessions, cache queries, pub/sub temps réel |
| **ORM** | SQLAlchemy 2.0 | Async support, migrations Alembic |
| **IA/ML** | scikit-learn, TensorFlow | Écosystème Python, modèles pré-entraînés |
| **NLP** | Hugging Face Transformers | RAG, embeddings, LLM local |
| **OCR** | Tesseract + EasyOCR | Open source, multi-langue |
| **Frontend** | React 18 + TypeScript | PWA ready, composants réutilisables |
| **Mobile** | PWA (Workbox) | Installation native-like, offline |
| **Conteneurs** | Docker + Docker Compose | Reproductibilité, isolation |
| **ML Ops** | MLflow | Versioning modèles, tracking expériences |

---

## 2. Architecture existante

### 2.1 État actuel

```
┌──────────────────────────────────────────────────────────────────┐
│                      ARCHITECTURE ACTUELLE                        │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│   ┌─────────────┐         ┌─────────────┐         ┌───────────┐ │
│   │   HFSQL     │ ──────► │   FastAPI   │ ──────► │ PostgreSQL│ │
│   │ (EasyPharm) │  Sync   │   Backend   │         │    DB     │ │
│   └─────────────┘         └─────────────┘         └───────────┘ │
│         │                        │                      │        │
│         ▼                        ▼                      ▼        │
│   ┌─────────────┐         ┌─────────────┐         ┌───────────┐ │
│   │ PHP Legacy  │         │    Redis    │         │  PgAdmin  │ │
│   │  Frontend   │         │    Cache    │         │           │ │
│   └─────────────┘         └─────────────┘         └───────────┘ │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Tables existantes synchronisées

| Table HFSQL | Table PostgreSQL | Description |
|-------------|------------------|-------------|
| `nomenclature` | `products` | Catalogue produits |
| `entrees` | `purchases` | Commandes d'achat |
| `entrees_produits` | `purchase_details` | Lignes d'achat |
| `sorties` | `sales` | Ventes |
| `sorties_produits` | `sale_details` | Lignes de vente |

### 2.3 Points forts à conserver

- ✅ Synchronisation incrémentale ID-based
- ✅ Architecture async FastAPI
- ✅ Modèle KISS simple et maintenable
- ✅ Gestion transactions robuste
- ✅ Logging avec Loguru
- ✅ Docker Compose opérationnel

### 2.4 Points à améliorer

- ⚠️ Pas d'authentification API
- ⚠️ Pas de gestion RH
- ⚠️ Pas d'IA/ML
- ⚠️ Pas de frontend moderne
- ⚠️ Credentials en dur

---

## 3. Architecture cible

### 3.1 Vue globale

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           ARCHITECTURE CIBLE SYNERGO                             │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                            FRONTEND LAYER                                │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐ │   │
│  │  │ React Admin  │  │  PWA Mobile  │  │   Chatbot    │  │  Dashboard  │ │   │
│  │  │   Panel      │  │   Employé    │  │     UI       │  │   KPIs      │ │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └─────────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                        │                                         │
│                                        ▼                                         │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                           API GATEWAY (FastAPI)                          │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐ │   │
│  │  │   Auth   │  │   CORS   │  │Rate Limit│  │  Logging │  │ Metrics  │ │   │
│  │  │   JWT    │  │  Middleware│ │          │  │          │  │Prometheus│ │   │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘  └──────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                        │                                         │
│                                        ▼                                         │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                         BUSINESS SERVICES LAYER                          │   │
│  │                                                                          │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐       │   │
│  │  │    RH      │  │   Stock    │  │  Commandes │  │    CRM     │       │   │
│  │  │  Service   │  │  Service   │  │   Service  │  │  Service   │       │   │
│  │  └────────────┘  └────────────┘  └────────────┘  └────────────┘       │   │
│  │                                                                          │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐       │   │
│  │  │ Pointage   │  │  Salaires  │  │ Analytics  │  │   Sync     │       │   │
│  │  │  Service   │  │  Service   │  │  Service   │  │  Service   │       │   │
│  │  └────────────┘  └────────────┘  └────────────┘  └────────────┘       │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                        │                                         │
│                                        ▼                                         │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                              AI/ML LAYER                                 │   │
│  │                                                                          │   │
│  │  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐            │   │
│  │  │   Prédiction   │  │      RAG       │  │      OCR       │            │   │
│  │  │    Ventes      │  │   Chatbot      │  │  Ordonnances   │            │   │
│  │  │  (Prophet)     │  │ (Embeddings)   │  │ (Tesseract)    │            │   │
│  │  └────────────────┘  └────────────────┘  └────────────────┘            │   │
│  │                                                                          │   │
│  │  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐            │   │
│  │  │  Interactions  │  │   Analytics    │  │  Segmentation  │            │   │
│  │  │Médicamenteuses │  │      RH        │  │    Clients     │            │   │
│  │  │   (Rules DB)   │  │  (Clustering)  │  │   (K-means)    │            │   │
│  │  └────────────────┘  └────────────────┘  └────────────────┘            │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                        │                                         │
│                                        ▼                                         │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                            DATA LAYER                                    │   │
│  │                                                                          │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────┐ │   │
│  │  │  PostgreSQL  │  │    Redis     │  │   Vector DB  │  │   MLflow   │ │   │
│  │  │   (Main)     │  │   (Cache)    │  │  (pgvector)  │  │  (Models)  │ │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘  └────────────┘ │   │
│  │         │                                                               │   │
│  │         ▼                                                               │   │
│  │  ┌──────────────┐                                                       │   │
│  │  │    HFSQL     │  ◄─── Sync bidirectionnel (lecture seule HFSQL)      │   │
│  │  │  (Legacy)    │                                                       │   │
│  │  └──────────────┘                                                       │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Structure des répertoires (cible)

```
synergo/
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py                    # Point d'entrée FastAPI
│   │   │
│   │   ├── api/                       # Endpoints REST
│   │   │   ├── __init__.py
│   │   │   ├── deps.py                # Dépendances (auth, db)
│   │   │   └── v1/
│   │   │       ├── __init__.py
│   │   │       ├── router.py          # Agrégateur routes
│   │   │       ├── auth.py            # Authentification
│   │   │       ├── users.py           # Gestion utilisateurs
│   │   │       ├── employees.py       # Module RH
│   │   │       ├── attendance.py      # Pointage
│   │   │       ├── payroll.py         # Salaires
│   │   │       ├── products.py        # Produits
│   │   │       ├── stock.py           # Stock
│   │   │       ├── orders.py          # Commandes
│   │   │       ├── sales.py           # Ventes
│   │   │       ├── customers.py       # CRM
│   │   │       ├── dashboard.py       # KPIs
│   │   │       ├── sync.py            # Synchronisation
│   │   │       ├── ai_predictions.py  # Prédictions IA
│   │   │       ├── ai_chatbot.py      # Chatbot RAG
│   │   │       └── ai_ocr.py          # OCR ordonnances
│   │   │
│   │   ├── core/                      # Configuration
│   │   │   ├── __init__.py
│   │   │   ├── config.py              # Settings Pydantic
│   │   │   ├── security.py            # JWT, hashing
│   │   │   └── database.py            # Connexions DB
│   │   │
│   │   ├── models/                    # Modèles SQLAlchemy
│   │   │   ├── __init__.py
│   │   │   ├── base.py                # Base déclarative
│   │   │   ├── user.py                # Utilisateurs
│   │   │   ├── employee.py            # Employés
│   │   │   ├── attendance.py          # Pointage
│   │   │   ├── payroll.py             # Salaires
│   │   │   ├── product.py             # Produits
│   │   │   ├── stock.py               # Stock
│   │   │   ├── order.py               # Commandes
│   │   │   ├── sale.py                # Ventes
│   │   │   ├── customer.py            # Clients
│   │   │   └── sync.py                # Sync tracking
│   │   │
│   │   ├── schemas/                   # Schémas Pydantic
│   │   │   ├── __init__.py
│   │   │   ├── user.py
│   │   │   ├── employee.py
│   │   │   ├── attendance.py
│   │   │   ├── payroll.py
│   │   │   ├── product.py
│   │   │   ├── stock.py
│   │   │   ├── order.py
│   │   │   ├── sale.py
│   │   │   ├── customer.py
│   │   │   └── ai.py
│   │   │
│   │   ├── services/                  # Logique métier
│   │   │   ├── __init__.py
│   │   │   ├── auth_service.py
│   │   │   ├── employee_service.py
│   │   │   ├── attendance_service.py
│   │   │   ├── payroll_service.py
│   │   │   ├── stock_service.py
│   │   │   ├── order_service.py
│   │   │   ├── customer_service.py
│   │   │   ├── dashboard_service.py
│   │   │   └── sync_service.py
│   │   │
│   │   ├── ai/                        # Modules IA
│   │   │   ├── __init__.py
│   │   │   ├── predictions/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── sales_forecaster.py
│   │   │   │   ├── stock_optimizer.py
│   │   │   │   └── models/
│   │   │   ├── rag/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── embeddings.py
│   │   │   │   ├── retriever.py
│   │   │   │   └── chatbot.py
│   │   │   ├── ocr/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── prescription_reader.py
│   │   │   │   └── text_extractor.py
│   │   │   ├── pharma/
│   │   │   │   ├── __init__.py
│   │   │   │   ├── interactions.py
│   │   │   │   └── drug_database.py
│   │   │   └── analytics/
│   │   │       ├── __init__.py
│   │   │       ├── hr_analytics.py
│   │   │       └── customer_segmentation.py
│   │   │
│   │   ├── sync/                      # Synchronisation HFSQL
│   │   │   ├── __init__.py
│   │   │   ├── scheduler.py
│   │   │   ├── sync_manager.py
│   │   │   └── transformers/
│   │   │
│   │   └── utils/                     # Utilitaires
│   │       ├── __init__.py
│   │       ├── hfsql_connector.py
│   │       └── helpers.py
│   │
│   ├── alembic/                       # Migrations DB
│   │   ├── versions/
│   │   └── alembic.ini
│   │
│   ├── tests/                         # Tests
│   │   ├── __init__.py
│   │   ├── conftest.py
│   │   ├── test_api/
│   │   ├── test_services/
│   │   └── test_ai/
│   │
│   ├── requirements.txt
│   ├── requirements-dev.txt
│   └── Dockerfile
│
├── frontend/                          # React App
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── services/
│   │   ├── hooks/
│   │   ├── store/
│   │   └── types/
│   ├── public/
│   ├── package.json
│   └── Dockerfile
│
├── ml/                                # ML Pipeline
│   ├── notebooks/
│   ├── training/
│   ├── models/
│   └── mlflow/
│
├── docker/
│   └── docker-compose.yml
│
├── docs/
│   ├── ARCHITECTURE_SYSTEME.md
│   ├── API_REFERENCE.md
│   └── DEPLOYMENT.md
│
└── scripts/
    ├── setup.sh
    └── deploy.sh
```

---

## 4. Modules fonctionnels

### 4.1 Module RH & Pointage

```
┌─────────────────────────────────────────────────────────────────┐
│                      MODULE RH & POINTAGE                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────┐     ┌─────────────────┐                   │
│  │    Employés     │     │    Planning     │                   │
│  │  - Profils      │     │  - Calendrier   │                   │
│  │  - Contrats     │     │  - Rotations    │                   │
│  │  - Documents    │     │  - Congés       │                   │
│  └────────┬────────┘     └────────┬────────┘                   │
│           │                       │                              │
│           ▼                       ▼                              │
│  ┌─────────────────────────────────────────┐                   │
│  │              POINTAGE                    │                   │
│  │  - Pointeuse physique (API)             │                   │
│  │  - Pointage mobile (GPS + photo)        │                   │
│  │  - Validation manager                    │                   │
│  └────────────────────┬────────────────────┘                   │
│                       │                                          │
│                       ▼                                          │
│  ┌─────────────────────────────────────────┐                   │
│  │           CALCUL SALAIRES               │                   │
│  │  - Salaire fixe (contrat)               │                   │
│  │  - Heures supplémentaires               │                   │
│  │  - Primes (objectifs, ancienneté)       │                   │
│  │  - Retenues (absences, avances)         │                   │
│  │  - Cotisations (CNAS, IRG)              │                   │
│  └─────────────────────────────────────────┘                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Entités principales :**

| Entité | Description | Relations |
|--------|-------------|-----------|
| `Employee` | Profil employé | 1:N Attendance, 1:N Payroll |
| `Contract` | Contrat de travail | N:1 Employee |
| `Schedule` | Planning hebdo | N:1 Employee |
| `Attendance` | Pointage | N:1 Employee |
| `Leave` | Congés | N:1 Employee |
| `Payroll` | Fiche de paie | N:1 Employee |
| `Objective` | Objectifs | N:1 Employee |

### 4.2 Module Stock & Commandes

```
┌─────────────────────────────────────────────────────────────────┐
│                   MODULE STOCK & COMMANDES                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │  Products   │    │   Stock     │    │  Suppliers  │         │
│  │  (sync)     │───►│  Levels     │◄───│  (Grossistes│         │
│  └─────────────┘    └──────┬──────┘    └─────────────┘         │
│                            │                                     │
│         ┌──────────────────┼──────────────────┐                 │
│         ▼                  ▼                  ▼                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│  │   Alertes   │    │  Commandes  │    │ Réceptions  │         │
│  │  Ruptures   │    │   Auto      │    │             │         │
│  └─────────────┘    └─────────────┘    └─────────────┘         │
│                            │                                     │
│                            ▼                                     │
│  ┌─────────────────────────────────────────────────────┐       │
│  │              ASSISTANT COMMANDE IA                   │       │
│  │  - Suggestions basées sur historique                │       │
│  │  - Prévision ruptures (7-30 jours)                  │       │
│  │  - Optimisation quantités (coût vs péremption)      │       │
│  │  - Comparaison prix grossistes                      │       │
│  └─────────────────────────────────────────────────────┘       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 4.3 Module CRM Clients

```
┌─────────────────────────────────────────────────────────────────┐
│                        MODULE CRM                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌───────────────────────────────────────────────┐             │
│  │                 FICHE CLIENT                   │             │
│  │  - Informations personnelles                  │             │
│  │  - Numéro CHIFA / Assurance                   │             │
│  │  - Historique achats                          │             │
│  │  - Allergies / Contre-indications             │             │
│  └───────────────────────────────────────────────┘             │
│                            │                                     │
│           ┌────────────────┼────────────────┐                   │
│           ▼                ▼                ▼                   │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐           │
│  │  Patients   │   │   Suivi     │   │ Fidélité    │           │
│  │ Chroniques  │   │ Traitements │   │  Points     │           │
│  └─────────────┘   └─────────────┘   └─────────────┘           │
│                                                                  │
│  ┌───────────────────────────────────────────────┐             │
│  │           SEGMENTATION IA                      │             │
│  │  - Clusters comportementaux                   │             │
│  │  - Scoring valeur client                      │             │
│  │  - Prédiction churn                           │             │
│  └───────────────────────────────────────────────┘             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 4.4 Module Dashboard & Analytics

```
┌─────────────────────────────────────────────────────────────────┐
│                    DASHBOARD & ANALYTICS                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    KPIs TEMPS RÉEL                       │   │
│  │                                                          │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │   │
│  │  │  CA Jour │  │ Marge %  │  │ Stock €  │  │ Alertes │ │   │
│  │  │  15.2K   │  │  28.5%   │  │  125K    │  │   12    │ │   │
│  │  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │   │
│  │                                                          │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │   │
│  │  │Ventes/h  │  │ Panier   │  │ Ruptures │  │Employés │ │   │
│  │  │   45     │  │  Moyen   │  │    8     │  │ Actifs  │ │   │
│  │  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   GRAPHIQUES                             │   │
│  │  - Évolution CA (jour/semaine/mois)                     │   │
│  │  - Top 10 produits vendus                               │   │
│  │  - Répartition CHIFA vs Libre                           │   │
│  │  - Performance employés                                  │   │
│  │  - Prévisions vs Réel                                   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. Base de données

### 5.1 Schémas PostgreSQL

```sql
-- 4 schémas pour séparer les responsabilités
CREATE SCHEMA IF NOT EXISTS synergo_core;      -- Données métier (existant)
CREATE SCHEMA IF NOT EXISTS synergo_sync;      -- Tracking sync (existant)
CREATE SCHEMA IF NOT EXISTS synergo_analytics; -- Analytics (existant)
CREATE SCHEMA IF NOT EXISTS synergo_hr;        -- RH & Pointage (nouveau)
CREATE SCHEMA IF NOT EXISTS synergo_ai;        -- Données IA (nouveau)
```

### 5.2 Modèle de données complet

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           MODÈLE DE DONNÉES                                      │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│  SYNERGO_CORE (existant + extensions)                                           │
│  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐           │
│  │    products     │     │    purchases    │     │     sales       │           │
│  │  (nomenclature) │     │    (entrees)    │     │    (sorties)    │           │
│  └────────┬────────┘     └────────┬────────┘     └────────┬────────┘           │
│           │                       │                       │                      │
│           │              ┌────────┴────────┐     ┌────────┴────────┐           │
│           │              │purchase_details │     │  sale_details   │           │
│           └──────────────┤(entrees_produits│     │(sorties_produits│           │
│                          └─────────────────┘     └─────────────────┘           │
│                                                                                  │
│  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐           │
│  │   suppliers     │     │   stock_levels  │     │   stock_alerts  │           │
│  │  (fournisseurs) │     │  (niveaux stock)│     │    (alertes)    │           │
│  └─────────────────┘     └─────────────────┘     └─────────────────┘           │
│                                                                                  │
│  SYNERGO_HR (nouveau)                                                           │
│  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐           │
│  │   employees     │────►│   attendance    │     │    schedules    │           │
│  │   (employés)    │     │   (pointages)   │     │   (plannings)   │           │
│  └────────┬────────┘     └─────────────────┘     └─────────────────┘           │
│           │                                                                      │
│           │              ┌─────────────────┐     ┌─────────────────┐           │
│           ├─────────────►│    contracts    │     │     leaves      │           │
│           │              │   (contrats)    │     │    (congés)     │           │
│           │              └─────────────────┘     └─────────────────┘           │
│           │                                                                      │
│           │              ┌─────────────────┐     ┌─────────────────┐           │
│           └─────────────►│    payrolls     │     │   objectives    │           │
│                          │ (fiches paie)   │     │   (objectifs)   │           │
│                          └─────────────────┘     └─────────────────┘           │
│                                                                                  │
│  SYNERGO_CRM (nouveau)                                                          │
│  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐           │
│  │   customers     │────►│  prescriptions  │     │loyalty_programs │           │
│  │   (clients)     │     │ (ordonnances)   │     │   (fidélité)    │           │
│  └────────┬────────┘     └─────────────────┘     └─────────────────┘           │
│           │                                                                      │
│           │              ┌─────────────────┐     ┌─────────────────┐           │
│           └─────────────►│chronic_treatments│    │customer_segments│           │
│                          │(traitements chron)│   │  (segments IA)  │           │
│                          └─────────────────┘     └─────────────────┘           │
│                                                                                  │
│  SYNERGO_AI (nouveau)                                                           │
│  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐           │
│  │  ai_predictions │     │  ai_embeddings  │     │drug_interactions│           │
│  │  (prévisions)   │     │   (vecteurs)    │     │ (interactions)  │           │
│  └─────────────────┘     └─────────────────┘     └─────────────────┘           │
│                                                                                  │
│  ┌─────────────────┐     ┌─────────────────┐                                   │
│  │   ml_models     │     │  chat_history   │                                   │
│  │(modèles versionnés)│  │(historique chat)│                                   │
│  └─────────────────┘     └─────────────────┘                                   │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 5.3 Tables détaillées (nouvelles)

#### Module RH

```sql
-- Table employees (employés)
CREATE TABLE synergo_hr.employees (
    id SERIAL PRIMARY KEY,
    employee_code VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20),
    birth_date DATE,
    hire_date DATE NOT NULL,
    position VARCHAR(100) NOT NULL,  -- Pharmacien, Préparateur, Caissier
    department VARCHAR(50),
    photo_url VARCHAR(500),
    nss VARCHAR(20),                  -- Numéro sécurité sociale
    is_active BOOLEAN DEFAULT true,
    user_id INTEGER REFERENCES synergo_core.users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Table contracts (contrats)
CREATE TABLE synergo_hr.contracts (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES synergo_hr.employees(id),
    contract_type VARCHAR(20) NOT NULL,  -- CDI, CDD, Stage
    start_date DATE NOT NULL,
    end_date DATE,
    base_salary DECIMAL(12, 2) NOT NULL,
    weekly_hours INTEGER DEFAULT 40,
    trial_period_end DATE,
    signed_at TIMESTAMP,
    document_url VARCHAR(500),
    is_current BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Table schedules (plannings)
CREATE TABLE synergo_hr.schedules (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES synergo_hr.employees(id),
    week_start DATE NOT NULL,
    monday_start TIME, monday_end TIME,
    tuesday_start TIME, tuesday_end TIME,
    wednesday_start TIME, wednesday_end TIME,
    thursday_start TIME, thursday_end TIME,
    friday_start TIME, friday_end TIME,
    saturday_start TIME, saturday_end TIME,
    sunday_start TIME, sunday_end TIME,
    notes TEXT,
    created_by INTEGER,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(employee_id, week_start)
);

-- Table attendance (pointages)
CREATE TABLE synergo_hr.attendance (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES synergo_hr.employees(id),
    date DATE NOT NULL,
    clock_in TIMESTAMP,
    clock_out TIMESTAMP,
    clock_in_method VARCHAR(20),      -- DEVICE, MOBILE, MANUAL
    clock_out_method VARCHAR(20),
    clock_in_location POINT,          -- GPS coordinates
    clock_out_location POINT,
    clock_in_photo VARCHAR(500),
    break_minutes INTEGER DEFAULT 0,
    overtime_minutes INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'PRESENT',  -- PRESENT, ABSENT, LATE, LEAVE
    validated_by INTEGER,
    validated_at TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(employee_id, date)
);

-- Table leaves (congés)
CREATE TABLE synergo_hr.leaves (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES synergo_hr.employees(id),
    leave_type VARCHAR(30) NOT NULL,  -- ANNUAL, SICK, MATERNITY, UNPAID
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    days_count DECIMAL(4,1) NOT NULL,
    reason TEXT,
    status VARCHAR(20) DEFAULT 'PENDING',  -- PENDING, APPROVED, REJECTED
    approved_by INTEGER,
    approved_at TIMESTAMP,
    document_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Table payrolls (fiches de paie)
CREATE TABLE synergo_hr.payrolls (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES synergo_hr.employees(id),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    base_salary DECIMAL(12, 2) NOT NULL,
    worked_days INTEGER NOT NULL,
    worked_hours DECIMAL(6, 2),
    overtime_hours DECIMAL(6, 2) DEFAULT 0,
    overtime_amount DECIMAL(12, 2) DEFAULT 0,
    bonus_objectives DECIMAL(12, 2) DEFAULT 0,
    bonus_other DECIMAL(12, 2) DEFAULT 0,
    gross_salary DECIMAL(12, 2) NOT NULL,
    -- Cotisations
    cnas_employee DECIMAL(12, 2) DEFAULT 0,  -- 9%
    irg DECIMAL(12, 2) DEFAULT 0,            -- Impôt sur revenu
    other_deductions DECIMAL(12, 2) DEFAULT 0,
    net_salary DECIMAL(12, 2) NOT NULL,
    -- Charges patronales
    cnas_employer DECIMAL(12, 2) DEFAULT 0,   -- 26%
    total_cost DECIMAL(12, 2) NOT NULL,
    payment_date DATE,
    payment_method VARCHAR(20),  -- BANK, CASH, CHECK
    status VARCHAR(20) DEFAULT 'DRAFT',  -- DRAFT, VALIDATED, PAID
    validated_by INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Table objectives (objectifs)
CREATE TABLE synergo_hr.objectives (
    id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES synergo_hr.employees(id),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    objective_type VARCHAR(30) NOT NULL,  -- SALES, ATTENDANCE, CUSTOM
    target_value DECIMAL(12, 2) NOT NULL,
    achieved_value DECIMAL(12, 2) DEFAULT 0,
    bonus_amount DECIMAL(12, 2),
    achievement_rate DECIMAL(5, 2),
    status VARCHAR(20) DEFAULT 'ACTIVE',  -- ACTIVE, COMPLETED, CANCELLED
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
```

#### Module CRM

```sql
-- Table customers (clients)
CREATE TABLE synergo_core.customers (
    id SERIAL PRIMARY KEY,
    hfsql_id INTEGER UNIQUE,
    customer_code VARCHAR(20) UNIQUE,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    full_name VARCHAR(200),
    phone VARCHAR(20),
    email VARCHAR(255),
    address TEXT,
    city VARCHAR(100),
    birth_date DATE,
    gender VARCHAR(10),
    -- Assurance
    chifa_number VARCHAR(30),
    insurance_type VARCHAR(50),
    coverage_percent DECIMAL(5, 2),
    -- Médical
    allergies TEXT[],                 -- Array des allergies
    chronic_conditions TEXT[],        -- Maladies chroniques
    -- Fidélité
    loyalty_points INTEGER DEFAULT 0,
    total_purchases DECIMAL(14, 2) DEFAULT 0,
    visit_count INTEGER DEFAULT 0,
    last_visit_date DATE,
    -- Segmentation IA
    segment VARCHAR(50),              -- VIP, REGULAR, OCCASIONAL, CHRONIC
    lifetime_value DECIMAL(14, 2),
    churn_risk DECIMAL(5, 2),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Table chronic_treatments (traitements chroniques)
CREATE TABLE synergo_core.chronic_treatments (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES synergo_core.customers(id),
    product_id INTEGER REFERENCES synergo_core.products(id),
    condition_name VARCHAR(200),      -- Diabète, Hypertension, etc.
    dosage VARCHAR(100),
    frequency VARCHAR(100),           -- 1x/jour, 2x/jour
    start_date DATE,
    end_date DATE,
    prescribing_doctor VARCHAR(200),
    renewal_date DATE,
    is_active BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
```

#### Module IA

```sql
-- Extension pgvector pour embeddings
CREATE EXTENSION IF NOT EXISTS vector;

-- Table ai_predictions (prévisions)
CREATE TABLE synergo_ai.ai_predictions (
    id SERIAL PRIMARY KEY,
    prediction_type VARCHAR(50) NOT NULL,  -- SALES, STOCK, DEMAND
    target_entity VARCHAR(50),             -- product_id, category, global
    target_id INTEGER,
    prediction_date DATE NOT NULL,
    predicted_value DECIMAL(14, 2),
    confidence_score DECIMAL(5, 4),
    actual_value DECIMAL(14, 2),           -- Rempli après
    model_version VARCHAR(50),
    features_used JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Table ai_embeddings (vecteurs pour RAG)
CREATE TABLE synergo_ai.ai_embeddings (
    id SERIAL PRIMARY KEY,
    entity_type VARCHAR(50) NOT NULL,  -- PRODUCT, FAQ, DOCUMENT
    entity_id INTEGER,
    content TEXT NOT NULL,
    embedding vector(384),              -- Dimension pour all-MiniLM-L6-v2
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Index pour recherche vectorielle
CREATE INDEX idx_embeddings_vector ON synergo_ai.ai_embeddings
USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- Table drug_interactions (interactions médicamenteuses)
CREATE TABLE synergo_ai.drug_interactions (
    id SERIAL PRIMARY KEY,
    drug_a_code VARCHAR(20) NOT NULL,  -- Code CIP ou DCI
    drug_a_name VARCHAR(200),
    drug_b_code VARCHAR(20) NOT NULL,
    drug_b_name VARCHAR(200),
    severity VARCHAR(20) NOT NULL,      -- MINOR, MODERATE, SEVERE, CONTRAINDICATED
    description TEXT,
    mechanism TEXT,
    recommendation TEXT,
    source VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(drug_a_code, drug_b_code)
);

-- Table chat_history (historique conversations)
CREATE TABLE synergo_ai.chat_history (
    id SERIAL PRIMARY KEY,
    session_id UUID NOT NULL,
    user_id INTEGER,
    role VARCHAR(20) NOT NULL,         -- USER, ASSISTANT, SYSTEM
    content TEXT NOT NULL,
    tokens_used INTEGER,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Table ml_models (versioning modèles)
CREATE TABLE synergo_ai.ml_models (
    id SERIAL PRIMARY KEY,
    model_name VARCHAR(100) NOT NULL,
    model_type VARCHAR(50) NOT NULL,    -- PROPHET, SKLEARN, TENSORFLOW
    version VARCHAR(20) NOT NULL,
    metrics JSONB,                       -- MAE, RMSE, accuracy
    parameters JSONB,
    file_path VARCHAR(500),
    is_active BOOLEAN DEFAULT false,
    trained_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(model_name, version)
);
```

---

## 6. APIs REST

### 6.1 Structure générale

```
Base URL: /api/v1

Authentication:
  POST   /auth/login           → JWT token
  POST   /auth/refresh         → Refresh token
  POST   /auth/logout          → Invalidate token

Users:
  GET    /users/me             → Current user profile
  PUT    /users/me             → Update profile
  GET    /users                → List users (admin)
  POST   /users                → Create user (admin)

Employees (RH):
  GET    /employees            → List employees
  POST   /employees            → Create employee
  GET    /employees/{id}       → Get employee
  PUT    /employees/{id}       → Update employee
  DELETE /employees/{id}       → Deactivate employee
  GET    /employees/{id}/attendance → Employee attendance
  GET    /employees/{id}/payrolls   → Employee payrolls

Attendance (Pointage):
  GET    /attendance           → List attendance records
  POST   /attendance/clock-in  → Clock in
  POST   /attendance/clock-out → Clock out
  PUT    /attendance/{id}      → Update/validate attendance
  GET    /attendance/report    → Attendance report

Payroll (Salaires):
  GET    /payroll              → List payrolls
  POST   /payroll/generate     → Generate payroll period
  GET    /payroll/{id}         → Get payroll details
  PUT    /payroll/{id}         → Update payroll
  POST   /payroll/{id}/validate → Validate payroll
  GET    /payroll/export       → Export payroll (PDF/Excel)

Products:
  GET    /products             → List products (paginated)
  GET    /products/{id}        → Get product
  GET    /products/search      → Search products
  GET    /products/low-stock   → Products below threshold

Stock:
  GET    /stock                → Stock levels
  GET    /stock/alerts         → Stock alerts
  GET    /stock/expiring       → Products expiring soon
  POST   /stock/adjust         → Manual adjustment

Orders (Commandes):
  GET    /orders               → List orders
  POST   /orders               → Create order
  GET    /orders/{id}          → Get order details
  PUT    /orders/{id}          → Update order
  POST   /orders/{id}/receive  → Receive order
  GET    /orders/suggestions   → AI-suggested orders

Sales:
  GET    /sales                → List sales
  GET    /sales/{id}           → Get sale details
  GET    /sales/stats          → Sales statistics

Customers (CRM):
  GET    /customers            → List customers
  POST   /customers            → Create customer
  GET    /customers/{id}       → Get customer
  PUT    /customers/{id}       → Update customer
  GET    /customers/{id}/history → Purchase history
  GET    /customers/segments   → Customer segments

Dashboard:
  GET    /dashboard/kpis       → Real-time KPIs
  GET    /dashboard/charts     → Chart data
  GET    /dashboard/alerts     → Active alerts
  WS     /dashboard/live       → WebSocket live updates

AI - Predictions:
  GET    /ai/predictions/sales     → Sales forecast
  GET    /ai/predictions/stock     → Stock predictions
  POST   /ai/predictions/train     → Trigger model training

AI - Chatbot:
  POST   /ai/chat                  → Chat message
  GET    /ai/chat/history          → Chat history
  POST   /ai/chat/feedback         → Feedback on response

AI - OCR:
  POST   /ai/ocr/prescription      → Process prescription image
  GET    /ai/ocr/{id}              → Get OCR result

AI - Pharma:
  POST   /ai/interactions/check    → Check drug interactions
  GET    /ai/interactions/{drug}   → Get drug interactions

Sync:
  GET    /sync/status          → Sync status
  POST   /sync/trigger         → Manual sync
  GET    /sync/logs            → Sync history
```

### 6.2 Exemples de endpoints détaillés

```python
# backend/app/api/v1/employees.py

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Optional
from app.api.deps import get_db, get_current_user
from app.schemas.employee import (
    EmployeeCreate,
    EmployeeUpdate,
    EmployeeResponse,
    EmployeeListResponse
)
from app.services.employee_service import EmployeeService

router = APIRouter(prefix="/employees", tags=["employees"])

@router.get("", response_model=EmployeeListResponse)
async def list_employees(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    is_active: Optional[bool] = None,
    department: Optional[str] = None,
    search: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """
    Liste des employés avec filtres et pagination.

    - **skip**: Nombre d'enregistrements à sauter
    - **limit**: Nombre max d'enregistrements
    - **is_active**: Filtrer par statut actif
    - **department**: Filtrer par département
    - **search**: Recherche par nom
    """
    service = EmployeeService(db)
    employees, total = await service.get_employees(
        skip=skip,
        limit=limit,
        is_active=is_active,
        department=department,
        search=search
    )
    return EmployeeListResponse(
        items=employees,
        total=total,
        skip=skip,
        limit=limit
    )

@router.post("", response_model=EmployeeResponse, status_code=201)
async def create_employee(
    employee_data: EmployeeCreate,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Créer un nouvel employé."""
    service = EmployeeService(db)
    return await service.create_employee(employee_data)

@router.get("/{employee_id}", response_model=EmployeeResponse)
async def get_employee(
    employee_id: int,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Récupérer un employé par ID."""
    service = EmployeeService(db)
    employee = await service.get_employee(employee_id)
    if not employee:
        raise HTTPException(status_code=404, detail="Employé non trouvé")
    return employee

@router.get("/{employee_id}/attendance")
async def get_employee_attendance(
    employee_id: int,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user)
):
    """Historique de pointage d'un employé."""
    service = EmployeeService(db)
    return await service.get_attendance_history(
        employee_id,
        start_date,
        end_date
    )
```

### 6.3 Schémas Pydantic

```python
# backend/app/schemas/employee.py

from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import date, datetime
from enum import Enum

class ContractType(str, Enum):
    CDI = "CDI"
    CDD = "CDD"
    STAGE = "STAGE"

class Position(str, Enum):
    PHARMACIEN = "Pharmacien"
    PREPARATEUR = "Préparateur"
    CAISSIER = "Caissier"
    GESTIONNAIRE = "Gestionnaire"

# Base schema
class EmployeeBase(BaseModel):
    first_name: str = Field(..., min_length=2, max_length=100)
    last_name: str = Field(..., min_length=2, max_length=100)
    email: Optional[EmailStr] = None
    phone: Optional[str] = Field(None, pattern=r"^[0-9+\s-]{10,20}$")
    birth_date: Optional[date] = None
    position: Position
    department: Optional[str] = None
    nss: Optional[str] = None

# Create schema
class EmployeeCreate(EmployeeBase):
    hire_date: date
    contract_type: ContractType
    base_salary: float = Field(..., gt=0)

# Update schema
class EmployeeUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    position: Optional[Position] = None
    department: Optional[str] = None
    is_active: Optional[bool] = None

# Response schema
class EmployeeResponse(EmployeeBase):
    id: int
    employee_code: str
    hire_date: date
    is_active: bool
    photo_url: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# List response with pagination
class EmployeeListResponse(BaseModel):
    items: List[EmployeeResponse]
    total: int
    skip: int
    limit: int
```

---

## 7. Architecture IA

### 7.1 Vue d'ensemble des modules IA

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           ARCHITECTURE IA                                        │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                    IA PRÉDICTIVE (MVP Phase 1)                           │   │
│  │                                                                          │   │
│  │  ┌─────────────────┐                      ┌─────────────────┐           │   │
│  │  │ Prophet/ARIMA   │                      │ scikit-learn    │           │   │
│  │  │ Prévision ventes│                      │ Stock optimizer │           │   │
│  │  └────────┬────────┘                      └────────┬────────┘           │   │
│  │           │                                        │                     │   │
│  │           ▼                                        ▼                     │   │
│  │  ┌─────────────────────────────────────────────────────────┐            │   │
│  │  │              PIPELINE ML (MLflow)                        │            │   │
│  │  │  Data → Features → Training → Evaluation → Deploy        │            │   │
│  │  └─────────────────────────────────────────────────────────┘            │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                 IA CONVERSATIONNELLE (Phase 2)                           │   │
│  │                                                                          │   │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐     │   │
│  │  │   User Query    │───►│   Retriever     │───►│    Generator    │     │   │
│  │  │                 │    │  (pgvector)     │    │   (LLM local)   │     │   │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────┘     │   │
│  │                                                                          │   │
│  │  Architecture RAG:                                                       │   │
│  │  1. Embedding query → vecteur 384 dims                                  │   │
│  │  2. Recherche similarité dans pgvector                                  │   │
│  │  3. Contexte pertinent + query → LLM                                    │   │
│  │  4. Réponse générée                                                     │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                    IA PHARMACEUTIQUE (Phase 2)                           │   │
│  │                                                                          │   │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐     │   │
│  │  │  OCR Engine     │    │  NLP Pipeline   │    │ Drug Interaction│     │   │
│  │  │  (Tesseract)    │───►│ (spaCy/BERT)    │───►│    Checker      │     │   │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────┘     │   │
│  │                                                                          │   │
│  │  Pipeline OCR Ordonnance:                                               │   │
│  │  1. Image preprocessing (deskew, denoise)                               │   │
│  │  2. OCR text extraction                                                 │   │
│  │  3. NER: extraction médicaments, dosages, quantités                     │   │
│  │  4. Mapping vers base produits                                          │   │
│  │  5. Vérification interactions                                           │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                    IA ANALYTIQUE RH (Phase 3)                            │   │
│  │                                                                          │   │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐     │   │
│  │  │  Performance    │    │   Turnover      │    │   Anomaly       │     │   │
│  │  │   Scoring       │    │   Prediction    │    │   Detection     │     │   │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────┘     │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 7.2 Module Prédiction Ventes

```python
# backend/app/ai/predictions/sales_forecaster.py

from prophet import Prophet
import pandas as pd
from datetime import datetime, timedelta
from typing import List, Dict, Optional
from sqlalchemy.ext.asyncio import AsyncSession

class SalesForecaster:
    """
    Prévision des ventes avec Prophet.

    Avantages Prophet:
    - Gère automatiquement saisonnalité (jour, semaine, année)
    - Robuste aux données manquantes
    - Facile à interpréter
    - Bon pour séries temporelles business

    Inconvénients:
    - Moins précis pour patterns complexes
    - Nécessite au moins 2 ans de données idéalement
    """

    def __init__(self, db: AsyncSession):
        self.db = db
        self.model = None

    async def prepare_data(
        self,
        product_id: Optional[int] = None,
        category: Optional[str] = None,
        start_date: Optional[datetime] = None
    ) -> pd.DataFrame:
        """
        Prépare les données pour Prophet.
        Format requis: colonnes 'ds' (date) et 'y' (valeur)
        """
        query = """
            SELECT
                DATE(sale_date) as ds,
                SUM(total_amount) as y
            FROM synergo_core.sales
            WHERE 1=1
        """
        params = {}

        if product_id:
            query += " AND id IN (SELECT sale_id FROM sale_details WHERE product_id = :product_id)"
            params['product_id'] = product_id

        if start_date:
            query += " AND sale_date >= :start_date"
            params['start_date'] = start_date

        query += " GROUP BY DATE(sale_date) ORDER BY ds"

        result = await self.db.execute(query, params)
        df = pd.DataFrame(result.fetchall(), columns=['ds', 'y'])
        return df

    def train(self, df: pd.DataFrame) -> None:
        """
        Entraîne le modèle Prophet.
        """
        self.model = Prophet(
            yearly_seasonality=True,
            weekly_seasonality=True,
            daily_seasonality=False,
            seasonality_mode='multiplicative',
            changepoint_prior_scale=0.05  # Régularisation
        )

        # Ajouter jours fériés algériens
        self.model.add_country_holidays(country_name='DZ')

        self.model.fit(df)

    def predict(self, periods: int = 30) -> pd.DataFrame:
        """
        Génère les prévisions.

        Args:
            periods: Nombre de jours à prédire

        Returns:
            DataFrame avec colonnes: ds, yhat, yhat_lower, yhat_upper
        """
        if not self.model:
            raise ValueError("Modèle non entraîné")

        future = self.model.make_future_dataframe(periods=periods)
        forecast = self.model.predict(future)

        return forecast[['ds', 'yhat', 'yhat_lower', 'yhat_upper']].tail(periods)

    async def get_forecast(
        self,
        days: int = 30,
        product_id: Optional[int] = None
    ) -> List[Dict]:
        """
        Pipeline complet de prévision.
        """
        # Préparer données (derniers 2 ans)
        start_date = datetime.now() - timedelta(days=730)
        df = await self.prepare_data(product_id=product_id, start_date=start_date)

        if len(df) < 30:
            raise ValueError("Données insuffisantes pour prédiction")

        # Entraîner et prédire
        self.train(df)
        forecast = self.predict(periods=days)

        # Formater résultat
        return [
            {
                "date": row['ds'].strftime('%Y-%m-%d'),
                "predicted_value": round(row['yhat'], 2),
                "lower_bound": round(row['yhat_lower'], 2),
                "upper_bound": round(row['yhat_upper'], 2),
                "confidence": 0.95
            }
            for _, row in forecast.iterrows()
        ]
```

### 7.3 Module RAG Chatbot

```python
# backend/app/ai/rag/chatbot.py

from sentence_transformers import SentenceTransformer
from typing import List, Dict, Optional
import numpy as np
from sqlalchemy.ext.asyncio import AsyncSession

class PharmaChatbot:
    """
    Chatbot RAG (Retrieval-Augmented Generation) pour pharmacie.

    Architecture:
    1. Embedding model: all-MiniLM-L6-v2 (léger, rapide, 384 dims)
    2. Vector store: pgvector (intégré PostgreSQL)
    3. LLM: Mistral 7B local ou API Claude/GPT

    Avantages RAG:
    - Réponses basées sur données réelles de la pharmacie
    - Pas d'hallucination (grounded)
    - Mise à jour facile (réindexation)
    - Coût contrôlé (LLM local possible)
    """

    def __init__(self, db: AsyncSession):
        self.db = db
        self.encoder = SentenceTransformer('all-MiniLM-L6-v2')

    def embed_text(self, text: str) -> List[float]:
        """Génère l'embedding d'un texte."""
        return self.encoder.encode(text).tolist()

    async def index_products(self) -> int:
        """
        Indexe tous les produits dans la base vectorielle.
        À exécuter périodiquement (cron job).
        """
        # Récupérer produits
        query = """
            SELECT id, name, family, laboratory,
                   COALESCE(description, '') as description
            FROM synergo_core.products
            WHERE is_active = true
        """
        result = await self.db.execute(query)
        products = result.fetchall()

        count = 0
        for product in products:
            # Créer texte à indexer
            content = f"""
            Produit: {product.name}
            Famille: {product.family}
            Laboratoire: {product.laboratory}
            {product.description}
            """

            # Générer embedding
            embedding = self.embed_text(content)

            # Insérer ou mettre à jour
            upsert_query = """
                INSERT INTO synergo_ai.ai_embeddings
                (entity_type, entity_id, content, embedding, metadata)
                VALUES ('PRODUCT', :entity_id, :content, :embedding, :metadata)
                ON CONFLICT (entity_type, entity_id)
                DO UPDATE SET content = :content, embedding = :embedding
            """
            await self.db.execute(upsert_query, {
                'entity_id': product.id,
                'content': content,
                'embedding': embedding,
                'metadata': {'name': product.name, 'family': product.family}
            })
            count += 1

        await self.db.commit()
        return count

    async def retrieve_context(
        self,
        query: str,
        top_k: int = 5,
        entity_type: str = 'PRODUCT'
    ) -> List[Dict]:
        """
        Recherche les documents les plus pertinents.
        Utilise la similarité cosinus via pgvector.
        """
        query_embedding = self.embed_text(query)

        search_query = """
            SELECT
                entity_id,
                content,
                metadata,
                1 - (embedding <=> :embedding) as similarity
            FROM synergo_ai.ai_embeddings
            WHERE entity_type = :entity_type
            ORDER BY embedding <=> :embedding
            LIMIT :top_k
        """

        result = await self.db.execute(search_query, {
            'embedding': query_embedding,
            'entity_type': entity_type,
            'top_k': top_k
        })

        return [
            {
                'entity_id': row.entity_id,
                'content': row.content,
                'metadata': row.metadata,
                'similarity': round(row.similarity, 4)
            }
            for row in result.fetchall()
        ]

    async def generate_response(
        self,
        user_query: str,
        context: List[Dict],
        llm_provider: str = 'local'
    ) -> str:
        """
        Génère une réponse basée sur le contexte récupéré.
        """
        # Construire le prompt
        context_text = "\n---\n".join([doc['content'] for doc in context])

        prompt = f"""Tu es un assistant pharmaceutique expert.
Réponds à la question en te basant UNIQUEMENT sur le contexte fourni.
Si l'information n'est pas dans le contexte, dis-le clairement.

CONTEXTE:
{context_text}

QUESTION: {user_query}

RÉPONSE:"""

        # Appeler le LLM (exemple avec API locale)
        if llm_provider == 'local':
            # Utiliser Ollama ou vLLM local
            response = await self._call_local_llm(prompt)
        else:
            # Utiliser API externe
            response = await self._call_external_llm(prompt, llm_provider)

        return response

    async def chat(self, user_query: str, session_id: str) -> Dict:
        """
        Pipeline complet de chat.
        """
        # 1. Récupérer contexte pertinent
        context = await self.retrieve_context(user_query)

        # 2. Générer réponse
        response = await self.generate_response(user_query, context)

        # 3. Sauvegarder dans l'historique
        await self._save_chat_history(session_id, user_query, response)

        return {
            'response': response,
            'sources': [
                {'id': c['entity_id'], 'name': c['metadata'].get('name')}
                for c in context
            ],
            'session_id': session_id
        }
```

### 7.4 Module OCR Ordonnances

```python
# backend/app/ai/ocr/prescription_reader.py

import cv2
import numpy as np
from PIL import Image
import pytesseract
import easyocr
from typing import List, Dict, Tuple
import re

class PrescriptionReader:
    """
    OCR pour lecture d'ordonnances médicales.

    Pipeline:
    1. Prétraitement image (amélioration qualité)
    2. OCR (Tesseract + EasyOCR pour redondance)
    3. NER (extraction entités: médicaments, dosages)
    4. Matching avec base produits
    5. Validation et vérification interactions

    Avantages double OCR:
    - Tesseract: rapide, bon pour texte imprimé
    - EasyOCR: meilleur pour écriture manuscrite
    - Fusion des résultats améliore précision
    """

    def __init__(self, db):
        self.db = db
        self.reader = easyocr.Reader(['fr'])

        # Patterns regex pour extraction
        self.patterns = {
            'dosage': r'(\d+(?:[.,]\d+)?)\s*(mg|g|ml|µg|ui)',
            'quantity': r'(\d+)\s*(comprimé|gélule|sachet|flacon|boîte)s?',
            'frequency': r'(\d+)\s*(?:fois|x)\s*(?:par)?\s*(jour|semaine|mois)',
            'duration': r'(?:pendant|durant)\s*(\d+)\s*(jour|semaine|mois)s?'
        }

    def preprocess_image(self, image_path: str) -> np.ndarray:
        """
        Prétraitement de l'image pour améliorer l'OCR.
        """
        # Charger image
        img = cv2.imread(image_path)

        # Convertir en niveaux de gris
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

        # Correction de l'inclinaison (deskew)
        coords = np.column_stack(np.where(gray > 0))
        angle = cv2.minAreaRect(coords)[-1]
        if angle < -45:
            angle = -(90 + angle)
        else:
            angle = -angle

        (h, w) = gray.shape[:2]
        center = (w // 2, h // 2)
        M = cv2.getRotationMatrix2D(center, angle, 1.0)
        rotated = cv2.warpAffine(gray, M, (w, h),
                                  flags=cv2.INTER_CUBIC,
                                  borderMode=cv2.BORDER_REPLICATE)

        # Débruitage
        denoised = cv2.fastNlMeansDenoising(rotated, None, 10, 7, 21)

        # Binarisation adaptative
        binary = cv2.adaptiveThreshold(
            denoised, 255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY, 11, 2
        )

        return binary

    def extract_text_tesseract(self, image: np.ndarray) -> str:
        """OCR avec Tesseract."""
        custom_config = r'--oem 3 --psm 6 -l fra'
        text = pytesseract.image_to_string(image, config=custom_config)
        return text

    def extract_text_easyocr(self, image_path: str) -> str:
        """OCR avec EasyOCR (meilleur pour manuscrit)."""
        results = self.reader.readtext(image_path)
        text = ' '.join([result[1] for result in results])
        return text

    def extract_medications(self, text: str) -> List[Dict]:
        """
        Extraction des médicaments et leurs détails via NER simplifié.
        """
        medications = []

        # Normaliser le texte
        text = text.lower()
        lines = text.split('\n')

        for line in lines:
            if not line.strip():
                continue

            med = {'raw_text': line.strip()}

            # Extraire dosage
            dosage_match = re.search(self.patterns['dosage'], line)
            if dosage_match:
                med['dosage'] = f"{dosage_match.group(1)} {dosage_match.group(2)}"

            # Extraire quantité
            qty_match = re.search(self.patterns['quantity'], line)
            if qty_match:
                med['quantity'] = int(qty_match.group(1))
                med['form'] = qty_match.group(2)

            # Extraire fréquence
            freq_match = re.search(self.patterns['frequency'], line)
            if freq_match:
                med['frequency'] = f"{freq_match.group(1)}x/{freq_match.group(2)}"

            if 'dosage' in med or 'quantity' in med:
                medications.append(med)

        return medications

    async def match_products(self, medications: List[Dict]) -> List[Dict]:
        """
        Match les médicaments extraits avec la base produits.
        Utilise recherche full-text PostgreSQL.
        """
        for med in medications:
            raw_text = med['raw_text']

            # Recherche full-text
            query = """
                SELECT id, name, family, laboratory,
                       ts_rank(to_tsvector('french', name),
                               plainto_tsquery('french', :search)) as rank
                FROM synergo_core.products
                WHERE to_tsvector('french', name) @@ plainto_tsquery('french', :search)
                ORDER BY rank DESC
                LIMIT 3
            """

            result = await self.db.execute(query, {'search': raw_text})
            matches = result.fetchall()

            if matches:
                med['matched_products'] = [
                    {
                        'id': m.id,
                        'name': m.name,
                        'family': m.family,
                        'confidence': min(round(m.rank, 2), 1.0)
                    }
                    for m in matches
                ]
            else:
                med['matched_products'] = []

        return medications

    async def process_prescription(self, image_path: str) -> Dict:
        """
        Pipeline complet de traitement d'ordonnance.
        """
        # 1. Prétraitement
        preprocessed = self.preprocess_image(image_path)

        # 2. Double OCR
        text_tesseract = self.extract_text_tesseract(preprocessed)
        text_easyocr = self.extract_text_easyocr(image_path)

        # 3. Fusion des textes (prendre le plus long/complet)
        text = text_tesseract if len(text_tesseract) > len(text_easyocr) else text_easyocr

        # 4. Extraction médicaments
        medications = self.extract_medications(text)

        # 5. Matching produits
        medications = await self.match_products(medications)

        # 6. Vérification interactions (si plusieurs médicaments)
        interactions = []
        if len(medications) > 1:
            interactions = await self._check_interactions(medications)

        return {
            'raw_text': text,
            'medications': medications,
            'interactions': interactions,
            'confidence': self._calculate_confidence(medications)
        }

    def _calculate_confidence(self, medications: List[Dict]) -> float:
        """Calcule un score de confiance global."""
        if not medications:
            return 0.0

        total_confidence = 0
        for med in medications:
            if med.get('matched_products'):
                total_confidence += med['matched_products'][0].get('confidence', 0)

        return round(total_confidence / len(medications), 2)
```

### 7.5 Choix technologiques IA - Justification

| Composant | Choix | Avantages | Inconvénients | Alternative |
|-----------|-------|-----------|---------------|-------------|
| **Prévision ventes** | Prophet | Simple, saisonnalité auto, interprétable | Moins précis patterns complexes | LSTM (plus complexe) |
| **Embeddings** | all-MiniLM-L6-v2 | Léger (80MB), rapide, multilingue | Moins précis que modèles plus gros | sentence-t5-xl (meilleur mais 5GB) |
| **Vector DB** | pgvector | Intégré PostgreSQL, pas de service supplémentaire | Moins performant que Pinecone/Milvus | Qdrant, Milvus |
| **OCR** | Tesseract + EasyOCR | Open source, gratuit, multi-langue | Moins bon que Google Vision AI | Google Vision, AWS Textract |
| **LLM local** | Mistral 7B | Open source, bon français, runnable local | Nécessite GPU | Llama 2, GPT-4 API |
| **NER Pharma** | spaCy + règles | Rapide, customisable | Nécessite données entraînement | MedCAT, BioBERT |

---

## 8. Sécurité

### 8.1 Architecture sécurité

```
┌─────────────────────────────────────────────────────────────────┐
│                    SÉCURITÉ MULTICOUCHE                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. AUTHENTIFICATION                                             │
│     ├── JWT tokens (access + refresh)                           │
│     ├── Password hashing (bcrypt, cost=12)                      │
│     ├── Rate limiting (100 req/min/user)                        │
│     └── Session management (Redis)                              │
│                                                                  │
│  2. AUTORISATION (RBAC)                                          │
│     ├── Rôles: ADMIN, MANAGER, PHARMACIST, EMPLOYEE             │
│     ├── Permissions granulaires par ressource                   │
│     └── Row-level security PostgreSQL                           │
│                                                                  │
│  3. PROTECTION DONNÉES                                           │
│     ├── Chiffrement at-rest (PostgreSQL TDE)                    │
│     ├── Chiffrement in-transit (TLS 1.3)                        │
│     ├── Données sensibles hashées (NSS, etc.)                   │
│     └── Audit log toutes modifications                          │
│                                                                  │
│  4. SÉCURITÉ API                                                 │
│     ├── CORS restrictif                                         │
│     ├── Input validation (Pydantic)                             │
│     ├── SQL injection prevention (ORM)                          │
│     ├── XSS prevention (React auto-escape)                      │
│     └── CSRF tokens                                             │
│                                                                  │
│  5. INFRASTRUCTURE                                               │
│     ├── Firewall (ports minimaux)                               │
│     ├── Secrets management (.env, pas de hardcode)              │
│     ├── Container isolation (Docker)                            │
│     └── Regular security updates                                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2 Implémentation JWT

```python
# backend/app/core/security.py

from datetime import datetime, timedelta
from typing import Optional, Dict
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel

# Configuration
SECRET_KEY = "your-secret-key-from-env"  # À charger depuis .env
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30
REFRESH_TOKEN_EXPIRE_DAYS = 7

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class TokenData(BaseModel):
    user_id: int
    role: str
    permissions: list[str]

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def create_access_token(data: Dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire, "type": "access"})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def create_refresh_token(data: Dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "type": "refresh"})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def decode_token(token: str) -> Optional[TokenData]:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return TokenData(**payload)
    except JWTError:
        return None
```

### 8.3 Rôles et permissions

```python
# backend/app/core/permissions.py

from enum import Enum
from typing import List

class Role(str, Enum):
    ADMIN = "admin"
    MANAGER = "manager"
    PHARMACIST = "pharmacist"
    EMPLOYEE = "employee"

class Permission(str, Enum):
    # Employees
    EMPLOYEES_VIEW = "employees:view"
    EMPLOYEES_CREATE = "employees:create"
    EMPLOYEES_EDIT = "employees:edit"
    EMPLOYEES_DELETE = "employees:delete"

    # Attendance
    ATTENDANCE_VIEW_OWN = "attendance:view_own"
    ATTENDANCE_VIEW_ALL = "attendance:view_all"
    ATTENDANCE_VALIDATE = "attendance:validate"

    # Payroll
    PAYROLL_VIEW_OWN = "payroll:view_own"
    PAYROLL_VIEW_ALL = "payroll:view_all"
    PAYROLL_CREATE = "payroll:create"
    PAYROLL_VALIDATE = "payroll:validate"

    # Stock
    STOCK_VIEW = "stock:view"
    STOCK_ADJUST = "stock:adjust"

    # Orders
    ORDERS_VIEW = "orders:view"
    ORDERS_CREATE = "orders:create"
    ORDERS_APPROVE = "orders:approve"

    # Sales
    SALES_VIEW = "sales:view"
    SALES_CREATE = "sales:create"

    # Dashboard
    DASHBOARD_VIEW = "dashboard:view"
    DASHBOARD_ADMIN = "dashboard:admin"

    # AI
    AI_CHAT = "ai:chat"
    AI_PREDICTIONS = "ai:predictions"
    AI_OCR = "ai:ocr"

# Mapping rôles → permissions
ROLE_PERMISSIONS = {
    Role.ADMIN: list(Permission),  # Toutes les permissions

    Role.MANAGER: [
        Permission.EMPLOYEES_VIEW,
        Permission.EMPLOYEES_CREATE,
        Permission.EMPLOYEES_EDIT,
        Permission.ATTENDANCE_VIEW_ALL,
        Permission.ATTENDANCE_VALIDATE,
        Permission.PAYROLL_VIEW_ALL,
        Permission.PAYROLL_CREATE,
        Permission.STOCK_VIEW,
        Permission.STOCK_ADJUST,
        Permission.ORDERS_VIEW,
        Permission.ORDERS_CREATE,
        Permission.ORDERS_APPROVE,
        Permission.SALES_VIEW,
        Permission.DASHBOARD_VIEW,
        Permission.DASHBOARD_ADMIN,
        Permission.AI_CHAT,
        Permission.AI_PREDICTIONS,
    ],

    Role.PHARMACIST: [
        Permission.ATTENDANCE_VIEW_OWN,
        Permission.PAYROLL_VIEW_OWN,
        Permission.STOCK_VIEW,
        Permission.ORDERS_VIEW,
        Permission.ORDERS_CREATE,
        Permission.SALES_VIEW,
        Permission.SALES_CREATE,
        Permission.DASHBOARD_VIEW,
        Permission.AI_CHAT,
        Permission.AI_OCR,
    ],

    Role.EMPLOYEE: [
        Permission.ATTENDANCE_VIEW_OWN,
        Permission.PAYROLL_VIEW_OWN,
        Permission.SALES_CREATE,
        Permission.AI_CHAT,
    ],
}
```

---

## 9. Déploiement

### 9.1 Architecture déploiement

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        ARCHITECTURE DÉPLOIEMENT                                  │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                      SERVEUR LOCAL PHARMACIE                             │   │
│  │                                                                          │   │
│  │  ┌──────────────────────────────────────────────────────────────────┐  │   │
│  │  │                    Docker Compose Stack                           │  │   │
│  │  │                                                                   │  │   │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │  │   │
│  │  │  │   FastAPI   │  │  PostgreSQL │  │    Redis    │              │  │   │
│  │  │  │   Backend   │  │     DB      │  │    Cache    │              │  │   │
│  │  │  │  :8000      │  │   :5439     │  │   :6379     │              │  │   │
│  │  │  └─────────────┘  └─────────────┘  └─────────────┘              │  │   │
│  │  │                                                                   │  │   │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │  │   │
│  │  │  │   React     │  │   Nginx     │  │   MLflow    │              │  │   │
│  │  │  │  Frontend   │  │   Proxy     │  │   Tracking  │              │  │   │
│  │  │  │  :3000      │  │   :80/443   │  │   :5000     │              │  │   │
│  │  │  └─────────────┘  └─────────────┘  └─────────────┘              │  │   │
│  │  └──────────────────────────────────────────────────────────────────┘  │   │
│  │                              │                                          │   │
│  │                              ▼                                          │   │
│  │  ┌──────────────────────────────────────────────────────────────────┐  │   │
│  │  │                    HFSQL Server (EasyPharm)                       │  │   │
│  │  │                         :4900                                     │  │   │
│  │  └──────────────────────────────────────────────────────────────────┘  │   │
│  │                                                                          │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                        │                                         │
│                                        │ Backup automatique                     │
│                                        ▼                                         │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                         CLOUD BACKUP (Optionnel)                         │   │
│  │                                                                          │   │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐         │   │
│  │  │   PostgreSQL    │  │    S3/MinIO     │  │   Monitoring    │         │   │
│  │  │    Replica      │  │  ML Models      │  │   Grafana       │         │   │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘         │   │
│  │                                                                          │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 9.2 Docker Compose complet

```yaml
# docker/docker-compose.yml

version: '3.8'

services:
  # Base de données PostgreSQL
  postgres:
    image: pgvector/pgvector:pg15
    container_name: synergo_postgres
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-synergo_user}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-synergo_2024!}
      POSTGRES_DB: ${POSTGRES_DB:-synergo_db}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init:/docker-entrypoint-initdb.d
    ports:
      - "5439:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U synergo_user -d synergo_db"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  # Cache Redis
  redis:
    image: redis:7-alpine
    container_name: synergo_redis
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  # Backend FastAPI
  backend:
    build:
      context: ../backend
      dockerfile: Dockerfile
    container_name: synergo_backend
    environment:
      DATABASE_URL: postgresql+asyncpg://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5439/${POSTGRES_DB}
      REDIS_URL: redis://redis:6379/0
      SECRET_KEY: ${SECRET_KEY:-change-me-in-production}
      HFSQL_SERVER: ${HFSQL_SERVER:-host.docker.internal}
      HFSQL_PORT: ${HFSQL_PORT:-4900}
    volumes:
      - ../backend/app:/app/app
      - backend_logs:/app/logs
      - ml_models:/app/models
    ports:
      - "8000:8000"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped

  # Frontend React
  frontend:
    build:
      context: ../frontend
      dockerfile: Dockerfile
    container_name: synergo_frontend
    environment:
      REACT_APP_API_URL: http://localhost:8000/api/v1
    volumes:
      - ../frontend/src:/app/src
    ports:
      - "3000:3000"
    depends_on:
      - backend
    restart: unless-stopped

  # Nginx reverse proxy
  nginx:
    image: nginx:alpine
    container_name: synergo_nginx
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - backend
      - frontend
    restart: unless-stopped

  # MLflow tracking server
  mlflow:
    image: ghcr.io/mlflow/mlflow:v2.9.0
    container_name: synergo_mlflow
    command: mlflow server --host 0.0.0.0 --backend-store-uri postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5439/mlflow --default-artifact-root /mlflow/artifacts
    volumes:
      - mlflow_artifacts:/mlflow/artifacts
    ports:
      - "5000:5000"
    depends_on:
      postgres:
        condition: service_healthy
    restart: unless-stopped

  # PgAdmin (optionnel, pour développement)
  pgadmin:
    image: dpage/pgadmin4
    container_name: synergo_pgadmin
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@synergo.com
      PGADMIN_DEFAULT_PASSWORD: admin123
    volumes:
      - pgadmin_data:/var/lib/pgadmin
    ports:
      - "8085:80"
    depends_on:
      - postgres
    profiles:
      - dev
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
  backend_logs:
  ml_models:
  mlflow_artifacts:
  pgadmin_data:

networks:
  default:
    name: synergo_network
```

### 9.3 Dockerfile Backend

```dockerfile
# backend/Dockerfile

FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    tesseract-ocr \
    tesseract-ocr-fra \
    libgl1-mesa-glx \
    libglib2.0-0 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first (cache layer)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run with uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## 10. Roadmap d'implémentation

### 10.1 Vue d'ensemble

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           ROADMAP IMPLÉMENTATION                                 │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│  PHASE 1 - MVP (Mois 1-3)                                                       │
│  ════════════════════════                                                       │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │ Mois 1: Infrastructure & Base                                            │   │
│  │ • Configuration environnement Docker complet                            │   │
│  │ • Migration base de données (nouveaux schémas)                          │   │
│  │ • Authentification JWT + RBAC                                           │   │
│  │ • API CRUD employés de base                                             │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │ Mois 2: Module RH                                                        │   │
│  │ • Gestion complète employés                                             │   │
│  │ • Système de pointage (API pointeuse)                                   │   │
│  │ • Planning et congés                                                    │   │
│  │ • Dashboard KPIs basique                                                │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │ Mois 3: Stock & Prévisions simples                                       │   │
│  │ • Alertes rupture stock                                                 │   │
│  │ • Assistant commande (règles simples)                                   │   │
│  │ • Prévision ventes simple (Prophet)                                     │   │
│  │ • Frontend React basique                                                │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
│  PHASE 2 - IA AVANCÉE (Mois 4-6)                                               │
│  ══════════════════════════════                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │ Mois 4: Chatbot RAG                                                      │   │
│  │ • Indexation produits (pgvector)                                        │   │
│  │ • API chatbot avec contexte                                             │   │
│  │ • Interface chat React                                                  │   │
│  │ • FAQ automatique                                                       │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │ Mois 5: OCR Ordonnances                                                  │   │
│  │ • Pipeline OCR (Tesseract + EasyOCR)                                    │   │
│  │ • Extraction médicaments (NER)                                          │   │
│  │ • Matching base produits                                                │   │
│  │ • Base interactions médicamenteuses                                     │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │ Mois 6: CRM & Analytics RH                                               │   │
│  │ • Module CRM clients                                                    │   │
│  │ • Segmentation clients (K-means)                                        │   │
│  │ • Analytics performance employés                                        │   │
│  │ • PWA mobile employé                                                    │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
│  PHASE 3 - OPTIMISATION (Mois 7-9)                                             │
│  ═════════════════════════════════                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │ Mois 7-8: IA Prédictive avancée                                          │   │
│  │ • Modèles LSTM pour prévisions complexes                                │   │
│  │ • Optimisation automatique commandes                                    │   │
│  │ • Détection anomalies                                                   │   │
│  │ • Facteurs saisonniers (Ramadan, rentrée, etc.)                        │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │ Mois 9: Production & Monitoring                                          │   │
│  │ • Tests de charge                                                       │   │
│  │ • Monitoring (Prometheus + Grafana)                                     │   │
│  │ • Documentation utilisateur                                             │   │
│  │ • Formation équipe pharmacie                                            │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 10.2 Détail Phase 1 (MVP)

#### Semaine 1-2: Setup Infrastructure

| Tâche | Priorité | Effort |
|-------|----------|--------|
| Docker Compose production-ready | P0 | 2j |
| Migration Alembic setup | P0 | 1j |
| Schémas DB synergo_hr et synergo_ai | P0 | 2j |
| Variables d'environnement sécurisées | P0 | 1j |
| CI/CD basique (GitHub Actions) | P1 | 2j |

#### Semaine 3-4: Authentification

| Tâche | Priorité | Effort |
|-------|----------|--------|
| Modèle User avec hashing | P0 | 1j |
| JWT access + refresh tokens | P0 | 2j |
| Middleware auth FastAPI | P0 | 1j |
| RBAC permissions | P0 | 2j |
| Tests auth | P1 | 2j |

#### Semaine 5-8: Module RH

| Tâche | Priorité | Effort |
|-------|----------|--------|
| CRUD Employees | P0 | 3j |
| CRUD Contracts | P0 | 2j |
| API Pointage | P0 | 3j |
| Intégration pointeuse physique | P1 | 3j |
| Planning et congés | P0 | 4j |
| Calcul salaires | P0 | 5j |
| Export PDF fiche paie | P1 | 2j |

#### Semaine 9-12: Stock & Dashboard

| Tâche | Priorité | Effort |
|-------|----------|--------|
| API alertes stock | P0 | 2j |
| Dashboard KPIs temps réel | P0 | 4j |
| WebSocket live updates | P1 | 3j |
| Prophet prévisions basiques | P0 | 4j |
| Frontend React MVP | P0 | 10j |
| Tests E2E | P1 | 3j |

### 10.3 Livrables par phase

#### Phase 1 (MVP)
- ✅ Système de gestion RH fonctionnel
- ✅ Pointage employés (API + pointeuse)
- ✅ Calcul salaires automatisé
- ✅ Dashboard KPIs temps réel
- ✅ Alertes rupture stock
- ✅ Prévisions ventes 7 jours

#### Phase 2 (IA avancée)
- ✅ Chatbot RAG pharmacie
- ✅ OCR ordonnances avec matching
- ✅ Vérification interactions médicamenteuses
- ✅ CRM clients avec segmentation
- ✅ PWA mobile employé

#### Phase 3 (Optimisation)
- ✅ Prévisions ventes 30 jours (LSTM)
- ✅ Optimisation automatique commandes
- ✅ Détection anomalies (fraude, erreurs)
- ✅ Analytics RH avancés
- ✅ Système en production stable

---

## Annexes

### A. Ressources techniques

- FastAPI: https://fastapi.tiangolo.com/
- SQLAlchemy 2.0: https://docs.sqlalchemy.org/en/20/
- Prophet: https://facebook.github.io/prophet/
- pgvector: https://github.com/pgvector/pgvector
- Hugging Face: https://huggingface.co/docs

### B. Estimation budget

| Poste | Coût estimé |
|-------|-------------|
| Serveur local (Dell PowerEdge) | 3000-5000 € |
| GPU cloud (optionnel, entraînement) | 100-200 €/mois |
| Licences (aucune, full open source) | 0 € |
| Développement (9 mois, 1 dev senior) | Variable |

### C. Contacts & Support

- Documentation projet: `/docs/`
- Issues: GitHub Issues
- API Docs: http://localhost:8000/docs

---

*Document généré le 2026-01-26*
*Version: 1.0.0*
*Auteur: Architecture Team*
