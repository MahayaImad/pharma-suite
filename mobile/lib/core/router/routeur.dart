import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/connexion/presentation/ecran_connexion.dart';

import '../../features/preferences/presentation/ecran_preferences.dart';
import '../widgets/coquille.dart';
import '../widgets/ecran_a_venir.dart';

const _descriptions = <String, String>{
  '/accueil': "La vue d'ensemble de l'officine.",
  '/stock': 'Recherche de produits, lots et valeur du stock.',
  '/alertes': 'Ruptures, seuils et péremptions à traiter.',
  '/inventaire': "L'inventaire tournant et ses écarts.",
  '/commandes': 'Les propositions de commande.',
};

/// [connecte] dit si une session est ouverte ; [rafraichir] prévient le
/// routeur quand elle change, pour qu'il réapplique la redirection.
GoRouter construireRouteur({
  String depart = '/stock',
  bool Function()? connecte,
  Listenable? rafraichir,
}) =>
    GoRouter(
      initialLocation: depart,
      refreshListenable: rafraichir,
      redirect: (context, etat) {
        final ouvert = connecte?.call() ?? true;
        final surConnexion = etat.matchedLocation == '/connexion';
        if (!ouvert && !surConnexion) return '/connexion';
        if (ouvert && surConnexion) return '/stock';
        return null;
      },
      routes: [
        GoRoute(
          path: '/connexion',
          pageBuilder: (context, etat) => const NoTransitionPage(child: EcranConnexion()),
        ),
        ShellRoute(
          builder: (context, etat, child) =>
              Coquille(emplacement: etat.matchedLocation, child: child),
          routes: [
            for (final d in destinations)
              GoRoute(
                path: d.chemin,
                pageBuilder: (context, etat) => NoTransitionPage(
                  child: EcranAVenir(
                      titre: d.libelle, icone: d.icone, description: _descriptions[d.chemin]!),
                ),
              ),
          ],
        ),
        // Hors du cadre commun : sur portable l'écran s'empile par-dessus la
        // barre du bas (plein écran, avec retour) ; sur PC la coquille lui
        // rend le menu latéral.
        GoRoute(
          path: '/preferences',
          pageBuilder: (context, etat) => const NoTransitionPage(
            child: Coquille(emplacement: '/preferences', child: EcranPreferences()),
          ),
        ),
      ],
    );
