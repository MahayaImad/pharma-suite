import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/themes.dart';
import '../../../core/widgets/coquille.dart';
import '../../connexion/application/session_controller.dart';
import '../../reglages/presentation/ecran_consommables.dart';
import '../../reglages/presentation/ecran_reglages.dart';
import '../application/theme_controller.dart';

/// Préférences : le thème, le calendrier et les réglages, les consommables,
/// la déconnexion.
class EcranPreferences extends ConsumerWidget {
  const EcranPreferences({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choisi = ref.watch(themeProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Préférences'),
        // Sur portable l'écran est en plein écran : il lui faut un retour,
        // même s'il a été ouvert directement par son adresse.
        automaticallyImplyLeading: false,
        leading: MediaQuery.sizeOf(context).width >= largeurPc
            ? null
            : IconButton(
                tooltip: 'Retour',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.canPop() ? context.pop() : context.go('/stock'),
              ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thème',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Le choix est enregistré sur cet appareil.',
                    style: TextStyle(color: context.couleurs.encre2),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final t in ThemeId.values)
                        _CarteTheme(
                          theme: t,
                          choisi: t == choisi,
                          surAppui: () => ref.read(themeProvider.notifier).choisir(t),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Réglages',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  const EntreeReglages(),
                  const SizedBox(height: 10),
                  const EntreeConsommables(),
                  const SizedBox(height: 28),
                  // Seul accès à la déconnexion sur portable (le menu latéral est sur PC).
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const ValueKey('bouton-deconnexion'),
                      onPressed: () => ref.read(sessionProvider.notifier).fermer(),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Se déconnecter'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vignette d'un thème, dessinée avec ses propres couleurs.
class _CarteTheme extends StatelessWidget {
  const _CarteTheme({required this.theme, required this.choisi, required this.surAppui});

  final ThemeId theme;
  final bool choisi;
  final VoidCallback surAppui;

  @override
  Widget build(BuildContext context) {
    final donnees = construireTheme(theme);
    final schema = donnees.colorScheme;
    final couleurs = donnees.extension<CouleursApp>()!;
    final contour = choisi ? context.schema.primary : context.couleurs.bord;

    return Semantics(
      button: true,
      selected: choisi,
      label: 'Thème ${theme.libelle}',
      child: InkWell(
        key: ValueKey('theme-${theme.name}'),
        borderRadius: BorderRadius.circular(14),
        onTap: surAppui,
        child: Container(
          width: 164,
          decoration: BoxDecoration(
            color: context.schema.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: contour, width: choisi ? 2 : 1),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 76,
                decoration: BoxDecoration(
                  color: donnees.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: couleurs.bord),
                ),
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: couleurs.tuilePrincipale,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: schema.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: couleurs.bord),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: schema.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      theme.libelle,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    choisi ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    size: 20,
                    color: choisi ? context.schema.primary : context.couleurs.encre3,
                  ),
                ],
              ),
              if (theme == ThemeId.defaut)
                Text('Par défaut', style: TextStyle(fontSize: 12, color: context.couleurs.encre3))
              else
                const SizedBox(height: 17),
            ],
          ),
        ),
      ),
    );
  }
}
