# Contrat de l'agent de synchronisation EASYPHARM

> **Statut** : document reconstitué. Le code de l'agent (le programme Windows qui
> lit HFSQL et pousse vers l'API) n'est pas dans ce dépôt. Tout ce qui suit est
> déduit du **côté serveur** : `app/api/v1/sync.py`, `app/schemas/sync.py`, les
> 16 modules de `app/models/`, et les migrations Alembic.
>
> Chaque affirmation est adossée à un `fichier:ligne`. Ce qui n'est pas
> vérifiable dans le dépôt est marqué **(déduction)** et repris au §6.
>
> Chemins relatifs à `backend/synergo/`.

---

**Sommaire**

1. [Vue d'ensemble](#1--vue-densemble)
2. [Les 39 tables miroir](#2--les-39-tables-miroir) — nom PostgreSQL, source HFSQL, clé primaire, colonnes, mutabilité
3. [Le protocole](#3--le-protocole) — authentification, corps, clé de conflit, réponse, pipeline `instance_produits`
4. [Comment le nom de table est validé](#4--comment-le-nom-de-table-est-validé) — liste blanche, et les vrais risques
5. [Les empreintes HFSQL](#5--les-empreintes-hfsql) — dates en texte, montants, blobs encodés
6. [Ambiguïtés à lever](#6--ambiguïtés-à-lever) — 11 questions ouvertes
   · [Annexe : ce qui n'est pas dans le contrat](#annexe--ce-qui-nest-pas-dans-le-contrat-de-sync)

---

## §1 — Vue d'ensemble

```
  PC Windows (officine)                        Serveur
┌───────────────────────┐               ┌────────────────────────┐
│  EASYPHARM / HFSQL    │               │  API FastAPI           │
│         │             │  Bearer JWT   │         │              │
│    sync agent  ───────┼──────────────►│  POST /sync/{table}    │
│         │             │               │         │              │
│    (état local ?)  ◄──┼───────────────┤  GET/POST /sync/status │
└───────────────────────┘               │         ▼              │
                                        │  PostgreSQL 16         │
                                        │  (39 tables miroir)    │
                                        └────────────────────────┘
```

L'agent pousse ; le serveur ne tire jamais. Une seule opération d'écriture :
`INSERT … ON CONFLICT (id) DO UPDATE`.

Deux modes de passage se devinent dans le code :

- **incrémental** — l'agent garde un curseur `last_id` par table
  (`GET`/`POST /sync/status/{table}`, `sync.py:492-541`) et n'envoie que les
  `id` supérieurs. Ne fonctionne que sur les tables en insertion pure (§2).
- **`full_nightly`** — nommé explicitement dans `alembic/versions/011_instance_produits_archive.py:5`
  (« Mis à jour par le sync agent lors de chaque full_nightly »). C'est le seul
  endroit du dépôt qui atteste son existence ; son périmètre exact est une
  question ouverte (§6.3).

Le tableau du §2 indique, table par table, laquelle des deux stratégies est
correcte.

---

## §2 — Les 39 tables miroir

### Comment lire les colonnes « source » et « mutabilité »

**Nom HFSQL** — trois noms seulement sont attestés dans le dépôt :
`instance_produits` (`sync.py:262`), `instance_produits_trt` (`sync.py:380`) et
`groupware` (`auth.py:104`), plus la colonne `info_trt`
(`alembic/versions/039_instance_produits_archive_trace.py:6`). Ces trois-là sont
identiques au nom PostgreSQL. Pour les 36 autres, le document note **`≈ identique`** :
c'est une extrapolation à partir des trois cas connus, pas un fait. Voir §6.1.

**Mutabilité** — le contrat serveur traite *toutes* les tables comme mutables
(`ON CONFLICT DO UPDATE` sans exception, `sync.py:180`). La colonne ci-dessous
dit autre chose : si la ligne **HFSQL** change après sa création. C'est ce qui
détermine si un curseur `id > last_id` suffit ou s'il faut un passage complet.

| Classe | Signification |
|---|---|
| **Insertion pure** | ligne figée après création → `id > last_id` suffit |
| **Mutable (en-tête)** | l'en-tête d'un document est réédité → fenêtre glissante |
| **Mutable (agrégat)** | compteurs vivants recalculés en permanence → full |
| **Mutable (état)** | machine à états à plusieurs étapes → full |
| **Supprimable** | la ligne disparaît de HFSQL → pipeline dédié |

**Colonnes PostgreSQL-only** — ajoutées par une migration, absentes de HFSQL.
L'agent ne doit **jamais** les envoyer : `_upsert_batch` ne met à jour que les
colonnes présentes dans le payload (`sync.py:169-179`), c'est précisément ce qui
les protège. Les envoyer les écraserait.

---

### 2.1 — Référentiel pharmaceutique

#### `nomenclature` — fiche produit
`≈ identique` · PK `id` `BIGINT` (pas de séquence : l'ID vient de HFSQL) · **Mutable (agrégat)**

| Colonne | Type | Note |
|---|---|---|
| `id` | BIGINT | PK, `autoincrement=False` |
| `nom` | VARCHAR(150) | indexé |
| `id_famille` / `famille` | BIGINT / VARCHAR(100) | dénormalisé |
| `prix_vente`, `prix_achat_moyen` | NUMERIC(15,4) | |
| `quantite_entree`, `quantite_sortie`, `stock` | NUMERIC(15,4) | **compteurs vivants** |
| `dci`, `dosage`, `conditionnement` | VARCHAR(200) | |
| `id_forme`, `forme`, `forme_abr` | BIGINT / VARCHAR(200) | |
| `id_cnas` | BIGINT | jointure vers `nomenclature_chifa` |
| `psychotrope`, `remb_cvm`, `desactiv_alrt_rup`, `ord_trois_souche` | SMALLINT | booléens 0/1 |
| `qte_alerte` | BIGINT | |
| `de_equiv` | VARCHAR(20) | clé de classe thérapeutique, ex. `14A188` |
| `code_barre_original` | VARCHAR(50) | |
| `cle_compo_nom_cdb` | VARCHAR(200) | indexé, clé composite HFSQL |
| `labo`, `cls_trp` | VARCHAR(200) | |

**PostgreSQL-only — ne pas envoyer :**

| Colonne | Type | Origine |
|---|---|---|
| `generique` | SMALLINT | migration `004:27` |
| `etagere` | VARCHAR(50) | migration `004:34` — responsable d'étagère |
| `archive` | BOOLEAN | migration `014` — produit retiré du marché, positionné à la main |
| `segment_abc`, `segment_xyz` | VARCHAR(1) | migration `014` — recalculés mensuellement par l'APScheduler |
| `disponibilite` | VARCHAR(10) | migration `014` — `oui`/`rupture` recalculés à chaque sync, `quota` manuel |
| `categorie` | VARCHAR(20) | migration `016`, renommée par `017` — `princeps`/`generique`/`generique++` |

> ⚠️ Le commentaire du modèle (`app/models/pharma.py:45`) place la frontière
> PostgreSQL-only *après* `generique` et `etagere`. C'est faux : les deux
> viennent de la migration 004 et sont tout aussi PostgreSQL-only. Un agent qui
> se fierait au commentaire les écraserait.

#### `familles`
`≈ identique` · PK `id` BIGINT · **Mutable (référentiel)** · `famille` VARCHAR(100).

#### `formes`
`≈ identique` · PK `id` BIGINT · **Mutable (référentiel)** · `forme`, `forme_abr` VARCHAR(200).

#### `laboratoires`
`≈ identique` · PK `id` BIGINT · **Mutable (référentiel)** · `labo` VARCHAR(200).
**PostgreSQL-only :** `is_generique` BOOLEAN (migration `016`).

#### `instance_produits` — clients en attente d'ordonnance
**`instance_produits` (attesté, `sync.py:262`)** · PK `id` BIGINT · **Supprimable**

C'est la seule table dont les lignes *disparaissent* de HFSQL (l'ordonnance
arrive → la ligne part). D'où tout le dispositif d'archivage du §3.4.

| Colonne | Type | Note |
|---|---|---|
| `id` | BIGINT | PK |
| `date`, `echeance` | DATE | |
| `heure` | VARCHAR(10) | heure séparée de la date |
| `id_client`, `client` | BIGINT / VARCHAR(100) | **nominatif** |
| `id_nom`, `nom` | BIGINT / VARCHAR(150) | produit |
| `id_famille`, `famille` | INTEGER / VARCHAR(50) | |
| `prix_vente`, `prix_achat_ttc` | NUMERIC(15,4) | |
| `qte_sortie` | BIGINT | |
| `id_produit` | BIGINT | ligne de stock |
| `lot` | VARCHAR(50) | |
| `peremption` | VARCHAR(10) | **date en texte**, format `MM/YYYY` ici (§5) |
| `psychotrope`, `type` | SMALLINT | |
| `n_assure_chifa`, `n_assure_cvm` | VARCHAR(30) | **nominatif** |
| `utilisateur` | VARCHAR(50) | |
| `motif` | VARCHAR(200) | |
| `indice` | VARCHAR(10) | |

**PostgreSQL-only :** `archive` BOOLEAN (migration `011`), `date_archive`
TIMESTAMPTZ et `utilisateur_validation` VARCHAR(50) (migration `022`),
`archive_trace` VARCHAR(50) (migration `039` — `Vente CHIFA` / `Vente Comptoir` /
`Suppression manuelle`, parsé par l'agent depuis `instance_produits_trt.info_trt`).

> 🔒 Cette table contient des données patient. Elle est explicitement citée par
> la règle 6 de CLAUDE.md comme devant être exclue de ce que `chatbot.py` envoie
> à l'API Anthropic.

#### `nomenclature_chifa` — nomenclature CNAS
`≈ identique` · PK `id` BIGINT · **Mutable (référentiel)**

Mêmes colonnes que `nomenclature` (hors colonnes PostgreSQL-only), plus :
`nom_court` VARCHAR(150), `tarif_ref` NUMERIC(15,4), `date_fin_remb` DATE.
`id_cnas` est indexé ici.

---

### 2.2 — Ventes

#### `sorties` — en-tête de vente
`≈ identique` · PK `id` BIGINT · **Mutable (en-tête)** — la colonne `modif`
SMALLINT existe précisément pour tracer la réédition ; `reglement_ult` et
`etat_cloture` bougent après coup.

| Colonne | Type | Note |
|---|---|---|
| `id` | BIGINT | PK |
| `type` | VARCHAR(5) | `'A'` = avoir/retour (filtré partout : `crm.py:140`) |
| `date` | DATE | indexé |
| `heure` | VARCHAR(10) | **texte** — base du pointage (`grh_presence.py:75-76`) |
| `id_client`, `client` | BIGINT / VARCHAR(100) | **nominatif**, indexé |
| `total`, `remise`, `total_a_payer`, `versement`, `benefices` | NUMERIC(15,4) | |
| `utilisateur` | VARCHAR(50) | indexé — **fait foi pour la présence** |
| `poste` | INTEGER | indexé |
| `modif` | SMALLINT | ligne rééditée |
| `type_versement` | VARCHAR(10) | |
| `no_facture_chifa` | VARCHAR(50) | |
| `montant_cnas`, `montant_assure` | NUMERIC(15,4) | |
| `n_assure` | VARCHAR(50) | indexé, **nominatif** |
| `etat_cloture` | SMALLINT | |
| `reglement_ult` | NUMERIC(15,4) | règlement ultérieur — **change après création** |
| `num_assure_cvm`, `ayant_droit_cvm`, `rang_cvm` | VARCHAR(30) / BIGINT / VARCHAR(10) | |
| `cabinet_medical_cvm`, `specialite_cvm` | VARCHAR(200) / VARCHAR(100) | |
| `date_soins_cvm` | DATE | |
| `chronique_cvm` | SMALLINT | |
| `mld_cvm1` … `mld_cvm5` | VARCHAR(10) | 5 colonnes plates au lieu d'une relation |
| `id_facture_cvm` | BIGINT | |
| `pharmnos_num_fact`, `pharmnos_num_assure` | VARCHAR(50) | |
| `pharmnos_total_remb`, `pharmnos_total_non_remb` | NUMERIC(15,4) | |
| `num_fact` | INTEGER | |
| `caisse` | VARCHAR(50) | indexé |
| `id_session` | BIGINT | indexé |
| `mdc` | VARCHAR(200) | médecin |
| `majoration` | NUMERIC(15,4) | |
| `observation` | VARCHAR(200) | |

#### `sorties_produits` — lignes de vente
`≈ identique` · PK `id` BIGINT · **Insertion pure** *(déduction : aucune colonne
`modif`, contrairement à `sorties`)*

`id_sortie` BIGINT · `date` DATE · `type_sortie` VARCHAR(5) · `id_client`,
`client` · `id_nom`, `nom` · `id_famille` INTEGER, `famille` VARCHAR(50) ·
`prix_vente`, `prix_achat_ttc` NUMERIC(15,4) · `qte_sortie` BIGINT ·
`heure` VARCHAR(10) · `poste` INTEGER · `id_produit` BIGINT · `lot` VARCHAR(50) ·
`peremption` **VARCHAR(10) — format `MM/YY` ici, pas `MM/YYYY` (§5, §6.2)** ·
`no_facture_chifa` VARCHAR(50) · `psychotrope`, `remb_cvm` SMALLINT ·
`pharmnos_num_fact` VARCHAR(50) · `caisse` VARCHAR(50) idx · `id_session` BIGINT idx ·
`utilisateur` VARCHAR(50) · `mdc` VARCHAR(200).

> C'est la table de base du calcul des primes (`performance.py`). Toute erreur de
> synchronisation ici se traduit en erreur de paie.

---

### 2.3 — Achats et fournisseurs

#### `entrees` — en-tête de réception
`≈ identique` · PK `id` BIGINT · **Mutable (en-tête)** — `modif`, `ouverte`,
`reglement`, `montant_difference` évoluent après création.

`type` VARCHAR(5) · `date` DATE idx · `heure` VARCHAR(10) · `date_piece` DATE ·
`id_fournisseur` BIGINT idx, `fournisseur` VARCHAR(100) ·
`total_ht`, `total_tva`, `total_ttc`, `remise`, `total_a_payer`, `total_ppa`,
`total_shp`, `reglement`, `montant_facture`, `montant_difference` NUMERIC(15,4) ·
`num_bl`, `num_fact` VARCHAR(50) · `num_avoir` VARCHAR(30) ·
`motif_avoir` VARCHAR(200) · `attach_bc` VARCHAR(50) · `echeance` DATE ·
`type_achat` VARCHAR(10) · `type_psy`, `avoir_financier`, `modif`, `ouverte` SMALLINT ·
`utilisateur` VARCHAR(50) · `poste` INTEGER · `observations` VARCHAR(1000).

#### `entrees_produits` — lignes de réception
`≈ identique` · PK `id` BIGINT · **Insertion pure**, sauf `bloque` et
`last_modif_inv_tourn` *(déduction : les deux impliquent une reprise ultérieure)*

`id_entree` BIGINT idx · `date_entree` DATE · `type_entree` VARCHAR(10) ·
`id_fournisseur` INTEGER, `fournisseur` VARCHAR(100) · `id_nom` BIGINT,
`nom` VARCHAR(150) idx · `marge` NUMERIC(15,4) · `id_famille` INTEGER,
`famille` VARCHAR(50) · `prix_achat`, `prix_vente`, `shp`, `tva`,
`prix_achat_ttc`, `ppa` NUMERIC(15,4) · `qte_entree`, `stock` BIGINT ·
`code_barre` VARCHAR(30) idx · `num_bl`, `num_fact` VARCHAR(50) ·
`poste` INTEGER · `utilisateur` VARCHAR(50) · `observation` VARCHAR(100) ·
`peremption` VARCHAR(10) **et** `peremption_date` DATE — les deux coexistent ·
`lot` VARCHAR(50) · `id_cnas` BIGINT · **`id_produit` NUMERIC(15,4) — un
identifiant typé en décimal (§5)** · `indice` VARCHAR(200) · `id_echange` BIGINT ·
`type_achat` VARCHAR(10) · `psychotrope`, `bloque` SMALLINT · `num_avoir` VARCHAR(30) ·
`de_equiv` VARCHAR(20) idx · `date_piece` DATE · `last_modif_inv_tourn` BIGINT ·
`labo`, `cls_trp` VARCHAR(200) · `heure` VARCHAR(10).

#### `fournisseurs`
`≈ identique` · PK `id` BIGINT · **Mutable (agrégat)** — `achats`, `avoirs`,
`versements`, `remboursements`, `solde_actuel` sont des compteurs vivants.

`fournisseur` VARCHAR(100) idx · `adresse` VARCHAR(200) · `ville` VARCHAR(100) ·
`telephone`, `fax`, `mobile`, `email`, `banque` VARCHAR(100) ·
`achats`, `avoirs`, `versements`, `remboursements`, `solde_actuel`,
`solde_initial` NUMERIC(15,4) · `mode_qr`, `code_efacture` SMALLINT ·
`filiale_efacture` VARCHAR(20).

#### `commandes_fournisseurs`
`≈ identique` · **PK `id` INTEGER** (et non BIGINT) · **Mutable (en-tête)** — `sync` SMALLINT
suggère un drapeau d'export côté EASYPHARM, donc rééditable.

`ref` VARCHAR(20) · `fournisseur` VARCHAR(100) · `date` DATE ·
`utilisateur` VARCHAR(50) · `poste`, `type_psy`, `sync` SMALLINT ·
`observation` VARCHAR(200) · `nbr_prod` INTEGER.

#### `commandes_fournisseurs_produits`
`≈ identique` · **PK `id` INTEGER** · **Insertion pure** *(déduction)*

`id_commande` BIGINT idx · `ref_commande` VARCHAR(20) · `date_commande` DATE ·
`fournisseur` VARCHAR(100) · `produit` VARCHAR(200) · `quantite` BIGINT ·
`utilisateur` VARCHAR(50) · `poste` INTEGER · `type_psy` SMALLINT ·
`stock`, `p_achat`, `taux_ug` NUMERIC(15,4) · `offsettt` INTEGER ·
`per` VARCHAR(10) — encore une péremption en texte.

---

### 2.4 — Clients

#### `clients`
`≈ identique` · PK `id` BIGINT · **Mutable (agrégat)** — `ventes`, `versements`,
`credit` bougent à chaque passage ; les droits CNAS aussi.

| Colonne | Type | Note |
|---|---|---|
| `client` | VARCHAR(100) | indexé — **nominatif** |
| `code_barre_client` | VARCHAR(100) | |
| `adresse`, `ville`, `telephone`, `fax`, `email` | VARCHAR(100-200) | **nominatif** |
| `ventes`, `versements`, `credit`, `solde_initial`, `solde_max` | NUMERIC(15,4) | compteurs vivants |
| `n_assure_chifa` | VARCHAR(20) | indexé — **nominatif** |
| `num_assure_cvm`, `num_assure_pharmnos` | VARCHAR(30) | **nominatif** |
| `num_ccp`, `reg_com`, `nif`, `ai`, `nis` | VARCHAR(30) | |
| `date_naissance`, `date_ctl` | DATE | **donnée de santé / identité** |
| `sexe`, `situation_familiale`, `type_militaire` | SMALLINT | codes |
| `chronique` | SMALLINT | **donnée de santé** |
| `pathologie` | VARCHAR(200) | **donnée de santé en clair** |
| `num_carte_chronique` … `num_carte_chronique5` | VARCHAR(30) | 5 colonnes plates |
| `date_exp_droits` … `date_exp_droits5` | DATE | 5 colonnes plates |
| `date_deliv_carte_chronique` | DATE | |
| `nom_cvm`, `prenom_cvm` | VARCHAR(100) | **nominatif** |
| `blk_comptoir`, `blk_chifa`, `blk_cvm`, `blk_instance` | SMALLINT | blocages |
| `activer_solde_max` | SMALLINT | |

**PostgreSQL-only :** `is_archive` BOOLEAN, `date_archive` DATE,
`motif_archive` VARCHAR(200) (migration `030`) — décès, doublon, inactif définitif.
Voir §6.7 : **aucun endpoint n'écrit ces colonnes**, alors que `crm.py` les lit
partout.

---

### 2.5 — Caisse et trésorerie

Les schémas de `caisses` et `caisses_regies` ont été alignés sur HFSQL par la
migration `002` (« full schema matching HFSQL ») : leurs colonnes sont donc
fiables, même si le nom de fichier source reste `≈`.

#### `caisses`
**PK `id` INTEGER** · **Mutable (état)** · `caisse` VARCHAR(50) idx ·
`date_creation` DATE · `etat` SMALLINT.

#### `caisses_regies` — sessions de caisse
PK `id` BIGINT · **Mutable (état)** — la ligne est créée à l'ouverture et
complétée à la clôture (`date_fin`, `heure_fin`, `total_reel`, `etat_cloture`).

`date_debut`, `date_fin` DATE · `heure_debut`, `heure_fin` VARCHAR(10) ·
`fond_de_caisse`, `total_calcule`, `total_reel` NUMERIC(15,4) ·
`etat_cloture`, `modif` SMALLINT · `poste` INTEGER ·
`util_ouvre`, `util_cloture` VARCHAR(50) ·
`ventes`, `retours`, `versements_clients`, `remboursements_clients`,
`versements_fournisseurs`, `remboursements_fournisseurs`, `alimentations`,
`depenses`, `virement_de_fond_entrant`, `virement_de_fond_sortant` NUMERIC(15,4) ·
`indice_ouverture` NUMERIC(10,4).

#### `suivi_caisses`
PK `id` BIGINT · **Mutable (état)** · mêmes colonnes que `caisses_regies`,
sans `poste`/`modif`, plus `caisse` VARCHAR(50) idx et `ecart` NUMERIC(15,4).

#### `operations` — mouvements de trésorerie
`≈ identique` · PK `id` BIGINT · **Mutable (en-tête)** — `modif` et `cloture` existent.

`date` DATE idx · `heure` VARCHAR(10) · `operation` VARCHAR(50) ·
`montant` NUMERIC(15,4) · `observation` VARCHAR(100) · `utilisateur` VARCHAR(50) ·
**`id_relatif` NUMERIC(15,4) — identifiant en décimal (§5)** · `modif` SMALLINT ·
`origine`, `destinataire` VARCHAR(100) · `id_tier` BIGINT · `mode`, `ref` VARCHAR(50) ·
`n_assure` VARCHAR(50) idx · `n_facture_chifa`, `n_bordereau_chifa` VARCHAR(30) ·
`cloture` SMALLINT · **`indice_creation` NUMERIC(20,0) — horodatage concaténé
`AAAAMMJJHHMMSSmm`, cf. migration `010`** · `mois_cvm` VARCHAR(10) ·
`num_bord_pharmnos` VARCHAR(30) · `num_fact_cvm_4eme` INTEGER ·
`id_session` BIGINT idx · `id_ph_echange` INTEGER.

#### `depenses`
`≈ identique` · PK `id` BIGINT · **Mutable (référentiel)** · une seule colonne :
`depense` VARCHAR(100). Miroir manifestement tronqué — voir §6.9.

#### `comptes_bancaires`
`≈ identique` · **PK `id` INTEGER** · **Mutable (référentiel)** ·
`compte` VARCHAR(500) · `date_creation` DATE.

---

### 2.6 — CHIFA / CNAS

Schémas alignés sur HFSQL par les migrations `001` (bordereaux) et `003`
(rejets partiels).

#### `bordereaux_chifa`
PK `id` BIGINT · **Mutable (état)** — machine à états à cinq étapes :
`dt_creation` → `dt_cloture` → `dt_depot` → `dt_validation` → `dt_encaisse`,
chacune avec son champ `obs_*`. Une ligne reste modifiable pendant des mois.

`num_bord` VARCHAR(50) idx · `centre` VARCHAR(50) idx · `nbr_fact` INTEGER ·
`mnt_assure`, `mnt_officine`, `mnt_fae`, `mnt_majoration`, `mnt_rej`,
`versement` NUMERIC(15,4) · `observation` VARCHAR(200) ·
`dt_cloture`, `dt_validation`, `dt_encaisse`, `dt_depot`, `dt_creation` DATE ·
**`archive` SMALLINT — attention : celui-ci vient de HFSQL** (§5) ·
`statut` VARCHAR(50) · `extra` VARCHAR(2000) — blob non décodé ·
`obs_creation`, `obs_cloture`, `obs_depot`, `obs_validation`,
`obs_encaissement` VARCHAR(200).

#### `factures_chifa`
`≈ identique` · PK `id` BIGINT · **Mutable (état)** — `annule`, `destocke`, `rej`
basculent après création.

`officine`, `centre`, `centre_as` VARCHAR(100) · `no_assure` VARCHAR(100)
**nominatif** · `rang_ad` VARCHAR(100) · `d_soins`, `date_fact` DATE ·
`no_bordereau_fact` VARCHAR(100) · `mt_assure`, `mt_officine`, `maj_fact`,
`mt_maj` NUMERIC(15,4) · `type_maj` VARCHAR(100) · `no_facture` VARCHAR(100) idx ·
`destocke`, `annule`, `rej` SMALLINT · `signature`, `trace_destockage` VARCHAR(20) ·
`code_affect` VARCHAR(10) · `motif_annulation` VARCHAR(100) ·
**`txt_prod` VARCHAR(10000) — blob encodé HFSQL, format
`[a[a[id_cnas|prix|qte|…|&]}…]a]a]`, décodé au regex dans `chifa.py:231-260`**.

> 🔒 `txt_prod` contient le détail des médicaments délivrés, rattaché à un
> `no_assure`. C'est de la donnée patient au sens de la Partie 3 de CLAUDE.md.

#### `factures_chifa_produits`
`≈ identique` · PK `id` BIGINT · **Insertion pure** *(déduction)* ·
`num_enr`, `num_enr_prescrit` BIGINT · `prix_ppa`, `mt_assure`,
`mt_officine` NUMERIC(15,4) · `quantite` BIGINT · `no_fact` VARCHAR(50).

#### `chifa_rejet_partiel`
PK `id` BIGINT · **Insertion pure** *(déduction)* · `num_bordereau`,
`num_facture` VARCHAR(30) · `montant` NUMERIC(15,4) · `observation` VARCHAR(500).

> `facture_anomalies` et `facture_rejets` (`app/models/chifa.py:90-115`) sont
> **hors contrat de sync** : PK auto-incrémentée, absentes de `SYNC_REGISTRY`,
> alimentées par `chifa.py`. Ne pas les confondre avec les miroirs.

---

### 2.7 — Configuration

#### `pharmacies`
`≈ identique` · PK `id` BIGINT · **Mutable (référentiel)** ·
`pharmacie` VARCHAR(100) · `adresse` VARCHAR(200) · `ville`, `telephone`, `fax`,
`mobile`, `email` VARCHAR(100) · `ecart_initial` NUMERIC(15,4).

#### `postes` — configuration des postes de travail
`≈ identique` · PK `id` BIGINT · **Mutable (référentiel)**

30 colonnes de paramétrage matériel : `km`, `enr`, `dngl` BIGINT ·
`langue` VARCHAR(10) · `etat_caisse`, `sauvegarde_a_partir_ce_poste`,
`gerer_tiroir_caisse`, `port_tiroir_caisse`, `gerer_imp_tk`,
`type_impression_ticket`, `port_imp_tk`, `ouv_tir_caisse`, `recherche_vente`,
`sur_comptoir`, `type_imp_cdb`, `serveur_chifa`, `ent_easychifa`,
`ident_vend_chaq_vnt`, `quitter_agent_ect` SMALLINT ·
`att_ect_1` … `att_ect_4` INTEGER · `image_fond` VARCHAR(200) ·
`nom_imp_cdb` VARCHAR(50) · `imprimante_tk` VARCHAR(100) ·
`chemin_chifa_local` VARCHAR(500) · `nom_pc` VARCHAR(50) ·
`caisse_associee` VARCHAR(50) · **`cim_test` VARCHAR(5000) — blob non décodé (§5)**.

#### `groupware` — comptes utilisateurs EASYPHARM
**`groupware` (attesté, `auth.py:104`)** · PK `id` BIGINT · **Mutable (référentiel)**

`utilisateur` VARCHAR(50) · **`mot_de_passe` VARCHAR(100) — en clair** ·
`nom`, `prenom` VARCHAR(100) · `role` INTEGER · `actif` SMALLINT.

> 🔴 **Priorité haute.** Les mots de passe de tout le personnel traversent l'API
> en clair dans un batch de sync, puis servent de source d'authentification
> (`auth.py:104`, voie 3 du login). Un batch `groupware` déclenche en plus un
> post-hook qui propage les comptes vers `users` avec un hash bcrypt
> (`sync.py:192-241`) — le hachage n'a lieu qu'*après* le transport en clair.
> `id = 1` reçoit le rôle `admin`, tous les autres `employee` (`sync.py:221`).

#### `prestations`
`≈ identique` · **PK `id` INTEGER** · **Mutable (référentiel)** ·
`prestation` VARCHAR(100) · `prix` NUMERIC(15,4).

#### `motif_instance`
`≈ identique` · PK `id` BIGINT · **Mutable (référentiel)** · `motif` VARCHAR(200).
Miroir tronqué — voir §6.9.

---

### 2.8 — Divers

#### `mouchard` — journal d'audit EASYPHARM
`≈ identique` · PK `id` BIGINT · **Insertion pure** — c'est un journal.

`date` DATE idx · `heure` VARCHAR(10) · `utilisateur` VARCHAR(50) ·
`poste` INTEGER · `action` VARCHAR(100) · `description` VARCHAR(200).

Puis, en colonnes plates, l'avant/après de chaque type d'opération — suffixes
`_ini` / `_fin` :

- vente : `vnt_tier_*` VARCHAR(100), `vnt_montant_*`, `vnt_versement_*` NUMERIC(15,4)
- achat : `ach_date_*` DATE, `ach_fournisseur_*` VARCHAR(100), `ach_type_*` VARCHAR(20),
  `ach_num_fact_*`, `ach_num_bl_*` VARCHAR(50), `ach_total_ppa_*`,
  `ach_total_a_payer_*`, `ach_remise_*` NUMERIC(15,4), `ach_ech_*` DATE
- stock : `stk_ppa_*` NUMERIC(15,4), `stk_lot_*`, `stk_cdb_*` VARCHAR(50),
  **`stk_per_*` VARCHAR(10) — péremption en texte**, `stk_prod` VARCHAR(200),
  `stk_blok_*` SMALLINT
- caisse : `op_caisse_*`, `op_tier_*` VARCHAR(100-150), `op_montant_*` NUMERIC(15,4),
  `op_mode_*`, `op_ref_*` VARCHAR(50), `op_obs_*` VARCHAR(200)

> 54 colonnes — la table la plus large du miroir. `_upsert_batch` en tire
> `chunk_size = 65000 // 54 = 1203` lignes par requête (`sync.py:165`).

#### `mouchard_details`
`≈ identique` · PK `id` BIGINT · **Insertion pure** · `id_mouchard` BIGINT idx ·
`produit` VARCHAR(200) · `prix_achat_ttc`, `ppa` NUMERIC(15,4) · `lot` VARCHAR(50) ·
`per` VARCHAR(10) · `sts` VARCHAR(5) · `qte` INTEGER.

#### `ordonnancier` — registre des psychotropes
`≈ identique` · PK `id` BIGINT · **Insertion pure** (registre légal)

`num` BIGINT · `date` DATE idx · `date_soin` DATE · `ordonnateur` VARCHAR(50) ·
`client`, `adresse` VARCHAR(50) **nominatif** · `num_cin` VARCHAR(20)
**pièce d'identité** · `observation` VARCHAR(200) · `utilisateur` VARCHAR(30) ·
**`id_vente` NUMERIC(15,4) — identifiant en décimal (§5)** · `id_vente_2` BIGINT ·
`adresse_medecin` VARCHAR(50) · `type`, `mld_lui_meme` SMALLINT ·
`porteur` VARCHAR(200), `porteur_adresse` VARCHAR(50), `porteur_cin` VARCHAR(20) ·
**`txt_duree` VARCHAR(5000) — blob non décodé** · `age_malade` SMALLINT ·
`taille_malade`, `poids_malade` VARCHAR(10) — **données de santé, en texte** ·
`structure_ordo` VARCHAR(100) · `num_serie_ordo`, `prescripteur_ordre` VARCHAR(20).

> 🔒 Table la plus sensible du miroir : identité, CIN, âge, taille, poids,
> médecin prescripteur, psychotropes.

#### `echanges` / `echanges_sorties_produits` — échanges inter-pharmacies
`≈ identique` · PK `id` BIGINT · **Insertion pure** *(déduction, `modif` présent
sur l'en-tête → en-tête plutôt mutable)*

`echanges` : `type` VARCHAR(5) · `date` DATE · `heure` VARCHAR(10) ·
`id_pharmacie` BIGINT, `pharmacie` VARCHAR(100) · `total` NUMERIC(15,4) ·
`utilisateur` VARCHAR(50) · `poste` INTEGER · `modif`, `contient_psy` SMALLINT.

`echanges_sorties_produits` : `id_produit` BIGINT · **`id_nom` NUMERIC(15,4)** ·
`nom` VARCHAR(150) · **`id_famille` SMALLINT** (BIGINT ailleurs) ·
`famille` VARCHAR(50) · `prix_achat_ttc`, `prix_vente` NUMERIC(15,4) ·
`qte` BIGINT · `lot` VARCHAR(50) · `peremption` VARCHAR(10) ·
`id_echange` BIGINT idx · `id_pharmacie`, `pharmacie` · `date_echange` DATE ·
`psychotrope` SMALLINT · `heure` VARCHAR(10).

#### `reg_client_association` / `reg_fourn_association` — ventilation des règlements
`≈ identique` · PK `id` BIGINT · **Insertion pure**

Colonnes identiques des deux côtés, à la clé étrangère près :
`id_operation` BIGINT · `id_vente` (clients) / `id_entree` (fournisseurs) BIGINT ·
`tranche` NUMERIC(15,4) · `date` DATE · `mode`, `ref` VARCHAR(50) ·
`observation` VARCHAR(100) · `utilisateur` VARCHAR(50).

#### `pharmnos_factures`
`≈ identique` · PK `id` BIGINT · **Mutable (état)** — `destocke`, `annule` basculent.

`matricule` VARCHAR(20) **nominatif** · `num_dec` VARCHAR(20) idx ·
`date_soin`, `date_dec` DATE · `taux` INTEGER ·
`total_ppa`, `total_remb`, `total_non_remb`, `majoration`, `fae` NUMERIC(15,4) ·
`num_brd` VARCHAR(20) · `destocke`, `annule` SMALLINT.

---

### 2.9 — Inventaires

Créées par la migration `004:38-71` avec `id BIGINT PRIMARY KEY` sans séquence :
l'ID vient donc de l'extérieur, et les deux tables sont dans `SYNC_REGISTRY`.
Leur forme (`heure` VARCHAR(10), `peremption` VARCHAR(10)) est celle des autres
miroirs. Origine HFSQL **probable mais non attestée** — voir §6.

#### `inventaires`
PK `id` BIGINT · **Mutable (état)** — `etat` SMALLINT (0 = ouvert, 1 = validé).
`date` DATE idx · `heure` VARCHAR(10) · `utilisateur` VARCHAR(50) ·
`poste` INTEGER · `observations` VARCHAR(500).

#### `inventaires_produits`
PK `id` BIGINT · **Mutable** jusqu'à validation de l'inventaire parent.
`id_inventaire` BIGINT idx · `date` DATE idx · `id_nom`, `nom` ·
`id_famille` INTEGER, `famille` VARCHAR(50) · `code_barre` VARCHAR(30) ·
`lot` VARCHAR(50) · `peremption` VARCHAR(10) **et** `peremption_date` DATE ·
`stock_theorique`, `stock_reel`, `ecart` BIGINT (`ecart` = réel − théorique,
négatif = perte) · `prix_achat_ttc`, `prix_vente` NUMERIC(15,4) ·
`motif` VARCHAR(200) · `utilisateur` VARCHAR(50) · `poste` INTEGER.

---

### 2.10 — Récapitulatif de la stratégie de passage

| Stratégie | Tables |
|---|---|
| **Incrémental `id > last_id`** possible | `sorties_produits`, `entrees_produits`, `factures_chifa_produits`, `chifa_rejet_partiel`, `mouchard`, `mouchard_details`, `ordonnancier`, `echanges_sorties_produits`, `reg_client_association`, `reg_fourn_association`, `commandes_fournisseurs_produits` |
| **Fenêtre glissante** (en-têtes réédités) | `sorties`, `entrees`, `operations`, `echanges`, `commandes_fournisseurs` |
| **Full obligatoire** (agrégats / états) | `nomenclature`, `nomenclature_chifa`, `familles`, `formes`, `laboratoires`, `clients`, `fournisseurs`, `caisses`, `caisses_regies`, `suivi_caisses`, `depenses`, `comptes_bancaires`, `bordereaux_chifa`, `factures_chifa`, `pharmnos_factures`, `pharmacies`, `postes`, `groupware`, `prestations`, `motif_instance`, `inventaires`, `inventaires_produits` |
| **Pipeline dédié** | `instance_produits` (§3.4) |

> Ce classement est une **déduction** tirée de la forme des colonnes. Il n'est
> confirmé nulle part dans le dépôt : voir §6.3.

---

## §3 — Le protocole

### 3.1 — Authentification

Les routes `/sync/*` dépendent toutes de `get_current_user`
(`app/core/security.py:49`). L'agent doit présenter un JWT.

**Obtention du jeton** — `POST /api/v1/auth/login`, en
`application/x-www-form-urlencoded` (FastAPI `OAuth2PasswordRequestForm`,
`auth.py:96`), **pas** en JSON :

```http
POST /api/v1/auth/login HTTP/1.1
Content-Type: application/x-www-form-urlencoded

username=sync_agent&password=<mot de passe>
```

Réponse :

```json
{ "access_token": "eyJhbGciOiJIUzI1NiIs…", "token_type": "bearer" }
```

Identifiants côté serveur : `settings.sync_agent_username` /
`settings.sync_agent_password` (`app/core/config.py:26-27`), comparés en clair
avant tout accès base (`auth.py:108-113`). Le jeton porte `role: "sync_agent"`.

**Durée de vie : 60 minutes** (`access_token_expire_minutes`,
`config.py`). Un full nightly long doit donc renouveler son jeton en cours de
route, ou anticiper le `401`.

**Appels de sync :**

```http
POST /api/v1/sync/sorties HTTP/1.1
Authorization: Bearer <access_token>
Content-Type: application/json
```

> 🔴 **Priorité haute — le rôle n'est jamais vérifié.** `get_current_user`
> (`security.py:49-54`) décode le jeton et renvoie `{username, role}` sans
> contrôler quoi que ce soit ; aucune route de `sync.py` n'inspecte `role`.
> Le rôle `sync_agent` est émis mais inutilisé. Conséquence : **n'importe quel
> compte `groupware` authentifié peut écraser les 39 tables miroir**, y compris
> avec un mot de passe issu de HFSQL en clair. À rapprocher de
> `allow_origins=["*"]` dans `main.py:110`.

### 3.2 — `POST /api/v1/sync/{table}`

**Corps** — `SyncBatchPayload` (`app/schemas/sync.py:5-7`) :

```json
{
  "records": [
    { "id": 480912, "date": "2026-08-19", "total": "1450.0000", "…": "…" },
    { "id": 480913, "date": "2026-08-19", "total": "890.5000",  "…": "…" }
  ]
}
```

`records` est une `list[dict[str, Any]]` : **Pydantic ne valide rien**. Ni les
noms de colonnes, ni les types, ni la présence de `id`. Tout le contrôle est
dans `_clean_record` (`sync.py:99-137`), qui **filtre silencieusement**.

**Traitement, étape par étape** (`sync.py:140-187`) :

1. `_clean_record` retire toute clé absente du modèle SQLAlchemy — aucune erreur,
   aucun log (`sync.py:108`, `sync.py:121-122`).
2. Les chaînes destinées à une colonne `Date` sont parsées en `%Y-%m-%d`
   (`sync.py:127`) ; **échec → `None` silencieux** (`sync.py:128-129`).
3. Les chaînes destinées à une colonne `Numeric` deviennent des `Decimal`
   (`sync.py:132`) ; **échec → `None` silencieux**.
4. Découpage en sous-lots de `65000 // nombre_de_colonnes_du_modèle` lignes
   (`sync.py:165`), pour rester sous la limite de 65 535 paramètres liés de
   PostgreSQL. Un `commit` par sous-lot.
5. `INSERT … ON CONFLICT (id) DO UPDATE` (`sync.py:178-180`).

**Clé de conflit : `id`, toujours, en dur.** `index_elements=["id"]`
(`sync.py:180`). Une table dont l'unicité HFSQL ne serait pas portée par `id`
est hors contrat.

**Colonnes mises à jour en cas de conflit** — celles présentes dans le payload,
`id` exclu (`sync.py:169-179`). C'est le mécanisme qui préserve les colonnes
PostgreSQL-only du §2.

**Réponse** — `SyncBatchResult` (`schemas/sync.py:10-14`), toujours `200` :

```json
{ "table": "sorties", "synced": 1200, "errors": 0 }
```

- `synced` compte les lignes **envoyées** dans les sous-lots réussis, pas les
  lignes réellement insérées ou modifiées.
- `errors` compte les lignes des sous-lots **rejetés**. Un sous-lot en échec est
  intégralement `rollback` (`sync.py:184-187`).

**Table inconnue** — `404`, avec la liste blanche complète dans `detail`
(`sync.py:472-476`) :

```json
{ "detail": "Table 'toto' inconnue. Tables disponibles: ['bordereaux_chifa', …]" }
```

**Payload vide** — `{"records": []}` renvoie `{"table": …, "synced": 0}` sans
toucher la base (`sync.py:479-480`).

**Post-hook `groupware`** — un batch sur cette table déclenche
`_sync_groupware_to_users` (`sync.py:486-487`), qui relit **toute** la table
`groupware` et propage les comptes vers `users` en bcrypt. Le coût est donc
proportionnel au nombre total de comptes, pas à la taille du batch.

### 3.3 — Cinq exigences que le code impose sans les documenter

Chacune est vérifiable ; aucune n'est signalée à l'agent en cas de violation.

**1. Toutes les lignes d'un batch doivent porter exactement le même jeu de clés.**
`pg_insert(model.__table__).values(chunk)` (`sync.py:174`) compile la liste des
colonnes à partir du **premier** dict du lot, et `payload_cols` est lu sur
`cleaned[0]` seul (`sync.py:169`). Une ligne portant une clé absente de la
première ligne fait échouer tout le sous-lot ; une colonne absente de la première
ligne mais présente ailleurs n'est jamais mise à jour. Corollaire pratique : il
faut envoyer **toutes** les colonnes de la table, `null` compris, plutôt que
d'omettre les valeurs vides.

**2. Les montants doivent partir en chaînes de caractères, pas en nombres JSON.**
`_clean_record` ne convertit en `Decimal` que ce qui arrive en `str`
(`sync.py:130-132`). Un nombre JSON est décodé en `float` Python, transmis tel
quel à asyncpg, et arrondi en binaire **avant** d'atteindre la colonne
`NUMERIC(15,4)`. C'est exactement ce que la règle « Argent » de CLAUDE.md
(Partie 3) interdit. Écrire `"total": "1450.0000"`, jamais `"total": 1450.0`.

**3. Les dates doivent être au format `YYYY-MM-DD` strict.**
`strptime(v, "%Y-%m-%d")` (`sync.py:127`). Un `2026-08-19T00:00:00`, un
`19/08/2026` ou un `2026-8-19` deviennent **`None`**, sans exception, sans log,
et le `200` renvoyé annonce `errors: 0`. C'est le mode de défaillance le plus
insidieux du contrat : une date perdue ne se voit qu'en aval, dans un KPI.

**4. Les colonnes `DateTime` ne sont pas converties.** `_clean_record` ne traite
que `Date` et `Numeric` (`sync.py:110-118`). La seule colonne `TIMESTAMPTZ` d'une
table du registre est `instance_produits.date_archive`, qui est PostgreSQL-only
et ne doit donc jamais être envoyée par la route générique.

**5. `errors > 0` arrive avec un `200`.** Il n'y a pas de code HTTP d'échec
partiel. L'agent doit lire `errors` dans le corps et rejouer le lot lui-même —
sans quoi les lignes du sous-lot rejeté sont perdues silencieusement.

### 3.4 — Le pipeline `instance_produits`

Cette table est la seule dont les lignes **disparaissent** de HFSQL : quand
l'ordonnance arrive, EASYPHARM supprime la ligne. Un upsert ne peut pas
représenter une suppression, d'où trois endpoints dédiés, déclarés **avant** la
route générique dans le fichier (l'ordre compte pour le routage FastAPI).

#### `POST /api/v1/sync/instance_produits/batch` (`sync.py:255`)

« Étape 1 du full sync séquentiel » selon la docstring. Upsert des instances
**actives**, en SQL brut sur 23 colonnes fixes, avec `archive = FALSE` forcé et
`date_archive`, `utilisateur_validation`, `archive_trace` remis à `NULL`
(`sync.py:298-337`).

Conversions locales, distinctes de `_clean_record` : `date` et `echeance` via
`date.fromisoformat` (donc **plus permissif** que la route générique), `prix_vente`
et `prix_achat_ttc` en `Decimal` (`sync.py:268-284`). Les lignes sans `id` sont
ignorées (`sync.py:288`).

Réponse : `{"table": "instance_produits", "synced": N}`.

#### `POST /api/v1/sync/instance_produits_trt` (`sync.py:373`)

Reçoit les instances **traitées**, depuis la table HFSQL `instance_produits_trt`
(attesté). Upsert dans la même table PostgreSQL avec `archive = TRUE`.

L'agent doit avoir **déjà parsé** la colonne HFSQL `info_trt` en trois champs
(`sync.py:393-395`, migration `039`) :

| Champ attendu | Type | Valeurs |
|---|---|---|
| `archive_trace` | str | `Vente CHIFA` \| `Vente Comptoir` \| `Suppression manuelle` |
| `utilisateur_validation` | str | employé ayant transformé l'instance en vente |
| `date_archive` | str ISO | parsé côté serveur par `datetime.fromisoformat` (`sync.py:400`) |

Les trois sont écrits en `COALESCE(EXCLUDED.x, instance_produits.x)`
(`sync.py:448-450`) : une valeur nulle ne détruit pas une trace existante.

> ⚠️ **Asymétrie à connaître** : cet endpoint ne convertit **ni les dates ni les
> décimaux** des 23 colonnes standard — contrairement à `/batch`. Les valeurs
> sont passées telles quelles à un `text()` sans typage (`sync.py:452-453`), donc
> asyncpg reçoit une `str` pour une colonne `DATE` ou `NUMERIC`. Voir §6.6.

#### `POST /api/v1/sync/instance_produits/finalize` (`sync.py:346`)

Corps : `{"active_ids": [1, 2, 3]}`. Réponse :
`{"archived": 0, "restored": N}`.

La docstring le dit : « Outil de récupération manuelle (non appelé par le sync
automatique) ». Il ne fait plus que **restaurer** `archive = FALSE` pour les IDs
fournis (`sync.py:360-366`) ; `archived` est renvoyé à **`0` en dur**
(`sync.py:370`). Son nom et son champ `archived` sont les vestiges d'un
comportement disparu — voir §6.5.

### 3.5 — Suivi de progression

#### `GET /api/v1/sync/status/{table}` (`sync.py:492`)

```json
{ "table": "sorties", "last_id": 480913, "total_synced": 128400 }
```

Table absente → `{"last_id": 0, "total_synced": 0}`, pas de `404`
(`sync.py:504-505`).

#### `POST /api/v1/sync/status/{table}` (`sync.py:514`)

```json
{ "last_id": 481500, "count": 587 }
```

⚠️ **`count` est cumulé, pas remplacé** : `total_synced = total_synced + count`
(`sync.py:531`). En revanche la réponse renvoie le `count` du seul appel, pas le
cumul (`sync.py:540`) — donc la valeur renvoyée ne correspond pas à celle qui
vient d'être stockée.

Le nom de table n'est pas validé ici : `sync_status` accepte n'importe quelle
chaîne comme clé (`app/models/sync_status.py:12`).

**Aucun autre module du dépôt ne lit `sync_status`.** Elle n'est qu'un
presse-papier à l'usage exclusif de l'agent — voir §6.4.

---

## §4 — Comment le nom de table est validé

**Réponse nette : le nom de table n'est jamais interpolé dans du SQL. Il n'y a
pas de vecteur d'injection par cette voie.**

Le mécanisme (`sync.py:472`) :

```python
model = SYNC_REGISTRY.get(table_name)
if not model:
    raise HTTPException(404, detail=f"Table '{table_name}' inconnue…")
```

`SYNC_REGISTRY` (`sync.py:47-97`) est un `dict` littéral figé à l'import,
associant une chaîne à une **classe SQLAlchemy**. L'écriture se fait ensuite via
`pg_insert(model.__table__)` (`sync.py:174`) : le nom de la table provient de
l'objet `Table`, jamais de la chaîne HTTP. Une clé absente ne produit aucune
requête. C'est une liste blanche stricte au sens propre.

Les deux endpoints en SQL brut (`sync.py:298`, `sync.py:411`) ciblent
`instance_produits` en dur et passent toutes les valeurs en paramètres liés
(`:id`, `:date`, …). Le `**rec` répandu dans le dict de paramètres
(`sync.py:290`, `sync.py:452`) ne transporte que des **valeurs**, jamais du SQL.

**La liste blanche — 39 entrées** (`sync.py:47-97`) :

```
bordereaux_chifa                    instance_produits
caisses                             inventaires
caisses_regies                      inventaires_produits
chifa_rejet_partiel                 laboratoires
clients                             motif_instance
commandes_fournisseurs              mouchard
commandes_fournisseurs_produits     mouchard_details
comptes_bancaires                   nomenclature
depenses                            nomenclature_chifa
echanges                            operations
echanges_sorties_produits           ordonnancier
entrees                             pharmacies
entrees_produits                    pharmnos_factures
factures_chifa                      postes
factures_chifa_produits             prestations
familles                            reg_client_association
formes                              reg_fourn_association
fournisseurs                        sorties
groupware                           sorties_produits
                                    suivi_caisses
```

Les clés du registre sont identiques aux `__tablename__` des modèles : aucun
alias, aucune indirection.

### Ce qui, en revanche, mérite une priorité haute

L'injection SQL n'est pas le problème de ce module. Deux autres le sont :

1. **Aucun contrôle de rôle sur `/sync/*`** (détaillé au §3.1). Tout compte
   authentifié — donc tout employé présent dans `groupware` — peut réécrire les
   39 tables miroir, y compris `nomenclature` (prix) et `sorties` (base de calcul
   des primes). Le correctif tient en une dépendance :
   `role == "sync_agent"` exigé sur le routeur.
2. **`groupware.mot_de_passe` transite en clair** (détaillé au §2.7). Les mots de
   passe de tout le personnel traversent le réseau puis l'API en clair, avant
   d'être hachés côté serveur.

Deux points mineurs à connaître :

3. Le `404` de table inconnue renvoie la liste complète des 39 tables à un appelant
   authentifié (`sync.py:476`) — divulgation de schéma, de faible gravité vu le
   point 1.
4. `POST /sync/status/{table}` n'applique **aucune** validation de nom
   (§3.5) : on peut y créer autant de lignes que de chaînes distinctes.

---

## §5 — Les empreintes HFSQL

Ce que le schéma PostgreSQL a hérité du format source, et qui doit être
reproduit à l'identique par l'agent.

### 5.1 — Dates stockées en texte

**Péremptions.** `VARCHAR(10)` dans huit tables :
`instance_produits.peremption`, `sorties_produits.peremption`,
`entrees_produits.peremption`, `inventaires_produits.peremption`,
`echanges_sorties_produits.peremption`, `mouchard_details.per`,
`commandes_fournisseurs_produits.per`, `mouchard.stk_per_ini` / `stk_per_fin`.

🔴 **Deux formats incompatibles coexistent, et le dépôt en fait la preuve :**

| Table | Format supposé par le code | Référence |
|---|---|---|
| `instance_produits` | `MM/YYYY` — regex `^[0-9]{2}/[0-9]{4}$`, `TO_DATE(…, 'MM/YYYY')` | `dashboard.py:214-216` |
| `sorties_produits` | `MM/YY` — regex `^[0-9]{2}/[0-9]{2}$`, `to_date('01/' \|\| …, 'DD/MM/YY')` | `performance.py:485-486`, `599-607` |

Les deux modules filtrent sur leur propre regex : le format non conforme est
**écarté silencieusement** au lieu de lever une erreur. Si un seul des deux
formats est réellement produit par HFSQL, l'un des deux calculs ne voit rien.
Celui de `performance.py` alimente le KPI `ventes_peremption_3`, donc **la
prime**. Voir §6.2.

`entrees_produits` et `inventaires_produits` portent les deux colonnes :
`peremption` VARCHAR(10) **et** `peremption_date` DATE. Rien n'indique laquelle
fait foi, ni si l'agent renseigne les deux.

**Heures.** `heure`, `heure_debut`, `heure_fin` en `VARCHAR(10)`, systématiquement
séparées de la colonne `date` — habitude WinDev caractéristique. Présentes sur
`sorties`, `sorties_produits`, `entrees`, `entrees_produits`,
`instance_produits`, `echanges`, `echanges_sorties_produits`, `mouchard`,
`inventaires`, `operations`, `caisses_regies`, `suivi_caisses`.

⚠️ `grh_presence.py:75-76` fait `MIN(heure)` / `MAX(heure)` — une comparaison
**lexicographique** sur du texte. Elle n'est correcte que si l'heure est
zéro-padée sur 24 h (`08:05:00`, jamais `8:05`). Un format non padé décale le
pointage, donc la ponctualité, donc la prime.

**Autres.** `operations.mois_cvm` VARCHAR(10) — un mois stocké en texte.
`instance_produits.indice` VARCHAR(10).

### 5.2 — Horodatage concaténé

`operations.indice_creation` : `NUMERIC(20, 0)`. La migration `010` l'explique —
« Les valeurs HFSQL de `indice_creation` sont des horodatages concaténés
(ex. `2025060315181251` = 16 chiffres entiers) qui dépassent la précision
`NUMERIC(15,4)` ». Le champ n'a jamais de décimales ; il a fallu élargir le type
après coup. C'est un `TIMESTAMP` déguisé en nombre.

### 5.3 — Montants et « numérique » indifférencié

**Le schéma est sain.** Toutes les colonnes d'argent sont en `NUMERIC(15, 4)`,
conformément à la règle « Argent » de CLAUDE.md. Aucun `float`, aucun `REAL`,
aucun `DOUBLE PRECISION` dans les 39 tables miroir.

**Le transport ne l'est pas.** Le float entre par le JSON, pas par le schéma :
`_clean_record` ne convertit en `Decimal` que les `str` (`sync.py:130-132`). Un
`"total": 1450.10` en nombre JSON devient un `float` Python, arrondi en binaire
avant d'atteindre la colonne. C'est le point 2 du §3.3, et c'est le seul endroit
du projet où la règle « Argent » peut être violée sans qu'aucun code n'ait l'air
fautif.

**Identifiants typés en décimal.** Quatre colonnes trahissent le type
« numérique » indifférencié de HFSQL, mappé mécaniquement :

| Colonne | Type actuel | Devrait être |
|---|---|---|
| `entrees_produits.id_produit` | NUMERIC(15,4) | BIGINT |
| `echanges_sorties_produits.id_nom` | NUMERIC(15,4) | BIGINT |
| `ordonnancier.id_vente` | NUMERIC(15,4) | BIGINT |
| `operations.id_relatif` | NUMERIC(15,4) | BIGINT |

Même symptôme : `caisses_regies.indice_ouverture` et `suivi_caisses.indice_ouverture`
en `NUMERIC(10,4)` pour un compteur entier.

**Largeurs d'entiers incohérentes d'une table à l'autre**, sur la même donnée
métier :

- `id_famille` : `BIGINT` dans `nomenclature`, `INTEGER` dans `sorties_produits`,
  `instance_produits`, `entrees_produits`, `inventaires_produits`,
  `SMALLINT` dans `echanges_sorties_produits`.
- clé primaire : `BIGINT` partout, sauf `caisses`, `comptes_bancaires`,
  `prestations`, `commandes_fournisseurs`, `commandes_fournisseurs_produits`
  en `INTEGER`.
- `entrees_produits.id_fournisseur` en `INTEGER`, alors que `entrees.id_fournisseur`
  est en `BIGINT` — même clé étrangère, deux types.

### 5.4 — Booléens en `SMALLINT`

HFSQL n'a pas de type booléen : tout arrive en 0/1. Concernées, entre autres :
`psychotrope`, `remb_cvm`, `generique`, `modif`, `ouverte`, `annule`, `destocke`,
`rej`, `actif`, `chronique`, `cloture`, `etat_cloture`, `contient_psy`,
`avoir_financier`, `type_psy`, `bloque`, `blk_comptoir`, `blk_chifa`, `blk_cvm`,
`blk_instance`, `activer_solde_max`, `desactiv_alrt_rup`, `ord_trois_souche`,
`mode_qr`, `code_efacture`, `mld_lui_meme`.

🔴 **Piège de nommage à retenir** — trois colonnes s'appellent `archive`, et
elles n'ont pas la même origine :

| Colonne | Type | Origine | L'agent l'envoie ? |
|---|---|---|---|
| `bordereaux_chifa.archive` | SMALLINT | **HFSQL** | **oui** |
| `nomenclature.archive` | BOOLEAN | PostgreSQL (migration `014`) | **non** |
| `instance_produits.archive` | BOOLEAN | PostgreSQL (migration `011`) | **non** |

Une confusion ici écrase soit l'archivage produit, soit le pipeline d'instances.

### 5.5 — Colonnes à l'encodage douteux

**`factures_chifa.txt_prod`, `VARCHAR(10000)`** — plusieurs lignes de médicaments
sérialisées dans une seule colonne. Format, documenté dans `chifa.py:231-233` :

```
[a[a[ id_cnas|prix|qte|O|…|N|duree_trt|…|&] } id_cnas|…|&] ]a]a]
       ↑pos.1                  ↑pos.12
```

Délimiteurs : `[a[a[` … `]a]a]` en enveloppe, `}` entre médicaments, `|` entre
champs, `&]` en fin d'enregistrement. Décodé en SQL, au regex et au
`split_part`, dans `chifa.py:235-260`. Toute variation d'encodage côté EASYPHARM
casse silencieusement la détection des patients chroniques.

**Trois blobs de même nature, jamais décodés nulle part :**

| Colonne | Type | Contenu |
|---|---|---|
| `ordonnancier.txt_duree` | VARCHAR(5000) | durées de traitement sérialisées |
| `postes.cim_test` | VARCHAR(5000) | inconnu |
| `bordereaux_chifa.extra` | VARCHAR(2000) | inconnu |

**Clés composites textuelles :**

- `nomenclature.de_equiv` VARCHAR(20) — `'14A188'`, dont le préfixe devient
  `'14 A'` **avec un espace inséré** pour joindre `nomenclature_classification`
  (`chifa.py:233`). Une transformation de chaîne au milieu d'une jointure.
- `nomenclature.cle_compo_nom_cdb` VARCHAR(200) — indexée, clé de composition.
- `nomenclature.cls_trp`, `entrees_produits.cls_trp` VARCHAR(200).

**Mots de passe en clair :** `groupware.mot_de_passe` VARCHAR(100) (§2.7, §4).

**Largeurs de colonnes** *(déduction, non vérifiable dans le dépôt)* — HFSQL
dimensionne ses chaînes en **octets**, PostgreSQL en **caractères**. Un
`client` de 50 caractères accentués tient dans un champ HFSQL de 50 octets
mais pas l'inverse ; à l'import, le risque est plutôt une troncature côté agent
ou un `value too long` côté PostgreSQL. Rien dans le code ne trahit un problème
d'encodage — mais rien ne prouve non plus qu'il n'y en a pas. À vérifier sur les
colonnes courtes et accentuées : `sorties.client` VARCHAR(100),
`ordonnancier.client` / `adresse` VARCHAR(50), `instance_produits.famille`
VARCHAR(50).

---

## §6 — Ambiguïtés à lever

Onze points que le dépôt ne permet pas de trancher. Chacun bloque soit la
réécriture de l'agent, soit la confiance dans les données déjà synchronisées.
Classés par ce qu'ils coûtent s'ils restent ouverts.

### Bloquant pour réécrire l'agent

**6.1 — Les 36 noms de tables HFSQL non attestés.**
Seuls `instance_produits`, `instance_produits_trt` et `groupware` sont nommés dans
le code, et ils sont identiques au nom PostgreSQL. Les 36 autres sont notés
`≈ identique` par extrapolation. Les conventions WinDev voient souvent des
préfixes (`E_`, `F_`, `TB_`) ou du singulier là où PostgreSQL a du pluriel
(`sortie` vs `sorties`). **Question : peut-on obtenir l'analyse du fichier
`.wdd`, ou un `SELECT` sur les métadonnées HFSQL, pour figer la table de
correspondance ?** Sans ça, le §2 reste une carte approximative.

**6.2 — 🔴 `peremption` : `MM/YYYY` ou `MM/YY` ?**
Deux modules du même dépôt supposent des formats différents sur la même donnée
métier (`dashboard.py:214` contre `performance.py:485`). Trois cas possibles :
HFSQL produit les deux selon la table, HFSQL n'en produit qu'un et l'un des deux
modules ne voit jamais rien, ou l'agent normalise différemment selon la table.
Les deux codes filtrent par regex, donc **échouent en silence** au lieu de lever.

`performance.py` alimente le KPI `ventes_peremption_3`, donc **le calcul des
primes**. Toute correction ici tombe sous la règle « Paie » de la Partie 3 de
CLAUDE.md : elle exige `backend/tests/paie/`, qui n'existe pas encore. **Question :
quel format sort réellement de HFSQL, table par table ?** Un `SELECT DISTINCT
length(peremption)` sur chaque table miroir suffirait à trancher.

**6.3 — Périmètre et cadence réels du sync.**
`full_nightly` n'apparaît qu'une fois, dans un commentaire de migration
(`011:5`). Le classement du §2.10 (incrémental / fenêtre glissante / full) est
entièrement déduit de la forme des colonnes. **Questions : quelles tables passent
en incrémental et à quelle fréquence ? Que couvre le full nightly ? Y a-t-il des
tables qui ne sont jamais resynchronisées après le premier import ?**

**6.4 — À quoi sert vraiment `sync_status` ?**
Elle est écrite et relue par l'agent, et par personne d'autre dans le dépôt.
Deux lectures possibles : c'est le curseur de référence, ou c'est un doublon de
courtoisie et l'agent tient son état côté Windows. À noter que
`POST /sync/status/{table}` **cumule** `count` (`sync.py:531`) tout en renvoyant
la valeur du seul appel (`sync.py:540`) : si l'agent se fie à la réponse, il ne
lit pas ce qui a été stocké. **Question : l'agent utilise-t-il `last_id` au
redémarrage, ou peut-on considérer cette table comme abandonnable ?**

**6.5 — 🔴 `finalize` ne peut plus archiver.**
`POST /sync/instance_produits/finalize` renvoie `archived: 0` **en dur**
(`sync.py:370`) et ne fait plus que restaurer `archive = FALSE`. Le nom du
endpoint, le nom du champ et le paramètre `active_ids` (« les IDs encore
actifs ») décrivent tous un comportement de balayage inverse — « archiver tout ce
qui n'est **pas** dans cette liste » — qui n'est plus dans le code.

Conséquence aujourd'hui : une ligne ne passe à `archive = TRUE` que si elle
remonte via `/sync/instance_produits_trt`. Une instance supprimée dans HFSQL sans
passer par `instance_produits_trt` reste **active pour toujours** côté
PostgreSQL. **Question : régression à corriger, ou l'archivage a-t-il été déplacé
dans l'agent ?**

**6.6 — 🔴 `/sync/instance_produits_trt` accepte-t-il vraiment des chaînes ?**
Contrairement à `/batch`, cet endpoint ne convertit ni les dates ni les décimaux
des 23 colonnes standard : les valeurs sont passées telles quelles à un `text()`
sans typage (`sync.py:452-453`). asyncpg refuse une `str` pour une colonne `DATE`
ou `NUMERIC`. Deux lectures : soit l'endpoint est cassé et n'est plus appelé, soit
l'agent y envoie des types natifs — ce que JSON ne permet pas pour une date.

À noter aussi que `**standard_fields` répand des clés arbitraires dans le dict de
paramètres : une clé **manquante** (`lot` absent, par exemple) provoque une
`StatementError` qui fait échouer **tout** le batch avec un `500`. Cet endpoint
exige donc les 23 colonnes exactes, ni plus ni moins.

**Question : cet endpoint est-il encore appelé, et sous quelle forme l'agent
envoie-t-il `date`, `echeance`, `prix_vente` et `prix_achat_ttc` ?**

### Bloquant pour faire confiance aux données

**6.7 — `clients.is_archive` n'est écrit par personne.**
La migration `030` a créé `is_archive`, `date_archive`, `motif_archive`. `crm.py`
les lit dans une dizaine de requêtes (`crm.py:116`, `140`, `255`, `329`, `460`,
`571`, `626`, `640`, `656`, `670`). **Aucun endpoint du dépôt ne les écrit.**
Donc soit l'archivage client se fait à la main en SQL, soit un endpoint manque,
soit l'agent est censé le déduire côté HFSQL. **Question : laquelle des trois ?**

**6.8 — Détection des suppressions, au-delà de `instance_produits`.**
`instance_produits` est la seule table dotée d'un mécanisme de suppression. Que
devient, côté PostgreSQL, une vente annulée dans EASYPHARM, un client fusionné,
un produit retiré du référentiel ? Le contrat actuel n'a **aucun moyen** de
supprimer une ligne : `ON CONFLICT DO UPDATE` ne fait qu'ajouter et modifier.
`nomenclature.archive` et `clients.is_archive` existent, mais sont
PostgreSQL-only et positionnés à la main. **Question : les suppressions HFSQL
sont-elles rares au point d'être négligeables, ou avons-nous des lignes fantômes
en base ?**

**6.9 — Miroirs tronqués : volontaire ou incomplet ?**
`depenses` n'a que `(id, depense)`, `motif_instance` que `(id, motif)`. Comparées
aux 54 colonnes de `mouchard`, ces deux tables ressemblent à des imports
inachevés. **Question : le fichier HFSQL est-il aussi maigre, ou n'a-t-on importé
que ce qui servait à l'époque ?** Même question, plus légère, pour `caisses`
(3 colonnes) et `comptes_bancaires` (2).

**6.10 — Origine réelle de `inventaires` / `inventaires_produits`.**
Créées par la migration `004`, dont le titre parle de « performance et
inventaires » — donc plutôt un chantier projet. Mais elles ont la forme d'un
miroir (PK `BIGINT` sans séquence, `heure` VARCHAR(10), `peremption` VARCHAR(10))
et figurent dans `SYNC_REGISTRY`. **Question : EASYPHARM gère-t-il les
inventaires, ou ces tables sont-elles alimentées autrement ?** La réponse change
leur place dans ce document.

### Décisions à prendre

**6.11 — 🔴 Sécurité : deux arbitrages attendus.**

- Le rôle `sync_agent` doit-il devenir bloquant sur `/sync/*` ? Aujourd'hui
  n'importe quel employé authentifié peut réécrire les 39 tables miroir (§3.1,
  §4). Le correctif est une dépendance de routeur, et il casse tout appelant
  qui ne serait pas l'agent — d'où la question.
- `groupware.mot_de_passe` doit-il continuer à transiter en clair (§2.7) ? La
  chaîne actuelle est : HFSQL en clair → HTTP → PostgreSQL en clair → hachage
  bcrypt vers `users` uniquement. Supprimer la colonne du payload signifie
  renoncer à la voie 3 du login (`auth.py:104`), donc trouver un autre chemin
  d'enrôlement des comptes.

À rapprocher des deux entrées « Pièges connus » de CLAUDE.md sur le même sujet :
`allow_origins=["*"]` avec `allow_credentials=True` (`main.py:110`), et les
secrets par défaut fonctionnels de `config.py` — dont
`sync_agent_password` (`config.py:27`), qui est le mot de passe du compte
capable d'écrire dans les 39 tables — et dont la valeur par défaut est
fonctionnelle telle quelle.

### Tranché

**Numérotation — ce document garde `02`.**
La Partie 2 de CLAUDE.md réservait `docs/02-` à `02-chifa-integration.md`. La
cible a été renumérotée : l'intégration Chifa passe en `03-chifa-integration.md`
et les règles de paie en `04-paie-regles.md`. `02-sync-contrat.md` est donc
stable, et les liens vers ce fichier ne bougeront plus.

---

## Annexe — Ce qui n'est *pas* dans le contrat de sync

Tables absentes de `SYNC_REGISTRY`, alimentées par l'application et non par
l'agent. À ne pas confondre avec des miroirs :

| Table | Module propriétaire |
|---|---|
| `users` | `auth.py` — dérivée de `groupware` par post-hook |
| `sync_status` | `sync.py` — métadonnées |
| `employes`, `objectifs_mensuels`, `kpi_definitions`, `performance_mensuelle`, `prime_taux_config` | `performance.py` |
| `facture_anomalies`, `facture_rejets` | `chifa.py` |
| `maladies_chroniques`, `classe_maladie`, `patients_chifa` | `chifa.py`, `crm.py` |
| `nomenclature_classification` | `stock.py` |
| `parametres_stock`, `previsions_demande` | `assistant_achat.py` |
| `historique_stock_jour` | `services/purchase_engine/stock_history.py` |
| `task_templates`, `task_assignments` | `tasks.py` |
| `presences_overrides`, `demandes_conge` | `grh_presence.py`, `grh_employes.py` |
| `sms_logs` | `sms.py` |

Ces tables ont des clés primaires auto-incrémentées, contrairement aux 39
miroirs dont l'`id` vient toujours de HFSQL.
