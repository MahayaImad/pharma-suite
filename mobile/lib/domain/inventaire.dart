// Inventaire tournant : liste du jour, comptages, écarts — Dart pur.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'format.dart';

part 'inventaire.freezed.dart';
part 'inventaire.g.dart';

/// Cause d'un écart, si on la connaît.
enum CauseEcart {
  @JsonValue('casse')
  casse('Casse'),
  @JsonValue('perime')
  perime('Périmé'),
  @JsonValue('saisie')
  saisie('Erreur de saisie'),
  @JsonValue('vol')
  vol('Vol'),
  @JsonValue('inconnu')
  inconnu('Inconnue');

  const CauseEcart(this.libelle);
  final String libelle;

  String get api => switch (this) {
    casse => 'casse',
    perime => 'perime',
    saisie => 'saisie',
    vol => 'vol',
    inconnu => 'inconnu',
  };
}

/// Un produit de la liste du jour, pas encore compté.
@freezed
abstract class ProduitACompter with _$ProduitACompter {
  const ProduitACompter._();

  const factory ProduitACompter({
    @JsonKey(name: 'id_nom') required int idNom,
    String? nom,
    String? classe,
    @Default('') String raison,
    @JsonKey(name: 'stock_theorique') @Default(0) int stockTheorique,
    @JsonKey(name: 'dernier_comptage') DateTime? dernierComptage,
  }) = _ProduitACompter;

  factory ProduitACompter.fromJson(Map<String, dynamic> json) => _$ProduitACompterFromJson(json);

  String get nomLisible => libelleProduit(nom ?? 'Produit $idNom');
}

/// Un comptage enregistré.
@freezed
abstract class Comptage with _$Comptage {
  const Comptage._();

  const factory Comptage({
    required int id,
    @JsonKey(name: 'id_nom') required int idNom,
    String? nom,
    String? classe,
    @JsonKey(name: 'stock_theorique') @Default(0) int stockTheorique,
    @JsonKey(name: 'stock_compte') @Default(0) int stockCompte,
    @Default(0) int ecart,
    @JsonKey(name: 'valeur_ecart') @Default(0) double valeurEcart,
    @JsonKey(unknownEnumValue: CauseEcart.inconnu) CauseEcart? cause,
    @JsonKey(name: 'compte_par') String? comptePar,
    @JsonKey(name: 'compte_le') DateTime? compteLe,
    required DateTime jour,
    @Default(false) bool corrige,
    @JsonKey(name: 'dans_la_liste') @Default(true) bool dansLaListe,
  }) = _Comptage;

  factory Comptage.fromJson(Map<String, dynamic> json) => _$ComptageFromJson(json);

  String get nomLisible => libelleProduit(nom ?? 'Produit $idNom');

  /// « Écart −3 », « Écart +2 », « Juste ».
  String get libelleEcart => ecart == 0 ? 'Juste' : 'Écart ${ecart > 0 ? '+' : '−'}${ecart.abs()}';
}

@freezed
abstract class Progression with _$Progression {
  const factory Progression({@Default(0) int total, @Default(0) int comptes, @Default(0) int ecarts}) = _Progression;

  factory Progression.fromJson(Map<String, dynamic> json) => _$ProgressionFromJson(json);
}

@freezed
abstract class Exactitude with _$Exactitude {
  const factory Exactitude({
    @JsonKey(name: 'comptes_mois') @Default(0) int comptesMois,
    @JsonKey(name: 'exactitude_pct') int? exactitudePct,
    @JsonKey(name: 'classe_a_pct') int? classeAPct,
    @JsonKey(name: 'a_corriger') @Default(0) int aCorriger,
  }) = _Exactitude;

  factory Exactitude.fromJson(Map<String, dynamic> json) => _$ExactitudeFromJson(json);
}

/// Journée d'inventaire (`GET /inventaire/jour`).
@freezed
abstract class JourneeInventaire with _$JourneeInventaire {
  const factory JourneeInventaire({
    required DateTime jour,
    @JsonKey(name: 'a_compter') @Default(<ProduitACompter>[]) List<ProduitACompter> aCompter,
    @Default(<Comptage>[]) List<Comptage> comptes,
    @Default(Progression()) Progression progression,
    @Default(Exactitude()) Exactitude exactitude,
    @JsonKey(name: 'a_corriger') @Default(<Comptage>[]) List<Comptage> aCorriger,
  }) = _JourneeInventaire;

  factory JourneeInventaire.fromJson(Map<String, dynamic> json) => _$JourneeInventaireFromJson(json);
}
