import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/connexion/application/session_controller.dart';
import 'logo.dart';

import '../theme/themes.dart';

/// Une entrée de la navigation principale.
class Destination {
  const Destination(this.chemin, this.libelle, this.icone, this.iconeActive);
  final String chemin, libelle;
  final IconData icone, iconeActive;
}

const destinations = <Destination>[
  Destination('/accueil', 'Accueil', Icons.home_outlined, Icons.home),
  Destination('/stock', 'Stock', Icons.inventory_2_outlined, Icons.inventory_2),
  Destination('/alertes', 'Alertes', Icons.warning_amber_outlined, Icons.warning_amber),
  Destination('/inventaire', 'Inventaire', Icons.checklist_outlined, Icons.checklist),
  Destination('/commandes', 'Commandes', Icons.shopping_cart_outlined, Icons.shopping_cart),
];

/// Largeur à partir de laquelle le menu passe du bas de l'écran au côté.
const largeurPc = 760.0;

/// Cadre commun à tous les écrans : menu latéral sur PC, barre du bas sur
/// portable. L'application est pensée d'abord pour 390 px de large.
class Coquille extends StatelessWidget {
  const Coquille({super.key, required this.emplacement, required this.child});

  final String emplacement;
  final Widget child;

  int get _index {
    final i = destinations.indexWhere((d) => emplacement.startsWith(d.chemin));
    return i < 0 ? 0 : i;
  }

  bool get _dansPreferences => emplacement.startsWith('/preferences');

  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.sizeOf(context).width >= largeurPc;
    void aller(int i) => context.go(destinations[i].chemin);

    if (large) {
      return Scaffold(
        body: Row(
          children: [
            _MenuLateral(
              index: _dansPreferences ? null : _index,
              surChoix: aller,
              preferencesActives: _dansPreferences,
            ),
            const VerticalDivider(),
            Expanded(child: child),
          ],
        ),
      );
    }
    // Sur portable, les préférences s'ouvrent en plein écran, avec un retour :
    // elles ne sont pas une section de la barre du bas.
    if (_dansPreferences) return child;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: aller,
        height: 68,
        destinations: [
          for (final d in destinations)
            NavigationDestination(icon: Icon(d.icone), selectedIcon: Icon(d.iconeActive), label: d.libelle),
        ],
      ),
    );
  }
}

class _MenuLateral extends StatelessWidget {
  const _MenuLateral({required this.index, required this.surChoix, required this.preferencesActives});

  final int? index;
  final ValueChanged<int> surChoix;
  final bool preferencesActives;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      color: context.schema.surface,
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 20),
            child: Row(
              children: [
                const LogoPharmaSuite(taille: 34),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'PharmaSuite',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Sora',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final (i, d) in destinations.indexed)
            _Lien(
              libelle: d.libelle,
              icone: i == index ? d.iconeActive : d.icone,
              actif: i == index,
              surAppui: () => surChoix(i),
            ),
          const Spacer(),
          const Divider(),
          const SizedBox(height: 8),
          _Lien(
            libelle: 'Préférences',
            icone: preferencesActives ? Icons.settings : Icons.settings_outlined,
            actif: preferencesActives,
            surAppui: () => context.go('/preferences'),
          ),
          const SizedBox(height: 6),
          const _Utilisateur(),
        ],
      ),
    );
  }
}

class _Lien extends StatelessWidget {
  const _Lien({required this.libelle, required this.icone, required this.actif, required this.surAppui});

  final String libelle;
  final IconData icone;
  final bool actif;
  final VoidCallback surAppui;

  @override
  Widget build(BuildContext context) {
    final couleur = actif ? context.schema.onPrimaryContainer : context.couleurs.encre2;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: actif ? context.schema.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: surAppui,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icone, size: 21, color: couleur),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    libelle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: couleur,
                      fontSize: 15,
                      fontWeight: actif ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Accès aux préférences depuis la barre de titre, sur portable seulement :
/// sur PC elles sont dans le menu latéral.
class BoutonPreferences extends StatelessWidget {
  const BoutonPreferences({super.key});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= largeurPc) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'Préférences',
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => context.push('/preferences'),
    );
  }
}

/// Qui est connecté, et le bouton pour se déconnecter (menu latéral).
class _Utilisateur extends ConsumerWidget {
  const _Utilisateur();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(sessionProvider)?.profil;
    if (profil == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 0, 0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: context.schema.primaryContainer,
            child: Text(
              profil.initiales,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.schema.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profil.nomAffiche,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  profil.role == 'admin' ? 'Administrateur' : 'Équipe',
                  style: TextStyle(fontSize: 12, color: context.couleurs.encre3),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Se déconnecter',
            icon: Icon(Icons.logout, size: 20, color: context.couleurs.encre2),
            onPressed: () => ref.read(sessionProvider.notifier).fermer(),
          ),
        ],
      ),
    );
  }
}
