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
3. **Chaque indicateur a une définition écrite** (section 5) : formule,
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
| **0. Fiabiliser** | lancer `scripts/verifier_stock.py`, corriger ce qui échoue ; rafraîchir la vue du stock après chaque passe de l'agent ; trancher le format de péremption ; contrôler sur 20 produits que la synchronisation suit EASYPHARM | toutes les routes répondent, et les 20 produits concordent |
| **1. Consulter** | recherche produit, fiche, lots triés par péremption (FEFO), stock et valeur | un employé retrouve un produit et ses lots en moins de 10 s |
| **2. Alerter** | ruptures, sous le seuil, péremptions à 1/3/6 mois, stock dormant, surstock | chaque alerte mène à une action (commander, mettre en avant, échanger, retourner) |
| **3. Piloter** | indicateurs de la section 5, par famille / étagère / responsable, avec historique | le titulaire lit l'état du stock en une page |
| **4. Classer** | ABC × XYZ existants, ajout de la criticité VEN, taux de service cible par classe (bloc 1) | chaque produit actif a ses trois classes |
| **5. Inventorier** | inventaire tournant : listes de comptage par classe, saisie, écarts, exactitude | l'exactitude du stock est mesurée chaque mois |
| **6. Réapprovisionner** | brancher le moteur d'achat existant (`assistant_achat`) sur des paramètres fiables | une proposition de commande est acceptée sans retouche majeure |

La phase 0 est le backend ; le frontend Flutter démarre à la phase 1, sur
des routes vérifiées. Les six blocs de la section 4 disent, pour chaque
phase, la méthode à suivre.

---

## 3. Règles sur les données

- **Stock d'un produit** = somme des `entrees_produits.stock` de ses lots
  (vue `mv_stock_produits`). Ce champ est celui qu'EASYPHARM affiche : le
  stock n'y est pas calculé, il est stocké et tenu à jour sur la ligne du lot
  (`docs/BUSINESS_LOGIC.md` §3.3). PharmaSuite ne recalcule donc jamais un
  stock du jour ; un écart avec EASYPHARM ne peut venir que de la
  synchronisation. `nomenclature.stock` vaut 0 partout et ne s'utilise pas.
- **Produit actif** = non archivé **et** (en stock **ou** vendu au moins une
  fois dans les 12 derniers mois). Calculé dans la vue (`actif`), à chaque
  recalcul. Les ruptures, les alertes et tout taux de rupture ne portent que
  sur les produits actifs. Un produit à stock nul et inactif a la
  disponibilité `inactif`, pas `rupture`.
- **Prix de vente d'un produit** = celui de son lot de référence : le plus
  récent ayant du stock, à défaut le plus récent tout court, hors avoirs
  (`mv_stock_produits.prix_vente`). `nomenclature.prix_vente` vaut 0 partout
  et ne s'utilise pas. La valeur d'un stock se calcule lot par lot
  (`valeur_achat`, `valeur_vente`), jamais stock × prix de référence.
- **La vue `mv_stock_produits` doit être rafraîchie** après chaque
  synchronisation, sinon tout le module affiche un stock périmé. À la
  création de la base elle est vide (`WITH NO DATA`) et toute lecture échoue
  tant qu'elle n'a pas été calculée une première fois.
- **Péremption** : `entrees_produits.peremption_date` (date) fait foi quand
  elle est remplie ; sinon on convertit le texte `peremption`, dont le format
  réel (`MM/YY` ou `MM/YYYY`) se constate dans le rapport de vérification —
  on ne le suppose pas. Une péremption illisible est comptée et affichée
  comme « inconnue », jamais ignorée.
- **Ventes** (`docs/BUSINESS_LOGIC.md` §2.3, vérifié sur la base) : une ligne
  de vente a `type_sortie = 'V'` ; un retour client n'a pas de type dédié, sa
  `qte_sortie` est **négative**. Le net est donc la simple somme de
  `qte_sortie` ; pour compter des ventes, filtrer `qte_sortie > 0`. Les
  valeurs `RET` et `AV` n'existent pas côté ventes.
- **Achats** : `type_entree = 'AV'` est un avoir produit, un retour au
  fournisseur ; il s'exclut des quantités reçues.
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

## 4. Méthode : les six blocs

La gestion du stock repose sur six blocs, tirés de la littérature
(Silver, Pyke et Thomas ; Syntetos et Boylan ; Nahmias ; MSH, *MDS-3*). Pour
chacun : la règle de l'art, ce que le code fait déjà, ce qui reste à faire.
« Existe » veut dire écrit, pas encore vérifié sur les données réelles.

### Bloc 1 — Classer avant de gérer

On ne gère pas 9 000 références de la même façon.

| Classement | Critère | Sert à |
|---|---|---|
| **ABC** | valeur vendue sur 12 mois (A ≤ 80 % du cumul, B ≤ 95 %, C au-delà) | concentrer le contrôle et la trésorerie |
| **XYZ** | régularité de la demande (coefficient de variation) | choisir la méthode de prévision |
| **VEN** | criticité thérapeutique : Vital, Essentiel, Non essentiel | fixer le taux de service visé |

Le croisement **ABC × VEN** est la référence en pharmacie : un produit vital
de classe C mérite un stock de sécurité qu'un classement purement financier
lui refuserait.

Règles de calcul retenues (`services/stock_segmentation.py`, testées dans
`backend/tests/stock/`) :

- **Produits classés** : non archivés, chiffre d'affaires **net** positif
  sur 12 mois glissants (les retours, à quantité négative, se déduisent).
  Les autres n'ont **pas de classe** : un produit sans mouvement n'est ni C
  ni Z. ABC et XYZ classent exactement les mêmes produits.
- **ABC** : produits rangés par chiffre d'affaires décroissant ; A tant que
  le cumul *avant* le produit est sous 80 %, B sous 95 %, C ensuite. Le
  produit qui fait franchir un seuil appartient à la classe qu'il termine.
- **XYZ** : coefficient de variation des quantités mensuelles sur les
  **12 derniers mois complets**, les mois sans vente comptant pour **zéro** ;
  X sous 0,5, Y sous 1, Z au-delà. Pour un produit récent la série part du
  mois de sa première vente ; sous 3 mois d'historique : Z.
- Une classe devenue fausse est effacée au recalcul.

- **Existe** : ABC et XYZ, recalcul le 1er du mois, lancement à la main par
  `python -m scripts.calculer_segments`, matrice ABC × XYZ
  (`/stock/kpis/segments`).
- **À faire** : VEN (colonne, saisie par le pharmacien, valeur par défaut par
  classe thérapeutique) ; croisement ABC × VEN. *Phase 4.*

### Bloc 2 — Prévoir la demande

| Demande | Méthode |
|---|---|
| régulière (X) | lissage exponentiel ; Holt-Winters s'il y a saisonnalité (grippe, allergies, Ramadan) |
| intermittente (Z) | Croston, corrigé par Syntetos-Boylan — les moyennes classiques surestiment |
| censurée par une rupture | corriger l'historique des jours à stock nul : les ventes sous-estiment le besoin |

La qualité se mesure : erreur (MAPE ou MASE — le MAPE est indéfini quand la
demande vaut zéro) et **biais**, suivis dans le temps et par classe.

- **Existe** : `purchase_engine/forecaster.py` choisit entre Croston
  (variante SBA), Holt-Winters, régression et moyenne mobile, sur le MAPE des
  30 derniers jours ; `censored_demand.py` corrige la demande des jours de
  rupture ; `stock_history.py` reconstitue le stock jour par jour.
- **À faire** : vérifier sur données réelles ; remplacer ou compléter le MAPE
  par le MASE pour les produits intermittents ; suivre le biais ; gérer les
  fêtes mobiles (Ramadan, Aïd), que la saisonnalité calendaire ne voit pas ;
  aligner les filtres de vente sur la règle de la section 3 (retour =
  quantité négative). *Phase 6.*

### Bloc 3 — Décider quand et combien commander

```
stock de sécurité  SS  = z × σ(demande) × √(délai)
point de commande  ROP = demande moyenne × délai + SS
quantité économique EOQ = √(2 × demande annuelle × coût de commande ÷ coût de possession)
```

- `z` vient du **taux de service visé**, qui dépend de la classe, pas d'une
  valeur unique.
- En officine, avec des livraisons quotidiennes ou presque, la politique
  adaptée est la **révision périodique avec niveau de recomplètement**
  (min / max) ; l'EOQ sert de repère, pas de règle.
- La variabilité du **délai fournisseur** entre dans le stock de sécurité,
  pas seulement celle de la demande.
- Contraintes réelles : colisage, minimum de commande, remises par palier,
  unités gratuites, budget.

- **Existe** : `purchase_engine/stock_params.py` (SS, ROP, EOQ ; taux de
  service A 95 %, B 90 %, C 85 %) ; `optimizer.py` (quantités entières sous
  contrainte de budget, PuLP) ; tables `parametres_stock` et
  `previsions_demande`.
- **À faire** : taux de service par ABC × VEN au lieu d'ABC seul ; délai et
  sa variabilité mesurés par fournisseur au lieu d'un délai fixe ; coût de
  commande (500 DA) et taux de possession (20 %) aujourd'hui en dur, à rendre
  configurables ; colisage, minimum, remises et unités gratuites absents de
  l'optimisation ; montants en `Decimal` (le moteur calcule en `float`).
  *Phase 6.*

### Bloc 4 — Gérer le périssable

- **FEFO** : premier périmé, premier sorti — pas FIFO.
- Suivi par **lot** et date de péremption ; alertes à 6, 3 et 1 mois.
- Pour un lot proche de la péremption, une action : mise en avant, échange
  inter-pharmacies, retour fournisseur.
- **Stock dormant** (aucune vente depuis N mois) et **surstock** détectés et
  valorisés.
- Un lot périmé encore en stock est une anomalie à traiter, pas une ligne de
  tableau.

- **Existe** : lots triés par péremption (`/stock/products/{id}/lots`),
  alertes à 3 / 6 / 9 mois et surstock (`/stock/dashboard/lots`), KPI
  `ventes_peremption_3` (prime).
- **À faire** : trancher le format de péremption (section 9) ; alerte à
  1 mois ; lots périmés en stock ; stock dormant ; l'action associée à chaque
  alerte ; taux de péremption (pertes subies). *Phases 2 et 3.*

### Bloc 5 — Fiabiliser les données

- **Inventaire tournant** : compter un peu chaque jour, à une fréquence
  fixée par la classe (A souvent, C rarement), plutôt qu'un inventaire annuel.
- **Exactitude du stock** : part des références dont le compté égale le
  théorique. C'est le préalable à tout : une prévision sur un stock faux ne
  vaut rien.
- **Analyse des écarts** par cause : casse, vol, erreur de saisie, périmé.
- **Psychotropes** : traçabilité renforcée, registre et rapprochement.

- **Existe** : tables `inventaires` et `inventaires_produits` (miroir
  EASYPHARM), historique et instantané des psychotropes
  (`/stock/psychotropes/*`).
- **À faire** : tout l'inventaire tournant (listes de comptage, saisie
  mobile, écarts, causes) dans des tables propres à PharmaSuite, puisque
  PharmaSuite n'écrit pas dans EASYPHARM ; exactitude et démarque ;
  rapprochement stock fiche / somme des lots. *Phases 0 et 5.*

### Bloc 6 — Mesurer

Les indicateurs sont définis à la section 5. Trois règles de lecture :

- ils se lisent **ensemble** : une rotation excellente avec des ruptures
  fréquentes est une mauvaise gestion ;
- ils se déclinent **par classe** : un taux de rupture global cache une
  rupture sur un produit vital ;
- ils se suivent **dans le temps** : une valeur isolée ne dit rien, une
  tendance oui — d'où un relevé périodique conservé.

- **Existe** : rotation, segments, catégories (`/stock/kpis/*`), valeur du
  stock.
- **À faire** : couverture, taux et jours de rupture, dormant, taux de
  péremption, exactitude, démarque, GMROI, indicateurs fournisseurs, et
  l'historisation de tous. *Phase 3.*

---

## 5. Indicateurs — définitions de référence

Période par défaut : 12 mois glissants, sauf mention. Tout indicateur se
décline par famille, étagère, responsable, classe ABC/XYZ/VEN.

| Indicateur | Formule | Lecture |
|---|---|---|
| **Valeur du stock** | Σ (stock du lot × prix d'achat du lot) | capital immobilisé |
| **Rotation** | coût d'achat des ventes ÷ valeur moyenne du stock | plus haut = mieux, à lire avec les ruptures |
| **Couverture (jours)** | stock ÷ vente moyenne par jour (quantité vendue sur 12 mois ÷ 365) ; non mesurable sans vente | cible selon la classe |
| **Taux de marge** | (prix de vente − prix d'achat moyen pondéré) ÷ prix d'achat, en % — lecture de la réglementation algérienne des marges, sur le prix d'achat | affiché sur la fiche produit |
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

Les classements ABC, XYZ et VEN et le taux de service cible sont définis
aux blocs 1 et 3 de la section 4.

Un indicateur qui influence la prime (`ventes_peremption_3`, catégories)
relève de la règle « Paie » : pas de changement sans test de non-régression
dans `backend/tests/paie/`.

---

## 6. Règles backend

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

## 7. Règles frontend (Flutter)

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

## 8. Avant de dire « terminé »

Pour chaque fonctionnalité du module :

- [ ] la définition de l'indicateur est dans la section 5, ou y a été ajoutée
- [ ] le calcul a un test avec un résultat vérifié à la main
- [ ] le chiffre a été rapproché d'EASYPHARM sur des produits réels
- [ ] la route répond en moins d'une seconde sur la base réelle
- [ ] les cas limites sont traités (vide, zéro, inconnu, archivé, bloqué)
- [ ] aucune donnée patient ne sort du réseau local
- [ ] toute modification de schéma a sa migration, testée
- [ ] l'écran a ses trois états et l'horodatage des données
- [ ] `scripts/verifier_stock.py` passe toujours

---

## 9. Phase 0 — constats du rapport du 2026-11-10

`scripts/verifier_stock.py` sur la base réelle : les 32 routes de lecture
répondent, toutes en moins d'une demi-seconde. Chiffres : 9 184 produits,
2 354 en stock, 34 977 unités, 15,9 M DA de stock au prix d'achat, 55 238
lots dont 4 310 avec stock.

### Corrigé

- **Stock figé au chargement.** `entrees_produits` était synchronisée en
  « incremental » : seuls les nouveaux lots arrivaient, alors que chaque
  vente décrémente `stock` sur la ligne du lot. Stratégie « lots » dans
  l'agent (nouveaux lots, lots ayant du stock, lots venant de tomber à zéro).
- **Vue `mv_stock_produits` jamais calculée.** L'agent appelle maintenant
  `POST /stock/refresh-cache` après chaque passe qui touche le stock ; la
  route accepte une vue encore vide.
- **Format de péremption tranché : `MM/YY`** partout
  (`docs/02-sync-contrat.md` §6.2). `peremption_date` est remplie partout où
  le texte l'est.

- **Prix de vente à 0 dans toutes les listes** : `nomenclature.prix_vente`
  vaut 0 pour tous les produits. Le prix vient maintenant des lots, par la
  vue (migration 004).
- **« Rupture » sur 6 780 produits sur 9 184**, pour l'essentiel des
  références jamais ou plus vendues : définition du produit actif
  (section 3), appliquée aux alertes, aux ruptures et à la disponibilité
  (migration 004).

- **Classement ABC / XYZ** : le calcul d'origine classait « C » et « Z »
  les 5 565 produits inactifs, gardait pour toujours une classe devenue
  fausse, et mesurait la régularité sur les seuls mois avec vente — un
  produit vendu trois mois sur douze sortait « régulier ». Réécrit et testé.

### À corriger

- **Contrôle de la synchronisation sur 20 produits.** Le stock étant un
  champ lu tel quel, il n'y a pas de formule à valider : il reste à vérifier
  que la valeur lue est à jour (lots relus, lots épuisés remis à zéro).
- **Aucune catégorie, aucune étagère** : `laboratoires.is_generique` est faux partout, les étagères
  et responsables ne sont pas saisis. Les indicateurs par catégorie et par
  employé sont vides. **La catégorie alimente l'enveloppe de prime** : à
  traiter avec la règle « Paie ».
- **`dashboard.py:214`** attend `MM/YYYY` sur `instance_produits` et ne voit
  aucune ligne.
- **504 lots en stock sans date de péremption** (12 % des lots en stock),
  2 lots à stock négatif, 77 lots périmant sous 3 mois, aucun lot périmé en
  stock.
- **2 619 lignes de vente orphelines** (0,5 %) : leur produit n'existe plus
  dans la nomenclature.
- **Surstock** : la liste est plafonnée à 200 produits et va jusqu'à
  1 272 mois de couverture — à borner et à croiser avec le produit actif.
- **`psychotrope` prend la valeur 2** en plus de 0 et 1 ; les filtres ne
  retiennent que 1. Signification à confirmer.
- **Historique** : ventes depuis le 2022-01-16, lots depuis le 2023-01-01.
  La reconstitution du stock n'est pas possible avant 2023.
- **Inventaires** : 27 872 lignes rattachées à un seul inventaire, absent
  de la table `inventaires` (vide). Hypothèse : l'inventaire d'ouverture de
  2023. Les colonnes lues par le moteur d'achat (`id_nom`, `stock_reel`)
  sont vides ; les données sont dans `id_produit` et `quantite_physique`.
- **Moteur d'achat jamais exécuté** : `historique_stock_jour`,
  `parametres_stock` et `previsions_demande` sont vides.
- `nomenclature.generique` n'est alimentée par rien.
- Filtres de vente à aligner sur `docs/BUSINESS_LOGIC.md` §2.3 : le code
  filtre tantôt `type_sortie = 'V'`, tantôt `NOT IN ('RET', 'AV')`,
  `!= 'RET'` ou `NOT IN ('AV', 'R')`, et `stock.py` inverse le signe des
  lignes `RET` / `AV`. Aucune de ces valeurs n'existe : ces filtres ne font
  rien aujourd'hui ; à vérifier : les comptages de ventes peuvent inclure
  les retours.
- Le moteur d'achat calcule les montants en `float`, contre la règle
  « Argent ».
