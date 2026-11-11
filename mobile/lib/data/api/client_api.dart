import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/connexion/application/session_controller.dart';

/// Adresse de l'API.
///
/// Version web : la page est servie par le serveur de l'officine, qui relaie
/// `/api/` vers l'API (docker/ : service `web`) — même origine, rien à régler.
/// Android : l'adresse se fixe à la compilation,
/// `flutter build apk --dart-define=API_URL=http://<serveur>:8000/api/v1`.
String adresseApi() {
  const fixee = String.fromEnvironment('API_URL');
  if (fixee.isNotEmpty) return fixee;
  if (kIsWeb) return '${Uri.base.origin}/api/v1';
  return 'http://192.168.100.33:8000/api/v1';
}

/// Client HTTP sans jeton, pour la connexion elle-même.
final dioPublicProvider = Provider<Dio>(
  (ref) => Dio(
    BaseOptions(
      baseUrl: adresseApi(),
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 20),
    ),
  ),
);

/// Client HTTP des appels authentifiés : ajoute le jeton de la session et,
/// si l'API répond 401 (jeton expiré ou révoqué), ferme la session — le
/// routeur ramène alors à l'écran de connexion.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: adresseApi(),
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final jeton = ref.read(sessionProvider)?.jeton;
        if (jeton != null) options.headers['Authorization'] = 'Bearer $jeton';
        handler.next(options);
      },
      onError: (erreur, handler) {
        if (erreur.response?.statusCode == 401 && ref.read(sessionProvider) != null) {
          ref.read(sessionProvider.notifier).fermer();
        }
        handler.next(erreur);
      },
    ),
  );
  return dio;
});

/// Erreur d'un appel à l'API, avec un message pour l'utilisateur.
class ErreurApi implements Exception {
  const ErreurApi(this.message, {this.reseau = false});

  /// Construit l'erreur d'un échec Dio.
  factory ErreurApi.depuis(Object erreur) {
    if (erreur is ErreurApi) return erreur;
    if (erreur is DioException) {
      final code = erreur.response?.statusCode;
      if (code == 401) return const ErreurApi('Votre session a expiré. Reconnectez-vous.');
      if (code == 404) return const ErreurApi('Élément introuvable.');
      if (code != null && code >= 500) {
        return const ErreurApi('Le serveur a rencontré une erreur. Réessayez dans un instant.');
      }
      if (code == null) {
        return const ErreurApi(
          "Le serveur de l'officine ne répond pas. Vérifiez la connexion au réseau.",
          reseau: true,
        );
      }
    }
    return const ErreurApi('Une erreur inattendue est survenue.');
  }

  final String message;
  final bool reseau;

  @override
  String toString() => message;
}
