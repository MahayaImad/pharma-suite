# Module stock — ligne directrice

Ce document fixe **comment** on construit la gestion du stock de PharmaSuite :
le périmètre, l'ordre des travaux, les définitions des indicateurs et les
règles à respecter. Il complète `CLAUDE.md` (qui reste prioritaire) et se
relit avant chaque nouvelle fonctionnalité du module.

État au 2026-11-10 : les 39 tables EASYPHARM sont synchronisées ; le backend
stock (`backend/app/api/v1/stock.py`, 25 routes) existe mais n'a pas encore
été vérifié sur les données réelles ; aucun frontend.

---

## 1. Principes

1. **EASYPHARM est la référence du stock.** PharmaSuite lit, analyse, alerte
   et recommande. Il ne modifie jamais le stock d'EASYPHARM. Toute saisie
   faite dans PharmaSuite (comptage d'inventaire, seuil, étagère) vit dans
   des tables propres à PharmaSuite.
2. **Un chiffre affiché est un chiffre vérifié.** Aucun indicateur ne part à
   l'écran sans avoir été rapproché d'EASYPHARM sur un échantillon réel.
3. **Chaque indicateur a une définition écrite** (section 4) : formule,
   période, exclusions. Deux écrans ne calculent jamais le même indicateur de
   deux façons.
4. **Dire la fraîcheur.** Le stock affiché date de la dernière
   synchronisation (15 min à 4 h selon la table). Chaque écran montre
   « données au … ».
5. **Service avant finance.** L'arbitrage central est taux de service contre
   capital immobilisé ; pour un produit vital, le service gagne.
6. **Corriger et étendre, pas réécrire** (`CLAUDE.md`, Partie 3). `stock.py`
   ne se refond pas au passage.

---

## 2. Ordre des travaux

Chaque phase a une sortie vérifiable. On ne commence pas la suivante avant.

| Phase | Contenu | Terminé quand |
|---|---|---|
| **0. Fiabiliser** | lancer `scripts/verifier_stock.py`, corriger ce qui échoue ; rafraîchir la vue du stock après chaque passe de l'agent ; trancher le format de péremption ; rapprocher le stock de 20 produits avec EASYPHARM | toutes les routes répondent, et les 20 produits concordent |
| **1. Consulter** | recherche produit, fiche, lots triés par péremption (FEFO), stock et valeur | un employé retrouve un produit et ses lots en moins de 10 s |
| **2. Alerter** | ruptures, sous le seuil, péremptions à 1/3/6 mois, stock dormant, surstock | chaque alerte mène à une action (commander, mettre en avant, échanger, retourner) |
| **3. Piloter** | indicateurs de la section 4, par famille / étagère / responsable, avec historique | le titulaire lit l'état du stock en une page |
| **4. Classer** | ABC × XYZ existants, ajout de la criticité VEN, taux de service cible par classe | chaque produit actif a ses trois classes |
| **5. Inventorier** | inventaire tournant : listes de comptage par classe, saisie, écarts, exactitude | l'exactitude du stock est mesurée chaque mois |
| **6. Réapprovisionner** | brancher le moteur d'achat existant (`assistant_achat`) sur des paramètres fiables | une proposition de commande est acceptée sans retouche majeure |

La phase 0 est le backend ; le frontend Flutter démarre à la phase 1, sur
des routes vérifiées.

---

## 3. Règles sur les données

- **Stock d'un produit** = somme des `entrees_produits.stock` de ses lots
  (vue `mv_stock_produits`). `nomenclature.stock` sert de contrôle : un écart
  entre les deux se signale, il ne se masque pas.
- **La vue `mv_stock_produits` doit être rafraîchie** après chaque
  synchronisation, sinon tout le module affiche un stock périmé. À la
  création de la base elle est vide (`WITH NO DATA`) et toute lecture échoue
  tant qu'elle n'a pas été calculée une première fois.
- **Péremption** : `entrees_produits.peremption_date` (date) fait foi quand
  elle est remplie ; sinon on convertit le texte `peremption`, dont le format
  réel (`MM/YY` ou `MM/YYYY`) se constate dans le rapport de vérification —
  on ne le suppose pas. Une péremption illisible est comptée et affichée
  comme « inconnue », jamais ignorée.
- **Ventes** : exclure retours et avoirs (`type_sortie` `RET`, `AV`) des
  quantités vendues, de la même façon partout.
- **Produits archivés** (`nomenclature.archive`) exclus par défaut des listes
  et des indicateurs.
- **Lots bloqués** (`bloque = 1`) : comptés dans le stock physique, exclus du
  stock vendable.
- **Colonnes propres à PharmaSuite** (`segment_abc`, `segment_xyz`,
  `disponibilite`, `categorie`, `etagere`, `archive`) : jamais écrasées par la
  synchronisation.
- **Argent** en `Numeric`, jamais en `float`, y compris dans les calculs
  intermédiaires ; les `float` n'existent qu'à la sérialisation JSON.
- **Dates** : stockage UTC, affichage `Africa/Algiers`.
- **Données sensibles** : psychotropes, instances et ordonnancier contiennent
  des données patient ; elles ne sortent pas du réseau local et ne sont
  visibles que des rôles autorisés.

---

## 4. Indicateurs — définitions de référence

Période par défaut : 12 mois glissants, sauf mention. Tout indicateur se
décline par famille, étagère, responsable, classe ABC/XYZ/VEN.

| Indicateur | Formule | Lecture |
|---|---|---|
| **Valeur du stock** | Σ (stock du lot × prix d'achat du lot) | capital immobilisé |
| **Rotation** | coût d'achat des ventes ÷ valeur moyenne du stock | plus haut = mieux, à lire avec les ruptures |
| **Couverture (jours)** | stock ÷ vente moyenne par jour | cible selon la classe |
| **Taux de rupture** | produits actifs à stock 0 ÷ produits actifs (hors `desactiv_alrt_rup`) | par classe : une rupture en A ou en vital pèse plus |
| **Jours de rupture** | jours à stock 0 sur la période (`historique_stock_jour`) | base de la demande perdue |
| **Stock dormant** | valeur des produits en stock sans vente depuis N mois (N = 6 par défaut) ÷ valeur du stock | trésorerie gelée |
| **Surstock** | valeur au-delà de X mois de couverture (X selon la classe) | à écouler ou retourner |
| **Péremption à risque** | valeur des lots en stock périmant sous 1 / 3 / 6 mois | pertes évitables |
| **Taux de péremption** | valeur périmée ÷ valeur achetée | pertes subies |
| **Exactitude du stock** | références dont compté = théorique ÷ références comptées | fiabilité de tout le reste |
| **Démarque** | Σ écarts d'inventaire valorisés ÷ valeur du stock | pertes inconnues |
| **GMROI** | marge brute ÷ valeur moyenne du stock | rentabilité du stock |
| **Fournisseur : délai** | moyenne et écart-type (réception − commande) | entre dans le stock de sécurité |
| **Fournisseur : complétude** | lignes livrées en entier ÷ lignes commandées | fiabilité |

Classements :

- **ABC** — part cumulée du chiffre d'affaires 12 mois : A ≤ 80 %, B ≤ 95 %,
  C au-delà (implémenté, `services/stock_segmentation.py`).
- **XYZ** — régularité de la demande (coefficient de variation) : X régulier,
  Y variable, Z erratique (implémenté).
- **VEN** — Vital / Essentiel / Non essentiel, fixé par le pharmacien, pas
  calculé (à créer).
- **Taux de service cible** — par croisement ABC × VEN ; il règle le stock de
  sécurité : `z × σ` de la demande pendant le délai de livraison.

Un indicateur qui influence la prime (`ventes_peremption_3`, catégories)
relève de la règle « Paie » : pas de changement sans test de non-régression
dans `backend/tests/paie/`.

---

## 5. Règles backend

- **Existant** : suivre les conventions de `stock.py` (SQL brut paramétré,
  `async def`, réponses nues). Corriger au plus près.
- **Nouveau** : découpage cible `backend/app/modules/<nom>/` (router,
  service, repository, schemas), enveloppe `{data, error}`.
- **Schéma** : toute table ou colonne passe par une migration Alembic
  numérotée (`004_…`). Vérifiée sur une base locale avant d'être poussée.
- **Paramètres liés** partout (`:param`), jamais de valeur en f-string.
- **Listes** : toujours paginées (`limit` / `offset`, `total`), triées de
  façon stable.
- **Performance** : une route d'écran répond en moins d'une seconde sur les
  volumes réels (563 000 lignes de vente). Sinon : index, ou agrégat
  pré-calculé rafraîchi après la synchronisation — pas de calcul lourd à
  chaque affichage.
- **Tests** : chaque calcul d'indicateur a un test sur un petit jeu de
  données dont le résultat est connu à la main, y compris les cas limites
  (stock nul, aucune vente, péremption inconnue, produit archivé).
- **Écritures** : réservées aux rôles autorisés, tracées (qui, quand, ancienne
  et nouvelle valeur) pour les seuils, classes et inventaires.

---

## 6. Règles frontend (Flutter)

Celles de `CLAUDE.md`, Partie 2, s'appliquent en entier. Pour le stock :

- **Mobile d'abord**, 390 px : l'employé est devant l'étagère, une main prise.
- **Recherche** par nom, DCI ou code-barres (lecture par l'appareil photo) :
  c'est l'entrée principale.
- **Trois états** par écran : vide, chargement, erreur — plus l'horodatage
  des données.
- **Hors ligne** : consultation du stock sur la dernière copie locale ; les
  saisies (comptage, seuil) partent dans la file d'attente et se
  synchronisent ensuite, avec un `client_uuid`.
- **Couleurs d'alerte constantes** : rupture, sous le seuil, péremption
  proche, périmé — les mêmes sur tous les écrans, jamais la couleur seule
  (icône ou libellé en plus).
- **Une alerte = une action** proposée, pas seulement un constat.
- **Montants** affichés en DA, sans décimales inutiles ; quantités en unités.

---

## 7. Avant de dire « terminé »

Pour chaque fonctionnalité du module :

- [ ] la définition de l'indicateur est dans la section 4, ou y a été ajoutée
- [ ] le calcul a un test avec un résultat vérifié à la main
- [ ] le chiffre a été rapproché d'EASYPHARM sur des produits réels
- [ ] la route répond en moins d'une seconde sur la base réelle
- [ ] les cas limites sont traités (vide, zéro, inconnu, archivé, bloqué)
- [ ] aucune donnée patient ne sort du réseau local
- [ ] toute modification de schéma a sa migration, testée
- [ ] l'écran a ses trois états et l'horodatage des données
- [ ] `scripts/verifier_stock.py` passe toujours

---

## 8. Points connus à traiter en phase 0

- La vue `mv_stock_produits` n'est rafraîchie par personne : l'agent
  n'appelle pas `POST /stock/refresh-cache` après ses passes.
- `inventaires` est vide côté EASYPHARM alors que `inventaires_produits`
  contient ~27 900 lignes ; le moteur d'achat ne lit que les inventaires
  validés de la première, et les anciennes colonnes de la seconde.
- Format de péremption : `dashboard.py` suppose `MM/YYYY`, `performance.py`
  suppose `MM/YY` (`docs/02-sync-contrat.md` §6.2).
- La segmentation ABC/XYZ n'a jamais tourné sur cette base ; elle est
  planifiée mensuellement et peut être lancée par
  `POST /stock/segmentation/run`.
- `nomenclature.generique` n'est alimentée par rien.
