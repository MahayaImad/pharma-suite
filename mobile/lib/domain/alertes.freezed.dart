// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alertes.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ActionAlerte {

@JsonKey(unknownEnumValue: SorteAction.aucune) SorteAction get sorte; String get libelle; String? get route;
/// Create a copy of ActionAlerte
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActionAlerteCopyWith<ActionAlerte> get copyWith => _$ActionAlerteCopyWithImpl<ActionAlerte>(this as ActionAlerte, _$identity);

  /// Serializes this ActionAlerte to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ActionAlerte;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActionAlerte&&(identical(other.sorte, _this.sorte) || other.sorte == _this.sorte)&&(identical(other.libelle, _this.libelle) || other.libelle == _this.libelle)&&(identical(other.route, _this.route) || other.route == _this.route));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ActionAlerte;
  return Object.hash(runtimeType,_this.sorte,_this.libelle,_this.route);
}

@override
String toString() {
  final _this = this as ActionAlerte;
  return 'ActionAlerte(sorte: ${_this.sorte}, libelle: ${_this.libelle}, route: ${_this.route})';
}


}

/// @nodoc
abstract mixin class $ActionAlerteCopyWith<$Res>  {
  factory $ActionAlerteCopyWith(ActionAlerte value, $Res Function(ActionAlerte) _then) = _$ActionAlerteCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: SorteAction.aucune) SorteAction sorte, String libelle, String? route
});




}
/// @nodoc
class _$ActionAlerteCopyWithImpl<$Res>
    implements $ActionAlerteCopyWith<$Res> {
  _$ActionAlerteCopyWithImpl(this._self, this._then);

  final ActionAlerte _self;
  final $Res Function(ActionAlerte) _then;

/// Create a copy of ActionAlerte
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sorte = null,Object? libelle = null,Object? route = freezed,}) {
  return _then(ActionAlerte(
sorte: null == sorte ? _self.sorte : sorte // ignore: cast_nullable_to_non_nullable
as SorteAction,libelle: null == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String,route: freezed == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ActionAlerte].
extension ActionAlertePatterns on ActionAlerte {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActionAlerte value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActionAlerte() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActionAlerte value)  $default,){
final _that = this;
switch (_that) {
case _ActionAlerte():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActionAlerte value)?  $default,){
final _that = this;
switch (_that) {
case _ActionAlerte() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: SorteAction.aucune)  SorteAction sorte,  String libelle,  String? route)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActionAlerte() when $default != null:
return $default(_that.sorte,_that.libelle,_that.route);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: SorteAction.aucune)  SorteAction sorte,  String libelle,  String? route)  $default,) {final _that = this;
switch (_that) {
case _ActionAlerte():
return $default(_that.sorte,_that.libelle,_that.route);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: SorteAction.aucune)  SorteAction sorte,  String libelle,  String? route)?  $default,) {final _that = this;
switch (_that) {
case _ActionAlerte() when $default != null:
return $default(_that.sorte,_that.libelle,_that.route);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActionAlerte implements ActionAlerte {
  const _ActionAlerte({@JsonKey(unknownEnumValue: SorteAction.aucune) this.sorte = SorteAction.aucune, this.libelle = '', this.route});
  factory _ActionAlerte.fromJson(Map<String, dynamic> json) => _$ActionAlerteFromJson(json);

@override@JsonKey(unknownEnumValue: SorteAction.aucune) final  SorteAction sorte;
@override@JsonKey() final  String libelle;
@override final  String? route;

/// Create a copy of ActionAlerte
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActionAlerteCopyWith<_ActionAlerte> get copyWith => __$ActionAlerteCopyWithImpl<_ActionAlerte>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActionAlerteToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActionAlerte&&(identical(other.sorte, sorte) || other.sorte == sorte)&&(identical(other.libelle, libelle) || other.libelle == libelle)&&(identical(other.route, route) || other.route == route));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,sorte,libelle,route);
}

@override
String toString() {
    return 'ActionAlerte(sorte: $sorte, libelle: $libelle, route: $route)';
}


}

/// @nodoc
abstract mixin class _$ActionAlerteCopyWith<$Res> implements $ActionAlerteCopyWith<$Res> {
  factory _$ActionAlerteCopyWith(_ActionAlerte value, $Res Function(_ActionAlerte) _then) = __$ActionAlerteCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: SorteAction.aucune) SorteAction sorte, String libelle, String? route
});




}
/// @nodoc
class __$ActionAlerteCopyWithImpl<$Res>
    implements _$ActionAlerteCopyWith<$Res> {
  __$ActionAlerteCopyWithImpl(this._self, this._then);

  final _ActionAlerte _self;
  final $Res Function(_ActionAlerte) _then;

/// Create a copy of ActionAlerte
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sorte = null,Object? libelle = null,Object? route = freezed,}) {
  return _then(_ActionAlerte(
sorte: null == sorte ? _self.sorte : sorte // ignore: cast_nullable_to_non_nullable
as SorteAction,libelle: null == libelle ? _self.libelle : libelle // ignore: cast_nullable_to_non_nullable
as String,route: freezed == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Alerte {

 String get id; TypeAlerte get type; NiveauAlerte get niveau;/// rupture, livraison, peremption, seuil, tension, confirmer, surstock, synchro.
 String get icone;/// Produit ou grossiste concerné, tel qu'EASYPHARM l'écrit.
 String? get sujet; String get titre; String get detail;@JsonKey(name: 'id_nom') int? get idNom; ActionAlerte get action;
/// Create a copy of Alerte
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlerteCopyWith<Alerte> get copyWith => _$AlerteCopyWithImpl<Alerte>(this as Alerte, _$identity);

  /// Serializes this Alerte to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Alerte;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Alerte&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.niveau, _this.niveau) || other.niveau == _this.niveau)&&(identical(other.icone, _this.icone) || other.icone == _this.icone)&&(identical(other.sujet, _this.sujet) || other.sujet == _this.sujet)&&(identical(other.titre, _this.titre) || other.titre == _this.titre)&&(identical(other.detail, _this.detail) || other.detail == _this.detail)&&(identical(other.idNom, _this.idNom) || other.idNom == _this.idNom)&&(identical(other.action, _this.action) || other.action == _this.action));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Alerte;
  return Object.hash(runtimeType,_this.id,_this.type,_this.niveau,_this.icone,_this.sujet,_this.titre,_this.detail,_this.idNom,_this.action);
}

@override
String toString() {
  final _this = this as Alerte;
  return 'Alerte(id: ${_this.id}, type: ${_this.type}, niveau: ${_this.niveau}, icone: ${_this.icone}, sujet: ${_this.sujet}, titre: ${_this.titre}, detail: ${_this.detail}, idNom: ${_this.idNom}, action: ${_this.action})';
}


}

/// @nodoc
abstract mixin class $AlerteCopyWith<$Res>  {
  factory $AlerteCopyWith(Alerte value, $Res Function(Alerte) _then) = _$AlerteCopyWithImpl;
@useResult
$Res call({
 String id, TypeAlerte type, NiveauAlerte niveau, String icone, String? sujet, String titre, String detail,@JsonKey(name: 'id_nom') int? idNom, ActionAlerte action
});


$ActionAlerteCopyWith<$Res> get action;

}
/// @nodoc
class _$AlerteCopyWithImpl<$Res>
    implements $AlerteCopyWith<$Res> {
  _$AlerteCopyWithImpl(this._self, this._then);

  final Alerte _self;
  final $Res Function(Alerte) _then;

/// Create a copy of Alerte
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? niveau = null,Object? icone = null,Object? sujet = freezed,Object? titre = null,Object? detail = null,Object? idNom = freezed,Object? action = null,}) {
  return _then(Alerte(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeAlerte,niveau: null == niveau ? _self.niveau : niveau // ignore: cast_nullable_to_non_nullable
as NiveauAlerte,icone: null == icone ? _self.icone : icone // ignore: cast_nullable_to_non_nullable
as String,sujet: freezed == sujet ? _self.sujet : sujet // ignore: cast_nullable_to_non_nullable
as String?,titre: null == titre ? _self.titre : titre // ignore: cast_nullable_to_non_nullable
as String,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,idNom: freezed == idNom ? _self.idNom : idNom // ignore: cast_nullable_to_non_nullable
as int?,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as ActionAlerte,
  ));
}
/// Create a copy of Alerte
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActionAlerteCopyWith<$Res> get action {
  
  return $ActionAlerteCopyWith<$Res>(_self.action, (value) {
    return _then(_self.copyWith(action: value));
  });
}
}


/// Adds pattern-matching-related methods to [Alerte].
extension AlertePatterns on Alerte {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Alerte value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Alerte() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Alerte value)  $default,){
final _that = this;
switch (_that) {
case _Alerte():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Alerte value)?  $default,){
final _that = this;
switch (_that) {
case _Alerte() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  TypeAlerte type,  NiveauAlerte niveau,  String icone,  String? sujet,  String titre,  String detail, @JsonKey(name: 'id_nom')  int? idNom,  ActionAlerte action)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Alerte() when $default != null:
return $default(_that.id,_that.type,_that.niveau,_that.icone,_that.sujet,_that.titre,_that.detail,_that.idNom,_that.action);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  TypeAlerte type,  NiveauAlerte niveau,  String icone,  String? sujet,  String titre,  String detail, @JsonKey(name: 'id_nom')  int? idNom,  ActionAlerte action)  $default,) {final _that = this;
switch (_that) {
case _Alerte():
return $default(_that.id,_that.type,_that.niveau,_that.icone,_that.sujet,_that.titre,_that.detail,_that.idNom,_that.action);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  TypeAlerte type,  NiveauAlerte niveau,  String icone,  String? sujet,  String titre,  String detail, @JsonKey(name: 'id_nom')  int? idNom,  ActionAlerte action)?  $default,) {final _that = this;
switch (_that) {
case _Alerte() when $default != null:
return $default(_that.id,_that.type,_that.niveau,_that.icone,_that.sujet,_that.titre,_that.detail,_that.idNom,_that.action);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Alerte extends Alerte {
  const _Alerte({required this.id, this.type = TypeAlerte.stock, this.niveau = NiveauAlerte.surveiller, this.icone = '', this.sujet, this.titre = '', this.detail = '', @JsonKey(name: 'id_nom') this.idNom, this.action = const ActionAlerte()}): super._();
  factory _Alerte.fromJson(Map<String, dynamic> json) => _$AlerteFromJson(json);

@override final  String id;
@override@JsonKey() final  TypeAlerte type;
@override@JsonKey() final  NiveauAlerte niveau;
/// rupture, livraison, peremption, seuil, tension, confirmer, surstock, synchro.
@override@JsonKey() final  String icone;
/// Produit ou grossiste concerné, tel qu'EASYPHARM l'écrit.
@override final  String? sujet;
@override@JsonKey() final  String titre;
@override@JsonKey() final  String detail;
@override@JsonKey(name: 'id_nom') final  int? idNom;
@override@JsonKey() final  ActionAlerte action;

/// Create a copy of Alerte
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AlerteCopyWith<_Alerte> get copyWith => __$AlerteCopyWithImpl<_Alerte>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AlerteToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Alerte&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.niveau, niveau) || other.niveau == niveau)&&(identical(other.icone, icone) || other.icone == icone)&&(identical(other.sujet, sujet) || other.sujet == sujet)&&(identical(other.titre, titre) || other.titre == titre)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.idNom, idNom) || other.idNom == idNom)&&(identical(other.action, action) || other.action == action));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,type,niveau,icone,sujet,titre,detail,idNom,action);
}

@override
String toString() {
    return 'Alerte(id: $id, type: $type, niveau: $niveau, icone: $icone, sujet: $sujet, titre: $titre, detail: $detail, idNom: $idNom, action: $action)';
}


}

/// @nodoc
abstract mixin class _$AlerteCopyWith<$Res> implements $AlerteCopyWith<$Res> {
  factory _$AlerteCopyWith(_Alerte value, $Res Function(_Alerte) _then) = __$AlerteCopyWithImpl;
@override @useResult
$Res call({
 String id, TypeAlerte type, NiveauAlerte niveau, String icone, String? sujet, String titre, String detail,@JsonKey(name: 'id_nom') int? idNom, ActionAlerte action
});


@override $ActionAlerteCopyWith<$Res> get action;

}
/// @nodoc
class __$AlerteCopyWithImpl<$Res>
    implements _$AlerteCopyWith<$Res> {
  __$AlerteCopyWithImpl(this._self, this._then);

  final _Alerte _self;
  final $Res Function(_Alerte) _then;

/// Create a copy of Alerte
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? niveau = null,Object? icone = null,Object? sujet = freezed,Object? titre = null,Object? detail = null,Object? idNom = freezed,Object? action = null,}) {
  return _then(_Alerte(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeAlerte,niveau: null == niveau ? _self.niveau : niveau // ignore: cast_nullable_to_non_nullable
as NiveauAlerte,icone: null == icone ? _self.icone : icone // ignore: cast_nullable_to_non_nullable
as String,sujet: freezed == sujet ? _self.sujet : sujet // ignore: cast_nullable_to_non_nullable
as String?,titre: null == titre ? _self.titre : titre // ignore: cast_nullable_to_non_nullable
as String,detail: null == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as String,idNom: freezed == idNom ? _self.idNom : idNom // ignore: cast_nullable_to_non_nullable
as int?,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as ActionAlerte,
  ));
}

/// Create a copy of Alerte
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ActionAlerteCopyWith<$Res> get action {
  
  return $ActionAlerteCopyWith<$Res>(_self.action, (value) {
    return _then(_self.copyWith(action: value));
  });
}
}


/// @nodoc
mixin _$BrefAlertes {

 int get ruptures;@JsonKey(name: 'ruptures_imminentes') int get rupturesImminentes;@JsonKey(name: 'valeur_a_risque') double get valeurARisque;@JsonKey(name: 'commandes_non_livrees') int get commandesNonLivrees;@JsonKey(name: 'budget_pct') int? get budgetPct;
/// Create a copy of BrefAlertes
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BrefAlertesCopyWith<BrefAlertes> get copyWith => _$BrefAlertesCopyWithImpl<BrefAlertes>(this as BrefAlertes, _$identity);

  /// Serializes this BrefAlertes to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BrefAlertes;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BrefAlertes&&(identical(other.ruptures, _this.ruptures) || other.ruptures == _this.ruptures)&&(identical(other.rupturesImminentes, _this.rupturesImminentes) || other.rupturesImminentes == _this.rupturesImminentes)&&(identical(other.valeurARisque, _this.valeurARisque) || other.valeurARisque == _this.valeurARisque)&&(identical(other.commandesNonLivrees, _this.commandesNonLivrees) || other.commandesNonLivrees == _this.commandesNonLivrees)&&(identical(other.budgetPct, _this.budgetPct) || other.budgetPct == _this.budgetPct));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BrefAlertes;
  return Object.hash(runtimeType,_this.ruptures,_this.rupturesImminentes,_this.valeurARisque,_this.commandesNonLivrees,_this.budgetPct);
}

@override
String toString() {
  final _this = this as BrefAlertes;
  return 'BrefAlertes(ruptures: ${_this.ruptures}, rupturesImminentes: ${_this.rupturesImminentes}, valeurARisque: ${_this.valeurARisque}, commandesNonLivrees: ${_this.commandesNonLivrees}, budgetPct: ${_this.budgetPct})';
}


}

/// @nodoc
abstract mixin class $BrefAlertesCopyWith<$Res>  {
  factory $BrefAlertesCopyWith(BrefAlertes value, $Res Function(BrefAlertes) _then) = _$BrefAlertesCopyWithImpl;
@useResult
$Res call({
 int ruptures,@JsonKey(name: 'ruptures_imminentes') int rupturesImminentes,@JsonKey(name: 'valeur_a_risque') double valeurARisque,@JsonKey(name: 'commandes_non_livrees') int commandesNonLivrees,@JsonKey(name: 'budget_pct') int? budgetPct
});




}
/// @nodoc
class _$BrefAlertesCopyWithImpl<$Res>
    implements $BrefAlertesCopyWith<$Res> {
  _$BrefAlertesCopyWithImpl(this._self, this._then);

  final BrefAlertes _self;
  final $Res Function(BrefAlertes) _then;

/// Create a copy of BrefAlertes
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ruptures = null,Object? rupturesImminentes = null,Object? valeurARisque = null,Object? commandesNonLivrees = null,Object? budgetPct = freezed,}) {
  return _then(BrefAlertes(
ruptures: null == ruptures ? _self.ruptures : ruptures // ignore: cast_nullable_to_non_nullable
as int,rupturesImminentes: null == rupturesImminentes ? _self.rupturesImminentes : rupturesImminentes // ignore: cast_nullable_to_non_nullable
as int,valeurARisque: null == valeurARisque ? _self.valeurARisque : valeurARisque // ignore: cast_nullable_to_non_nullable
as double,commandesNonLivrees: null == commandesNonLivrees ? _self.commandesNonLivrees : commandesNonLivrees // ignore: cast_nullable_to_non_nullable
as int,budgetPct: freezed == budgetPct ? _self.budgetPct : budgetPct // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [BrefAlertes].
extension BrefAlertesPatterns on BrefAlertes {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BrefAlertes value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BrefAlertes() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BrefAlertes value)  $default,){
final _that = this;
switch (_that) {
case _BrefAlertes():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BrefAlertes value)?  $default,){
final _that = this;
switch (_that) {
case _BrefAlertes() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int ruptures, @JsonKey(name: 'ruptures_imminentes')  int rupturesImminentes, @JsonKey(name: 'valeur_a_risque')  double valeurARisque, @JsonKey(name: 'commandes_non_livrees')  int commandesNonLivrees, @JsonKey(name: 'budget_pct')  int? budgetPct)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BrefAlertes() when $default != null:
return $default(_that.ruptures,_that.rupturesImminentes,_that.valeurARisque,_that.commandesNonLivrees,_that.budgetPct);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int ruptures, @JsonKey(name: 'ruptures_imminentes')  int rupturesImminentes, @JsonKey(name: 'valeur_a_risque')  double valeurARisque, @JsonKey(name: 'commandes_non_livrees')  int commandesNonLivrees, @JsonKey(name: 'budget_pct')  int? budgetPct)  $default,) {final _that = this;
switch (_that) {
case _BrefAlertes():
return $default(_that.ruptures,_that.rupturesImminentes,_that.valeurARisque,_that.commandesNonLivrees,_that.budgetPct);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int ruptures, @JsonKey(name: 'ruptures_imminentes')  int rupturesImminentes, @JsonKey(name: 'valeur_a_risque')  double valeurARisque, @JsonKey(name: 'commandes_non_livrees')  int commandesNonLivrees, @JsonKey(name: 'budget_pct')  int? budgetPct)?  $default,) {final _that = this;
switch (_that) {
case _BrefAlertes() when $default != null:
return $default(_that.ruptures,_that.rupturesImminentes,_that.valeurARisque,_that.commandesNonLivrees,_that.budgetPct);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BrefAlertes implements BrefAlertes {
  const _BrefAlertes({this.ruptures = 0, @JsonKey(name: 'ruptures_imminentes') this.rupturesImminentes = 0, @JsonKey(name: 'valeur_a_risque') this.valeurARisque = 0, @JsonKey(name: 'commandes_non_livrees') this.commandesNonLivrees = 0, @JsonKey(name: 'budget_pct') this.budgetPct});
  factory _BrefAlertes.fromJson(Map<String, dynamic> json) => _$BrefAlertesFromJson(json);

@override@JsonKey() final  int ruptures;
@override@JsonKey(name: 'ruptures_imminentes') final  int rupturesImminentes;
@override@JsonKey(name: 'valeur_a_risque') final  double valeurARisque;
@override@JsonKey(name: 'commandes_non_livrees') final  int commandesNonLivrees;
@override@JsonKey(name: 'budget_pct') final  int? budgetPct;

/// Create a copy of BrefAlertes
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BrefAlertesCopyWith<_BrefAlertes> get copyWith => __$BrefAlertesCopyWithImpl<_BrefAlertes>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BrefAlertesToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BrefAlertes&&(identical(other.ruptures, ruptures) || other.ruptures == ruptures)&&(identical(other.rupturesImminentes, rupturesImminentes) || other.rupturesImminentes == rupturesImminentes)&&(identical(other.valeurARisque, valeurARisque) || other.valeurARisque == valeurARisque)&&(identical(other.commandesNonLivrees, commandesNonLivrees) || other.commandesNonLivrees == commandesNonLivrees)&&(identical(other.budgetPct, budgetPct) || other.budgetPct == budgetPct));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,ruptures,rupturesImminentes,valeurARisque,commandesNonLivrees,budgetPct);
}

@override
String toString() {
    return 'BrefAlertes(ruptures: $ruptures, rupturesImminentes: $rupturesImminentes, valeurARisque: $valeurARisque, commandesNonLivrees: $commandesNonLivrees, budgetPct: $budgetPct)';
}


}

/// @nodoc
abstract mixin class _$BrefAlertesCopyWith<$Res> implements $BrefAlertesCopyWith<$Res> {
  factory _$BrefAlertesCopyWith(_BrefAlertes value, $Res Function(_BrefAlertes) _then) = __$BrefAlertesCopyWithImpl;
@override @useResult
$Res call({
 int ruptures,@JsonKey(name: 'ruptures_imminentes') int rupturesImminentes,@JsonKey(name: 'valeur_a_risque') double valeurARisque,@JsonKey(name: 'commandes_non_livrees') int commandesNonLivrees,@JsonKey(name: 'budget_pct') int? budgetPct
});




}
/// @nodoc
class __$BrefAlertesCopyWithImpl<$Res>
    implements _$BrefAlertesCopyWith<$Res> {
  __$BrefAlertesCopyWithImpl(this._self, this._then);

  final _BrefAlertes _self;
  final $Res Function(_BrefAlertes) _then;

/// Create a copy of BrefAlertes
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ruptures = null,Object? rupturesImminentes = null,Object? valeurARisque = null,Object? commandesNonLivrees = null,Object? budgetPct = freezed,}) {
  return _then(_BrefAlertes(
ruptures: null == ruptures ? _self.ruptures : ruptures // ignore: cast_nullable_to_non_nullable
as int,rupturesImminentes: null == rupturesImminentes ? _self.rupturesImminentes : rupturesImminentes // ignore: cast_nullable_to_non_nullable
as int,valeurARisque: null == valeurARisque ? _self.valeurARisque : valeurARisque // ignore: cast_nullable_to_non_nullable
as double,commandesNonLivrees: null == commandesNonLivrees ? _self.commandesNonLivrees : commandesNonLivrees // ignore: cast_nullable_to_non_nullable
as int,budgetPct: freezed == budgetPct ? _self.budgetPct : budgetPct // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$ListeAlertes {

 DateTime get jour;@JsonKey(name: 'donnees_du') DateTime? get donneesDu;@JsonKey(name: 'peut_decider') bool get peutDecider; List<Alerte> get alertes; BrefAlertes get bref;
/// Create a copy of ListeAlertes
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListeAlertesCopyWith<ListeAlertes> get copyWith => _$ListeAlertesCopyWithImpl<ListeAlertes>(this as ListeAlertes, _$identity);

  /// Serializes this ListeAlertes to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ListeAlertes;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListeAlertes&&(identical(other.jour, _this.jour) || other.jour == _this.jour)&&(identical(other.donneesDu, _this.donneesDu) || other.donneesDu == _this.donneesDu)&&(identical(other.peutDecider, _this.peutDecider) || other.peutDecider == _this.peutDecider)&&const DeepCollectionEquality().equals(other.alertes, _this.alertes)&&(identical(other.bref, _this.bref) || other.bref == _this.bref));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ListeAlertes;
  return Object.hash(runtimeType,_this.jour,_this.donneesDu,_this.peutDecider,const DeepCollectionEquality().hash(_this.alertes),_this.bref);
}

@override
String toString() {
  final _this = this as ListeAlertes;
  return 'ListeAlertes(jour: ${_this.jour}, donneesDu: ${_this.donneesDu}, peutDecider: ${_this.peutDecider}, alertes: ${_this.alertes}, bref: ${_this.bref})';
}


}

/// @nodoc
abstract mixin class $ListeAlertesCopyWith<$Res>  {
  factory $ListeAlertesCopyWith(ListeAlertes value, $Res Function(ListeAlertes) _then) = _$ListeAlertesCopyWithImpl;
@useResult
$Res call({
 DateTime jour,@JsonKey(name: 'donnees_du') DateTime? donneesDu,@JsonKey(name: 'peut_decider') bool peutDecider, List<Alerte> alertes, BrefAlertes bref
});


$BrefAlertesCopyWith<$Res> get bref;

}
/// @nodoc
class _$ListeAlertesCopyWithImpl<$Res>
    implements $ListeAlertesCopyWith<$Res> {
  _$ListeAlertesCopyWithImpl(this._self, this._then);

  final ListeAlertes _self;
  final $Res Function(ListeAlertes) _then;

/// Create a copy of ListeAlertes
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jour = null,Object? donneesDu = freezed,Object? peutDecider = null,Object? alertes = null,Object? bref = null,}) {
  return _then(ListeAlertes(
jour: null == jour ? _self.jour : jour // ignore: cast_nullable_to_non_nullable
as DateTime,donneesDu: freezed == donneesDu ? _self.donneesDu : donneesDu // ignore: cast_nullable_to_non_nullable
as DateTime?,peutDecider: null == peutDecider ? _self.peutDecider : peutDecider // ignore: cast_nullable_to_non_nullable
as bool,alertes: null == alertes ? _self.alertes : alertes // ignore: cast_nullable_to_non_nullable
as List<Alerte>,bref: null == bref ? _self.bref : bref // ignore: cast_nullable_to_non_nullable
as BrefAlertes,
  ));
}
/// Create a copy of ListeAlertes
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BrefAlertesCopyWith<$Res> get bref {
  
  return $BrefAlertesCopyWith<$Res>(_self.bref, (value) {
    return _then(_self.copyWith(bref: value));
  });
}
}


/// Adds pattern-matching-related methods to [ListeAlertes].
extension ListeAlertesPatterns on ListeAlertes {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ListeAlertes value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ListeAlertes() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ListeAlertes value)  $default,){
final _that = this;
switch (_that) {
case _ListeAlertes():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ListeAlertes value)?  $default,){
final _that = this;
switch (_that) {
case _ListeAlertes() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime jour, @JsonKey(name: 'donnees_du')  DateTime? donneesDu, @JsonKey(name: 'peut_decider')  bool peutDecider,  List<Alerte> alertes,  BrefAlertes bref)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ListeAlertes() when $default != null:
return $default(_that.jour,_that.donneesDu,_that.peutDecider,_that.alertes,_that.bref);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime jour, @JsonKey(name: 'donnees_du')  DateTime? donneesDu, @JsonKey(name: 'peut_decider')  bool peutDecider,  List<Alerte> alertes,  BrefAlertes bref)  $default,) {final _that = this;
switch (_that) {
case _ListeAlertes():
return $default(_that.jour,_that.donneesDu,_that.peutDecider,_that.alertes,_that.bref);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime jour, @JsonKey(name: 'donnees_du')  DateTime? donneesDu, @JsonKey(name: 'peut_decider')  bool peutDecider,  List<Alerte> alertes,  BrefAlertes bref)?  $default,) {final _that = this;
switch (_that) {
case _ListeAlertes() when $default != null:
return $default(_that.jour,_that.donneesDu,_that.peutDecider,_that.alertes,_that.bref);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ListeAlertes extends ListeAlertes {
  const _ListeAlertes({required this.jour, @JsonKey(name: 'donnees_du') this.donneesDu, @JsonKey(name: 'peut_decider') this.peutDecider = false,  List<Alerte> alertes = const <Alerte>[], this.bref = const BrefAlertes()}): _alertes = alertes,super._();
  factory _ListeAlertes.fromJson(Map<String, dynamic> json) => _$ListeAlertesFromJson(json);

@override final  DateTime jour;
@override@JsonKey(name: 'donnees_du') final  DateTime? donneesDu;
@override@JsonKey(name: 'peut_decider') final  bool peutDecider;
 final  List<Alerte> _alertes;
@override@JsonKey() List<Alerte> get alertes {
  if (_alertes is EqualUnmodifiableListView) return _alertes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_alertes);
}

@override@JsonKey() final  BrefAlertes bref;

/// Create a copy of ListeAlertes
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListeAlertesCopyWith<_ListeAlertes> get copyWith => __$ListeAlertesCopyWithImpl<_ListeAlertes>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ListeAlertesToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListeAlertes&&(identical(other.jour, jour) || other.jour == jour)&&(identical(other.donneesDu, donneesDu) || other.donneesDu == donneesDu)&&(identical(other.peutDecider, peutDecider) || other.peutDecider == peutDecider)&&const DeepCollectionEquality().equals(other.alertes, _alertes)&&(identical(other.bref, bref) || other.bref == bref));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,jour,donneesDu,peutDecider,const DeepCollectionEquality().hash(_alertes),bref);
}

@override
String toString() {
    return 'ListeAlertes(jour: $jour, donneesDu: $donneesDu, peutDecider: $peutDecider, alertes: $alertes, bref: $bref)';
}


}

/// @nodoc
abstract mixin class _$ListeAlertesCopyWith<$Res> implements $ListeAlertesCopyWith<$Res> {
  factory _$ListeAlertesCopyWith(_ListeAlertes value, $Res Function(_ListeAlertes) _then) = __$ListeAlertesCopyWithImpl;
@override @useResult
$Res call({
 DateTime jour,@JsonKey(name: 'donnees_du') DateTime? donneesDu,@JsonKey(name: 'peut_decider') bool peutDecider, List<Alerte> alertes, BrefAlertes bref
});


@override $BrefAlertesCopyWith<$Res> get bref;

}
/// @nodoc
class __$ListeAlertesCopyWithImpl<$Res>
    implements _$ListeAlertesCopyWith<$Res> {
  __$ListeAlertesCopyWithImpl(this._self, this._then);

  final _ListeAlertes _self;
  final $Res Function(_ListeAlertes) _then;

/// Create a copy of ListeAlertes
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jour = null,Object? donneesDu = freezed,Object? peutDecider = null,Object? alertes = null,Object? bref = null,}) {
  return _then(_ListeAlertes(
jour: null == jour ? _self.jour : jour // ignore: cast_nullable_to_non_nullable
as DateTime,donneesDu: freezed == donneesDu ? _self.donneesDu : donneesDu // ignore: cast_nullable_to_non_nullable
as DateTime?,peutDecider: null == peutDecider ? _self.peutDecider : peutDecider // ignore: cast_nullable_to_non_nullable
as bool,alertes: null == alertes ? _self._alertes : alertes // ignore: cast_nullable_to_non_nullable
as List<Alerte>,bref: null == bref ? _self.bref : bref // ignore: cast_nullable_to_non_nullable
as BrefAlertes,
  ));
}

/// Create a copy of ListeAlertes
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BrefAlertesCopyWith<$Res> get bref {
  
  return $BrefAlertesCopyWith<$Res>(_self.bref, (value) {
    return _then(_self.copyWith(bref: value));
  });
}
}

// dart format on
