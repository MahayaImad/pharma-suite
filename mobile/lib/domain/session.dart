// Modèles de la session. Logique pure : n'importe jamais package:flutter.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'session.freezed.dart';
part 'session.g.dart';

/// Réponse de `POST /auth/login`.
@freezed
abstract class ReponseJeton with _$ReponseJeton {
  const factory ReponseJeton({
    @JsonKey(name: 'access_token') required String jeton,
    @JsonKey(name: 'token_type') @Default('bearer') String type,
  }) = _ReponseJeton;

  factory ReponseJeton.fromJson(Map<String, dynamic> json) => _$ReponseJetonFromJson(json);
}

/// Réponse de `GET /auth/me` : qui est connecté.
@freezed
abstract class Profil with _$Profil {
  const Profil._();

  const factory Profil({
    @JsonKey(name: 'username') required String utilisateur,
    @Default('employee') String role,
    String? nom,
    String? prenom,
  }) = _Profil;

  factory Profil.fromJson(Map<String, dynamic> json) => _$ProfilFromJson(json);

  /// Nom affiché : « Prénom Nom », à défaut l'identifiant.
  String get nomAffiche {
    final complet = [prenom, nom].where((p) => p != null && p.trim().isNotEmpty).join(' ');
    return complet.isEmpty ? utilisateur : complet;
  }

  /// Initiales pour l'avatar.
  String get initiales {
    final mots = nomAffiche.split(RegExp(r'\s+')).where((m) => m.isNotEmpty).toList();
    if (mots.isEmpty) return '?';
    if (mots.length == 1) return mots.first.substring(0, 1).toUpperCase();
    return (mots.first[0] + mots.last[0]).toUpperCase();
  }
}

/// Session ouverte : le jeton de l'API et le profil.
@freezed
abstract class Session with _$Session {
  const factory Session({required String jeton, required Profil profil}) = _Session;

  factory Session.fromJson(Map<String, dynamic> json) => _$SessionFromJson(json);
}

/// Pourquoi une connexion a échoué, sans détail technique.
enum EchecConnexion {
  identifiants('Utilisateur ou mot de passe incorrect.'),
  compteDesactive('Ce compte est désactivé. Voyez avec le titulaire.'),
  serveurInjoignable("Le serveur de l'officine ne répond pas. Vérifiez que le poste est sur le réseau de l'officine."),
  inattendu('La connexion a échoué. Réessayez dans un instant.');

  const EchecConnexion(this.message);
  final String message;
}

class ErreurConnexion implements Exception {
  const ErreurConnexion(this.echec);
  final EchecConnexion echec;

  @override
  String toString() => echec.message;
}
