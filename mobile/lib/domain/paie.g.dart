// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paie.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EmployePaie _$EmployePaieFromJson(Map<String, dynamic> json) => _EmployePaie(
  id: (json['id'] as num).toInt(),
  nom: json['nom'] as String? ?? '',
  prenom: json['prenom'] as String?,
  posteCode: json['poste_code'] as String?,
  poste: json['poste'] as String?,
  dateEntree: json['date_entree'] == null ? null : DateTime.parse(json['date_entree'] as String),
  dateSortie: json['date_sortie'] == null ? null : DateTime.parse(json['date_sortie'] as String),
  heureDebut: json['heure_debut'] as String?,
);

Map<String, dynamic> _$EmployePaieToJson(_EmployePaie instance) => <String, dynamic>{
  'id': instance.id,
  'nom': instance.nom,
  'prenom': instance.prenom,
  'poste_code': instance.posteCode,
  'poste': instance.poste,
  'date_entree': instance.dateEntree?.toIso8601String(),
  'date_sortie': instance.dateSortie?.toIso8601String(),
  'heure_debut': instance.heureDebut,
};

_JoursPaie _$JoursPaieFromJson(Map<String, dynamic> json) => _JoursPaie(
  mois: (json['mois'] as num?)?.toInt() ?? 30,
  contrat: (json['contrat'] as num?)?.toInt() ?? 30,
  presence: (json['presence'] as num?)?.toInt() ?? 0,
  absences: (json['absences'] as num?)?.toInt() ?? 0,
  aConfirmer: (json['a_confirmer'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$JoursPaieToJson(_JoursPaie instance) => <String, dynamic>{
  'mois': instance.mois,
  'contrat': instance.contrat,
  'presence': instance.presence,
  'absences': instance.absences,
  'a_confirmer': instance.aConfirmer,
};

_LigneBulletin _$LigneBulletinFromJson(Map<String, dynamic> json) => _LigneBulletin(
  code: json['code'] as String,
  libelle: json['libelle'] as String? ?? '',
  montant: (json['montant'] as num?)?.toDouble() ?? 0,
);

Map<String, dynamic> _$LigneBulletinToJson(_LigneBulletin instance) => <String, dynamic>{
  'code': instance.code,
  'libelle': instance.libelle,
  'montant': instance.montant,
};

_Critere _$CritereFromJson(Map<String, dynamic> json) => _Critere(
  code: json['code'] as String,
  libelle: json['libelle'] as String? ?? '',
  unite: json['unite'] as String?,
  valeur: json['valeur'],
  poids: (json['poids'] as num?)?.toDouble() ?? 0,
  indice: (json['indice'] as num?)?.toInt(),
);

Map<String, dynamic> _$CritereToJson(_Critere instance) => <String, dynamic>{
  'code': instance.code,
  'libelle': instance.libelle,
  'unite': instance.unite,
  'valeur': instance.valeur,
  'poids': instance.poids,
  'indice': instance.indice,
};

_PrimeDetail _$PrimeDetailFromJson(Map<String, dynamic> json) => _PrimeDetail(
  plancher: (json['plancher'] as num?)?.toDouble() ?? 0,
  merite: (json['merite'] as num?)?.toDouble() ?? 0,
  calculeeLe: json['calculee_le'] == null ? null : DateTime.parse(json['calculee_le'] as String),
  criteres:
      (json['criteres'] as List<dynamic>?)?.map((e) => Critere.fromJson(e as Map<String, dynamic>)).toList() ??
      const <Critere>[],
);

Map<String, dynamic> _$PrimeDetailToJson(_PrimeDetail instance) => <String, dynamic>{
  'plancher': instance.plancher,
  'merite': instance.merite,
  'calculee_le': instance.calculeeLe?.toIso8601String(),
  'criteres': instance.criteres,
};

_BulletinValide _$BulletinValideFromJson(Map<String, dynamic> json) => _BulletinValide(
  version: (json['version'] as num?)?.toInt() ?? 1,
  brut: (json['brut'] as num?)?.toDouble() ?? 0,
  valideLe: json['valide_le'] == null ? null : DateTime.parse(json['valide_le'] as String),
  validePar: json['valide_par'] as String?,
  aJour: json['a_jour'] as bool? ?? true,
);

Map<String, dynamic> _$BulletinValideToJson(_BulletinValide instance) => <String, dynamic>{
  'version': instance.version,
  'brut': instance.brut,
  'valide_le': instance.valideLe?.toIso8601String(),
  'valide_par': instance.validePar,
  'a_jour': instance.aJour,
};

_PaieEmploye _$PaieEmployeFromJson(Map<String, dynamic> json) => _PaieEmploye(
  employe: EmployePaie.fromJson(json['employe'] as Map<String, dynamic>),
  jours: json['jours'] == null ? const JoursPaie() : JoursPaie.fromJson(json['jours'] as Map<String, dynamic>),
  ancienneteAnnees: (json['anciennete_annees'] as num?)?.toInt() ?? 0,
  heuresSup: (json['heures_sup'] as num?)?.toDouble() ?? 0,
  lignes:
      (json['lignes'] as List<dynamic>?)?.map((e) => LigneBulletin.fromJson(e as Map<String, dynamic>)).toList() ??
      const <LigneBulletin>[],
  partFixe: (json['part_fixe'] as num?)?.toDouble() ?? 0,
  partVariable: (json['part_variable'] as num?)?.toDouble() ?? 0,
  prime: json['prime'] == null ? null : PrimeDetail.fromJson(json['prime'] as Map<String, dynamic>),
  primeValidee: json['prime_validee'] as bool? ?? false,
  brut: (json['brut'] as num?)?.toDouble() ?? 0,
  aVerifier: (json['a_verifier'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
  bulletin: json['bulletin'] == null ? null : BulletinValide.fromJson(json['bulletin'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PaieEmployeToJson(_PaieEmploye instance) => <String, dynamic>{
  'employe': instance.employe,
  'jours': instance.jours,
  'anciennete_annees': instance.ancienneteAnnees,
  'heures_sup': instance.heuresSup,
  'lignes': instance.lignes,
  'part_fixe': instance.partFixe,
  'part_variable': instance.partVariable,
  'prime': instance.prime,
  'prime_validee': instance.primeValidee,
  'brut': instance.brut,
  'a_verifier': instance.aVerifier,
  'bulletin': instance.bulletin,
};

_TotauxPaie _$TotauxPaieFromJson(Map<String, dynamic> json) => _TotauxPaie(
  partFixe: (json['part_fixe'] as num?)?.toDouble() ?? 0,
  partVariable: (json['part_variable'] as num?)?.toDouble() ?? 0,
  brut: (json['brut'] as num?)?.toDouble() ?? 0,
);

Map<String, dynamic> _$TotauxPaieToJson(_TotauxPaie instance) => <String, dynamic>{
  'part_fixe': instance.partFixe,
  'part_variable': instance.partVariable,
  'brut': instance.brut,
};

_ReglesPaie _$ReglesPaieFromJson(Map<String, dynamic> json) => _ReglesPaie(
  transportJour: (json['transport_jour'] as num?)?.toDouble() ?? 300,
  panierJour: (json['panier_jour'] as num?)?.toDouble() ?? 600,
  ancienneteAn: (json['anciennete_an'] as num?)?.toDouble() ?? 1000,
  majorationHs: (json['majoration_hs'] as num?)?.toDouble() ?? 1.5,
  heuresMois: (json['heures_mois'] as num?)?.toDouble() ?? 173.33,
);

Map<String, dynamic> _$ReglesPaieToJson(_ReglesPaie instance) => <String, dynamic>{
  'transport_jour': instance.transportJour,
  'panier_jour': instance.panierJour,
  'anciennete_an': instance.ancienneteAn,
  'majoration_hs': instance.majorationHs,
  'heures_mois': instance.heuresMois,
};

_PaieMois _$PaieMoisFromJson(Map<String, dynamic> json) => _PaieMois(
  annee: (json['annee'] as num).toInt(),
  mois: (json['mois'] as num).toInt(),
  employes:
      (json['employes'] as List<dynamic>?)?.map((e) => PaieEmploye.fromJson(e as Map<String, dynamic>)).toList() ??
      const <PaieEmploye>[],
  totaux: json['totaux'] == null ? const TotauxPaie() : TotauxPaie.fromJson(json['totaux'] as Map<String, dynamic>),
  enveloppe: (json['enveloppe'] as num?)?.toDouble(),
  regles: json['regles'] == null ? const ReglesPaie() : ReglesPaie.fromJson(json['regles'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PaieMoisToJson(_PaieMois instance) => <String, dynamic>{
  'annee': instance.annee,
  'mois': instance.mois,
  'employes': instance.employes,
  'totaux': instance.totaux,
  'enveloppe': instance.enveloppe,
  'regles': instance.regles,
};

_PosteTravail _$PosteTravailFromJson(Map<String, dynamic> json) => _PosteTravail(
  code: json['code'] as String,
  libelle: json['libelle'] as String,
  salaireBase: (json['salaire_base'] as num?)?.toDouble() ?? 0,
  vendAuComptoir: json['vend_au_comptoir'] as bool? ?? true,
);

Map<String, dynamic> _$PosteTravailToJson(_PosteTravail instance) => <String, dynamic>{
  'code': instance.code,
  'libelle': instance.libelle,
  'salaire_base': instance.salaireBase,
  'vend_au_comptoir': instance.vendAuComptoir,
};
