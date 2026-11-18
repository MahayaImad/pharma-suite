# Paie : règles de calcul

Ce document décrit ce que PharmaSuite calcule aujourd'hui. Les arbitrages
d'origine sont dans `CLAUDE.md` (partie 4, 2026-08-19 et 2026-11-18). En cas
de contradiction, `CLAUDE.md` fait foi.

PharmaSuite calcule le **salaire brut** : part fixe + part variable. Les
cotisations CNAS et l'IRG restent au comptable.

## 1. Présence du mois

Elle vient de la grille GRH (`app/api/v1/grh_presence.py`), un statut par jour :

| Statut | D'où il vient |
|---|---|
| présent | au moins une vente ce jour-là (`sorties.utilisateur`) |
| retard | première vente plus de 45 minutes après l'heure de début (postes au comptoir), ou saisi par le titulaire |
| absent | aucune vente, poste qui vend au comptoir |
| à confirmer | aucune vente, poste qui ne vend pas (préparateur) |
| congé | demande de congé approuvée |
| maladie | saisi par le titulaire |
| férié | jours fériés fixes (1/1, 1/5, 19/6, 5/7, 1/11), jours saisis dans Préférences › Calendrier et réglages, Aïd el-Fitr et Aïd el-Adha du Calendrier |
| repos | vendredi |

Une saisie du titulaire remplace toujours le statut automatique.

**Heure de début** (arbitrage du 2026-11-18, en attendant une pointeuse) :
celle de l'employé (`employes.heure_debut`) si elle est renseignée, sinon le
réglage général `paie_heure_debut` (8 h 30) ; pendant le Ramadan, le réglage
`paie_heure_debut_ramadan`. Tolérance : `paie_tolerance_retard_min` (45).
C'est une approximation : un employé arrivé à l'heure peut faire sa première
vente plus tard. Le titulaire corrige le jour dans la grille.

## 2. Part fixe (`app/services/paie/part_fixe.py`)

```
part_fixe = salaire de base × jours sous contrat ÷ jours du mois
          + ancienneté      × jours sous contrat ÷ jours du mois
          + 300 DA × jours de présence effective          (transport)
          + 600 DA × jours de présence effective          (panier)
          + heures sup × (salaire de base ÷ 173,33) × 1,5
          − salaire de base ÷ 30 × jours d'absence injustifiée
```

- **Salaire de base** : celui du poste (`postes_travail`) : pharmacien
  assistant 42 000, caissier 40 000, préparateur 35 000 DA.
- **Jours sous contrat** : entre la date d'entrée et la date de sortie. Un
  jour « absent » avant l'arrivée n'est pas une absence.
- **Ancienneté** : 1 000 DA par année révolue au dernier jour du mois,
  plafond 15 000 DA.
- **Présence effective** : présent ou en retard. Congé, maladie, férié et
  jours « à confirmer » n'ouvrent droit ni au transport ni au panier.
- **Retard** : aucune retenue en argent ; il coûte un jour de ponctualité dans
  la part variable.
- **Heures supplémentaires** : saisies par le titulaire, arrondies au quart
  d'heure. 173,33 h = 40 h × 52 semaines ÷ 12 mois.
- **Absence injustifiée** : retenue de 1/30ᵉ du salaire de base par jour, sur
  le seul salaire de base.

Tous ces montants sont des réglages (`reglages_stock`, clés `paie_*`).

**Exemple** : caissier, 6 ans d'ancienneté, 24 jours présents, 1 absence.
40 000 + 6 000 + 7 200 + 14 400 − 1 333,33 = **66 266,67 DA**.

## 3. Part variable (`app/api/v1/performance.py`, `app/services/paie/`)

**Enveloppe** = Σ (CA du mois de la catégorie × taux) : princeps 0,5 %,
générique 1 %, générique++ 3 % (`prime_taux_config`). La catégorie est celle
de `nomenclature.categorie`, propre à PharmaSuite (EASYPHARM ne la fournit
pas). **Un produit sans catégorie, ou absent de la nomenclature, compte au
taux princeps** (arbitrage du 2026-11-18) : l'enveloppe n'est jamais nulle
faute de classement.

**Score de chaque employé** (distributif) :

```
score_i = Σ_kpi (valeur_i ÷ total de l'équipe) × poids du KPI pour le poste de i
```

- Poids par poste (`kpi_poids_poste`), sinon les poids globaux
  (`kpi_definitions.poids`).
- Les KPIs de volume (CA, nombre de ventes, clients, tâches, jours à l'heure,
  produits comptés…) sont **ramenés aux jours de présence** :
  valeur ÷ jours de présence effective × jours comptés comme travaillés
  (présence + congé + maladie + férié). Un congé ne fait pas baisser la prime.

| KPI | Comptoir | Préparateur |
|---|---|---|
| CA réalisé | 20 | |
| Tâches terminées dans les délais | 20 | 40 |
| Nombre de ventes | 12 | |
| Jours à l'heure | 10 | 25 |
| Panier moyen | 7 | |
| CA compléments / parapharmacie | 7 | |
| Boîtes vendues à moins de 3 mois de péremption | 7 | |
| Nouveaux clients | 7 | |
| Clients récupérés | 7 | |
| Montant encaissé (recouvrement) | 3 | |
| Produits comptés à l'inventaire | | 35 |

**Répartition** :

```
part_egalitaire = enveloppe ÷ nombre d'éligibles présents
plancher        = 50 % de la part égalitaire        (présents seulement)
prime_i         = plancher + score_i ÷ Σ scores × (enveloppe − Σ planchers)
```

Arrondi au centime, la somme des primes vaut toujours l'enveloppe.

## 4. Traçabilité

- Chaque calcul de primes est gardé (`primes_calculs`) ; le dernier est dans
  `performance_mensuelle`.
- Chaque validation de la paie ajoute une version du bulletin brut
  (`paie_bulletins`) ; aucune n'est écrasée.

## 5. Limites connues

- Le retard est déduit de la première vente, pas de l'heure d'arrivée ; il
  n'est pas détecté pour le préparateur. Une pointeuse est prévue.
- Les fériés religieux autres que l'Aïd (Mawlid, Achoura, 1er Moharram…) se
  saisissent dans Préférences › Calendrier et réglages, rubrique jours fériés.
- Les employés non éligibles à la prime (comptes non nominatifs) ne sont pas
  dans la paie.

## 6. À l'écran (`/paie`)

Titulaire seulement. Pour chaque employé : la part fixe ligne par ligne avec
son détail (« 24 jours × 300 »), le plancher et le mérite de la prime, et un
**radar des critères** de son poste. Sur chaque axe, l'employé est comparé à
la moyenne de l'équipe (100 = moyenne, cercle pointillé), à partir des
valeurs ramenées aux jours de présence ; l'axe s'arrête à 200. Le radar ne
reflète pas les poids : le tableau sous le radar les donne, avec la valeur du
mois et l'écart à la moyenne.

