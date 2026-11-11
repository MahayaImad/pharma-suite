# PharmaSuite — application (Flutter)

Android en priorité, et web pour le poste de l'officine. Pensée d'abord pour
390 px de large.

## État

Socle seulement : les cinq thèmes, le choix du thème dans les préférences
(conservé sur l'appareil) et la navigation, menu latéral sur PC, barre du bas
sur portable. Les sections Accueil, Stock, Alertes, Inventaire et Commandes
affichent un état « Bientôt disponible » : aucune donnée n'est encore lue.

Pas encore là : connexion, appels à l'API, base locale et fonctionnement hors
ligne (Dio, Drift, freezed viendront avec le premier écran de données).

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
