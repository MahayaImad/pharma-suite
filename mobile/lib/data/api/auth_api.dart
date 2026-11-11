import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/session.dart';
import 'client_api.dart';

/// Les deux appels d'authentification de l'API.
abstract interface class AuthApi {
  /// `POST /auth/login` ; lève [ErreurConnexion].
  Future<ReponseJeton> connecter(String utilisateur, String motDePasse);

  /// `GET /auth/me` ; lève [ErreurConnexion].
  Future<Profil> moi(String jeton);
}

class AuthApiDio implements AuthApi {
  AuthApiDio(this._dio);
  final Dio _dio;

  @override
  Future<ReponseJeton> connecter(String utilisateur, String motDePasse) async {
    try {
      // OAuth2PasswordRequestForm côté FastAPI : formulaire, pas JSON.
      final reponse = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'username': utilisateur, 'password': motDePasse},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      return ReponseJeton.fromJson(reponse.data!);
    } on DioException catch (e) {
      throw ErreurConnexion(_traduire(e));
    }
  }

  @override
  Future<Profil> moi(String jeton) async {
    try {
      final reponse = await _dio.get<Map<String, dynamic>>(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $jeton'}),
      );
      return Profil.fromJson(reponse.data!);
    } on DioException catch (e) {
      throw ErreurConnexion(_traduire(e));
    }
  }

  static EchecConnexion _traduire(DioException e) {
    switch (e.response?.statusCode) {
      case 401:
        return EchecConnexion.identifiants;
      case 403:
        return EchecConnexion.compteDesactive;
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.connectionError ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => EchecConnexion.serveurInjoignable,
      _ => EchecConnexion.inattendu,
    };
  }
}

final authApiProvider = Provider<AuthApi>((ref) => AuthApiDio(ref.watch(dioPublicProvider)));
