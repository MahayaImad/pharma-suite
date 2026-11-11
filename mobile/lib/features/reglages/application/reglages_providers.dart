import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/api/calendrier_api.dart';
import '../../../domain/calendrier.dart';
import '../../connexion/application/session_controller.dart';

Duration? _sansNouvelEssai(int essais, Object erreur) => null;

final gardesProvider = FutureProvider<List<Garde>>(
  (ref) => ref.watch(calendrierApiProvider).gardes(),
  retry: _sansNouvelEssai,
);

final evenementsProvider = FutureProvider<List<Evenement>>(
  (ref) => ref.watch(calendrierApiProvider).evenements(),
  retry: _sansNouvelEssai,
);

final feriesProvider = FutureProvider<List<Ferie>>(
  (ref) => ref.watch(calendrierApiProvider).feries(),
  retry: _sansNouvelEssai,
);

final reglagesProvider = FutureProvider<List<Reglage>>(
  (ref) => ref.watch(calendrierApiProvider).reglages(),
  retry: _sansNouvelEssai,
);

/// Seul le titulaire (administrateur) modifie le calendrier et les réglages.
final peutModifierProvider = Provider<bool>((ref) => ref.watch(sessionProvider)?.profil.role == 'admin');
