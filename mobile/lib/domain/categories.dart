// Catégories de prime (princeps, générique, générique++) — Dart pur.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'categories.freezed.dart';
part 'categories.g.dart';

/// Codes des catégories, dans l'ordre d'affichage.
const categoriesPrime = ['princeps', 'generique', 'generique++'];

/// « Princeps », « Générique », « Générique++ », « Sans catégorie ».
String libelleCategorie(String? code) => switch (code) {
  'princeps' => 'Princeps',
  'generique' => 'Générique',
  'generique++' => 'Générique++',
  _ => 'Sans catégorie',
};

/// Une catégorie dans l'enveloppe du mois (null : sans catégorie, au taux princeps).
@freezed
abstract class CategorieMois with _$CategorieMois {
  const factory CategorieMois({
    String? categorie,
    @JsonKey(name: 'taux_pct') @Default(0) double tauxPct,
    @Default(0) double ca,
    @Default(0) int produits,
    @Default(0) double montant,
  }) = _CategorieMois;

  factory CategorieMois.fromJson(Map<String, dynamic> json) => _$CategorieMoisFromJson(json);
}

@freezed
abstract class DernierClassement with _$DernierClassement {
  const factory DernierClassement({
    required DateTime le,
    String? par,
    @JsonKey(name: 'seuil_marge') @Default(50) double seuilMarge,
    @JsonKey(name: 'tout_reclasser') @Default(false) bool toutReclasser,
    @Default(0) int produits,
  }) = _DernierClassement;

  factory DernierClassement.fromJson(Map<String, dynamic> json) => _$DernierClassementFromJson(json);
}

@freezed
abstract class PrimeCategories with _$PrimeCategories {
  const PrimeCategories._();

  const factory PrimeCategories({
    required int annee,
    required int mois,
    @Default(0) double enveloppe,
    @Default(0) double ca,
    @Default([]) List<CategorieMois> categories,
    @JsonKey(name: 'seuil_marge') @Default(50) double seuilMarge,
    @JsonKey(name: 'sans_categorie_total') @Default(0) int sansCategorieTotal,
    @JsonKey(name: 'dernier_classement') DernierClassement? dernierClassement,
  }) = _PrimeCategories;

  factory PrimeCategories.fromJson(Map<String, dynamic> json) => _$PrimeCategoriesFromJson(json);

  CategorieMois categorie(String? code) =>
      categories.firstWhere((c) => c.categorie == code, orElse: () => CategorieMois(categorie: code));

  /// Taux d'une catégorie, en %.
  double taux(String code) => categorie(code).tauxPct;
}

@freezed
abstract class LaboratoirePrime with _$LaboratoirePrime {
  const factory LaboratoirePrime({
    required int id,
    @Default('') String labo,
    @JsonKey(name: 'is_generique') @Default(false) bool generique,
    @Default(0) double ca,
    @Default(0) int produits,
    @JsonKey(name: 'part_ca') @Default(0) double partCa,
  }) = _LaboratoirePrime;

  factory LaboratoirePrime.fromJson(Map<String, dynamic> json) => _$LaboratoirePrimeFromJson(json);
}

@freezed
abstract class PageLaboratoires with _$PageLaboratoires {
  const factory PageLaboratoires({@Default([]) List<LaboratoirePrime> laboratoires, @Default(0) int total}) =
      _PageLaboratoires;

  factory PageLaboratoires.fromJson(Map<String, dynamic> json) => _$PageLaboratoiresFromJson(json);
}

/// Produit vendu dans le mois sans catégorie, ou classé à la main.
@freezed
abstract class ProduitCategorie with _$ProduitCategorie {
  const factory ProduitCategorie({
    required int id,
    String? nom,
    String? labo,
    String? categorie,
    @Default(false) bool manuelle,
    @Default(0) double ca,
  }) = _ProduitCategorie;

  factory ProduitCategorie.fromJson(Map<String, dynamic> json) => _$ProduitCategorieFromJson(json);
}

@freezed
abstract class ResultatClassement with _$ResultatClassement {
  const factory ResultatClassement({
    @Default(0) int princeps,
    @Default(0) int generique,
    @JsonKey(name: 'generique++') @Default(0) int generiquePlus,
    @Default(0) int total,
  }) = _ResultatClassement;

  factory ResultatClassement.fromJson(Map<String, dynamic> json) => _$ResultatClassementFromJson(json);
}
