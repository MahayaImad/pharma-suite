// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendrier.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Garde _$GardeFromJson(Map<String, dynamic> json) => _Garde(
  date: DateTime.parse(json['date'] as String),
  type: $enumDecode(_$TypeGardeEnumMap, json['type']),
  source: json['source'] as String? ?? 'saisie',
  confirme: json['confirme'] as bool? ?? true,
  note: json['note'] as String?,
  modifiePar: json['modifie_par'] as String?,
);

Map<String, dynamic> _$GardeToJson(_Garde instance) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'type': _$TypeGardeEnumMap[instance.type]!,
  'source': instance.source,
  'confirme': instance.confirme,
  'note': instance.note,
  'modifie_par': instance.modifiePar,
};

const _$TypeGardeEnumMap = {
  TypeGarde.soiree: 'soiree',
  TypeGarde.h24: '24h',
  TypeGarde.jour: 'jour',
};

_Evenement _$EvenementFromJson(Map<String, dynamic> json) => _Evenement(
  id: (json['id'] as num).toInt(),
  type: $enumDecode(_$TypeEvenementEnumMap, json['type']),
  debut: DateTime.parse(json['date_debut'] as String),
  fin: DateTime.parse(json['date_fin'] as String),
  aVerifier: json['a_verifier'] as bool? ?? false,
);

Map<String, dynamic> _$EvenementToJson(_Evenement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$TypeEvenementEnumMap[instance.type]!,
      'date_debut': instance.debut.toIso8601String(),
      'date_fin': instance.fin.toIso8601String(),
      'a_verifier': instance.aVerifier,
    };

const _$TypeEvenementEnumMap = {
  TypeEvenement.ramadan: 'ramadan',
  TypeEvenement.aidFitr: 'aid_fitr',
  TypeEvenement.aidAdha: 'aid_adha',
};

_Ferie _$FerieFromJson(Map<String, dynamic> json) => _Ferie(
  id: (json['id'] as num).toInt(),
  date: DateTime.parse(json['date'] as String),
  label: json['label'] as String?,
);

Map<String, dynamic> _$FerieToJson(_Ferie instance) => <String, dynamic>{
  'id': instance.id,
  'date': instance.date.toIso8601String(),
  'label': instance.label,
};

_Reglage _$ReglageFromJson(Map<String, dynamic> json) => _Reglage(
  cle: json['cle'] as String,
  valeur: (json['valeur'] as num).toDouble(),
  description: json['description'] as String?,
  modifiePar: json['modifie_par'] as String?,
);

Map<String, dynamic> _$ReglageToJson(_Reglage instance) => <String, dynamic>{
  'cle': instance.cle,
  'valeur': instance.valeur,
  'description': instance.description,
  'modifie_par': instance.modifiePar,
};
