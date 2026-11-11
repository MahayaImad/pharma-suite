# Version web de l'application : compilée par Flutter, servie par nginx.
# Aucun Flutter à installer sur le serveur ; Docker s'en charge.
#
#   cd docker && docker compose build web && docker compose up -d web

FROM debian:bookworm-slim AS build

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils \
 && rm -rf /var/lib/apt/lists/*

# Version exacte de Flutter, celle avec laquelle l'application est compilée et
# testée. Une image « stable » d'un registre tiers peut être plus ancienne que
# ce qu'exige pubspec.yaml ; l'archive officielle, elle, est figée.
ARG FLUTTER_VERSION=3.47.9
RUN curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
      | tar -xJ -C /opt \
 && git config --global --add safe.directory /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}"
RUN flutter config --no-analytics && flutter precache --web

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
