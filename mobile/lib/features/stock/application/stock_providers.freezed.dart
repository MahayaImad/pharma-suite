// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock_providers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ListeProduits {

 List<Produit> get produits; int get total; bool get chargeSuite;
/// Create a copy of ListeProduits
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListeProduitsCopyWith<ListeProduits> get copyWith => _$ListeProduitsCopyWithImpl<ListeProduits>(this as ListeProduits, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ListeProduits;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListeProduits&&const DeepCollectionEquality().equals(other.produits, _this.produits)&&(identical(other.total, _this.total) || other.total == _this.total)&&(identical(other.chargeSuite, _this.chargeSuite) || other.chargeSuite == _this.chargeSuite));
}


@override
int get hashCode {
  final _this = this as ListeProduits;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.produits),_this.total,_this.chargeSuite);
}

@override
String toString() {
  final _this = this as ListeProduits;
  return 'ListeProduits(produits: ${_this.produits}, total: ${_this.total}, chargeSuite: ${_this.chargeSuite})';
}


}

/// @nodoc
abstract mixin class $ListeProduitsCopyWith<$Res>  {
  factory $ListeProduitsCopyWith(ListeProduits value, $Res Function(ListeProduits) _then) = _$ListeProduitsCopyWithImpl;
@useResult
$Res call({
 List<Produit> produits, int total, bool chargeSuite
});




}
/// @nodoc
class _$ListeProduitsCopyWithImpl<$Res>
    implements $ListeProduitsCopyWith<$Res> {
  _$ListeProduitsCopyWithImpl(this._self, this._then);

  final ListeProduits _self;
  final $Res Function(ListeProduits) _then;

/// Create a copy of ListeProduits
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? produits = null,Object? total = null,Object? chargeSuite = null,}) {
  return _then(ListeProduits(
produits: null == produits ? _self.produits : produits // ignore: cast_nullable_to_non_nullable
as List<Produit>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,chargeSuite: null == chargeSuite ? _self.chargeSuite : chargeSuite // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ListeProduits].
extension ListeProduitsPatterns on ListeProduits {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ListeProduits value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ListeProduits() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ListeProduits value)  $default,){
final _that = this;
switch (_that) {
case _ListeProduits():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ListeProduits value)?  $default,){
final _that = this;
switch (_that) {
case _ListeProduits() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Produit> produits,  int total,  bool chargeSuite)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ListeProduits() when $default != null:
return $default(_that.produits,_that.total,_that.chargeSuite);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Produit> produits,  int total,  bool chargeSuite)  $default,) {final _that = this;
switch (_that) {
case _ListeProduits():
return $default(_that.produits,_that.total,_that.chargeSuite);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Produit> produits,  int total,  bool chargeSuite)?  $default,) {final _that = this;
switch (_that) {
case _ListeProduits() when $default != null:
return $default(_that.produits,_that.total,_that.chargeSuite);case _:
  return null;

}
}

}

/// @nodoc


class _ListeProduits extends ListeProduits {
  const _ListeProduits({ List<Produit> produits = const <Produit>[], this.total = 0, this.chargeSuite = false}): _produits = produits,super._();
  

 final  List<Produit> _produits;
@override@JsonKey() List<Produit> get produits {
  if (_produits is EqualUnmodifiableListView) return _produits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_produits);
}

@override@JsonKey() final  int total;
@override@JsonKey() final  bool chargeSuite;

/// Create a copy of ListeProduits
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListeProduitsCopyWith<_ListeProduits> get copyWith => __$ListeProduitsCopyWithImpl<_ListeProduits>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListeProduits&&const DeepCollectionEquality().equals(other.produits, _produits)&&(identical(other.total, total) || other.total == total)&&(identical(other.chargeSuite, chargeSuite) || other.chargeSuite == chargeSuite));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_produits),total,chargeSuite);
}

@override
String toString() {
    return 'ListeProduits(produits: $produits, total: $total, chargeSuite: $chargeSuite)';
}


}

/// @nodoc
abstract mixin class _$ListeProduitsCopyWith<$Res> implements $ListeProduitsCopyWith<$Res> {
  factory _$ListeProduitsCopyWith(_ListeProduits value, $Res Function(_ListeProduits) _then) = __$ListeProduitsCopyWithImpl;
@override @useResult
$Res call({
 List<Produit> produits, int total, bool chargeSuite
});




}
/// @nodoc
class __$ListeProduitsCopyWithImpl<$Res>
    implements _$ListeProduitsCopyWith<$Res> {
  __$ListeProduitsCopyWithImpl(this._self, this._then);

  final _ListeProduits _self;
  final $Res Function(_ListeProduits) _then;

/// Create a copy of ListeProduits
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? produits = null,Object? total = null,Object? chargeSuite = null,}) {
  return _then(_ListeProduits(
produits: null == produits ? _self._produits : produits // ignore: cast_nullable_to_non_nullable
as List<Produit>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,chargeSuite: null == chargeSuite ? _self.chargeSuite : chargeSuite // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
