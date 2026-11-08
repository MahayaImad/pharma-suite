# Agent EASYPHARM → PharmaSuite

Tourne sur le **PC Windows** de l'officine, celui qui héberge EASYPHARM. Lit
les fichiers HyperFileSQL par ODBC et pousse les données vers l'API
PharmaSuite, sur le serveur Ubuntu.

Le flux est à sens unique : l'agent ne modifie jamais EASYPHARM.

```
Windows (officine)                     Ubuntu (serveur)
┌──────────────────────┐               ┌─────────────────────┐
│ EASYPHARM (HFSQL)    │               │ PharmaSuite API     │
│        ▲             │  HTTP + JWT   │   POST /sync/{table}│
│        │ ODBC (lect.)│──────────────▶│   PostgreSQL 16     │
│   agent (ce dossier) │               └─────────────────────┘
└──────────────────────┘
```

## Tables synchronisées (31 tables)

| Stratégie | Tables | Intervalle |
|-----------|--------|------------|
| **incremental** | sorties_produits, entrees_produits, mouchard, factures_chifa_produits, ordonnancier, commandes_fournisseurs_produits, echanges_sorties_produits | 15-30 min |
| **window** | sorties, entrees, operations, factures_chifa, commandes_fournisseurs, echanges | 30-60 min |
| **full** | nomenclature, clients, fournisseurs, groupware, bordereaux_chifa, suivi_caisses, familles, formes, laboratoires, etc. | 4h-24h |
| **pipeline** | instance_produits (+ instance_produits_trt) | 15 min |

### Stratégies de synchronisation

- **incremental** : `id > last_id` — pour les tables qui ne font que grossir
- **window** : fenêtre glissante sur `date` + champ `modif` — pour les tables modifiées sur place
- **full** : relecture complète périodique — pour les référentiels
- **pipeline** : cas spécial `instance_produits` (seule table avec DELETE)

## Pourquoi un agent, plutôt qu'une connexion directe

Le serveur Ubuntu ne peut pas lire HyperFileSQL : le driver est Windows. En
poussant depuis le poste, on évite aussi d'exposer EASYPHARM sur le réseau —
c'est l'agent qui sort, rien n'entre.

## Installation

Sur le poste Windows, Python 3.11 ou plus récent :

```bat
cd agent-easypharm
python -m pip install -r requirements.txt
copy config.example.toml config.toml
```

Éditer `config.toml` : DSN ODBC, adresse du serveur, mot de passe du compte
`sync_agent` (celui de `settings.sync_agent_password` côté backend).

Le DSN se crée dans **Panneau de configuration → Outils d'administration →
Sources de données ODBC (64 bits) → onglet Système → Ajouter → HFSQL**.
Il doit être **Système**, pas Utilisateur, sinon le service ne le verra pas.

## Vérifier avant de lancer

```bat
python -m pharmasuite_agent --config config.toml --tester
```

Teste les deux extrémités séparément et dit laquelle échoue :

```
  EASYPHARM (ODBC EASYPHARM) : OK — sorties.id max = 184203
  PharmaSuite (http://192.168.1.10:8000/api/v1) : OK — sorties last_id = 184203
```

## Lister les tables

```bat
python -m pharmasuite_agent --lister
```

Affiche les 31 tables avec leur stratégie et intervalle.

## Lancer

En continu, une passe toutes les `interval_seconds` :

```bat
python -m pharmasuite_agent --config config.toml
```

En une passe, pour le Planificateur de tâches Windows :

```bat
python -m pharmasuite_agent --config config.toml --une-passe
```

Synchroniser une table spécifique :

```bat
python -m pharmasuite_agent --config config.toml --table sorties
```

Le code de sortie vaut 1 si au moins une table a échoué, ce qui permet au
planificateur de signaler l'incident.

## Comment la reprise fonctionne

Le curseur de chaque table est gardé **côté serveur**
(`GET /sync/status/{table}`), pas dans un fichier local : réinstaller l'agent
ou changer de poste ne fait rien reperdre.

Chaque lot accepté avance le curseur. Une coupure réseau au milieu d'une
grosse table ne fait donc reperdre que le lot en cours, et comme les écritures
sont des upserts, rejouer un lot est sans effet de bord.

Une table qui échoue n'interrompt pas les autres : un fichier verrouillé par
EASYPHARM ne doit pas bloquer la synchronisation des ventes.

## Mode intervalles par table

Par défaut (`respecter_intervalles = true` dans config.toml), chaque table
respecte son propre intervalle :

- **15 min** : sorties_produits, entrees_produits, mouchard, instance_produits
- **30 min** : sorties, entrees, operations
- **4h** : nomenclature, clients, fournisseurs
- **24h** : familles, formes, laboratoires (nightly)

En mode legacy (`respecter_intervalles = false`), toutes les tables sont
synchronisées à chaque passe, avec `full_resync_every` pour les full syncs.

## Tests

```bat
python -m pip install -r requirements-dev.txt
python -m pytest
```

Ils ne demandent ni ODBC ni réseau : la source et le client sont doublés.

## Sécurité

- `config.toml` contient un mot de passe : il est dans `.gitignore`, ne jamais
  le committer.
- Les montants circulent en **chaînes**, jamais en float, pour ne pas perdre
  de précision avant PostgreSQL.
- Aucune donnée patient ne quitte le réseau local : l'agent parle uniquement
  au serveur de l'officine.
- Les tables sensibles (ordonnancier, clients, groupware) sont marquées RGPD.
