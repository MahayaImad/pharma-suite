# Module Commandes : comment il fonctionne

État au 2026-11-16. Ce document résume le module tel qu'il est codé. Les
définitions des indicateurs du stock sont dans `05-stock-guide.md`, et les
règles métier une par une dans `BUSINESS_LOGIC.md` §3.9.

---

## 1. Le principe

**PharmaSuite propose et prépare la commande, EASYPHARM la reçoit.**

- **Chaque soir** (sauf le vendredi, grossistes fermés), PharmaSuite calcule
  pour chaque produit s'il faut commander, combien, et chez quel grossiste.
- **Les commandes partent** par WhatsApp ou par téléphone. Les factures
  arrivent dans EASYPHARM par e-facture, comme avant.
- **L'agent ne fait que lire EASYPHARM** : il n'y écrit jamais. Une commande
  vit donc dans PharmaSuite, du brouillon jusqu'à l'envoi.

## 2. Le cycle d'une commande

```
proposée  →  brouillon  →  validée  →  envoyée
                 │             │
                 └── annulée ──┘
```

1. **Proposée.** C'est le calcul du soir, rien n'est encore enregistré : un
   panier par grossiste.
2. **Brouillon.** La proposition est enregistrée (« Préparer », ou dès le
   premier geste : changer une quantité, ⇄ générique, déplacer, ajouter).
   Une commande par jour et par grossiste.
3. **Validée.** Par le titulaire ou un employé désigné. Elle est alors figée ;
   « Rouvrir » la repasse en brouillon.
4. **Envoyée.** « Envoyer par WhatsApp » ouvre WhatsApp avec le bon déjà
   rempli (produits et boîtes, sans prix). Le bon reste copiable.
5. **En cours.** Une commande validée ou envoyée compte « en cours » jusqu'à
   sa livraison prévue, pour ne pas recommander le lendemain. Ensuite, la
   marchandise est dans le stock d'EASYPHARM.

Le vendredi, l'écran prépare la commande du samedi.

## 3. Combien commander : la stratégie mini / maxi

Arrêtée avec l'officine le 2026-11-16 (`proposition.decider_minmax`).

### 3.1 Prévoir la vente

- **Type de demande** (méthode Syntetos et Boylan, sur 12 mois) : régulier,
  irrégulier, intermittent, sporadique, lent (moins de 12 jours de vente par
  an), nouveau (moins de 90 jours depuis la première vente). Un nouveau
  produit vendu moins de 3 jours compte comme lent.
- **Rythme** : vente moyenne par jour ouvert, sur 8 semaines (régulier,
  irrégulier) ou 26 semaines (les autres types).
- **Jours de rupture exclus** : leur demande est inconnue. Pour qu'un produit
  presque toujours en rupture n'ait pas un rythme absurde, on ajoute
  l'équivalent de 14 jours au rythme moyen de la fenêtre :
  `(ventes des jours retenus + 14 × moyenne brute) / (jours retenus + 14)`.
- **Calendrier** :
  - profil de la semaine ;
  - gardes (soirée, 24 h, jour de fermeture) ;
  - saison, si le produit est saisonnier d'une année sur l'autre ;
  - Ramadan, ramené vers 1 quand le volume est faible.

### 3.2 Les deux seuils

| Seuil | Calcul |
|---|---|
| **Mini** (point de commande) | max(demande jusqu'à la livraison suivante + stock de sécurité, **taille d'une ordonnance**) |
| **Maxi** (stock maximum) | mini + demande prévue sur la **couverture visée** |

- **Stock de sécurité** = Z × écart-type journalier × √jours, avec Z selon la
  classe : A 95 %, B 90 %, C 85 %. Au moins 1 boîte pour un produit qui se
  vend.
- **Taille d'une ordonnance** = quantité vendue en une fois dans 80 % des
  ventes du produit sur 12 mois (Spiriva : 3).
- **Couverture visée** : A 15 jours, B 21, C 30, **en tension 60**. Elle ne
  dépasse jamais 80 % de la durée de vie habituelle du produit à réception.

### 3.3 La décision

- **On ne commande que sous le mini**, et alors jusqu'au maxi. Un produit en
  tension est complété dès qu'il passe sous le maxi.
- **Quantité** = maxi − stock − commandes en cours, arrondie à la boîte.
- **Au moins le lot habituel** : la médiane de vos réceptions sur 12 mois,
  hors unités gratuites, avoirs et échanges (Clofenal : 30). Le lot ne peut
  pas faire dépasser 90 jours de vente, ni la péremption.

### 3.4 Les cas particuliers

| Cas | Règle |
|---|---|
| Produit lent | 1 ordonnance en rayon s'il s'est vendu dans les 6 derniers mois |
| Produit lent **et cher** (une ordonnance > 5 000 DA) | Pas de stock, **commandé à la demande** (Menopur, Decapeptyl…) |
| **Parapharmacie** (grossiste de type « para ») | Stock seulement pour les classes **A et B** ; un produit de classe C se commande à la main |
| Produit **en tension** confirmé | Couverture de 60 jours, complété dès que possible, étiquette « Quota » |
| Psychotrope | Listé à part : il se commande dans EASYPHARM (bon spécial) |
| Consommable confirmé | Exclu (jamais vendu) |

## 4. Les génériques

Règle du 2026-11-15 (`prevision/generiques.py`).

- **Groupe** : les produits de même code DCI (`nomenclature.de_equiv`, dosage
  et forme compris : 04B044, 14A224…).
- **Classe chronique** : les 3 premiers caractères du code donnent la classe
  thérapeutique (« 14A » antidiabétiques, « 06M » hypolipémiants). Une classe
  présente dans `classe_maladie` (maladies chroniques de la CNAS) garde
  **toutes** ses marques : chaque patient est habitué à la sienne.
- **Autres classes** (AINS…) : seules les **2 marques les plus vendues** sur
  12 mois, parmi les disponibles (en stock ou vendues dans les 60 jours),
  sont commandées. Les autres s'écoulent, puis leur demande passe aux marques
  gardées.
- **Calcul au niveau de la DCI** : les marques gardées sont calculées
  ensemble (ventes, stock, commandes en cours). La quantité est ensuite
  répartie selon leur part des ventes. Xydol en stock évite donc de
  commander Sapofen.
- **Choix du titulaire**, depuis la fiche produit, section « Génériques » :
  - par groupe : toutes les marques, ou seulement les plus vendues ;
  - par marque : toujours commander, ou ne plus commander.
- **Dans le panier** : ⇄ remplace une ligne par un autre générique de la même
  DCI, même quantité, même panier.

## 5. Les grossistes

- **Grossiste d'un produit** : son **grossiste préféré** s'il y en a un
  (table `produits_fournisseur_prefere`, migration 016), sinon celui de son
  dernier achat (hors avoirs et échanges) ; au dernier prix d'achat.
- **Retenir un grossiste** : changer le grossiste d'une ligne ne vaut que
  pour le soir ; le message qui suit propose « Toujours » pour le retenir
  (`PUT /commandes/preferes/{id}`). On l'oublie depuis les actions de la
  ligne (« Ne plus préférer ce grossiste »). Un grossiste désactivé par le
  titulaire n'est plus suivi.
- **Actif ou inactif** : sans réglage du titulaire, un grossiste est actif
  s'il a livré ou reçu une commande dans les 30 derniers jours. Un grossiste
  inactif n'a pas de panier ; ses produits sont listés « sans fournisseur
  actif ».
- **Type** : pharmaceutique ou parapharmaceutique, deviné d'après les
  produits reçus (DCI ou code CNAS), puis corrigeable.
- **Numéro WhatsApp** : par défaut, le portable enregistré dans EASYPHARM.
- **Changer de grossiste** pour une ligne : glisser la ligne sur un autre
  grossiste (sur PC), ou le menu de la ligne (sur portable). La ligne garde
  sa quantité. Ce choix ne vaut que pour la commande du jour.

## 6. Produits en tension

- **Détection automatique**, avec deux critères :
  - en rupture depuis au moins 14 jours, sans aucune livraison, alors que le
    produit se vendait au moins 6 jours sur les 6 mois d'avant ;
  - ou marqué « quota » dans EASYPHARM.
- **Le titulaire confirme ou écarte**, dans Préférences › Produits en
  tension, ou avec la case « En tension » de la fiche (qui sert aussi à
  marquer un produit soi-même). Un produit écarté n'est jamais reproposé.
- **Seuls les produits confirmés** changent le calcul.

## 6 bis. Suivi des livraisons

PharmaSuite n'enregistre pas la réception : il la **lit** dans EASYPHARM et
la rapproche des lignes commandées (`rapprochement.py`, `GET /commandes/suivi`).

- Une entrée EASYPHARM est attribuée à la plus ancienne ligne encore ouverte
  du **même grossiste** et du **même produit**, envoyée avant elle. Une ligne
  reste ouverte jusqu'à 7 jours après sa livraison prévue.
- États d'une ligne : **attendue** (date prévue pas dépassée), **livrée**
  (tout reçu), **partielle**, **manquante** (rien reçu, date dépassée).
- **En cours** = seulement le reste à recevoir des lignes attendues. Ce qui
  est déjà entré dans EASYPHARM n'est plus compté deux fois ; ce qui n'est
  pas arrivé à la date prévue est **reproposé** le soir même.
- **Budget engagé** = ce même reste à recevoir.
- **Taux de service** de chaque grossiste : lignes livrées en entier et
  quantités reçues, sur les commandes dont la date est passée.
- Un produit commandé **2 fois en 45 jours sans jamais être livré** est
  proposé comme produit en tension (à confirmer).

Limite : une réception saisie le jour même de l'envoi n'est pas comptée, et
un produit livré par un autre grossiste reste « manquant » chez le premier.

## 7. Budget

Le reste du mois se calcule ainsi :

```
reste = budget − achats reçus ce mois (EASYPHARM, hors avoirs et échanges)
               − commandes validées ou envoyées pas encore livrées
```

L'écran affiche aussi le montant proposé ce soir et ce qui restera après. Le
budget se règle dans Calendrier et réglages (0 = pas de budget).

## 8. Qui fait quoi

| Action | Qui |
|---|---|
| Voir, préparer, corriger un brouillon, ajouter, déplacer, ⇄ | Tout utilisateur connecté |
| Valider, rouvrir, annuler une commande validée | Titulaire ou employé désigné |
| Grossistes, valideurs, tensions, choix des génériques, réglages | Titulaire (rôle `admin`) |

## 9. Les écrans

- **Commandes** (`/commandes`) :
  - à gauche, le budget, « Préparer toutes les commandes », les grossistes
    (pharmaceutiques puis parapharmaceutiques), les psychotropes et les
    produits sans fournisseur ;
  - à droite (plein écran sur portable), le panier : filtres (Tout, Ruptures,
    Modifiées, Génériques), une ligne par produit avec la raison du calcul,
    − / +, ⇄, poignée ⋮⋮ ; barre fixe en bas avec le total et l'action de
    l'étape.
- **« Pourquoi cette quantité ? »** (appui sur une ligne) : type de demande,
  rythme comparé à la moyenne sur 12 mois, jours exclus pour rupture, mini,
  maxi, couverture, lot, ou la raison d'une commande à la demande.
- **« Commander »** (écran Stock et fiche produit) : ajoute le produit au
  brouillon du jour de son grossiste. Le panier proposé de ce grossiste est
  préparé au besoin.
- **Livraisons** (onglet de l'écran Commandes, `/commandes/livraisons`) :
  tuiles (non livrés, partiels, attendus, taux de service), liste par produit
  filtrable, taux de service de chaque grossiste. « Autre grossiste » ajoute
  le reste à recevoir au brouillon du jour d'un autre grossiste actif
  (`POST /commandes/ajouter` avec `id_fournisseur`). L'onglet porte le nombre
  de produits à vérifier.
- **Écran Stock aligné** : dès que le calcul des commandes est prêt, le Stock
  utilise les mêmes seuils que le panier. « À commander » = ce que le panier
  propose ; la jauge et la fiche montrent le point de commande (mini), le
  stock maximum et la quantité du soir ; le surstock se mesure au-dessus du
  maximum des commandes. Tant que le calcul n'est pas prêt (quelques minutes
  après un redémarrage), le Stock garde ses seuils simples.
- **Préférences** :
  - Fournisseurs et validation ;
  - Produits en tension ;
  - Calendrier et réglages (gardes, fêtes, couvertures, budget, seuil du
    produit lent et cher, nombre de marques gardées).

## 10. Où c'est dans le code

| Partie | Emplacement |
|---|---|
| API (format cible, réponses `{data, error}`) | `backend/app/modules/commandes/` : router, service, repository, schemas |
| Calcul | `backend/app/services/prevision/` : `modele.py` (prévision), `proposition.py` (décision, mini / maxi), `generiques.py`, `du_jour.py` (proposition du soir, regroupement par DCI), `donnees.py` (chargement), `rejeu.py` |
| Tables | `commandes`, `commandes_lignes`, `fournisseurs_commande`, `commandes_valideurs` (012) ; `generiques_groupes`, `generiques_choix` (013) ; `produits_tension` (014) |
| Réglages (`reglages_stock`) | `budget_mensuel_commandes`, `generiques_gardes`, `couverture_{a,b,c,tension}_jours`, `lent_valeur_max_da` (012 à 015) |
| Application | `mobile/lib/features/commandes/`, `mobile/lib/domain/commandes.dart` |

**Exécution sur le serveur.** Le calcul tourne dans un fil à part, un seul à
la fois. Il est préparé toutes les 15 minutes et gardé en cache jusqu'au
prochain rafraîchissement du stock, pour que l'API continue de répondre.

## 11. Outils

```bash
cd docker
docker compose run --rm api python -m scripts.rejouer_commandes
docker compose run --rm api python -m scripts.expliquer_quantite "NOM DU PRODUIT"
```

- **`rejouer_commandes`** rejoue les 12 derniers mois jour par jour, comme si
  PharmaSuite avait commandé. Il compare les politiques à la réalité :
  ruptures, stock moyen, demande servie, lignes de commande.
- **`expliquer_quantite`** donne le détail du calcul d'un produit, comme le
  volet « Pourquoi cette quantité ? ».

**Derniers résultats mesurés (2026-11-15)** : 2,4 % de jours en rupture
contre 23,3 % en réalité, et un stock moyen de 20,3 M DA contre 27,4 M DA,
avec la politique quotidienne et les génériques. La stratégie mini / maxi n'a pas
encore été rejouée sur les données réelles.

## 12. Limites connues et suite

**Limites connues**

- **Grossistes** : les pénuries ne sont pas simulées dans le rejeu, qui
  suppose toute commande livrée.
- **Rejeu** :
  - les tensions passées sont inconnues ;
  - le stock commun d'une DCI n'y est pas mis en commun.
- **Demande des jours de rupture** : inconnue, donc sous-estimée, aussi bien
  dans le calcul que dans la mesure.

**À faire**

1. Rejouer la stratégie mini / maxi sur les données réelles.
2. Vue Alertes.
3. Modèle de fondation en concurrence dans le rejeu (service `ml/`).
