# Version web de l'application : compilée par Flutter, servie par nginx.
# Aucun Flutter à installer sur le serveur ; Docker s'en charge.
#
#   cd docker && docker compose build web && docker compose up -d web

ARG FLUTTER_VERSION=stable
FROM ghcr.io/cirruslabs/flutter:${FLUTTER_VERSION} AS build
WORKDIR /app

# Les dépendances d'abord : cette couche n'est refaite que si elles changent.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
# --no-web-resources-cdn : le moteur de rendu est servi par ce serveur, pas
# téléchargé depuis Internet à chaque ouverture.
RUN flutter build web --release --no-web-resources-cdn

FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
