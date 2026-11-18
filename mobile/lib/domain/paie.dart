// Paie du mois (brut) : part fixe, prime de rendement, critères — Dart pur.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'format.dart';

part 'paie.freezed.dart';
part 'paie.g.dart';

const moisFrancais = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin', //
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

/// « novembre 2026 ».
String libelleMois(int annee, int mois) => '${moisFrancais[mois - 1]} $annee';

@freezed
abstract class EmployePaie with _$EmployePaie {
  const EmployePaie._();

  const factory EmployePaie({
    required int id,
    @Default('') String nom,
    String? prenom,
    @JsonKey(name: 'poste_code') String? posteCode,
    String? poste,
    @JsonKey(name: 'date_entree') DateTime? dateEntree,
    @JsonKey(name: 'date_sortie') DateTime? dateSortie,

    /// « 08:30:00 » ; absente, l'heure de début générale des réglages.
    @JsonKey(name: 'heure_debut') String? heureDebut,
  }) = _EmployePaie;

  factory EmployePaie.fromJson(Map<String, dynamic> json) => _$EmployePaieFromJson(json);

  String get nomComplet => [if (prenom != null && prenom!.isNotEmpty) prenom!, nom].join(' ');

  /// « 08:30 », ou null.
  String? get heureDebutCourte => heureDebut == null || heureDebut!.length < 5 ? null : heureDebut!.substring(0, 5);

  String get initiales {
    final p = (prenom ?? '').trim(), n = nom.trim();
    final a = p.isNotEmpty ? p[0] : '', b = n.isNotEmpty ? n[0] : '';
    return (a + b).toUpperCase();
  }
}

@freezed
abstract class JoursPaie with _$JoursPaie {
  const factory JoursPaie({
    @Default(30) int mois,
    @Default(30) int contrat,
    @Default(0) int presence,
    @Default(0) int absences,
    @JsonKey(name: 'a_confirmer') @Default(0) int aConfirmer,
  }) = _JoursPaie;

  factory JoursPaie.fromJson(Map<String, dynamic> json) => _$JoursPaieFromJson(json);
}

@freezed
abstract class LigneBulletin with _$LigneBulletin {
  const factory LigneBulletin({required String code, @Default('') String libelle, @Default(0) double montant}) =
      _LigneBulletin;

  factory LigneBulletin.fromJson(Map<String, dynamic> json) => _$LigneBulletinFromJson(json);
}

/// Un critère de la prime : valeur du mois, poids pour le poste, indice face
/// à la moyenne de l'équipe (100 = moyenne).
@freezed
abstract class Critere with _$Critere {
  const Critere._();

  const factory Critere({
    required String code,
    @Default('') String libelle,
    String? unite,
    Object? valeur,
    @Default(0) double poids,
    int? indice,
  }) = _Critere;

  factory Critere.fromJson(Map<String, dynamic> json) => _$CritereFromJson(json);

  /// « 312 400 DA », « 18 », « 22 j ».
  String get valeurLisible {
    final v = valeur is num ? valeur as num : num.tryParse('${valeur ?? ''}');
    if (v == null) return '—';
    if (unite == 'DA') return '${entier(v)} DA';
    if (code == 'ponctualite') return '${entier(v)} j';
    return entier(v);
  }

  /// Écart à la moyenne : « +55 % », « −40 % », null sans moyenne.
  String? get ecart {
    final i = indice;
    if (i == null) return null;
    final d = i - 100;
    return '${d >= 0 ? '+' : '−'}${d.abs()} %';
  }
}

@freezed
abstract class PrimeDetail with _$PrimeDetail {
  const factory PrimeDetail({
    @Default(0) double plancher,
    @Default(0) double merite,
    @JsonKey(name: 'calculee_le') DateTime? calculeeLe,
    @Default(<Critere>[]) List<Critere> criteres,
  }) = _PrimeDetail;

  factory PrimeDetail.fromJson(Map<String, dynamic> json) => _$PrimeDetailFromJson(json);
}

@freezed
abstract class BulletinValide with _$BulletinValide {
  const factory BulletinValide({
    @Default(1) int version,
    @Default(0) double brut,
    @JsonKey(name: 'valide_le') DateTime? valideLe,
    @JsonKey(name: 'valide_par') String? validePar,
    @JsonKey(name: 'a_jour') @Default(true) bool aJour,
  }) = _BulletinValide;

  factory BulletinValide.fromJson(Map<String, dynamic> json) => _$BulletinValideFromJson(json);
}

enum EtatPaie { prete, aConfirmer, aCompleter, aVerifier }

/// Brut du mois d'un employé.
@freezed
abstract class PaieEmploye with _$PaieEmploye {
  const PaieEmploye._();

  const factory PaieEmploye({
    required EmployePaie employe,
    @Default(JoursPaie()) JoursPaie jours,
    @JsonKey(name: 'anciennete_annees') @Default(0) int ancienneteAnnees,
    @JsonKey(name: 'heures_sup') @Default(0) double heuresSup,
    @Default(<LigneBulletin>[]) List<LigneBulletin> lignes,
    @JsonKey(name: 'part_fixe') @Default(0) double partFixe,
    @JsonKey(name: 'part_variable') @Default(0) double partVariable,
    PrimeDetail? prime,
    @JsonKey(name: 'prime_validee') @Default(false) bool primeValidee,
    @Default(0) double brut,
    @JsonKey(name: 'a_verifier') @Default(<String>[]) List<String> aVerifier,
    BulletinValide? bulletin,
  }) = _PaieEmploye;

  factory PaieEmploye.fromJson(Map<String, dynamic> json) => _$PaieEmployeFromJson(json);

  EtatPaie get etat {
    if (employe.posteCode == null) return EtatPaie.aCompleter;
    if (jours.aConfirmer > 0) return EtatPaie.aConfirmer;
    if (aVerifier.isNotEmpty) return EtatPaie.aVerifier;
    return EtatPaie.prete;
  }

  double ligne(String code) => lignes.where((l) => l.code == code).firstOrNull?.montant ?? 0;
}

@freezed
abstract class TotauxPaie with _$TotauxPaie {
  const factory TotauxPaie({
    @JsonKey(name: 'part_fixe') @Default(0) double partFixe,
    @JsonKey(name: 'part_variable') @Default(0) double partVariable,
    @Default(0) double brut,
  }) = _TotauxPaie;

  factory TotauxPaie.fromJson(Map<String, dynamic> json) => _$TotauxPaieFromJson(json);
}

@freezed
abstract class ReglesPaie with _$ReglesPaie {
  const factory ReglesPaie({
    @JsonKey(name: 'transport_jour') @Default(300) double transportJour,
    @JsonKey(name: 'panier_jour') @Default(600) double panierJour,
    @JsonKey(name: 'anciennete_an') @Default(1000) double ancienneteAn,
    @JsonKey(name: 'majoration_hs') @Default(1.5) double majorationHs,
    @JsonKey(name: 'heures_mois') @Default(173.33) double heuresMois,
  }) = _ReglesPaie;

  factory ReglesPaie.fromJson(Map<String, dynamic> json) => _$ReglesPaieFromJson(json);
}

/// Paie du mois (`GET /paie/{annee}/{mois}`).
@freezed
abstract class PaieMois with _$PaieMois {
  const PaieMois._();

  const factory PaieMois({
    required int annee,
    required int mois,
    @Default(<PaieEmploye>[]) List<PaieEmploye> employes,
    @Default(TotauxPaie()) TotauxPaie totaux,
    double? enveloppe,
    @Default(ReglesPaie()) ReglesPaie regles,
  }) = _PaieMois;

  factory PaieMois.fromJson(Map<String, dynamic> json) => _$PaieMoisFromJson(json);

  PaieEmploye? employe(int id) => employes.where((e) => e.employe.id == id).firstOrNull;

  int get aVerifier => employes.where((e) => e.etat != EtatPaie.prete).length;

  /// Tous les bulletins du mois sont validés et à jour.
  bool get valide => employes.isNotEmpty && employes.every((e) => e.bulletin?.aJour ?? false);
}

/// Détail d'une ligne de la part fixe : « 24 jours × 300 ».
String detailLigne(PaieEmploye p, String code, ReglesPaie r) {
  final j = p.jours;
  return switch (code) {
    'salaire_base' => j.contrat < j.mois ? '${j.contrat} jours sur ${j.mois}' : '',
    'anciennete' =>
      '${p.ancienneteAnnees} an${p.ancienneteAnnees > 1 ? 's' : ''} × ${entier(r.ancienneteAn)}'
          '${j.contrat < j.mois ? ' · ${j.contrat} j sur ${j.mois}' : ''}',
    'transport' => '${j.presence} jours × ${entier(r.transportJour)}',
    'panier' => '${j.presence} jours × ${entier(r.panierJour)}',
    'heures_sup' =>
      p.heuresSup == 0 ? 'aucune' : '${decimal(p.heuresSup, chiffres: 2)} h majorées × ${decimal(r.majorationHs)}',
    'retenue_absences' =>
      j.absences == 0 ? 'aucune absence' : '${j.absences} jour${j.absences > 1 ? 's' : ''} × 1/30ᵉ du salaire',
    _ => '',
  };
}

/// Un poste de travail (salaire de base, poids des critères).
@freezed
abstract class PosteTravail with _$PosteTravail {
  const factory PosteTravail({
    required String code,
    required String libelle,
    @JsonKey(name: 'salaire_base') @Default(0) double salaireBase,
    @JsonKey(name: 'vend_au_comptoir') @Default(true) bool vendAuComptoir,
  }) = _PosteTravail;

  factory PosteTravail.fromJson(Map<String, dynamic> json) => _$PosteTravailFromJson(json);
}
