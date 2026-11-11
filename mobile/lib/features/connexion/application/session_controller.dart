import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/api/auth_api.dart';
import '../../../domain/session.dart';
import '../../preferences/application/theme_controller.dart';

const cleSession = 'session';

/// La session courante : `null` quand personne n'est connecté.
///
/// Conservée sur l'appareil pour ne pas redemander le mot de passe à chaque
/// ouverture. Le jeton de l'API expire (60 min par défaut) : un appel refusé
/// ramène alors à l'écran de connexion (voir [SessionController.fermer]).
class SessionController extends Notifier<Session?> {
  @override
  Session? build() {
    final brut = ref.watch(preferencesLocalesProvider).getString(cleSession);
    if (brut == null) return null;
    try {
      return Session.fromJson(jsonDecode(brut) as Map<String, dynamic>);
    } catch (_) {
      return null; // format ancien ou abîmé : on redemande la connexion
    }
  }

  /// Ouvre une session ; lève [ErreurConnexion].
  Future<void> ouvrir(String utilisateur, String motDePasse) async {
    final api = ref.read(authApiProvider);
    final jeton = await api.connecter(utilisateur.trim(), motDePasse);
    final profil = await api.moi(jeton.jeton);
    final session = Session(jeton: jeton.jeton, profil: profil);
    await ref.read(preferencesLocalesProvider).setString(cleSession, jsonEncode(session.toJson()));
    state = session;
  }

  Future<void> fermer() async {
    await ref.read(preferencesLocalesProvider).remove(cleSession);
    state = null;
  }
}

final sessionProvider = NotifierProvider<SessionController, Session?>(SessionController.new);
