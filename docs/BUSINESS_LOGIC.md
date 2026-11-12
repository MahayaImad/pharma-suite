# Logique Métier EasyPharm - Documentation

> Ce document capture les règles métier essentielles de l'application EasyPharm
> pour référence lors du développement de Synergo.

---

## 1. Gestion des Instances (Produits en Attente)

### 1.1 Flux Instance Produits

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    CYCLE DE VIE - INSTANCE PRODUITS                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│   Client avec ordonnance                                                │
│          │                                                              │
│          ▼                                                              │
│   ┌──────────────┐                                                      │
│   │  Vérification │                                                      │
│   │    CHIFA      │                                                      │
│   └──────┬───────┘                                                      │
│          │                                                              │
│    ┌─────┴─────┐                                                        │
│    │           │                                                        │
│    ▼           ▼                                                        │
│  [OK]      [BLOCAGE]                                                    │
│    │           │                                                        │
│    │           │  Motifs possibles:                                     │
│    │           │  • Carte CHIFA bloquée                                 │
│    │           │  • Médicament en rupture                               │
│    │           │  • Contrôle médical requis                             │
│    │           │  • Droits expirés                                      │
│    │           │                                                        │
│    ▼           ▼                                                        │
│ ┌──────┐   ┌──────────────────┐                                         │
│ │VENTE │   │ INSTANCE_PRODUITS │  ← Sortie stock SANS paiement          │
│ │direct│   │ (mise en attente) │                                        │
│ └──────┘   └────────┬─────────┘                                         │
│                     │                                                   │
│                     │ Plus tard (problème résolu)                       │
│                     ▼                                                   │
│              ┌──────────────┐                                           │
│              │ VENTE finale │  ← Paiement effectué                      │
│              │ (CHIFA/Libre)│                                           │
│              └──────┬───────┘                                           │
│                     │                                                   │
│         ┌───────────┴───────────┐                                       │
│         │                       │                                       │
│         ▼                       ▼                                       │
│   ┌──────────┐         ┌────────────────────┐                           │
│   │ SORTIES  │         │ INSTANCE_PRODUITS_ │                           │
│   │ (ventes) │         │ TRT (archive)      │                           │
│   └──────────┘         └────────────────────┘                           │
│                                                                         │
│   IMPORTANT: La ligne est SUPPRIMÉE de instance_produits                │
│              (seule table où les lignes disparaissent)                  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Champs Clés - instance_produits

| Champ | Description |
|-------|-------------|
| `id_client`, `client` | Patient concerné |
| `id_nom`, `nom` | Produit mis en attente |
| `qte_sortie` | Quantité réservée |
| `motif` | Raison du blocage (voir table `motif_instance`) |
| `echeance` | Date limite pour finaliser |
| `n_assuré_chifa` | Numéro d'assuré CHIFA |
| `n_assuré_cvm` | Numéro d'assuré CVM |

### 1.3 Motifs d'Instance (Liste Dynamique)

Les motifs de mise en attente sont stockés dans la table **`motif_instance`** :

| Motif | Description |
|-------|-------------|
| Contrôle médical | Patient doit passer un contrôle |
| Carte bloquée | Carte CHIFA suspendue |
| Rupture stock | Médicament non disponible |
| Droits expirés | Droits CNAS expirés |
| Attente ordonnance | Ordonnance à récupérer |

**Note** : Cette liste est **dynamique** et modifiable par l'utilisateur dans EasyPharm.

### 1.3 Table Archive - instance_produits_trt

Quand une instance est vendue ou annulée :
- Copie dans `instance_produits_trt` avec :
  - `archive = TRUE`
  - `archive_trace` = "Vente CHIFA" | "Vente Comptoir" | "Suppression manuelle"
  - `utilisateur_validation` = employé qui a finalisé
  - `date_archive` = timestamp de l'action

---

## 2. Types de Ventes

### 2.1 Classification des Ventes

| Type | Code | Description | Particularités |
|------|------|-------------|----------------|
| **Vente Libre** | V | Vente comptoir sans assurance | Paiement direct |
| **CHIFA** | - | Sécurité sociale algérienne | `no_facture_chifa` renseigné |
| **CVM** | - | Caisse militaire | `num_assuré_cvm` renseigné |
| **Pharmnos** | - | Autre convention | `Pharmnos_num_fact` renseigné |
| **Avoir/Retour** | A | Retour produit | `type = 'A'` dans sorties |

### 2.2 Champ `type` dans sorties

- `V` = Vente normale
- `A` = Avoir/Retour (filtré dans la plupart des calculs)

> Ces deux valeurs concernent l'en-tête (`sorties.type`) et n'ont pas été
> revérifiées sur la base. Pour les lignes de vente, voir 2.3, qui fait foi.

### 2.3 Champ `type_sortie` dans sorties_produits — vérifié sur la base (2026-11-10)

| Fait | Détail |
|------|--------|
| `type_sortie = 'V'` | une **vente** |
| `'RET'`, `'AV'` | **aucun enregistrement** ne porte ces valeurs |
| Retour client | **pas de type dédié** : la ligne garde son type et `sorties_produits.qte_sortie` est **négative** |

Conséquences pour les calculs :

- **Quantité ou chiffre d'affaires net** = simple somme de `qte_sortie` (ou
  de `qte_sortie × prix_vente`) : les retours se déduisent d'eux-mêmes par
  leur signe. Ne pas inverser le signe une seconde fois.
- **Retours seuls** = lignes où `qte_sortie < 0`.
- **Ventes brutes** = lignes où `qte_sortie > 0`.
- **Compter des ventes** (nombre de lignes, de tickets) : filtrer
  `qte_sortie > 0`, sinon un retour est compté comme une vente.
- Les filtres `type_sortie NOT IN ('RET', 'AV')` ou `!= 'RET'` présents dans
  le code ne retirent rien : ils ne correspondent à aucune ligne.

---

## 3. Gestion des Achats

### 3.1 États d'un Achat

| Champ | Valeur | Signification |
|-------|--------|---------------|
| `ouverte` | 1 | Achat en cours de saisie (modifiable) |
| `ouverte` | 0 | Achat clôturé (figé) |
| `modif` | > 0 | Achat a été modifié après clôture |
| `type` | A | Achat normal |
| `type` | AV | Avoir fournisseur |

**`AV` = avoir produit, c'est-à-dire un retour au fournisseur** (côté achats
uniquement ; cette valeur n'existe pas côté ventes, voir 2.3). Sur les lignes,
c'est `entrees_produits.type_entree = 'AV'`. Un avoir fait **sortir** du
stock : il ne se compte ni comme une entrée ni comme un achat, et s'exclut
des quantités reçues (`type_entree NOT IN ('AV')`).

### 3.2 Flux de Réception

```
Commande → Réception BL → Réception Facture → Paiement
              │                   │
              ▼                   ▼
          entrees            entrees (update)
          (ouverte=1)        (ouverte=0)
              │
              ▼
        entrees_produits
        (lignes de stock)
```

### 3.3 Le stock — un champ, pas un calcul (confirmé le 2026-11-11)

Le stock affiché dans EASYPHARM **n'est pas calculé** à partir des mouvements
(entrées − sorties) : c'est un **champ stocké**, `entrees_produits.stock`,
la quantité restante de chaque lot. EASYPHARM le met à jour lui-même à chaque
vente, retour ou correction.

Conséquences :

- **Stock d'un lot** = `entrees_produits.stock`. **Stock d'un produit** =
  somme de ce champ sur ses lots. PharmaSuite lit ce champ ; il ne recalcule
  jamais un stock à partir des ventes et des achats.
- **La ligne du lot est modifiée sur place** : son `id` ne change pas, seul
  `stock` bouge. La synchronisation doit donc relire les lots existants, pas
  seulement les nouveaux (stratégie « lots » de l'agent).
- **Un écart entre PharmaSuite et EASYPHARM ne peut venir que de la
  synchronisation** (retard, lot non relu), jamais d'une formule : les deux
  affichent le même champ.
- `nomenclature.stock` existe mais vaut 0 partout : ce n'est pas le stock.
- Reconstituer un stock **passé** reste un calcul (stock actuel, en
  remontant les mouvements) : c'est une estimation, à la différence du stock
  du jour.
- **Historique** (`historique_stock_jour`, colonne `source`, migration 009) :
  depuis le 2026-11-12, une **photo** du stock de chaque produit actif ou en
  stock est prise chaque soir à 23 h 50 (heure d'Alger), donc exacte ; le
  passé antérieur ne peut être que **reconstitué** (estimation), **par
  lot** avec tous les mouvements du §3.4. Une reconstitution n'écrase
  jamais une photo.

### 3.4 Le stock passé : tous les mouvements à compter (confirmé le 2026-11-12)

Le stock d'un jour passé se reconstitue à rebours depuis le stock actuel. Il
ne suffit pas de suivre achats et ventes : **six mouvements** modifient le
stock d'un lot.

| Mouvement | Table | Sens | Remarque |
|---|---|---|---|
| Achat | `entrees_produits`, `type_entree = 'A'` | entrée | crée le lot à sa `date_entree` |
| Avoir fournisseur | `entrees_produits`, `type_entree = 'AV'` | **sortie** | retour au fournisseur ; quantité saisie **positive** (123 lignes) |
| Vente | `sorties_produits.qte_sortie` | sortie | un retour client est une quantité négative (§2.3) |
| Échange vers une autre pharmacie | `echanges_sorties_produits.qte` (type `ES`) | sortie | porte le lot |
| **Échange reçu** d'une autre pharmacie | `entrees_produits`, **`type_achat = 'E'`** | entrée | crée un lot comme un achat (confirmé le 2026-11-12) ; 950 lignes, **toutes avec un prix d'achat** |
| **Unités gratuites (UG)** | `entrees_produits`, `type_achat` `Facture` ou `BL`, **`prix_achat = 0`** | entrée | lignes gratuites d'une livraison (confirmé le 2026-11-12) : 1 263 lignes |
| **Ajustement d'inventaire** | `inventaires_produits.ecart` | **±** | `ecart = stock_reel − stock_theorique`, par **lot**, à la `date` de l'inventaire ; positif = stock retrouvé, négatif = perte (casse, péremption, vol). 27 876 lignes : la table est utilisée au fil de l'eau, pas seulement pour l'inventaire d'ouverture |
| **Instance** | `instance_produits` | sortie | le produit sort du stock **à la mise en instance**, sans paiement ; la vente est enregistrée plus tard |

À rebours, pour un lot : stock(veille) = stock(jour) + sorties du jour −
ajustements du jour ; avant sa date d'entrée, le lot n'existe pas.

**Échanges reçus** (`type_achat = 'E'`) : ce ne sont pas des achats. Ils
sont **exclus** de tout ce qui parle des fournisseurs — fournisseur principal
d'un produit, délai de livraison, prix d'achat par fournisseur. Ils sont
saisis avec un prix d'achat (aucune ligne à 0 sur la base réelle) : pas
d'effet sur la valeur du stock.

**Unités gratuites** (lignes d'achat à `prix_achat = 0`, type `Facture` ou
`BL`) : elles entrent en stock comme les autres et sont valorisées à 0. Le
prix d'achat moyen pondéré d'un produit (`mv_stock_produits`) en tient donc
compte : c'est le **coût réel** par unité. Pour comparer les fournisseurs,
le module Commandes utilisera le **prix effectif** = montant payé ÷
(unités payées + unités gratuites), et le **taux d'UG** = unités gratuites ÷
unités payées (voir aussi `commandes_fournisseurs_produits.taux_ug`).
Autres valeurs de `type_achat` vues : `R` (123 lignes, les avoirs `AV`) et
`I` (3 lignes).

**Motif des ajustements** (`inventaires_produits.motif`, confirmé le
2026-11-12) :

- **Péremption** : `motif = 'Péremption'` avec un **écart négatif** = les
  périmés retirés du stock. Base du **taux de péremption** = valeur des
  périmés (écart × prix d'achat de la ligne) ÷ valeur des achats de la
  période × 100 ; objectif courant : sous 1 à 2 %. `GET /stock/peremption`.
- **Consommables donnés** : certains produits sont achetés mais **jamais
  vendus**, donnés gratuitement (aiguilles Insupen, sachets, lecteurs de
  glycémie…) ; ils sortent du stock par un **ajustement à zéro** à
  l'inventaire. Ce ne sont **ni des pertes** (pas de démarque) **ni des
  ventes** : leur consommation se lit dans les ajustements. Ils sont à
  écarter de la démarque, de la rotation et de la prévision par les ventes.
- Les autres écarts (casse, vol, erreurs de saisie) forment la **démarque**.

**Instances** : leur historique exact n'existe pas depuis 2023 (la ligne est
supprimée d'`instance_produits` une fois traitée). Elles se retrouvent
ensuite dans les ventes : on les compte à la date de la vente, ce qui
surestime le stock pendant les quelques jours d'attente. **Écart accepté.**

**Méthode retenue : par lot** (diagnostic du 2026-11-12, 150 produits les
plus vendus, 12 mois) — 0,3 % de jours à stock négatif (2 produits sur 150)
contre 9,9 % par produit (95 sur 150), qui ne sait pas affecter les
ajustements, avoirs et échanges au bon lot. 24 % des lignes de vente n'ont
pas de numéro de lot : elles sont rattachées aux lots sans numéro du même
produit.

### 3.5 Familles de produits (confirmé le 2026-11-11)

Chaque produit appartient à une **famille**. La liste vit dans la table
`familles` (`id`, `famille`) ; aujourd'hui :

| id | Famille |
|---:|---|
| 1 | Médicaments |
| 3 | Cosmétiques |
| 4 | NUTRITION INFANTILE ET COUCHES |
| 9 | COMPLEMENTS ALIMENTAIRES |
| 10 | DERMO-COSMETIQUE |
| 11 | SOIN CORPOREL |
| 12 | ORTHOPEDIE ET MATERIEL MEDICAL |
| 13 | HYGIENE BUCCO DENTAIRE |
| 15 | BEBE ET MAMAN |

Les identifiants ne se suivent pas (2, 5 à 8 et 14 manquent) : ne jamais
supposer une suite continue ni coder la liste en dur, elle se lit en base.

`nomenclature` porte **deux champs** : `id_famille` et `famille`. Le second
est une **copie texte** du libellé, recopiée par EASYPHARM (les tables de
mouvements `sorties_produits`, `entrees_produits`, `achats_produits`… la
portent aussi). Règles :

- **`id_famille` fait foi.** Le libellé se lit dans `familles` par jointure
  (`LEFT JOIN familles f ON f.id = n.id_famille`) ; la copie texte n'est
  qu'un repli quand l'id est absent de `familles`.
- **Filtrer et regrouper par `id_famille`**, jamais par le texte : un
  libellé renommé dans EASYPHARM laisse d'anciennes copies divergentes.
- Les produits dont l'id est inconnu sont regroupés sous « Sans famille ».
- Dans le module stock, la famille est le **premier axe de navigation** :
  `GET /stock/resume` donne le nombre de produits actifs et en stock par
  famille, `GET /stock/products?id_famille=…` filtre la liste.
- La famille (nature du produit) n'est **pas** la catégorie
  (`nomenclature.categorie` : princeps / générique / générique++), qui sert
  au calcul de l'enveloppe de prime.

### 3.6 Délai de livraison des fournisseurs (confirmé le 2026-11-11)

- Les grossistes livrent en général **en 24 heures, les jours ouvrés**. La
  semaine algérienne ne travaille pas le **vendredi ni le samedi** : une
  commande du **jeudi arrive le dimanche**, une commande du vendredi aussi.
- Le délai propre à un fournisseur se saisit dans
  `fournisseurs.delai_livraison`, en **jours ouvrés** (colonne absente
  d'EASYPHARM : la synchronisation ne l'écrase pas). Sans saisie, on prend le
  réglage `delai_livraison_jours` (1).
- Le **fournisseur principal** d'un produit est celui de sa dernière entrée
  qui est un vrai achat : ni avoir (`type_entree <> 'AV'`), ni échange reçu
  (`type_achat <> 'E'`) (`entrees_produits.id_fournisseur`).
- Les jours fériés ne sont pas encore retirés du calcul.

### 3.7 Gardes et fêtes à date mobile (confirmé le 2026-11-12)

La demande change les jours de **garde** et pendant **Ramadan et les Aïd** :
la prévision des commandes en tient compte.

- **Trois types de garde** (table `gardes`, migration 006) :
  `soiree` (jusqu'à 23 h, ex. 2026-11-07), `24h` et `jour` (ouverture un
  jour de fermeture habituelle).
- **Une garde se date du jour où elle commence** (confirmé le 2026-11-12).
  La garde 24 h du **30/09/2026** a couru du mercredi 30/09 au matin au
  jeudi 01/10 au matin ; EASYPHARM date ses ventes de la nuit (0 h – 6 h)
  **du lendemain**, le 01/10. Corrigée par la migration 008 (elle avait été
  saisie au 01/10).
- **Gardes passées** : retrouvées dans les heures de vente
  (`sorties.heure`) par `scripts/detecter_gardes.py`, qui apprend les
  horaires habituels de chaque jour de la semaine et repère les ventes hors
  horaires. Les candidates sont enregistrées `source = 'detection'`,
  `confirme = false` : l'officine les confirme.
- **Gardes à venir** : saisies par l'officine (`source = 'saisie'`), ou
  **proposées d'après la rotation** (`source = 'prevision'`, migration 007,
  bouton « Proposer les 3 prochains mois ») puis confirmées. Rotation
  observée sur 3 ans (rapport du 2026-11-12) : **soirée tous les 10 jours**
  (45 fois), **vendredi entier toutes les 10 semaines** (70 j, 9 fois ;
  parfois 77), **24 h tous les ~16 semaines** (112–118 j). La période de
  chaque type est recalculée sur les gardes connues ; on part de la dernière
  garde passée ; un jour déjà pris n'est jamais reproposé ; une soirée qui
  tombe un vendredi (jour de fermeture) est signalée « à vérifier ».
- **Annuler** une garde détectée ou proposée (non confirmée) la marque
  `annulee` (migration 010) au lieu de la supprimer : elle disparaît de la
  liste, ne fixe plus la rotation, et ni la détection ni la rotation ne la
  reproposent. La saisir ou la confirmer à nouveau la rétablit.
- **Ramadan, Aïd el-Fitr, Aïd el-Adha** : table `evenements_calendrier`,
  dates 2022–2027 pré-remplies d'après le calendrier lunaire, marquées
  `a_verifier` (l'annonce officielle peut décaler d'un jour), modifiables.
  Les fériés à date fixe restent dans `holidays`.

### 3.8 Horodatage des données du stock

Les écrans stock affichent l'heure de leurs données : c'est l'heure du
dernier calcul de la vue `mv_stock_produits` (`POST /stock/refresh-cache`,
appelé par l'agent après chaque passe), notée dans `sync_status` sous le nom
de la vue, et rendue par `GET /stock/resume` (`donnees_du`, UTC).

---

## 4. Bordereaux CHIFA (CNAS)

### 4.1 Machine à États

```
dt_creation → dt_cloture → dt_depot → dt_validation → dt_encaisse

   Création      Clôture      Dépôt       Validation    Encaissement
   du lot        du lot       au centre   par CNAS      reçu
```

### 4.2 Statuts

| Statut | Description |
|--------|-------------|
| `Créé` | Bordereau ouvert, factures en cours d'ajout |
| `Clôturé` | Bordereau fermé, prêt pour dépôt |
| `Déposé` | Déposé au centre CNAS |
| `Validé` | Accepté par la CNAS |
| `Encaissé` | Paiement reçu |
| `archive = 1` | Bordereau archivé |

---

## 5. Opérations de Trésorerie

### 5.1 Types d'Opérations

| Opération | Description |
|-----------|-------------|
| `Versement Client` | Paiement d'une créance client |
| `Versement Fournisseur` | Paiement d'une dette fournisseur |
| `Remboursement Client` | Remboursement d'un avoir client |
| `Remboursement Fournisseur` | Remboursement d'un avoir fournisseur |
| `Alimentation` | Apport de fonds en caisse |
| `Dépense` | Sortie de fonds pour frais |
| `Virement de fond` | Transfert entre caisses |

### 5.2 Champs Importants

| Champ | Usage |
|-------|-------|
| `id_relatif` | Lien vers la vente/achat concerné |
| `id_tier` | Client ou fournisseur |
| `cloturé` | 1 = opération dans une session clôturée |
| `id_session` | Session de caisse |
| `indice_creation` | Horodatage concaténé (YYYYMMDDHHMMSS) |

---

## 6. Sessions de Caisse

### 6.1 Cycle de Vie

```
Ouverture → Opérations → Clôture → Validation
    │            │           │          │
    ▼            ▼           ▼          ▼
fond_de_    Ventes,      total_     etat_cloture
caisse      Versements   calcule,   = 1
            Dépenses     total_reel
```

### 6.2 Calcul de l'Écart

```
écart = total_reel - total_calcule
```

- `total_calcule` = somme automatique des opérations
- `total_reel` = comptage physique à la clôture

---

## 7. Audit (Mouchard)

### 7.1 Structure

Le mouchard enregistre les modifications avec un système avant/après :

| Préfixe | Domaine |
|---------|---------|
| `vnt_*` | Modifications de ventes |
| `ach_*` | Modifications d'achats |
| `stk_*` | Modifications de stock |
| `op_*` | Modifications d'opérations |

Suffixes :
- `_ini` = valeur avant modification
- `_fin` = valeur après modification

### 7.2 Actions Tracées

- Modification de vente (prix, quantité)
- Modification d'achat
- Blocage/déblocage de stock
- Modification d'opération de caisse

---

## 8. Péremptions

### 8.1 Formats

| Table | Format | Exemple |
|-------|--------|---------|
| `sorties_produits` | MM/YY | `04/23` |
| `instance_produits` | MM/YYYY | `04/2023` |
| `entrees_produits` | MM/YY + Date | `04/23` + `2023-04-30` |

⚠️ **Attention** : Deux formats coexistent dans HFSQL !

### 8.2 Alertes Péremption

- **Proche péremption** : < 3 mois
- **Très proche** : < 1 mois
- **Périmé** : Date dépassée

---

## 9. Droits Utilisateurs (Groupware)

### 9.1 Structure des Permissions

Format : `{module}_{action}` où action = add | modif | supp | (vide=lecture)

| Préfixe | Module |
|---------|--------|
| `fc_*` | Fiches (nomenclature, familles, etc.) |
| `ac_*` | Achats |
| `vnt_*` | Ventes |
| `stk_*` | Stock |
| `trs_*` | Trésorerie |
| `ch_*` | CHIFA |
| `mil_*` | Militaire |
| `Ph_*` | Pharmnos |

### 9.2 Exemple de Droits

```
fc_nom = 1       → Peut voir la nomenclature
fc_nom_add = 1   → Peut ajouter des produits
fc_nom_modif = 1 → Peut modifier des produits
fc_nom_supp = 1  → Peut supprimer des produits
```

---

## 10. Clients - Données Sensibles (RGPD)

### 10.1 Champs Nominatifs

| Champ | Sensibilité |
|-------|-------------|
| `client` | Nom complet |
| `adresse`, `ville` | Localisation |
| `téléphone`, `email` | Contact |
| `n_assuré_chifa` | N° sécurité sociale |
| `pathologie` | **Donnée de santé** |
| `chronique` | **Donnée de santé** |
| `date_naissance` | Identité |

### 10.2 Règles de Traitement

- Ne jamais exposer `pathologie` dans des exports non sécurisés
- `n_assuré_chifa` = donnée à protéger
- Logging des accès aux données patients

---

## 11. Synchronisation - Règles Clés

### 11.1 Tables avec Suppression

- **Seule `instance_produits`** peut avoir des lignes supprimées
- Toutes les autres tables sont en INSERT ou UPDATE uniquement

### 11.2 Détection des Modifications

| Table | Indicateur |
|-------|------------|
| `sorties`, `entrees` | `modif > 0` |
| `entrees` | `ouverte = 1` |
| `operations` | `cloturé = 0` ou `modif > 0` |
| `bordereaux_chifa` | Toute date `dt_*` peut changer |

### 11.3 Ordre de Synchronisation

1. `nomenclature` (référentiel produits)
2. `clients`, `fournisseurs` (tiers)
3. `entrees`, `entrees_produits` (achats)
4. `sorties`, `sorties_produits` (ventes)
5. `instance_produits` (pipeline spécial)
6. `operations`, `bordereaux_chifa` (trésorerie)
7. `mouchard` (audit - en dernier)

---

---

## 12. Ordonnancier (Registre Psychotropes)

### 12.1 Obligation Légale

Le registre des psychotropes est **obligatoire** pour toute pharmacie.
Il doit conserver :
- Identité du patient (`client`, `num_cin`)
- Identité du porteur si différent (`porteur`, `Porteur_cin`)
- Prescripteur (`ordonnateur`, `Adresse_medecin`)
- Données médicales (`Age_malade`, `poids_malade`, `taille_malade`)
- Détails de l'ordonnance (`txt_duree`, `structure_ordo`)

### 12.2 Sensibilité RGPD

🔴 **NIVEAU MAXIMAL** - Cette table contient :
- Pièce d'identité (CIN)
- Données de santé
- Informations sur les traitements psychotropes

**Règles** :
- Accès restreint aux pharmaciens uniquement
- Pas d'export sans autorisation
- Logs de tous les accès
- Conservation légale obligatoire

---

## 13. Tables Non Utilisées

Les tables suivantes existent dans HFSQL mais sont **vides** :

| Table | Raison probable |
|-------|-----------------|
| `caisses_régies` | Gestion sessions caisse non activée |
| `inventaires` | Module inventaire non utilisé |
| `inventaires_produits` | Idem |

Ces tables peuvent être ignorées dans la synchronisation initiale.

---

*Document créé le 2026-11-07 - À maintenir à jour avec l'évolution du projet*
