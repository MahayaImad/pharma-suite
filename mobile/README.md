# PharmaSuite — application (Flutter)

Android en priorité, et web pour le poste de l'officine. Pensée d'abord pour
390 px de large.

## État

- Les cinq thèmes, le choix du thème dans les préférences (conservé sur
  l'appareil) et la navigation : menu latéral sur PC, barre du bas sur portable.
- **Connexion** avec un compte de l'API : écran en deux volets (photo à gauche,
  formulaire à droite ; bandeau au-dessus sur portable). La session (jeton et
  profil) est gardée sur l'appareil ; sans session, toute adresse renvoie vers
  `/connexion`. Déconnexion dans le menu et dans les préférences.
- **Stock** : valeur du stock et heure des données EASYPHARM, recherche (nom,
  DCI, code-barres), filtre par famille, par état (actifs, en stock, sous le
  seuil, rupture), tri, liste paginée ; fiche produit avec stock, seuil, ventes
  sur 12 mois, couverture, prix, marge et lots (péremption, fournisseur, BL).
  Sur PC, la fiche s'ouvre à côté de la liste ; sur portable, en plein écran.
- Accueil, Alertes, Inventaire et Commandes affichent encore « Bientôt
  disponible ».

Adresse de l'API : `--dart-define=API_URL=…` si fourni ; sinon, en web,
`<origine de la page>/api/v1` (nginx relaie vers l'API) ; sinon
`http://192.168.100.33:8000/api/v1`.

Modèles en `freezed` : après modification de `lib/domain/`, relancer
`dart run build_runner build --delete-conflicting-outputs` (les fichiers
`*.freezed.dart` et `*.g.dart` sont committés, ne pas les éditer).

Les appels authentifiés passent par `dioProvider` (jeton ajouté, session
fermée sur 401). Pas encore là : base locale et hors-ligne (Drift), lecture du
code-barres par l'appareil photo.

**Photo de connexion** : `assets/images/connexion.webp` est une image Envato
filigranée, provisoire. Acheter la licence (ou la remplacer) avant la mise en
production. Polices embarquées : Roboto et Sora (licence OFL).

## Commandes

```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run -d chrome                                   # développement
flutter build web --release --no-web-resources-cdn      # version web
flutter build apk --release                             # Android
```

### Sans installer Flutter : par Docker

Sur le serveur, Docker compile l'application et la sert :

```bash
cd docker
docker compose build web
docker compose up -d web
```

Puis ouvrir `http://<serveur>:8090` depuis un PC ou un téléphone du réseau
(port réglable par `WEB_PORT` dans `docker/.env`). Les appels `/api/` sont
relayés vers l'API : une seule adresse à connaître. Après un `git pull`,
relancer ces deux commandes.

`--no-web-resources-cdn` est obligatoire pour la version web : sans lui,
Flutter télécharge son moteur de rendu depuis Internet à chaque ouverture.
Avec lui et la police embarquée (`assets/fonts/`), l'application ne contacte
que le serveur de l'officine.

## Organisation

```
lib/
├── main.dart              # lit les préférences, puis lance l'application
├── app.dart               # MaterialApp, thème courant, routeur
├── core/
│   ├── theme/themes.dart  # les cinq thèmes, couleurs d'état
│   ├── router/            # go_router
│   └── widgets/           # coquille (navigation), pastille d'état, état vide
└── features/
    └── preferences/
        ├── application/   # providers Riverpod
        └── presentation/  # écrans
```

Une fonctionnalité = `features/<nom>/` avec `application/` et
`presentation/`. Un widget ne lit ni le réseau ni le stockage directement :
il passe par un provider.

## Thèmes

`ThemeId` : `bleu` (par défaut), `sombre`, `vert`, `turquoise`, `indigo`.
Seules quelques couleurs changent d'un thème à l'autre ; les couleurs d'état
(rupture, seuil, bon) sont les mêmes dans tous les thèmes clairs et
s'emploient toujours avec une icône et un libellé (`PastilleEtat`).

Ajouter un thème : une valeur dans `ThemeId`, une entrée dans `_palettes`.
Les tests vérifient le contraste du texte sur chaque thème.
