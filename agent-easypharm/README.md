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

## Tables synchronisées (39 tables)

Les 39 tables miroir attendues par le serveur (`SYNC_REGISTRY` dans
`backend/app/api/v1/sync.py`) ; un test vérifie que les deux listes restent
identiques.

| Stratégie | Tables | Intervalle |
|-----------|--------|------------|
| **incremental** | sorties_produits, entrees_produits, mouchard, factures_chifa_produits, ordonnancier, commandes_fournisseurs_produits, echanges_sorties_produits, + optionnelles : chifa_rejet_partiel, mouchard_details, reg_client_association, reg_fourn_association | 15-60 min |
| **window** | sorties, entrees, operations, factures_chifa, commandes_fournisseurs, echanges | 30-60 min |
| **full** | nomenclature, clients, fournisseurs, groupware, bordereaux_chifa, suivi_caisses, familles, formes, laboratoires, etc. + optionnelles : pharmnos_factures, caisses_regies, inventaires, inventaires_produits | 4h-24h |
| **pipeline** | instance_produits (+ instance_produits_trt) | 15 min |

### Stratégies de synchronisation

- **incremental** : `id > last_id` — pour les tables qui ne font que grossir
- **window** : rattrapage `id > last_id` (donc **tout l'historique** au premier
  lancement), puis relecture de la fenêtre glissante sur `date` + champ `modif`
  — pour les en-têtes modifiés sur place
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

## Vérifier que tout arrive

```bat
python -m pharmasuite_agent --config config.toml --verifier
```

Ne synchronise rien. Pour chaque table, compare HFSQL et PostgreSQL :

- la table existe-t-elle côté HFSQL sous le nom configuré ;
- **colonnes perdues** : présentes dans HFSQL, sans colonne PostgreSQL — leur
  contenu n'est pas importé ;
- **jamais remplies** : colonnes PostgreSQL qu'aucune colonne HFSQL n'alimente
  (souvent un nom de colonne qui diffère) ;
- l'**écart** de lignes HFSQL − PostgreSQL : positif = pas encore synchronisé,
  négatif = lignes supprimées dans EASYPHARM et restées en base.

Liste aussi les tables HFSQL que l'agent ne lit pas du tout. Code de sortie 1
tant que le résultat n'est pas « COMPLET ».

Les tables marquées **optionnelles** ont un nom HFSQL non attesté : si elles
sont introuvables, la passe continue avec un avertissement, et `--verifier`
dit s'il faut corriger leur nom `source` dans `tables.py`.

## Premier chargement complet

1. `--tester` : les deux connexions répondent.
2. `--verifier` : corriger dans `tables.py` les noms `source` introuvables.
3. `--une-passe` : charge tout l'historique. Peut être long sur
   `sorties_produits` et `mouchard`, mais reprenable à tout moment : le
   relancer repart du dernier lot accepté.
4. `--verifier` à nouveau : écart 0 et aucune colonne perdue sur chaque table.

## Lister les tables

```bat
python -m pharmasuite_agent --lister
```

Affiche les 39 tables avec leur stratégie et intervalle.

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

**Un lot partiellement refusé bloque le curseur.** Si PostgreSQL refuse des
lignes (texte trop long, valeur hors type…), le serveur les rejoue une par une,
importe les saines et renvoie les ids refusés avec leur cause. L'agent n'avance
alors pas son curseur et journalise l'erreur : la table reste en échec, visible,
jusqu'à correction — plutôt que de sauter ces lignes pour toujours.

Les noms de colonnes HFSQL sont normalisés (minuscules, sans accents :
`cloturé` → `cloture`) pour correspondre au schéma PostgreSQL.

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
