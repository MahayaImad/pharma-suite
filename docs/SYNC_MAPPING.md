# Mapping de Synchronisation HFSQL → PostgreSQL

> Document de référence pour l'agent de synchronisation EasyPharm → Synergo

---

## Vue d'Ensemble

| Catégorie | Nombre | Stratégie |
|-----------|--------|-----------|
| Incrémentale | 7 tables | `id > last_id` |
| Fenêtre glissante | 6 tables | `date > J-30 OR modif > 0` |
| Full Sync | 17 tables | Copie complète |
| Pipeline dédié | 1 table | Archive spéciale |
| Ignorées (vides) | 2 tables | Non synchronisées |
| **TOTAL** | **33 tables** | |

---

## 1. Tables INCRÉMENTALES (id > last_id)

Ces tables sont en **insertion pure** - les lignes ne changent jamais après création.

| Table HFSQL | Table PostgreSQL | Fréquence | Notes |
|-------------|------------------|-----------|-------|
| `sorties_produits` | `sale_details` | 15 min | Lignes de ventes |
| `entrees_produits` | `purchase_details` | 15 min | Lignes d'achats, vérif `bloqué` |
| `mouchard` | `audit_log` | 15 min | 54 colonnes, journal d'audit |
| `factures_chifa_produits` | `chifa_invoice_lines` | 15 min | Lignes factures CNAS |
| `ordonnancier` | `prescription_register` | 15 min | 🔒 TRÈS SENSIBLE |
| `commandes_fournisseurs_produits` | `supplier_order_lines` | 30 min | ID=INTEGER |
| `echanges_sorties_produits` | `exchange_lines` | 30 min | `id_nom` = Décimal |

### Requête Type (Incrémentale)
```sql
SELECT * FROM {table} 
WHERE id > :last_sync_id 
ORDER BY id ASC
LIMIT 1000
```

---

## 2. Tables FENÊTRE GLISSANTE

Ces tables ont des en-têtes qui peuvent être **modifiés après création**.

| Table HFSQL | Table PostgreSQL | Fréquence | Condition |
|-------------|------------------|-----------|-----------|
| `sorties` | `sales` | 30 min | `date > J-30 OR modif > 0` |
| `entrees` | `purchases` | 30 min | `date > J-30 OR modif > 0 OR ouverte = 1` |
| `opérations` | `operations` | 30 min | `date > J-30 OR modif > 0 OR cloturé = 0` |
| `factures_chifa` | `chifa_invoices` | 30 min | États `déstocké`, `annulé`, `rej` |
| `commandes_fournisseurs` | `supplier_orders` | 1h | `Sync` flag, ID=INTEGER |
| `echanges` | `exchanges` | 1h | `modif > 0` |

### Requête Type (Fenêtre)
```sql
SELECT * FROM sorties 
WHERE date >= :date_minus_30_days 
   OR modif > 0
ORDER BY id ASC
```

---

## 3. Tables FULL SYNC

Ces tables doivent être synchronisées **entièrement** car :
- Compteurs/agrégats qui changent constamment
- Machines à états complexes
- Référentiels modifiables

### 3.1 Données Métier (4h)

| Table HFSQL | Table PostgreSQL | Notes |
|-------------|------------------|-------|
| `nomenclature` | `products` | Catalogue produits |
| `clients` | `customers` | 🔒 Données RGPD |
| `fournisseurs` | `suppliers` | Compteurs vivants |
| `bordereaux_chifa` | `chifa_batches` | Machine à 5 états |

### 3.2 Utilisateurs (4h)

| Table HFSQL | Table PostgreSQL | Notes |
|-------------|------------------|-------|
| `groupware` | `users` + `permissions` | 🔴 mdp en clair → bcrypt |

### 3.3 Caisse et Trésorerie (4h)

| Table HFSQL | Table PostgreSQL | Notes |
|-------------|------------------|-------|
| `suivi_caisses` | `cash_sessions` | 25 cols, sessions de caisse |

### 3.4 Référentiels (Nightly)

| Table HFSQL | Table PostgreSQL | Colonnes |
|-------------|------------------|----------|
| `familles` | `families` | 2 |
| `formes` | `forms` | 4 |
| `laboratoires` | `laboratories` | 2 |
| `nomenclature_chifa` | `cnas_products` | 22 |
| `caisses` | `cash_registers` | 5, ID=INTEGER |
| `pharmacies` | `pharmacies` | 9 |
| `postes` | `workstations` | 30+ |
| `prestations` | `services` | 3, ID=INTEGER |
| `comptes_bancaires` | `bank_accounts` | 4, ID=INTEGER |
| `dépenses` | `expense_types` | 2 (catégories) |
| `motif_instance` | `instance_reasons` | 2 (liste dynamique) |

---

## 4. Pipeline DÉDIÉ

### `instance_produits` → `instance_produits_trt`

**Seule table où les lignes sont SUPPRIMÉES** de HFSQL.

```
┌─────────────────┐     Vente      ┌─────────────────┐
│ instance_       │ ──────────────▶│ sorties         │
│ produits        │                └─────────────────┘
│ (en attente)    │                        │
└────────┬────────┘                        │
         │                                 │
         │ Suppression                     │
         ▼                                 ▼
┌─────────────────┐                ┌─────────────────┐
│ instance_       │                │ instance_       │
│ produits_trt    │ ◀──────────────│ produits_trt    │
│ (archive)       │    Copie       │ + archive_trace │
└─────────────────┘                └─────────────────┘
```

**Champs Archive** :
- `archive` = TRUE
- `archive_trace` = "Vente CHIFA" | "Vente Comptoir" | "Suppression manuelle"
- `utilisateur_validation` = Employé
- `date_archive` = Timestamp

---

## 5. Tables IGNORÉES (Vides)

| Table HFSQL | Raison |
|-------------|--------|
| `caisses_régies` | Non utilisée |
| `inventaires` | Module désactivé |
| `inventaires_produits` | Module désactivé |

---

## 6. Transformations de Données

### 6.1 Dates

| Format HFSQL | Format PostgreSQL | Exemple |
|--------------|-------------------|---------|
| `DD/MM/YYYY` | `YYYY-MM-DD` | `01/01/2023` → `2023-01-01` |
| Heure `HH:MM` | VARCHAR(10) | Garder tel quel |

```python
def convert_date(hfsql_date: str) -> str:
    """DD/MM/YYYY → YYYY-MM-DD"""
    if not hfsql_date:
        return None
    parts = hfsql_date.split('/')
    return f"{parts[2]}-{parts[1]}-{parts[0]}"
```

### 6.2 Péremptions

| Table | Format |
|-------|--------|
| `sorties_produits` | `MM/YY` |
| `instance_produits` | `MM/YYYY` |
| `entrees_produits` | `MM/YY` + `peremption_date` (Date native) |

**Règle** : Utiliser `peremption_date` si disponible, sinon parser le texte.

### 6.3 Décimaux

```python
def convert_decimal(value) -> str:
    """Toujours envoyer en STRING pour éviter l'arrondi float"""
    if value is None:
        return None
    return f"{value:.4f}"  # "1450.0000"
```

⚠️ **JAMAIS** envoyer en nombre JSON : `"total": 1450.0` → arrondi binaire !

### 6.4 Mot de Passe

```python
import bcrypt

def hash_password(plain: str) -> str:
    """Hachage côté serveur uniquement"""
    return bcrypt.hashpw(plain.encode(), bcrypt.gensalt()).decode()
```

---

## 7. Anomalies HFSQL Connues

### 7.1 Types d'ID Incorrects

| Table | Champ | Type HFSQL | Type Attendu |
|-------|-------|------------|--------------|
| `commandes_fournisseurs` | `id` | INTEGER (4) | BIGINT |
| `commandes_fournisseurs_produits` | `id` | INTEGER (4) | BIGINT |
| `prestations` | `id` | INTEGER (4) | BIGINT |
| `comptes_bancaires` | `id` | INTEGER (4) | BIGINT |
| `caisses` | `id` | INTEGER (4) | BIGINT |

### 7.2 Décimaux au lieu de BIGINT

| Table | Champ | Type HFSQL |
|-------|-------|------------|
| `entrees_produits` | `id_produit` | Décimal 9 |
| `echanges_sorties_produits` | `id_nom` | Décimal 9 |
| `ordonnancier` | `id_vente` | Décimal 9 |
| `opérations` | `id_relatif` | Décimal 9 |
| `opérations` | `indice_creation` | Décimal 9 (timestamp) |

### 7.3 Largeurs Incohérentes

| Champ | Tables avec BIGINT | Tables avec autre |
|-------|-------------------|-------------------|
| `id_famille` | `nomenclature` | `sorties_produits` (INT), `echanges_sorties_produits` (SMALLINT) |

---

## 8. Ordre de Synchronisation

L'ordre respecte les **dépendances de clés étrangères** :

```
Phase 1 - Référentiels (pas de FK)
├── familles
├── formes
├── laboratoires
├── pharmacies
├── caisses
├── postes
├── prestations
├── comptes_bancaires
└── groupware

Phase 2 - Données de Base
├── nomenclature
├── nomenclature_chifa
├── clients
└── fournisseurs

Phase 3 - Transactions
├── entrees → entrees_produits
├── sorties → sorties_produits
├── commandes_fournisseurs → commandes_fournisseurs_produits
├── echanges → echanges_sorties_produits
└── opérations

Phase 4 - CHIFA
├── bordereaux_chifa
├── factures_chifa → factures_chifa_produits
└── ordonnancier

Phase 5 - Spéciaux
├── instance_produits (pipeline)
└── mouchard (audit, en dernier)
```

---

## 9. Configuration Scheduler

```python
SYNC_SCHEDULE = {
    # Incrémentales - Haute fréquence
    "sorties_produits": {"interval": 15, "strategy": "incremental"},
    "entrees_produits": {"interval": 15, "strategy": "incremental"},
    "mouchard": {"interval": 15, "strategy": "incremental"},
    "factures_chifa_produits": {"interval": 15, "strategy": "incremental"},
    "ordonnancier": {"interval": 15, "strategy": "incremental"},
    "commandes_fournisseurs_produits": {"interval": 30, "strategy": "incremental"},
    "echanges_sorties_produits": {"interval": 30, "strategy": "incremental"},
    
    # Fenêtre glissante - Moyenne fréquence
    "sorties": {"interval": 30, "strategy": "window", "days": 30},
    "entrees": {"interval": 30, "strategy": "window", "days": 30},
    "operations": {"interval": 30, "strategy": "window", "days": 30},
    "factures_chifa": {"interval": 30, "strategy": "window", "days": 30},
    "commandes_fournisseurs": {"interval": 60, "strategy": "window", "days": 30},
    "echanges": {"interval": 60, "strategy": "window", "days": 30},
    
    # Full Sync - Basse fréquence
    "nomenclature": {"interval": 240, "strategy": "full"},
    "clients": {"interval": 240, "strategy": "full"},
    "fournisseurs": {"interval": 240, "strategy": "full"},
    "groupware": {"interval": 240, "strategy": "full"},
    "bordereaux_chifa": {"interval": 240, "strategy": "full"},
    
    # Caisse - 4h
    "suivi_caisses": {"interval": 240, "strategy": "full"},
    
    # Référentiels - Nightly
    "familles": {"interval": 1440, "strategy": "full"},
    "formes": {"interval": 1440, "strategy": "full"},
    "laboratoires": {"interval": 1440, "strategy": "full"},
    "nomenclature_chifa": {"interval": 1440, "strategy": "full"},
    "caisses": {"interval": 1440, "strategy": "full"},
    "pharmacies": {"interval": 1440, "strategy": "full"},
    "postes": {"interval": 1440, "strategy": "full"},
    "prestations": {"interval": 1440, "strategy": "full"},
    "comptes_bancaires": {"interval": 1440, "strategy": "full"},
    "depenses": {"interval": 1440, "strategy": "full"},
    "motif_instance": {"interval": 1440, "strategy": "full"},
    
    # Pipeline spécial
    "instance_produits": {"interval": 15, "strategy": "pipeline"},
}
```

---

## 10. Données Sensibles (RGPD)

### 🔴 Niveau Maximum
- `ordonnancier` : CIN, données santé, psychotropes
- `clients.pathologie` : Données médicales

### 🟠 Niveau Élevé
- `clients` : Nom, adresse, téléphone, n° assuré
- `instance_produits` : N° assuré CHIFA/CVM
- `factures_chifa.no_assure` : N° sécurité sociale
- `sorties.client`, `sorties.n_assuré` : Identité

### 🟡 Niveau Modéré
- `groupware.mot_de_passe` : Credentials (→ hacher !)
- `fournisseurs` : Contacts professionnels

---

*Document généré le 2026-11-07 - Version 1.0*
