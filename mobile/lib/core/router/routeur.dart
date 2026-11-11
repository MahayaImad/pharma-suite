import 'package:go_router/go_router.dart';

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

GoRouter construireRouteur({String depart = '/stock'}) => GoRouter(
      initialLocation: depart,
      routes: [
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
