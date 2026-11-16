// Alertes : ce qui demande une action, par urgence — Dart pur.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'format.dart';

part 'alertes.freezed.dart';
part 'alertes.g.dart';

/// Urgence d'une alerte.
enum NiveauAlerte {
  @JsonValue('aujourdhui')
  aujourdhui("Aujourd'hui"),
  @JsonValue('semaine')
  semaine('Cette semaine'),
  @JsonValue('surveiller')
  surveiller('À surveiller');

  const NiveauAlerte(this.libelle);
  final String libelle;
}

/// Famille d'une alerte : sert aux filtres.
enum TypeAlerte {
  @JsonValue('stock')
  stock('Stock'),
  @JsonValue('peremption')
  peremption('Péremption'),
  @JsonValue('livraison')
  livraison('Livraisons'),
  @JsonValue('confirmer')
  confirmer('À confirmer');

  const TypeAlerte(this.libelle);
  final String libelle;
}

/// Ce que fait le bouton d'une alerte.
enum SorteAction {
  /// Ajoute le produit à la commande du jour.
  @JsonValue('commander')
  commander,

  /// Ouvre l'écran [ActionAlerte.route].
  @JsonValue('ouvrir')
  ouvrir,

  /// Confirme ou écarte une tension (titulaire).
  @JsonValue('tension')
  tension,
  @JsonValue('aucune')
  aucune,
}

@freezed
abstract class ActionAlerte with _$ActionAlerte {
  const factory ActionAlerte({
    @JsonKey(unknownEnumValue: SorteAction.aucune) @Default(SorteAction.aucune) SorteAction sorte,
    @Default('') String libelle,
    String? route,
  }) = _ActionAlerte;

  factory ActionAlerte.fromJson(Map<String, dynamic> json) => _$ActionAlerteFromJson(json);
}

@freezed
abstract class Alerte with _$Alerte {
  const Alerte._();

  const factory Alerte({
    required String id,
    @Default(TypeAlerte.stock) TypeAlerte type,
    @Default(NiveauAlerte.surveiller) NiveauAlerte niveau,

    /// rupture, livraison, peremption, seuil, tension, confirmer, surstock, synchro.
    @Default('') String icone,

    /// Produit ou grossiste concerné, tel qu'EASYPHARM l'écrit.
    String? sujet,
    @Default('') String titre,
    @Default('') String detail,
    @JsonKey(name: 'id_nom') int? idNom,
    @Default(ActionAlerte()) ActionAlerte action,
  }) = _Alerte;

  factory Alerte.fromJson(Map<String, dynamic> json) => _$AlerteFromJson(json);

  /// « Doliprane 1 g B/8 · en rupture ».
  String get titreComplet => sujet == null ? titre : '${libelleProduit(sujet!)} · $titre';
}

@freezed
abstract class BrefAlertes with _$BrefAlertes {
  const factory BrefAlertes({
    @Default(0) int ruptures,
    @JsonKey(name: 'ruptures_imminentes') @Default(0) int rupturesImminentes,
    @JsonKey(name: 'valeur_a_risque') @Default(0) double valeurARisque,
    @JsonKey(name: 'commandes_non_livrees') @Default(0) int commandesNonLivrees,
    @JsonKey(name: 'budget_pct') int? budgetPct,
  }) = _BrefAlertes;

  factory BrefAlertes.fromJson(Map<String, dynamic> json) => _$BrefAlertesFromJson(json);
}

/// Alertes du jour (`GET /alertes`), de la plus urgente à la moins urgente.
@freezed
abstract class ListeAlertes with _$ListeAlertes {
  const ListeAlertes._();

  const factory ListeAlertes({
    required DateTime jour,
    @JsonKey(name: 'donnees_du') DateTime? donneesDu,
    @JsonKey(name: 'peut_decider') @Default(false) bool peutDecider,
    @Default(<Alerte>[]) List<Alerte> alertes,
    @Default(BrefAlertes()) BrefAlertes bref,
  }) = _ListeAlertes;

  factory ListeAlertes.fromJson(Map<String, dynamic> json) => _$ListeAlertesFromJson(json);

  /// Alertes de ce [type] (toutes si null) et de ce [niveau].
  List<Alerte> de(NiveauAlerte niveau, [TypeAlerte? type]) => [
    for (final a in alertes)
      if (a.niveau == niveau && (type == null || a.type == type)) a,
  ];

  int nombre([TypeAlerte? type]) => type == null ? alertes.length : alertes.where((a) => a.type == type).length;
}
