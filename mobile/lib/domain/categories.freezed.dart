// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'categories.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CategorieMois {

 String? get categorie;@JsonKey(name: 'taux_pct') double get tauxPct; double get ca; int get produits; double get montant;
/// Create a copy of CategorieMois
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategorieMoisCopyWith<CategorieMois> get copyWith => _$CategorieMoisCopyWithImpl<CategorieMois>(this as CategorieMois, _$identity);

  /// Serializes this CategorieMois to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CategorieMois;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategorieMois&&(identical(other.categorie, _this.categorie) || other.categorie == _this.categorie)&&(identical(other.tauxPct, _this.tauxPct) || other.tauxPct == _this.tauxPct)&&(identical(other.ca, _this.ca) || other.ca == _this.ca)&&(identical(other.produits, _this.produits) || other.produits == _this.produits)&&(identical(other.montant, _this.montant) || other.montant == _this.montant));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CategorieMois;
  return Object.hash(runtimeType,_this.categorie,_this.tauxPct,_this.ca,_this.produits,_this.montant);
}

@override
String toString() {
  final _this = this as CategorieMois;
  return 'CategorieMois(categorie: ${_this.categorie}, tauxPct: ${_this.tauxPct}, ca: ${_this.ca}, produits: ${_this.produits}, montant: ${_this.montant})';
}


}

/// @nodoc
abstract mixin class $CategorieMoisCopyWith<$Res>  {
  factory $CategorieMoisCopyWith(CategorieMois value, $Res Function(CategorieMois) _then) = _$CategorieMoisCopyWithImpl;
@useResult
$Res call({
 String? categorie,@JsonKey(name: 'taux_pct') double tauxPct, double ca, int produits, double montant
});




}
/// @nodoc
class _$CategorieMoisCopyWithImpl<$Res>
    implements $CategorieMoisCopyWith<$Res> {
  _$CategorieMoisCopyWithImpl(this._self, this._then);

  final CategorieMois _self;
  final $Res Function(CategorieMois) _then;

/// Create a copy of CategorieMois
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categorie = freezed,Object? tauxPct = null,Object? ca = null,Object? produits = null,Object? montant = null,}) {
  return _then(CategorieMois(
categorie: freezed == categorie ? _self.categorie : categorie // ignore: cast_nullable_to_non_nullable
as String?,tauxPct: null == tauxPct ? _self.tauxPct : tauxPct // ignore: cast_nullable_to_non_nullable
as double,ca: null == ca ? _self.ca : ca // ignore: cast_nullable_to_non_nullable
as double,produits: null == produits ? _self.produits : produits // ignore: cast_nullable_to_non_nullable
as int,montant: null == montant ? _self.montant : montant // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [CategorieMois].
extension CategorieMoisPatterns on CategorieMois {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategorieMois value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategorieMois() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategorieMois value)  $default,){
final _that = this;
switch (_that) {
case _CategorieMois():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategorieMois value)?  $default,){
final _that = this;
switch (_that) {
case _CategorieMois() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? categorie, @JsonKey(name: 'taux_pct')  double tauxPct,  double ca,  int produits,  double montant)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategorieMois() when $default != null:
return $default(_that.categorie,_that.tauxPct,_that.ca,_that.produits,_that.montant);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? categorie, @JsonKey(name: 'taux_pct')  double tauxPct,  double ca,  int produits,  double montant)  $default,) {final _that = this;
switch (_that) {
case _CategorieMois():
return $default(_that.categorie,_that.tauxPct,_that.ca,_that.produits,_that.montant);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? categorie, @JsonKey(name: 'taux_pct')  double tauxPct,  double ca,  int produits,  double montant)?  $default,) {final _that = this;
switch (_that) {
case _CategorieMois() when $default != null:
return $default(_that.categorie,_that.tauxPct,_that.ca,_that.produits,_that.montant);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategorieMois implements CategorieMois {
  const _CategorieMois({this.categorie, @JsonKey(name: 'taux_pct') this.tauxPct = 0, this.ca = 0, this.produits = 0, this.montant = 0});
  factory _CategorieMois.fromJson(Map<String, dynamic> json) => _$CategorieMoisFromJson(json);

@override final  String? categorie;
@override@JsonKey(name: 'taux_pct') final  double tauxPct;
@override@JsonKey() final  double ca;
@override@JsonKey() final  int produits;
@override@JsonKey() final  double montant;

/// Create a copy of CategorieMois
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategorieMoisCopyWith<_CategorieMois> get copyWith => __$CategorieMoisCopyWithImpl<_CategorieMois>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategorieMoisToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategorieMois&&(identical(other.categorie, categorie) || other.categorie == categorie)&&(identical(other.tauxPct, tauxPct) || other.tauxPct == tauxPct)&&(identical(other.ca, ca) || other.ca == ca)&&(identical(other.produits, produits) || other.produits == produits)&&(identical(other.montant, montant) || other.montant == montant));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,categorie,tauxPct,ca,produits,montant);
}

@override
String toString() {
    return 'CategorieMois(categorie: $categorie, tauxPct: $tauxPct, ca: $ca, produits: $produits, montant: $montant)';
}


}

/// @nodoc
abstract mixin class _$CategorieMoisCopyWith<$Res> implements $CategorieMoisCopyWith<$Res> {
  factory _$CategorieMoisCopyWith(_CategorieMois value, $Res Function(_CategorieMois) _then) = __$CategorieMoisCopyWithImpl;
@override @useResult
$Res call({
 String? categorie,@JsonKey(name: 'taux_pct') double tauxPct, double ca, int produits, double montant
});




}
/// @nodoc
class __$CategorieMoisCopyWithImpl<$Res>
    implements _$CategorieMoisCopyWith<$Res> {
  __$CategorieMoisCopyWithImpl(this._self, this._then);

  final _CategorieMois _self;
  final $Res Function(_CategorieMois) _then;

/// Create a copy of CategorieMois
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categorie = freezed,Object? tauxPct = null,Object? ca = null,Object? produits = null,Object? montant = null,}) {
  return _then(_CategorieMois(
categorie: freezed == categorie ? _self.categorie : categorie // ignore: cast_nullable_to_non_nullable
as String?,tauxPct: null == tauxPct ? _self.tauxPct : tauxPct // ignore: cast_nullable_to_non_nullable
as double,ca: null == ca ? _self.ca : ca // ignore: cast_nullable_to_non_nullable
as double,produits: null == produits ? _self.produits : produits // ignore: cast_nullable_to_non_nullable
as int,montant: null == montant ? _self.montant : montant // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$DernierClassement {

 DateTime get le; String? get par;@JsonKey(name: 'seuil_marge') double get seuilMarge;@JsonKey(name: 'tout_reclasser') bool get toutReclasser; int get produits;
/// Create a copy of DernierClassement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DernierClassementCopyWith<DernierClassement> get copyWith => _$DernierClassementCopyWithImpl<DernierClassement>(this as DernierClassement, _$identity);

  /// Serializes this DernierClassement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DernierClassement;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DernierClassement&&(identical(other.le, _this.le) || other.le == _this.le)&&(identical(other.par, _this.par) || other.par == _this.par)&&(identical(other.seuilMarge, _this.seuilMarge) || other.seuilMarge == _this.seuilMarge)&&(identical(other.toutReclasser, _this.toutReclasser) || other.toutReclasser == _this.toutReclasser)&&(identical(other.produits, _this.produits) || other.produits == _this.produits));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DernierClassement;
  return Object.hash(runtimeType,_this.le,_this.par,_this.seuilMarge,_this.toutReclasser,_this.produits);
}

@override
String toString() {
  final _this = this as DernierClassement;
  return 'DernierClassement(le: ${_this.le}, par: ${_this.par}, seuilMarge: ${_this.seuilMarge}, toutReclasser: ${_this.toutReclasser}, produits: ${_this.produits})';
}


}

/// @nodoc
abstract mixin class $DernierClassementCopyWith<$Res>  {
  factory $DernierClassementCopyWith(DernierClassement value, $Res Function(DernierClassement) _then) = _$DernierClassementCopyWithImpl;
@useResult
$Res call({
 DateTime le, String? par,@JsonKey(name: 'seuil_marge') double seuilMarge,@JsonKey(name: 'tout_reclasser') bool toutReclasser, int produits
});




}
/// @nodoc
class _$DernierClassementCopyWithImpl<$Res>
    implements $DernierClassementCopyWith<$Res> {
  _$DernierClassementCopyWithImpl(this._self, this._then);

  final DernierClassement _self;
  final $Res Function(DernierClassement) _then;

/// Create a copy of DernierClassement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? le = null,Object? par = freezed,Object? seuilMarge = null,Object? toutReclasser = null,Object? produits = null,}) {
  return _then(DernierClassement(
le: null == le ? _self.le : le // ignore: cast_nullable_to_non_nullable
as DateTime,par: freezed == par ? _self.par : par // ignore: cast_nullable_to_non_nullable
as String?,seuilMarge: null == seuilMarge ? _self.seuilMarge : seuilMarge // ignore: cast_nullable_to_non_nullable
as double,toutReclasser: null == toutReclasser ? _self.toutReclasser : toutReclasser // ignore: cast_nullable_to_non_nullable
as bool,produits: null == produits ? _self.produits : produits // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DernierClassement].
extension DernierClassementPatterns on DernierClassement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DernierClassement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DernierClassement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DernierClassement value)  $default,){
final _that = this;
switch (_that) {
case _DernierClassement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DernierClassement value)?  $default,){
final _that = this;
switch (_that) {
case _DernierClassement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime le,  String? par, @JsonKey(name: 'seuil_marge')  double seuilMarge, @JsonKey(name: 'tout_reclasser')  bool toutReclasser,  int produits)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DernierClassement() when $default != null:
return $default(_that.le,_that.par,_that.seuilMarge,_that.toutReclasser,_that.produits);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime le,  String? par, @JsonKey(name: 'seuil_marge')  double seuilMarge, @JsonKey(name: 'tout_reclasser')  bool toutReclasser,  int produits)  $default,) {final _that = this;
switch (_that) {
case _DernierClassement():
return $default(_that.le,_that.par,_that.seuilMarge,_that.toutReclasser,_that.produits);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime le,  String? par, @JsonKey(name: 'seuil_marge')  double seuilMarge, @JsonKey(name: 'tout_reclasser')  bool toutReclasser,  int produits)?  $default,) {final _that = this;
switch (_that) {
case _DernierClassement() when $default != null:
return $default(_that.le,_that.par,_that.seuilMarge,_that.toutReclasser,_that.produits);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DernierClassement implements DernierClassement {
  const _DernierClassement({required this.le, this.par, @JsonKey(name: 'seuil_marge') this.seuilMarge = 50, @JsonKey(name: 'tout_reclasser') this.toutReclasser = false, this.produits = 0});
  factory _DernierClassement.fromJson(Map<String, dynamic> json) => _$DernierClassementFromJson(json);

@override final  DateTime le;
@override final  String? par;
@override@JsonKey(name: 'seuil_marge') final  double seuilMarge;
@override@JsonKey(name: 'tout_reclasser') final  bool toutReclasser;
@override@JsonKey() final  int produits;

/// Create a copy of DernierClassement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DernierClassementCopyWith<_DernierClassement> get copyWith => __$DernierClassementCopyWithImpl<_DernierClassement>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DernierClassementToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DernierClassement&&(identical(other.le, le) || other.le == le)&&(identical(other.par, par) || other.par == par)&&(identical(other.seuilMarge, seuilMarge) || other.seuilMarge == seuilMarge)&&(identical(other.toutReclasser, toutReclasser) || other.toutReclasser == toutReclasser)&&(identical(other.produits, produits) || other.produits == produits));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,le,par,seuilMarge,toutReclasser,produits);
}

@override
String toString() {
    return 'DernierClassement(le: $le, par: $par, seuilMarge: $seuilMarge, toutReclasser: $toutReclasser, produits: $produits)';
}


}

/// @nodoc
abstract mixin class _$DernierClassementCopyWith<$Res> implements $DernierClassementCopyWith<$Res> {
  factory _$DernierClassementCopyWith(_DernierClassement value, $Res Function(_DernierClassement) _then) = __$DernierClassementCopyWithImpl;
@override @useResult
$Res call({
 DateTime le, String? par,@JsonKey(name: 'seuil_marge') double seuilMarge,@JsonKey(name: 'tout_reclasser') bool toutReclasser, int produits
});




}
/// @nodoc
class __$DernierClassementCopyWithImpl<$Res>
    implements _$DernierClassementCopyWith<$Res> {
  __$DernierClassementCopyWithImpl(this._self, this._then);

  final _DernierClassement _self;
  final $Res Function(_DernierClassement) _then;

/// Create a copy of DernierClassement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? le = null,Object? par = freezed,Object? seuilMarge = null,Object? toutReclasser = null,Object? produits = null,}) {
  return _then(_DernierClassement(
le: null == le ? _self.le : le // ignore: cast_nullable_to_non_nullable
as DateTime,par: freezed == par ? _self.par : par // ignore: cast_nullable_to_non_nullable
as String?,seuilMarge: null == seuilMarge ? _self.seuilMarge : seuilMarge // ignore: cast_nullable_to_non_nullable
as double,toutReclasser: null == toutReclasser ? _self.toutReclasser : toutReclasser // ignore: cast_nullable_to_non_nullable
as bool,produits: null == produits ? _self.produits : produits // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PrimeCategories {

 int get annee; int get mois; double get enveloppe; double get ca; List<CategorieMois> get categories;@JsonKey(name: 'seuil_marge') double get seuilMarge;@JsonKey(name: 'sans_categorie_total') int get sansCategorieTotal;@JsonKey(name: 'dernier_classement') DernierClassement? get dernierClassement;
/// Create a copy of PrimeCategories
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrimeCategoriesCopyWith<PrimeCategories> get copyWith => _$PrimeCategoriesCopyWithImpl<PrimeCategories>(this as PrimeCategories, _$identity);

  /// Serializes this PrimeCategories to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PrimeCategories;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrimeCategories&&(identical(other.annee, _this.annee) || other.annee == _this.annee)&&(identical(other.mois, _this.mois) || other.mois == _this.mois)&&(identical(other.enveloppe, _this.enveloppe) || other.enveloppe == _this.enveloppe)&&(identical(other.ca, _this.ca) || other.ca == _this.ca)&&const DeepCollectionEquality().equals(other.categories, _this.categories)&&(identical(other.seuilMarge, _this.seuilMarge) || other.seuilMarge == _this.seuilMarge)&&(identical(other.sansCategorieTotal, _this.sansCategorieTotal) || other.sansCategorieTotal == _this.sansCategorieTotal)&&(identical(other.dernierClassement, _this.dernierClassement) || other.dernierClassement == _this.dernierClassement));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PrimeCategories;
  return Object.hash(runtimeType,_this.annee,_this.mois,_this.enveloppe,_this.ca,const DeepCollectionEquality().hash(_this.categories),_this.seuilMarge,_this.sansCategorieTotal,_this.dernierClassement);
}

@override
String toString() {
  final _this = this as PrimeCategories;
  return 'PrimeCategories(annee: ${_this.annee}, mois: ${_this.mois}, enveloppe: ${_this.enveloppe}, ca: ${_this.ca}, categories: ${_this.categories}, seuilMarge: ${_this.seuilMarge}, sansCategorieTotal: ${_this.sansCategorieTotal}, dernierClassement: ${_this.dernierClassement})';
}


}

/// @nodoc
abstract mixin class $PrimeCategoriesCopyWith<$Res>  {
  factory $PrimeCategoriesCopyWith(PrimeCategories value, $Res Function(PrimeCategories) _then) = _$PrimeCategoriesCopyWithImpl;
@useResult
$Res call({
 int annee, int mois, double enveloppe, double ca, List<CategorieMois> categories,@JsonKey(name: 'seuil_marge') double seuilMarge,@JsonKey(name: 'sans_categorie_total') int sansCategorieTotal,@JsonKey(name: 'dernier_classement') DernierClassement? dernierClassement
});


$DernierClassementCopyWith<$Res>? get dernierClassement;

}
/// @nodoc
class _$PrimeCategoriesCopyWithImpl<$Res>
    implements $PrimeCategoriesCopyWith<$Res> {
  _$PrimeCategoriesCopyWithImpl(this._self, this._then);

  final PrimeCategories _self;
  final $Res Function(PrimeCategories) _then;

/// Create a copy of PrimeCategories
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? annee = null,Object? mois = null,Object? enveloppe = null,Object? ca = null,Object? categories = null,Object? seuilMarge = null,Object? sansCategorieTotal = null,Object? dernierClassement = freezed,}) {
  return _then(PrimeCategories(
annee: null == annee ? _self.annee : annee // ignore: cast_nullable_to_non_nullable
as int,mois: null == mois ? _self.mois : mois // ignore: cast_nullable_to_non_nullable
as int,enveloppe: null == enveloppe ? _self.enveloppe : enveloppe // ignore: cast_nullable_to_non_nullable
as double,ca: null == ca ? _self.ca : ca // ignore: cast_nullable_to_non_nullable
as double,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<CategorieMois>,seuilMarge: null == seuilMarge ? _self.seuilMarge : seuilMarge // ignore: cast_nullable_to_non_nullable
as double,sansCategorieTotal: null == sansCategorieTotal ? _self.sansCategorieTotal : sansCategorieTotal // ignore: cast_nullable_to_non_nullable
as int,dernierClassement: freezed == dernierClassement ? _self.dernierClassement : dernierClassement // ignore: cast_nullable_to_non_nullable
as DernierClassement?,
  ));
}
/// Create a copy of PrimeCategories
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DernierClassementCopyWith<$Res>? get dernierClassement {
    if (_self.dernierClassement == null) {
    return null;
  }

  return $DernierClassementCopyWith<$Res>(_self.dernierClassement!, (value) {
    return _then(_self.copyWith(dernierClassement: value));
  });
}
}


/// Adds pattern-matching-related methods to [PrimeCategories].
extension PrimeCategoriesPatterns on PrimeCategories {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PrimeCategories value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PrimeCategories() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PrimeCategories value)  $default,){
final _that = this;
switch (_that) {
case _PrimeCategories():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PrimeCategories value)?  $default,){
final _that = this;
switch (_that) {
case _PrimeCategories() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int annee,  int mois,  double enveloppe,  double ca,  List<CategorieMois> categories, @JsonKey(name: 'seuil_marge')  double seuilMarge, @JsonKey(name: 'sans_categorie_total')  int sansCategorieTotal, @JsonKey(name: 'dernier_classement')  DernierClassement? dernierClassement)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PrimeCategories() when $default != null:
return $default(_that.annee,_that.mois,_that.enveloppe,_that.ca,_that.categories,_that.seuilMarge,_that.sansCategorieTotal,_that.dernierClassement);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int annee,  int mois,  double enveloppe,  double ca,  List<CategorieMois> categories, @JsonKey(name: 'seuil_marge')  double seuilMarge, @JsonKey(name: 'sans_categorie_total')  int sansCategorieTotal, @JsonKey(name: 'dernier_classement')  DernierClassement? dernierClassement)  $default,) {final _that = this;
switch (_that) {
case _PrimeCategories():
return $default(_that.annee,_that.mois,_that.enveloppe,_that.ca,_that.categories,_that.seuilMarge,_that.sansCategorieTotal,_that.dernierClassement);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int annee,  int mois,  double enveloppe,  double ca,  List<CategorieMois> categories, @JsonKey(name: 'seuil_marge')  double seuilMarge, @JsonKey(name: 'sans_categorie_total')  int sansCategorieTotal, @JsonKey(name: 'dernier_classement')  DernierClassement? dernierClassement)?  $default,) {final _that = this;
switch (_that) {
case _PrimeCategories() when $default != null:
return $default(_that.annee,_that.mois,_that.enveloppe,_that.ca,_that.categories,_that.seuilMarge,_that.sansCategorieTotal,_that.dernierClassement);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PrimeCategories extends PrimeCategories {
  const _PrimeCategories({required this.annee, required this.mois, this.enveloppe = 0, this.ca = 0,  List<CategorieMois> categories = const [], @JsonKey(name: 'seuil_marge') this.seuilMarge = 50, @JsonKey(name: 'sans_categorie_total') this.sansCategorieTotal = 0, @JsonKey(name: 'dernier_classement') this.dernierClassement}): _categories = categories,super._();
  factory _PrimeCategories.fromJson(Map<String, dynamic> json) => _$PrimeCategoriesFromJson(json);

@override final  int annee;
@override final  int mois;
@override@JsonKey() final  double enveloppe;
@override@JsonKey() final  double ca;
 final  List<CategorieMois> _categories;
@override@JsonKey() List<CategorieMois> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

@override@JsonKey(name: 'seuil_marge') final  double seuilMarge;
@override@JsonKey(name: 'sans_categorie_total') final  int sansCategorieTotal;
@override@JsonKey(name: 'dernier_classement') final  DernierClassement? dernierClassement;

/// Create a copy of PrimeCategories
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PrimeCategoriesCopyWith<_PrimeCategories> get copyWith => __$PrimeCategoriesCopyWithImpl<_PrimeCategories>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PrimeCategoriesToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PrimeCategories&&(identical(other.annee, annee) || other.annee == annee)&&(identical(other.mois, mois) || other.mois == mois)&&(identical(other.enveloppe, enveloppe) || other.enveloppe == enveloppe)&&(identical(other.ca, ca) || other.ca == ca)&&const DeepCollectionEquality().equals(other.categories, _categories)&&(identical(other.seuilMarge, seuilMarge) || other.seuilMarge == seuilMarge)&&(identical(other.sansCategorieTotal, sansCategorieTotal) || other.sansCategorieTotal == sansCategorieTotal)&&(identical(other.dernierClassement, dernierClassement) || other.dernierClassement == dernierClassement));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,annee,mois,enveloppe,ca,const DeepCollectionEquality().hash(_categories),seuilMarge,sansCategorieTotal,dernierClassement);
}

@override
String toString() {
    return 'PrimeCategories(annee: $annee, mois: $mois, enveloppe: $enveloppe, ca: $ca, categories: $categories, seuilMarge: $seuilMarge, sansCategorieTotal: $sansCategorieTotal, dernierClassement: $dernierClassement)';
}


}

/// @nodoc
abstract mixin class _$PrimeCategoriesCopyWith<$Res> implements $PrimeCategoriesCopyWith<$Res> {
  factory _$PrimeCategoriesCopyWith(_PrimeCategories value, $Res Function(_PrimeCategories) _then) = __$PrimeCategoriesCopyWithImpl;
@override @useResult
$Res call({
 int annee, int mois, double enveloppe, double ca, List<CategorieMois> categories,@JsonKey(name: 'seuil_marge') double seuilMarge,@JsonKey(name: 'sans_categorie_total') int sansCategorieTotal,@JsonKey(name: 'dernier_classement') DernierClassement? dernierClassement
});


@override $DernierClassementCopyWith<$Res>? get dernierClassement;

}
/// @nodoc
class __$PrimeCategoriesCopyWithImpl<$Res>
    implements _$PrimeCategoriesCopyWith<$Res> {
  __$PrimeCategoriesCopyWithImpl(this._self, this._then);

  final _PrimeCategories _self;
  final $Res Function(_PrimeCategories) _then;

/// Create a copy of PrimeCategories
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? annee = null,Object? mois = null,Object? enveloppe = null,Object? ca = null,Object? categories = null,Object? seuilMarge = null,Object? sansCategorieTotal = null,Object? dernierClassement = freezed,}) {
  return _then(_PrimeCategories(
annee: null == annee ? _self.annee : annee // ignore: cast_nullable_to_non_nullable
as int,mois: null == mois ? _self.mois : mois // ignore: cast_nullable_to_non_nullable
as int,enveloppe: null == enveloppe ? _self.enveloppe : enveloppe // ignore: cast_nullable_to_non_nullable
as double,ca: null == ca ? _self.ca : ca // ignore: cast_nullable_to_non_nullable
as double,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<CategorieMois>,seuilMarge: null == seuilMarge ? _self.seuilMarge : seuilMarge // ignore: cast_nullable_to_non_nullable
as double,sansCategorieTotal: null == sansCategorieTotal ? _self.sansCategorieTotal : sansCategorieTotal // ignore: cast_nullable_to_non_nullable
as int,dernierClassement: freezed == dernierClassement ? _self.dernierClassement : dernierClassement // ignore: cast_nullable_to_non_nullable
as DernierClassement?,
  ));
}

/// Create a copy of PrimeCategories
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DernierClassementCopyWith<$Res>? get dernierClassement {
    if (_self.dernierClassement == null) {
    return null;
  }

  return $DernierClassementCopyWith<$Res>(_self.dernierClassement!, (value) {
    return _then(_self.copyWith(dernierClassement: value));
  });
}
}


/// @nodoc
mixin _$LaboratoirePrime {

 int get id; String get labo;@JsonKey(name: 'is_generique') bool get generique; double get ca; int get produits;@JsonKey(name: 'part_ca') double get partCa;
/// Create a copy of LaboratoirePrime
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LaboratoirePrimeCopyWith<LaboratoirePrime> get copyWith => _$LaboratoirePrimeCopyWithImpl<LaboratoirePrime>(this as LaboratoirePrime, _$identity);

  /// Serializes this LaboratoirePrime to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LaboratoirePrime;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LaboratoirePrime&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.labo, _this.labo) || other.labo == _this.labo)&&(identical(other.generique, _this.generique) || other.generique == _this.generique)&&(identical(other.ca, _this.ca) || other.ca == _this.ca)&&(identical(other.produits, _this.produits) || other.produits == _this.produits)&&(identical(other.partCa, _this.partCa) || other.partCa == _this.partCa));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LaboratoirePrime;
  return Object.hash(runtimeType,_this.id,_this.labo,_this.generique,_this.ca,_this.produits,_this.partCa);
}

@override
String toString() {
  final _this = this as LaboratoirePrime;
  return 'LaboratoirePrime(id: ${_this.id}, labo: ${_this.labo}, generique: ${_this.generique}, ca: ${_this.ca}, produits: ${_this.produits}, partCa: ${_this.partCa})';
}


}

/// @nodoc
abstract mixin class $LaboratoirePrimeCopyWith<$Res>  {
  factory $LaboratoirePrimeCopyWith(LaboratoirePrime value, $Res Function(LaboratoirePrime) _then) = _$LaboratoirePrimeCopyWithImpl;
@useResult
$Res call({
 int id, String labo,@JsonKey(name: 'is_generique') bool generique, double ca, int produits,@JsonKey(name: 'part_ca') double partCa
});




}
/// @nodoc
class _$LaboratoirePrimeCopyWithImpl<$Res>
    implements $LaboratoirePrimeCopyWith<$Res> {
  _$LaboratoirePrimeCopyWithImpl(this._self, this._then);

  final LaboratoirePrime _self;
  final $Res Function(LaboratoirePrime) _then;

/// Create a copy of LaboratoirePrime
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? labo = null,Object? generique = null,Object? ca = null,Object? produits = null,Object? partCa = null,}) {
  return _then(LaboratoirePrime(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,labo: null == labo ? _self.labo : labo // ignore: cast_nullable_to_non_nullable
as String,generique: null == generique ? _self.generique : generique // ignore: cast_nullable_to_non_nullable
as bool,ca: null == ca ? _self.ca : ca // ignore: cast_nullable_to_non_nullable
as double,produits: null == produits ? _self.produits : produits // ignore: cast_nullable_to_non_nullable
as int,partCa: null == partCa ? _self.partCa : partCa // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [LaboratoirePrime].
extension LaboratoirePrimePatterns on LaboratoirePrime {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LaboratoirePrime value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LaboratoirePrime() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LaboratoirePrime value)  $default,){
final _that = this;
switch (_that) {
case _LaboratoirePrime():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LaboratoirePrime value)?  $default,){
final _that = this;
switch (_that) {
case _LaboratoirePrime() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String labo, @JsonKey(name: 'is_generique')  bool generique,  double ca,  int produits, @JsonKey(name: 'part_ca')  double partCa)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LaboratoirePrime() when $default != null:
return $default(_that.id,_that.labo,_that.generique,_that.ca,_that.produits,_that.partCa);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String labo, @JsonKey(name: 'is_generique')  bool generique,  double ca,  int produits, @JsonKey(name: 'part_ca')  double partCa)  $default,) {final _that = this;
switch (_that) {
case _LaboratoirePrime():
return $default(_that.id,_that.labo,_that.generique,_that.ca,_that.produits,_that.partCa);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String labo, @JsonKey(name: 'is_generique')  bool generique,  double ca,  int produits, @JsonKey(name: 'part_ca')  double partCa)?  $default,) {final _that = this;
switch (_that) {
case _LaboratoirePrime() when $default != null:
return $default(_that.id,_that.labo,_that.generique,_that.ca,_that.produits,_that.partCa);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LaboratoirePrime implements LaboratoirePrime {
  const _LaboratoirePrime({required this.id, this.labo = '', @JsonKey(name: 'is_generique') this.generique = false, this.ca = 0, this.produits = 0, @JsonKey(name: 'part_ca') this.partCa = 0});
  factory _LaboratoirePrime.fromJson(Map<String, dynamic> json) => _$LaboratoirePrimeFromJson(json);

@override final  int id;
@override@JsonKey() final  String labo;
@override@JsonKey(name: 'is_generique') final  bool generique;
@override@JsonKey() final  double ca;
@override@JsonKey() final  int produits;
@override@JsonKey(name: 'part_ca') final  double partCa;

/// Create a copy of LaboratoirePrime
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LaboratoirePrimeCopyWith<_LaboratoirePrime> get copyWith => __$LaboratoirePrimeCopyWithImpl<_LaboratoirePrime>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LaboratoirePrimeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LaboratoirePrime&&(identical(other.id, id) || other.id == id)&&(identical(other.labo, labo) || other.labo == labo)&&(identical(other.generique, generique) || other.generique == generique)&&(identical(other.ca, ca) || other.ca == ca)&&(identical(other.produits, produits) || other.produits == produits)&&(identical(other.partCa, partCa) || other.partCa == partCa));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,labo,generique,ca,produits,partCa);
}

@override
String toString() {
    return 'LaboratoirePrime(id: $id, labo: $labo, generique: $generique, ca: $ca, produits: $produits, partCa: $partCa)';
}


}

/// @nodoc
abstract mixin class _$LaboratoirePrimeCopyWith<$Res> implements $LaboratoirePrimeCopyWith<$Res> {
  factory _$LaboratoirePrimeCopyWith(_LaboratoirePrime value, $Res Function(_LaboratoirePrime) _then) = __$LaboratoirePrimeCopyWithImpl;
@override @useResult
$Res call({
 int id, String labo,@JsonKey(name: 'is_generique') bool generique, double ca, int produits,@JsonKey(name: 'part_ca') double partCa
});




}
/// @nodoc
class __$LaboratoirePrimeCopyWithImpl<$Res>
    implements _$LaboratoirePrimeCopyWith<$Res> {
  __$LaboratoirePrimeCopyWithImpl(this._self, this._then);

  final _LaboratoirePrime _self;
  final $Res Function(_LaboratoirePrime) _then;

/// Create a copy of LaboratoirePrime
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? labo = null,Object? generique = null,Object? ca = null,Object? produits = null,Object? partCa = null,}) {
  return _then(_LaboratoirePrime(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,labo: null == labo ? _self.labo : labo // ignore: cast_nullable_to_non_nullable
as String,generique: null == generique ? _self.generique : generique // ignore: cast_nullable_to_non_nullable
as bool,ca: null == ca ? _self.ca : ca // ignore: cast_nullable_to_non_nullable
as double,produits: null == produits ? _self.produits : produits // ignore: cast_nullable_to_non_nullable
as int,partCa: null == partCa ? _self.partCa : partCa // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$PageLaboratoires {

 List<LaboratoirePrime> get laboratoires; int get total;
/// Create a copy of PageLaboratoires
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageLaboratoiresCopyWith<PageLaboratoires> get copyWith => _$PageLaboratoiresCopyWithImpl<PageLaboratoires>(this as PageLaboratoires, _$identity);

  /// Serializes this PageLaboratoires to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PageLaboratoires;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageLaboratoires&&const DeepCollectionEquality().equals(other.laboratoires, _this.laboratoires)&&(identical(other.total, _this.total) || other.total == _this.total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PageLaboratoires;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.laboratoires),_this.total);
}

@override
String toString() {
  final _this = this as PageLaboratoires;
  return 'PageLaboratoires(laboratoires: ${_this.laboratoires}, total: ${_this.total})';
}


}

/// @nodoc
abstract mixin class $PageLaboratoiresCopyWith<$Res>  {
  factory $PageLaboratoiresCopyWith(PageLaboratoires value, $Res Function(PageLaboratoires) _then) = _$PageLaboratoiresCopyWithImpl;
@useResult
$Res call({
 List<LaboratoirePrime> laboratoires, int total
});




}
/// @nodoc
class _$PageLaboratoiresCopyWithImpl<$Res>
    implements $PageLaboratoiresCopyWith<$Res> {
  _$PageLaboratoiresCopyWithImpl(this._self, this._then);

  final PageLaboratoires _self;
  final $Res Function(PageLaboratoires) _then;

/// Create a copy of PageLaboratoires
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? laboratoires = null,Object? total = null,}) {
  return _then(PageLaboratoires(
laboratoires: null == laboratoires ? _self.laboratoires : laboratoires // ignore: cast_nullable_to_non_nullable
as List<LaboratoirePrime>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PageLaboratoires].
extension PageLaboratoiresPatterns on PageLaboratoires {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PageLaboratoires value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PageLaboratoires() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PageLaboratoires value)  $default,){
final _that = this;
switch (_that) {
case _PageLaboratoires():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PageLaboratoires value)?  $default,){
final _that = this;
switch (_that) {
case _PageLaboratoires() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<LaboratoirePrime> laboratoires,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PageLaboratoires() when $default != null:
return $default(_that.laboratoires,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<LaboratoirePrime> laboratoires,  int total)  $default,) {final _that = this;
switch (_that) {
case _PageLaboratoires():
return $default(_that.laboratoires,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<LaboratoirePrime> laboratoires,  int total)?  $default,) {final _that = this;
switch (_that) {
case _PageLaboratoires() when $default != null:
return $default(_that.laboratoires,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PageLaboratoires implements PageLaboratoires {
  const _PageLaboratoires({ List<LaboratoirePrime> laboratoires = const [], this.total = 0}): _laboratoires = laboratoires;
  factory _PageLaboratoires.fromJson(Map<String, dynamic> json) => _$PageLaboratoiresFromJson(json);

 final  List<LaboratoirePrime> _laboratoires;
@override@JsonKey() List<LaboratoirePrime> get laboratoires {
  if (_laboratoires is EqualUnmodifiableListView) return _laboratoires;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_laboratoires);
}

@override@JsonKey() final  int total;

/// Create a copy of PageLaboratoires
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PageLaboratoiresCopyWith<_PageLaboratoires> get copyWith => __$PageLaboratoiresCopyWithImpl<_PageLaboratoires>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PageLaboratoiresToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PageLaboratoires&&const DeepCollectionEquality().equals(other.laboratoires, _laboratoires)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_laboratoires),total);
}

@override
String toString() {
    return 'PageLaboratoires(laboratoires: $laboratoires, total: $total)';
}


}

/// @nodoc
abstract mixin class _$PageLaboratoiresCopyWith<$Res> implements $PageLaboratoiresCopyWith<$Res> {
  factory _$PageLaboratoiresCopyWith(_PageLaboratoires value, $Res Function(_PageLaboratoires) _then) = __$PageLaboratoiresCopyWithImpl;
@override @useResult
$Res call({
 List<LaboratoirePrime> laboratoires, int total
});




}
/// @nodoc
class __$PageLaboratoiresCopyWithImpl<$Res>
    implements _$PageLaboratoiresCopyWith<$Res> {
  __$PageLaboratoiresCopyWithImpl(this._self, this._then);

  final _PageLaboratoires _self;
  final $Res Function(_PageLaboratoires) _then;

/// Create a copy of PageLaboratoires
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? laboratoires = null,Object? total = null,}) {
  return _then(_PageLaboratoires(
laboratoires: null == laboratoires ? _self._laboratoires : laboratoires // ignore: cast_nullable_to_non_nullable
as List<LaboratoirePrime>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ProduitCategorie {

 int get id; String? get nom; String? get labo; String? get categorie; bool get manuelle; double get ca;
/// Create a copy of ProduitCategorie
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProduitCategorieCopyWith<ProduitCategorie> get copyWith => _$ProduitCategorieCopyWithImpl<ProduitCategorie>(this as ProduitCategorie, _$identity);

  /// Serializes this ProduitCategorie to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ProduitCategorie;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProduitCategorie&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nom, _this.nom) || other.nom == _this.nom)&&(identical(other.labo, _this.labo) || other.labo == _this.labo)&&(identical(other.categorie, _this.categorie) || other.categorie == _this.categorie)&&(identical(other.manuelle, _this.manuelle) || other.manuelle == _this.manuelle)&&(identical(other.ca, _this.ca) || other.ca == _this.ca));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ProduitCategorie;
  return Object.hash(runtimeType,_this.id,_this.nom,_this.labo,_this.categorie,_this.manuelle,_this.ca);
}

@override
String toString() {
  final _this = this as ProduitCategorie;
  return 'ProduitCategorie(id: ${_this.id}, nom: ${_this.nom}, labo: ${_this.labo}, categorie: ${_this.categorie}, manuelle: ${_this.manuelle}, ca: ${_this.ca})';
}


}

/// @nodoc
abstract mixin class $ProduitCategorieCopyWith<$Res>  {
  factory $ProduitCategorieCopyWith(ProduitCategorie value, $Res Function(ProduitCategorie) _then) = _$ProduitCategorieCopyWithImpl;
@useResult
$Res call({
 int id, String? nom, String? labo, String? categorie, bool manuelle, double ca
});




}
/// @nodoc
class _$ProduitCategorieCopyWithImpl<$Res>
    implements $ProduitCategorieCopyWith<$Res> {
  _$ProduitCategorieCopyWithImpl(this._self, this._then);

  final ProduitCategorie _self;
  final $Res Function(ProduitCategorie) _then;

/// Create a copy of ProduitCategorie
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nom = freezed,Object? labo = freezed,Object? categorie = freezed,Object? manuelle = null,Object? ca = null,}) {
  return _then(ProduitCategorie(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nom: freezed == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String?,labo: freezed == labo ? _self.labo : labo // ignore: cast_nullable_to_non_nullable
as String?,categorie: freezed == categorie ? _self.categorie : categorie // ignore: cast_nullable_to_non_nullable
as String?,manuelle: null == manuelle ? _self.manuelle : manuelle // ignore: cast_nullable_to_non_nullable
as bool,ca: null == ca ? _self.ca : ca // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ProduitCategorie].
extension ProduitCategoriePatterns on ProduitCategorie {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProduitCategorie value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProduitCategorie() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProduitCategorie value)  $default,){
final _that = this;
switch (_that) {
case _ProduitCategorie():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProduitCategorie value)?  $default,){
final _that = this;
switch (_that) {
case _ProduitCategorie() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? nom,  String? labo,  String? categorie,  bool manuelle,  double ca)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProduitCategorie() when $default != null:
return $default(_that.id,_that.nom,_that.labo,_that.categorie,_that.manuelle,_that.ca);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? nom,  String? labo,  String? categorie,  bool manuelle,  double ca)  $default,) {final _that = this;
switch (_that) {
case _ProduitCategorie():
return $default(_that.id,_that.nom,_that.labo,_that.categorie,_that.manuelle,_that.ca);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? nom,  String? labo,  String? categorie,  bool manuelle,  double ca)?  $default,) {final _that = this;
switch (_that) {
case _ProduitCategorie() when $default != null:
return $default(_that.id,_that.nom,_that.labo,_that.categorie,_that.manuelle,_that.ca);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProduitCategorie implements ProduitCategorie {
  const _ProduitCategorie({required this.id, this.nom, this.labo, this.categorie, this.manuelle = false, this.ca = 0});
  factory _ProduitCategorie.fromJson(Map<String, dynamic> json) => _$ProduitCategorieFromJson(json);

@override final  int id;
@override final  String? nom;
@override final  String? labo;
@override final  String? categorie;
@override@JsonKey() final  bool manuelle;
@override@JsonKey() final  double ca;

/// Create a copy of ProduitCategorie
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProduitCategorieCopyWith<_ProduitCategorie> get copyWith => __$ProduitCategorieCopyWithImpl<_ProduitCategorie>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProduitCategorieToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProduitCategorie&&(identical(other.id, id) || other.id == id)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.labo, labo) || other.labo == labo)&&(identical(other.categorie, categorie) || other.categorie == categorie)&&(identical(other.manuelle, manuelle) || other.manuelle == manuelle)&&(identical(other.ca, ca) || other.ca == ca));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,nom,labo,categorie,manuelle,ca);
}

@override
String toString() {
    return 'ProduitCategorie(id: $id, nom: $nom, labo: $labo, categorie: $categorie, manuelle: $manuelle, ca: $ca)';
}


}

/// @nodoc
abstract mixin class _$ProduitCategorieCopyWith<$Res> implements $ProduitCategorieCopyWith<$Res> {
  factory _$ProduitCategorieCopyWith(_ProduitCategorie value, $Res Function(_ProduitCategorie) _then) = __$ProduitCategorieCopyWithImpl;
@override @useResult
$Res call({
 int id, String? nom, String? labo, String? categorie, bool manuelle, double ca
});




}
/// @nodoc
class __$ProduitCategorieCopyWithImpl<$Res>
    implements _$ProduitCategorieCopyWith<$Res> {
  __$ProduitCategorieCopyWithImpl(this._self, this._then);

  final _ProduitCategorie _self;
  final $Res Function(_ProduitCategorie) _then;

/// Create a copy of ProduitCategorie
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nom = freezed,Object? labo = freezed,Object? categorie = freezed,Object? manuelle = null,Object? ca = null,}) {
  return _then(_ProduitCategorie(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nom: freezed == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String?,labo: freezed == labo ? _self.labo : labo // ignore: cast_nullable_to_non_nullable
as String?,categorie: freezed == categorie ? _self.categorie : categorie // ignore: cast_nullable_to_non_nullable
as String?,manuelle: null == manuelle ? _self.manuelle : manuelle // ignore: cast_nullable_to_non_nullable
as bool,ca: null == ca ? _self.ca : ca // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$ResultatClassement {

 int get princeps; int get generique;@JsonKey(name: 'generique++') int get generiquePlus; int get total;
/// Create a copy of ResultatClassement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResultatClassementCopyWith<ResultatClassement> get copyWith => _$ResultatClassementCopyWithImpl<ResultatClassement>(this as ResultatClassement, _$identity);

  /// Serializes this ResultatClassement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ResultatClassement;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResultatClassement&&(identical(other.princeps, _this.princeps) || other.princeps == _this.princeps)&&(identical(other.generique, _this.generique) || other.generique == _this.generique)&&(identical(other.generiquePlus, _this.generiquePlus) || other.generiquePlus == _this.generiquePlus)&&(identical(other.total, _this.total) || other.total == _this.total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ResultatClassement;
  return Object.hash(runtimeType,_this.princeps,_this.generique,_this.generiquePlus,_this.total);
}

@override
String toString() {
  final _this = this as ResultatClassement;
  return 'ResultatClassement(princeps: ${_this.princeps}, generique: ${_this.generique}, generiquePlus: ${_this.generiquePlus}, total: ${_this.total})';
}


}

/// @nodoc
abstract mixin class $ResultatClassementCopyWith<$Res>  {
  factory $ResultatClassementCopyWith(ResultatClassement value, $Res Function(ResultatClassement) _then) = _$ResultatClassementCopyWithImpl;
@useResult
$Res call({
 int princeps, int generique,@JsonKey(name: 'generique++') int generiquePlus, int total
});




}
/// @nodoc
class _$ResultatClassementCopyWithImpl<$Res>
    implements $ResultatClassementCopyWith<$Res> {
  _$ResultatClassementCopyWithImpl(this._self, this._then);

  final ResultatClassement _self;
  final $Res Function(ResultatClassement) _then;

/// Create a copy of ResultatClassement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? princeps = null,Object? generique = null,Object? generiquePlus = null,Object? total = null,}) {
  return _then(ResultatClassement(
princeps: null == princeps ? _self.princeps : princeps // ignore: cast_nullable_to_non_nullable
as int,generique: null == generique ? _self.generique : generique // ignore: cast_nullable_to_non_nullable
as int,generiquePlus: null == generiquePlus ? _self.generiquePlus : generiquePlus // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ResultatClassement].
extension ResultatClassementPatterns on ResultatClassement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResultatClassement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResultatClassement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResultatClassement value)  $default,){
final _that = this;
switch (_that) {
case _ResultatClassement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResultatClassement value)?  $default,){
final _that = this;
switch (_that) {
case _ResultatClassement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int princeps,  int generique, @JsonKey(name: 'generique++')  int generiquePlus,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResultatClassement() when $default != null:
return $default(_that.princeps,_that.generique,_that.generiquePlus,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int princeps,  int generique, @JsonKey(name: 'generique++')  int generiquePlus,  int total)  $default,) {final _that = this;
switch (_that) {
case _ResultatClassement():
return $default(_that.princeps,_that.generique,_that.generiquePlus,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int princeps,  int generique, @JsonKey(name: 'generique++')  int generiquePlus,  int total)?  $default,) {final _that = this;
switch (_that) {
case _ResultatClassement() when $default != null:
return $default(_that.princeps,_that.generique,_that.generiquePlus,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ResultatClassement implements ResultatClassement {
  const _ResultatClassement({this.princeps = 0, this.generique = 0, @JsonKey(name: 'generique++') this.generiquePlus = 0, this.total = 0});
  factory _ResultatClassement.fromJson(Map<String, dynamic> json) => _$ResultatClassementFromJson(json);

@override@JsonKey() final  int princeps;
@override@JsonKey() final  int generique;
@override@JsonKey(name: 'generique++') final  int generiquePlus;
@override@JsonKey() final  int total;

/// Create a copy of ResultatClassement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResultatClassementCopyWith<_ResultatClassement> get copyWith => __$ResultatClassementCopyWithImpl<_ResultatClassement>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ResultatClassementToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResultatClassement&&(identical(other.princeps, princeps) || other.princeps == princeps)&&(identical(other.generique, generique) || other.generique == generique)&&(identical(other.generiquePlus, generiquePlus) || other.generiquePlus == generiquePlus)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,princeps,generique,generiquePlus,total);
}

@override
String toString() {
    return 'ResultatClassement(princeps: $princeps, generique: $generique, generiquePlus: $generiquePlus, total: $total)';
}


}

/// @nodoc
abstract mixin class _$ResultatClassementCopyWith<$Res> implements $ResultatClassementCopyWith<$Res> {
  factory _$ResultatClassementCopyWith(_ResultatClassement value, $Res Function(_ResultatClassement) _then) = __$ResultatClassementCopyWithImpl;
@override @useResult
$Res call({
 int princeps, int generique,@JsonKey(name: 'generique++') int generiquePlus, int total
});




}
/// @nodoc
class __$ResultatClassementCopyWithImpl<$Res>
    implements _$ResultatClassementCopyWith<$Res> {
  __$ResultatClassementCopyWithImpl(this._self, this._then);

  final _ResultatClassement _self;
  final $Res Function(_ResultatClassement) _then;

/// Create a copy of ResultatClassement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? princeps = null,Object? generique = null,Object? generiquePlus = null,Object? total = null,}) {
  return _then(_ResultatClassement(
princeps: null == princeps ? _self.princeps : princeps // ignore: cast_nullable_to_non_nullable
as int,generique: null == generique ? _self.generique : generique // ignore: cast_nullable_to_non_nullable
as int,generiquePlus: null == generiquePlus ? _self.generiquePlus : generiquePlus // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
