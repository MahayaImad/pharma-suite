// Calendrier de l'officine et réglages du calcul des commandes — Dart pur.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendrier.freezed.dart';
part 'calendrier.g.dart';

enum TypeGarde {
  @JsonValue('soiree')
  soiree('Soirée', 'jusqu\'à 23 h'),
  @JsonValue('24h')
  h24('24 h sur 24', 'jour et nuit'),
  @JsonValue('jour')
  jour('Jour de fermeture', 'ouverture exceptionnelle');

  const TypeGarde(this.libelle, this.detail);
  final String libelle, detail;

  String get api => switch (this) {
    TypeGarde.soiree => 'soiree',
    TypeGarde.h24 => '24h',
    TypeGarde.jour => 'jour',
  };
}

enum TypeEvenement {
  @JsonValue('ramadan')
  ramadan('Ramadan'),
  @JsonValue('aid_fitr')
  aidFitr('Aïd el-Fitr'),
  @JsonValue('aid_adha')
  aidAdha('Aïd el-Adha');

  const TypeEvenement(this.libelle);
  final String libelle;

  String get api => switch (this) {
    TypeEvenement.ramadan => 'ramadan',
    TypeEvenement.aidFitr => 'aid_fitr',
    TypeEvenement.aidAdha => 'aid_adha',
  };
}

@freezed
abstract class Garde with _$Garde {
  const Garde._();

  const factory Garde({
    required DateTime date,
    required TypeGarde type,
    @Default('saisie') String source,
    @Default(true) bool confirme,
    String? note,
    @JsonKey(name: 'modifie_par') String? modifiePar,
  }) = _Garde;

  factory Garde.fromJson(Map<String, dynamic> json) => _$GardeFromJson(json);

  /// Retrouvée dans les ventes ou proposée par la rotation, pas encore
  /// confirmée par l'officine.
  bool get aConfirmer => (source == 'detection' || source == 'prevision') && !confirme;

  /// Proposée d'après la rotation, pas encore confirmée.
  bool get proposee => source == 'prevision' && !confirme;
}

@freezed
abstract class Evenement with _$Evenement {
  const Evenement._();

  const factory Evenement({
    required int id,
    required TypeEvenement type,
    @JsonKey(name: 'date_debut') required DateTime debut,
    @JsonKey(name: 'date_fin') required DateTime fin,
    @JsonKey(name: 'a_verifier') @Default(false) bool aVerifier,
  }) = _Evenement;

  factory Evenement.fromJson(Map<String, dynamic> json) => _$EvenementFromJson(json);

  int get jours => fin.difference(debut).inDays + 1;
}

@freezed
abstract class Ferie with _$Ferie {
  const factory Ferie({required int id, required DateTime date, String? label}) = _Ferie;

  factory Ferie.fromJson(Map<String, dynamic> json) => _$FerieFromJson(json);
}

/// Une constante du calcul des commandes (`/stock/reglages`).
@freezed
abstract class Reglage with _$Reglage {
  const factory Reglage({
    required String cle,
    required double valeur,
    String? description,
    @JsonKey(name: 'modifie_par') String? modifiePar,
  }) = _Reglage;

  factory Reglage.fromJson(Map<String, dynamic> json) => _$ReglageFromJson(json);
}

/// « 2026-11-07 » pour l'API.
String jourApi(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
