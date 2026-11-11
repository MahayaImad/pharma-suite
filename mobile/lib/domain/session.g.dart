// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReponseJeton _$ReponseJetonFromJson(Map<String, dynamic> json) =>
    _ReponseJeton(
      jeton: json['access_token'] as String,
      type: json['token_type'] as String? ?? 'bearer',
    );

Map<String, dynamic> _$ReponseJetonToJson(_ReponseJeton instance) =>
    <String, dynamic>{
      'access_token': instance.jeton,
      'token_type': instance.type,
    };

_Profil _$ProfilFromJson(Map<String, dynamic> json) => _Profil(
  utilisateur: json['username'] as String,
  role: json['role'] as String? ?? 'employee',
  nom: json['nom'] as String?,
  prenom: json['prenom'] as String?,
);

Map<String, dynamic> _$ProfilToJson(_Profil instance) => <String, dynamic>{
  'username': instance.utilisateur,
  'role': instance.role,
  'nom': instance.nom,
  'prenom': instance.prenom,
};

_Session _$SessionFromJson(Map<String, dynamic> json) => _Session(
  jeton: json['jeton'] as String,
  profil: Profil.fromJson(json['profil'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SessionToJson(_Session instance) => <String, dynamic>{
  'jeton': instance.jeton,
  'profil': instance.profil,
};
