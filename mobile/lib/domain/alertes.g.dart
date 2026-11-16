// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alertes.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ActionAlerte _$ActionAlerteFromJson(Map<String, dynamic> json) => _ActionAlerte(
  sorte:
      $enumDecodeNullable(_$SorteActionEnumMap, json['sorte'], unknownValue: SorteAction.aucune) ?? SorteAction.aucune,
  libelle: json['libelle'] as String? ?? '',
  route: json['route'] as String?,
);

Map<String, dynamic> _$ActionAlerteToJson(_ActionAlerte instance) => <String, dynamic>{
  'sorte': _$SorteActionEnumMap[instance.sorte]!,
  'libelle': instance.libelle,
  'route': instance.route,
};

const _$SorteActionEnumMap = {
  SorteAction.commander: 'commander',
  SorteAction.ouvrir: 'ouvrir',
  SorteAction.tension: 'tension',
  SorteAction.aucune: 'aucune',
};

_Alerte _$AlerteFromJson(Map<String, dynamic> json) => _Alerte(
  id: json['id'] as String,
  type: $enumDecodeNullable(_$TypeAlerteEnumMap, json['type']) ?? TypeAlerte.stock,
  niveau: $enumDecodeNullable(_$NiveauAlerteEnumMap, json['niveau']) ?? NiveauAlerte.surveiller,
  icone: json['icone'] as String? ?? '',
  sujet: json['sujet'] as String?,
  titre: json['titre'] as String? ?? '',
  detail: json['detail'] as String? ?? '',
  idNom: (json['id_nom'] as num?)?.toInt(),
  action: json['action'] == null ? const ActionAlerte() : ActionAlerte.fromJson(json['action'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AlerteToJson(_Alerte instance) => <String, dynamic>{
  'id': instance.id,
  'type': _$TypeAlerteEnumMap[instance.type]!,
  'niveau': _$NiveauAlerteEnumMap[instance.niveau]!,
  'icone': instance.icone,
  'sujet': instance.sujet,
  'titre': instance.titre,
  'detail': instance.detail,
  'id_nom': instance.idNom,
  'action': instance.action,
};

const _$TypeAlerteEnumMap = {
  TypeAlerte.stock: 'stock',
  TypeAlerte.peremption: 'peremption',
  TypeAlerte.livraison: 'livraison',
  TypeAlerte.confirmer: 'confirmer',
};

const _$NiveauAlerteEnumMap = {
  NiveauAlerte.aujourdhui: 'aujourdhui',
  NiveauAlerte.semaine: 'semaine',
  NiveauAlerte.surveiller: 'surveiller',
};

_BrefAlertes _$BrefAlertesFromJson(Map<String, dynamic> json) => _BrefAlertes(
  ruptures: (json['ruptures'] as num?)?.toInt() ?? 0,
  rupturesImminentes: (json['ruptures_imminentes'] as num?)?.toInt() ?? 0,
  valeurARisque: (json['valeur_a_risque'] as num?)?.toDouble() ?? 0,
  commandesNonLivrees: (json['commandes_non_livrees'] as num?)?.toInt() ?? 0,
  budgetPct: (json['budget_pct'] as num?)?.toInt(),
);

Map<String, dynamic> _$BrefAlertesToJson(_BrefAlertes instance) => <String, dynamic>{
  'ruptures': instance.ruptures,
  'ruptures_imminentes': instance.rupturesImminentes,
  'valeur_a_risque': instance.valeurARisque,
  'commandes_non_livrees': instance.commandesNonLivrees,
  'budget_pct': instance.budgetPct,
};

_ListeAlertes _$ListeAlertesFromJson(Map<String, dynamic> json) => _ListeAlertes(
  jour: DateTime.parse(json['jour'] as String),
  donneesDu: json['donnees_du'] == null ? null : DateTime.parse(json['donnees_du'] as String),
  peutDecider: json['peut_decider'] as bool? ?? false,
  alertes:
      (json['alertes'] as List<dynamic>?)?.map((e) => Alerte.fromJson(e as Map<String, dynamic>)).toList() ??
      const <Alerte>[],
  bref: json['bref'] == null ? const BrefAlertes() : BrefAlertes.fromJson(json['bref'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ListeAlertesToJson(_ListeAlertes instance) => <String, dynamic>{
  'jour': instance.jour.toIso8601String(),
  'donnees_du': instance.donneesDu?.toIso8601String(),
  'peut_decider': instance.peutDecider,
  'alertes': instance.alertes,
  'bref': instance.bref,
};
