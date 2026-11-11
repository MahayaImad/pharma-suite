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

 int get id; String get nom; String? get dci; String? get dosage; String? get forme;@JsonKey(name: 'forme_abr') String? get formeAbr;@JsonKey(name: 'id_famille') int? get idFamille; String? get famille; String? get labo;@JsonKey(name: 'code_barre_original') String? get codeBarre; String? get conditionnement; double get stock;@JsonKey(name: 'qte_alerte') int? get seuil;@JsonKey(name: 'prix_vente') double get prixVente;@JsonKey(name: 'prix_achat_moyen') double get prixAchat;@JsonKey(name: 'valeur_achat') double get valeurAchat;@JsonKey(name: 'valeur_vente') double get valeurVente;@JsonKey(name: 'qte_vendue_12m') int? get vendu12Mois;@JsonKey(name: 'derniere_vente') DateTime? get derniereVente; bool get actif;@JsonKey(name: 'segment_abc') String? get classeAbc;@JsonKey(name: 'segment_xyz') String? get classeXyz; String? get categorie; String? get disponibilite; int? get psychotrope;@JsonKey(name: 'remb_cvm') int? get remboursable;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Produit&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nom, _this.nom) || other.nom == _this.nom)&&(identical(other.dci, _this.dci) || other.dci == _this.dci)&&(identical(other.dosage, _this.dosage) || other.dosage == _this.dosage)&&(identical(other.forme, _this.forme) || other.forme == _this.forme)&&(identical(other.formeAbr, _this.formeAbr) || other.formeAbr == _this.formeAbr)&&(identical(other.idFamille, _this.idFamille) || other.idFamille == _this.idFamille)&&(identical(other.famille, _this.famille) || other.famille == _this.famille)&&(identical(other.labo, _this.labo) || other.labo == _this.labo)&&(identical(other.codeBarre, _this.codeBarre) || other.codeBarre == _this.codeBarre)&&(identical(other.conditionnement, _this.conditionnement) || other.conditionnement == _this.conditionnement)&&(identical(other.stock, _this.stock) || other.stock == _this.stock)&&(identical(other.seuil, _this.seuil) || other.seuil == _this.seuil)&&(identical(other.prixVente, _this.prixVente) || other.prixVente == _this.prixVente)&&(identical(other.prixAchat, _this.prixAchat) || other.prixAchat == _this.prixAchat)&&(identical(other.valeurAchat, _this.valeurAchat) || other.valeurAchat == _this.valeurAchat)&&(identical(other.valeurVente, _this.valeurVente) || other.valeurVente == _this.valeurVente)&&(identical(other.vendu12Mois, _this.vendu12Mois) || other.vendu12Mois == _this.vendu12Mois)&&(identical(other.derniereVente, _this.derniereVente) || other.derniereVente == _this.derniereVente)&&(identical(other.actif, _this.actif) || other.actif == _this.actif)&&(identical(other.classeAbc, _this.classeAbc) || other.classeAbc == _this.classeAbc)&&(identical(other.classeXyz, _this.classeXyz) || other.classeXyz == _this.classeXyz)&&(identical(other.categorie, _this.categorie) || other.categorie == _this.categorie)&&(identical(other.disponibilite, _this.disponibilite) || other.disponibilite == _this.disponibilite)&&(identical(other.psychotrope, _this.psychotrope) || other.psychotrope == _this.psychotrope)&&(identical(other.remboursable, _this.remboursable) || other.remboursable == _this.remboursable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Produit;
  return Object.hashAll([runtimeType,_this.id,_this.nom,_this.dci,_this.dosage,_this.forme,_this.formeAbr,_this.idFamille,_this.famille,_this.labo,_this.codeBarre,_this.conditionnement,_this.stock,_this.seuil,_this.prixVente,_this.prixAchat,_this.valeurAchat,_this.valeurVente,_this.vendu12Mois,_this.derniereVente,_this.actif,_this.classeAbc,_this.classeXyz,_this.categorie,_this.disponibilite,_this.psychotrope,_this.remboursable]);
}

@override
String toString() {
  final _this = this as Produit;
  return 'Produit(id: ${_this.id}, nom: ${_this.nom}, dci: ${_this.dci}, dosage: ${_this.dosage}, forme: ${_this.forme}, formeAbr: ${_this.formeAbr}, idFamille: ${_this.idFamille}, famille: ${_this.famille}, labo: ${_this.labo}, codeBarre: ${_this.codeBarre}, conditionnement: ${_this.conditionnement}, stock: ${_this.stock}, seuil: ${_this.seuil}, prixVente: ${_this.prixVente}, prixAchat: ${_this.prixAchat}, valeurAchat: ${_this.valeurAchat}, valeurVente: ${_this.valeurVente}, vendu12Mois: ${_this.vendu12Mois}, derniereVente: ${_this.derniereVente}, actif: ${_this.actif}, classeAbc: ${_this.classeAbc}, classeXyz: ${_this.classeXyz}, categorie: ${_this.categorie}, disponibilite: ${_this.disponibilite}, psychotrope: ${_this.psychotrope}, remboursable: ${_this.remboursable})';
}


}

/// @nodoc
abstract mixin class $ProduitCopyWith<$Res>  {
  factory $ProduitCopyWith(Produit value, $Res Function(Produit) _then) = _$ProduitCopyWithImpl;
@useResult
$Res call({
 int id, String nom, String? dci, String? dosage, String? forme,@JsonKey(name: 'forme_abr') String? formeAbr,@JsonKey(name: 'id_famille') int? idFamille, String? famille, String? labo,@JsonKey(name: 'code_barre_original') String? codeBarre, String? conditionnement, double stock,@JsonKey(name: 'qte_alerte') int? seuil,@JsonKey(name: 'prix_vente') double prixVente,@JsonKey(name: 'prix_achat_moyen') double prixAchat,@JsonKey(name: 'valeur_achat') double valeurAchat,@JsonKey(name: 'valeur_vente') double valeurVente,@JsonKey(name: 'qte_vendue_12m') int? vendu12Mois,@JsonKey(name: 'derniere_vente') DateTime? derniereVente, bool actif,@JsonKey(name: 'segment_abc') String? classeAbc,@JsonKey(name: 'segment_xyz') String? classeXyz, String? categorie, String? disponibilite, int? psychotrope,@JsonKey(name: 'remb_cvm') int? remboursable
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nom = null,Object? dci = freezed,Object? dosage = freezed,Object? forme = freezed,Object? formeAbr = freezed,Object? idFamille = freezed,Object? famille = freezed,Object? labo = freezed,Object? codeBarre = freezed,Object? conditionnement = freezed,Object? stock = null,Object? seuil = freezed,Object? prixVente = null,Object? prixAchat = null,Object? valeurAchat = null,Object? valeurVente = null,Object? vendu12Mois = freezed,Object? derniereVente = freezed,Object? actif = null,Object? classeAbc = freezed,Object? classeXyz = freezed,Object? categorie = freezed,Object? disponibilite = freezed,Object? psychotrope = freezed,Object? remboursable = freezed,}) {
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
as int?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String nom,  String? dci,  String? dosage,  String? forme, @JsonKey(name: 'forme_abr')  String? formeAbr, @JsonKey(name: 'id_famille')  int? idFamille,  String? famille,  String? labo, @JsonKey(name: 'code_barre_original')  String? codeBarre,  String? conditionnement,  double stock, @JsonKey(name: 'qte_alerte')  int? seuil, @JsonKey(name: 'prix_vente')  double prixVente, @JsonKey(name: 'prix_achat_moyen')  double prixAchat, @JsonKey(name: 'valeur_achat')  double valeurAchat, @JsonKey(name: 'valeur_vente')  double valeurVente, @JsonKey(name: 'qte_vendue_12m')  int? vendu12Mois, @JsonKey(name: 'derniere_vente')  DateTime? derniereVente,  bool actif, @JsonKey(name: 'segment_abc')  String? classeAbc, @JsonKey(name: 'segment_xyz')  String? classeXyz,  String? categorie,  String? disponibilite,  int? psychotrope, @JsonKey(name: 'remb_cvm')  int? remboursable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Produit() when $default != null:
return $default(_that.id,_that.nom,_that.dci,_that.dosage,_that.forme,_that.formeAbr,_that.idFamille,_that.famille,_that.labo,_that.codeBarre,_that.conditionnement,_that.stock,_that.seuil,_that.prixVente,_that.prixAchat,_that.valeurAchat,_that.valeurVente,_that.vendu12Mois,_that.derniereVente,_that.actif,_that.classeAbc,_that.classeXyz,_that.categorie,_that.disponibilite,_that.psychotrope,_that.remboursable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String nom,  String? dci,  String? dosage,  String? forme, @JsonKey(name: 'forme_abr')  String? formeAbr, @JsonKey(name: 'id_famille')  int? idFamille,  String? famille,  String? labo, @JsonKey(name: 'code_barre_original')  String? codeBarre,  String? conditionnement,  double stock, @JsonKey(name: 'qte_alerte')  int? seuil, @JsonKey(name: 'prix_vente')  double prixVente, @JsonKey(name: 'prix_achat_moyen')  double prixAchat, @JsonKey(name: 'valeur_achat')  double valeurAchat, @JsonKey(name: 'valeur_vente')  double valeurVente, @JsonKey(name: 'qte_vendue_12m')  int? vendu12Mois, @JsonKey(name: 'derniere_vente')  DateTime? derniereVente,  bool actif, @JsonKey(name: 'segment_abc')  String? classeAbc, @JsonKey(name: 'segment_xyz')  String? classeXyz,  String? categorie,  String? disponibilite,  int? psychotrope, @JsonKey(name: 'remb_cvm')  int? remboursable)  $default,) {final _that = this;
switch (_that) {
case _Produit():
return $default(_that.id,_that.nom,_that.dci,_that.dosage,_that.forme,_that.formeAbr,_that.idFamille,_that.famille,_that.labo,_that.codeBarre,_that.conditionnement,_that.stock,_that.seuil,_that.prixVente,_that.prixAchat,_that.valeurAchat,_that.valeurVente,_that.vendu12Mois,_that.derniereVente,_that.actif,_that.classeAbc,_that.classeXyz,_that.categorie,_that.disponibilite,_that.psychotrope,_that.remboursable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String nom,  String? dci,  String? dosage,  String? forme, @JsonKey(name: 'forme_abr')  String? formeAbr, @JsonKey(name: 'id_famille')  int? idFamille,  String? famille,  String? labo, @JsonKey(name: 'code_barre_original')  String? codeBarre,  String? conditionnement,  double stock, @JsonKey(name: 'qte_alerte')  int? seuil, @JsonKey(name: 'prix_vente')  double prixVente, @JsonKey(name: 'prix_achat_moyen')  double prixAchat, @JsonKey(name: 'valeur_achat')  double valeurAchat, @JsonKey(name: 'valeur_vente')  double valeurVente, @JsonKey(name: 'qte_vendue_12m')  int? vendu12Mois, @JsonKey(name: 'derniere_vente')  DateTime? derniereVente,  bool actif, @JsonKey(name: 'segment_abc')  String? classeAbc, @JsonKey(name: 'segment_xyz')  String? classeXyz,  String? categorie,  String? disponibilite,  int? psychotrope, @JsonKey(name: 'remb_cvm')  int? remboursable)?  $default,) {final _that = this;
switch (_that) {
case _Produit() when $default != null:
return $default(_that.id,_that.nom,_that.dci,_that.dosage,_that.forme,_that.formeAbr,_that.idFamille,_that.famille,_that.labo,_that.codeBarre,_that.conditionnement,_that.stock,_that.seuil,_that.prixVente,_that.prixAchat,_that.valeurAchat,_that.valeurVente,_that.vendu12Mois,_that.derniereVente,_that.actif,_that.classeAbc,_that.classeXyz,_that.categorie,_that.disponibilite,_that.psychotrope,_that.remboursable);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Produit extends Produit {
  const _Produit({required this.id, this.nom = '', this.dci, this.dosage, this.forme, @JsonKey(name: 'forme_abr') this.formeAbr, @JsonKey(name: 'id_famille') this.idFamille, this.famille, this.labo, @JsonKey(name: 'code_barre_original') this.codeBarre, this.conditionnement, this.stock = 0, @JsonKey(name: 'qte_alerte') this.seuil, @JsonKey(name: 'prix_vente') this.prixVente = 0, @JsonKey(name: 'prix_achat_moyen') this.prixAchat = 0, @JsonKey(name: 'valeur_achat') this.valeurAchat = 0, @JsonKey(name: 'valeur_vente') this.valeurVente = 0, @JsonKey(name: 'qte_vendue_12m') this.vendu12Mois, @JsonKey(name: 'derniere_vente') this.derniereVente, this.actif = false, @JsonKey(name: 'segment_abc') this.classeAbc, @JsonKey(name: 'segment_xyz') this.classeXyz, this.categorie, this.disponibilite, this.psychotrope, @JsonKey(name: 'remb_cvm') this.remboursable}): super._();
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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Produit&&(identical(other.id, id) || other.id == id)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.dci, dci) || other.dci == dci)&&(identical(other.dosage, dosage) || other.dosage == dosage)&&(identical(other.forme, forme) || other.forme == forme)&&(identical(other.formeAbr, formeAbr) || other.formeAbr == formeAbr)&&(identical(other.idFamille, idFamille) || other.idFamille == idFamille)&&(identical(other.famille, famille) || other.famille == famille)&&(identical(other.labo, labo) || other.labo == labo)&&(identical(other.codeBarre, codeBarre) || other.codeBarre == codeBarre)&&(identical(other.conditionnement, conditionnement) || other.conditionnement == conditionnement)&&(identical(other.stock, stock) || other.stock == stock)&&(identical(other.seuil, seuil) || other.seuil == seuil)&&(identical(other.prixVente, prixVente) || other.prixVente == prixVente)&&(identical(other.prixAchat, prixAchat) || other.prixAchat == prixAchat)&&(identical(other.valeurAchat, valeurAchat) || other.valeurAchat == valeurAchat)&&(identical(other.valeurVente, valeurVente) || other.valeurVente == valeurVente)&&(identical(other.vendu12Mois, vendu12Mois) || other.vendu12Mois == vendu12Mois)&&(identical(other.derniereVente, derniereVente) || other.derniereVente == derniereVente)&&(identical(other.actif, actif) || other.actif == actif)&&(identical(other.classeAbc, classeAbc) || other.classeAbc == classeAbc)&&(identical(other.classeXyz, classeXyz) || other.classeXyz == classeXyz)&&(identical(other.categorie, categorie) || other.categorie == categorie)&&(identical(other.disponibilite, disponibilite) || other.disponibilite == disponibilite)&&(identical(other.psychotrope, psychotrope) || other.psychotrope == psychotrope)&&(identical(other.remboursable, remboursable) || other.remboursable == remboursable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,nom,dci,dosage,forme,formeAbr,idFamille,famille,labo,codeBarre,conditionnement,stock,seuil,prixVente,prixAchat,valeurAchat,valeurVente,vendu12Mois,derniereVente,actif,classeAbc,classeXyz,categorie,disponibilite,psychotrope,remboursable]);
}

@override
String toString() {
    return 'Produit(id: $id, nom: $nom, dci: $dci, dosage: $dosage, forme: $forme, formeAbr: $formeAbr, idFamille: $idFamille, famille: $famille, labo: $labo, codeBarre: $codeBarre, conditionnement: $conditionnement, stock: $stock, seuil: $seuil, prixVente: $prixVente, prixAchat: $prixAchat, valeurAchat: $valeurAchat, valeurVente: $valeurVente, vendu12Mois: $vendu12Mois, derniereVente: $derniereVente, actif: $actif, classeAbc: $classeAbc, classeXyz: $classeXyz, categorie: $categorie, disponibilite: $disponibilite, psychotrope: $psychotrope, remboursable: $remboursable)';
}


}

/// @nodoc
abstract mixin class _$ProduitCopyWith<$Res> implements $ProduitCopyWith<$Res> {
  factory _$ProduitCopyWith(_Produit value, $Res Function(_Produit) _then) = __$ProduitCopyWithImpl;
@override @useResult
$Res call({
 int id, String nom, String? dci, String? dosage, String? forme,@JsonKey(name: 'forme_abr') String? formeAbr,@JsonKey(name: 'id_famille') int? idFamille, String? famille, String? labo,@JsonKey(name: 'code_barre_original') String? codeBarre, String? conditionnement, double stock,@JsonKey(name: 'qte_alerte') int? seuil,@JsonKey(name: 'prix_vente') double prixVente,@JsonKey(name: 'prix_achat_moyen') double prixAchat,@JsonKey(name: 'valeur_achat') double valeurAchat,@JsonKey(name: 'valeur_vente') double valeurVente,@JsonKey(name: 'qte_vendue_12m') int? vendu12Mois,@JsonKey(name: 'derniere_vente') DateTime? derniereVente, bool actif,@JsonKey(name: 'segment_abc') String? classeAbc,@JsonKey(name: 'segment_xyz') String? classeXyz, String? categorie, String? disponibilite, int? psychotrope,@JsonKey(name: 'remb_cvm') int? remboursable
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nom = null,Object? dci = freezed,Object? dosage = freezed,Object? forme = freezed,Object? formeAbr = freezed,Object? idFamille = freezed,Object? famille = freezed,Object? labo = freezed,Object? codeBarre = freezed,Object? conditionnement = freezed,Object? stock = null,Object? seuil = freezed,Object? prixVente = null,Object? prixAchat = null,Object? valeurAchat = null,Object? valeurVente = null,Object? vendu12Mois = freezed,Object? derniereVente = freezed,Object? actif = null,Object? classeAbc = freezed,Object? classeXyz = freezed,Object? categorie = freezed,Object? disponibilite = freezed,Object? psychotrope = freezed,Object? remboursable = freezed,}) {
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
as int?,
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
