// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventaire.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProduitACompter _$ProduitACompterFromJson(Map<String, dynamic> json) => _ProduitACompter(
  idNom: (json['id_nom'] as num).toInt(),
  nom: json['nom'] as String?,
  classe: json['classe'] as String?,
  raison: json['raison'] as String? ?? '',
  stockTheorique: (json['stock_theorique'] as num?)?.toInt() ?? 0,
  dernierComptage: json['dernier_comptage'] == null ? null : DateTime.parse(json['dernier_comptage'] as String),
);

Map<String, dynamic> _$ProduitACompterToJson(_ProduitACompter instance) => <String, dynamic>{
  'id_nom': instance.idNom,
  'nom': instance.nom,
  'classe': instance.classe,
  'raison': instance.raison,
  'stock_theorique': instance.stockTheorique,
  'dernier_comptage': instance.dernierComptage?.toIso8601String(),
};

_Comptage _$ComptageFromJson(Map<String, dynamic> json) => _Comptage(
  id: (json['id'] as num).toInt(),
  idNom: (json['id_nom'] as num).toInt(),
  nom: json['nom'] as String?,
  classe: json['classe'] as String?,
  stockTheorique: (json['stock_theorique'] as num?)?.toInt() ?? 0,
  stockCompte: (json['stock_compte'] as num?)?.toInt() ?? 0,
  ecart: (json['ecart'] as num?)?.toInt() ?? 0,
  valeurEcart: (json['valeur_ecart'] as num?)?.toDouble() ?? 0,
  cause: $enumDecodeNullable(_$CauseEcartEnumMap, json['cause'], unknownValue: CauseEcart.inconnu),
  comptePar: json['compte_par'] as String?,
  compteLe: json['compte_le'] == null ? null : DateTime.parse(json['compte_le'] as String),
  jour: DateTime.parse(json['jour'] as String),
  corrige: json['corrige'] as bool? ?? false,
  dansLaListe: json['dans_la_liste'] as bool? ?? true,
);

Map<String, dynamic> _$ComptageToJson(_Comptage instance) => <String, dynamic>{
  'id': instance.id,
  'id_nom': instance.idNom,
  'nom': instance.nom,
  'classe': instance.classe,
  'stock_theorique': instance.stockTheorique,
  'stock_compte': instance.stockCompte,
  'ecart': instance.ecart,
  'valeur_ecart': instance.valeurEcart,
  'cause': _$CauseEcartEnumMap[instance.cause],
  'compte_par': instance.comptePar,
  'compte_le': instance.compteLe?.toIso8601String(),
  'jour': instance.jour.toIso8601String(),
  'corrige': instance.corrige,
  'dans_la_liste': instance.dansLaListe,
};

const _$CauseEcartEnumMap = {
  CauseEcart.casse: 'casse',
  CauseEcart.perime: 'perime',
  CauseEcart.saisie: 'saisie',
  CauseEcart.vol: 'vol',
  CauseEcart.inconnu: 'inconnu',
};

_Progression _$ProgressionFromJson(Map<String, dynamic> json) => _Progression(
  total: (json['total'] as num?)?.toInt() ?? 0,
  comptes: (json['comptes'] as num?)?.toInt() ?? 0,
  ecarts: (json['ecarts'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ProgressionToJson(_Progression instance) => <String, dynamic>{
  'total': instance.total,
  'comptes': instance.comptes,
  'ecarts': instance.ecarts,
};

_Exactitude _$ExactitudeFromJson(Map<String, dynamic> json) => _Exactitude(
  comptesMois: (json['comptes_mois'] as num?)?.toInt() ?? 0,
  exactitudePct: (json['exactitude_pct'] as num?)?.toInt(),
  classeAPct: (json['classe_a_pct'] as num?)?.toInt(),
  aCorriger: (json['a_corriger'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ExactitudeToJson(_Exactitude instance) => <String, dynamic>{
  'comptes_mois': instance.comptesMois,
  'exactitude_pct': instance.exactitudePct,
  'classe_a_pct': instance.classeAPct,
  'a_corriger': instance.aCorriger,
};

_JourneeInventaire _$JourneeInventaireFromJson(Map<String, dynamic> json) => _JourneeInventaire(
  jour: DateTime.parse(json['jour'] as String),
  aCompter:
      (json['a_compter'] as List<dynamic>?)?.map((e) => ProduitACompter.fromJson(e as Map<String, dynamic>)).toList() ??
      const <ProduitACompter>[],
  comptes:
      (json['comptes'] as List<dynamic>?)?.map((e) => Comptage.fromJson(e as Map<String, dynamic>)).toList() ??
      const <Comptage>[],
  progression: json['progression'] == null
      ? const Progression()
      : Progression.fromJson(json['progression'] as Map<String, dynamic>),
  exactitude: json['exactitude'] == null
      ? const Exactitude()
      : Exactitude.fromJson(json['exactitude'] as Map<String, dynamic>),
  aCorriger:
      (json['a_corriger'] as List<dynamic>?)?.map((e) => Comptage.fromJson(e as Map<String, dynamic>)).toList() ??
      const <Comptage>[],
);

Map<String, dynamic> _$JourneeInventaireToJson(_JourneeInventaire instance) => <String, dynamic>{
  'jour': instance.jour.toIso8601String(),
  'a_compter': instance.aCompter,
  'comptes': instance.comptes,
  'progression': instance.progression,
  'exactitude': instance.exactitude,
  'a_corriger': instance.aCorriger,
};
