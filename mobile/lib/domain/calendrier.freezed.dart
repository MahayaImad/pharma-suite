// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'calendrier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Garde {

 DateTime get date; TypeGarde get type; String get source; bool get confirme; String? get note;@JsonKey(name: 'modifie_par') String? get modifiePar;
/// Create a copy of Garde
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GardeCopyWith<Garde> get copyWith => _$GardeCopyWithImpl<Garde>(this as Garde, _$identity);

  /// Serializes this Garde to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Garde;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Garde&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.confirme, _this.confirme) || other.confirme == _this.confirme)&&(identical(other.note, _this.note) || other.note == _this.note)&&(identical(other.modifiePar, _this.modifiePar) || other.modifiePar == _this.modifiePar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Garde;
  return Object.hash(runtimeType,_this.date,_this.type,_this.source,_this.confirme,_this.note,_this.modifiePar);
}

@override
String toString() {
  final _this = this as Garde;
  return 'Garde(date: ${_this.date}, type: ${_this.type}, source: ${_this.source}, confirme: ${_this.confirme}, note: ${_this.note}, modifiePar: ${_this.modifiePar})';
}


}

/// @nodoc
abstract mixin class $GardeCopyWith<$Res>  {
  factory $GardeCopyWith(Garde value, $Res Function(Garde) _then) = _$GardeCopyWithImpl;
@useResult
$Res call({
 DateTime date, TypeGarde type, String source, bool confirme, String? note,@JsonKey(name: 'modifie_par') String? modifiePar
});




}
/// @nodoc
class _$GardeCopyWithImpl<$Res>
    implements $GardeCopyWith<$Res> {
  _$GardeCopyWithImpl(this._self, this._then);

  final Garde _self;
  final $Res Function(Garde) _then;

/// Create a copy of Garde
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? type = null,Object? source = null,Object? confirme = null,Object? note = freezed,Object? modifiePar = freezed,}) {
  return _then(Garde(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeGarde,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,confirme: null == confirme ? _self.confirme : confirme // ignore: cast_nullable_to_non_nullable
as bool,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,modifiePar: freezed == modifiePar ? _self.modifiePar : modifiePar // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Garde].
extension GardePatterns on Garde {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Garde value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Garde() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Garde value)  $default,){
final _that = this;
switch (_that) {
case _Garde():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Garde value)?  $default,){
final _that = this;
switch (_that) {
case _Garde() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  TypeGarde type,  String source,  bool confirme,  String? note, @JsonKey(name: 'modifie_par')  String? modifiePar)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Garde() when $default != null:
return $default(_that.date,_that.type,_that.source,_that.confirme,_that.note,_that.modifiePar);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  TypeGarde type,  String source,  bool confirme,  String? note, @JsonKey(name: 'modifie_par')  String? modifiePar)  $default,) {final _that = this;
switch (_that) {
case _Garde():
return $default(_that.date,_that.type,_that.source,_that.confirme,_that.note,_that.modifiePar);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  TypeGarde type,  String source,  bool confirme,  String? note, @JsonKey(name: 'modifie_par')  String? modifiePar)?  $default,) {final _that = this;
switch (_that) {
case _Garde() when $default != null:
return $default(_that.date,_that.type,_that.source,_that.confirme,_that.note,_that.modifiePar);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Garde extends Garde {
  const _Garde({required this.date, required this.type, this.source = 'saisie', this.confirme = true, this.note, @JsonKey(name: 'modifie_par') this.modifiePar}): super._();
  factory _Garde.fromJson(Map<String, dynamic> json) => _$GardeFromJson(json);

@override final  DateTime date;
@override final  TypeGarde type;
@override@JsonKey() final  String source;
@override@JsonKey() final  bool confirme;
@override final  String? note;
@override@JsonKey(name: 'modifie_par') final  String? modifiePar;

/// Create a copy of Garde
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GardeCopyWith<_Garde> get copyWith => __$GardeCopyWithImpl<_Garde>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GardeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Garde&&(identical(other.date, date) || other.date == date)&&(identical(other.type, type) || other.type == type)&&(identical(other.source, source) || other.source == source)&&(identical(other.confirme, confirme) || other.confirme == confirme)&&(identical(other.note, note) || other.note == note)&&(identical(other.modifiePar, modifiePar) || other.modifiePar == modifiePar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,date,type,source,confirme,note,modifiePar);
}

@override
String toString() {
    return 'Garde(date: $date, type: $type, source: $source, confirme: $confirme, note: $note, modifiePar: $modifiePar)';
}


}

/// @nodoc
abstract mixin class _$GardeCopyWith<$Res> implements $GardeCopyWith<$Res> {
  factory _$GardeCopyWith(_Garde value, $Res Function(_Garde) _then) = __$GardeCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, TypeGarde type, String source, bool confirme, String? note,@JsonKey(name: 'modifie_par') String? modifiePar
});




}
/// @nodoc
class __$GardeCopyWithImpl<$Res>
    implements _$GardeCopyWith<$Res> {
  __$GardeCopyWithImpl(this._self, this._then);

  final _Garde _self;
  final $Res Function(_Garde) _then;

/// Create a copy of Garde
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? type = null,Object? source = null,Object? confirme = null,Object? note = freezed,Object? modifiePar = freezed,}) {
  return _then(_Garde(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeGarde,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,confirme: null == confirme ? _self.confirme : confirme // ignore: cast_nullable_to_non_nullable
as bool,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,modifiePar: freezed == modifiePar ? _self.modifiePar : modifiePar // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Evenement {

 int get id; TypeEvenement get type;@JsonKey(name: 'date_debut') DateTime get debut;@JsonKey(name: 'date_fin') DateTime get fin;@JsonKey(name: 'a_verifier') bool get aVerifier;
/// Create a copy of Evenement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EvenementCopyWith<Evenement> get copyWith => _$EvenementCopyWithImpl<Evenement>(this as Evenement, _$identity);

  /// Serializes this Evenement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Evenement;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Evenement&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.debut, _this.debut) || other.debut == _this.debut)&&(identical(other.fin, _this.fin) || other.fin == _this.fin)&&(identical(other.aVerifier, _this.aVerifier) || other.aVerifier == _this.aVerifier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Evenement;
  return Object.hash(runtimeType,_this.id,_this.type,_this.debut,_this.fin,_this.aVerifier);
}

@override
String toString() {
  final _this = this as Evenement;
  return 'Evenement(id: ${_this.id}, type: ${_this.type}, debut: ${_this.debut}, fin: ${_this.fin}, aVerifier: ${_this.aVerifier})';
}


}

/// @nodoc
abstract mixin class $EvenementCopyWith<$Res>  {
  factory $EvenementCopyWith(Evenement value, $Res Function(Evenement) _then) = _$EvenementCopyWithImpl;
@useResult
$Res call({
 int id, TypeEvenement type,@JsonKey(name: 'date_debut') DateTime debut,@JsonKey(name: 'date_fin') DateTime fin,@JsonKey(name: 'a_verifier') bool aVerifier
});




}
/// @nodoc
class _$EvenementCopyWithImpl<$Res>
    implements $EvenementCopyWith<$Res> {
  _$EvenementCopyWithImpl(this._self, this._then);

  final Evenement _self;
  final $Res Function(Evenement) _then;

/// Create a copy of Evenement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? debut = null,Object? fin = null,Object? aVerifier = null,}) {
  return _then(Evenement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeEvenement,debut: null == debut ? _self.debut : debut // ignore: cast_nullable_to_non_nullable
as DateTime,fin: null == fin ? _self.fin : fin // ignore: cast_nullable_to_non_nullable
as DateTime,aVerifier: null == aVerifier ? _self.aVerifier : aVerifier // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Evenement].
extension EvenementPatterns on Evenement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Evenement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Evenement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Evenement value)  $default,){
final _that = this;
switch (_that) {
case _Evenement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Evenement value)?  $default,){
final _that = this;
switch (_that) {
case _Evenement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  TypeEvenement type, @JsonKey(name: 'date_debut')  DateTime debut, @JsonKey(name: 'date_fin')  DateTime fin, @JsonKey(name: 'a_verifier')  bool aVerifier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Evenement() when $default != null:
return $default(_that.id,_that.type,_that.debut,_that.fin,_that.aVerifier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  TypeEvenement type, @JsonKey(name: 'date_debut')  DateTime debut, @JsonKey(name: 'date_fin')  DateTime fin, @JsonKey(name: 'a_verifier')  bool aVerifier)  $default,) {final _that = this;
switch (_that) {
case _Evenement():
return $default(_that.id,_that.type,_that.debut,_that.fin,_that.aVerifier);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  TypeEvenement type, @JsonKey(name: 'date_debut')  DateTime debut, @JsonKey(name: 'date_fin')  DateTime fin, @JsonKey(name: 'a_verifier')  bool aVerifier)?  $default,) {final _that = this;
switch (_that) {
case _Evenement() when $default != null:
return $default(_that.id,_that.type,_that.debut,_that.fin,_that.aVerifier);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Evenement extends Evenement {
  const _Evenement({required this.id, required this.type, @JsonKey(name: 'date_debut') required this.debut, @JsonKey(name: 'date_fin') required this.fin, @JsonKey(name: 'a_verifier') this.aVerifier = false}): super._();
  factory _Evenement.fromJson(Map<String, dynamic> json) => _$EvenementFromJson(json);

@override final  int id;
@override final  TypeEvenement type;
@override@JsonKey(name: 'date_debut') final  DateTime debut;
@override@JsonKey(name: 'date_fin') final  DateTime fin;
@override@JsonKey(name: 'a_verifier') final  bool aVerifier;

/// Create a copy of Evenement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EvenementCopyWith<_Evenement> get copyWith => __$EvenementCopyWithImpl<_Evenement>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EvenementToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Evenement&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.debut, debut) || other.debut == debut)&&(identical(other.fin, fin) || other.fin == fin)&&(identical(other.aVerifier, aVerifier) || other.aVerifier == aVerifier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,type,debut,fin,aVerifier);
}

@override
String toString() {
    return 'Evenement(id: $id, type: $type, debut: $debut, fin: $fin, aVerifier: $aVerifier)';
}


}

/// @nodoc
abstract mixin class _$EvenementCopyWith<$Res> implements $EvenementCopyWith<$Res> {
  factory _$EvenementCopyWith(_Evenement value, $Res Function(_Evenement) _then) = __$EvenementCopyWithImpl;
@override @useResult
$Res call({
 int id, TypeEvenement type,@JsonKey(name: 'date_debut') DateTime debut,@JsonKey(name: 'date_fin') DateTime fin,@JsonKey(name: 'a_verifier') bool aVerifier
});




}
/// @nodoc
class __$EvenementCopyWithImpl<$Res>
    implements _$EvenementCopyWith<$Res> {
  __$EvenementCopyWithImpl(this._self, this._then);

  final _Evenement _self;
  final $Res Function(_Evenement) _then;

/// Create a copy of Evenement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? debut = null,Object? fin = null,Object? aVerifier = null,}) {
  return _then(_Evenement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeEvenement,debut: null == debut ? _self.debut : debut // ignore: cast_nullable_to_non_nullable
as DateTime,fin: null == fin ? _self.fin : fin // ignore: cast_nullable_to_non_nullable
as DateTime,aVerifier: null == aVerifier ? _self.aVerifier : aVerifier // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$Ferie {

 int get id; DateTime get date; String? get label;
/// Create a copy of Ferie
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FerieCopyWith<Ferie> get copyWith => _$FerieCopyWithImpl<Ferie>(this as Ferie, _$identity);

  /// Serializes this Ferie to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Ferie;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Ferie&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.label, _this.label) || other.label == _this.label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Ferie;
  return Object.hash(runtimeType,_this.id,_this.date,_this.label);
}

@override
String toString() {
  final _this = this as Ferie;
  return 'Ferie(id: ${_this.id}, date: ${_this.date}, label: ${_this.label})';
}


}

/// @nodoc
abstract mixin class $FerieCopyWith<$Res>  {
  factory $FerieCopyWith(Ferie value, $Res Function(Ferie) _then) = _$FerieCopyWithImpl;
@useResult
$Res call({
 int id, DateTime date, String? label
});




}
/// @nodoc
class _$FerieCopyWithImpl<$Res>
    implements $FerieCopyWith<$Res> {
  _$FerieCopyWithImpl(this._self, this._then);

  final Ferie _self;
  final $Res Function(Ferie) _then;

/// Create a copy of Ferie
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? date = null,Object? label = freezed,}) {
  return _then(Ferie(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Ferie].
extension FeriePatterns on Ferie {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Ferie value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Ferie() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Ferie value)  $default,){
final _that = this;
switch (_that) {
case _Ferie():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Ferie value)?  $default,){
final _that = this;
switch (_that) {
case _Ferie() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  DateTime date,  String? label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Ferie() when $default != null:
return $default(_that.id,_that.date,_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  DateTime date,  String? label)  $default,) {final _that = this;
switch (_that) {
case _Ferie():
return $default(_that.id,_that.date,_that.label);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  DateTime date,  String? label)?  $default,) {final _that = this;
switch (_that) {
case _Ferie() when $default != null:
return $default(_that.id,_that.date,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Ferie implements Ferie {
  const _Ferie({required this.id, required this.date, this.label});
  factory _Ferie.fromJson(Map<String, dynamic> json) => _$FerieFromJson(json);

@override final  int id;
@override final  DateTime date;
@override final  String? label;

/// Create a copy of Ferie
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FerieCopyWith<_Ferie> get copyWith => __$FerieCopyWithImpl<_Ferie>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FerieToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Ferie&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,date,label);
}

@override
String toString() {
    return 'Ferie(id: $id, date: $date, label: $label)';
}


}

/// @nodoc
abstract mixin class _$FerieCopyWith<$Res> implements $FerieCopyWith<$Res> {
  factory _$FerieCopyWith(_Ferie value, $Res Function(_Ferie) _then) = __$FerieCopyWithImpl;
@override @useResult
$Res call({
 int id, DateTime date, String? label
});




}
/// @nodoc
class __$FerieCopyWithImpl<$Res>
    implements _$FerieCopyWith<$Res> {
  __$FerieCopyWithImpl(this._self, this._then);

  final _Ferie _self;
  final $Res Function(_Ferie) _then;

/// Create a copy of Ferie
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? date = null,Object? label = freezed,}) {
  return _then(_Ferie(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Reglage {

 String get cle; double get valeur; String? get description;@JsonKey(name: 'modifie_par') String? get modifiePar;
/// Create a copy of Reglage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReglageCopyWith<Reglage> get copyWith => _$ReglageCopyWithImpl<Reglage>(this as Reglage, _$identity);

  /// Serializes this Reglage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Reglage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Reglage&&(identical(other.cle, _this.cle) || other.cle == _this.cle)&&(identical(other.valeur, _this.valeur) || other.valeur == _this.valeur)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.modifiePar, _this.modifiePar) || other.modifiePar == _this.modifiePar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Reglage;
  return Object.hash(runtimeType,_this.cle,_this.valeur,_this.description,_this.modifiePar);
}

@override
String toString() {
  final _this = this as Reglage;
  return 'Reglage(cle: ${_this.cle}, valeur: ${_this.valeur}, description: ${_this.description}, modifiePar: ${_this.modifiePar})';
}


}

/// @nodoc
abstract mixin class $ReglageCopyWith<$Res>  {
  factory $ReglageCopyWith(Reglage value, $Res Function(Reglage) _then) = _$ReglageCopyWithImpl;
@useResult
$Res call({
 String cle, double valeur, String? description,@JsonKey(name: 'modifie_par') String? modifiePar
});




}
/// @nodoc
class _$ReglageCopyWithImpl<$Res>
    implements $ReglageCopyWith<$Res> {
  _$ReglageCopyWithImpl(this._self, this._then);

  final Reglage _self;
  final $Res Function(Reglage) _then;

/// Create a copy of Reglage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cle = null,Object? valeur = null,Object? description = freezed,Object? modifiePar = freezed,}) {
  return _then(Reglage(
cle: null == cle ? _self.cle : cle // ignore: cast_nullable_to_non_nullable
as String,valeur: null == valeur ? _self.valeur : valeur // ignore: cast_nullable_to_non_nullable
as double,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,modifiePar: freezed == modifiePar ? _self.modifiePar : modifiePar // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Reglage].
extension ReglagePatterns on Reglage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Reglage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Reglage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Reglage value)  $default,){
final _that = this;
switch (_that) {
case _Reglage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Reglage value)?  $default,){
final _that = this;
switch (_that) {
case _Reglage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String cle,  double valeur,  String? description, @JsonKey(name: 'modifie_par')  String? modifiePar)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Reglage() when $default != null:
return $default(_that.cle,_that.valeur,_that.description,_that.modifiePar);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String cle,  double valeur,  String? description, @JsonKey(name: 'modifie_par')  String? modifiePar)  $default,) {final _that = this;
switch (_that) {
case _Reglage():
return $default(_that.cle,_that.valeur,_that.description,_that.modifiePar);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String cle,  double valeur,  String? description, @JsonKey(name: 'modifie_par')  String? modifiePar)?  $default,) {final _that = this;
switch (_that) {
case _Reglage() when $default != null:
return $default(_that.cle,_that.valeur,_that.description,_that.modifiePar);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Reglage implements Reglage {
  const _Reglage({required this.cle, required this.valeur, this.description, @JsonKey(name: 'modifie_par') this.modifiePar});
  factory _Reglage.fromJson(Map<String, dynamic> json) => _$ReglageFromJson(json);

@override final  String cle;
@override final  double valeur;
@override final  String? description;
@override@JsonKey(name: 'modifie_par') final  String? modifiePar;

/// Create a copy of Reglage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReglageCopyWith<_Reglage> get copyWith => __$ReglageCopyWithImpl<_Reglage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReglageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Reglage&&(identical(other.cle, cle) || other.cle == cle)&&(identical(other.valeur, valeur) || other.valeur == valeur)&&(identical(other.description, description) || other.description == description)&&(identical(other.modifiePar, modifiePar) || other.modifiePar == modifiePar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,cle,valeur,description,modifiePar);
}

@override
String toString() {
    return 'Reglage(cle: $cle, valeur: $valeur, description: $description, modifiePar: $modifiePar)';
}


}

/// @nodoc
abstract mixin class _$ReglageCopyWith<$Res> implements $ReglageCopyWith<$Res> {
  factory _$ReglageCopyWith(_Reglage value, $Res Function(_Reglage) _then) = __$ReglageCopyWithImpl;
@override @useResult
$Res call({
 String cle, double valeur, String? description,@JsonKey(name: 'modifie_par') String? modifiePar
});




}
/// @nodoc
class __$ReglageCopyWithImpl<$Res>
    implements _$ReglageCopyWith<$Res> {
  __$ReglageCopyWithImpl(this._self, this._then);

  final _Reglage _self;
  final $Res Function(_Reglage) _then;

/// Create a copy of Reglage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cle = null,Object? valeur = null,Object? description = freezed,Object? modifiePar = freezed,}) {
  return _then(_Reglage(
cle: null == cle ? _self.cle : cle // ignore: cast_nullable_to_non_nullable
as String,valeur: null == valeur ? _self.valeur : valeur // ignore: cast_nullable_to_non_nullable
as double,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,modifiePar: freezed == modifiePar ? _self.modifiePar : modifiePar // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
