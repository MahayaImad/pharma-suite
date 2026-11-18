// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'paie.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EmployePaie {

 int get id; String get nom; String? get prenom;@JsonKey(name: 'poste_code') String? get posteCode; String? get poste;@JsonKey(name: 'date_entree') DateTime? get dateEntree;@JsonKey(name: 'date_sortie') DateTime? get dateSortie;
/// Create a copy of EmployePaie
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployePaieCopyWith<EmployePaie> get copyWith => _$EmployePaieCopyWithImpl<EmployePaie>(this as EmployePaie, _$identity);

  /// Serializes this EmployePaie to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EmployePaie;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployePaie&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nom, _this.nom) || other.nom == _this.nom)&&(identical(other.prenom, _this.prenom) || other.prenom == _this.prenom)&&(identical(other.posteCode, _this.posteCode) || other.posteCode == _this.posteCode)&&(identical(other.poste, _this.poste) || other.poste == _this.poste)&&(identical(other.dateEntree, _this.dateEntree) || other.dateEntree == _this.dateEntree)&&(identical(other.dateSortie, _this.dateSortie) || other.dateSortie == _this.dateSortie));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EmployePaie;
  return Object.hash(runtimeType,_this.id,_this.nom,_this.prenom,_this.posteCode,_this.poste,_this.dateEntree,_this.dateSortie);
}

@override
String toString() {
  final _this = this as EmployePaie;
  return 'EmployePaie(id: ${_this.id}, nom: ${_this.nom}, prenom: ${_this.prenom}, posteCode: ${_this.posteCode}, poste: ${_this.poste}, dateEntree: ${_this.dateEntree}, dateSortie: ${_this.dateSortie})';
}


}

/// @nodoc
abstract mixin class $EmployePaieCopyWith<$Res>  {
  factory $EmployePaieCopyWith(EmployePaie value, $Res Function(EmployePaie) _then) = _$EmployePaieCopyWithImpl;
@useResult
$Res call({
 int id, String nom, String? prenom,@JsonKey(name: 'poste_code') String? posteCode, String? poste,@JsonKey(name: 'date_entree') DateTime? dateEntree,@JsonKey(name: 'date_sortie') DateTime? dateSortie
});




}
/// @nodoc
class _$EmployePaieCopyWithImpl<$Res>
    implements $EmployePaieCopyWith<$Res> {
  _$EmployePaieCopyWithImpl(this._self, this._then);

  final EmployePaie _self;
  final $Res Function(EmployePaie) _then;

/// Create a copy of EmployePaie
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nom = null,Object? prenom = freezed,Object? posteCode = freezed,Object? poste = freezed,Object? dateEntree = freezed,Object? dateSortie = freezed,}) {
  return _then(EmployePaie(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,prenom: freezed == prenom ? _self.prenom : prenom // ignore: cast_nullable_to_non_nullable
as String?,posteCode: freezed == posteCode ? _self.posteCode : posteCode // ignore: cast_nullable_to_non_nullable
as String?,poste: freezed == poste ? _self.poste : poste // ignore: cast_nullable_to_non_nullable
as String?,dateEntree: freezed == dateEntree ? _self.dateEntree : dateEntree // ignore: cast_nullable_to_non_nullable
as DateTime?,dateSortie: freezed == dateSortie ? _self.dateSortie : dateSortie // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [EmployePaie].
extension EmployePaiePatterns on EmployePaie {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmployePaie value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmployePaie() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmployePaie value)  $default,){
final _that = this;
switch (_that) {
case _EmployePaie():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmployePaie value)?  $default,){
final _that = this;
switch (_that) {
case _EmployePaie() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String nom,  String? prenom, @JsonKey(name: 'poste_code')  String? posteCode,  String? poste, @JsonKey(name: 'date_entree')  DateTime? dateEntree, @JsonKey(name: 'date_sortie')  DateTime? dateSortie)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmployePaie() when $default != null:
return $default(_that.id,_that.nom,_that.prenom,_that.posteCode,_that.poste,_that.dateEntree,_that.dateSortie);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String nom,  String? prenom, @JsonKey(name: 'poste_code')  String? posteCode,  String? poste, @JsonKey(name: 'date_entree')  DateTime? dateEntree, @JsonKey(name: 'date_sortie')  DateTime? dateSortie)  $default,) {final _that = this;
switch (_that) {
case _EmployePaie():
return $default(_that.id,_that.nom,_that.prenom,_that.posteCode,_that.poste,_that.dateEntree,_that.dateSortie);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String nom,  String? prenom, @JsonKey(name: 'poste_code')  String? posteCode,  String? poste, @JsonKey(name: 'date_entree')  DateTime? dateEntree, @JsonKey(name: 'date_sortie')  DateTime? dateSortie)?  $default,) {final _that = this;
switch (_that) {
case _EmployePaie() when $default != null:
return $default(_that.id,_that.nom,_that.prenom,_that.posteCode,_that.poste,_that.dateEntree,_that.dateSortie);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EmployePaie extends EmployePaie {
  const _EmployePaie({required this.id, this.nom = '', this.prenom, @JsonKey(name: 'poste_code') this.posteCode, this.poste, @JsonKey(name: 'date_entree') this.dateEntree, @JsonKey(name: 'date_sortie') this.dateSortie}): super._();
  factory _EmployePaie.fromJson(Map<String, dynamic> json) => _$EmployePaieFromJson(json);

@override final  int id;
@override@JsonKey() final  String nom;
@override final  String? prenom;
@override@JsonKey(name: 'poste_code') final  String? posteCode;
@override final  String? poste;
@override@JsonKey(name: 'date_entree') final  DateTime? dateEntree;
@override@JsonKey(name: 'date_sortie') final  DateTime? dateSortie;

/// Create a copy of EmployePaie
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmployePaieCopyWith<_EmployePaie> get copyWith => __$EmployePaieCopyWithImpl<_EmployePaie>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmployePaieToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmployePaie&&(identical(other.id, id) || other.id == id)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.prenom, prenom) || other.prenom == prenom)&&(identical(other.posteCode, posteCode) || other.posteCode == posteCode)&&(identical(other.poste, poste) || other.poste == poste)&&(identical(other.dateEntree, dateEntree) || other.dateEntree == dateEntree)&&(identical(other.dateSortie, dateSortie) || other.dateSortie == dateSortie));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,nom,prenom,posteCode,poste,dateEntree,dateSortie);
}

@override
String toString() {
    return 'EmployePaie(id: $id, nom: $nom, prenom: $prenom, posteCode: $posteCode, poste: $poste, dateEntree: $dateEntree, dateSortie: $dateSortie)';
}


}

/// @nodoc
abstract mixin class _$EmployePaieCopyWith<$Res> implements $EmployePaieCopyWith<$Res> {
  factory _$EmployePaieCopyWith(_EmployePaie value, $Res Function(_EmployePaie) _then) = __$EmployePaieCopyWithImpl;
@override @useResult
$Res call({
 int id, String nom, String? prenom,@JsonKey(name: 'poste_code') String? posteCode, String? poste,@JsonKey(name: 'date_entree') DateTime? dateEntree,@JsonKey(name: 'date_sortie') DateTime? dateSortie
});




}
/// @nodoc
class __$EmployePaieCopyWithImpl<$Res>
    implements _$EmployePaieCopyWith<$Res> {
  __$EmployePaieCopyWithImpl(this._self, this._then);

  final _EmployePaie _self;
  final $Res Function(_EmployePaie) _then;

/// Create a copy of EmployePaie
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nom = null,Object? prenom = freezed,Object? posteCode = freezed,Object? poste = freezed,Object? dateEntree = freezed,Object? dateSortie = freezed,}) {
  return _then(_EmployePaie(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,prenom: freezed == prenom ? _self.prenom : prenom // ignore: cast_nullable_to_non_nullable
as String?,posteCode: freezed == posteCode ? _self.posteCode : posteCode // ignore: cast_nullable_to_non_nullable
as String?,poste: freezed == poste ? _self.poste : poste // ignore: cast_nullable_to_non_nullable
as String?,dateEntree: freezed == dateEntree ? _self.dateEntree : dateEntree // ignore: cast_nullable_to_non_nullable
as DateTime?,dateSortie: freezed == dateSortie ? _self.dateSortie : dateSortie // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$JoursPaie {

 int get mois; int get contrat; int get presence; int get absences;@JsonKey(name: 'a_confirmer') int get aConfirmer;
/// Create a copy of JoursPaie
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JoursPaieCopyWith<JoursPaie> get copyWith => _$JoursPaieCopyWithImpl<JoursPaie>(this as JoursPaie, _$identity);

  /// Serializes this JoursPaie to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as JoursPaie;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JoursPaie&&(identical(other.mois, _this.mois) || other.mois == _this.mois)&&(identical(other.contrat, _this.contrat) || other.contrat == _this.contrat)&&(identical(other.presence, _this.presence) || other.presence == _this.presence)&&(identical(other.absences, _this.absences) || other.absences == _this.absences)&&(identical(other.aConfirmer, _this.aConfirmer) || other.aConfirmer == _this.aConfirmer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as JoursPaie;
  return Object.hash(runtimeType,_this.mois,_this.contrat,_this.presence,_this.absences,_this.aConfirmer);
}

@override
String toString() {
  final _this = this as JoursPaie;
  return 'JoursPaie(mois: ${_this.mois}, contrat: ${_this.contrat}, presence: ${_this.presence}, absences: ${_this.absences}, aConfirmer: ${_this.aConfirmer})';
}


}

/// @nodoc
abstract mixin class $JoursPaieCopyWith<$Res>  {
  factory $JoursPaieCopyWith(JoursPaie value, $Res Function(JoursPaie) _then) = _$JoursPaieCopyWithImpl;
@useResult
$Res call({
 int mois, int contrat, int presence, int absences,@JsonKey(name: 'a_confirmer') int aConfirmer
});




}
/// @nodoc
class _$JoursPaieCopyWithImpl<$Res>
    implements $JoursPaieCopyWith<$Res> {
  _$JoursPaieCopyWithImpl(this._self, this._then);

  final JoursPaie _self;
  final $Res Function(JoursPaie) _then;

/// Create a copy of JoursPaie
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mois = null,Object? contrat = null,Object? presence = null,Object? absences = null,Object? aConfirmer = null,}) {
  return _then(JoursPaie(
mois: null == mois ? _self.mois : mois // ignore: cast_nullable_to_non_nullable
as int,contrat: null == contrat ? _self.contrat : contrat // ignore: cast_nullable_to_non_nullable
as int,presence: null == presence ? _self.presence : presence // ignore: cast_nullable_to_non_nullable
as int,absences: null == absences ? _self.absences : absences // ignore: cast_nullable_to_non_nullable
as int,aConfirmer: null == aConfirmer ? _self.aConfirmer : aConfirmer // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [JoursPaie].
extension JoursPaiePatterns on JoursPaie {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JoursPaie value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JoursPaie() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JoursPaie value)  $default,){
final _that = this;
switch (_that) {
case _JoursPaie():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JoursPaie value)?  $default,){
final _that = this;
switch (_that) {
case _JoursPaie() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int mois,  int contrat,  int presence,  int absences, @JsonKey(name: 'a_confirmer')  int aConfirmer)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JoursPaie() when $default != null:
return $default(_that.mois,_that.contrat,_that.presence,_that.absences,_that.aConfirmer);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int mois,  int contrat,  int presence,  int absences, @JsonKey(name: 'a_confirmer')  int aConfirmer)  $default,) {final _that = this;
switch (_that) {
case _JoursPaie():
return $default(_that.mois,_that.contrat,_that.presence,_that.absences,_that.aConfirmer);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int mois,  int contrat,  int presence,  int absences, @JsonKey(name: 'a_confirmer')  int aConfirmer)?  $default,) {final _that = this;
switch (_that) {
case _JoursPaie() when $default != null:
return $default(_that.mois,_that.contrat,_that.presence,_that.absences,_that.aConfirmer);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JoursPaie implements JoursPaie {
  const _JoursPaie({this.mois = 30, this.contrat = 30, this.presence = 0, this.absences = 0, @JsonKey(name: 'a_confirmer') this.aConfirmer = 0});
  factory _JoursPaie.fromJson(Map<String, dynamic> json) => _$JoursPaieFromJson(json);

@override@JsonKey() final  int mois;
@override@JsonKey() final  int contrat;
@override@JsonKey() final  int presence;
@override@JsonKey() final  int absences;
@override@JsonKey(name: 'a_confirmer') final  int aConfirmer;

/// Create a copy of JoursPaie
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JoursPaieCopyWith<_JoursPaie> get copyWith => __$JoursPaieCopyWithImpl<_JoursPaie>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JoursPaieToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _JoursPaie&&(identical(other.mois, mois) || other.mois == mois)&&(identical(other.contrat, contrat) || other.contrat == contrat)&&(identical(other.presence, presence) || other.presence == presence)&&(identical(other.absences, absences) || other.absences == absences)&&(identical(other.aConfirmer, aConfirmer) || other.aConfirmer == aConfirmer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,mois,contrat,presence,absences,aConfirmer);
}

@override
String toString() {
    return 'JoursPaie(mois: $mois, contrat: $contrat, presence: $presence, absences: $absences, aConfirmer: $aConfirmer)';
}


}

/// @nodoc
abstract mixin class _$JoursPaieCopyWith<$Res> implements $JoursPaieCopyWith<$Res> {
  factory _$JoursPaieCopyWith(_JoursPaie value, $Res Function(_JoursPaie) _then) = __$JoursPaieCopyWithImpl;
@override @useResult
$Res call({
 int mois, int contrat, int presence, int absences,@JsonKey(name: 'a_confirmer') int aConfirmer
});




}
/// @nodoc
class __$JoursPaieCopyWithImpl<$Res>
    implements _$JoursPaieCopyWith<$Res> {
  __$JoursPaieCopyWithImpl(this._self, this._then);

  final _JoursPaie _self;
  final $Res Function(_JoursPaie) _then;

/// Create a copy of JoursPaie
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mois = null,Object? contrat = null,Object? presence = null,Object? absences = null,Object? aConfirmer = null,}) {
  return _then(_JoursPaie(
mois: null == mois ? _self.mois : mois // ignore: cast_nullable_to_non_nullable
as int,contrat: null == contrat ? _self.contrat : contrat // ignore: cast_nullable_to_non_nullable
as int,presence: null == presence ? _self.presence : presence // ignore: cast_nullable_to_non_nullable
as int,absences: null == absences ? _self.absences : absences // ignore: cast_nullable_to_non_nullable
as int,aConfirmer: null == aConfirmer ? _self.aConfirmer : aConfirmer // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$LigneBulletin {

 String get code; String get libelle; double get montant;
/// Create a copy of LigneBulletin
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LigneBulletinCopyWith<LigneBulletin> get copyWith => _$LigneBulletinCopyWithImpl<LigneBulletin>(this as LigneBulletin, _$identity);

  /// Serializes this LigneBulletin to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LigneBulletin;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LigneBulletin&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.libelle, _this.libelle) || other.libelle == _this.libelle)&&(identical(other.montant, _this.montant) || other.montant == _this.montant));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LigneBulletin;
  return Object.hash(runtimeType,_this.code,_this.libelle,_this.montant);
}

@override
String toString() {
  final _this = this as LigneBulletin;
  return 'LigneBulletin(code: ${_this.code}, libelle: ${_this.libelle}, montant: ${_this.montant})';
}


}

/// @nodoc
abstract mixin class $LigneBulletinCopyWith<$Res>  {
  factory $LigneBulletinCopyWith(LigneBulletin value, $Res Function(LigneBulletin) _then) = _$LigneBulletinCopyWithImpl;
@useResult
$Res call({
 String code, String libelle, double montant
});




}
/// @nodoc
class _$LigneBulletinCopyWithImpl<$Res>
    implements $LigneBulletinCopyWith<$Res> {
  _$LigneBulletinCopyWithImpl(this._self, this._then);

  final LigneBulletin _self;
  final $Res Function(LigneBulletin) _then;

/// Create a copy of LigneBulletin
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? libelle = null,Object? montant = null,}) {
  return _then(LigneBulletin(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,libelle: null == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String,montant: null == montant ? _self.montant : montant // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [LigneBulletin].
extension LigneBulletinPatterns on LigneBulletin {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LigneBulletin value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LigneBulletin() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LigneBulletin value)  $default,){
final _that = this;
switch (_that) {
case _LigneBulletin():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LigneBulletin value)?  $default,){
final _that = this;
switch (_that) {
case _LigneBulletin() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String libelle,  double montant)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LigneBulletin() when $default != null:
return $default(_that.code,_that.libelle,_that.montant);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String libelle,  double montant)  $default,) {final _that = this;
switch (_that) {
case _LigneBulletin():
return $default(_that.code,_that.libelle,_that.montant);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String libelle,  double montant)?  $default,) {final _that = this;
switch (_that) {
case _LigneBulletin() when $default != null:
return $default(_that.code,_that.libelle,_that.montant);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LigneBulletin implements LigneBulletin {
  const _LigneBulletin({required this.code, this.libelle = '', this.montant = 0});
  factory _LigneBulletin.fromJson(Map<String, dynamic> json) => _$LigneBulletinFromJson(json);

@override final  String code;
@override@JsonKey() final  String libelle;
@override@JsonKey() final  double montant;

/// Create a copy of LigneBulletin
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LigneBulletinCopyWith<_LigneBulletin> get copyWith => __$LigneBulletinCopyWithImpl<_LigneBulletin>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LigneBulletinToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LigneBulletin&&(identical(other.code, code) || other.code == code)&&(identical(other.libelle, libelle) || other.libelle == libelle)&&(identical(other.montant, montant) || other.montant == montant));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,code,libelle,montant);
}

@override
String toString() {
    return 'LigneBulletin(code: $code, libelle: $libelle, montant: $montant)';
}


}

/// @nodoc
abstract mixin class _$LigneBulletinCopyWith<$Res> implements $LigneBulletinCopyWith<$Res> {
  factory _$LigneBulletinCopyWith(_LigneBulletin value, $Res Function(_LigneBulletin) _then) = __$LigneBulletinCopyWithImpl;
@override @useResult
$Res call({
 String code, String libelle, double montant
});




}
/// @nodoc
class __$LigneBulletinCopyWithImpl<$Res>
    implements _$LigneBulletinCopyWith<$Res> {
  __$LigneBulletinCopyWithImpl(this._self, this._then);

  final _LigneBulletin _self;
  final $Res Function(_LigneBulletin) _then;

/// Create a copy of LigneBulletin
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? libelle = null,Object? montant = null,}) {
  return _then(_LigneBulletin(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,libelle: null == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String,montant: null == montant ? _self.montant : montant // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$Critere {

 String get code; String get libelle; String? get unite; Object? get valeur; double get poids; int? get indice;
/// Create a copy of Critere
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CritereCopyWith<Critere> get copyWith => _$CritereCopyWithImpl<Critere>(this as Critere, _$identity);

  /// Serializes this Critere to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Critere;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Critere&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.libelle, _this.libelle) || other.libelle == _this.libelle)&&(identical(other.unite, _this.unite) || other.unite == _this.unite)&&const DeepCollectionEquality().equals(other.valeur, _this.valeur)&&(identical(other.poids, _this.poids) || other.poids == _this.poids)&&(identical(other.indice, _this.indice) || other.indice == _this.indice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Critere;
  return Object.hash(runtimeType,_this.code,_this.libelle,_this.unite,const DeepCollectionEquality().hash(_this.valeur),_this.poids,_this.indice);
}

@override
String toString() {
  final _this = this as Critere;
  return 'Critere(code: ${_this.code}, libelle: ${_this.libelle}, unite: ${_this.unite}, valeur: ${_this.valeur}, poids: ${_this.poids}, indice: ${_this.indice})';
}


}

/// @nodoc
abstract mixin class $CritereCopyWith<$Res>  {
  factory $CritereCopyWith(Critere value, $Res Function(Critere) _then) = _$CritereCopyWithImpl;
@useResult
$Res call({
 String code, String libelle, String? unite, Object? valeur, double poids, int? indice
});




}
/// @nodoc
class _$CritereCopyWithImpl<$Res>
    implements $CritereCopyWith<$Res> {
  _$CritereCopyWithImpl(this._self, this._then);

  final Critere _self;
  final $Res Function(Critere) _then;

/// Create a copy of Critere
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? libelle = null,Object? unite = freezed,Object? valeur = freezed,Object? poids = null,Object? indice = freezed,}) {
  return _then(Critere(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,libelle: null == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String,unite: freezed == unite ? _self.unite : unite // ignore: cast_nullable_to_non_nullable
as String?,valeur: freezed == valeur ? _self.valeur : valeur ,poids: null == poids ? _self.poids : poids // ignore: cast_nullable_to_non_nullable
as double,indice: freezed == indice ? _self.indice : indice // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [Critere].
extension CriterePatterns on Critere {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Critere value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Critere() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Critere value)  $default,){
final _that = this;
switch (_that) {
case _Critere():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Critere value)?  $default,){
final _that = this;
switch (_that) {
case _Critere() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String libelle,  String? unite,  Object? valeur,  double poids,  int? indice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Critere() when $default != null:
return $default(_that.code,_that.libelle,_that.unite,_that.valeur,_that.poids,_that.indice);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String libelle,  String? unite,  Object? valeur,  double poids,  int? indice)  $default,) {final _that = this;
switch (_that) {
case _Critere():
return $default(_that.code,_that.libelle,_that.unite,_that.valeur,_that.poids,_that.indice);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String libelle,  String? unite,  Object? valeur,  double poids,  int? indice)?  $default,) {final _that = this;
switch (_that) {
case _Critere() when $default != null:
return $default(_that.code,_that.libelle,_that.unite,_that.valeur,_that.poids,_that.indice);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Critere extends Critere {
  const _Critere({required this.code, this.libelle = '', this.unite, this.valeur, this.poids = 0, this.indice}): super._();
  factory _Critere.fromJson(Map<String, dynamic> json) => _$CritereFromJson(json);

@override final  String code;
@override@JsonKey() final  String libelle;
@override final  String? unite;
@override final  Object? valeur;
@override@JsonKey() final  double poids;
@override final  int? indice;

/// Create a copy of Critere
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CritereCopyWith<_Critere> get copyWith => __$CritereCopyWithImpl<_Critere>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CritereToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Critere&&(identical(other.code, code) || other.code == code)&&(identical(other.libelle, libelle) || other.libelle == libelle)&&(identical(other.unite, unite) || other.unite == unite)&&const DeepCollectionEquality().equals(other.valeur, valeur)&&(identical(other.poids, poids) || other.poids == poids)&&(identical(other.indice, indice) || other.indice == indice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,code,libelle,unite,const DeepCollectionEquality().hash(valeur),poids,indice);
}

@override
String toString() {
    return 'Critere(code: $code, libelle: $libelle, unite: $unite, valeur: $valeur, poids: $poids, indice: $indice)';
}


}

/// @nodoc
abstract mixin class _$CritereCopyWith<$Res> implements $CritereCopyWith<$Res> {
  factory _$CritereCopyWith(_Critere value, $Res Function(_Critere) _then) = __$CritereCopyWithImpl;
@override @useResult
$Res call({
 String code, String libelle, String? unite, Object? valeur, double poids, int? indice
});




}
/// @nodoc
class __$CritereCopyWithImpl<$Res>
    implements _$CritereCopyWith<$Res> {
  __$CritereCopyWithImpl(this._self, this._then);

  final _Critere _self;
  final $Res Function(_Critere) _then;

/// Create a copy of Critere
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? libelle = null,Object? unite = freezed,Object? valeur = freezed,Object? poids = null,Object? indice = freezed,}) {
  return _then(_Critere(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,libelle: null == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String,unite: freezed == unite ? _self.unite : unite // ignore: cast_nullable_to_non_nullable
as String?,valeur: freezed == valeur ? _self.valeur : valeur ,poids: null == poids ? _self.poids : poids // ignore: cast_nullable_to_non_nullable
as double,indice: freezed == indice ? _self.indice : indice // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$PrimeDetail {

 double get plancher; double get merite;@JsonKey(name: 'calculee_le') DateTime? get calculeeLe; List<Critere> get criteres;
/// Create a copy of PrimeDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrimeDetailCopyWith<PrimeDetail> get copyWith => _$PrimeDetailCopyWithImpl<PrimeDetail>(this as PrimeDetail, _$identity);

  /// Serializes this PrimeDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PrimeDetail;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrimeDetail&&(identical(other.plancher, _this.plancher) || other.plancher == _this.plancher)&&(identical(other.merite, _this.merite) || other.merite == _this.merite)&&(identical(other.calculeeLe, _this.calculeeLe) || other.calculeeLe == _this.calculeeLe)&&const DeepCollectionEquality().equals(other.criteres, _this.criteres));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PrimeDetail;
  return Object.hash(runtimeType,_this.plancher,_this.merite,_this.calculeeLe,const DeepCollectionEquality().hash(_this.criteres));
}

@override
String toString() {
  final _this = this as PrimeDetail;
  return 'PrimeDetail(plancher: ${_this.plancher}, merite: ${_this.merite}, calculeeLe: ${_this.calculeeLe}, criteres: ${_this.criteres})';
}


}

/// @nodoc
abstract mixin class $PrimeDetailCopyWith<$Res>  {
  factory $PrimeDetailCopyWith(PrimeDetail value, $Res Function(PrimeDetail) _then) = _$PrimeDetailCopyWithImpl;
@useResult
$Res call({
 double plancher, double merite,@JsonKey(name: 'calculee_le') DateTime? calculeeLe, List<Critere> criteres
});




}
/// @nodoc
class _$PrimeDetailCopyWithImpl<$Res>
    implements $PrimeDetailCopyWith<$Res> {
  _$PrimeDetailCopyWithImpl(this._self, this._then);

  final PrimeDetail _self;
  final $Res Function(PrimeDetail) _then;

/// Create a copy of PrimeDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plancher = null,Object? merite = null,Object? calculeeLe = freezed,Object? criteres = null,}) {
  return _then(PrimeDetail(
plancher: null == plancher ? _self.plancher : plancher // ignore: cast_nullable_to_non_nullable
as double,merite: null == merite ? _self.merite : merite // ignore: cast_nullable_to_non_nullable
as double,calculeeLe: freezed == calculeeLe ? _self.calculeeLe : calculeeLe // ignore: cast_nullable_to_non_nullable
as DateTime?,criteres: null == criteres ? _self.criteres : criteres // ignore: cast_nullable_to_non_nullable
as List<Critere>,
  ));
}

}


/// Adds pattern-matching-related methods to [PrimeDetail].
extension PrimeDetailPatterns on PrimeDetail {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PrimeDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PrimeDetail() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PrimeDetail value)  $default,){
final _that = this;
switch (_that) {
case _PrimeDetail():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PrimeDetail value)?  $default,){
final _that = this;
switch (_that) {
case _PrimeDetail() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double plancher,  double merite, @JsonKey(name: 'calculee_le')  DateTime? calculeeLe,  List<Critere> criteres)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PrimeDetail() when $default != null:
return $default(_that.plancher,_that.merite,_that.calculeeLe,_that.criteres);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double plancher,  double merite, @JsonKey(name: 'calculee_le')  DateTime? calculeeLe,  List<Critere> criteres)  $default,) {final _that = this;
switch (_that) {
case _PrimeDetail():
return $default(_that.plancher,_that.merite,_that.calculeeLe,_that.criteres);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double plancher,  double merite, @JsonKey(name: 'calculee_le')  DateTime? calculeeLe,  List<Critere> criteres)?  $default,) {final _that = this;
switch (_that) {
case _PrimeDetail() when $default != null:
return $default(_that.plancher,_that.merite,_that.calculeeLe,_that.criteres);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PrimeDetail implements PrimeDetail {
  const _PrimeDetail({this.plancher = 0, this.merite = 0, @JsonKey(name: 'calculee_le') this.calculeeLe,  List<Critere> criteres = const <Critere>[]}): _criteres = criteres;
  factory _PrimeDetail.fromJson(Map<String, dynamic> json) => _$PrimeDetailFromJson(json);

@override@JsonKey() final  double plancher;
@override@JsonKey() final  double merite;
@override@JsonKey(name: 'calculee_le') final  DateTime? calculeeLe;
 final  List<Critere> _criteres;
@override@JsonKey() List<Critere> get criteres {
  if (_criteres is EqualUnmodifiableListView) return _criteres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_criteres);
}


/// Create a copy of PrimeDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PrimeDetailCopyWith<_PrimeDetail> get copyWith => __$PrimeDetailCopyWithImpl<_PrimeDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PrimeDetailToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PrimeDetail&&(identical(other.plancher, plancher) || other.plancher == plancher)&&(identical(other.merite, merite) || other.merite == merite)&&(identical(other.calculeeLe, calculeeLe) || other.calculeeLe == calculeeLe)&&const DeepCollectionEquality().equals(other.criteres, _criteres));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,plancher,merite,calculeeLe,const DeepCollectionEquality().hash(_criteres));
}

@override
String toString() {
    return 'PrimeDetail(plancher: $plancher, merite: $merite, calculeeLe: $calculeeLe, criteres: $criteres)';
}


}

/// @nodoc
abstract mixin class _$PrimeDetailCopyWith<$Res> implements $PrimeDetailCopyWith<$Res> {
  factory _$PrimeDetailCopyWith(_PrimeDetail value, $Res Function(_PrimeDetail) _then) = __$PrimeDetailCopyWithImpl;
@override @useResult
$Res call({
 double plancher, double merite,@JsonKey(name: 'calculee_le') DateTime? calculeeLe, List<Critere> criteres
});




}
/// @nodoc
class __$PrimeDetailCopyWithImpl<$Res>
    implements _$PrimeDetailCopyWith<$Res> {
  __$PrimeDetailCopyWithImpl(this._self, this._then);

  final _PrimeDetail _self;
  final $Res Function(_PrimeDetail) _then;

/// Create a copy of PrimeDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? plancher = null,Object? merite = null,Object? calculeeLe = freezed,Object? criteres = null,}) {
  return _then(_PrimeDetail(
plancher: null == plancher ? _self.plancher : plancher // ignore: cast_nullable_to_non_nullable
as double,merite: null == merite ? _self.merite : merite // ignore: cast_nullable_to_non_nullable
as double,calculeeLe: freezed == calculeeLe ? _self.calculeeLe : calculeeLe // ignore: cast_nullable_to_non_nullable
as DateTime?,criteres: null == criteres ? _self._criteres : criteres // ignore: cast_nullable_to_non_nullable
as List<Critere>,
  ));
}


}


/// @nodoc
mixin _$BulletinValide {

 int get version; double get brut;@JsonKey(name: 'valide_le') DateTime? get valideLe;@JsonKey(name: 'valide_par') String? get validePar;@JsonKey(name: 'a_jour') bool get aJour;
/// Create a copy of BulletinValide
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BulletinValideCopyWith<BulletinValide> get copyWith => _$BulletinValideCopyWithImpl<BulletinValide>(this as BulletinValide, _$identity);

  /// Serializes this BulletinValide to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BulletinValide;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BulletinValide&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.brut, _this.brut) || other.brut == _this.brut)&&(identical(other.valideLe, _this.valideLe) || other.valideLe == _this.valideLe)&&(identical(other.validePar, _this.validePar) || other.validePar == _this.validePar)&&(identical(other.aJour, _this.aJour) || other.aJour == _this.aJour));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BulletinValide;
  return Object.hash(runtimeType,_this.version,_this.brut,_this.valideLe,_this.validePar,_this.aJour);
}

@override
String toString() {
  final _this = this as BulletinValide;
  return 'BulletinValide(version: ${_this.version}, brut: ${_this.brut}, valideLe: ${_this.valideLe}, validePar: ${_this.validePar}, aJour: ${_this.aJour})';
}


}

/// @nodoc
abstract mixin class $BulletinValideCopyWith<$Res>  {
  factory $BulletinValideCopyWith(BulletinValide value, $Res Function(BulletinValide) _then) = _$BulletinValideCopyWithImpl;
@useResult
$Res call({
 int version, double brut,@JsonKey(name: 'valide_le') DateTime? valideLe,@JsonKey(name: 'valide_par') String? validePar,@JsonKey(name: 'a_jour') bool aJour
});




}
/// @nodoc
class _$BulletinValideCopyWithImpl<$Res>
    implements $BulletinValideCopyWith<$Res> {
  _$BulletinValideCopyWithImpl(this._self, this._then);

  final BulletinValide _self;
  final $Res Function(BulletinValide) _then;

/// Create a copy of BulletinValide
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? brut = null,Object? valideLe = freezed,Object? validePar = freezed,Object? aJour = null,}) {
  return _then(BulletinValide(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,brut: null == brut ? _self.brut : brut // ignore: cast_nullable_to_non_nullable
as double,valideLe: freezed == valideLe ? _self.valideLe : valideLe // ignore: cast_nullable_to_non_nullable
as DateTime?,validePar: freezed == validePar ? _self.validePar : validePar // ignore: cast_nullable_to_non_nullable
as String?,aJour: null == aJour ? _self.aJour : aJour // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [BulletinValide].
extension BulletinValidePatterns on BulletinValide {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BulletinValide value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BulletinValide() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BulletinValide value)  $default,){
final _that = this;
switch (_that) {
case _BulletinValide():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BulletinValide value)?  $default,){
final _that = this;
switch (_that) {
case _BulletinValide() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int version,  double brut, @JsonKey(name: 'valide_le')  DateTime? valideLe, @JsonKey(name: 'valide_par')  String? validePar, @JsonKey(name: 'a_jour')  bool aJour)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BulletinValide() when $default != null:
return $default(_that.version,_that.brut,_that.valideLe,_that.validePar,_that.aJour);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int version,  double brut, @JsonKey(name: 'valide_le')  DateTime? valideLe, @JsonKey(name: 'valide_par')  String? validePar, @JsonKey(name: 'a_jour')  bool aJour)  $default,) {final _that = this;
switch (_that) {
case _BulletinValide():
return $default(_that.version,_that.brut,_that.valideLe,_that.validePar,_that.aJour);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int version,  double brut, @JsonKey(name: 'valide_le')  DateTime? valideLe, @JsonKey(name: 'valide_par')  String? validePar, @JsonKey(name: 'a_jour')  bool aJour)?  $default,) {final _that = this;
switch (_that) {
case _BulletinValide() when $default != null:
return $default(_that.version,_that.brut,_that.valideLe,_that.validePar,_that.aJour);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BulletinValide implements BulletinValide {
  const _BulletinValide({this.version = 1, this.brut = 0, @JsonKey(name: 'valide_le') this.valideLe, @JsonKey(name: 'valide_par') this.validePar, @JsonKey(name: 'a_jour') this.aJour = true});
  factory _BulletinValide.fromJson(Map<String, dynamic> json) => _$BulletinValideFromJson(json);

@override@JsonKey() final  int version;
@override@JsonKey() final  double brut;
@override@JsonKey(name: 'valide_le') final  DateTime? valideLe;
@override@JsonKey(name: 'valide_par') final  String? validePar;
@override@JsonKey(name: 'a_jour') final  bool aJour;

/// Create a copy of BulletinValide
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BulletinValideCopyWith<_BulletinValide> get copyWith => __$BulletinValideCopyWithImpl<_BulletinValide>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BulletinValideToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BulletinValide&&(identical(other.version, version) || other.version == version)&&(identical(other.brut, brut) || other.brut == brut)&&(identical(other.valideLe, valideLe) || other.valideLe == valideLe)&&(identical(other.validePar, validePar) || other.validePar == validePar)&&(identical(other.aJour, aJour) || other.aJour == aJour));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,version,brut,valideLe,validePar,aJour);
}

@override
String toString() {
    return 'BulletinValide(version: $version, brut: $brut, valideLe: $valideLe, validePar: $validePar, aJour: $aJour)';
}


}

/// @nodoc
abstract mixin class _$BulletinValideCopyWith<$Res> implements $BulletinValideCopyWith<$Res> {
  factory _$BulletinValideCopyWith(_BulletinValide value, $Res Function(_BulletinValide) _then) = __$BulletinValideCopyWithImpl;
@override @useResult
$Res call({
 int version, double brut,@JsonKey(name: 'valide_le') DateTime? valideLe,@JsonKey(name: 'valide_par') String? validePar,@JsonKey(name: 'a_jour') bool aJour
});




}
/// @nodoc
class __$BulletinValideCopyWithImpl<$Res>
    implements _$BulletinValideCopyWith<$Res> {
  __$BulletinValideCopyWithImpl(this._self, this._then);

  final _BulletinValide _self;
  final $Res Function(_BulletinValide) _then;

/// Create a copy of BulletinValide
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? brut = null,Object? valideLe = freezed,Object? validePar = freezed,Object? aJour = null,}) {
  return _then(_BulletinValide(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,brut: null == brut ? _self.brut : brut // ignore: cast_nullable_to_non_nullable
as double,valideLe: freezed == valideLe ? _self.valideLe : valideLe // ignore: cast_nullable_to_non_nullable
as DateTime?,validePar: freezed == validePar ? _self.validePar : validePar // ignore: cast_nullable_to_non_nullable
as String?,aJour: null == aJour ? _self.aJour : aJour // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$PaieEmploye {

 EmployePaie get employe; JoursPaie get jours;@JsonKey(name: 'anciennete_annees') int get ancienneteAnnees;@JsonKey(name: 'heures_sup') double get heuresSup; List<LigneBulletin> get lignes;@JsonKey(name: 'part_fixe') double get partFixe;@JsonKey(name: 'part_variable') double get partVariable; PrimeDetail? get prime;@JsonKey(name: 'prime_validee') bool get primeValidee; double get brut;@JsonKey(name: 'a_verifier') List<String> get aVerifier; BulletinValide? get bulletin;
/// Create a copy of PaieEmploye
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaieEmployeCopyWith<PaieEmploye> get copyWith => _$PaieEmployeCopyWithImpl<PaieEmploye>(this as PaieEmploye, _$identity);

  /// Serializes this PaieEmploye to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PaieEmploye;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaieEmploye&&(identical(other.employe, _this.employe) || other.employe == _this.employe)&&(identical(other.jours, _this.jours) || other.jours == _this.jours)&&(identical(other.ancienneteAnnees, _this.ancienneteAnnees) || other.ancienneteAnnees == _this.ancienneteAnnees)&&(identical(other.heuresSup, _this.heuresSup) || other.heuresSup == _this.heuresSup)&&const DeepCollectionEquality().equals(other.lignes, _this.lignes)&&(identical(other.partFixe, _this.partFixe) || other.partFixe == _this.partFixe)&&(identical(other.partVariable, _this.partVariable) || other.partVariable == _this.partVariable)&&(identical(other.prime, _this.prime) || other.prime == _this.prime)&&(identical(other.primeValidee, _this.primeValidee) || other.primeValidee == _this.primeValidee)&&(identical(other.brut, _this.brut) || other.brut == _this.brut)&&const DeepCollectionEquality().equals(other.aVerifier, _this.aVerifier)&&(identical(other.bulletin, _this.bulletin) || other.bulletin == _this.bulletin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PaieEmploye;
  return Object.hash(runtimeType,_this.employe,_this.jours,_this.ancienneteAnnees,_this.heuresSup,const DeepCollectionEquality().hash(_this.lignes),_this.partFixe,_this.partVariable,_this.prime,_this.primeValidee,_this.brut,const DeepCollectionEquality().hash(_this.aVerifier),_this.bulletin);
}

@override
String toString() {
  final _this = this as PaieEmploye;
  return 'PaieEmploye(employe: ${_this.employe}, jours: ${_this.jours}, ancienneteAnnees: ${_this.ancienneteAnnees}, heuresSup: ${_this.heuresSup}, lignes: ${_this.lignes}, partFixe: ${_this.partFixe}, partVariable: ${_this.partVariable}, prime: ${_this.prime}, primeValidee: ${_this.primeValidee}, brut: ${_this.brut}, aVerifier: ${_this.aVerifier}, bulletin: ${_this.bulletin})';
}


}

/// @nodoc
abstract mixin class $PaieEmployeCopyWith<$Res>  {
  factory $PaieEmployeCopyWith(PaieEmploye value, $Res Function(PaieEmploye) _then) = _$PaieEmployeCopyWithImpl;
@useResult
$Res call({
 EmployePaie employe, JoursPaie jours,@JsonKey(name: 'anciennete_annees') int ancienneteAnnees,@JsonKey(name: 'heures_sup') double heuresSup, List<LigneBulletin> lignes,@JsonKey(name: 'part_fixe') double partFixe,@JsonKey(name: 'part_variable') double partVariable, PrimeDetail? prime,@JsonKey(name: 'prime_validee') bool primeValidee, double brut,@JsonKey(name: 'a_verifier') List<String> aVerifier, BulletinValide? bulletin
});


$EmployePaieCopyWith<$Res> get employe;$JoursPaieCopyWith<$Res> get jours;$PrimeDetailCopyWith<$Res>? get prime;$BulletinValideCopyWith<$Res>? get bulletin;

}
/// @nodoc
class _$PaieEmployeCopyWithImpl<$Res>
    implements $PaieEmployeCopyWith<$Res> {
  _$PaieEmployeCopyWithImpl(this._self, this._then);

  final PaieEmploye _self;
  final $Res Function(PaieEmploye) _then;

/// Create a copy of PaieEmploye
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? employe = null,Object? jours = null,Object? ancienneteAnnees = null,Object? heuresSup = null,Object? lignes = null,Object? partFixe = null,Object? partVariable = null,Object? prime = freezed,Object? primeValidee = null,Object? brut = null,Object? aVerifier = null,Object? bulletin = freezed,}) {
  return _then(PaieEmploye(
employe: null == employe ? _self.employe : employe // ignore: cast_nullable_to_non_nullable
as EmployePaie,jours: null == jours ? _self.jours : jours // ignore: cast_nullable_to_non_nullable
as JoursPaie,ancienneteAnnees: null == ancienneteAnnees ? _self.ancienneteAnnees : ancienneteAnnees // ignore: cast_nullable_to_non_nullable
as int,heuresSup: null == heuresSup ? _self.heuresSup : heuresSup // ignore: cast_nullable_to_non_nullable
as double,lignes: null == lignes ? _self.lignes : lignes // ignore: cast_nullable_to_non_nullable
as List<LigneBulletin>,partFixe: null == partFixe ? _self.partFixe : partFixe // ignore: cast_nullable_to_non_nullable
as double,partVariable: null == partVariable ? _self.partVariable : partVariable // ignore: cast_nullable_to_non_nullable
as double,prime: freezed == prime ? _self.prime : prime // ignore: cast_nullable_to_non_nullable
as PrimeDetail?,primeValidee: null == primeValidee ? _self.primeValidee : primeValidee // ignore: cast_nullable_to_non_nullable
as bool,brut: null == brut ? _self.brut : brut // ignore: cast_nullable_to_non_nullable
as double,aVerifier: null == aVerifier ? _self.aVerifier : aVerifier // ignore: cast_nullable_to_non_nullable
as List<String>,bulletin: freezed == bulletin ? _self.bulletin : bulletin // ignore: cast_nullable_to_non_nullable
as BulletinValide?,
  ));
}
/// Create a copy of PaieEmploye
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EmployePaieCopyWith<$Res> get employe {
  
  return $EmployePaieCopyWith<$Res>(_self.employe, (value) {
    return _then(_self.copyWith(employe: value));
  });
}/// Create a copy of PaieEmploye
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JoursPaieCopyWith<$Res> get jours {
  
  return $JoursPaieCopyWith<$Res>(_self.jours, (value) {
    return _then(_self.copyWith(jours: value));
  });
}/// Create a copy of PaieEmploye
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PrimeDetailCopyWith<$Res>? get prime {
    if (_self.prime == null) {
    return null;
  }

  return $PrimeDetailCopyWith<$Res>(_self.prime!, (value) {
    return _then(_self.copyWith(prime: value));
  });
}/// Create a copy of PaieEmploye
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BulletinValideCopyWith<$Res>? get bulletin {
    if (_self.bulletin == null) {
    return null;
  }

  return $BulletinValideCopyWith<$Res>(_self.bulletin!, (value) {
    return _then(_self.copyWith(bulletin: value));
  });
}
}


/// Adds pattern-matching-related methods to [PaieEmploye].
extension PaieEmployePatterns on PaieEmploye {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaieEmploye value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaieEmploye() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaieEmploye value)  $default,){
final _that = this;
switch (_that) {
case _PaieEmploye():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaieEmploye value)?  $default,){
final _that = this;
switch (_that) {
case _PaieEmploye() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EmployePaie employe,  JoursPaie jours, @JsonKey(name: 'anciennete_annees')  int ancienneteAnnees, @JsonKey(name: 'heures_sup')  double heuresSup,  List<LigneBulletin> lignes, @JsonKey(name: 'part_fixe')  double partFixe, @JsonKey(name: 'part_variable')  double partVariable,  PrimeDetail? prime, @JsonKey(name: 'prime_validee')  bool primeValidee,  double brut, @JsonKey(name: 'a_verifier')  List<String> aVerifier,  BulletinValide? bulletin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaieEmploye() when $default != null:
return $default(_that.employe,_that.jours,_that.ancienneteAnnees,_that.heuresSup,_that.lignes,_that.partFixe,_that.partVariable,_that.prime,_that.primeValidee,_that.brut,_that.aVerifier,_that.bulletin);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EmployePaie employe,  JoursPaie jours, @JsonKey(name: 'anciennete_annees')  int ancienneteAnnees, @JsonKey(name: 'heures_sup')  double heuresSup,  List<LigneBulletin> lignes, @JsonKey(name: 'part_fixe')  double partFixe, @JsonKey(name: 'part_variable')  double partVariable,  PrimeDetail? prime, @JsonKey(name: 'prime_validee')  bool primeValidee,  double brut, @JsonKey(name: 'a_verifier')  List<String> aVerifier,  BulletinValide? bulletin)  $default,) {final _that = this;
switch (_that) {
case _PaieEmploye():
return $default(_that.employe,_that.jours,_that.ancienneteAnnees,_that.heuresSup,_that.lignes,_that.partFixe,_that.partVariable,_that.prime,_that.primeValidee,_that.brut,_that.aVerifier,_that.bulletin);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EmployePaie employe,  JoursPaie jours, @JsonKey(name: 'anciennete_annees')  int ancienneteAnnees, @JsonKey(name: 'heures_sup')  double heuresSup,  List<LigneBulletin> lignes, @JsonKey(name: 'part_fixe')  double partFixe, @JsonKey(name: 'part_variable')  double partVariable,  PrimeDetail? prime, @JsonKey(name: 'prime_validee')  bool primeValidee,  double brut, @JsonKey(name: 'a_verifier')  List<String> aVerifier,  BulletinValide? bulletin)?  $default,) {final _that = this;
switch (_that) {
case _PaieEmploye() when $default != null:
return $default(_that.employe,_that.jours,_that.ancienneteAnnees,_that.heuresSup,_that.lignes,_that.partFixe,_that.partVariable,_that.prime,_that.primeValidee,_that.brut,_that.aVerifier,_that.bulletin);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaieEmploye extends PaieEmploye {
  const _PaieEmploye({required this.employe, this.jours = const JoursPaie(), @JsonKey(name: 'anciennete_annees') this.ancienneteAnnees = 0, @JsonKey(name: 'heures_sup') this.heuresSup = 0,  List<LigneBulletin> lignes = const <LigneBulletin>[], @JsonKey(name: 'part_fixe') this.partFixe = 0, @JsonKey(name: 'part_variable') this.partVariable = 0, this.prime, @JsonKey(name: 'prime_validee') this.primeValidee = false, this.brut = 0, @JsonKey(name: 'a_verifier')  List<String> aVerifier = const <String>[], this.bulletin}): _lignes = lignes,_aVerifier = aVerifier,super._();
  factory _PaieEmploye.fromJson(Map<String, dynamic> json) => _$PaieEmployeFromJson(json);

@override final  EmployePaie employe;
@override@JsonKey() final  JoursPaie jours;
@override@JsonKey(name: 'anciennete_annees') final  int ancienneteAnnees;
@override@JsonKey(name: 'heures_sup') final  double heuresSup;
 final  List<LigneBulletin> _lignes;
@override@JsonKey() List<LigneBulletin> get lignes {
  if (_lignes is EqualUnmodifiableListView) return _lignes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lignes);
}

@override@JsonKey(name: 'part_fixe') final  double partFixe;
@override@JsonKey(name: 'part_variable') final  double partVariable;
@override final  PrimeDetail? prime;
@override@JsonKey(name: 'prime_validee') final  bool primeValidee;
@override@JsonKey() final  double brut;
 final  List<String> _aVerifier;
@override@JsonKey(name: 'a_verifier') List<String> get aVerifier {
  if (_aVerifier is EqualUnmodifiableListView) return _aVerifier;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_aVerifier);
}

@override final  BulletinValide? bulletin;

/// Create a copy of PaieEmploye
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaieEmployeCopyWith<_PaieEmploye> get copyWith => __$PaieEmployeCopyWithImpl<_PaieEmploye>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaieEmployeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaieEmploye&&(identical(other.employe, employe) || other.employe == employe)&&(identical(other.jours, jours) || other.jours == jours)&&(identical(other.ancienneteAnnees, ancienneteAnnees) || other.ancienneteAnnees == ancienneteAnnees)&&(identical(other.heuresSup, heuresSup) || other.heuresSup == heuresSup)&&const DeepCollectionEquality().equals(other.lignes, _lignes)&&(identical(other.partFixe, partFixe) || other.partFixe == partFixe)&&(identical(other.partVariable, partVariable) || other.partVariable == partVariable)&&(identical(other.prime, prime) || other.prime == prime)&&(identical(other.primeValidee, primeValidee) || other.primeValidee == primeValidee)&&(identical(other.brut, brut) || other.brut == brut)&&const DeepCollectionEquality().equals(other.aVerifier, _aVerifier)&&(identical(other.bulletin, bulletin) || other.bulletin == bulletin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,employe,jours,ancienneteAnnees,heuresSup,const DeepCollectionEquality().hash(_lignes),partFixe,partVariable,prime,primeValidee,brut,const DeepCollectionEquality().hash(_aVerifier),bulletin);
}

@override
String toString() {
    return 'PaieEmploye(employe: $employe, jours: $jours, ancienneteAnnees: $ancienneteAnnees, heuresSup: $heuresSup, lignes: $lignes, partFixe: $partFixe, partVariable: $partVariable, prime: $prime, primeValidee: $primeValidee, brut: $brut, aVerifier: $aVerifier, bulletin: $bulletin)';
}


}

/// @nodoc
abstract mixin class _$PaieEmployeCopyWith<$Res> implements $PaieEmployeCopyWith<$Res> {
  factory _$PaieEmployeCopyWith(_PaieEmploye value, $Res Function(_PaieEmploye) _then) = __$PaieEmployeCopyWithImpl;
@override @useResult
$Res call({
 EmployePaie employe, JoursPaie jours,@JsonKey(name: 'anciennete_annees') int ancienneteAnnees,@JsonKey(name: 'heures_sup') double heuresSup, List<LigneBulletin> lignes,@JsonKey(name: 'part_fixe') double partFixe,@JsonKey(name: 'part_variable') double partVariable, PrimeDetail? prime,@JsonKey(name: 'prime_validee') bool primeValidee, double brut,@JsonKey(name: 'a_verifier') List<String> aVerifier, BulletinValide? bulletin
});


@override $EmployePaieCopyWith<$Res> get employe;@override $JoursPaieCopyWith<$Res> get jours;@override $PrimeDetailCopyWith<$Res>? get prime;@override $BulletinValideCopyWith<$Res>? get bulletin;

}
/// @nodoc
class __$PaieEmployeCopyWithImpl<$Res>
    implements _$PaieEmployeCopyWith<$Res> {
  __$PaieEmployeCopyWithImpl(this._self, this._then);

  final _PaieEmploye _self;
  final $Res Function(_PaieEmploye) _then;

/// Create a copy of PaieEmploye
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? employe = null,Object? jours = null,Object? ancienneteAnnees = null,Object? heuresSup = null,Object? lignes = null,Object? partFixe = null,Object? partVariable = null,Object? prime = freezed,Object? primeValidee = null,Object? brut = null,Object? aVerifier = null,Object? bulletin = freezed,}) {
  return _then(_PaieEmploye(
employe: null == employe ? _self.employe : employe // ignore: cast_nullable_to_non_nullable
as EmployePaie,jours: null == jours ? _self.jours : jours // ignore: cast_nullable_to_non_nullable
as JoursPaie,ancienneteAnnees: null == ancienneteAnnees ? _self.ancienneteAnnees : ancienneteAnnees // ignore: cast_nullable_to_non_nullable
as int,heuresSup: null == heuresSup ? _self.heuresSup : heuresSup // ignore: cast_nullable_to_non_nullable
as double,lignes: null == lignes ? _self._lignes : lignes // ignore: cast_nullable_to_non_nullable
as List<LigneBulletin>,partFixe: null == partFixe ? _self.partFixe : partFixe // ignore: cast_nullable_to_non_nullable
as double,partVariable: null == partVariable ? _self.partVariable : partVariable // ignore: cast_nullable_to_non_nullable
as double,prime: freezed == prime ? _self.prime : prime // ignore: cast_nullable_to_non_nullable
as PrimeDetail?,primeValidee: null == primeValidee ? _self.primeValidee : primeValidee // ignore: cast_nullable_to_non_nullable
as bool,brut: null == brut ? _self.brut : brut // ignore: cast_nullable_to_non_nullable
as double,aVerifier: null == aVerifier ? _self._aVerifier : aVerifier // ignore: cast_nullable_to_non_nullable
as List<String>,bulletin: freezed == bulletin ? _self.bulletin : bulletin // ignore: cast_nullable_to_non_nullable
as BulletinValide?,
  ));
}

/// Create a copy of PaieEmploye
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EmployePaieCopyWith<$Res> get employe {
  
  return $EmployePaieCopyWith<$Res>(_self.employe, (value) {
    return _then(_self.copyWith(employe: value));
  });
}/// Create a copy of PaieEmploye
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JoursPaieCopyWith<$Res> get jours {
  
  return $JoursPaieCopyWith<$Res>(_self.jours, (value) {
    return _then(_self.copyWith(jours: value));
  });
}/// Create a copy of PaieEmploye
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PrimeDetailCopyWith<$Res>? get prime {
    if (_self.prime == null) {
    return null;
  }

  return $PrimeDetailCopyWith<$Res>(_self.prime!, (value) {
    return _then(_self.copyWith(prime: value));
  });
}/// Create a copy of PaieEmploye
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BulletinValideCopyWith<$Res>? get bulletin {
    if (_self.bulletin == null) {
    return null;
  }

  return $BulletinValideCopyWith<$Res>(_self.bulletin!, (value) {
    return _then(_self.copyWith(bulletin: value));
  });
}
}


/// @nodoc
mixin _$TotauxPaie {

@JsonKey(name: 'part_fixe') double get partFixe;@JsonKey(name: 'part_variable') double get partVariable; double get brut;
/// Create a copy of TotauxPaie
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TotauxPaieCopyWith<TotauxPaie> get copyWith => _$TotauxPaieCopyWithImpl<TotauxPaie>(this as TotauxPaie, _$identity);

  /// Serializes this TotauxPaie to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TotauxPaie;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TotauxPaie&&(identical(other.partFixe, _this.partFixe) || other.partFixe == _this.partFixe)&&(identical(other.partVariable, _this.partVariable) || other.partVariable == _this.partVariable)&&(identical(other.brut, _this.brut) || other.brut == _this.brut));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TotauxPaie;
  return Object.hash(runtimeType,_this.partFixe,_this.partVariable,_this.brut);
}

@override
String toString() {
  final _this = this as TotauxPaie;
  return 'TotauxPaie(partFixe: ${_this.partFixe}, partVariable: ${_this.partVariable}, brut: ${_this.brut})';
}


}

/// @nodoc
abstract mixin class $TotauxPaieCopyWith<$Res>  {
  factory $TotauxPaieCopyWith(TotauxPaie value, $Res Function(TotauxPaie) _then) = _$TotauxPaieCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'part_fixe') double partFixe,@JsonKey(name: 'part_variable') double partVariable, double brut
});




}
/// @nodoc
class _$TotauxPaieCopyWithImpl<$Res>
    implements $TotauxPaieCopyWith<$Res> {
  _$TotauxPaieCopyWithImpl(this._self, this._then);

  final TotauxPaie _self;
  final $Res Function(TotauxPaie) _then;

/// Create a copy of TotauxPaie
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? partFixe = null,Object? partVariable = null,Object? brut = null,}) {
  return _then(TotauxPaie(
partFixe: null == partFixe ? _self.partFixe : partFixe // ignore: cast_nullable_to_non_nullable
as double,partVariable: null == partVariable ? _self.partVariable : partVariable // ignore: cast_nullable_to_non_nullable
as double,brut: null == brut ? _self.brut : brut // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [TotauxPaie].
extension TotauxPaiePatterns on TotauxPaie {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TotauxPaie value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TotauxPaie() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TotauxPaie value)  $default,){
final _that = this;
switch (_that) {
case _TotauxPaie():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TotauxPaie value)?  $default,){
final _that = this;
switch (_that) {
case _TotauxPaie() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'part_fixe')  double partFixe, @JsonKey(name: 'part_variable')  double partVariable,  double brut)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TotauxPaie() when $default != null:
return $default(_that.partFixe,_that.partVariable,_that.brut);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'part_fixe')  double partFixe, @JsonKey(name: 'part_variable')  double partVariable,  double brut)  $default,) {final _that = this;
switch (_that) {
case _TotauxPaie():
return $default(_that.partFixe,_that.partVariable,_that.brut);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'part_fixe')  double partFixe, @JsonKey(name: 'part_variable')  double partVariable,  double brut)?  $default,) {final _that = this;
switch (_that) {
case _TotauxPaie() when $default != null:
return $default(_that.partFixe,_that.partVariable,_that.brut);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TotauxPaie implements TotauxPaie {
  const _TotauxPaie({@JsonKey(name: 'part_fixe') this.partFixe = 0, @JsonKey(name: 'part_variable') this.partVariable = 0, this.brut = 0});
  factory _TotauxPaie.fromJson(Map<String, dynamic> json) => _$TotauxPaieFromJson(json);

@override@JsonKey(name: 'part_fixe') final  double partFixe;
@override@JsonKey(name: 'part_variable') final  double partVariable;
@override@JsonKey() final  double brut;

/// Create a copy of TotauxPaie
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TotauxPaieCopyWith<_TotauxPaie> get copyWith => __$TotauxPaieCopyWithImpl<_TotauxPaie>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TotauxPaieToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TotauxPaie&&(identical(other.partFixe, partFixe) || other.partFixe == partFixe)&&(identical(other.partVariable, partVariable) || other.partVariable == partVariable)&&(identical(other.brut, brut) || other.brut == brut));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,partFixe,partVariable,brut);
}

@override
String toString() {
    return 'TotauxPaie(partFixe: $partFixe, partVariable: $partVariable, brut: $brut)';
}


}

/// @nodoc
abstract mixin class _$TotauxPaieCopyWith<$Res> implements $TotauxPaieCopyWith<$Res> {
  factory _$TotauxPaieCopyWith(_TotauxPaie value, $Res Function(_TotauxPaie) _then) = __$TotauxPaieCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'part_fixe') double partFixe,@JsonKey(name: 'part_variable') double partVariable, double brut
});




}
/// @nodoc
class __$TotauxPaieCopyWithImpl<$Res>
    implements _$TotauxPaieCopyWith<$Res> {
  __$TotauxPaieCopyWithImpl(this._self, this._then);

  final _TotauxPaie _self;
  final $Res Function(_TotauxPaie) _then;

/// Create a copy of TotauxPaie
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? partFixe = null,Object? partVariable = null,Object? brut = null,}) {
  return _then(_TotauxPaie(
partFixe: null == partFixe ? _self.partFixe : partFixe // ignore: cast_nullable_to_non_nullable
as double,partVariable: null == partVariable ? _self.partVariable : partVariable // ignore: cast_nullable_to_non_nullable
as double,brut: null == brut ? _self.brut : brut // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$ReglesPaie {

@JsonKey(name: 'transport_jour') double get transportJour;@JsonKey(name: 'panier_jour') double get panierJour;@JsonKey(name: 'anciennete_an') double get ancienneteAn;@JsonKey(name: 'majoration_hs') double get majorationHs;@JsonKey(name: 'heures_mois') double get heuresMois;
/// Create a copy of ReglesPaie
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReglesPaieCopyWith<ReglesPaie> get copyWith => _$ReglesPaieCopyWithImpl<ReglesPaie>(this as ReglesPaie, _$identity);

  /// Serializes this ReglesPaie to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ReglesPaie;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReglesPaie&&(identical(other.transportJour, _this.transportJour) || other.transportJour == _this.transportJour)&&(identical(other.panierJour, _this.panierJour) || other.panierJour == _this.panierJour)&&(identical(other.ancienneteAn, _this.ancienneteAn) || other.ancienneteAn == _this.ancienneteAn)&&(identical(other.majorationHs, _this.majorationHs) || other.majorationHs == _this.majorationHs)&&(identical(other.heuresMois, _this.heuresMois) || other.heuresMois == _this.heuresMois));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ReglesPaie;
  return Object.hash(runtimeType,_this.transportJour,_this.panierJour,_this.ancienneteAn,_this.majorationHs,_this.heuresMois);
}

@override
String toString() {
  final _this = this as ReglesPaie;
  return 'ReglesPaie(transportJour: ${_this.transportJour}, panierJour: ${_this.panierJour}, ancienneteAn: ${_this.ancienneteAn}, majorationHs: ${_this.majorationHs}, heuresMois: ${_this.heuresMois})';
}


}

/// @nodoc
abstract mixin class $ReglesPaieCopyWith<$Res>  {
  factory $ReglesPaieCopyWith(ReglesPaie value, $Res Function(ReglesPaie) _then) = _$ReglesPaieCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'transport_jour') double transportJour,@JsonKey(name: 'panier_jour') double panierJour,@JsonKey(name: 'anciennete_an') double ancienneteAn,@JsonKey(name: 'majoration_hs') double majorationHs,@JsonKey(name: 'heures_mois') double heuresMois
});




}
/// @nodoc
class _$ReglesPaieCopyWithImpl<$Res>
    implements $ReglesPaieCopyWith<$Res> {
  _$ReglesPaieCopyWithImpl(this._self, this._then);

  final ReglesPaie _self;
  final $Res Function(ReglesPaie) _then;

/// Create a copy of ReglesPaie
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? transportJour = null,Object? panierJour = null,Object? ancienneteAn = null,Object? majorationHs = null,Object? heuresMois = null,}) {
  return _then(ReglesPaie(
transportJour: null == transportJour ? _self.transportJour : transportJour // ignore: cast_nullable_to_non_nullable
as double,panierJour: null == panierJour ? _self.panierJour : panierJour // ignore: cast_nullable_to_non_nullable
as double,ancienneteAn: null == ancienneteAn ? _self.ancienneteAn : ancienneteAn // ignore: cast_nullable_to_non_nullable
as double,majorationHs: null == majorationHs ? _self.majorationHs : majorationHs // ignore: cast_nullable_to_non_nullable
as double,heuresMois: null == heuresMois ? _self.heuresMois : heuresMois // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ReglesPaie].
extension ReglesPaiePatterns on ReglesPaie {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReglesPaie value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReglesPaie() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReglesPaie value)  $default,){
final _that = this;
switch (_that) {
case _ReglesPaie():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReglesPaie value)?  $default,){
final _that = this;
switch (_that) {
case _ReglesPaie() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'transport_jour')  double transportJour, @JsonKey(name: 'panier_jour')  double panierJour, @JsonKey(name: 'anciennete_an')  double ancienneteAn, @JsonKey(name: 'majoration_hs')  double majorationHs, @JsonKey(name: 'heures_mois')  double heuresMois)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReglesPaie() when $default != null:
return $default(_that.transportJour,_that.panierJour,_that.ancienneteAn,_that.majorationHs,_that.heuresMois);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'transport_jour')  double transportJour, @JsonKey(name: 'panier_jour')  double panierJour, @JsonKey(name: 'anciennete_an')  double ancienneteAn, @JsonKey(name: 'majoration_hs')  double majorationHs, @JsonKey(name: 'heures_mois')  double heuresMois)  $default,) {final _that = this;
switch (_that) {
case _ReglesPaie():
return $default(_that.transportJour,_that.panierJour,_that.ancienneteAn,_that.majorationHs,_that.heuresMois);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'transport_jour')  double transportJour, @JsonKey(name: 'panier_jour')  double panierJour, @JsonKey(name: 'anciennete_an')  double ancienneteAn, @JsonKey(name: 'majoration_hs')  double majorationHs, @JsonKey(name: 'heures_mois')  double heuresMois)?  $default,) {final _that = this;
switch (_that) {
case _ReglesPaie() when $default != null:
return $default(_that.transportJour,_that.panierJour,_that.ancienneteAn,_that.majorationHs,_that.heuresMois);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReglesPaie implements ReglesPaie {
  const _ReglesPaie({@JsonKey(name: 'transport_jour') this.transportJour = 300, @JsonKey(name: 'panier_jour') this.panierJour = 600, @JsonKey(name: 'anciennete_an') this.ancienneteAn = 1000, @JsonKey(name: 'majoration_hs') this.majorationHs = 1.5, @JsonKey(name: 'heures_mois') this.heuresMois = 173.33});
  factory _ReglesPaie.fromJson(Map<String, dynamic> json) => _$ReglesPaieFromJson(json);

@override@JsonKey(name: 'transport_jour') final  double transportJour;
@override@JsonKey(name: 'panier_jour') final  double panierJour;
@override@JsonKey(name: 'anciennete_an') final  double ancienneteAn;
@override@JsonKey(name: 'majoration_hs') final  double majorationHs;
@override@JsonKey(name: 'heures_mois') final  double heuresMois;

/// Create a copy of ReglesPaie
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReglesPaieCopyWith<_ReglesPaie> get copyWith => __$ReglesPaieCopyWithImpl<_ReglesPaie>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReglesPaieToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReglesPaie&&(identical(other.transportJour, transportJour) || other.transportJour == transportJour)&&(identical(other.panierJour, panierJour) || other.panierJour == panierJour)&&(identical(other.ancienneteAn, ancienneteAn) || other.ancienneteAn == ancienneteAn)&&(identical(other.majorationHs, majorationHs) || other.majorationHs == majorationHs)&&(identical(other.heuresMois, heuresMois) || other.heuresMois == heuresMois));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,transportJour,panierJour,ancienneteAn,majorationHs,heuresMois);
}

@override
String toString() {
    return 'ReglesPaie(transportJour: $transportJour, panierJour: $panierJour, ancienneteAn: $ancienneteAn, majorationHs: $majorationHs, heuresMois: $heuresMois)';
}


}

/// @nodoc
abstract mixin class _$ReglesPaieCopyWith<$Res> implements $ReglesPaieCopyWith<$Res> {
  factory _$ReglesPaieCopyWith(_ReglesPaie value, $Res Function(_ReglesPaie) _then) = __$ReglesPaieCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'transport_jour') double transportJour,@JsonKey(name: 'panier_jour') double panierJour,@JsonKey(name: 'anciennete_an') double ancienneteAn,@JsonKey(name: 'majoration_hs') double majorationHs,@JsonKey(name: 'heures_mois') double heuresMois
});




}
/// @nodoc
class __$ReglesPaieCopyWithImpl<$Res>
    implements _$ReglesPaieCopyWith<$Res> {
  __$ReglesPaieCopyWithImpl(this._self, this._then);

  final _ReglesPaie _self;
  final $Res Function(_ReglesPaie) _then;

/// Create a copy of ReglesPaie
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? transportJour = null,Object? panierJour = null,Object? ancienneteAn = null,Object? majorationHs = null,Object? heuresMois = null,}) {
  return _then(_ReglesPaie(
transportJour: null == transportJour ? _self.transportJour : transportJour // ignore: cast_nullable_to_non_nullable
as double,panierJour: null == panierJour ? _self.panierJour : panierJour // ignore: cast_nullable_to_non_nullable
as double,ancienneteAn: null == ancienneteAn ? _self.ancienneteAn : ancienneteAn // ignore: cast_nullable_to_non_nullable
as double,majorationHs: null == majorationHs ? _self.majorationHs : majorationHs // ignore: cast_nullable_to_non_nullable
as double,heuresMois: null == heuresMois ? _self.heuresMois : heuresMois // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$PaieMois {

 int get annee; int get mois; List<PaieEmploye> get employes; TotauxPaie get totaux; double? get enveloppe; ReglesPaie get regles;
/// Create a copy of PaieMois
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaieMoisCopyWith<PaieMois> get copyWith => _$PaieMoisCopyWithImpl<PaieMois>(this as PaieMois, _$identity);

  /// Serializes this PaieMois to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PaieMois;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaieMois&&(identical(other.annee, _this.annee) || other.annee == _this.annee)&&(identical(other.mois, _this.mois) || other.mois == _this.mois)&&const DeepCollectionEquality().equals(other.employes, _this.employes)&&(identical(other.totaux, _this.totaux) || other.totaux == _this.totaux)&&(identical(other.enveloppe, _this.enveloppe) || other.enveloppe == _this.enveloppe)&&(identical(other.regles, _this.regles) || other.regles == _this.regles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PaieMois;
  return Object.hash(runtimeType,_this.annee,_this.mois,const DeepCollectionEquality().hash(_this.employes),_this.totaux,_this.enveloppe,_this.regles);
}

@override
String toString() {
  final _this = this as PaieMois;
  return 'PaieMois(annee: ${_this.annee}, mois: ${_this.mois}, employes: ${_this.employes}, totaux: ${_this.totaux}, enveloppe: ${_this.enveloppe}, regles: ${_this.regles})';
}


}

/// @nodoc
abstract mixin class $PaieMoisCopyWith<$Res>  {
  factory $PaieMoisCopyWith(PaieMois value, $Res Function(PaieMois) _then) = _$PaieMoisCopyWithImpl;
@useResult
$Res call({
 int annee, int mois, List<PaieEmploye> employes, TotauxPaie totaux, double? enveloppe, ReglesPaie regles
});


$TotauxPaieCopyWith<$Res> get totaux;$ReglesPaieCopyWith<$Res> get regles;

}
/// @nodoc
class _$PaieMoisCopyWithImpl<$Res>
    implements $PaieMoisCopyWith<$Res> {
  _$PaieMoisCopyWithImpl(this._self, this._then);

  final PaieMois _self;
  final $Res Function(PaieMois) _then;

/// Create a copy of PaieMois
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? annee = null,Object? mois = null,Object? employes = null,Object? totaux = null,Object? enveloppe = freezed,Object? regles = null,}) {
  return _then(PaieMois(
annee: null == annee ? _self.annee : annee // ignore: cast_nullable_to_non_nullable
as int,mois: null == mois ? _self.mois : mois // ignore: cast_nullable_to_non_nullable
as int,employes: null == employes ? _self.employes : employes // ignore: cast_nullable_to_non_nullable
as List<PaieEmploye>,totaux: null == totaux ? _self.totaux : totaux // ignore: cast_nullable_to_non_nullable
as TotauxPaie,enveloppe: freezed == enveloppe ? _self.enveloppe : enveloppe // ignore: cast_nullable_to_non_nullable
as double?,regles: null == regles ? _self.regles : regles // ignore: cast_nullable_to_non_nullable
as ReglesPaie,
  ));
}
/// Create a copy of PaieMois
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TotauxPaieCopyWith<$Res> get totaux {
  
  return $TotauxPaieCopyWith<$Res>(_self.totaux, (value) {
    return _then(_self.copyWith(totaux: value));
  });
}/// Create a copy of PaieMois
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReglesPaieCopyWith<$Res> get regles {
  
  return $ReglesPaieCopyWith<$Res>(_self.regles, (value) {
    return _then(_self.copyWith(regles: value));
  });
}
}


/// Adds pattern-matching-related methods to [PaieMois].
extension PaieMoisPatterns on PaieMois {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaieMois value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaieMois() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaieMois value)  $default,){
final _that = this;
switch (_that) {
case _PaieMois():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaieMois value)?  $default,){
final _that = this;
switch (_that) {
case _PaieMois() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int annee,  int mois,  List<PaieEmploye> employes,  TotauxPaie totaux,  double? enveloppe,  ReglesPaie regles)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaieMois() when $default != null:
return $default(_that.annee,_that.mois,_that.employes,_that.totaux,_that.enveloppe,_that.regles);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int annee,  int mois,  List<PaieEmploye> employes,  TotauxPaie totaux,  double? enveloppe,  ReglesPaie regles)  $default,) {final _that = this;
switch (_that) {
case _PaieMois():
return $default(_that.annee,_that.mois,_that.employes,_that.totaux,_that.enveloppe,_that.regles);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int annee,  int mois,  List<PaieEmploye> employes,  TotauxPaie totaux,  double? enveloppe,  ReglesPaie regles)?  $default,) {final _that = this;
switch (_that) {
case _PaieMois() when $default != null:
return $default(_that.annee,_that.mois,_that.employes,_that.totaux,_that.enveloppe,_that.regles);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaieMois extends PaieMois {
  const _PaieMois({required this.annee, required this.mois,  List<PaieEmploye> employes = const <PaieEmploye>[], this.totaux = const TotauxPaie(), this.enveloppe, this.regles = const ReglesPaie()}): _employes = employes,super._();
  factory _PaieMois.fromJson(Map<String, dynamic> json) => _$PaieMoisFromJson(json);

@override final  int annee;
@override final  int mois;
 final  List<PaieEmploye> _employes;
@override@JsonKey() List<PaieEmploye> get employes {
  if (_employes is EqualUnmodifiableListView) return _employes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_employes);
}

@override@JsonKey() final  TotauxPaie totaux;
@override final  double? enveloppe;
@override@JsonKey() final  ReglesPaie regles;

/// Create a copy of PaieMois
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaieMoisCopyWith<_PaieMois> get copyWith => __$PaieMoisCopyWithImpl<_PaieMois>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaieMoisToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaieMois&&(identical(other.annee, annee) || other.annee == annee)&&(identical(other.mois, mois) || other.mois == mois)&&const DeepCollectionEquality().equals(other.employes, _employes)&&(identical(other.totaux, totaux) || other.totaux == totaux)&&(identical(other.enveloppe, enveloppe) || other.enveloppe == enveloppe)&&(identical(other.regles, regles) || other.regles == regles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,annee,mois,const DeepCollectionEquality().hash(_employes),totaux,enveloppe,regles);
}

@override
String toString() {
    return 'PaieMois(annee: $annee, mois: $mois, employes: $employes, totaux: $totaux, enveloppe: $enveloppe, regles: $regles)';
}


}

/// @nodoc
abstract mixin class _$PaieMoisCopyWith<$Res> implements $PaieMoisCopyWith<$Res> {
  factory _$PaieMoisCopyWith(_PaieMois value, $Res Function(_PaieMois) _then) = __$PaieMoisCopyWithImpl;
@override @useResult
$Res call({
 int annee, int mois, List<PaieEmploye> employes, TotauxPaie totaux, double? enveloppe, ReglesPaie regles
});


@override $TotauxPaieCopyWith<$Res> get totaux;@override $ReglesPaieCopyWith<$Res> get regles;

}
/// @nodoc
class __$PaieMoisCopyWithImpl<$Res>
    implements _$PaieMoisCopyWith<$Res> {
  __$PaieMoisCopyWithImpl(this._self, this._then);

  final _PaieMois _self;
  final $Res Function(_PaieMois) _then;

/// Create a copy of PaieMois
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? annee = null,Object? mois = null,Object? employes = null,Object? totaux = null,Object? enveloppe = freezed,Object? regles = null,}) {
  return _then(_PaieMois(
annee: null == annee ? _self.annee : annee // ignore: cast_nullable_to_non_nullable
as int,mois: null == mois ? _self.mois : mois // ignore: cast_nullable_to_non_nullable
as int,employes: null == employes ? _self._employes : employes // ignore: cast_nullable_to_non_nullable
as List<PaieEmploye>,totaux: null == totaux ? _self.totaux : totaux // ignore: cast_nullable_to_non_nullable
as TotauxPaie,enveloppe: freezed == enveloppe ? _self.enveloppe : enveloppe // ignore: cast_nullable_to_non_nullable
as double?,regles: null == regles ? _self.regles : regles // ignore: cast_nullable_to_non_nullable
as ReglesPaie,
  ));
}

/// Create a copy of PaieMois
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TotauxPaieCopyWith<$Res> get totaux {
  
  return $TotauxPaieCopyWith<$Res>(_self.totaux, (value) {
    return _then(_self.copyWith(totaux: value));
  });
}/// Create a copy of PaieMois
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReglesPaieCopyWith<$Res> get regles {
  
  return $ReglesPaieCopyWith<$Res>(_self.regles, (value) {
    return _then(_self.copyWith(regles: value));
  });
}
}

// dart format on
