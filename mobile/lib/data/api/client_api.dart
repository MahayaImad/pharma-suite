import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
final dioPublicProvider = Provider<Dio>((ref) => Dio(BaseOptions(
      baseUrl: adresseApi(),
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 20),
    )));
