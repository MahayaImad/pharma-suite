// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categories.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CategorieMois _$CategorieMoisFromJson(Map<String, dynamic> json) => _CategorieMois(
  categorie: json['categorie'] as String?,
  tauxPct: (json['taux_pct'] as num?)?.toDouble() ?? 0,
  ca: (json['ca'] as num?)?.toDouble() ?? 0,
  produits: (json['produits'] as num?)?.toInt() ?? 0,
  montant: (json['montant'] as num?)?.toDouble() ?? 0,
);

Map<String, dynamic> _$CategorieMoisToJson(_CategorieMois instance) => <String, dynamic>{
  'categorie': instance.categorie,
  'taux_pct': instance.tauxPct,
  'ca': instance.ca,
  'produits': instance.produits,
  'montant': instance.montant,
};

_DernierClassement _$DernierClassementFromJson(Map<String, dynamic> json) => _DernierClassement(
  le: DateTime.parse(json['le'] as String),
  par: json['par'] as String?,
  seuilMarge: (json['seuil_marge'] as num?)?.toDouble() ?? 50,
  toutReclasser: json['tout_reclasser'] as bool? ?? false,
  produits: (json['produits'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$DernierClassementToJson(_DernierClassement instance) => <String, dynamic>{
  'le': instance.le.toIso8601String(),
  'par': instance.par,
  'seuil_marge': instance.seuilMarge,
  'tout_reclasser': instance.toutReclasser,
  'produits': instance.produits,
};

_PrimeCategories _$PrimeCategoriesFromJson(Map<String, dynamic> json) => _PrimeCategories(
  annee: (json['annee'] as num).toInt(),
  mois: (json['mois'] as num).toInt(),
  enveloppe: (json['enveloppe'] as num?)?.toDouble() ?? 0,
  ca: (json['ca'] as num?)?.toDouble() ?? 0,
  categories:
      (json['categories'] as List<dynamic>?)?.map((e) => CategorieMois.fromJson(e as Map<String, dynamic>)).toList() ??
      const [],
  seuilMarge: (json['seuil_marge'] as num?)?.toDouble() ?? 50,
  sansCategorieTotal: (json['sans_categorie_total'] as num?)?.toInt() ?? 0,
  dernierClassement: json['dernier_classement'] == null
      ? null
      : DernierClassement.fromJson(json['dernier_classement'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PrimeCategoriesToJson(_PrimeCategories instance) => <String, dynamic>{
  'annee': instance.annee,
  'mois': instance.mois,
  'enveloppe': instance.enveloppe,
  'ca': instance.ca,
  'categories': instance.categories,
  'seuil_marge': instance.seuilMarge,
  'sans_categorie_total': instance.sansCategorieTotal,
  'dernier_classement': instance.dernierClassement,
};

_LaboratoirePrime _$LaboratoirePrimeFromJson(Map<String, dynamic> json) => _LaboratoirePrime(
  id: (json['id'] as num).toInt(),
  labo: json['labo'] as String? ?? '',
  generique: json['is_generique'] as bool? ?? false,
  ca: (json['ca'] as num?)?.toDouble() ?? 0,
  produits: (json['produits'] as num?)?.toInt() ?? 0,
  partCa: (json['part_ca'] as num?)?.toDouble() ?? 0,
);

Map<String, dynamic> _$LaboratoirePrimeToJson(_LaboratoirePrime instance) => <String, dynamic>{
  'id': instance.id,
  'labo': instance.labo,
  'is_generique': instance.generique,
  'ca': instance.ca,
  'produits': instance.produits,
  'part_ca': instance.partCa,
};

_PageLaboratoires _$PageLaboratoiresFromJson(Map<String, dynamic> json) => _PageLaboratoires(
  laboratoires:
      (json['laboratoires'] as List<dynamic>?)
          ?.map((e) => LaboratoirePrime.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  total: (json['total'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$PageLaboratoiresToJson(_PageLaboratoires instance) => <String, dynamic>{
  'laboratoires': instance.laboratoires,
  'total': instance.total,
};

_ProduitCategorie _$ProduitCategorieFromJson(Map<String, dynamic> json) => _ProduitCategorie(
  id: (json['id'] as num).toInt(),
  nom: json['nom'] as String?,
  labo: json['labo'] as String?,
  categorie: json['categorie'] as String?,
  manuelle: json['manuelle'] as bool? ?? false,
  ca: (json['ca'] as num?)?.toDouble() ?? 0,
);

Map<String, dynamic> _$ProduitCategorieToJson(_ProduitCategorie instance) => <String, dynamic>{
  'id': instance.id,
  'nom': instance.nom,
  'labo': instance.labo,
  'categorie': instance.categorie,
  'manuelle': instance.manuelle,
  'ca': instance.ca,
};

_ResultatClassement _$ResultatClassementFromJson(Map<String, dynamic> json) => _ResultatClassement(
  princeps: (json['princeps'] as num?)?.toInt() ?? 0,
  generique: (json['generique'] as num?)?.toInt() ?? 0,
  generiquePlus: (json['generique++'] as num?)?.toInt() ?? 0,
  total: (json['total'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ResultatClassementToJson(_ResultatClassement instance) => <String, dynamic>{
  'princeps': instance.princeps,
  'generique': instance.generique,
  'generique++': instance.generiquePlus,
  'total': instance.total,
};
