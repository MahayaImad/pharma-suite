// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FamilleStock {

 int? get id; String get famille;@JsonKey(name: 'produits_actifs') int get produitsActifs;@JsonKey(name: 'produits_en_stock') int get produitsEnStock;
/// Create a copy of FamilleStock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FamilleStockCopyWith<FamilleStock> get copyWith => _$FamilleStockCopyWithImpl<FamilleStock>(this as FamilleStock, _$identity);

  /// Serializes this FamilleStock to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FamilleStock;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FamilleStock&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.famille, _this.famille) || other.famille == _this.famille)&&(identical(other.produitsActifs, _this.produitsActifs) || other.produitsActifs == _this.produitsActifs)&&(identical(other.produitsEnStock, _this.produitsEnStock) || other.produitsEnStock == _this.produitsEnStock));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FamilleStock;
  return Object.hash(runtimeType,_this.id,_this.famille,_this.produitsActifs,_this.produitsEnStock);
}

@override
String toString() {
  final _this = this as FamilleStock;
  return 'FamilleStock(id: ${_this.id}, famille: ${_this.famille}, produitsActifs: ${_this.produitsActifs}, produitsEnStock: ${_this.produitsEnStock})';
}


}

/// @nodoc
abstract mixin class $FamilleStockCopyWith<$Res>  {
  factory $FamilleStockCopyWith(FamilleStock value, $Res Function(FamilleStock) _then) = _$FamilleStockCopyWithImpl;
@useResult
$Res call({
 int? id, String famille,@JsonKey(name: 'produits_actifs') int produitsActifs,@JsonKey(name: 'produits_en_stock') int produitsEnStock
});




}
/// @nodoc
class _$FamilleStockCopyWithImpl<$Res>
    implements $FamilleStockCopyWith<$Res> {
  _$FamilleStockCopyWithImpl(this._self, this._then);

  final FamilleStock _self;
  final $Res Function(FamilleStock) _then;

/// Create a copy of FamilleStock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? famille = null,Object? produitsActifs = null,Object? produitsEnStock = null,}) {
  return _then(FamilleStock(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,famille: null == famille ? _self.famille : famille // ignore: cast_nullable_to_non_nullable
as String,produitsActifs: null == produitsActifs ? _self.produitsActifs : produitsActifs // ignore: cast_nullable_to_non_nullable
as int,produitsEnStock: null == produitsEnStock ? _self.produitsEnStock : produitsEnStock // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FamilleStock].
extension FamilleStockPatterns on FamilleStock {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FamilleStock value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FamilleStock() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FamilleStock value)  $default,){
final _that = this;
switch (_that) {
case _FamilleStock():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FamilleStock value)?  $default,){
final _that = this;
switch (_that) {
case _FamilleStock() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String famille, @JsonKey(name: 'produits_actifs')  int produitsActifs, @JsonKey(name: 'produits_en_stock')  int produitsEnStock)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FamilleStock() when $default != null:
return $default(_that.id,_that.famille,_that.produitsActifs,_that.produitsEnStock);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String famille, @JsonKey(name: 'produits_actifs')  int produitsActifs, @JsonKey(name: 'produits_en_stock')  int produitsEnStock)  $default,) {final _that = this;
switch (_that) {
case _FamilleStock():
return $default(_that.id,_that.famille,_that.produitsActifs,_that.produitsEnStock);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String famille, @JsonKey(name: 'produits_actifs')  int produitsActifs, @JsonKey(name: 'produits_en_stock')  int produitsEnStock)?  $default,) {final _that = this;
switch (_that) {
case _FamilleStock() when $default != null:
return $default(_that.id,_that.famille,_that.produitsActifs,_that.produitsEnStock);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FamilleStock implements FamilleStock {
  const _FamilleStock({this.id, required this.famille, @JsonKey(name: 'produits_actifs') this.produitsActifs = 0, @JsonKey(name: 'produits_en_stock') this.produitsEnStock = 0});
  factory _FamilleStock.fromJson(Map<String, dynamic> json) => _$FamilleStockFromJson(json);

@override final  int? id;
@override final  String famille;
@override@JsonKey(name: 'produits_actifs') final  int produitsActifs;
@override@JsonKey(name: 'produits_en_stock') final  int produitsEnStock;

/// Create a copy of FamilleStock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FamilleStockCopyWith<_FamilleStock> get copyWith => __$FamilleStockCopyWithImpl<_FamilleStock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FamilleStockToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FamilleStock&&(identical(other.id, id) || other.id == id)&&(identical(other.famille, famille) || other.famille == famille)&&(identical(other.produitsActifs, produitsActifs) || other.produitsActifs == produitsActifs)&&(identical(other.produitsEnStock, produitsEnStock) || other.produitsEnStock == produitsEnStock));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,famille,produitsActifs,produitsEnStock);
}

@override
String toString() {
    return 'FamilleStock(id: $id, famille: $famille, produitsActifs: $produitsActifs, produitsEnStock: $produitsEnStock)';
}


}

/// @nodoc
abstract mixin class _$FamilleStockCopyWith<$Res> implements $FamilleStockCopyWith<$Res> {
  factory _$FamilleStockCopyWith(_FamilleStock value, $Res Function(_FamilleStock) _then) = __$FamilleStockCopyWithImpl;
@override @useResult
$Res call({
 int? id, String famille,@JsonKey(name: 'produits_actifs') int produitsActifs,@JsonKey(name: 'produits_en_stock') int produitsEnStock
});




}
/// @nodoc
class __$FamilleStockCopyWithImpl<$Res>
    implements _$FamilleStockCopyWith<$Res> {
  __$FamilleStockCopyWithImpl(this._self, this._then);

  final _FamilleStock _self;
  final $Res Function(_FamilleStock) _then;

/// Create a copy of FamilleStock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? famille = null,Object? produitsActifs = null,Object? produitsEnStock = null,}) {
  return _then(_FamilleStock(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,famille: null == famille ? _self.famille : famille // ignore: cast_nullable_to_non_nullable
as String,produitsActifs: null == produitsActifs ? _self.produitsActifs : produitsActifs // ignore: cast_nullable_to_non_nullable
as int,produitsEnStock: null == produitsEnStock ? _self.produitsEnStock : produitsEnStock // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ResumeStock {

/// Heure du dernier calcul du stock, en UTC ; null s'il n'a jamais eu lieu.
@JsonKey(name: 'donnees_du') DateTime? get donneesDu;@JsonKey(name: 'produits_actifs') int get produitsActifs;@JsonKey(name: 'produits_en_stock') int get produitsEnStock;@JsonKey(name: 'valeur_achat') double get valeurAchat;@JsonKey(name: 'valeur_vente') double get valeurVente; List<FamilleStock> get familles;
/// Create a copy of ResumeStock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResumeStockCopyWith<ResumeStock> get copyWith => _$ResumeStockCopyWithImpl<ResumeStock>(this as ResumeStock, _$identity);

  /// Serializes this ResumeStock to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ResumeStock;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResumeStock&&(identical(other.donneesDu, _this.donneesDu) || other.donneesDu == _this.donneesDu)&&(identical(other.produitsActifs, _this.produitsActifs) || other.produitsActifs == _this.produitsActifs)&&(identical(other.produitsEnStock, _this.produitsEnStock) || other.produitsEnStock == _this.produitsEnStock)&&(identical(other.valeurAchat, _this.valeurAchat) || other.valeurAchat == _this.valeurAchat)&&(identical(other.valeurVente, _this.valeurVente) || other.valeurVente == _this.valeurVente)&&const DeepCollectionEquality().equals(other.familles, _this.familles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ResumeStock;
  return Object.hash(runtimeType,_this.donneesDu,_this.produitsActifs,_this.produitsEnStock,_this.valeurAchat,_this.valeurVente,const DeepCollectionEquality().hash(_this.familles));
}

@override
String toString() {
  final _this = this as ResumeStock;
  return 'ResumeStock(donneesDu: ${_this.donneesDu}, produitsActifs: ${_this.produitsActifs}, produitsEnStock: ${_this.produitsEnStock}, valeurAchat: ${_this.valeurAchat}, valeurVente: ${_this.valeurVente}, familles: ${_this.familles})';
}


}

/// @nodoc
abstract mixin class $ResumeStockCopyWith<$Res>  {
  factory $ResumeStockCopyWith(ResumeStock value, $Res Function(ResumeStock) _then) = _$ResumeStockCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'donnees_du') DateTime? donneesDu,@JsonKey(name: 'produits_actifs') int produitsActifs,@JsonKey(name: 'produits_en_stock') int produitsEnStock,@JsonKey(name: 'valeur_achat') double valeurAchat,@JsonKey(name: 'valeur_vente') double valeurVente, List<FamilleStock> familles
});




}
/// @nodoc
class _$ResumeStockCopyWithImpl<$Res>
    implements $ResumeStockCopyWith<$Res> {
  _$ResumeStockCopyWithImpl(this._self, this._then);

  final ResumeStock _self;
  final $Res Function(ResumeStock) _then;

/// Create a copy of ResumeStock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? donneesDu = freezed,Object? produitsActifs = null,Object? produitsEnStock = null,Object? valeurAchat = null,Object? valeurVente = null,Object? familles = null,}) {
  return _then(ResumeStock(
donneesDu: freezed == donneesDu ? _self.donneesDu : donneesDu // ignore: cast_nullable_to_non_nullable
as DateTime?,produitsActifs: null == produitsActifs ? _self.produitsActifs : produitsActifs // ignore: cast_nullable_to_non_nullable
as int,produitsEnStock: null == produitsEnStock ? _self.produitsEnStock : produitsEnStock // ignore: cast_nullable_to_non_nullable
as int,valeurAchat: null == valeurAchat ? _self.valeurAchat : valeurAchat // ignore: cast_nullable_to_non_nullable
as double,valeurVente: null == valeurVente ? _self.valeurVente : valeurVente // ignore: cast_nullable_to_non_nullable
as double,familles: null == familles ? _self.familles : familles // ignore: cast_nullable_to_non_nullable
as List<FamilleStock>,
  ));
}

}


/// Adds pattern-matching-related methods to [ResumeStock].
extension ResumeStockPatterns on ResumeStock {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResumeStock value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResumeStock() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResumeStock value)  $default,){
final _that = this;
switch (_that) {
case _ResumeStock():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResumeStock value)?  $default,){
final _that = this;
switch (_that) {
case _ResumeStock() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'donnees_du')  DateTime? donneesDu, @JsonKey(name: 'produits_actifs')  int produitsActifs, @JsonKey(name: 'produits_en_stock')  int produitsEnStock, @JsonKey(name: 'valeur_achat')  double valeurAchat, @JsonKey(name: 'valeur_vente')  double valeurVente,  List<FamilleStock> familles)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResumeStock() when $default != null:
return $default(_that.donneesDu,_that.produitsActifs,_that.produitsEnStock,_that.valeurAchat,_that.valeurVente,_that.familles);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'donnees_du')  DateTime? donneesDu, @JsonKey(name: 'produits_actifs')  int produitsActifs, @JsonKey(name: 'produits_en_stock')  int produitsEnStock, @JsonKey(name: 'valeur_achat')  double valeurAchat, @JsonKey(name: 'valeur_vente')  double valeurVente,  List<FamilleStock> familles)  $default,) {final _that = this;
switch (_that) {
case _ResumeStock():
return $default(_that.donneesDu,_that.produitsActifs,_that.produitsEnStock,_that.valeurAchat,_that.valeurVente,_that.familles);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'donnees_du')  DateTime? donneesDu, @JsonKey(name: 'produits_actifs')  int produitsActifs, @JsonKey(name: 'produits_en_stock')  int produitsEnStock, @JsonKey(name: 'valeur_achat')  double valeurAchat, @JsonKey(name: 'valeur_vente')  double valeurVente,  List<FamilleStock> familles)?  $default,) {final _that = this;
switch (_that) {
case _ResumeStock() when $default != null:
return $default(_that.donneesDu,_that.produitsActifs,_that.produitsEnStock,_that.valeurAchat,_that.valeurVente,_that.familles);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ResumeStock implements ResumeStock {
  const _ResumeStock({@JsonKey(name: 'donnees_du') this.donneesDu, @JsonKey(name: 'produits_actifs') this.produitsActifs = 0, @JsonKey(name: 'produits_en_stock') this.produitsEnStock = 0, @JsonKey(name: 'valeur_achat') this.valeurAchat = 0, @JsonKey(name: 'valeur_vente') this.valeurVente = 0,  List<FamilleStock> familles = const <FamilleStock>[]}): _familles = familles;
  factory _ResumeStock.fromJson(Map<String, dynamic> json) => _$ResumeStockFromJson(json);

/// Heure du dernier calcul du stock, en UTC ; null s'il n'a jamais eu lieu.
@override@JsonKey(name: 'donnees_du') final  DateTime? donneesDu;
@override@JsonKey(name: 'produits_actifs') final  int produitsActifs;
@override@JsonKey(name: 'produits_en_stock') final  int produitsEnStock;
@override@JsonKey(name: 'valeur_achat') final  double valeurAchat;
@override@JsonKey(name: 'valeur_vente') final  double valeurVente;
 final  List<FamilleStock> _familles;
@override@JsonKey() List<FamilleStock> get familles {
  if (_familles is EqualUnmodifiableListView) return _familles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_familles);
}


/// Create a copy of ResumeStock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResumeStockCopyWith<_ResumeStock> get copyWith => __$ResumeStockCopyWithImpl<_ResumeStock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ResumeStockToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResumeStock&&(identical(other.donneesDu, donneesDu) || other.donneesDu == donneesDu)&&(identical(other.produitsActifs, produitsActifs) || other.produitsActifs == produitsActifs)&&(identical(other.produitsEnStock, produitsEnStock) || other.produitsEnStock == produitsEnStock)&&(identical(other.valeurAchat, valeurAchat) || other.valeurAchat == valeurAchat)&&(identical(other.valeurVente, valeurVente) || other.valeurVente == valeurVente)&&const DeepCollectionEquality().equals(other.familles, _familles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,donneesDu,produitsActifs,produitsEnStock,valeurAchat,valeurVente,const DeepCollectionEquality().hash(_familles));
}

@override
String toString() {
    return 'ResumeStock(donneesDu: $donneesDu, produitsActifs: $produitsActifs, produitsEnStock: $produitsEnStock, valeurAchat: $valeurAchat, valeurVente: $valeurVente, familles: $familles)';
}


}

/// @nodoc
abstract mixin class _$ResumeStockCopyWith<$Res> implements $ResumeStockCopyWith<$Res> {
  factory _$ResumeStockCopyWith(_ResumeStock value, $Res Function(_ResumeStock) _then) = __$ResumeStockCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'donnees_du') DateTime? donneesDu,@JsonKey(name: 'produits_actifs') int produitsActifs,@JsonKey(name: 'produits_en_stock') int produitsEnStock,@JsonKey(name: 'valeur_achat') double valeurAchat,@JsonKey(name: 'valeur_vente') double valeurVente, List<FamilleStock> familles
});




}
/// @nodoc
class __$ResumeStockCopyWithImpl<$Res>
    implements _$ResumeStockCopyWith<$Res> {
  __$ResumeStockCopyWithImpl(this._self, this._then);

  final _ResumeStock _self;
  final $Res Function(_ResumeStock) _then;

/// Create a copy of ResumeStock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? donneesDu = freezed,Object? produitsActifs = null,Object? produitsEnStock = null,Object? valeurAchat = null,Object? valeurVente = null,Object? familles = null,}) {
  return _then(_ResumeStock(
donneesDu: freezed == donneesDu ? _self.donneesDu : donneesDu // ignore: cast_nullable_to_non_nullable
as DateTime?,produitsActifs: null == produitsActifs ? _self.produitsActifs : produitsActifs // ignore: cast_nullable_to_non_nullable
as int,produitsEnStock: null == produitsEnStock ? _self.produitsEnStock : produitsEnStock // ignore: cast_nullable_to_non_nullable
as int,valeurAchat: null == valeurAchat ? _self.valeurAchat : valeurAchat // ignore: cast_nullable_to_non_nullable
as double,valeurVente: null == valeurVente ? _self.valeurVente : valeurVente // ignore: cast_nullable_to_non_nullable
as double,familles: null == familles ? _self._familles : familles // ignore: cast_nullable_to_non_nullable
as List<FamilleStock>,
  ));
}


}


/// @nodoc
mixin _$Produit {

 int get id; String get nom; String? get dci; String? get dosage; String? get forme;@JsonKey(name: 'forme_abr') String? get formeAbr;@JsonKey(name: 'id_famille') int? get idFamille; String? get famille; String? get labo;@JsonKey(name: 'code_barre_original') String? get codeBarre; String? get conditionnement; double get stock;@JsonKey(name: 'qte_alerte') int? get seuil;@JsonKey(name: 'prix_vente') double get prixVente;@JsonKey(name: 'prix_achat_moyen') double get prixAchat;@JsonKey(name: 'valeur_achat') double get valeurAchat;@JsonKey(name: 'valeur_vente') double get valeurVente;@JsonKey(name: 'qte_vendue_12m') int? get vendu12Mois;@JsonKey(name: 'derniere_vente') DateTime? get derniereVente; bool get actif;@JsonKey(name: 'segment_abc') String? get classeAbc;@JsonKey(name: 'segment_xyz') String? get classeXyz; String? get categorie; String? get disponibilite; int? get psychotrope;@JsonKey(name: 'remb_cvm') int? get remboursable; double get cmm;@JsonKey(name: 'stock_securite') int get stockSecurite;@JsonKey(name: 'stock_maximum') int get stockMaximum;@JsonKey(name: 'couverture_jours') int? get couverture;@JsonKey(name: 'qte_a_risque') int get qteARisque;@JsonKey(name: 'valeur_a_risque') double get valeurARisque;@JsonKey(name: 'qte_surstock') int get qteSurstock;@JsonKey(name: 'valeur_surstock') double get valeurSurstock;
/// Create a copy of Produit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProduitCopyWith<Produit> get copyWith => _$ProduitCopyWithImpl<Produit>(this as Produit, _$identity);

  /// Serializes this Produit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Produit;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Produit&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nom, _this.nom) || other.nom == _this.nom)&&(identical(other.dci, _this.dci) || other.dci == _this.dci)&&(identical(other.dosage, _this.dosage) || other.dosage == _this.dosage)&&(identical(other.forme, _this.forme) || other.forme == _this.forme)&&(identical(other.formeAbr, _this.formeAbr) || other.formeAbr == _this.formeAbr)&&(identical(other.idFamille, _this.idFamille) || other.idFamille == _this.idFamille)&&(identical(other.famille, _this.famille) || other.famille == _this.famille)&&(identical(other.labo, _this.labo) || other.labo == _this.labo)&&(identical(other.codeBarre, _this.codeBarre) || other.codeBarre == _this.codeBarre)&&(identical(other.conditionnement, _this.conditionnement) || other.conditionnement == _this.conditionnement)&&(identical(other.stock, _this.stock) || other.stock == _this.stock)&&(identical(other.seuil, _this.seuil) || other.seuil == _this.seuil)&&(identical(other.prixVente, _this.prixVente) || other.prixVente == _this.prixVente)&&(identical(other.prixAchat, _this.prixAchat) || other.prixAchat == _this.prixAchat)&&(identical(other.valeurAchat, _this.valeurAchat) || other.valeurAchat == _this.valeurAchat)&&(identical(other.valeurVente, _this.valeurVente) || other.valeurVente == _this.valeurVente)&&(identical(other.vendu12Mois, _this.vendu12Mois) || other.vendu12Mois == _this.vendu12Mois)&&(identical(other.derniereVente, _this.derniereVente) || other.derniereVente == _this.derniereVente)&&(identical(other.actif, _this.actif) || other.actif == _this.actif)&&(identical(other.classeAbc, _this.classeAbc) || other.classeAbc == _this.classeAbc)&&(identical(other.classeXyz, _this.classeXyz) || other.classeXyz == _this.classeXyz)&&(identical(other.categorie, _this.categorie) || other.categorie == _this.categorie)&&(identical(other.disponibilite, _this.disponibilite) || other.disponibilite == _this.disponibilite)&&(identical(other.psychotrope, _this.psychotrope) || other.psychotrope == _this.psychotrope)&&(identical(other.remboursable, _this.remboursable) || other.remboursable == _this.remboursable)&&(identical(other.cmm, _this.cmm) || other.cmm == _this.cmm)&&(identical(other.stockSecurite, _this.stockSecurite) || other.stockSecurite == _this.stockSecurite)&&(identical(other.stockMaximum, _this.stockMaximum) || other.stockMaximum == _this.stockMaximum)&&(identical(other.couverture, _this.couverture) || other.couverture == _this.couverture)&&(identical(other.qteARisque, _this.qteARisque) || other.qteARisque == _this.qteARisque)&&(identical(other.valeurARisque, _this.valeurARisque) || other.valeurARisque == _this.valeurARisque)&&(identical(other.qteSurstock, _this.qteSurstock) || other.qteSurstock == _this.qteSurstock)&&(identical(other.valeurSurstock, _this.valeurSurstock) || other.valeurSurstock == _this.valeurSurstock));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Produit;
  return Object.hashAll([runtimeType,_this.id,_this.nom,_this.dci,_this.dosage,_this.forme,_this.formeAbr,_this.idFamille,_this.famille,_this.labo,_this.codeBarre,_this.conditionnement,_this.stock,_this.seuil,_this.prixVente,_this.prixAchat,_this.valeurAchat,_this.valeurVente,_this.vendu12Mois,_this.derniereVente,_this.actif,_this.classeAbc,_this.classeXyz,_this.categorie,_this.disponibilite,_this.psychotrope,_this.remboursable,_this.cmm,_this.stockSecurite,_this.stockMaximum,_this.couverture,_this.qteARisque,_this.valeurARisque,_this.qteSurstock,_this.valeurSurstock]);
}

@override
String toString() {
  final _this = this as Produit;
  return 'Produit(id: ${_this.id}, nom: ${_this.nom}, dci: ${_this.dci}, dosage: ${_this.dosage}, forme: ${_this.forme}, formeAbr: ${_this.formeAbr}, idFamille: ${_this.idFamille}, famille: ${_this.famille}, labo: ${_this.labo}, codeBarre: ${_this.codeBarre}, conditionnement: ${_this.conditionnement}, stock: ${_this.stock}, seuil: ${_this.seuil}, prixVente: ${_this.prixVente}, prixAchat: ${_this.prixAchat}, valeurAchat: ${_this.valeurAchat}, valeurVente: ${_this.valeurVente}, vendu12Mois: ${_this.vendu12Mois}, derniereVente: ${_this.derniereVente}, actif: ${_this.actif}, classeAbc: ${_this.classeAbc}, classeXyz: ${_this.classeXyz}, categorie: ${_this.categorie}, disponibilite: ${_this.disponibilite}, psychotrope: ${_this.psychotrope}, remboursable: ${_this.remboursable}, cmm: ${_this.cmm}, stockSecurite: ${_this.stockSecurite}, stockMaximum: ${_this.stockMaximum}, couverture: ${_this.couverture}, qteARisque: ${_this.qteARisque}, valeurARisque: ${_this.valeurARisque}, qteSurstock: ${_this.qteSurstock}, valeurSurstock: ${_this.valeurSurstock})';
}


}

/// @nodoc
abstract mixin class $ProduitCopyWith<$Res>  {
  factory $ProduitCopyWith(Produit value, $Res Function(Produit) _then) = _$ProduitCopyWithImpl;
@useResult
$Res call({
 int id, String nom, String? dci, String? dosage, String? forme,@JsonKey(name: 'forme_abr') String? formeAbr,@JsonKey(name: 'id_famille') int? idFamille, String? famille, String? labo,@JsonKey(name: 'code_barre_original') String? codeBarre, String? conditionnement, double stock,@JsonKey(name: 'qte_alerte') int? seuil,@JsonKey(name: 'prix_vente') double prixVente,@JsonKey(name: 'prix_achat_moyen') double prixAchat,@JsonKey(name: 'valeur_achat') double valeurAchat,@JsonKey(name: 'valeur_vente') double valeurVente,@JsonKey(name: 'qte_vendue_12m') int? vendu12Mois,@JsonKey(name: 'derniere_vente') DateTime? derniereVente, bool actif,@JsonKey(name: 'segment_abc') String? classeAbc,@JsonKey(name: 'segment_xyz') String? classeXyz, String? categorie, String? disponibilite, int? psychotrope,@JsonKey(name: 'remb_cvm') int? remboursable, double cmm,@JsonKey(name: 'stock_securite') int stockSecurite,@JsonKey(name: 'stock_maximum') int stockMaximum,@JsonKey(name: 'couverture_jours') int? couverture,@JsonKey(name: 'qte_a_risque') int qteARisque,@JsonKey(name: 'valeur_a_risque') double valeurARisque,@JsonKey(name: 'qte_surstock') int qteSurstock,@JsonKey(name: 'valeur_surstock') double valeurSurstock
});




}
/// @nodoc
class _$ProduitCopyWithImpl<$Res>
    implements $ProduitCopyWith<$Res> {
  _$ProduitCopyWithImpl(this._self, this._then);

  final Produit _self;
  final $Res Function(Produit) _then;

/// Create a copy of Produit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nom = null,Object? dci = freezed,Object? dosage = freezed,Object? forme = freezed,Object? formeAbr = freezed,Object? idFamille = freezed,Object? famille = freezed,Object? labo = freezed,Object? codeBarre = freezed,Object? conditionnement = freezed,Object? stock = null,Object? seuil = freezed,Object? prixVente = null,Object? prixAchat = null,Object? valeurAchat = null,Object? valeurVente = null,Object? vendu12Mois = freezed,Object? derniereVente = freezed,Object? actif = null,Object? classeAbc = freezed,Object? classeXyz = freezed,Object? categorie = freezed,Object? disponibilite = freezed,Object? psychotrope = freezed,Object? remboursable = freezed,Object? cmm = null,Object? stockSecurite = null,Object? stockMaximum = null,Object? couverture = freezed,Object? qteARisque = null,Object? valeurARisque = null,Object? qteSurstock = null,Object? valeurSurstock = null,}) {
  return _then(Produit(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,dci: freezed == dci ? _self.dci : dci // ignore: cast_nullable_to_non_nullable
as String?,dosage: freezed == dosage ? _self.dosage : dosage // ignore: cast_nullable_to_non_nullable
as String?,forme: freezed == forme ? _self.forme : forme // ignore: cast_nullable_to_non_nullable
as String?,formeAbr: freezed == formeAbr ? _self.formeAbr : formeAbr // ignore: cast_nullable_to_non_nullable
as String?,idFamille: freezed == idFamille ? _self.idFamille : idFamille // ignore: cast_nullable_to_non_nullable
as int?,famille: freezed == famille ? _self.famille : famille // ignore: cast_nullable_to_non_nullable
as String?,labo: freezed == labo ? _self.labo : labo // ignore: cast_nullable_to_non_nullable
as String?,codeBarre: freezed == codeBarre ? _self.codeBarre : codeBarre // ignore: cast_nullable_to_non_nullable
as String?,conditionnement: freezed == conditionnement ? _self.conditionnement : conditionnement // ignore: cast_nullable_to_non_nullable
as String?,stock: null == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as double,seuil: freezed == seuil ? _self.seuil : seuil // ignore: cast_nullable_to_non_nullable
as int?,prixVente: null == prixVente ? _self.prixVente : prixVente // ignore: cast_nullable_to_non_nullable
as double,prixAchat: null == prixAchat ? _self.prixAchat : prixAchat // ignore: cast_nullable_to_non_nullable
as double,valeurAchat: null == valeurAchat ? _self.valeurAchat : valeurAchat // ignore: cast_nullable_to_non_nullable
as double,valeurVente: null == valeurVente ? _self.valeurVente : valeurVente // ignore: cast_nullable_to_non_nullable
as double,vendu12Mois: freezed == vendu12Mois ? _self.vendu12Mois : vendu12Mois // ignore: cast_nullable_to_non_nullable
as int?,derniereVente: freezed == derniereVente ? _self.derniereVente : derniereVente // ignore: cast_nullable_to_non_nullable
as DateTime?,actif: null == actif ? _self.actif : actif // ignore: cast_nullable_to_non_nullable
as bool,classeAbc: freezed == classeAbc ? _self.classeAbc : classeAbc // ignore: cast_nullable_to_non_nullable
as String?,classeXyz: freezed == classeXyz ? _self.classeXyz : classeXyz // ignore: cast_nullable_to_non_nullable
as String?,categorie: freezed == categorie ? _self.categorie : categorie // ignore: cast_nullable_to_non_nullable
as String?,disponibilite: freezed == disponibilite ? _self.disponibilite : disponibilite // ignore: cast_nullable_to_non_nullable
as String?,psychotrope: freezed == psychotrope ? _self.psychotrope : psychotrope // ignore: cast_nullable_to_non_nullable
as int?,remboursable: freezed == remboursable ? _self.remboursable : remboursable // ignore: cast_nullable_to_non_nullable
as int?,cmm: null == cmm ? _self.cmm : cmm // ignore: cast_nullable_to_non_nullable
as double,stockSecurite: null == stockSecurite ? _self.stockSecurite : stockSecurite // ignore: cast_nullable_to_non_nullable
as int,stockMaximum: null == stockMaximum ? _self.stockMaximum : stockMaximum // ignore: cast_nullable_to_non_nullable
as int,couverture: freezed == couverture ? _self.couverture : couverture // ignore: cast_nullable_to_non_nullable
as int?,qteARisque: null == qteARisque ? _self.qteARisque : qteARisque // ignore: cast_nullable_to_non_nullable
as int,valeurARisque: null == valeurARisque ? _self.valeurARisque : valeurARisque // ignore: cast_nullable_to_non_nullable
as double,qteSurstock: null == qteSurstock ? _self.qteSurstock : qteSurstock // ignore: cast_nullable_to_non_nullable
as int,valeurSurstock: null == valeurSurstock ? _self.valeurSurstock : valeurSurstock // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Produit].
extension ProduitPatterns on Produit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Produit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Produit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Produit value)  $default,){
final _that = this;
switch (_that) {
case _Produit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Produit value)?  $default,){
final _that = this;
switch (_that) {
case _Produit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String nom,  String? dci,  String? dosage,  String? forme, @JsonKey(name: 'forme_abr')  String? formeAbr, @JsonKey(name: 'id_famille')  int? idFamille,  String? famille,  String? labo, @JsonKey(name: 'code_barre_original')  String? codeBarre,  String? conditionnement,  double stock, @JsonKey(name: 'qte_alerte')  int? seuil, @JsonKey(name: 'prix_vente')  double prixVente, @JsonKey(name: 'prix_achat_moyen')  double prixAchat, @JsonKey(name: 'valeur_achat')  double valeurAchat, @JsonKey(name: 'valeur_vente')  double valeurVente, @JsonKey(name: 'qte_vendue_12m')  int? vendu12Mois, @JsonKey(name: 'derniere_vente')  DateTime? derniereVente,  bool actif, @JsonKey(name: 'segment_abc')  String? classeAbc, @JsonKey(name: 'segment_xyz')  String? classeXyz,  String? categorie,  String? disponibilite,  int? psychotrope, @JsonKey(name: 'remb_cvm')  int? remboursable,  double cmm, @JsonKey(name: 'stock_securite')  int stockSecurite, @JsonKey(name: 'stock_maximum')  int stockMaximum, @JsonKey(name: 'couverture_jours')  int? couverture, @JsonKey(name: 'qte_a_risque')  int qteARisque, @JsonKey(name: 'valeur_a_risque')  double valeurARisque, @JsonKey(name: 'qte_surstock')  int qteSurstock, @JsonKey(name: 'valeur_surstock')  double valeurSurstock)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Produit() when $default != null:
return $default(_that.id,_that.nom,_that.dci,_that.dosage,_that.forme,_that.formeAbr,_that.idFamille,_that.famille,_that.labo,_that.codeBarre,_that.conditionnement,_that.stock,_that.seuil,_that.prixVente,_that.prixAchat,_that.valeurAchat,_that.valeurVente,_that.vendu12Mois,_that.derniereVente,_that.actif,_that.classeAbc,_that.classeXyz,_that.categorie,_that.disponibilite,_that.psychotrope,_that.remboursable,_that.cmm,_that.stockSecurite,_that.stockMaximum,_that.couverture,_that.qteARisque,_that.valeurARisque,_that.qteSurstock,_that.valeurSurstock);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String nom,  String? dci,  String? dosage,  String? forme, @JsonKey(name: 'forme_abr')  String? formeAbr, @JsonKey(name: 'id_famille')  int? idFamille,  String? famille,  String? labo, @JsonKey(name: 'code_barre_original')  String? codeBarre,  String? conditionnement,  double stock, @JsonKey(name: 'qte_alerte')  int? seuil, @JsonKey(name: 'prix_vente')  double prixVente, @JsonKey(name: 'prix_achat_moyen')  double prixAchat, @JsonKey(name: 'valeur_achat')  double valeurAchat, @JsonKey(name: 'valeur_vente')  double valeurVente, @JsonKey(name: 'qte_vendue_12m')  int? vendu12Mois, @JsonKey(name: 'derniere_vente')  DateTime? derniereVente,  bool actif, @JsonKey(name: 'segment_abc')  String? classeAbc, @JsonKey(name: 'segment_xyz')  String? classeXyz,  String? categorie,  String? disponibilite,  int? psychotrope, @JsonKey(name: 'remb_cvm')  int? remboursable,  double cmm, @JsonKey(name: 'stock_securite')  int stockSecurite, @JsonKey(name: 'stock_maximum')  int stockMaximum, @JsonKey(name: 'couverture_jours')  int? couverture, @JsonKey(name: 'qte_a_risque')  int qteARisque, @JsonKey(name: 'valeur_a_risque')  double valeurARisque, @JsonKey(name: 'qte_surstock')  int qteSurstock, @JsonKey(name: 'valeur_surstock')  double valeurSurstock)  $default,) {final _that = this;
switch (_that) {
case _Produit():
return $default(_that.id,_that.nom,_that.dci,_that.dosage,_that.forme,_that.formeAbr,_that.idFamille,_that.famille,_that.labo,_that.codeBarre,_that.conditionnement,_that.stock,_that.seuil,_that.prixVente,_that.prixAchat,_that.valeurAchat,_that.valeurVente,_that.vendu12Mois,_that.derniereVente,_that.actif,_that.classeAbc,_that.classeXyz,_that.categorie,_that.disponibilite,_that.psychotrope,_that.remboursable,_that.cmm,_that.stockSecurite,_that.stockMaximum,_that.couverture,_that.qteARisque,_that.valeurARisque,_that.qteSurstock,_that.valeurSurstock);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String nom,  String? dci,  String? dosage,  String? forme, @JsonKey(name: 'forme_abr')  String? formeAbr, @JsonKey(name: 'id_famille')  int? idFamille,  String? famille,  String? labo, @JsonKey(name: 'code_barre_original')  String? codeBarre,  String? conditionnement,  double stock, @JsonKey(name: 'qte_alerte')  int? seuil, @JsonKey(name: 'prix_vente')  double prixVente, @JsonKey(name: 'prix_achat_moyen')  double prixAchat, @JsonKey(name: 'valeur_achat')  double valeurAchat, @JsonKey(name: 'valeur_vente')  double valeurVente, @JsonKey(name: 'qte_vendue_12m')  int? vendu12Mois, @JsonKey(name: 'derniere_vente')  DateTime? derniereVente,  bool actif, @JsonKey(name: 'segment_abc')  String? classeAbc, @JsonKey(name: 'segment_xyz')  String? classeXyz,  String? categorie,  String? disponibilite,  int? psychotrope, @JsonKey(name: 'remb_cvm')  int? remboursable,  double cmm, @JsonKey(name: 'stock_securite')  int stockSecurite, @JsonKey(name: 'stock_maximum')  int stockMaximum, @JsonKey(name: 'couverture_jours')  int? couverture, @JsonKey(name: 'qte_a_risque')  int qteARisque, @JsonKey(name: 'valeur_a_risque')  double valeurARisque, @JsonKey(name: 'qte_surstock')  int qteSurstock, @JsonKey(name: 'valeur_surstock')  double valeurSurstock)?  $default,) {final _that = this;
switch (_that) {
case _Produit() when $default != null:
return $default(_that.id,_that.nom,_that.dci,_that.dosage,_that.forme,_that.formeAbr,_that.idFamille,_that.famille,_that.labo,_that.codeBarre,_that.conditionnement,_that.stock,_that.seuil,_that.prixVente,_that.prixAchat,_that.valeurAchat,_that.valeurVente,_that.vendu12Mois,_that.derniereVente,_that.actif,_that.classeAbc,_that.classeXyz,_that.categorie,_that.disponibilite,_that.psychotrope,_that.remboursable,_that.cmm,_that.stockSecurite,_that.stockMaximum,_that.couverture,_that.qteARisque,_that.valeurARisque,_that.qteSurstock,_that.valeurSurstock);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Produit extends Produit {
  const _Produit({required this.id, this.nom = '', this.dci, this.dosage, this.forme, @JsonKey(name: 'forme_abr') this.formeAbr, @JsonKey(name: 'id_famille') this.idFamille, this.famille, this.labo, @JsonKey(name: 'code_barre_original') this.codeBarre, this.conditionnement, this.stock = 0, @JsonKey(name: 'qte_alerte') this.seuil, @JsonKey(name: 'prix_vente') this.prixVente = 0, @JsonKey(name: 'prix_achat_moyen') this.prixAchat = 0, @JsonKey(name: 'valeur_achat') this.valeurAchat = 0, @JsonKey(name: 'valeur_vente') this.valeurVente = 0, @JsonKey(name: 'qte_vendue_12m') this.vendu12Mois, @JsonKey(name: 'derniere_vente') this.derniereVente, this.actif = false, @JsonKey(name: 'segment_abc') this.classeAbc, @JsonKey(name: 'segment_xyz') this.classeXyz, this.categorie, this.disponibilite, this.psychotrope, @JsonKey(name: 'remb_cvm') this.remboursable, this.cmm = 0, @JsonKey(name: 'stock_securite') this.stockSecurite = 0, @JsonKey(name: 'stock_maximum') this.stockMaximum = 0, @JsonKey(name: 'couverture_jours') this.couverture, @JsonKey(name: 'qte_a_risque') this.qteARisque = 0, @JsonKey(name: 'valeur_a_risque') this.valeurARisque = 0, @JsonKey(name: 'qte_surstock') this.qteSurstock = 0, @JsonKey(name: 'valeur_surstock') this.valeurSurstock = 0}): super._();
  factory _Produit.fromJson(Map<String, dynamic> json) => _$ProduitFromJson(json);

@override final  int id;
@override@JsonKey() final  String nom;
@override final  String? dci;
@override final  String? dosage;
@override final  String? forme;
@override@JsonKey(name: 'forme_abr') final  String? formeAbr;
@override@JsonKey(name: 'id_famille') final  int? idFamille;
@override final  String? famille;
@override final  String? labo;
@override@JsonKey(name: 'code_barre_original') final  String? codeBarre;
@override final  String? conditionnement;
@override@JsonKey() final  double stock;
@override@JsonKey(name: 'qte_alerte') final  int? seuil;
@override@JsonKey(name: 'prix_vente') final  double prixVente;
@override@JsonKey(name: 'prix_achat_moyen') final  double prixAchat;
@override@JsonKey(name: 'valeur_achat') final  double valeurAchat;
@override@JsonKey(name: 'valeur_vente') final  double valeurVente;
@override@JsonKey(name: 'qte_vendue_12m') final  int? vendu12Mois;
@override@JsonKey(name: 'derniere_vente') final  DateTime? derniereVente;
@override@JsonKey() final  bool actif;
@override@JsonKey(name: 'segment_abc') final  String? classeAbc;
@override@JsonKey(name: 'segment_xyz') final  String? classeXyz;
@override final  String? categorie;
@override final  String? disponibilite;
@override final  int? psychotrope;
@override@JsonKey(name: 'remb_cvm') final  int? remboursable;
@override@JsonKey() final  double cmm;
@override@JsonKey(name: 'stock_securite') final  int stockSecurite;
@override@JsonKey(name: 'stock_maximum') final  int stockMaximum;
@override@JsonKey(name: 'couverture_jours') final  int? couverture;
@override@JsonKey(name: 'qte_a_risque') final  int qteARisque;
@override@JsonKey(name: 'valeur_a_risque') final  double valeurARisque;
@override@JsonKey(name: 'qte_surstock') final  int qteSurstock;
@override@JsonKey(name: 'valeur_surstock') final  double valeurSurstock;

/// Create a copy of Produit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProduitCopyWith<_Produit> get copyWith => __$ProduitCopyWithImpl<_Produit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProduitToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Produit&&(identical(other.id, id) || other.id == id)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.dci, dci) || other.dci == dci)&&(identical(other.dosage, dosage) || other.dosage == dosage)&&(identical(other.forme, forme) || other.forme == forme)&&(identical(other.formeAbr, formeAbr) || other.formeAbr == formeAbr)&&(identical(other.idFamille, idFamille) || other.idFamille == idFamille)&&(identical(other.famille, famille) || other.famille == famille)&&(identical(other.labo, labo) || other.labo == labo)&&(identical(other.codeBarre, codeBarre) || other.codeBarre == codeBarre)&&(identical(other.conditionnement, conditionnement) || other.conditionnement == conditionnement)&&(identical(other.stock, stock) || other.stock == stock)&&(identical(other.seuil, seuil) || other.seuil == seuil)&&(identical(other.prixVente, prixVente) || other.prixVente == prixVente)&&(identical(other.prixAchat, prixAchat) || other.prixAchat == prixAchat)&&(identical(other.valeurAchat, valeurAchat) || other.valeurAchat == valeurAchat)&&(identical(other.valeurVente, valeurVente) || other.valeurVente == valeurVente)&&(identical(other.vendu12Mois, vendu12Mois) || other.vendu12Mois == vendu12Mois)&&(identical(other.derniereVente, derniereVente) || other.derniereVente == derniereVente)&&(identical(other.actif, actif) || other.actif == actif)&&(identical(other.classeAbc, classeAbc) || other.classeAbc == classeAbc)&&(identical(other.classeXyz, classeXyz) || other.classeXyz == classeXyz)&&(identical(other.categorie, categorie) || other.categorie == categorie)&&(identical(other.disponibilite, disponibilite) || other.disponibilite == disponibilite)&&(identical(other.psychotrope, psychotrope) || other.psychotrope == psychotrope)&&(identical(other.remboursable, remboursable) || other.remboursable == remboursable)&&(identical(other.cmm, cmm) || other.cmm == cmm)&&(identical(other.stockSecurite, stockSecurite) || other.stockSecurite == stockSecurite)&&(identical(other.stockMaximum, stockMaximum) || other.stockMaximum == stockMaximum)&&(identical(other.couverture, couverture) || other.couverture == couverture)&&(identical(other.qteARisque, qteARisque) || other.qteARisque == qteARisque)&&(identical(other.valeurARisque, valeurARisque) || other.valeurARisque == valeurARisque)&&(identical(other.qteSurstock, qteSurstock) || other.qteSurstock == qteSurstock)&&(identical(other.valeurSurstock, valeurSurstock) || other.valeurSurstock == valeurSurstock));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,nom,dci,dosage,forme,formeAbr,idFamille,famille,labo,codeBarre,conditionnement,stock,seuil,prixVente,prixAchat,valeurAchat,valeurVente,vendu12Mois,derniereVente,actif,classeAbc,classeXyz,categorie,disponibilite,psychotrope,remboursable,cmm,stockSecurite,stockMaximum,couverture,qteARisque,valeurARisque,qteSurstock,valeurSurstock]);
}

@override
String toString() {
    return 'Produit(id: $id, nom: $nom, dci: $dci, dosage: $dosage, forme: $forme, formeAbr: $formeAbr, idFamille: $idFamille, famille: $famille, labo: $labo, codeBarre: $codeBarre, conditionnement: $conditionnement, stock: $stock, seuil: $seuil, prixVente: $prixVente, prixAchat: $prixAchat, valeurAchat: $valeurAchat, valeurVente: $valeurVente, vendu12Mois: $vendu12Mois, derniereVente: $derniereVente, actif: $actif, classeAbc: $classeAbc, classeXyz: $classeXyz, categorie: $categorie, disponibilite: $disponibilite, psychotrope: $psychotrope, remboursable: $remboursable, cmm: $cmm, stockSecurite: $stockSecurite, stockMaximum: $stockMaximum, couverture: $couverture, qteARisque: $qteARisque, valeurARisque: $valeurARisque, qteSurstock: $qteSurstock, valeurSurstock: $valeurSurstock)';
}


}

/// @nodoc
abstract mixin class _$ProduitCopyWith<$Res> implements $ProduitCopyWith<$Res> {
  factory _$ProduitCopyWith(_Produit value, $Res Function(_Produit) _then) = __$ProduitCopyWithImpl;
@override @useResult
$Res call({
 int id, String nom, String? dci, String? dosage, String? forme,@JsonKey(name: 'forme_abr') String? formeAbr,@JsonKey(name: 'id_famille') int? idFamille, String? famille, String? labo,@JsonKey(name: 'code_barre_original') String? codeBarre, String? conditionnement, double stock,@JsonKey(name: 'qte_alerte') int? seuil,@JsonKey(name: 'prix_vente') double prixVente,@JsonKey(name: 'prix_achat_moyen') double prixAchat,@JsonKey(name: 'valeur_achat') double valeurAchat,@JsonKey(name: 'valeur_vente') double valeurVente,@JsonKey(name: 'qte_vendue_12m') int? vendu12Mois,@JsonKey(name: 'derniere_vente') DateTime? derniereVente, bool actif,@JsonKey(name: 'segment_abc') String? classeAbc,@JsonKey(name: 'segment_xyz') String? classeXyz, String? categorie, String? disponibilite, int? psychotrope,@JsonKey(name: 'remb_cvm') int? remboursable, double cmm,@JsonKey(name: 'stock_securite') int stockSecurite,@JsonKey(name: 'stock_maximum') int stockMaximum,@JsonKey(name: 'couverture_jours') int? couverture,@JsonKey(name: 'qte_a_risque') int qteARisque,@JsonKey(name: 'valeur_a_risque') double valeurARisque,@JsonKey(name: 'qte_surstock') int qteSurstock,@JsonKey(name: 'valeur_surstock') double valeurSurstock
});




}
/// @nodoc
class __$ProduitCopyWithImpl<$Res>
    implements _$ProduitCopyWith<$Res> {
  __$ProduitCopyWithImpl(this._self, this._then);

  final _Produit _self;
  final $Res Function(_Produit) _then;

/// Create a copy of Produit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nom = null,Object? dci = freezed,Object? dosage = freezed,Object? forme = freezed,Object? formeAbr = freezed,Object? idFamille = freezed,Object? famille = freezed,Object? labo = freezed,Object? codeBarre = freezed,Object? conditionnement = freezed,Object? stock = null,Object? seuil = freezed,Object? prixVente = null,Object? prixAchat = null,Object? valeurAchat = null,Object? valeurVente = null,Object? vendu12Mois = freezed,Object? derniereVente = freezed,Object? actif = null,Object? classeAbc = freezed,Object? classeXyz = freezed,Object? categorie = freezed,Object? disponibilite = freezed,Object? psychotrope = freezed,Object? remboursable = freezed,Object? cmm = null,Object? stockSecurite = null,Object? stockMaximum = null,Object? couverture = freezed,Object? qteARisque = null,Object? valeurARisque = null,Object? qteSurstock = null,Object? valeurSurstock = null,}) {
  return _then(_Produit(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,dci: freezed == dci ? _self.dci : dci // ignore: cast_nullable_to_non_nullable
as String?,dosage: freezed == dosage ? _self.dosage : dosage // ignore: cast_nullable_to_non_nullable
as String?,forme: freezed == forme ? _self.forme : forme // ignore: cast_nullable_to_non_nullable
as String?,formeAbr: freezed == formeAbr ? _self.formeAbr : formeAbr // ignore: cast_nullable_to_non_nullable
as String?,idFamille: freezed == idFamille ? _self.idFamille : idFamille // ignore: cast_nullable_to_non_nullable
as int?,famille: freezed == famille ? _self.famille : famille // ignore: cast_nullable_to_non_nullable
as String?,labo: freezed == labo ? _self.labo : labo // ignore: cast_nullable_to_non_nullable
as String?,codeBarre: freezed == codeBarre ? _self.codeBarre : codeBarre // ignore: cast_nullable_to_non_nullable
as String?,conditionnement: freezed == conditionnement ? _self.conditionnement : conditionnement // ignore: cast_nullable_to_non_nullable
as String?,stock: null == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as double,seuil: freezed == seuil ? _self.seuil : seuil // ignore: cast_nullable_to_non_nullable
as int?,prixVente: null == prixVente ? _self.prixVente : prixVente // ignore: cast_nullable_to_non_nullable
as double,prixAchat: null == prixAchat ? _self.prixAchat : prixAchat // ignore: cast_nullable_to_non_nullable
as double,valeurAchat: null == valeurAchat ? _self.valeurAchat : valeurAchat // ignore: cast_nullable_to_non_nullable
as double,valeurVente: null == valeurVente ? _self.valeurVente : valeurVente // ignore: cast_nullable_to_non_nullable
as double,vendu12Mois: freezed == vendu12Mois ? _self.vendu12Mois : vendu12Mois // ignore: cast_nullable_to_non_nullable
as int?,derniereVente: freezed == derniereVente ? _self.derniereVente : derniereVente // ignore: cast_nullable_to_non_nullable
as DateTime?,actif: null == actif ? _self.actif : actif // ignore: cast_nullable_to_non_nullable
as bool,classeAbc: freezed == classeAbc ? _self.classeAbc : classeAbc // ignore: cast_nullable_to_non_nullable
as String?,classeXyz: freezed == classeXyz ? _self.classeXyz : classeXyz // ignore: cast_nullable_to_non_nullable
as String?,categorie: freezed == categorie ? _self.categorie : categorie // ignore: cast_nullable_to_non_nullable
as String?,disponibilite: freezed == disponibilite ? _self.disponibilite : disponibilite // ignore: cast_nullable_to_non_nullable
as String?,psychotrope: freezed == psychotrope ? _self.psychotrope : psychotrope // ignore: cast_nullable_to_non_nullable
as int?,remboursable: freezed == remboursable ? _self.remboursable : remboursable // ignore: cast_nullable_to_non_nullable
as int?,cmm: null == cmm ? _self.cmm : cmm // ignore: cast_nullable_to_non_nullable
as double,stockSecurite: null == stockSecurite ? _self.stockSecurite : stockSecurite // ignore: cast_nullable_to_non_nullable
as int,stockMaximum: null == stockMaximum ? _self.stockMaximum : stockMaximum // ignore: cast_nullable_to_non_nullable
as int,couverture: freezed == couverture ? _self.couverture : couverture // ignore: cast_nullable_to_non_nullable
as int?,qteARisque: null == qteARisque ? _self.qteARisque : qteARisque // ignore: cast_nullable_to_non_nullable
as int,valeurARisque: null == valeurARisque ? _self.valeurARisque : valeurARisque // ignore: cast_nullable_to_non_nullable
as double,qteSurstock: null == qteSurstock ? _self.qteSurstock : qteSurstock // ignore: cast_nullable_to_non_nullable
as int,valeurSurstock: null == valeurSurstock ? _self.valeurSurstock : valeurSurstock // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$Lot {

 int get id; String? get lot;/// Texte EASYPHARM, format MM/YY.
 String? get peremption;@JsonKey(name: 'peremption_date') DateTime? get peremptionDate; int get stock;@JsonKey(name: 'qte_entree') int get qteEntree;@JsonKey(name: 'prix_achat') double get prixAchat;@JsonKey(name: 'prix_vente') double get prixVente; String? get fournisseur;@JsonKey(name: 'date_entree') DateTime? get dateEntree;@JsonKey(name: 'num_bl') String? get numBl;@JsonKey(fromJson: _versBool) bool get bloque;
/// Create a copy of Lot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LotCopyWith<Lot> get copyWith => _$LotCopyWithImpl<Lot>(this as Lot, _$identity);

  /// Serializes this Lot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Lot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Lot&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.lot, _this.lot) || other.lot == _this.lot)&&(identical(other.peremption, _this.peremption) || other.peremption == _this.peremption)&&(identical(other.peremptionDate, _this.peremptionDate) || other.peremptionDate == _this.peremptionDate)&&(identical(other.stock, _this.stock) || other.stock == _this.stock)&&(identical(other.qteEntree, _this.qteEntree) || other.qteEntree == _this.qteEntree)&&(identical(other.prixAchat, _this.prixAchat) || other.prixAchat == _this.prixAchat)&&(identical(other.prixVente, _this.prixVente) || other.prixVente == _this.prixVente)&&(identical(other.fournisseur, _this.fournisseur) || other.fournisseur == _this.fournisseur)&&(identical(other.dateEntree, _this.dateEntree) || other.dateEntree == _this.dateEntree)&&(identical(other.numBl, _this.numBl) || other.numBl == _this.numBl)&&(identical(other.bloque, _this.bloque) || other.bloque == _this.bloque));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Lot;
  return Object.hash(runtimeType,_this.id,_this.lot,_this.peremption,_this.peremptionDate,_this.stock,_this.qteEntree,_this.prixAchat,_this.prixVente,_this.fournisseur,_this.dateEntree,_this.numBl,_this.bloque);
}

@override
String toString() {
  final _this = this as Lot;
  return 'Lot(id: ${_this.id}, lot: ${_this.lot}, peremption: ${_this.peremption}, peremptionDate: ${_this.peremptionDate}, stock: ${_this.stock}, qteEntree: ${_this.qteEntree}, prixAchat: ${_this.prixAchat}, prixVente: ${_this.prixVente}, fournisseur: ${_this.fournisseur}, dateEntree: ${_this.dateEntree}, numBl: ${_this.numBl}, bloque: ${_this.bloque})';
}


}

/// @nodoc
abstract mixin class $LotCopyWith<$Res>  {
  factory $LotCopyWith(Lot value, $Res Function(Lot) _then) = _$LotCopyWithImpl;
@useResult
$Res call({
 int id, String? lot, String? peremption,@JsonKey(name: 'peremption_date') DateTime? peremptionDate, int stock,@JsonKey(name: 'qte_entree') int qteEntree,@JsonKey(name: 'prix_achat') double prixAchat,@JsonKey(name: 'prix_vente') double prixVente, String? fournisseur,@JsonKey(name: 'date_entree') DateTime? dateEntree,@JsonKey(name: 'num_bl') String? numBl,@JsonKey(fromJson: _versBool) bool bloque
});




}
/// @nodoc
class _$LotCopyWithImpl<$Res>
    implements $LotCopyWith<$Res> {
  _$LotCopyWithImpl(this._self, this._then);

  final Lot _self;
  final $Res Function(Lot) _then;

/// Create a copy of Lot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? lot = freezed,Object? peremption = freezed,Object? peremptionDate = freezed,Object? stock = null,Object? qteEntree = null,Object? prixAchat = null,Object? prixVente = null,Object? fournisseur = freezed,Object? dateEntree = freezed,Object? numBl = freezed,Object? bloque = null,}) {
  return _then(Lot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,lot: freezed == lot ? _self.lot : lot // ignore: cast_nullable_to_non_nullable
as String?,peremption: freezed == peremption ? _self.peremption : peremption // ignore: cast_nullable_to_non_nullable
as String?,peremptionDate: freezed == peremptionDate ? _self.peremptionDate : peremptionDate // ignore: cast_nullable_to_non_nullable
as DateTime?,stock: null == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as int,qteEntree: null == qteEntree ? _self.qteEntree : qteEntree // ignore: cast_nullable_to_non_nullable
as int,prixAchat: null == prixAchat ? _self.prixAchat : prixAchat // ignore: cast_nullable_to_non_nullable
as double,prixVente: null == prixVente ? _self.prixVente : prixVente // ignore: cast_nullable_to_non_nullable
as double,fournisseur: freezed == fournisseur ? _self.fournisseur : fournisseur // ignore: cast_nullable_to_non_nullable
as String?,dateEntree: freezed == dateEntree ? _self.dateEntree : dateEntree // ignore: cast_nullable_to_non_nullable
as DateTime?,numBl: freezed == numBl ? _self.numBl : numBl // ignore: cast_nullable_to_non_nullable
as String?,bloque: null == bloque ? _self.bloque : bloque // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Lot].
extension LotPatterns on Lot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Lot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Lot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Lot value)  $default,){
final _that = this;
switch (_that) {
case _Lot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Lot value)?  $default,){
final _that = this;
switch (_that) {
case _Lot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? lot,  String? peremption, @JsonKey(name: 'peremption_date')  DateTime? peremptionDate,  int stock, @JsonKey(name: 'qte_entree')  int qteEntree, @JsonKey(name: 'prix_achat')  double prixAchat, @JsonKey(name: 'prix_vente')  double prixVente,  String? fournisseur, @JsonKey(name: 'date_entree')  DateTime? dateEntree, @JsonKey(name: 'num_bl')  String? numBl, @JsonKey(fromJson: _versBool)  bool bloque)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Lot() when $default != null:
return $default(_that.id,_that.lot,_that.peremption,_that.peremptionDate,_that.stock,_that.qteEntree,_that.prixAchat,_that.prixVente,_that.fournisseur,_that.dateEntree,_that.numBl,_that.bloque);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? lot,  String? peremption, @JsonKey(name: 'peremption_date')  DateTime? peremptionDate,  int stock, @JsonKey(name: 'qte_entree')  int qteEntree, @JsonKey(name: 'prix_achat')  double prixAchat, @JsonKey(name: 'prix_vente')  double prixVente,  String? fournisseur, @JsonKey(name: 'date_entree')  DateTime? dateEntree, @JsonKey(name: 'num_bl')  String? numBl, @JsonKey(fromJson: _versBool)  bool bloque)  $default,) {final _that = this;
switch (_that) {
case _Lot():
return $default(_that.id,_that.lot,_that.peremption,_that.peremptionDate,_that.stock,_that.qteEntree,_that.prixAchat,_that.prixVente,_that.fournisseur,_that.dateEntree,_that.numBl,_that.bloque);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? lot,  String? peremption, @JsonKey(name: 'peremption_date')  DateTime? peremptionDate,  int stock, @JsonKey(name: 'qte_entree')  int qteEntree, @JsonKey(name: 'prix_achat')  double prixAchat, @JsonKey(name: 'prix_vente')  double prixVente,  String? fournisseur, @JsonKey(name: 'date_entree')  DateTime? dateEntree, @JsonKey(name: 'num_bl')  String? numBl, @JsonKey(fromJson: _versBool)  bool bloque)?  $default,) {final _that = this;
switch (_that) {
case _Lot() when $default != null:
return $default(_that.id,_that.lot,_that.peremption,_that.peremptionDate,_that.stock,_that.qteEntree,_that.prixAchat,_that.prixVente,_that.fournisseur,_that.dateEntree,_that.numBl,_that.bloque);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Lot implements Lot {
  const _Lot({required this.id, this.lot, this.peremption, @JsonKey(name: 'peremption_date') this.peremptionDate, this.stock = 0, @JsonKey(name: 'qte_entree') this.qteEntree = 0, @JsonKey(name: 'prix_achat') this.prixAchat = 0, @JsonKey(name: 'prix_vente') this.prixVente = 0, this.fournisseur, @JsonKey(name: 'date_entree') this.dateEntree, @JsonKey(name: 'num_bl') this.numBl, @JsonKey(fromJson: _versBool) this.bloque = false});
  factory _Lot.fromJson(Map<String, dynamic> json) => _$LotFromJson(json);

@override final  int id;
@override final  String? lot;
/// Texte EASYPHARM, format MM/YY.
@override final  String? peremption;
@override@JsonKey(name: 'peremption_date') final  DateTime? peremptionDate;
@override@JsonKey() final  int stock;
@override@JsonKey(name: 'qte_entree') final  int qteEntree;
@override@JsonKey(name: 'prix_achat') final  double prixAchat;
@override@JsonKey(name: 'prix_vente') final  double prixVente;
@override final  String? fournisseur;
@override@JsonKey(name: 'date_entree') final  DateTime? dateEntree;
@override@JsonKey(name: 'num_bl') final  String? numBl;
@override@JsonKey(fromJson: _versBool) final  bool bloque;

/// Create a copy of Lot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LotCopyWith<_Lot> get copyWith => __$LotCopyWithImpl<_Lot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LotToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Lot&&(identical(other.id, id) || other.id == id)&&(identical(other.lot, lot) || other.lot == lot)&&(identical(other.peremption, peremption) || other.peremption == peremption)&&(identical(other.peremptionDate, peremptionDate) || other.peremptionDate == peremptionDate)&&(identical(other.stock, stock) || other.stock == stock)&&(identical(other.qteEntree, qteEntree) || other.qteEntree == qteEntree)&&(identical(other.prixAchat, prixAchat) || other.prixAchat == prixAchat)&&(identical(other.prixVente, prixVente) || other.prixVente == prixVente)&&(identical(other.fournisseur, fournisseur) || other.fournisseur == fournisseur)&&(identical(other.dateEntree, dateEntree) || other.dateEntree == dateEntree)&&(identical(other.numBl, numBl) || other.numBl == numBl)&&(identical(other.bloque, bloque) || other.bloque == bloque));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,lot,peremption,peremptionDate,stock,qteEntree,prixAchat,prixVente,fournisseur,dateEntree,numBl,bloque);
}

@override
String toString() {
    return 'Lot(id: $id, lot: $lot, peremption: $peremption, peremptionDate: $peremptionDate, stock: $stock, qteEntree: $qteEntree, prixAchat: $prixAchat, prixVente: $prixVente, fournisseur: $fournisseur, dateEntree: $dateEntree, numBl: $numBl, bloque: $bloque)';
}


}

/// @nodoc
abstract mixin class _$LotCopyWith<$Res> implements $LotCopyWith<$Res> {
  factory _$LotCopyWith(_Lot value, $Res Function(_Lot) _then) = __$LotCopyWithImpl;
@override @useResult
$Res call({
 int id, String? lot, String? peremption,@JsonKey(name: 'peremption_date') DateTime? peremptionDate, int stock,@JsonKey(name: 'qte_entree') int qteEntree,@JsonKey(name: 'prix_achat') double prixAchat,@JsonKey(name: 'prix_vente') double prixVente, String? fournisseur,@JsonKey(name: 'date_entree') DateTime? dateEntree,@JsonKey(name: 'num_bl') String? numBl,@JsonKey(fromJson: _versBool) bool bloque
});




}
/// @nodoc
class __$LotCopyWithImpl<$Res>
    implements _$LotCopyWith<$Res> {
  __$LotCopyWithImpl(this._self, this._then);

  final _Lot _self;
  final $Res Function(_Lot) _then;

/// Create a copy of Lot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? lot = freezed,Object? peremption = freezed,Object? peremptionDate = freezed,Object? stock = null,Object? qteEntree = null,Object? prixAchat = null,Object? prixVente = null,Object? fournisseur = freezed,Object? dateEntree = freezed,Object? numBl = freezed,Object? bloque = null,}) {
  return _then(_Lot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,lot: freezed == lot ? _self.lot : lot // ignore: cast_nullable_to_non_nullable
as String?,peremption: freezed == peremption ? _self.peremption : peremption // ignore: cast_nullable_to_non_nullable
as String?,peremptionDate: freezed == peremptionDate ? _self.peremptionDate : peremptionDate // ignore: cast_nullable_to_non_nullable
as DateTime?,stock: null == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as int,qteEntree: null == qteEntree ? _self.qteEntree : qteEntree // ignore: cast_nullable_to_non_nullable
as int,prixAchat: null == prixAchat ? _self.prixAchat : prixAchat // ignore: cast_nullable_to_non_nullable
as double,prixVente: null == prixVente ? _self.prixVente : prixVente // ignore: cast_nullable_to_non_nullable
as double,fournisseur: freezed == fournisseur ? _self.fournisseur : fournisseur // ignore: cast_nullable_to_non_nullable
as String?,dateEntree: freezed == dateEntree ? _self.dateEntree : dateEntree // ignore: cast_nullable_to_non_nullable
as DateTime?,numBl: freezed == numBl ? _self.numBl : numBl // ignore: cast_nullable_to_non_nullable
as String?,bloque: null == bloque ? _self.bloque : bloque // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$RisqueLot {

 int get id;/// Durée de vie restante en jours ; null si la date est inconnue.
 int? get dvr;/// Ce que le lot vendra avant sa péremption ; null s'il est hors calcul
/// (bloqué, sans date).
 int? get ecoulable; int get stock;@JsonKey(name: 'a_risque') int? get aRisque;@JsonKey(name: 'valeur_a_risque') double? get valeurARisque;
/// Create a copy of RisqueLot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RisqueLotCopyWith<RisqueLot> get copyWith => _$RisqueLotCopyWithImpl<RisqueLot>(this as RisqueLot, _$identity);

  /// Serializes this RisqueLot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RisqueLot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RisqueLot&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.dvr, _this.dvr) || other.dvr == _this.dvr)&&(identical(other.ecoulable, _this.ecoulable) || other.ecoulable == _this.ecoulable)&&(identical(other.stock, _this.stock) || other.stock == _this.stock)&&(identical(other.aRisque, _this.aRisque) || other.aRisque == _this.aRisque)&&(identical(other.valeurARisque, _this.valeurARisque) || other.valeurARisque == _this.valeurARisque));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RisqueLot;
  return Object.hash(runtimeType,_this.id,_this.dvr,_this.ecoulable,_this.stock,_this.aRisque,_this.valeurARisque);
}

@override
String toString() {
  final _this = this as RisqueLot;
  return 'RisqueLot(id: ${_this.id}, dvr: ${_this.dvr}, ecoulable: ${_this.ecoulable}, stock: ${_this.stock}, aRisque: ${_this.aRisque}, valeurARisque: ${_this.valeurARisque})';
}


}

/// @nodoc
abstract mixin class $RisqueLotCopyWith<$Res>  {
  factory $RisqueLotCopyWith(RisqueLot value, $Res Function(RisqueLot) _then) = _$RisqueLotCopyWithImpl;
@useResult
$Res call({
 int id, int? dvr, int? ecoulable, int stock,@JsonKey(name: 'a_risque') int? aRisque,@JsonKey(name: 'valeur_a_risque') double? valeurARisque
});




}
/// @nodoc
class _$RisqueLotCopyWithImpl<$Res>
    implements $RisqueLotCopyWith<$Res> {
  _$RisqueLotCopyWithImpl(this._self, this._then);

  final RisqueLot _self;
  final $Res Function(RisqueLot) _then;

/// Create a copy of RisqueLot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? dvr = freezed,Object? ecoulable = freezed,Object? stock = null,Object? aRisque = freezed,Object? valeurARisque = freezed,}) {
  return _then(RisqueLot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,dvr: freezed == dvr ? _self.dvr : dvr // ignore: cast_nullable_to_non_nullable
as int?,ecoulable: freezed == ecoulable ? _self.ecoulable : ecoulable // ignore: cast_nullable_to_non_nullable
as int?,stock: null == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as int,aRisque: freezed == aRisque ? _self.aRisque : aRisque // ignore: cast_nullable_to_non_nullable
as int?,valeurARisque: freezed == valeurARisque ? _self.valeurARisque : valeurARisque // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [RisqueLot].
extension RisqueLotPatterns on RisqueLot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RisqueLot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RisqueLot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RisqueLot value)  $default,){
final _that = this;
switch (_that) {
case _RisqueLot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RisqueLot value)?  $default,){
final _that = this;
switch (_that) {
case _RisqueLot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int? dvr,  int? ecoulable,  int stock, @JsonKey(name: 'a_risque')  int? aRisque, @JsonKey(name: 'valeur_a_risque')  double? valeurARisque)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RisqueLot() when $default != null:
return $default(_that.id,_that.dvr,_that.ecoulable,_that.stock,_that.aRisque,_that.valeurARisque);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int? dvr,  int? ecoulable,  int stock, @JsonKey(name: 'a_risque')  int? aRisque, @JsonKey(name: 'valeur_a_risque')  double? valeurARisque)  $default,) {final _that = this;
switch (_that) {
case _RisqueLot():
return $default(_that.id,_that.dvr,_that.ecoulable,_that.stock,_that.aRisque,_that.valeurARisque);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int? dvr,  int? ecoulable,  int stock, @JsonKey(name: 'a_risque')  int? aRisque, @JsonKey(name: 'valeur_a_risque')  double? valeurARisque)?  $default,) {final _that = this;
switch (_that) {
case _RisqueLot() when $default != null:
return $default(_that.id,_that.dvr,_that.ecoulable,_that.stock,_that.aRisque,_that.valeurARisque);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RisqueLot implements RisqueLot {
  const _RisqueLot({required this.id, this.dvr, this.ecoulable, this.stock = 0, @JsonKey(name: 'a_risque') this.aRisque, @JsonKey(name: 'valeur_a_risque') this.valeurARisque});
  factory _RisqueLot.fromJson(Map<String, dynamic> json) => _$RisqueLotFromJson(json);

@override final  int id;
/// Durée de vie restante en jours ; null si la date est inconnue.
@override final  int? dvr;
/// Ce que le lot vendra avant sa péremption ; null s'il est hors calcul
/// (bloqué, sans date).
@override final  int? ecoulable;
@override@JsonKey() final  int stock;
@override@JsonKey(name: 'a_risque') final  int? aRisque;
@override@JsonKey(name: 'valeur_a_risque') final  double? valeurARisque;

/// Create a copy of RisqueLot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RisqueLotCopyWith<_RisqueLot> get copyWith => __$RisqueLotCopyWithImpl<_RisqueLot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RisqueLotToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RisqueLot&&(identical(other.id, id) || other.id == id)&&(identical(other.dvr, dvr) || other.dvr == dvr)&&(identical(other.ecoulable, ecoulable) || other.ecoulable == ecoulable)&&(identical(other.stock, stock) || other.stock == stock)&&(identical(other.aRisque, aRisque) || other.aRisque == aRisque)&&(identical(other.valeurARisque, valeurARisque) || other.valeurARisque == valeurARisque));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,dvr,ecoulable,stock,aRisque,valeurARisque);
}

@override
String toString() {
    return 'RisqueLot(id: $id, dvr: $dvr, ecoulable: $ecoulable, stock: $stock, aRisque: $aRisque, valeurARisque: $valeurARisque)';
}


}

/// @nodoc
abstract mixin class _$RisqueLotCopyWith<$Res> implements $RisqueLotCopyWith<$Res> {
  factory _$RisqueLotCopyWith(_RisqueLot value, $Res Function(_RisqueLot) _then) = __$RisqueLotCopyWithImpl;
@override @useResult
$Res call({
 int id, int? dvr, int? ecoulable, int stock,@JsonKey(name: 'a_risque') int? aRisque,@JsonKey(name: 'valeur_a_risque') double? valeurARisque
});




}
/// @nodoc
class __$RisqueLotCopyWithImpl<$Res>
    implements _$RisqueLotCopyWith<$Res> {
  __$RisqueLotCopyWithImpl(this._self, this._then);

  final _RisqueLot _self;
  final $Res Function(_RisqueLot) _then;

/// Create a copy of RisqueLot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? dvr = freezed,Object? ecoulable = freezed,Object? stock = null,Object? aRisque = freezed,Object? valeurARisque = freezed,}) {
  return _then(_RisqueLot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,dvr: freezed == dvr ? _self.dvr : dvr // ignore: cast_nullable_to_non_nullable
as int?,ecoulable: freezed == ecoulable ? _self.ecoulable : ecoulable // ignore: cast_nullable_to_non_nullable
as int?,stock: null == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as int,aRisque: freezed == aRisque ? _self.aRisque : aRisque // ignore: cast_nullable_to_non_nullable
as int?,valeurARisque: freezed == valeurARisque ? _self.valeurARisque : valeurARisque // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$FournisseurPrincipal {

 int? get id; String? get nom;@JsonKey(name: 'delai_jours_ouvres') int get delaiJoursOuvres;/// Faux : délai par défaut des réglages, non saisi pour ce fournisseur.
@JsonKey(name: 'delai_saisi') bool get delaiSaisi;
/// Create a copy of FournisseurPrincipal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FournisseurPrincipalCopyWith<FournisseurPrincipal> get copyWith => _$FournisseurPrincipalCopyWithImpl<FournisseurPrincipal>(this as FournisseurPrincipal, _$identity);

  /// Serializes this FournisseurPrincipal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FournisseurPrincipal;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FournisseurPrincipal&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nom, _this.nom) || other.nom == _this.nom)&&(identical(other.delaiJoursOuvres, _this.delaiJoursOuvres) || other.delaiJoursOuvres == _this.delaiJoursOuvres)&&(identical(other.delaiSaisi, _this.delaiSaisi) || other.delaiSaisi == _this.delaiSaisi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FournisseurPrincipal;
  return Object.hash(runtimeType,_this.id,_this.nom,_this.delaiJoursOuvres,_this.delaiSaisi);
}

@override
String toString() {
  final _this = this as FournisseurPrincipal;
  return 'FournisseurPrincipal(id: ${_this.id}, nom: ${_this.nom}, delaiJoursOuvres: ${_this.delaiJoursOuvres}, delaiSaisi: ${_this.delaiSaisi})';
}


}

/// @nodoc
abstract mixin class $FournisseurPrincipalCopyWith<$Res>  {
  factory $FournisseurPrincipalCopyWith(FournisseurPrincipal value, $Res Function(FournisseurPrincipal) _then) = _$FournisseurPrincipalCopyWithImpl;
@useResult
$Res call({
 int? id, String? nom,@JsonKey(name: 'delai_jours_ouvres') int delaiJoursOuvres,@JsonKey(name: 'delai_saisi') bool delaiSaisi
});




}
/// @nodoc
class _$FournisseurPrincipalCopyWithImpl<$Res>
    implements $FournisseurPrincipalCopyWith<$Res> {
  _$FournisseurPrincipalCopyWithImpl(this._self, this._then);

  final FournisseurPrincipal _self;
  final $Res Function(FournisseurPrincipal) _then;

/// Create a copy of FournisseurPrincipal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? nom = freezed,Object? delaiJoursOuvres = null,Object? delaiSaisi = null,}) {
  return _then(FournisseurPrincipal(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,nom: freezed == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String?,delaiJoursOuvres: null == delaiJoursOuvres ? _self.delaiJoursOuvres : delaiJoursOuvres // ignore: cast_nullable_to_non_nullable
as int,delaiSaisi: null == delaiSaisi ? _self.delaiSaisi : delaiSaisi // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FournisseurPrincipal].
extension FournisseurPrincipalPatterns on FournisseurPrincipal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FournisseurPrincipal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FournisseurPrincipal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FournisseurPrincipal value)  $default,){
final _that = this;
switch (_that) {
case _FournisseurPrincipal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FournisseurPrincipal value)?  $default,){
final _that = this;
switch (_that) {
case _FournisseurPrincipal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  String? nom, @JsonKey(name: 'delai_jours_ouvres')  int delaiJoursOuvres, @JsonKey(name: 'delai_saisi')  bool delaiSaisi)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FournisseurPrincipal() when $default != null:
return $default(_that.id,_that.nom,_that.delaiJoursOuvres,_that.delaiSaisi);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  String? nom, @JsonKey(name: 'delai_jours_ouvres')  int delaiJoursOuvres, @JsonKey(name: 'delai_saisi')  bool delaiSaisi)  $default,) {final _that = this;
switch (_that) {
case _FournisseurPrincipal():
return $default(_that.id,_that.nom,_that.delaiJoursOuvres,_that.delaiSaisi);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  String? nom, @JsonKey(name: 'delai_jours_ouvres')  int delaiJoursOuvres, @JsonKey(name: 'delai_saisi')  bool delaiSaisi)?  $default,) {final _that = this;
switch (_that) {
case _FournisseurPrincipal() when $default != null:
return $default(_that.id,_that.nom,_that.delaiJoursOuvres,_that.delaiSaisi);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FournisseurPrincipal implements FournisseurPrincipal {
  const _FournisseurPrincipal({this.id, this.nom, @JsonKey(name: 'delai_jours_ouvres') this.delaiJoursOuvres = 1, @JsonKey(name: 'delai_saisi') this.delaiSaisi = false});
  factory _FournisseurPrincipal.fromJson(Map<String, dynamic> json) => _$FournisseurPrincipalFromJson(json);

@override final  int? id;
@override final  String? nom;
@override@JsonKey(name: 'delai_jours_ouvres') final  int delaiJoursOuvres;
/// Faux : délai par défaut des réglages, non saisi pour ce fournisseur.
@override@JsonKey(name: 'delai_saisi') final  bool delaiSaisi;

/// Create a copy of FournisseurPrincipal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FournisseurPrincipalCopyWith<_FournisseurPrincipal> get copyWith => __$FournisseurPrincipalCopyWithImpl<_FournisseurPrincipal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FournisseurPrincipalToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FournisseurPrincipal&&(identical(other.id, id) || other.id == id)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.delaiJoursOuvres, delaiJoursOuvres) || other.delaiJoursOuvres == delaiJoursOuvres)&&(identical(other.delaiSaisi, delaiSaisi) || other.delaiSaisi == delaiSaisi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,nom,delaiJoursOuvres,delaiSaisi);
}

@override
String toString() {
    return 'FournisseurPrincipal(id: $id, nom: $nom, delaiJoursOuvres: $delaiJoursOuvres, delaiSaisi: $delaiSaisi)';
}


}

/// @nodoc
abstract mixin class _$FournisseurPrincipalCopyWith<$Res> implements $FournisseurPrincipalCopyWith<$Res> {
  factory _$FournisseurPrincipalCopyWith(_FournisseurPrincipal value, $Res Function(_FournisseurPrincipal) _then) = __$FournisseurPrincipalCopyWithImpl;
@override @useResult
$Res call({
 int? id, String? nom,@JsonKey(name: 'delai_jours_ouvres') int delaiJoursOuvres,@JsonKey(name: 'delai_saisi') bool delaiSaisi
});




}
/// @nodoc
class __$FournisseurPrincipalCopyWithImpl<$Res>
    implements _$FournisseurPrincipalCopyWith<$Res> {
  __$FournisseurPrincipalCopyWithImpl(this._self, this._then);

  final _FournisseurPrincipal _self;
  final $Res Function(_FournisseurPrincipal) _then;

/// Create a copy of FournisseurPrincipal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? nom = freezed,Object? delaiJoursOuvres = null,Object? delaiSaisi = null,}) {
  return _then(_FournisseurPrincipal(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,nom: freezed == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String?,delaiJoursOuvres: null == delaiJoursOuvres ? _self.delaiJoursOuvres : delaiJoursOuvres // ignore: cast_nullable_to_non_nullable
as int,delaiSaisi: null == delaiSaisi ? _self.delaiSaisi : delaiSaisi // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$IndicateursProduit {

@JsonKey(name: 'ventes_12_mois') double get ventes12Mois;@JsonKey(name: 'mois_historique') int get moisHistorique; double get cmm; double get cmj; FournisseurPrincipal? get fournisseur;@JsonKey(name: 'delai_livraison_jours') int get delaiLivraison;@JsonKey(name: 'date_livraison') DateTime? get dateLivraison;@JsonKey(name: 'stock_securite') int get stockSecurite;@JsonKey(name: 'stock_securite_simple') int get stockSecuriteSimple;@JsonKey(name: 'delai_securite_jours') double get delaiSecurite;@JsonKey(name: 'periode_commande_jours') double get periodeCommande;@JsonKey(name: 'stock_maximum') int get stockMaximum;@JsonKey(name: 'couverture_jours') int? get couverture;@JsonKey(name: 'dvr_max') int? get dvrMax;@JsonKey(name: 'qte_a_risque') int get qteARisque;@JsonKey(name: 'valeur_a_risque') double get valeurARisque; List<RisqueLot> get lots;
/// Create a copy of IndicateursProduit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IndicateursProduitCopyWith<IndicateursProduit> get copyWith => _$IndicateursProduitCopyWithImpl<IndicateursProduit>(this as IndicateursProduit, _$identity);

  /// Serializes this IndicateursProduit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as IndicateursProduit;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IndicateursProduit&&(identical(other.ventes12Mois, _this.ventes12Mois) || other.ventes12Mois == _this.ventes12Mois)&&(identical(other.moisHistorique, _this.moisHistorique) || other.moisHistorique == _this.moisHistorique)&&(identical(other.cmm, _this.cmm) || other.cmm == _this.cmm)&&(identical(other.cmj, _this.cmj) || other.cmj == _this.cmj)&&(identical(other.fournisseur, _this.fournisseur) || other.fournisseur == _this.fournisseur)&&(identical(other.delaiLivraison, _this.delaiLivraison) || other.delaiLivraison == _this.delaiLivraison)&&(identical(other.dateLivraison, _this.dateLivraison) || other.dateLivraison == _this.dateLivraison)&&(identical(other.stockSecurite, _this.stockSecurite) || other.stockSecurite == _this.stockSecurite)&&(identical(other.stockSecuriteSimple, _this.stockSecuriteSimple) || other.stockSecuriteSimple == _this.stockSecuriteSimple)&&(identical(other.delaiSecurite, _this.delaiSecurite) || other.delaiSecurite == _this.delaiSecurite)&&(identical(other.periodeCommande, _this.periodeCommande) || other.periodeCommande == _this.periodeCommande)&&(identical(other.stockMaximum, _this.stockMaximum) || other.stockMaximum == _this.stockMaximum)&&(identical(other.couverture, _this.couverture) || other.couverture == _this.couverture)&&(identical(other.dvrMax, _this.dvrMax) || other.dvrMax == _this.dvrMax)&&(identical(other.qteARisque, _this.qteARisque) || other.qteARisque == _this.qteARisque)&&(identical(other.valeurARisque, _this.valeurARisque) || other.valeurARisque == _this.valeurARisque)&&const DeepCollectionEquality().equals(other.lots, _this.lots));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as IndicateursProduit;
  return Object.hash(runtimeType,_this.ventes12Mois,_this.moisHistorique,_this.cmm,_this.cmj,_this.fournisseur,_this.delaiLivraison,_this.dateLivraison,_this.stockSecurite,_this.stockSecuriteSimple,_this.delaiSecurite,_this.periodeCommande,_this.stockMaximum,_this.couverture,_this.dvrMax,_this.qteARisque,_this.valeurARisque,const DeepCollectionEquality().hash(_this.lots));
}

@override
String toString() {
  final _this = this as IndicateursProduit;
  return 'IndicateursProduit(ventes12Mois: ${_this.ventes12Mois}, moisHistorique: ${_this.moisHistorique}, cmm: ${_this.cmm}, cmj: ${_this.cmj}, fournisseur: ${_this.fournisseur}, delaiLivraison: ${_this.delaiLivraison}, dateLivraison: ${_this.dateLivraison}, stockSecurite: ${_this.stockSecurite}, stockSecuriteSimple: ${_this.stockSecuriteSimple}, delaiSecurite: ${_this.delaiSecurite}, periodeCommande: ${_this.periodeCommande}, stockMaximum: ${_this.stockMaximum}, couverture: ${_this.couverture}, dvrMax: ${_this.dvrMax}, qteARisque: ${_this.qteARisque}, valeurARisque: ${_this.valeurARisque}, lots: ${_this.lots})';
}


}

/// @nodoc
abstract mixin class $IndicateursProduitCopyWith<$Res>  {
  factory $IndicateursProduitCopyWith(IndicateursProduit value, $Res Function(IndicateursProduit) _then) = _$IndicateursProduitCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'ventes_12_mois') double ventes12Mois,@JsonKey(name: 'mois_historique') int moisHistorique, double cmm, double cmj, FournisseurPrincipal? fournisseur,@JsonKey(name: 'delai_livraison_jours') int delaiLivraison,@JsonKey(name: 'date_livraison') DateTime? dateLivraison,@JsonKey(name: 'stock_securite') int stockSecurite,@JsonKey(name: 'stock_securite_simple') int stockSecuriteSimple,@JsonKey(name: 'delai_securite_jours') double delaiSecurite,@JsonKey(name: 'periode_commande_jours') double periodeCommande,@JsonKey(name: 'stock_maximum') int stockMaximum,@JsonKey(name: 'couverture_jours') int? couverture,@JsonKey(name: 'dvr_max') int? dvrMax,@JsonKey(name: 'qte_a_risque') int qteARisque,@JsonKey(name: 'valeur_a_risque') double valeurARisque, List<RisqueLot> lots
});


$FournisseurPrincipalCopyWith<$Res>? get fournisseur;

}
/// @nodoc
class _$IndicateursProduitCopyWithImpl<$Res>
    implements $IndicateursProduitCopyWith<$Res> {
  _$IndicateursProduitCopyWithImpl(this._self, this._then);

  final IndicateursProduit _self;
  final $Res Function(IndicateursProduit) _then;

/// Create a copy of IndicateursProduit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ventes12Mois = null,Object? moisHistorique = null,Object? cmm = null,Object? cmj = null,Object? fournisseur = freezed,Object? delaiLivraison = null,Object? dateLivraison = freezed,Object? stockSecurite = null,Object? stockSecuriteSimple = null,Object? delaiSecurite = null,Object? periodeCommande = null,Object? stockMaximum = null,Object? couverture = freezed,Object? dvrMax = freezed,Object? qteARisque = null,Object? valeurARisque = null,Object? lots = null,}) {
  return _then(IndicateursProduit(
ventes12Mois: null == ventes12Mois ? _self.ventes12Mois : ventes12Mois // ignore: cast_nullable_to_non_nullable
as double,moisHistorique: null == moisHistorique ? _self.moisHistorique : moisHistorique // ignore: cast_nullable_to_non_nullable
as int,cmm: null == cmm ? _self.cmm : cmm // ignore: cast_nullable_to_non_nullable
as double,cmj: null == cmj ? _self.cmj : cmj // ignore: cast_nullable_to_non_nullable
as double,fournisseur: freezed == fournisseur ? _self.fournisseur : fournisseur // ignore: cast_nullable_to_non_nullable
as FournisseurPrincipal?,delaiLivraison: null == delaiLivraison ? _self.delaiLivraison : delaiLivraison // ignore: cast_nullable_to_non_nullable
as int,dateLivraison: freezed == dateLivraison ? _self.dateLivraison : dateLivraison // ignore: cast_nullable_to_non_nullable
as DateTime?,stockSecurite: null == stockSecurite ? _self.stockSecurite : stockSecurite // ignore: cast_nullable_to_non_nullable
as int,stockSecuriteSimple: null == stockSecuriteSimple ? _self.stockSecuriteSimple : stockSecuriteSimple // ignore: cast_nullable_to_non_nullable
as int,delaiSecurite: null == delaiSecurite ? _self.delaiSecurite : delaiSecurite // ignore: cast_nullable_to_non_nullable
as double,periodeCommande: null == periodeCommande ? _self.periodeCommande : periodeCommande // ignore: cast_nullable_to_non_nullable
as double,stockMaximum: null == stockMaximum ? _self.stockMaximum : stockMaximum // ignore: cast_nullable_to_non_nullable
as int,couverture: freezed == couverture ? _self.couverture : couverture // ignore: cast_nullable_to_non_nullable
as int?,dvrMax: freezed == dvrMax ? _self.dvrMax : dvrMax // ignore: cast_nullable_to_non_nullable
as int?,qteARisque: null == qteARisque ? _self.qteARisque : qteARisque // ignore: cast_nullable_to_non_nullable
as int,valeurARisque: null == valeurARisque ? _self.valeurARisque : valeurARisque // ignore: cast_nullable_to_non_nullable
as double,lots: null == lots ? _self.lots : lots // ignore: cast_nullable_to_non_nullable
as List<RisqueLot>,
  ));
}
/// Create a copy of IndicateursProduit
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FournisseurPrincipalCopyWith<$Res>? get fournisseur {
    if (_self.fournisseur == null) {
    return null;
  }

  return $FournisseurPrincipalCopyWith<$Res>(_self.fournisseur!, (value) {
    return _then(_self.copyWith(fournisseur: value));
  });
}
}


/// Adds pattern-matching-related methods to [IndicateursProduit].
extension IndicateursProduitPatterns on IndicateursProduit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IndicateursProduit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IndicateursProduit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IndicateursProduit value)  $default,){
final _that = this;
switch (_that) {
case _IndicateursProduit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IndicateursProduit value)?  $default,){
final _that = this;
switch (_that) {
case _IndicateursProduit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'ventes_12_mois')  double ventes12Mois, @JsonKey(name: 'mois_historique')  int moisHistorique,  double cmm,  double cmj,  FournisseurPrincipal? fournisseur, @JsonKey(name: 'delai_livraison_jours')  int delaiLivraison, @JsonKey(name: 'date_livraison')  DateTime? dateLivraison, @JsonKey(name: 'stock_securite')  int stockSecurite, @JsonKey(name: 'stock_securite_simple')  int stockSecuriteSimple, @JsonKey(name: 'delai_securite_jours')  double delaiSecurite, @JsonKey(name: 'periode_commande_jours')  double periodeCommande, @JsonKey(name: 'stock_maximum')  int stockMaximum, @JsonKey(name: 'couverture_jours')  int? couverture, @JsonKey(name: 'dvr_max')  int? dvrMax, @JsonKey(name: 'qte_a_risque')  int qteARisque, @JsonKey(name: 'valeur_a_risque')  double valeurARisque,  List<RisqueLot> lots)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IndicateursProduit() when $default != null:
return $default(_that.ventes12Mois,_that.moisHistorique,_that.cmm,_that.cmj,_that.fournisseur,_that.delaiLivraison,_that.dateLivraison,_that.stockSecurite,_that.stockSecuriteSimple,_that.delaiSecurite,_that.periodeCommande,_that.stockMaximum,_that.couverture,_that.dvrMax,_that.qteARisque,_that.valeurARisque,_that.lots);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'ventes_12_mois')  double ventes12Mois, @JsonKey(name: 'mois_historique')  int moisHistorique,  double cmm,  double cmj,  FournisseurPrincipal? fournisseur, @JsonKey(name: 'delai_livraison_jours')  int delaiLivraison, @JsonKey(name: 'date_livraison')  DateTime? dateLivraison, @JsonKey(name: 'stock_securite')  int stockSecurite, @JsonKey(name: 'stock_securite_simple')  int stockSecuriteSimple, @JsonKey(name: 'delai_securite_jours')  double delaiSecurite, @JsonKey(name: 'periode_commande_jours')  double periodeCommande, @JsonKey(name: 'stock_maximum')  int stockMaximum, @JsonKey(name: 'couverture_jours')  int? couverture, @JsonKey(name: 'dvr_max')  int? dvrMax, @JsonKey(name: 'qte_a_risque')  int qteARisque, @JsonKey(name: 'valeur_a_risque')  double valeurARisque,  List<RisqueLot> lots)  $default,) {final _that = this;
switch (_that) {
case _IndicateursProduit():
return $default(_that.ventes12Mois,_that.moisHistorique,_that.cmm,_that.cmj,_that.fournisseur,_that.delaiLivraison,_that.dateLivraison,_that.stockSecurite,_that.stockSecuriteSimple,_that.delaiSecurite,_that.periodeCommande,_that.stockMaximum,_that.couverture,_that.dvrMax,_that.qteARisque,_that.valeurARisque,_that.lots);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'ventes_12_mois')  double ventes12Mois, @JsonKey(name: 'mois_historique')  int moisHistorique,  double cmm,  double cmj,  FournisseurPrincipal? fournisseur, @JsonKey(name: 'delai_livraison_jours')  int delaiLivraison, @JsonKey(name: 'date_livraison')  DateTime? dateLivraison, @JsonKey(name: 'stock_securite')  int stockSecurite, @JsonKey(name: 'stock_securite_simple')  int stockSecuriteSimple, @JsonKey(name: 'delai_securite_jours')  double delaiSecurite, @JsonKey(name: 'periode_commande_jours')  double periodeCommande, @JsonKey(name: 'stock_maximum')  int stockMaximum, @JsonKey(name: 'couverture_jours')  int? couverture, @JsonKey(name: 'dvr_max')  int? dvrMax, @JsonKey(name: 'qte_a_risque')  int qteARisque, @JsonKey(name: 'valeur_a_risque')  double valeurARisque,  List<RisqueLot> lots)?  $default,) {final _that = this;
switch (_that) {
case _IndicateursProduit() when $default != null:
return $default(_that.ventes12Mois,_that.moisHistorique,_that.cmm,_that.cmj,_that.fournisseur,_that.delaiLivraison,_that.dateLivraison,_that.stockSecurite,_that.stockSecuriteSimple,_that.delaiSecurite,_that.periodeCommande,_that.stockMaximum,_that.couverture,_that.dvrMax,_that.qteARisque,_that.valeurARisque,_that.lots);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IndicateursProduit extends IndicateursProduit {
  const _IndicateursProduit({@JsonKey(name: 'ventes_12_mois') this.ventes12Mois = 0, @JsonKey(name: 'mois_historique') this.moisHistorique = 12, this.cmm = 0, this.cmj = 0, this.fournisseur, @JsonKey(name: 'delai_livraison_jours') this.delaiLivraison = 1, @JsonKey(name: 'date_livraison') this.dateLivraison, @JsonKey(name: 'stock_securite') this.stockSecurite = 0, @JsonKey(name: 'stock_securite_simple') this.stockSecuriteSimple = 0, @JsonKey(name: 'delai_securite_jours') this.delaiSecurite = 0, @JsonKey(name: 'periode_commande_jours') this.periodeCommande = 0, @JsonKey(name: 'stock_maximum') this.stockMaximum = 0, @JsonKey(name: 'couverture_jours') this.couverture, @JsonKey(name: 'dvr_max') this.dvrMax, @JsonKey(name: 'qte_a_risque') this.qteARisque = 0, @JsonKey(name: 'valeur_a_risque') this.valeurARisque = 0,  List<RisqueLot> lots = const <RisqueLot>[]}): _lots = lots,super._();
  factory _IndicateursProduit.fromJson(Map<String, dynamic> json) => _$IndicateursProduitFromJson(json);

@override@JsonKey(name: 'ventes_12_mois') final  double ventes12Mois;
@override@JsonKey(name: 'mois_historique') final  int moisHistorique;
@override@JsonKey() final  double cmm;
@override@JsonKey() final  double cmj;
@override final  FournisseurPrincipal? fournisseur;
@override@JsonKey(name: 'delai_livraison_jours') final  int delaiLivraison;
@override@JsonKey(name: 'date_livraison') final  DateTime? dateLivraison;
@override@JsonKey(name: 'stock_securite') final  int stockSecurite;
@override@JsonKey(name: 'stock_securite_simple') final  int stockSecuriteSimple;
@override@JsonKey(name: 'delai_securite_jours') final  double delaiSecurite;
@override@JsonKey(name: 'periode_commande_jours') final  double periodeCommande;
@override@JsonKey(name: 'stock_maximum') final  int stockMaximum;
@override@JsonKey(name: 'couverture_jours') final  int? couverture;
@override@JsonKey(name: 'dvr_max') final  int? dvrMax;
@override@JsonKey(name: 'qte_a_risque') final  int qteARisque;
@override@JsonKey(name: 'valeur_a_risque') final  double valeurARisque;
 final  List<RisqueLot> _lots;
@override@JsonKey() List<RisqueLot> get lots {
  if (_lots is EqualUnmodifiableListView) return _lots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lots);
}


/// Create a copy of IndicateursProduit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IndicateursProduitCopyWith<_IndicateursProduit> get copyWith => __$IndicateursProduitCopyWithImpl<_IndicateursProduit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IndicateursProduitToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _IndicateursProduit&&(identical(other.ventes12Mois, ventes12Mois) || other.ventes12Mois == ventes12Mois)&&(identical(other.moisHistorique, moisHistorique) || other.moisHistorique == moisHistorique)&&(identical(other.cmm, cmm) || other.cmm == cmm)&&(identical(other.cmj, cmj) || other.cmj == cmj)&&(identical(other.fournisseur, fournisseur) || other.fournisseur == fournisseur)&&(identical(other.delaiLivraison, delaiLivraison) || other.delaiLivraison == delaiLivraison)&&(identical(other.dateLivraison, dateLivraison) || other.dateLivraison == dateLivraison)&&(identical(other.stockSecurite, stockSecurite) || other.stockSecurite == stockSecurite)&&(identical(other.stockSecuriteSimple, stockSecuriteSimple) || other.stockSecuriteSimple == stockSecuriteSimple)&&(identical(other.delaiSecurite, delaiSecurite) || other.delaiSecurite == delaiSecurite)&&(identical(other.periodeCommande, periodeCommande) || other.periodeCommande == periodeCommande)&&(identical(other.stockMaximum, stockMaximum) || other.stockMaximum == stockMaximum)&&(identical(other.couverture, couverture) || other.couverture == couverture)&&(identical(other.dvrMax, dvrMax) || other.dvrMax == dvrMax)&&(identical(other.qteARisque, qteARisque) || other.qteARisque == qteARisque)&&(identical(other.valeurARisque, valeurARisque) || other.valeurARisque == valeurARisque)&&const DeepCollectionEquality().equals(other.lots, _lots));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,ventes12Mois,moisHistorique,cmm,cmj,fournisseur,delaiLivraison,dateLivraison,stockSecurite,stockSecuriteSimple,delaiSecurite,periodeCommande,stockMaximum,couverture,dvrMax,qteARisque,valeurARisque,const DeepCollectionEquality().hash(_lots));
}

@override
String toString() {
    return 'IndicateursProduit(ventes12Mois: $ventes12Mois, moisHistorique: $moisHistorique, cmm: $cmm, cmj: $cmj, fournisseur: $fournisseur, delaiLivraison: $delaiLivraison, dateLivraison: $dateLivraison, stockSecurite: $stockSecurite, stockSecuriteSimple: $stockSecuriteSimple, delaiSecurite: $delaiSecurite, periodeCommande: $periodeCommande, stockMaximum: $stockMaximum, couverture: $couverture, dvrMax: $dvrMax, qteARisque: $qteARisque, valeurARisque: $valeurARisque, lots: $lots)';
}


}

/// @nodoc
abstract mixin class _$IndicateursProduitCopyWith<$Res> implements $IndicateursProduitCopyWith<$Res> {
  factory _$IndicateursProduitCopyWith(_IndicateursProduit value, $Res Function(_IndicateursProduit) _then) = __$IndicateursProduitCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'ventes_12_mois') double ventes12Mois,@JsonKey(name: 'mois_historique') int moisHistorique, double cmm, double cmj, FournisseurPrincipal? fournisseur,@JsonKey(name: 'delai_livraison_jours') int delaiLivraison,@JsonKey(name: 'date_livraison') DateTime? dateLivraison,@JsonKey(name: 'stock_securite') int stockSecurite,@JsonKey(name: 'stock_securite_simple') int stockSecuriteSimple,@JsonKey(name: 'delai_securite_jours') double delaiSecurite,@JsonKey(name: 'periode_commande_jours') double periodeCommande,@JsonKey(name: 'stock_maximum') int stockMaximum,@JsonKey(name: 'couverture_jours') int? couverture,@JsonKey(name: 'dvr_max') int? dvrMax,@JsonKey(name: 'qte_a_risque') int qteARisque,@JsonKey(name: 'valeur_a_risque') double valeurARisque, List<RisqueLot> lots
});


@override $FournisseurPrincipalCopyWith<$Res>? get fournisseur;

}
/// @nodoc
class __$IndicateursProduitCopyWithImpl<$Res>
    implements _$IndicateursProduitCopyWith<$Res> {
  __$IndicateursProduitCopyWithImpl(this._self, this._then);

  final _IndicateursProduit _self;
  final $Res Function(_IndicateursProduit) _then;

/// Create a copy of IndicateursProduit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ventes12Mois = null,Object? moisHistorique = null,Object? cmm = null,Object? cmj = null,Object? fournisseur = freezed,Object? delaiLivraison = null,Object? dateLivraison = freezed,Object? stockSecurite = null,Object? stockSecuriteSimple = null,Object? delaiSecurite = null,Object? periodeCommande = null,Object? stockMaximum = null,Object? couverture = freezed,Object? dvrMax = freezed,Object? qteARisque = null,Object? valeurARisque = null,Object? lots = null,}) {
  return _then(_IndicateursProduit(
ventes12Mois: null == ventes12Mois ? _self.ventes12Mois : ventes12Mois // ignore: cast_nullable_to_non_nullable
as double,moisHistorique: null == moisHistorique ? _self.moisHistorique : moisHistorique // ignore: cast_nullable_to_non_nullable
as int,cmm: null == cmm ? _self.cmm : cmm // ignore: cast_nullable_to_non_nullable
as double,cmj: null == cmj ? _self.cmj : cmj // ignore: cast_nullable_to_non_nullable
as double,fournisseur: freezed == fournisseur ? _self.fournisseur : fournisseur // ignore: cast_nullable_to_non_nullable
as FournisseurPrincipal?,delaiLivraison: null == delaiLivraison ? _self.delaiLivraison : delaiLivraison // ignore: cast_nullable_to_non_nullable
as int,dateLivraison: freezed == dateLivraison ? _self.dateLivraison : dateLivraison // ignore: cast_nullable_to_non_nullable
as DateTime?,stockSecurite: null == stockSecurite ? _self.stockSecurite : stockSecurite // ignore: cast_nullable_to_non_nullable
as int,stockSecuriteSimple: null == stockSecuriteSimple ? _self.stockSecuriteSimple : stockSecuriteSimple // ignore: cast_nullable_to_non_nullable
as int,delaiSecurite: null == delaiSecurite ? _self.delaiSecurite : delaiSecurite // ignore: cast_nullable_to_non_nullable
as double,periodeCommande: null == periodeCommande ? _self.periodeCommande : periodeCommande // ignore: cast_nullable_to_non_nullable
as double,stockMaximum: null == stockMaximum ? _self.stockMaximum : stockMaximum // ignore: cast_nullable_to_non_nullable
as int,couverture: freezed == couverture ? _self.couverture : couverture // ignore: cast_nullable_to_non_nullable
as int?,dvrMax: freezed == dvrMax ? _self.dvrMax : dvrMax // ignore: cast_nullable_to_non_nullable
as int?,qteARisque: null == qteARisque ? _self.qteARisque : qteARisque // ignore: cast_nullable_to_non_nullable
as int,valeurARisque: null == valeurARisque ? _self.valeurARisque : valeurARisque // ignore: cast_nullable_to_non_nullable
as double,lots: null == lots ? _self._lots : lots // ignore: cast_nullable_to_non_nullable
as List<RisqueLot>,
  ));
}

/// Create a copy of IndicateursProduit
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FournisseurPrincipalCopyWith<$Res>? get fournisseur {
    if (_self.fournisseur == null) {
    return null;
  }

  return $FournisseurPrincipalCopyWith<$Res>(_self.fournisseur!, (value) {
    return _then(_self.copyWith(fournisseur: value));
  });
}
}


/// @nodoc
mixin _$PageProduits {

 int get total; List<Produit> get items;
/// Create a copy of PageProduits
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageProduitsCopyWith<PageProduits> get copyWith => _$PageProduitsCopyWithImpl<PageProduits>(this as PageProduits, _$identity);

  /// Serializes this PageProduits to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PageProduits;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageProduits&&(identical(other.total, _this.total) || other.total == _this.total)&&const DeepCollectionEquality().equals(other.items, _this.items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PageProduits;
  return Object.hash(runtimeType,_this.total,const DeepCollectionEquality().hash(_this.items));
}

@override
String toString() {
  final _this = this as PageProduits;
  return 'PageProduits(total: ${_this.total}, items: ${_this.items})';
}


}

/// @nodoc
abstract mixin class $PageProduitsCopyWith<$Res>  {
  factory $PageProduitsCopyWith(PageProduits value, $Res Function(PageProduits) _then) = _$PageProduitsCopyWithImpl;
@useResult
$Res call({
 int total, List<Produit> items
});




}
/// @nodoc
class _$PageProduitsCopyWithImpl<$Res>
    implements $PageProduitsCopyWith<$Res> {
  _$PageProduitsCopyWithImpl(this._self, this._then);

  final PageProduits _self;
  final $Res Function(PageProduits) _then;

/// Create a copy of PageProduits
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = null,Object? items = null,}) {
  return _then(PageProduits(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<Produit>,
  ));
}

}


/// Adds pattern-matching-related methods to [PageProduits].
extension PageProduitsPatterns on PageProduits {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PageProduits value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PageProduits() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PageProduits value)  $default,){
final _that = this;
switch (_that) {
case _PageProduits():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PageProduits value)?  $default,){
final _that = this;
switch (_that) {
case _PageProduits() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int total,  List<Produit> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PageProduits() when $default != null:
return $default(_that.total,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int total,  List<Produit> items)  $default,) {final _that = this;
switch (_that) {
case _PageProduits():
return $default(_that.total,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int total,  List<Produit> items)?  $default,) {final _that = this;
switch (_that) {
case _PageProduits() when $default != null:
return $default(_that.total,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PageProduits implements PageProduits {
  const _PageProduits({this.total = 0,  List<Produit> items = const <Produit>[]}): _items = items;
  factory _PageProduits.fromJson(Map<String, dynamic> json) => _$PageProduitsFromJson(json);

@override@JsonKey() final  int total;
 final  List<Produit> _items;
@override@JsonKey() List<Produit> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of PageProduits
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PageProduitsCopyWith<_PageProduits> get copyWith => __$PageProduitsCopyWithImpl<_PageProduits>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PageProduitsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PageProduits&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,total,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'PageProduits(total: $total, items: $items)';
}


}

/// @nodoc
abstract mixin class _$PageProduitsCopyWith<$Res> implements $PageProduitsCopyWith<$Res> {
  factory _$PageProduitsCopyWith(_PageProduits value, $Res Function(_PageProduits) _then) = __$PageProduitsCopyWithImpl;
@override @useResult
$Res call({
 int total, List<Produit> items
});




}
/// @nodoc
class __$PageProduitsCopyWithImpl<$Res>
    implements _$PageProduitsCopyWith<$Res> {
  __$PageProduitsCopyWithImpl(this._self, this._then);

  final _PageProduits _self;
  final $Res Function(_PageProduits) _then;

/// Create a copy of PageProduits
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = null,Object? items = null,}) {
  return _then(_PageProduits(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<Produit>,
  ));
}


}


/// @nodoc
mixin _$Compteurs {

 int get ruptures;@JsonKey(name: 'sous_seuil') int get sousSeuil;@JsonKey(name: 'a_commander') int get aCommander;@JsonKey(name: 'a_risque') int get aRisque;@JsonKey(name: 'valeur_a_risque') double get valeurARisque; int get surstock;@JsonKey(name: 'valeur_surstock') double get valeurSurstock;
/// Create a copy of Compteurs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompteursCopyWith<Compteurs> get copyWith => _$CompteursCopyWithImpl<Compteurs>(this as Compteurs, _$identity);

  /// Serializes this Compteurs to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Compteurs;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Compteurs&&(identical(other.ruptures, _this.ruptures) || other.ruptures == _this.ruptures)&&(identical(other.sousSeuil, _this.sousSeuil) || other.sousSeuil == _this.sousSeuil)&&(identical(other.aCommander, _this.aCommander) || other.aCommander == _this.aCommander)&&(identical(other.aRisque, _this.aRisque) || other.aRisque == _this.aRisque)&&(identical(other.valeurARisque, _this.valeurARisque) || other.valeurARisque == _this.valeurARisque)&&(identical(other.surstock, _this.surstock) || other.surstock == _this.surstock)&&(identical(other.valeurSurstock, _this.valeurSurstock) || other.valeurSurstock == _this.valeurSurstock));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Compteurs;
  return Object.hash(runtimeType,_this.ruptures,_this.sousSeuil,_this.aCommander,_this.aRisque,_this.valeurARisque,_this.surstock,_this.valeurSurstock);
}

@override
String toString() {
  final _this = this as Compteurs;
  return 'Compteurs(ruptures: ${_this.ruptures}, sousSeuil: ${_this.sousSeuil}, aCommander: ${_this.aCommander}, aRisque: ${_this.aRisque}, valeurARisque: ${_this.valeurARisque}, surstock: ${_this.surstock}, valeurSurstock: ${_this.valeurSurstock})';
}


}

/// @nodoc
abstract mixin class $CompteursCopyWith<$Res>  {
  factory $CompteursCopyWith(Compteurs value, $Res Function(Compteurs) _then) = _$CompteursCopyWithImpl;
@useResult
$Res call({
 int ruptures,@JsonKey(name: 'sous_seuil') int sousSeuil,@JsonKey(name: 'a_commander') int aCommander,@JsonKey(name: 'a_risque') int aRisque,@JsonKey(name: 'valeur_a_risque') double valeurARisque, int surstock,@JsonKey(name: 'valeur_surstock') double valeurSurstock
});




}
/// @nodoc
class _$CompteursCopyWithImpl<$Res>
    implements $CompteursCopyWith<$Res> {
  _$CompteursCopyWithImpl(this._self, this._then);

  final Compteurs _self;
  final $Res Function(Compteurs) _then;

/// Create a copy of Compteurs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ruptures = null,Object? sousSeuil = null,Object? aCommander = null,Object? aRisque = null,Object? valeurARisque = null,Object? surstock = null,Object? valeurSurstock = null,}) {
  return _then(Compteurs(
ruptures: null == ruptures ? _self.ruptures : ruptures // ignore: cast_nullable_to_non_nullable
as int,sousSeuil: null == sousSeuil ? _self.sousSeuil : sousSeuil // ignore: cast_nullable_to_non_nullable
as int,aCommander: null == aCommander ? _self.aCommander : aCommander // ignore: cast_nullable_to_non_nullable
as int,aRisque: null == aRisque ? _self.aRisque : aRisque // ignore: cast_nullable_to_non_nullable
as int,valeurARisque: null == valeurARisque ? _self.valeurARisque : valeurARisque // ignore: cast_nullable_to_non_nullable
as double,surstock: null == surstock ? _self.surstock : surstock // ignore: cast_nullable_to_non_nullable
as int,valeurSurstock: null == valeurSurstock ? _self.valeurSurstock : valeurSurstock // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Compteurs].
extension CompteursPatterns on Compteurs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Compteurs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Compteurs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Compteurs value)  $default,){
final _that = this;
switch (_that) {
case _Compteurs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Compteurs value)?  $default,){
final _that = this;
switch (_that) {
case _Compteurs() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int ruptures, @JsonKey(name: 'sous_seuil')  int sousSeuil, @JsonKey(name: 'a_commander')  int aCommander, @JsonKey(name: 'a_risque')  int aRisque, @JsonKey(name: 'valeur_a_risque')  double valeurARisque,  int surstock, @JsonKey(name: 'valeur_surstock')  double valeurSurstock)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Compteurs() when $default != null:
return $default(_that.ruptures,_that.sousSeuil,_that.aCommander,_that.aRisque,_that.valeurARisque,_that.surstock,_that.valeurSurstock);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int ruptures, @JsonKey(name: 'sous_seuil')  int sousSeuil, @JsonKey(name: 'a_commander')  int aCommander, @JsonKey(name: 'a_risque')  int aRisque, @JsonKey(name: 'valeur_a_risque')  double valeurARisque,  int surstock, @JsonKey(name: 'valeur_surstock')  double valeurSurstock)  $default,) {final _that = this;
switch (_that) {
case _Compteurs():
return $default(_that.ruptures,_that.sousSeuil,_that.aCommander,_that.aRisque,_that.valeurARisque,_that.surstock,_that.valeurSurstock);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int ruptures, @JsonKey(name: 'sous_seuil')  int sousSeuil, @JsonKey(name: 'a_commander')  int aCommander, @JsonKey(name: 'a_risque')  int aRisque, @JsonKey(name: 'valeur_a_risque')  double valeurARisque,  int surstock, @JsonKey(name: 'valeur_surstock')  double valeurSurstock)?  $default,) {final _that = this;
switch (_that) {
case _Compteurs() when $default != null:
return $default(_that.ruptures,_that.sousSeuil,_that.aCommander,_that.aRisque,_that.valeurARisque,_that.surstock,_that.valeurSurstock);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Compteurs implements Compteurs {
  const _Compteurs({this.ruptures = 0, @JsonKey(name: 'sous_seuil') this.sousSeuil = 0, @JsonKey(name: 'a_commander') this.aCommander = 0, @JsonKey(name: 'a_risque') this.aRisque = 0, @JsonKey(name: 'valeur_a_risque') this.valeurARisque = 0, this.surstock = 0, @JsonKey(name: 'valeur_surstock') this.valeurSurstock = 0});
  factory _Compteurs.fromJson(Map<String, dynamic> json) => _$CompteursFromJson(json);

@override@JsonKey() final  int ruptures;
@override@JsonKey(name: 'sous_seuil') final  int sousSeuil;
@override@JsonKey(name: 'a_commander') final  int aCommander;
@override@JsonKey(name: 'a_risque') final  int aRisque;
@override@JsonKey(name: 'valeur_a_risque') final  double valeurARisque;
@override@JsonKey() final  int surstock;
@override@JsonKey(name: 'valeur_surstock') final  double valeurSurstock;

/// Create a copy of Compteurs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompteursCopyWith<_Compteurs> get copyWith => __$CompteursCopyWithImpl<_Compteurs>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompteursToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Compteurs&&(identical(other.ruptures, ruptures) || other.ruptures == ruptures)&&(identical(other.sousSeuil, sousSeuil) || other.sousSeuil == sousSeuil)&&(identical(other.aCommander, aCommander) || other.aCommander == aCommander)&&(identical(other.aRisque, aRisque) || other.aRisque == aRisque)&&(identical(other.valeurARisque, valeurARisque) || other.valeurARisque == valeurARisque)&&(identical(other.surstock, surstock) || other.surstock == surstock)&&(identical(other.valeurSurstock, valeurSurstock) || other.valeurSurstock == valeurSurstock));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,ruptures,sousSeuil,aCommander,aRisque,valeurARisque,surstock,valeurSurstock);
}

@override
String toString() {
    return 'Compteurs(ruptures: $ruptures, sousSeuil: $sousSeuil, aCommander: $aCommander, aRisque: $aRisque, valeurARisque: $valeurARisque, surstock: $surstock, valeurSurstock: $valeurSurstock)';
}


}

/// @nodoc
abstract mixin class _$CompteursCopyWith<$Res> implements $CompteursCopyWith<$Res> {
  factory _$CompteursCopyWith(_Compteurs value, $Res Function(_Compteurs) _then) = __$CompteursCopyWithImpl;
@override @useResult
$Res call({
 int ruptures,@JsonKey(name: 'sous_seuil') int sousSeuil,@JsonKey(name: 'a_commander') int aCommander,@JsonKey(name: 'a_risque') int aRisque,@JsonKey(name: 'valeur_a_risque') double valeurARisque, int surstock,@JsonKey(name: 'valeur_surstock') double valeurSurstock
});




}
/// @nodoc
class __$CompteursCopyWithImpl<$Res>
    implements _$CompteursCopyWith<$Res> {
  __$CompteursCopyWithImpl(this._self, this._then);

  final _Compteurs _self;
  final $Res Function(_Compteurs) _then;

/// Create a copy of Compteurs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ruptures = null,Object? sousSeuil = null,Object? aCommander = null,Object? aRisque = null,Object? valeurARisque = null,Object? surstock = null,Object? valeurSurstock = null,}) {
  return _then(_Compteurs(
ruptures: null == ruptures ? _self.ruptures : ruptures // ignore: cast_nullable_to_non_nullable
as int,sousSeuil: null == sousSeuil ? _self.sousSeuil : sousSeuil // ignore: cast_nullable_to_non_nullable
as int,aCommander: null == aCommander ? _self.aCommander : aCommander // ignore: cast_nullable_to_non_nullable
as int,aRisque: null == aRisque ? _self.aRisque : aRisque // ignore: cast_nullable_to_non_nullable
as int,valeurARisque: null == valeurARisque ? _self.valeurARisque : valeurARisque // ignore: cast_nullable_to_non_nullable
as double,surstock: null == surstock ? _self.surstock : surstock // ignore: cast_nullable_to_non_nullable
as int,valeurSurstock: null == valeurSurstock ? _self.valeurSurstock : valeurSurstock // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$ATraiter {

 Compteurs get compteurs;@JsonKey(name: 'a_commander') List<Produit> get aCommander;@JsonKey(name: 'a_risque') List<Produit> get aRisque; List<Produit> get surstock;
/// Create a copy of ATraiter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ATraiterCopyWith<ATraiter> get copyWith => _$ATraiterCopyWithImpl<ATraiter>(this as ATraiter, _$identity);

  /// Serializes this ATraiter to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ATraiter;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ATraiter&&(identical(other.compteurs, _this.compteurs) || other.compteurs == _this.compteurs)&&const DeepCollectionEquality().equals(other.aCommander, _this.aCommander)&&const DeepCollectionEquality().equals(other.aRisque, _this.aRisque)&&const DeepCollectionEquality().equals(other.surstock, _this.surstock));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ATraiter;
  return Object.hash(runtimeType,_this.compteurs,const DeepCollectionEquality().hash(_this.aCommander),const DeepCollectionEquality().hash(_this.aRisque),const DeepCollectionEquality().hash(_this.surstock));
}

@override
String toString() {
  final _this = this as ATraiter;
  return 'ATraiter(compteurs: ${_this.compteurs}, aCommander: ${_this.aCommander}, aRisque: ${_this.aRisque}, surstock: ${_this.surstock})';
}


}

/// @nodoc
abstract mixin class $ATraiterCopyWith<$Res>  {
  factory $ATraiterCopyWith(ATraiter value, $Res Function(ATraiter) _then) = _$ATraiterCopyWithImpl;
@useResult
$Res call({
 Compteurs compteurs,@JsonKey(name: 'a_commander') List<Produit> aCommander,@JsonKey(name: 'a_risque') List<Produit> aRisque, List<Produit> surstock
});


$CompteursCopyWith<$Res> get compteurs;

}
/// @nodoc
class _$ATraiterCopyWithImpl<$Res>
    implements $ATraiterCopyWith<$Res> {
  _$ATraiterCopyWithImpl(this._self, this._then);

  final ATraiter _self;
  final $Res Function(ATraiter) _then;

/// Create a copy of ATraiter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? compteurs = null,Object? aCommander = null,Object? aRisque = null,Object? surstock = null,}) {
  return _then(ATraiter(
compteurs: null == compteurs ? _self.compteurs : compteurs // ignore: cast_nullable_to_non_nullable
as Compteurs,aCommander: null == aCommander ? _self.aCommander : aCommander // ignore: cast_nullable_to_non_nullable
as List<Produit>,aRisque: null == aRisque ? _self.aRisque : aRisque // ignore: cast_nullable_to_non_nullable
as List<Produit>,surstock: null == surstock ? _self.surstock : surstock // ignore: cast_nullable_to_non_nullable
as List<Produit>,
  ));
}
/// Create a copy of ATraiter
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompteursCopyWith<$Res> get compteurs {
  
  return $CompteursCopyWith<$Res>(_self.compteurs, (value) {
    return _then(_self.copyWith(compteurs: value));
  });
}
}


/// Adds pattern-matching-related methods to [ATraiter].
extension ATraiterPatterns on ATraiter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ATraiter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ATraiter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ATraiter value)  $default,){
final _that = this;
switch (_that) {
case _ATraiter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ATraiter value)?  $default,){
final _that = this;
switch (_that) {
case _ATraiter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Compteurs compteurs, @JsonKey(name: 'a_commander')  List<Produit> aCommander, @JsonKey(name: 'a_risque')  List<Produit> aRisque,  List<Produit> surstock)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ATraiter() when $default != null:
return $default(_that.compteurs,_that.aCommander,_that.aRisque,_that.surstock);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Compteurs compteurs, @JsonKey(name: 'a_commander')  List<Produit> aCommander, @JsonKey(name: 'a_risque')  List<Produit> aRisque,  List<Produit> surstock)  $default,) {final _that = this;
switch (_that) {
case _ATraiter():
return $default(_that.compteurs,_that.aCommander,_that.aRisque,_that.surstock);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Compteurs compteurs, @JsonKey(name: 'a_commander')  List<Produit> aCommander, @JsonKey(name: 'a_risque')  List<Produit> aRisque,  List<Produit> surstock)?  $default,) {final _that = this;
switch (_that) {
case _ATraiter() when $default != null:
return $default(_that.compteurs,_that.aCommander,_that.aRisque,_that.surstock);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ATraiter implements ATraiter {
  const _ATraiter({this.compteurs = const Compteurs(), @JsonKey(name: 'a_commander')  List<Produit> aCommander = const <Produit>[], @JsonKey(name: 'a_risque')  List<Produit> aRisque = const <Produit>[],  List<Produit> surstock = const <Produit>[]}): _aCommander = aCommander,_aRisque = aRisque,_surstock = surstock;
  factory _ATraiter.fromJson(Map<String, dynamic> json) => _$ATraiterFromJson(json);

@override@JsonKey() final  Compteurs compteurs;
 final  List<Produit> _aCommander;
@override@JsonKey(name: 'a_commander') List<Produit> get aCommander {
  if (_aCommander is EqualUnmodifiableListView) return _aCommander;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_aCommander);
}

 final  List<Produit> _aRisque;
@override@JsonKey(name: 'a_risque') List<Produit> get aRisque {
  if (_aRisque is EqualUnmodifiableListView) return _aRisque;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_aRisque);
}

 final  List<Produit> _surstock;
@override@JsonKey() List<Produit> get surstock {
  if (_surstock is EqualUnmodifiableListView) return _surstock;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_surstock);
}


/// Create a copy of ATraiter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ATraiterCopyWith<_ATraiter> get copyWith => __$ATraiterCopyWithImpl<_ATraiter>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ATraiterToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ATraiter&&(identical(other.compteurs, compteurs) || other.compteurs == compteurs)&&const DeepCollectionEquality().equals(other.aCommander, _aCommander)&&const DeepCollectionEquality().equals(other.aRisque, _aRisque)&&const DeepCollectionEquality().equals(other.surstock, _surstock));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,compteurs,const DeepCollectionEquality().hash(_aCommander),const DeepCollectionEquality().hash(_aRisque),const DeepCollectionEquality().hash(_surstock));
}

@override
String toString() {
    return 'ATraiter(compteurs: $compteurs, aCommander: $aCommander, aRisque: $aRisque, surstock: $surstock)';
}


}

/// @nodoc
abstract mixin class _$ATraiterCopyWith<$Res> implements $ATraiterCopyWith<$Res> {
  factory _$ATraiterCopyWith(_ATraiter value, $Res Function(_ATraiter) _then) = __$ATraiterCopyWithImpl;
@override @useResult
$Res call({
 Compteurs compteurs,@JsonKey(name: 'a_commander') List<Produit> aCommander,@JsonKey(name: 'a_risque') List<Produit> aRisque, List<Produit> surstock
});


@override $CompteursCopyWith<$Res> get compteurs;

}
/// @nodoc
class __$ATraiterCopyWithImpl<$Res>
    implements _$ATraiterCopyWith<$Res> {
  __$ATraiterCopyWithImpl(this._self, this._then);

  final _ATraiter _self;
  final $Res Function(_ATraiter) _then;

/// Create a copy of ATraiter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? compteurs = null,Object? aCommander = null,Object? aRisque = null,Object? surstock = null,}) {
  return _then(_ATraiter(
compteurs: null == compteurs ? _self.compteurs : compteurs // ignore: cast_nullable_to_non_nullable
as Compteurs,aCommander: null == aCommander ? _self._aCommander : aCommander // ignore: cast_nullable_to_non_nullable
as List<Produit>,aRisque: null == aRisque ? _self._aRisque : aRisque // ignore: cast_nullable_to_non_nullable
as List<Produit>,surstock: null == surstock ? _self._surstock : surstock // ignore: cast_nullable_to_non_nullable
as List<Produit>,
  ));
}

/// Create a copy of ATraiter
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompteursCopyWith<$Res> get compteurs {
  
  return $CompteursCopyWith<$Res>(_self.compteurs, (value) {
    return _then(_self.copyWith(compteurs: value));
  });
}
}

/// @nodoc
mixin _$FiltreProduits {

 String get recherche; int? get idFamille; FiltreEtat? get etat; TriProduits get tri;
/// Create a copy of FiltreProduits
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FiltreProduitsCopyWith<FiltreProduits> get copyWith => _$FiltreProduitsCopyWithImpl<FiltreProduits>(this as FiltreProduits, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FiltreProduits;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FiltreProduits&&(identical(other.recherche, _this.recherche) || other.recherche == _this.recherche)&&(identical(other.idFamille, _this.idFamille) || other.idFamille == _this.idFamille)&&(identical(other.etat, _this.etat) || other.etat == _this.etat)&&(identical(other.tri, _this.tri) || other.tri == _this.tri));
}


@override
int get hashCode {
  final _this = this as FiltreProduits;
  return Object.hash(runtimeType,_this.recherche,_this.idFamille,_this.etat,_this.tri);
}

@override
String toString() {
  final _this = this as FiltreProduits;
  return 'FiltreProduits(recherche: ${_this.recherche}, idFamille: ${_this.idFamille}, etat: ${_this.etat}, tri: ${_this.tri})';
}


}

/// @nodoc
abstract mixin class $FiltreProduitsCopyWith<$Res>  {
  factory $FiltreProduitsCopyWith(FiltreProduits value, $Res Function(FiltreProduits) _then) = _$FiltreProduitsCopyWithImpl;
@useResult
$Res call({
 String recherche, int? idFamille, FiltreEtat? etat, TriProduits tri
});




}
/// @nodoc
class _$FiltreProduitsCopyWithImpl<$Res>
    implements $FiltreProduitsCopyWith<$Res> {
  _$FiltreProduitsCopyWithImpl(this._self, this._then);

  final FiltreProduits _self;
  final $Res Function(FiltreProduits) _then;

/// Create a copy of FiltreProduits
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? recherche = null,Object? idFamille = freezed,Object? etat = freezed,Object? tri = null,}) {
  return _then(FiltreProduits(
recherche: null == recherche ? _self.recherche : recherche // ignore: cast_nullable_to_non_nullable
as String,idFamille: freezed == idFamille ? _self.idFamille : idFamille // ignore: cast_nullable_to_non_nullable
as int?,etat: freezed == etat ? _self.etat : etat // ignore: cast_nullable_to_non_nullable
as FiltreEtat?,tri: null == tri ? _self.tri : tri // ignore: cast_nullable_to_non_nullable
as TriProduits,
  ));
}

}


/// Adds pattern-matching-related methods to [FiltreProduits].
extension FiltreProduitsPatterns on FiltreProduits {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FiltreProduits value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FiltreProduits() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FiltreProduits value)  $default,){
final _that = this;
switch (_that) {
case _FiltreProduits():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FiltreProduits value)?  $default,){
final _that = this;
switch (_that) {
case _FiltreProduits() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String recherche,  int? idFamille,  FiltreEtat? etat,  TriProduits tri)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FiltreProduits() when $default != null:
return $default(_that.recherche,_that.idFamille,_that.etat,_that.tri);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String recherche,  int? idFamille,  FiltreEtat? etat,  TriProduits tri)  $default,) {final _that = this;
switch (_that) {
case _FiltreProduits():
return $default(_that.recherche,_that.idFamille,_that.etat,_that.tri);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String recherche,  int? idFamille,  FiltreEtat? etat,  TriProduits tri)?  $default,) {final _that = this;
switch (_that) {
case _FiltreProduits() when $default != null:
return $default(_that.recherche,_that.idFamille,_that.etat,_that.tri);case _:
  return null;

}
}

}

/// @nodoc


class _FiltreProduits implements FiltreProduits {
  const _FiltreProduits({this.recherche = '', this.idFamille, this.etat, this.tri = TriProduits.nom});
  

@override@JsonKey() final  String recherche;
@override final  int? idFamille;
@override final  FiltreEtat? etat;
@override@JsonKey() final  TriProduits tri;

/// Create a copy of FiltreProduits
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FiltreProduitsCopyWith<_FiltreProduits> get copyWith => __$FiltreProduitsCopyWithImpl<_FiltreProduits>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FiltreProduits&&(identical(other.recherche, recherche) || other.recherche == recherche)&&(identical(other.idFamille, idFamille) || other.idFamille == idFamille)&&(identical(other.etat, etat) || other.etat == etat)&&(identical(other.tri, tri) || other.tri == tri));
}


@override
int get hashCode {
    return Object.hash(runtimeType,recherche,idFamille,etat,tri);
}

@override
String toString() {
    return 'FiltreProduits(recherche: $recherche, idFamille: $idFamille, etat: $etat, tri: $tri)';
}


}

/// @nodoc
abstract mixin class _$FiltreProduitsCopyWith<$Res> implements $FiltreProduitsCopyWith<$Res> {
  factory _$FiltreProduitsCopyWith(_FiltreProduits value, $Res Function(_FiltreProduits) _then) = __$FiltreProduitsCopyWithImpl;
@override @useResult
$Res call({
 String recherche, int? idFamille, FiltreEtat? etat, TriProduits tri
});




}
/// @nodoc
class __$FiltreProduitsCopyWithImpl<$Res>
    implements _$FiltreProduitsCopyWith<$Res> {
  __$FiltreProduitsCopyWithImpl(this._self, this._then);

  final _FiltreProduits _self;
  final $Res Function(_FiltreProduits) _then;

/// Create a copy of FiltreProduits
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? recherche = null,Object? idFamille = freezed,Object? etat = freezed,Object? tri = null,}) {
  return _then(_FiltreProduits(
recherche: null == recherche ? _self.recherche : recherche // ignore: cast_nullable_to_non_nullable
as String,idFamille: freezed == idFamille ? _self.idFamille : idFamille // ignore: cast_nullable_to_non_nullable
as int?,etat: freezed == etat ? _self.etat : etat // ignore: cast_nullable_to_non_nullable
as FiltreEtat?,tri: null == tri ? _self.tri : tri // ignore: cast_nullable_to_non_nullable
as TriProduits,
  ));
}


}

// dart format on
