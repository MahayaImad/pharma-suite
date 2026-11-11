// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReponseJeton {

@JsonKey(name: 'access_token') String get jeton;@JsonKey(name: 'token_type') String get type;
/// Create a copy of ReponseJeton
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReponseJetonCopyWith<ReponseJeton> get copyWith => _$ReponseJetonCopyWithImpl<ReponseJeton>(this as ReponseJeton, _$identity);

  /// Serializes this ReponseJeton to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ReponseJeton;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReponseJeton&&(identical(other.jeton, _this.jeton) || other.jeton == _this.jeton)&&(identical(other.type, _this.type) || other.type == _this.type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ReponseJeton;
  return Object.hash(runtimeType,_this.jeton,_this.type);
}

@override
String toString() {
  final _this = this as ReponseJeton;
  return 'ReponseJeton(jeton: ${_this.jeton}, type: ${_this.type})';
}


}

/// @nodoc
abstract mixin class $ReponseJetonCopyWith<$Res>  {
  factory $ReponseJetonCopyWith(ReponseJeton value, $Res Function(ReponseJeton) _then) = _$ReponseJetonCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'access_token') String jeton,@JsonKey(name: 'token_type') String type
});




}
/// @nodoc
class _$ReponseJetonCopyWithImpl<$Res>
    implements $ReponseJetonCopyWith<$Res> {
  _$ReponseJetonCopyWithImpl(this._self, this._then);

  final ReponseJeton _self;
  final $Res Function(ReponseJeton) _then;

/// Create a copy of ReponseJeton
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jeton = null,Object? type = null,}) {
  return _then(ReponseJeton(
jeton: null == jeton ? _self.jeton : jeton // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ReponseJeton].
extension ReponseJetonPatterns on ReponseJeton {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReponseJeton value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReponseJeton() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReponseJeton value)  $default,){
final _that = this;
switch (_that) {
case _ReponseJeton():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReponseJeton value)?  $default,){
final _that = this;
switch (_that) {
case _ReponseJeton() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'access_token')  String jeton, @JsonKey(name: 'token_type')  String type)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReponseJeton() when $default != null:
return $default(_that.jeton,_that.type);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'access_token')  String jeton, @JsonKey(name: 'token_type')  String type)  $default,) {final _that = this;
switch (_that) {
case _ReponseJeton():
return $default(_that.jeton,_that.type);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'access_token')  String jeton, @JsonKey(name: 'token_type')  String type)?  $default,) {final _that = this;
switch (_that) {
case _ReponseJeton() when $default != null:
return $default(_that.jeton,_that.type);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReponseJeton implements ReponseJeton {
  const _ReponseJeton({@JsonKey(name: 'access_token') required this.jeton, @JsonKey(name: 'token_type') this.type = 'bearer'});
  factory _ReponseJeton.fromJson(Map<String, dynamic> json) => _$ReponseJetonFromJson(json);

@override@JsonKey(name: 'access_token') final  String jeton;
@override@JsonKey(name: 'token_type') final  String type;

/// Create a copy of ReponseJeton
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReponseJetonCopyWith<_ReponseJeton> get copyWith => __$ReponseJetonCopyWithImpl<_ReponseJeton>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReponseJetonToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReponseJeton&&(identical(other.jeton, jeton) || other.jeton == jeton)&&(identical(other.type, type) || other.type == type));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,jeton,type);
}

@override
String toString() {
    return 'ReponseJeton(jeton: $jeton, type: $type)';
}


}

/// @nodoc
abstract mixin class _$ReponseJetonCopyWith<$Res> implements $ReponseJetonCopyWith<$Res> {
  factory _$ReponseJetonCopyWith(_ReponseJeton value, $Res Function(_ReponseJeton) _then) = __$ReponseJetonCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'access_token') String jeton,@JsonKey(name: 'token_type') String type
});




}
/// @nodoc
class __$ReponseJetonCopyWithImpl<$Res>
    implements _$ReponseJetonCopyWith<$Res> {
  __$ReponseJetonCopyWithImpl(this._self, this._then);

  final _ReponseJeton _self;
  final $Res Function(_ReponseJeton) _then;

/// Create a copy of ReponseJeton
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jeton = null,Object? type = null,}) {
  return _then(_ReponseJeton(
jeton: null == jeton ? _self.jeton : jeton // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Profil {

@JsonKey(name: 'username') String get utilisateur; String get role; String? get nom; String? get prenom;
/// Create a copy of Profil
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfilCopyWith<Profil> get copyWith => _$ProfilCopyWithImpl<Profil>(this as Profil, _$identity);

  /// Serializes this Profil to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Profil;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Profil&&(identical(other.utilisateur, _this.utilisateur) || other.utilisateur == _this.utilisateur)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.nom, _this.nom) || other.nom == _this.nom)&&(identical(other.prenom, _this.prenom) || other.prenom == _this.prenom));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Profil;
  return Object.hash(runtimeType,_this.utilisateur,_this.role,_this.nom,_this.prenom);
}

@override
String toString() {
  final _this = this as Profil;
  return 'Profil(utilisateur: ${_this.utilisateur}, role: ${_this.role}, nom: ${_this.nom}, prenom: ${_this.prenom})';
}


}

/// @nodoc
abstract mixin class $ProfilCopyWith<$Res>  {
  factory $ProfilCopyWith(Profil value, $Res Function(Profil) _then) = _$ProfilCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'username') String utilisateur, String role, String? nom, String? prenom
});




}
/// @nodoc
class _$ProfilCopyWithImpl<$Res>
    implements $ProfilCopyWith<$Res> {
  _$ProfilCopyWithImpl(this._self, this._then);

  final Profil _self;
  final $Res Function(Profil) _then;

/// Create a copy of Profil
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? utilisateur = null,Object? role = null,Object? nom = freezed,Object? prenom = freezed,}) {
  return _then(Profil(
utilisateur: null == utilisateur ? _self.utilisateur : utilisateur // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,nom: freezed == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String?,prenom: freezed == prenom ? _self.prenom : prenom // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Profil].
extension ProfilPatterns on Profil {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Profil value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Profil() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Profil value)  $default,){
final _that = this;
switch (_that) {
case _Profil():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Profil value)?  $default,){
final _that = this;
switch (_that) {
case _Profil() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'username')  String utilisateur,  String role,  String? nom,  String? prenom)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Profil() when $default != null:
return $default(_that.utilisateur,_that.role,_that.nom,_that.prenom);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'username')  String utilisateur,  String role,  String? nom,  String? prenom)  $default,) {final _that = this;
switch (_that) {
case _Profil():
return $default(_that.utilisateur,_that.role,_that.nom,_that.prenom);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'username')  String utilisateur,  String role,  String? nom,  String? prenom)?  $default,) {final _that = this;
switch (_that) {
case _Profil() when $default != null:
return $default(_that.utilisateur,_that.role,_that.nom,_that.prenom);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Profil extends Profil {
  const _Profil({@JsonKey(name: 'username') required this.utilisateur, this.role = 'employee', this.nom, this.prenom}): super._();
  factory _Profil.fromJson(Map<String, dynamic> json) => _$ProfilFromJson(json);

@override@JsonKey(name: 'username') final  String utilisateur;
@override@JsonKey() final  String role;
@override final  String? nom;
@override final  String? prenom;

/// Create a copy of Profil
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfilCopyWith<_Profil> get copyWith => __$ProfilCopyWithImpl<_Profil>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfilToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Profil&&(identical(other.utilisateur, utilisateur) || other.utilisateur == utilisateur)&&(identical(other.role, role) || other.role == role)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.prenom, prenom) || other.prenom == prenom));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,utilisateur,role,nom,prenom);
}

@override
String toString() {
    return 'Profil(utilisateur: $utilisateur, role: $role, nom: $nom, prenom: $prenom)';
}


}

/// @nodoc
abstract mixin class _$ProfilCopyWith<$Res> implements $ProfilCopyWith<$Res> {
  factory _$ProfilCopyWith(_Profil value, $Res Function(_Profil) _then) = __$ProfilCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'username') String utilisateur, String role, String? nom, String? prenom
});




}
/// @nodoc
class __$ProfilCopyWithImpl<$Res>
    implements _$ProfilCopyWith<$Res> {
  __$ProfilCopyWithImpl(this._self, this._then);

  final _Profil _self;
  final $Res Function(_Profil) _then;

/// Create a copy of Profil
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? utilisateur = null,Object? role = null,Object? nom = freezed,Object? prenom = freezed,}) {
  return _then(_Profil(
utilisateur: null == utilisateur ? _self.utilisateur : utilisateur // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,nom: freezed == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String?,prenom: freezed == prenom ? _self.prenom : prenom // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Session {

 String get jeton; Profil get profil;
/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionCopyWith<Session> get copyWith => _$SessionCopyWithImpl<Session>(this as Session, _$identity);

  /// Serializes this Session to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Session;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Session&&(identical(other.jeton, _this.jeton) || other.jeton == _this.jeton)&&(identical(other.profil, _this.profil) || other.profil == _this.profil));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Session;
  return Object.hash(runtimeType,_this.jeton,_this.profil);
}

@override
String toString() {
  final _this = this as Session;
  return 'Session(jeton: ${_this.jeton}, profil: ${_this.profil})';
}


}

/// @nodoc
abstract mixin class $SessionCopyWith<$Res>  {
  factory $SessionCopyWith(Session value, $Res Function(Session) _then) = _$SessionCopyWithImpl;
@useResult
$Res call({
 String jeton, Profil profil
});


$ProfilCopyWith<$Res> get profil;

}
/// @nodoc
class _$SessionCopyWithImpl<$Res>
    implements $SessionCopyWith<$Res> {
  _$SessionCopyWithImpl(this._self, this._then);

  final Session _self;
  final $Res Function(Session) _then;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jeton = null,Object? profil = null,}) {
  return _then(Session(
jeton: null == jeton ? _self.jeton : jeton // ignore: cast_nullable_to_non_nullable
as String,profil: null == profil ? _self.profil : profil // ignore: cast_nullable_to_non_nullable
as Profil,
  ));
}
/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfilCopyWith<$Res> get profil {
  
  return $ProfilCopyWith<$Res>(_self.profil, (value) {
    return _then(_self.copyWith(profil: value));
  });
}
}


/// Adds pattern-matching-related methods to [Session].
extension SessionPatterns on Session {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Session value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Session() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Session value)  $default,){
final _that = this;
switch (_that) {
case _Session():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Session value)?  $default,){
final _that = this;
switch (_that) {
case _Session() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String jeton,  Profil profil)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Session() when $default != null:
return $default(_that.jeton,_that.profil);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String jeton,  Profil profil)  $default,) {final _that = this;
switch (_that) {
case _Session():
return $default(_that.jeton,_that.profil);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String jeton,  Profil profil)?  $default,) {final _that = this;
switch (_that) {
case _Session() when $default != null:
return $default(_that.jeton,_that.profil);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Session implements Session {
  const _Session({required this.jeton, required this.profil});
  factory _Session.fromJson(Map<String, dynamic> json) => _$SessionFromJson(json);

@override final  String jeton;
@override final  Profil profil;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionCopyWith<_Session> get copyWith => __$SessionCopyWithImpl<_Session>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Session&&(identical(other.jeton, jeton) || other.jeton == jeton)&&(identical(other.profil, profil) || other.profil == profil));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,jeton,profil);
}

@override
String toString() {
    return 'Session(jeton: $jeton, profil: $profil)';
}


}

/// @nodoc
abstract mixin class _$SessionCopyWith<$Res> implements $SessionCopyWith<$Res> {
  factory _$SessionCopyWith(_Session value, $Res Function(_Session) _then) = __$SessionCopyWithImpl;
@override @useResult
$Res call({
 String jeton, Profil profil
});


@override $ProfilCopyWith<$Res> get profil;

}
/// @nodoc
class __$SessionCopyWithImpl<$Res>
    implements _$SessionCopyWith<$Res> {
  __$SessionCopyWithImpl(this._self, this._then);

  final _Session _self;
  final $Res Function(_Session) _then;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jeton = null,Object? profil = null,}) {
  return _then(_Session(
jeton: null == jeton ? _self.jeton : jeton // ignore: cast_nullable_to_non_nullable
as String,profil: null == profil ? _self.profil : profil // ignore: cast_nullable_to_non_nullable
as Profil,
  ));
}

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfilCopyWith<$Res> get profil {
  
  return $ProfilCopyWith<$Res>(_self.profil, (value) {
    return _then(_self.copyWith(profil: value));
  });
}
}

// dart format on
