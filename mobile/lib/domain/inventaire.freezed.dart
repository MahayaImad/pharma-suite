// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'inventaire.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProduitACompter {

@JsonKey(name: 'id_nom') int get idNom; String? get nom; String? get classe; String get raison;@JsonKey(name: 'stock_theorique') int get stockTheorique;@JsonKey(name: 'dernier_comptage') DateTime? get dernierComptage;
/// Create a copy of ProduitACompter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProduitACompterCopyWith<ProduitACompter> get copyWith => _$ProduitACompterCopyWithImpl<ProduitACompter>(this as ProduitACompter, _$identity);

  /// Serializes this ProduitACompter to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ProduitACompter;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProduitACompter&&(identical(other.idNom, _this.idNom) || other.idNom == _this.idNom)&&(identical(other.nom, _this.nom) || other.nom == _this.nom)&&(identical(other.classe, _this.classe) || other.classe == _this.classe)&&(identical(other.raison, _this.raison) || other.raison == _this.raison)&&(identical(other.stockTheorique, _this.stockTheorique) || other.stockTheorique == _this.stockTheorique)&&(identical(other.dernierComptage, _this.dernierComptage) || other.dernierComptage == _this.dernierComptage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ProduitACompter;
  return Object.hash(runtimeType,_this.idNom,_this.nom,_this.classe,_this.raison,_this.stockTheorique,_this.dernierComptage);
}

@override
String toString() {
  final _this = this as ProduitACompter;
  return 'ProduitACompter(idNom: ${_this.idNom}, nom: ${_this.nom}, classe: ${_this.classe}, raison: ${_this.raison}, stockTheorique: ${_this.stockTheorique}, dernierComptage: ${_this.dernierComptage})';
}


}

/// @nodoc
abstract mixin class $ProduitACompterCopyWith<$Res>  {
  factory $ProduitACompterCopyWith(ProduitACompter value, $Res Function(ProduitACompter) _then) = _$ProduitACompterCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id_nom') int idNom, String? nom, String? classe, String raison,@JsonKey(name: 'stock_theorique') int stockTheorique,@JsonKey(name: 'dernier_comptage') DateTime? dernierComptage
});




}
/// @nodoc
class _$ProduitACompterCopyWithImpl<$Res>
    implements $ProduitACompterCopyWith<$Res> {
  _$ProduitACompterCopyWithImpl(this._self, this._then);

  final ProduitACompter _self;
  final $Res Function(ProduitACompter) _then;

/// Create a copy of ProduitACompter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? idNom = null,Object? nom = freezed,Object? classe = freezed,Object? raison = null,Object? stockTheorique = null,Object? dernierComptage = freezed,}) {
  return _then(ProduitACompter(
idNom: null == idNom ? _self.idNom : idNom // ignore: cast_nullable_to_non_nullable
as int,nom: freezed == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String?,classe: freezed == classe ? _self.classe : classe // ignore: cast_nullable_to_non_nullable
as String?,raison: null == raison ? _self.raison : raison // ignore: cast_nullable_to_non_nullable
as String,stockTheorique: null == stockTheorique ? _self.stockTheorique : stockTheorique // ignore: cast_nullable_to_non_nullable
as int,dernierComptage: freezed == dernierComptage ? _self.dernierComptage : dernierComptage // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProduitACompter].
extension ProduitACompterPatterns on ProduitACompter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProduitACompter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProduitACompter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProduitACompter value)  $default,){
final _that = this;
switch (_that) {
case _ProduitACompter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProduitACompter value)?  $default,){
final _that = this;
switch (_that) {
case _ProduitACompter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id_nom')  int idNom,  String? nom,  String? classe,  String raison, @JsonKey(name: 'stock_theorique')  int stockTheorique, @JsonKey(name: 'dernier_comptage')  DateTime? dernierComptage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProduitACompter() when $default != null:
return $default(_that.idNom,_that.nom,_that.classe,_that.raison,_that.stockTheorique,_that.dernierComptage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id_nom')  int idNom,  String? nom,  String? classe,  String raison, @JsonKey(name: 'stock_theorique')  int stockTheorique, @JsonKey(name: 'dernier_comptage')  DateTime? dernierComptage)  $default,) {final _that = this;
switch (_that) {
case _ProduitACompter():
return $default(_that.idNom,_that.nom,_that.classe,_that.raison,_that.stockTheorique,_that.dernierComptage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id_nom')  int idNom,  String? nom,  String? classe,  String raison, @JsonKey(name: 'stock_theorique')  int stockTheorique, @JsonKey(name: 'dernier_comptage')  DateTime? dernierComptage)?  $default,) {final _that = this;
switch (_that) {
case _ProduitACompter() when $default != null:
return $default(_that.idNom,_that.nom,_that.classe,_that.raison,_that.stockTheorique,_that.dernierComptage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProduitACompter extends ProduitACompter {
  const _ProduitACompter({@JsonKey(name: 'id_nom') required this.idNom, this.nom, this.classe, this.raison = '', @JsonKey(name: 'stock_theorique') this.stockTheorique = 0, @JsonKey(name: 'dernier_comptage') this.dernierComptage}): super._();
  factory _ProduitACompter.fromJson(Map<String, dynamic> json) => _$ProduitACompterFromJson(json);

@override@JsonKey(name: 'id_nom') final  int idNom;
@override final  String? nom;
@override final  String? classe;
@override@JsonKey() final  String raison;
@override@JsonKey(name: 'stock_theorique') final  int stockTheorique;
@override@JsonKey(name: 'dernier_comptage') final  DateTime? dernierComptage;

/// Create a copy of ProduitACompter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProduitACompterCopyWith<_ProduitACompter> get copyWith => __$ProduitACompterCopyWithImpl<_ProduitACompter>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProduitACompterToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProduitACompter&&(identical(other.idNom, idNom) || other.idNom == idNom)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.classe, classe) || other.classe == classe)&&(identical(other.raison, raison) || other.raison == raison)&&(identical(other.stockTheorique, stockTheorique) || other.stockTheorique == stockTheorique)&&(identical(other.dernierComptage, dernierComptage) || other.dernierComptage == dernierComptage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,idNom,nom,classe,raison,stockTheorique,dernierComptage);
}

@override
String toString() {
    return 'ProduitACompter(idNom: $idNom, nom: $nom, classe: $classe, raison: $raison, stockTheorique: $stockTheorique, dernierComptage: $dernierComptage)';
}


}

/// @nodoc
abstract mixin class _$ProduitACompterCopyWith<$Res> implements $ProduitACompterCopyWith<$Res> {
  factory _$ProduitACompterCopyWith(_ProduitACompter value, $Res Function(_ProduitACompter) _then) = __$ProduitACompterCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id_nom') int idNom, String? nom, String? classe, String raison,@JsonKey(name: 'stock_theorique') int stockTheorique,@JsonKey(name: 'dernier_comptage') DateTime? dernierComptage
});




}
/// @nodoc
class __$ProduitACompterCopyWithImpl<$Res>
    implements _$ProduitACompterCopyWith<$Res> {
  __$ProduitACompterCopyWithImpl(this._self, this._then);

  final _ProduitACompter _self;
  final $Res Function(_ProduitACompter) _then;

/// Create a copy of ProduitACompter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? idNom = null,Object? nom = freezed,Object? classe = freezed,Object? raison = null,Object? stockTheorique = null,Object? dernierComptage = freezed,}) {
  return _then(_ProduitACompter(
idNom: null == idNom ? _self.idNom : idNom // ignore: cast_nullable_to_non_nullable
as int,nom: freezed == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String?,classe: freezed == classe ? _self.classe : classe // ignore: cast_nullable_to_non_nullable
as String?,raison: null == raison ? _self.raison : raison // ignore: cast_nullable_to_non_nullable
as String,stockTheorique: null == stockTheorique ? _self.stockTheorique : stockTheorique // ignore: cast_nullable_to_non_nullable
as int,dernierComptage: freezed == dernierComptage ? _self.dernierComptage : dernierComptage // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$Comptage {

 int get id;@JsonKey(name: 'id_nom') int get idNom; String? get nom; String? get classe;@JsonKey(name: 'stock_theorique') int get stockTheorique;@JsonKey(name: 'stock_compte') int get stockCompte; int get ecart;@JsonKey(name: 'valeur_ecart') double get valeurEcart;@JsonKey(unknownEnumValue: CauseEcart.inconnu) CauseEcart? get cause;@JsonKey(name: 'compte_par') String? get comptePar;@JsonKey(name: 'compte_le') DateTime? get compteLe; DateTime get jour; bool get corrige;@JsonKey(name: 'dans_la_liste') bool get dansLaListe;
/// Create a copy of Comptage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComptageCopyWith<Comptage> get copyWith => _$ComptageCopyWithImpl<Comptage>(this as Comptage, _$identity);

  /// Serializes this Comptage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Comptage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Comptage&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.idNom, _this.idNom) || other.idNom == _this.idNom)&&(identical(other.nom, _this.nom) || other.nom == _this.nom)&&(identical(other.classe, _this.classe) || other.classe == _this.classe)&&(identical(other.stockTheorique, _this.stockTheorique) || other.stockTheorique == _this.stockTheorique)&&(identical(other.stockCompte, _this.stockCompte) || other.stockCompte == _this.stockCompte)&&(identical(other.ecart, _this.ecart) || other.ecart == _this.ecart)&&(identical(other.valeurEcart, _this.valeurEcart) || other.valeurEcart == _this.valeurEcart)&&(identical(other.cause, _this.cause) || other.cause == _this.cause)&&(identical(other.comptePar, _this.comptePar) || other.comptePar == _this.comptePar)&&(identical(other.compteLe, _this.compteLe) || other.compteLe == _this.compteLe)&&(identical(other.jour, _this.jour) || other.jour == _this.jour)&&(identical(other.corrige, _this.corrige) || other.corrige == _this.corrige)&&(identical(other.dansLaListe, _this.dansLaListe) || other.dansLaListe == _this.dansLaListe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Comptage;
  return Object.hash(runtimeType,_this.id,_this.idNom,_this.nom,_this.classe,_this.stockTheorique,_this.stockCompte,_this.ecart,_this.valeurEcart,_this.cause,_this.comptePar,_this.compteLe,_this.jour,_this.corrige,_this.dansLaListe);
}

@override
String toString() {
  final _this = this as Comptage;
  return 'Comptage(id: ${_this.id}, idNom: ${_this.idNom}, nom: ${_this.nom}, classe: ${_this.classe}, stockTheorique: ${_this.stockTheorique}, stockCompte: ${_this.stockCompte}, ecart: ${_this.ecart}, valeurEcart: ${_this.valeurEcart}, cause: ${_this.cause}, comptePar: ${_this.comptePar}, compteLe: ${_this.compteLe}, jour: ${_this.jour}, corrige: ${_this.corrige}, dansLaListe: ${_this.dansLaListe})';
}


}

/// @nodoc
abstract mixin class $ComptageCopyWith<$Res>  {
  factory $ComptageCopyWith(Comptage value, $Res Function(Comptage) _then) = _$ComptageCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'id_nom') int idNom, String? nom, String? classe,@JsonKey(name: 'stock_theorique') int stockTheorique,@JsonKey(name: 'stock_compte') int stockCompte, int ecart,@JsonKey(name: 'valeur_ecart') double valeurEcart,@JsonKey(unknownEnumValue: CauseEcart.inconnu) CauseEcart? cause,@JsonKey(name: 'compte_par') String? comptePar,@JsonKey(name: 'compte_le') DateTime? compteLe, DateTime jour, bool corrige,@JsonKey(name: 'dans_la_liste') bool dansLaListe
});




}
/// @nodoc
class _$ComptageCopyWithImpl<$Res>
    implements $ComptageCopyWith<$Res> {
  _$ComptageCopyWithImpl(this._self, this._then);

  final Comptage _self;
  final $Res Function(Comptage) _then;

/// Create a copy of Comptage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? idNom = null,Object? nom = freezed,Object? classe = freezed,Object? stockTheorique = null,Object? stockCompte = null,Object? ecart = null,Object? valeurEcart = null,Object? cause = freezed,Object? comptePar = freezed,Object? compteLe = freezed,Object? jour = null,Object? corrige = null,Object? dansLaListe = null,}) {
  return _then(Comptage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,idNom: null == idNom ? _self.idNom : idNom // ignore: cast_nullable_to_non_nullable
as int,nom: freezed == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String?,classe: freezed == classe ? _self.classe : classe // ignore: cast_nullable_to_non_nullable
as String?,stockTheorique: null == stockTheorique ? _self.stockTheorique : stockTheorique // ignore: cast_nullable_to_non_nullable
as int,stockCompte: null == stockCompte ? _self.stockCompte : stockCompte // ignore: cast_nullable_to_non_nullable
as int,ecart: null == ecart ? _self.ecart : ecart // ignore: cast_nullable_to_non_nullable
as int,valeurEcart: null == valeurEcart ? _self.valeurEcart : valeurEcart // ignore: cast_nullable_to_non_nullable
as double,cause: freezed == cause ? _self.cause : cause // ignore: cast_nullable_to_non_nullable
as CauseEcart?,comptePar: freezed == comptePar ? _self.comptePar : comptePar // ignore: cast_nullable_to_non_nullable
as String?,compteLe: freezed == compteLe ? _self.compteLe : compteLe // ignore: cast_nullable_to_non_nullable
as DateTime?,jour: null == jour ? _self.jour : jour // ignore: cast_nullable_to_non_nullable
as DateTime,corrige: null == corrige ? _self.corrige : corrige // ignore: cast_nullable_to_non_nullable
as bool,dansLaListe: null == dansLaListe ? _self.dansLaListe : dansLaListe // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Comptage].
extension ComptagePatterns on Comptage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Comptage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Comptage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Comptage value)  $default,){
final _that = this;
switch (_that) {
case _Comptage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Comptage value)?  $default,){
final _that = this;
switch (_that) {
case _Comptage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'id_nom')  int idNom,  String? nom,  String? classe, @JsonKey(name: 'stock_theorique')  int stockTheorique, @JsonKey(name: 'stock_compte')  int stockCompte,  int ecart, @JsonKey(name: 'valeur_ecart')  double valeurEcart, @JsonKey(unknownEnumValue: CauseEcart.inconnu)  CauseEcart? cause, @JsonKey(name: 'compte_par')  String? comptePar, @JsonKey(name: 'compte_le')  DateTime? compteLe,  DateTime jour,  bool corrige, @JsonKey(name: 'dans_la_liste')  bool dansLaListe)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Comptage() when $default != null:
return $default(_that.id,_that.idNom,_that.nom,_that.classe,_that.stockTheorique,_that.stockCompte,_that.ecart,_that.valeurEcart,_that.cause,_that.comptePar,_that.compteLe,_that.jour,_that.corrige,_that.dansLaListe);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'id_nom')  int idNom,  String? nom,  String? classe, @JsonKey(name: 'stock_theorique')  int stockTheorique, @JsonKey(name: 'stock_compte')  int stockCompte,  int ecart, @JsonKey(name: 'valeur_ecart')  double valeurEcart, @JsonKey(unknownEnumValue: CauseEcart.inconnu)  CauseEcart? cause, @JsonKey(name: 'compte_par')  String? comptePar, @JsonKey(name: 'compte_le')  DateTime? compteLe,  DateTime jour,  bool corrige, @JsonKey(name: 'dans_la_liste')  bool dansLaListe)  $default,) {final _that = this;
switch (_that) {
case _Comptage():
return $default(_that.id,_that.idNom,_that.nom,_that.classe,_that.stockTheorique,_that.stockCompte,_that.ecart,_that.valeurEcart,_that.cause,_that.comptePar,_that.compteLe,_that.jour,_that.corrige,_that.dansLaListe);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'id_nom')  int idNom,  String? nom,  String? classe, @JsonKey(name: 'stock_theorique')  int stockTheorique, @JsonKey(name: 'stock_compte')  int stockCompte,  int ecart, @JsonKey(name: 'valeur_ecart')  double valeurEcart, @JsonKey(unknownEnumValue: CauseEcart.inconnu)  CauseEcart? cause, @JsonKey(name: 'compte_par')  String? comptePar, @JsonKey(name: 'compte_le')  DateTime? compteLe,  DateTime jour,  bool corrige, @JsonKey(name: 'dans_la_liste')  bool dansLaListe)?  $default,) {final _that = this;
switch (_that) {
case _Comptage() when $default != null:
return $default(_that.id,_that.idNom,_that.nom,_that.classe,_that.stockTheorique,_that.stockCompte,_that.ecart,_that.valeurEcart,_that.cause,_that.comptePar,_that.compteLe,_that.jour,_that.corrige,_that.dansLaListe);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Comptage extends Comptage {
  const _Comptage({required this.id, @JsonKey(name: 'id_nom') required this.idNom, this.nom, this.classe, @JsonKey(name: 'stock_theorique') this.stockTheorique = 0, @JsonKey(name: 'stock_compte') this.stockCompte = 0, this.ecart = 0, @JsonKey(name: 'valeur_ecart') this.valeurEcart = 0, @JsonKey(unknownEnumValue: CauseEcart.inconnu) this.cause, @JsonKey(name: 'compte_par') this.comptePar, @JsonKey(name: 'compte_le') this.compteLe, required this.jour, this.corrige = false, @JsonKey(name: 'dans_la_liste') this.dansLaListe = true}): super._();
  factory _Comptage.fromJson(Map<String, dynamic> json) => _$ComptageFromJson(json);

@override final  int id;
@override@JsonKey(name: 'id_nom') final  int idNom;
@override final  String? nom;
@override final  String? classe;
@override@JsonKey(name: 'stock_theorique') final  int stockTheorique;
@override@JsonKey(name: 'stock_compte') final  int stockCompte;
@override@JsonKey() final  int ecart;
@override@JsonKey(name: 'valeur_ecart') final  double valeurEcart;
@override@JsonKey(unknownEnumValue: CauseEcart.inconnu) final  CauseEcart? cause;
@override@JsonKey(name: 'compte_par') final  String? comptePar;
@override@JsonKey(name: 'compte_le') final  DateTime? compteLe;
@override final  DateTime jour;
@override@JsonKey() final  bool corrige;
@override@JsonKey(name: 'dans_la_liste') final  bool dansLaListe;

/// Create a copy of Comptage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComptageCopyWith<_Comptage> get copyWith => __$ComptageCopyWithImpl<_Comptage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComptageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Comptage&&(identical(other.id, id) || other.id == id)&&(identical(other.idNom, idNom) || other.idNom == idNom)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.classe, classe) || other.classe == classe)&&(identical(other.stockTheorique, stockTheorique) || other.stockTheorique == stockTheorique)&&(identical(other.stockCompte, stockCompte) || other.stockCompte == stockCompte)&&(identical(other.ecart, ecart) || other.ecart == ecart)&&(identical(other.valeurEcart, valeurEcart) || other.valeurEcart == valeurEcart)&&(identical(other.cause, cause) || other.cause == cause)&&(identical(other.comptePar, comptePar) || other.comptePar == comptePar)&&(identical(other.compteLe, compteLe) || other.compteLe == compteLe)&&(identical(other.jour, jour) || other.jour == jour)&&(identical(other.corrige, corrige) || other.corrige == corrige)&&(identical(other.dansLaListe, dansLaListe) || other.dansLaListe == dansLaListe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,idNom,nom,classe,stockTheorique,stockCompte,ecart,valeurEcart,cause,comptePar,compteLe,jour,corrige,dansLaListe);
}

@override
String toString() {
    return 'Comptage(id: $id, idNom: $idNom, nom: $nom, classe: $classe, stockTheorique: $stockTheorique, stockCompte: $stockCompte, ecart: $ecart, valeurEcart: $valeurEcart, cause: $cause, comptePar: $comptePar, compteLe: $compteLe, jour: $jour, corrige: $corrige, dansLaListe: $dansLaListe)';
}


}

/// @nodoc
abstract mixin class _$ComptageCopyWith<$Res> implements $ComptageCopyWith<$Res> {
  factory _$ComptageCopyWith(_Comptage value, $Res Function(_Comptage) _then) = __$ComptageCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'id_nom') int idNom, String? nom, String? classe,@JsonKey(name: 'stock_theorique') int stockTheorique,@JsonKey(name: 'stock_compte') int stockCompte, int ecart,@JsonKey(name: 'valeur_ecart') double valeurEcart,@JsonKey(unknownEnumValue: CauseEcart.inconnu) CauseEcart? cause,@JsonKey(name: 'compte_par') String? comptePar,@JsonKey(name: 'compte_le') DateTime? compteLe, DateTime jour, bool corrige,@JsonKey(name: 'dans_la_liste') bool dansLaListe
});




}
/// @nodoc
class __$ComptageCopyWithImpl<$Res>
    implements _$ComptageCopyWith<$Res> {
  __$ComptageCopyWithImpl(this._self, this._then);

  final _Comptage _self;
  final $Res Function(_Comptage) _then;

/// Create a copy of Comptage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? idNom = null,Object? nom = freezed,Object? classe = freezed,Object? stockTheorique = null,Object? stockCompte = null,Object? ecart = null,Object? valeurEcart = null,Object? cause = freezed,Object? comptePar = freezed,Object? compteLe = freezed,Object? jour = null,Object? corrige = null,Object? dansLaListe = null,}) {
  return _then(_Comptage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,idNom: null == idNom ? _self.idNom : idNom // ignore: cast_nullable_to_non_nullable
as int,nom: freezed == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String?,classe: freezed == classe ? _self.classe : classe // ignore: cast_nullable_to_non_nullable
as String?,stockTheorique: null == stockTheorique ? _self.stockTheorique : stockTheorique // ignore: cast_nullable_to_non_nullable
as int,stockCompte: null == stockCompte ? _self.stockCompte : stockCompte // ignore: cast_nullable_to_non_nullable
as int,ecart: null == ecart ? _self.ecart : ecart // ignore: cast_nullable_to_non_nullable
as int,valeurEcart: null == valeurEcart ? _self.valeurEcart : valeurEcart // ignore: cast_nullable_to_non_nullable
as double,cause: freezed == cause ? _self.cause : cause // ignore: cast_nullable_to_non_nullable
as CauseEcart?,comptePar: freezed == comptePar ? _self.comptePar : comptePar // ignore: cast_nullable_to_non_nullable
as String?,compteLe: freezed == compteLe ? _self.compteLe : compteLe // ignore: cast_nullable_to_non_nullable
as DateTime?,jour: null == jour ? _self.jour : jour // ignore: cast_nullable_to_non_nullable
as DateTime,corrige: null == corrige ? _self.corrige : corrige // ignore: cast_nullable_to_non_nullable
as bool,dansLaListe: null == dansLaListe ? _self.dansLaListe : dansLaListe // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$Progression {

 int get total; int get comptes; int get ecarts;
/// Create a copy of Progression
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProgressionCopyWith<Progression> get copyWith => _$ProgressionCopyWithImpl<Progression>(this as Progression, _$identity);

  /// Serializes this Progression to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Progression;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Progression&&(identical(other.total, _this.total) || other.total == _this.total)&&(identical(other.comptes, _this.comptes) || other.comptes == _this.comptes)&&(identical(other.ecarts, _this.ecarts) || other.ecarts == _this.ecarts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Progression;
  return Object.hash(runtimeType,_this.total,_this.comptes,_this.ecarts);
}

@override
String toString() {
  final _this = this as Progression;
  return 'Progression(total: ${_this.total}, comptes: ${_this.comptes}, ecarts: ${_this.ecarts})';
}


}

/// @nodoc
abstract mixin class $ProgressionCopyWith<$Res>  {
  factory $ProgressionCopyWith(Progression value, $Res Function(Progression) _then) = _$ProgressionCopyWithImpl;
@useResult
$Res call({
 int total, int comptes, int ecarts
});




}
/// @nodoc
class _$ProgressionCopyWithImpl<$Res>
    implements $ProgressionCopyWith<$Res> {
  _$ProgressionCopyWithImpl(this._self, this._then);

  final Progression _self;
  final $Res Function(Progression) _then;

/// Create a copy of Progression
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = null,Object? comptes = null,Object? ecarts = null,}) {
  return _then(Progression(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,comptes: null == comptes ? _self.comptes : comptes // ignore: cast_nullable_to_non_nullable
as int,ecarts: null == ecarts ? _self.ecarts : ecarts // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Progression].
extension ProgressionPatterns on Progression {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Progression value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Progression() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Progression value)  $default,){
final _that = this;
switch (_that) {
case _Progression():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Progression value)?  $default,){
final _that = this;
switch (_that) {
case _Progression() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int total,  int comptes,  int ecarts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Progression() when $default != null:
return $default(_that.total,_that.comptes,_that.ecarts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int total,  int comptes,  int ecarts)  $default,) {final _that = this;
switch (_that) {
case _Progression():
return $default(_that.total,_that.comptes,_that.ecarts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int total,  int comptes,  int ecarts)?  $default,) {final _that = this;
switch (_that) {
case _Progression() when $default != null:
return $default(_that.total,_that.comptes,_that.ecarts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Progression implements Progression {
  const _Progression({this.total = 0, this.comptes = 0, this.ecarts = 0});
  factory _Progression.fromJson(Map<String, dynamic> json) => _$ProgressionFromJson(json);

@override@JsonKey() final  int total;
@override@JsonKey() final  int comptes;
@override@JsonKey() final  int ecarts;

/// Create a copy of Progression
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProgressionCopyWith<_Progression> get copyWith => __$ProgressionCopyWithImpl<_Progression>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProgressionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Progression&&(identical(other.total, total) || other.total == total)&&(identical(other.comptes, comptes) || other.comptes == comptes)&&(identical(other.ecarts, ecarts) || other.ecarts == ecarts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,total,comptes,ecarts);
}

@override
String toString() {
    return 'Progression(total: $total, comptes: $comptes, ecarts: $ecarts)';
}


}

/// @nodoc
abstract mixin class _$ProgressionCopyWith<$Res> implements $ProgressionCopyWith<$Res> {
  factory _$ProgressionCopyWith(_Progression value, $Res Function(_Progression) _then) = __$ProgressionCopyWithImpl;
@override @useResult
$Res call({
 int total, int comptes, int ecarts
});




}
/// @nodoc
class __$ProgressionCopyWithImpl<$Res>
    implements _$ProgressionCopyWith<$Res> {
  __$ProgressionCopyWithImpl(this._self, this._then);

  final _Progression _self;
  final $Res Function(_Progression) _then;

/// Create a copy of Progression
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = null,Object? comptes = null,Object? ecarts = null,}) {
  return _then(_Progression(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,comptes: null == comptes ? _self.comptes : comptes // ignore: cast_nullable_to_non_nullable
as int,ecarts: null == ecarts ? _self.ecarts : ecarts // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Exactitude {

@JsonKey(name: 'comptes_mois') int get comptesMois;@JsonKey(name: 'exactitude_pct') int? get exactitudePct;@JsonKey(name: 'classe_a_pct') int? get classeAPct;@JsonKey(name: 'a_corriger') int get aCorriger;
/// Create a copy of Exactitude
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExactitudeCopyWith<Exactitude> get copyWith => _$ExactitudeCopyWithImpl<Exactitude>(this as Exactitude, _$identity);

  /// Serializes this Exactitude to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Exactitude;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Exactitude&&(identical(other.comptesMois, _this.comptesMois) || other.comptesMois == _this.comptesMois)&&(identical(other.exactitudePct, _this.exactitudePct) || other.exactitudePct == _this.exactitudePct)&&(identical(other.classeAPct, _this.classeAPct) || other.classeAPct == _this.classeAPct)&&(identical(other.aCorriger, _this.aCorriger) || other.aCorriger == _this.aCorriger));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Exactitude;
  return Object.hash(runtimeType,_this.comptesMois,_this.exactitudePct,_this.classeAPct,_this.aCorriger);
}

@override
String toString() {
  final _this = this as Exactitude;
  return 'Exactitude(comptesMois: ${_this.comptesMois}, exactitudePct: ${_this.exactitudePct}, classeAPct: ${_this.classeAPct}, aCorriger: ${_this.aCorriger})';
}


}

/// @nodoc
abstract mixin class $ExactitudeCopyWith<$Res>  {
  factory $ExactitudeCopyWith(Exactitude value, $Res Function(Exactitude) _then) = _$ExactitudeCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'comptes_mois') int comptesMois,@JsonKey(name: 'exactitude_pct') int? exactitudePct,@JsonKey(name: 'classe_a_pct') int? classeAPct,@JsonKey(name: 'a_corriger') int aCorriger
});




}
/// @nodoc
class _$ExactitudeCopyWithImpl<$Res>
    implements $ExactitudeCopyWith<$Res> {
  _$ExactitudeCopyWithImpl(this._self, this._then);

  final Exactitude _self;
  final $Res Function(Exactitude) _then;

/// Create a copy of Exactitude
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? comptesMois = null,Object? exactitudePct = freezed,Object? classeAPct = freezed,Object? aCorriger = null,}) {
  return _then(Exactitude(
comptesMois: null == comptesMois ? _self.comptesMois : comptesMois // ignore: cast_nullable_to_non_nullable
as int,exactitudePct: freezed == exactitudePct ? _self.exactitudePct : exactitudePct // ignore: cast_nullable_to_non_nullable
as int?,classeAPct: freezed == classeAPct ? _self.classeAPct : classeAPct // ignore: cast_nullable_to_non_nullable
as int?,aCorriger: null == aCorriger ? _self.aCorriger : aCorriger // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Exactitude].
extension ExactitudePatterns on Exactitude {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Exactitude value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Exactitude() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Exactitude value)  $default,){
final _that = this;
switch (_that) {
case _Exactitude():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Exactitude value)?  $default,){
final _that = this;
switch (_that) {
case _Exactitude() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'comptes_mois')  int comptesMois, @JsonKey(name: 'exactitude_pct')  int? exactitudePct, @JsonKey(name: 'classe_a_pct')  int? classeAPct, @JsonKey(name: 'a_corriger')  int aCorriger)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Exactitude() when $default != null:
return $default(_that.comptesMois,_that.exactitudePct,_that.classeAPct,_that.aCorriger);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'comptes_mois')  int comptesMois, @JsonKey(name: 'exactitude_pct')  int? exactitudePct, @JsonKey(name: 'classe_a_pct')  int? classeAPct, @JsonKey(name: 'a_corriger')  int aCorriger)  $default,) {final _that = this;
switch (_that) {
case _Exactitude():
return $default(_that.comptesMois,_that.exactitudePct,_that.classeAPct,_that.aCorriger);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'comptes_mois')  int comptesMois, @JsonKey(name: 'exactitude_pct')  int? exactitudePct, @JsonKey(name: 'classe_a_pct')  int? classeAPct, @JsonKey(name: 'a_corriger')  int aCorriger)?  $default,) {final _that = this;
switch (_that) {
case _Exactitude() when $default != null:
return $default(_that.comptesMois,_that.exactitudePct,_that.classeAPct,_that.aCorriger);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Exactitude implements Exactitude {
  const _Exactitude({@JsonKey(name: 'comptes_mois') this.comptesMois = 0, @JsonKey(name: 'exactitude_pct') this.exactitudePct, @JsonKey(name: 'classe_a_pct') this.classeAPct, @JsonKey(name: 'a_corriger') this.aCorriger = 0});
  factory _Exactitude.fromJson(Map<String, dynamic> json) => _$ExactitudeFromJson(json);

@override@JsonKey(name: 'comptes_mois') final  int comptesMois;
@override@JsonKey(name: 'exactitude_pct') final  int? exactitudePct;
@override@JsonKey(name: 'classe_a_pct') final  int? classeAPct;
@override@JsonKey(name: 'a_corriger') final  int aCorriger;

/// Create a copy of Exactitude
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExactitudeCopyWith<_Exactitude> get copyWith => __$ExactitudeCopyWithImpl<_Exactitude>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExactitudeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Exactitude&&(identical(other.comptesMois, comptesMois) || other.comptesMois == comptesMois)&&(identical(other.exactitudePct, exactitudePct) || other.exactitudePct == exactitudePct)&&(identical(other.classeAPct, classeAPct) || other.classeAPct == classeAPct)&&(identical(other.aCorriger, aCorriger) || other.aCorriger == aCorriger));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,comptesMois,exactitudePct,classeAPct,aCorriger);
}

@override
String toString() {
    return 'Exactitude(comptesMois: $comptesMois, exactitudePct: $exactitudePct, classeAPct: $classeAPct, aCorriger: $aCorriger)';
}


}

/// @nodoc
abstract mixin class _$ExactitudeCopyWith<$Res> implements $ExactitudeCopyWith<$Res> {
  factory _$ExactitudeCopyWith(_Exactitude value, $Res Function(_Exactitude) _then) = __$ExactitudeCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'comptes_mois') int comptesMois,@JsonKey(name: 'exactitude_pct') int? exactitudePct,@JsonKey(name: 'classe_a_pct') int? classeAPct,@JsonKey(name: 'a_corriger') int aCorriger
});




}
/// @nodoc
class __$ExactitudeCopyWithImpl<$Res>
    implements _$ExactitudeCopyWith<$Res> {
  __$ExactitudeCopyWithImpl(this._self, this._then);

  final _Exactitude _self;
  final $Res Function(_Exactitude) _then;

/// Create a copy of Exactitude
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? comptesMois = null,Object? exactitudePct = freezed,Object? classeAPct = freezed,Object? aCorriger = null,}) {
  return _then(_Exactitude(
comptesMois: null == comptesMois ? _self.comptesMois : comptesMois // ignore: cast_nullable_to_non_nullable
as int,exactitudePct: freezed == exactitudePct ? _self.exactitudePct : exactitudePct // ignore: cast_nullable_to_non_nullable
as int?,classeAPct: freezed == classeAPct ? _self.classeAPct : classeAPct // ignore: cast_nullable_to_non_nullable
as int?,aCorriger: null == aCorriger ? _self.aCorriger : aCorriger // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$JourneeInventaire {

 DateTime get jour;@JsonKey(name: 'a_compter') List<ProduitACompter> get aCompter; List<Comptage> get comptes; Progression get progression; Exactitude get exactitude;@JsonKey(name: 'a_corriger') List<Comptage> get aCorriger;
/// Create a copy of JourneeInventaire
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JourneeInventaireCopyWith<JourneeInventaire> get copyWith => _$JourneeInventaireCopyWithImpl<JourneeInventaire>(this as JourneeInventaire, _$identity);

  /// Serializes this JourneeInventaire to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as JourneeInventaire;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JourneeInventaire&&(identical(other.jour, _this.jour) || other.jour == _this.jour)&&const DeepCollectionEquality().equals(other.aCompter, _this.aCompter)&&const DeepCollectionEquality().equals(other.comptes, _this.comptes)&&(identical(other.progression, _this.progression) || other.progression == _this.progression)&&(identical(other.exactitude, _this.exactitude) || other.exactitude == _this.exactitude)&&const DeepCollectionEquality().equals(other.aCorriger, _this.aCorriger));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as JourneeInventaire;
  return Object.hash(runtimeType,_this.jour,const DeepCollectionEquality().hash(_this.aCompter),const DeepCollectionEquality().hash(_this.comptes),_this.progression,_this.exactitude,const DeepCollectionEquality().hash(_this.aCorriger));
}

@override
String toString() {
  final _this = this as JourneeInventaire;
  return 'JourneeInventaire(jour: ${_this.jour}, aCompter: ${_this.aCompter}, comptes: ${_this.comptes}, progression: ${_this.progression}, exactitude: ${_this.exactitude}, aCorriger: ${_this.aCorriger})';
}


}

/// @nodoc
abstract mixin class $JourneeInventaireCopyWith<$Res>  {
  factory $JourneeInventaireCopyWith(JourneeInventaire value, $Res Function(JourneeInventaire) _then) = _$JourneeInventaireCopyWithImpl;
@useResult
$Res call({
 DateTime jour,@JsonKey(name: 'a_compter') List<ProduitACompter> aCompter, List<Comptage> comptes, Progression progression, Exactitude exactitude,@JsonKey(name: 'a_corriger') List<Comptage> aCorriger
});


$ProgressionCopyWith<$Res> get progression;$ExactitudeCopyWith<$Res> get exactitude;

}
/// @nodoc
class _$JourneeInventaireCopyWithImpl<$Res>
    implements $JourneeInventaireCopyWith<$Res> {
  _$JourneeInventaireCopyWithImpl(this._self, this._then);

  final JourneeInventaire _self;
  final $Res Function(JourneeInventaire) _then;

/// Create a copy of JourneeInventaire
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jour = null,Object? aCompter = null,Object? comptes = null,Object? progression = null,Object? exactitude = null,Object? aCorriger = null,}) {
  return _then(JourneeInventaire(
jour: null == jour ? _self.jour : jour // ignore: cast_nullable_to_non_nullable
as DateTime,aCompter: null == aCompter ? _self.aCompter : aCompter // ignore: cast_nullable_to_non_nullable
as List<ProduitACompter>,comptes: null == comptes ? _self.comptes : comptes // ignore: cast_nullable_to_non_nullable
as List<Comptage>,progression: null == progression ? _self.progression : progression // ignore: cast_nullable_to_non_nullable
as Progression,exactitude: null == exactitude ? _self.exactitude : exactitude // ignore: cast_nullable_to_non_nullable
as Exactitude,aCorriger: null == aCorriger ? _self.aCorriger : aCorriger // ignore: cast_nullable_to_non_nullable
as List<Comptage>,
  ));
}
/// Create a copy of JourneeInventaire
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProgressionCopyWith<$Res> get progression {
  
  return $ProgressionCopyWith<$Res>(_self.progression, (value) {
    return _then(_self.copyWith(progression: value));
  });
}/// Create a copy of JourneeInventaire
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExactitudeCopyWith<$Res> get exactitude {
  
  return $ExactitudeCopyWith<$Res>(_self.exactitude, (value) {
    return _then(_self.copyWith(exactitude: value));
  });
}
}


/// Adds pattern-matching-related methods to [JourneeInventaire].
extension JourneeInventairePatterns on JourneeInventaire {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JourneeInventaire value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JourneeInventaire() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JourneeInventaire value)  $default,){
final _that = this;
switch (_that) {
case _JourneeInventaire():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JourneeInventaire value)?  $default,){
final _that = this;
switch (_that) {
case _JourneeInventaire() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime jour, @JsonKey(name: 'a_compter')  List<ProduitACompter> aCompter,  List<Comptage> comptes,  Progression progression,  Exactitude exactitude, @JsonKey(name: 'a_corriger')  List<Comptage> aCorriger)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JourneeInventaire() when $default != null:
return $default(_that.jour,_that.aCompter,_that.comptes,_that.progression,_that.exactitude,_that.aCorriger);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime jour, @JsonKey(name: 'a_compter')  List<ProduitACompter> aCompter,  List<Comptage> comptes,  Progression progression,  Exactitude exactitude, @JsonKey(name: 'a_corriger')  List<Comptage> aCorriger)  $default,) {final _that = this;
switch (_that) {
case _JourneeInventaire():
return $default(_that.jour,_that.aCompter,_that.comptes,_that.progression,_that.exactitude,_that.aCorriger);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime jour, @JsonKey(name: 'a_compter')  List<ProduitACompter> aCompter,  List<Comptage> comptes,  Progression progression,  Exactitude exactitude, @JsonKey(name: 'a_corriger')  List<Comptage> aCorriger)?  $default,) {final _that = this;
switch (_that) {
case _JourneeInventaire() when $default != null:
return $default(_that.jour,_that.aCompter,_that.comptes,_that.progression,_that.exactitude,_that.aCorriger);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JourneeInventaire implements JourneeInventaire {
  const _JourneeInventaire({required this.jour, @JsonKey(name: 'a_compter')  List<ProduitACompter> aCompter = const <ProduitACompter>[],  List<Comptage> comptes = const <Comptage>[], this.progression = const Progression(), this.exactitude = const Exactitude(), @JsonKey(name: 'a_corriger')  List<Comptage> aCorriger = const <Comptage>[]}): _aCompter = aCompter,_comptes = comptes,_aCorriger = aCorriger;
  factory _JourneeInventaire.fromJson(Map<String, dynamic> json) => _$JourneeInventaireFromJson(json);

@override final  DateTime jour;
 final  List<ProduitACompter> _aCompter;
@override@JsonKey(name: 'a_compter') List<ProduitACompter> get aCompter {
  if (_aCompter is EqualUnmodifiableListView) return _aCompter;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_aCompter);
}

 final  List<Comptage> _comptes;
@override@JsonKey() List<Comptage> get comptes {
  if (_comptes is EqualUnmodifiableListView) return _comptes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_comptes);
}

@override@JsonKey() final  Progression progression;
@override@JsonKey() final  Exactitude exactitude;
 final  List<Comptage> _aCorriger;
@override@JsonKey(name: 'a_corriger') List<Comptage> get aCorriger {
  if (_aCorriger is EqualUnmodifiableListView) return _aCorriger;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_aCorriger);
}


/// Create a copy of JourneeInventaire
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JourneeInventaireCopyWith<_JourneeInventaire> get copyWith => __$JourneeInventaireCopyWithImpl<_JourneeInventaire>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JourneeInventaireToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _JourneeInventaire&&(identical(other.jour, jour) || other.jour == jour)&&const DeepCollectionEquality().equals(other.aCompter, _aCompter)&&const DeepCollectionEquality().equals(other.comptes, _comptes)&&(identical(other.progression, progression) || other.progression == progression)&&(identical(other.exactitude, exactitude) || other.exactitude == exactitude)&&const DeepCollectionEquality().equals(other.aCorriger, _aCorriger));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,jour,const DeepCollectionEquality().hash(_aCompter),const DeepCollectionEquality().hash(_comptes),progression,exactitude,const DeepCollectionEquality().hash(_aCorriger));
}

@override
String toString() {
    return 'JourneeInventaire(jour: $jour, aCompter: $aCompter, comptes: $comptes, progression: $progression, exactitude: $exactitude, aCorriger: $aCorriger)';
}


}

/// @nodoc
abstract mixin class _$JourneeInventaireCopyWith<$Res> implements $JourneeInventaireCopyWith<$Res> {
  factory _$JourneeInventaireCopyWith(_JourneeInventaire value, $Res Function(_JourneeInventaire) _then) = __$JourneeInventaireCopyWithImpl;
@override @useResult
$Res call({
 DateTime jour,@JsonKey(name: 'a_compter') List<ProduitACompter> aCompter, List<Comptage> comptes, Progression progression, Exactitude exactitude,@JsonKey(name: 'a_corriger') List<Comptage> aCorriger
});


@override $ProgressionCopyWith<$Res> get progression;@override $ExactitudeCopyWith<$Res> get exactitude;

}
/// @nodoc
class __$JourneeInventaireCopyWithImpl<$Res>
    implements _$JourneeInventaireCopyWith<$Res> {
  __$JourneeInventaireCopyWithImpl(this._self, this._then);

  final _JourneeInventaire _self;
  final $Res Function(_JourneeInventaire) _then;

/// Create a copy of JourneeInventaire
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jour = null,Object? aCompter = null,Object? comptes = null,Object? progression = null,Object? exactitude = null,Object? aCorriger = null,}) {
  return _then(_JourneeInventaire(
jour: null == jour ? _self.jour : jour // ignore: cast_nullable_to_non_nullable
as DateTime,aCompter: null == aCompter ? _self._aCompter : aCompter // ignore: cast_nullable_to_non_nullable
as List<ProduitACompter>,comptes: null == comptes ? _self._comptes : comptes // ignore: cast_nullable_to_non_nullable
as List<Comptage>,progression: null == progression ? _self.progression : progression // ignore: cast_nullable_to_non_nullable
as Progression,exactitude: null == exactitude ? _self.exactitude : exactitude // ignore: cast_nullable_to_non_nullable
as Exactitude,aCorriger: null == aCorriger ? _self._aCorriger : aCorriger // ignore: cast_nullable_to_non_nullable
as List<Comptage>,
  ));
}

/// Create a copy of JourneeInventaire
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProgressionCopyWith<$Res> get progression {
  
  return $ProgressionCopyWith<$Res>(_self.progression, (value) {
    return _then(_self.copyWith(progression: value));
  });
}/// Create a copy of JourneeInventaire
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExactitudeCopyWith<$Res> get exactitude {
  
  return $ExactitudeCopyWith<$Res>(_self.exactitude, (value) {
    return _then(_self.copyWith(exactitude: value));
  });
}
}

// dart format on
