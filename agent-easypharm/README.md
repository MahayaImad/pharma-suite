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

## Lancer

En continu, une passe toutes les `interval_seconds` :

```bat
python -m pharmasuite_agent --config config.toml
```

En une passe, pour le Planificateur de tâches Windows :

```bat
python -m pharmasuite_agent --config config.toml --une-passe
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

## Tables complètes et tables incrémentales

Les ventes et les achats ne font que grossir : on ne relit que ce qui dépasse
le dernier id connu.

Les référentiels (nomenclature, clients, fournisseurs…) sont modifiés **sur
place** — un stock qui change ne change pas l'id. L'incrémental les raterait,
donc ils sont relus en entier toutes les `full_resync_every` passes (12 par
défaut, soit une heure avec l'intervalle de 5 minutes).

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
