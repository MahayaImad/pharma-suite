// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'commandes.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Raison {

 String get type; double get rythme;@JsonKey(name: 'jours_couverts') int get joursCouverts; double get prevu; double get securite; double get cible; double get stock;@JsonKey(name: 'en_cours') double get enCours;
/// Create a copy of Raison
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RaisonCopyWith<Raison> get copyWith => _$RaisonCopyWithImpl<Raison>(this as Raison, _$identity);

  /// Serializes this Raison to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Raison;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Raison&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.rythme, _this.rythme) || other.rythme == _this.rythme)&&(identical(other.joursCouverts, _this.joursCouverts) || other.joursCouverts == _this.joursCouverts)&&(identical(other.prevu, _this.prevu) || other.prevu == _this.prevu)&&(identical(other.securite, _this.securite) || other.securite == _this.securite)&&(identical(other.cible, _this.cible) || other.cible == _this.cible)&&(identical(other.stock, _this.stock) || other.stock == _this.stock)&&(identical(other.enCours, _this.enCours) || other.enCours == _this.enCours));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Raison;
  return Object.hash(runtimeType,_this.type,_this.rythme,_this.joursCouverts,_this.prevu,_this.securite,_this.cible,_this.stock,_this.enCours);
}

@override
String toString() {
  final _this = this as Raison;
  return 'Raison(type: ${_this.type}, rythme: ${_this.rythme}, joursCouverts: ${_this.joursCouverts}, prevu: ${_this.prevu}, securite: ${_this.securite}, cible: ${_this.cible}, stock: ${_this.stock}, enCours: ${_this.enCours})';
}


}

/// @nodoc
abstract mixin class $RaisonCopyWith<$Res>  {
  factory $RaisonCopyWith(Raison value, $Res Function(Raison) _then) = _$RaisonCopyWithImpl;
@useResult
$Res call({
 String type, double rythme,@JsonKey(name: 'jours_couverts') int joursCouverts, double prevu, double securite, double cible, double stock,@JsonKey(name: 'en_cours') double enCours
});




}
/// @nodoc
class _$RaisonCopyWithImpl<$Res>
    implements $RaisonCopyWith<$Res> {
  _$RaisonCopyWithImpl(this._self, this._then);

  final Raison _self;
  final $Res Function(Raison) _then;

/// Create a copy of Raison
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? rythme = null,Object? joursCouverts = null,Object? prevu = null,Object? securite = null,Object? cible = null,Object? stock = null,Object? enCours = null,}) {
  return _then(Raison(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,rythme: null == rythme ? _self.rythme : rythme // ignore: cast_nullable_to_non_nullable
as double,joursCouverts: null == joursCouverts ? _self.joursCouverts : joursCouverts // ignore: cast_nullable_to_non_nullable
as int,prevu: null == prevu ? _self.prevu : prevu // ignore: cast_nullable_to_non_nullable
as double,securite: null == securite ? _self.securite : securite // ignore: cast_nullable_to_non_nullable
as double,cible: null == cible ? _self.cible : cible // ignore: cast_nullable_to_non_nullable
as double,stock: null == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as double,enCours: null == enCours ? _self.enCours : enCours // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Raison].
extension RaisonPatterns on Raison {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Raison value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Raison() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Raison value)  $default,){
final _that = this;
switch (_that) {
case _Raison():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Raison value)?  $default,){
final _that = this;
switch (_that) {
case _Raison() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  double rythme, @JsonKey(name: 'jours_couverts')  int joursCouverts,  double prevu,  double securite,  double cible,  double stock, @JsonKey(name: 'en_cours')  double enCours)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Raison() when $default != null:
return $default(_that.type,_that.rythme,_that.joursCouverts,_that.prevu,_that.securite,_that.cible,_that.stock,_that.enCours);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  double rythme, @JsonKey(name: 'jours_couverts')  int joursCouverts,  double prevu,  double securite,  double cible,  double stock, @JsonKey(name: 'en_cours')  double enCours)  $default,) {final _that = this;
switch (_that) {
case _Raison():
return $default(_that.type,_that.rythme,_that.joursCouverts,_that.prevu,_that.securite,_that.cible,_that.stock,_that.enCours);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  double rythme, @JsonKey(name: 'jours_couverts')  int joursCouverts,  double prevu,  double securite,  double cible,  double stock, @JsonKey(name: 'en_cours')  double enCours)?  $default,) {final _that = this;
switch (_that) {
case _Raison() when $default != null:
return $default(_that.type,_that.rythme,_that.joursCouverts,_that.prevu,_that.securite,_that.cible,_that.stock,_that.enCours);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Raison implements Raison {
  const _Raison({this.type = '', this.rythme = 0, @JsonKey(name: 'jours_couverts') this.joursCouverts = 0, this.prevu = 0, this.securite = 0, this.cible = 0, this.stock = 0, @JsonKey(name: 'en_cours') this.enCours = 0});
  factory _Raison.fromJson(Map<String, dynamic> json) => _$RaisonFromJson(json);

@override@JsonKey() final  String type;
@override@JsonKey() final  double rythme;
@override@JsonKey(name: 'jours_couverts') final  int joursCouverts;
@override@JsonKey() final  double prevu;
@override@JsonKey() final  double securite;
@override@JsonKey() final  double cible;
@override@JsonKey() final  double stock;
@override@JsonKey(name: 'en_cours') final  double enCours;

/// Create a copy of Raison
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RaisonCopyWith<_Raison> get copyWith => __$RaisonCopyWithImpl<_Raison>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RaisonToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Raison&&(identical(other.type, type) || other.type == type)&&(identical(other.rythme, rythme) || other.rythme == rythme)&&(identical(other.joursCouverts, joursCouverts) || other.joursCouverts == joursCouverts)&&(identical(other.prevu, prevu) || other.prevu == prevu)&&(identical(other.securite, securite) || other.securite == securite)&&(identical(other.cible, cible) || other.cible == cible)&&(identical(other.stock, stock) || other.stock == stock)&&(identical(other.enCours, enCours) || other.enCours == enCours));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,type,rythme,joursCouverts,prevu,securite,cible,stock,enCours);
}

@override
String toString() {
    return 'Raison(type: $type, rythme: $rythme, joursCouverts: $joursCouverts, prevu: $prevu, securite: $securite, cible: $cible, stock: $stock, enCours: $enCours)';
}


}

/// @nodoc
abstract mixin class _$RaisonCopyWith<$Res> implements $RaisonCopyWith<$Res> {
  factory _$RaisonCopyWith(_Raison value, $Res Function(_Raison) _then) = __$RaisonCopyWithImpl;
@override @useResult
$Res call({
 String type, double rythme,@JsonKey(name: 'jours_couverts') int joursCouverts, double prevu, double securite, double cible, double stock,@JsonKey(name: 'en_cours') double enCours
});




}
/// @nodoc
class __$RaisonCopyWithImpl<$Res>
    implements _$RaisonCopyWith<$Res> {
  __$RaisonCopyWithImpl(this._self, this._then);

  final _Raison _self;
  final $Res Function(_Raison) _then;

/// Create a copy of Raison
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? rythme = null,Object? joursCouverts = null,Object? prevu = null,Object? securite = null,Object? cible = null,Object? stock = null,Object? enCours = null,}) {
  return _then(_Raison(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,rythme: null == rythme ? _self.rythme : rythme // ignore: cast_nullable_to_non_nullable
as double,joursCouverts: null == joursCouverts ? _self.joursCouverts : joursCouverts // ignore: cast_nullable_to_non_nullable
as int,prevu: null == prevu ? _self.prevu : prevu // ignore: cast_nullable_to_non_nullable
as double,securite: null == securite ? _self.securite : securite // ignore: cast_nullable_to_non_nullable
as double,cible: null == cible ? _self.cible : cible // ignore: cast_nullable_to_non_nullable
as double,stock: null == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as double,enCours: null == enCours ? _self.enCours : enCours // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$LigneCommande {

@JsonKey(name: 'id_nom') int get idNom; String? get nom; String? get famille;@JsonKey(name: 'classe_abc') String? get classeAbc; int get stock; int get qte;@JsonKey(name: 'qte_proposee') int? get qteProposee;@JsonKey(name: 'prix_achat') double get prixAchat; double get montant; Raison? get raison; String? get fournisseur;
/// Create a copy of LigneCommande
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LigneCommandeCopyWith<LigneCommande> get copyWith => _$LigneCommandeCopyWithImpl<LigneCommande>(this as LigneCommande, _$identity);

  /// Serializes this LigneCommande to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as LigneCommande;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LigneCommande&&(identical(other.idNom, _this.idNom) || other.idNom == _this.idNom)&&(identical(other.nom, _this.nom) || other.nom == _this.nom)&&(identical(other.famille, _this.famille) || other.famille == _this.famille)&&(identical(other.classeAbc, _this.classeAbc) || other.classeAbc == _this.classeAbc)&&(identical(other.stock, _this.stock) || other.stock == _this.stock)&&(identical(other.qte, _this.qte) || other.qte == _this.qte)&&(identical(other.qteProposee, _this.qteProposee) || other.qteProposee == _this.qteProposee)&&(identical(other.prixAchat, _this.prixAchat) || other.prixAchat == _this.prixAchat)&&(identical(other.montant, _this.montant) || other.montant == _this.montant)&&(identical(other.raison, _this.raison) || other.raison == _this.raison)&&(identical(other.fournisseur, _this.fournisseur) || other.fournisseur == _this.fournisseur));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as LigneCommande;
  return Object.hash(runtimeType,_this.idNom,_this.nom,_this.famille,_this.classeAbc,_this.stock,_this.qte,_this.qteProposee,_this.prixAchat,_this.montant,_this.raison,_this.fournisseur);
}

@override
String toString() {
  final _this = this as LigneCommande;
  return 'LigneCommande(idNom: ${_this.idNom}, nom: ${_this.nom}, famille: ${_this.famille}, classeAbc: ${_this.classeAbc}, stock: ${_this.stock}, qte: ${_this.qte}, qteProposee: ${_this.qteProposee}, prixAchat: ${_this.prixAchat}, montant: ${_this.montant}, raison: ${_this.raison}, fournisseur: ${_this.fournisseur})';
}


}

/// @nodoc
abstract mixin class $LigneCommandeCopyWith<$Res>  {
  factory $LigneCommandeCopyWith(LigneCommande value, $Res Function(LigneCommande) _then) = _$LigneCommandeCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id_nom') int idNom, String? nom, String? famille,@JsonKey(name: 'classe_abc') String? classeAbc, int stock, int qte,@JsonKey(name: 'qte_proposee') int? qteProposee,@JsonKey(name: 'prix_achat') double prixAchat, double montant, Raison? raison, String? fournisseur
});


$RaisonCopyWith<$Res>? get raison;

}
/// @nodoc
class _$LigneCommandeCopyWithImpl<$Res>
    implements $LigneCommandeCopyWith<$Res> {
  _$LigneCommandeCopyWithImpl(this._self, this._then);

  final LigneCommande _self;
  final $Res Function(LigneCommande) _then;

/// Create a copy of LigneCommande
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? idNom = null,Object? nom = freezed,Object? famille = freezed,Object? classeAbc = freezed,Object? stock = null,Object? qte = null,Object? qteProposee = freezed,Object? prixAchat = null,Object? montant = null,Object? raison = freezed,Object? fournisseur = freezed,}) {
  return _then(LigneCommande(
idNom: null == idNom ? _self.idNom : idNom // ignore: cast_nullable_to_non_nullable
as int,nom: freezed == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String?,famille: freezed == famille ? _self.famille : famille // ignore: cast_nullable_to_non_nullable
as String?,classeAbc: freezed == classeAbc ? _self.classeAbc : classeAbc // ignore: cast_nullable_to_non_nullable
as String?,stock: null == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as int,qte: null == qte ? _self.qte : qte // ignore: cast_nullable_to_non_nullable
as int,qteProposee: freezed == qteProposee ? _self.qteProposee : qteProposee // ignore: cast_nullable_to_non_nullable
as int?,prixAchat: null == prixAchat ? _self.prixAchat : prixAchat // ignore: cast_nullable_to_non_nullable
as double,montant: null == montant ? _self.montant : montant // ignore: cast_nullable_to_non_nullable
as double,raison: freezed == raison ? _self.raison : raison // ignore: cast_nullable_to_non_nullable
as Raison?,fournisseur: freezed == fournisseur ? _self.fournisseur : fournisseur // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of LigneCommande
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RaisonCopyWith<$Res>? get raison {
    if (_self.raison == null) {
    return null;
  }

  return $RaisonCopyWith<$Res>(_self.raison!, (value) {
    return _then(_self.copyWith(raison: value));
  });
}
}


/// Adds pattern-matching-related methods to [LigneCommande].
extension LigneCommandePatterns on LigneCommande {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LigneCommande value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LigneCommande() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LigneCommande value)  $default,){
final _that = this;
switch (_that) {
case _LigneCommande():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LigneCommande value)?  $default,){
final _that = this;
switch (_that) {
case _LigneCommande() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id_nom')  int idNom,  String? nom,  String? famille, @JsonKey(name: 'classe_abc')  String? classeAbc,  int stock,  int qte, @JsonKey(name: 'qte_proposee')  int? qteProposee, @JsonKey(name: 'prix_achat')  double prixAchat,  double montant,  Raison? raison,  String? fournisseur)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LigneCommande() when $default != null:
return $default(_that.idNom,_that.nom,_that.famille,_that.classeAbc,_that.stock,_that.qte,_that.qteProposee,_that.prixAchat,_that.montant,_that.raison,_that.fournisseur);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id_nom')  int idNom,  String? nom,  String? famille, @JsonKey(name: 'classe_abc')  String? classeAbc,  int stock,  int qte, @JsonKey(name: 'qte_proposee')  int? qteProposee, @JsonKey(name: 'prix_achat')  double prixAchat,  double montant,  Raison? raison,  String? fournisseur)  $default,) {final _that = this;
switch (_that) {
case _LigneCommande():
return $default(_that.idNom,_that.nom,_that.famille,_that.classeAbc,_that.stock,_that.qte,_that.qteProposee,_that.prixAchat,_that.montant,_that.raison,_that.fournisseur);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id_nom')  int idNom,  String? nom,  String? famille, @JsonKey(name: 'classe_abc')  String? classeAbc,  int stock,  int qte, @JsonKey(name: 'qte_proposee')  int? qteProposee, @JsonKey(name: 'prix_achat')  double prixAchat,  double montant,  Raison? raison,  String? fournisseur)?  $default,) {final _that = this;
switch (_that) {
case _LigneCommande() when $default != null:
return $default(_that.idNom,_that.nom,_that.famille,_that.classeAbc,_that.stock,_that.qte,_that.qteProposee,_that.prixAchat,_that.montant,_that.raison,_that.fournisseur);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LigneCommande extends LigneCommande {
  const _LigneCommande({@JsonKey(name: 'id_nom') required this.idNom, this.nom, this.famille, @JsonKey(name: 'classe_abc') this.classeAbc, this.stock = 0, required this.qte, @JsonKey(name: 'qte_proposee') this.qteProposee, @JsonKey(name: 'prix_achat') this.prixAchat = 0, this.montant = 0, this.raison, this.fournisseur}): super._();
  factory _LigneCommande.fromJson(Map<String, dynamic> json) => _$LigneCommandeFromJson(json);

@override@JsonKey(name: 'id_nom') final  int idNom;
@override final  String? nom;
@override final  String? famille;
@override@JsonKey(name: 'classe_abc') final  String? classeAbc;
@override@JsonKey() final  int stock;
@override final  int qte;
@override@JsonKey(name: 'qte_proposee') final  int? qteProposee;
@override@JsonKey(name: 'prix_achat') final  double prixAchat;
@override@JsonKey() final  double montant;
@override final  Raison? raison;
@override final  String? fournisseur;

/// Create a copy of LigneCommande
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LigneCommandeCopyWith<_LigneCommande> get copyWith => __$LigneCommandeCopyWithImpl<_LigneCommande>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LigneCommandeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LigneCommande&&(identical(other.idNom, idNom) || other.idNom == idNom)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.famille, famille) || other.famille == famille)&&(identical(other.classeAbc, classeAbc) || other.classeAbc == classeAbc)&&(identical(other.stock, stock) || other.stock == stock)&&(identical(other.qte, qte) || other.qte == qte)&&(identical(other.qteProposee, qteProposee) || other.qteProposee == qteProposee)&&(identical(other.prixAchat, prixAchat) || other.prixAchat == prixAchat)&&(identical(other.montant, montant) || other.montant == montant)&&(identical(other.raison, raison) || other.raison == raison)&&(identical(other.fournisseur, fournisseur) || other.fournisseur == fournisseur));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,idNom,nom,famille,classeAbc,stock,qte,qteProposee,prixAchat,montant,raison,fournisseur);
}

@override
String toString() {
    return 'LigneCommande(idNom: $idNom, nom: $nom, famille: $famille, classeAbc: $classeAbc, stock: $stock, qte: $qte, qteProposee: $qteProposee, prixAchat: $prixAchat, montant: $montant, raison: $raison, fournisseur: $fournisseur)';
}


}

/// @nodoc
abstract mixin class _$LigneCommandeCopyWith<$Res> implements $LigneCommandeCopyWith<$Res> {
  factory _$LigneCommandeCopyWith(_LigneCommande value, $Res Function(_LigneCommande) _then) = __$LigneCommandeCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id_nom') int idNom, String? nom, String? famille,@JsonKey(name: 'classe_abc') String? classeAbc, int stock, int qte,@JsonKey(name: 'qte_proposee') int? qteProposee,@JsonKey(name: 'prix_achat') double prixAchat, double montant, Raison? raison, String? fournisseur
});


@override $RaisonCopyWith<$Res>? get raison;

}
/// @nodoc
class __$LigneCommandeCopyWithImpl<$Res>
    implements _$LigneCommandeCopyWith<$Res> {
  __$LigneCommandeCopyWithImpl(this._self, this._then);

  final _LigneCommande _self;
  final $Res Function(_LigneCommande) _then;

/// Create a copy of LigneCommande
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? idNom = null,Object? nom = freezed,Object? famille = freezed,Object? classeAbc = freezed,Object? stock = null,Object? qte = null,Object? qteProposee = freezed,Object? prixAchat = null,Object? montant = null,Object? raison = freezed,Object? fournisseur = freezed,}) {
  return _then(_LigneCommande(
idNom: null == idNom ? _self.idNom : idNom // ignore: cast_nullable_to_non_nullable
as int,nom: freezed == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String?,famille: freezed == famille ? _self.famille : famille // ignore: cast_nullable_to_non_nullable
as String?,classeAbc: freezed == classeAbc ? _self.classeAbc : classeAbc // ignore: cast_nullable_to_non_nullable
as String?,stock: null == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as int,qte: null == qte ? _self.qte : qte // ignore: cast_nullable_to_non_nullable
as int,qteProposee: freezed == qteProposee ? _self.qteProposee : qteProposee // ignore: cast_nullable_to_non_nullable
as int?,prixAchat: null == prixAchat ? _self.prixAchat : prixAchat // ignore: cast_nullable_to_non_nullable
as double,montant: null == montant ? _self.montant : montant // ignore: cast_nullable_to_non_nullable
as double,raison: freezed == raison ? _self.raison : raison // ignore: cast_nullable_to_non_nullable
as Raison?,fournisseur: freezed == fournisseur ? _self.fournisseur : fournisseur // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of LigneCommande
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RaisonCopyWith<$Res>? get raison {
    if (_self.raison == null) {
    return null;
  }

  return $RaisonCopyWith<$Res>(_self.raison!, (value) {
    return _then(_self.copyWith(raison: value));
  });
}
}


/// @nodoc
mixin _$FournisseurPanier {

 int get id; String? get nom; TypeFournisseur get type; String? get whatsapp;
/// Create a copy of FournisseurPanier
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FournisseurPanierCopyWith<FournisseurPanier> get copyWith => _$FournisseurPanierCopyWithImpl<FournisseurPanier>(this as FournisseurPanier, _$identity);

  /// Serializes this FournisseurPanier to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FournisseurPanier;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FournisseurPanier&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nom, _this.nom) || other.nom == _this.nom)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.whatsapp, _this.whatsapp) || other.whatsapp == _this.whatsapp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FournisseurPanier;
  return Object.hash(runtimeType,_this.id,_this.nom,_this.type,_this.whatsapp);
}

@override
String toString() {
  final _this = this as FournisseurPanier;
  return 'FournisseurPanier(id: ${_this.id}, nom: ${_this.nom}, type: ${_this.type}, whatsapp: ${_this.whatsapp})';
}


}

/// @nodoc
abstract mixin class $FournisseurPanierCopyWith<$Res>  {
  factory $FournisseurPanierCopyWith(FournisseurPanier value, $Res Function(FournisseurPanier) _then) = _$FournisseurPanierCopyWithImpl;
@useResult
$Res call({
 int id, String? nom, TypeFournisseur type, String? whatsapp
});




}
/// @nodoc
class _$FournisseurPanierCopyWithImpl<$Res>
    implements $FournisseurPanierCopyWith<$Res> {
  _$FournisseurPanierCopyWithImpl(this._self, this._then);

  final FournisseurPanier _self;
  final $Res Function(FournisseurPanier) _then;

/// Create a copy of FournisseurPanier
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nom = freezed,Object? type = null,Object? whatsapp = freezed,}) {
  return _then(FournisseurPanier(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nom: freezed == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeFournisseur,whatsapp: freezed == whatsapp ? _self.whatsapp : whatsapp // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FournisseurPanier].
extension FournisseurPanierPatterns on FournisseurPanier {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FournisseurPanier value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FournisseurPanier() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FournisseurPanier value)  $default,){
final _that = this;
switch (_that) {
case _FournisseurPanier():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FournisseurPanier value)?  $default,){
final _that = this;
switch (_that) {
case _FournisseurPanier() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? nom,  TypeFournisseur type,  String? whatsapp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FournisseurPanier() when $default != null:
return $default(_that.id,_that.nom,_that.type,_that.whatsapp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? nom,  TypeFournisseur type,  String? whatsapp)  $default,) {final _that = this;
switch (_that) {
case _FournisseurPanier():
return $default(_that.id,_that.nom,_that.type,_that.whatsapp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? nom,  TypeFournisseur type,  String? whatsapp)?  $default,) {final _that = this;
switch (_that) {
case _FournisseurPanier() when $default != null:
return $default(_that.id,_that.nom,_that.type,_that.whatsapp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FournisseurPanier implements FournisseurPanier {
  const _FournisseurPanier({required this.id, this.nom, this.type = TypeFournisseur.pharma, this.whatsapp});
  factory _FournisseurPanier.fromJson(Map<String, dynamic> json) => _$FournisseurPanierFromJson(json);

@override final  int id;
@override final  String? nom;
@override@JsonKey() final  TypeFournisseur type;
@override final  String? whatsapp;

/// Create a copy of FournisseurPanier
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FournisseurPanierCopyWith<_FournisseurPanier> get copyWith => __$FournisseurPanierCopyWithImpl<_FournisseurPanier>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FournisseurPanierToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FournisseurPanier&&(identical(other.id, id) || other.id == id)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.type, type) || other.type == type)&&(identical(other.whatsapp, whatsapp) || other.whatsapp == whatsapp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,nom,type,whatsapp);
}

@override
String toString() {
    return 'FournisseurPanier(id: $id, nom: $nom, type: $type, whatsapp: $whatsapp)';
}


}

/// @nodoc
abstract mixin class _$FournisseurPanierCopyWith<$Res> implements $FournisseurPanierCopyWith<$Res> {
  factory _$FournisseurPanierCopyWith(_FournisseurPanier value, $Res Function(_FournisseurPanier) _then) = __$FournisseurPanierCopyWithImpl;
@override @useResult
$Res call({
 int id, String? nom, TypeFournisseur type, String? whatsapp
});




}
/// @nodoc
class __$FournisseurPanierCopyWithImpl<$Res>
    implements _$FournisseurPanierCopyWith<$Res> {
  __$FournisseurPanierCopyWithImpl(this._self, this._then);

  final _FournisseurPanier _self;
  final $Res Function(_FournisseurPanier) _then;

/// Create a copy of FournisseurPanier
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nom = freezed,Object? type = null,Object? whatsapp = freezed,}) {
  return _then(_FournisseurPanier(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nom: freezed == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeFournisseur,whatsapp: freezed == whatsapp ? _self.whatsapp : whatsapp // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CommandeEnregistree {

 int get id; DateTime get jour; StatutCommande get statut;@JsonKey(name: 'livraison_prevue') DateTime? get livraisonPrevue;@JsonKey(name: 'cree_par') String? get creePar;@JsonKey(name: 'valide_par') String? get validePar;
/// Create a copy of CommandeEnregistree
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommandeEnregistreeCopyWith<CommandeEnregistree> get copyWith => _$CommandeEnregistreeCopyWithImpl<CommandeEnregistree>(this as CommandeEnregistree, _$identity);

  /// Serializes this CommandeEnregistree to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CommandeEnregistree;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommandeEnregistree&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.jour, _this.jour) || other.jour == _this.jour)&&(identical(other.statut, _this.statut) || other.statut == _this.statut)&&(identical(other.livraisonPrevue, _this.livraisonPrevue) || other.livraisonPrevue == _this.livraisonPrevue)&&(identical(other.creePar, _this.creePar) || other.creePar == _this.creePar)&&(identical(other.validePar, _this.validePar) || other.validePar == _this.validePar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CommandeEnregistree;
  return Object.hash(runtimeType,_this.id,_this.jour,_this.statut,_this.livraisonPrevue,_this.creePar,_this.validePar);
}

@override
String toString() {
  final _this = this as CommandeEnregistree;
  return 'CommandeEnregistree(id: ${_this.id}, jour: ${_this.jour}, statut: ${_this.statut}, livraisonPrevue: ${_this.livraisonPrevue}, creePar: ${_this.creePar}, validePar: ${_this.validePar})';
}


}

/// @nodoc
abstract mixin class $CommandeEnregistreeCopyWith<$Res>  {
  factory $CommandeEnregistreeCopyWith(CommandeEnregistree value, $Res Function(CommandeEnregistree) _then) = _$CommandeEnregistreeCopyWithImpl;
@useResult
$Res call({
 int id, DateTime jour, StatutCommande statut,@JsonKey(name: 'livraison_prevue') DateTime? livraisonPrevue,@JsonKey(name: 'cree_par') String? creePar,@JsonKey(name: 'valide_par') String? validePar
});




}
/// @nodoc
class _$CommandeEnregistreeCopyWithImpl<$Res>
    implements $CommandeEnregistreeCopyWith<$Res> {
  _$CommandeEnregistreeCopyWithImpl(this._self, this._then);

  final CommandeEnregistree _self;
  final $Res Function(CommandeEnregistree) _then;

/// Create a copy of CommandeEnregistree
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? jour = null,Object? statut = null,Object? livraisonPrevue = freezed,Object? creePar = freezed,Object? validePar = freezed,}) {
  return _then(CommandeEnregistree(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,jour: null == jour ? _self.jour : jour // ignore: cast_nullable_to_non_nullable
as DateTime,statut: null == statut ? _self.statut : statut // ignore: cast_nullable_to_non_nullable
as StatutCommande,livraisonPrevue: freezed == livraisonPrevue ? _self.livraisonPrevue : livraisonPrevue // ignore: cast_nullable_to_non_nullable
as DateTime?,creePar: freezed == creePar ? _self.creePar : creePar // ignore: cast_nullable_to_non_nullable
as String?,validePar: freezed == validePar ? _self.validePar : validePar // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CommandeEnregistree].
extension CommandeEnregistreePatterns on CommandeEnregistree {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommandeEnregistree value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommandeEnregistree() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommandeEnregistree value)  $default,){
final _that = this;
switch (_that) {
case _CommandeEnregistree():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommandeEnregistree value)?  $default,){
final _that = this;
switch (_that) {
case _CommandeEnregistree() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  DateTime jour,  StatutCommande statut, @JsonKey(name: 'livraison_prevue')  DateTime? livraisonPrevue, @JsonKey(name: 'cree_par')  String? creePar, @JsonKey(name: 'valide_par')  String? validePar)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommandeEnregistree() when $default != null:
return $default(_that.id,_that.jour,_that.statut,_that.livraisonPrevue,_that.creePar,_that.validePar);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  DateTime jour,  StatutCommande statut, @JsonKey(name: 'livraison_prevue')  DateTime? livraisonPrevue, @JsonKey(name: 'cree_par')  String? creePar, @JsonKey(name: 'valide_par')  String? validePar)  $default,) {final _that = this;
switch (_that) {
case _CommandeEnregistree():
return $default(_that.id,_that.jour,_that.statut,_that.livraisonPrevue,_that.creePar,_that.validePar);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  DateTime jour,  StatutCommande statut, @JsonKey(name: 'livraison_prevue')  DateTime? livraisonPrevue, @JsonKey(name: 'cree_par')  String? creePar, @JsonKey(name: 'valide_par')  String? validePar)?  $default,) {final _that = this;
switch (_that) {
case _CommandeEnregistree() when $default != null:
return $default(_that.id,_that.jour,_that.statut,_that.livraisonPrevue,_that.creePar,_that.validePar);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommandeEnregistree implements CommandeEnregistree {
  const _CommandeEnregistree({required this.id, required this.jour, required this.statut, @JsonKey(name: 'livraison_prevue') this.livraisonPrevue, @JsonKey(name: 'cree_par') this.creePar, @JsonKey(name: 'valide_par') this.validePar});
  factory _CommandeEnregistree.fromJson(Map<String, dynamic> json) => _$CommandeEnregistreeFromJson(json);

@override final  int id;
@override final  DateTime jour;
@override final  StatutCommande statut;
@override@JsonKey(name: 'livraison_prevue') final  DateTime? livraisonPrevue;
@override@JsonKey(name: 'cree_par') final  String? creePar;
@override@JsonKey(name: 'valide_par') final  String? validePar;

/// Create a copy of CommandeEnregistree
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommandeEnregistreeCopyWith<_CommandeEnregistree> get copyWith => __$CommandeEnregistreeCopyWithImpl<_CommandeEnregistree>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommandeEnregistreeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommandeEnregistree&&(identical(other.id, id) || other.id == id)&&(identical(other.jour, jour) || other.jour == jour)&&(identical(other.statut, statut) || other.statut == statut)&&(identical(other.livraisonPrevue, livraisonPrevue) || other.livraisonPrevue == livraisonPrevue)&&(identical(other.creePar, creePar) || other.creePar == creePar)&&(identical(other.validePar, validePar) || other.validePar == validePar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,jour,statut,livraisonPrevue,creePar,validePar);
}

@override
String toString() {
    return 'CommandeEnregistree(id: $id, jour: $jour, statut: $statut, livraisonPrevue: $livraisonPrevue, creePar: $creePar, validePar: $validePar)';
}


}

/// @nodoc
abstract mixin class _$CommandeEnregistreeCopyWith<$Res> implements $CommandeEnregistreeCopyWith<$Res> {
  factory _$CommandeEnregistreeCopyWith(_CommandeEnregistree value, $Res Function(_CommandeEnregistree) _then) = __$CommandeEnregistreeCopyWithImpl;
@override @useResult
$Res call({
 int id, DateTime jour, StatutCommande statut,@JsonKey(name: 'livraison_prevue') DateTime? livraisonPrevue,@JsonKey(name: 'cree_par') String? creePar,@JsonKey(name: 'valide_par') String? validePar
});




}
/// @nodoc
class __$CommandeEnregistreeCopyWithImpl<$Res>
    implements _$CommandeEnregistreeCopyWith<$Res> {
  __$CommandeEnregistreeCopyWithImpl(this._self, this._then);

  final _CommandeEnregistree _self;
  final $Res Function(_CommandeEnregistree) _then;

/// Create a copy of CommandeEnregistree
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? jour = null,Object? statut = null,Object? livraisonPrevue = freezed,Object? creePar = freezed,Object? validePar = freezed,}) {
  return _then(_CommandeEnregistree(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,jour: null == jour ? _self.jour : jour // ignore: cast_nullable_to_non_nullable
as DateTime,statut: null == statut ? _self.statut : statut // ignore: cast_nullable_to_non_nullable
as StatutCommande,livraisonPrevue: freezed == livraisonPrevue ? _self.livraisonPrevue : livraisonPrevue // ignore: cast_nullable_to_non_nullable
as DateTime?,creePar: freezed == creePar ? _self.creePar : creePar // ignore: cast_nullable_to_non_nullable
as String?,validePar: freezed == validePar ? _self.validePar : validePar // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Panier {

 FournisseurPanier get fournisseur; CommandeEnregistree? get commande;@JsonKey(name: 'livraison_prevue') DateTime? get livraisonPrevue; List<LigneCommande> get lignes;
/// Create a copy of Panier
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PanierCopyWith<Panier> get copyWith => _$PanierCopyWithImpl<Panier>(this as Panier, _$identity);

  /// Serializes this Panier to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Panier;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Panier&&(identical(other.fournisseur, _this.fournisseur) || other.fournisseur == _this.fournisseur)&&(identical(other.commande, _this.commande) || other.commande == _this.commande)&&(identical(other.livraisonPrevue, _this.livraisonPrevue) || other.livraisonPrevue == _this.livraisonPrevue)&&const DeepCollectionEquality().equals(other.lignes, _this.lignes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Panier;
  return Object.hash(runtimeType,_this.fournisseur,_this.commande,_this.livraisonPrevue,const DeepCollectionEquality().hash(_this.lignes));
}

@override
String toString() {
  final _this = this as Panier;
  return 'Panier(fournisseur: ${_this.fournisseur}, commande: ${_this.commande}, livraisonPrevue: ${_this.livraisonPrevue}, lignes: ${_this.lignes})';
}


}

/// @nodoc
abstract mixin class $PanierCopyWith<$Res>  {
  factory $PanierCopyWith(Panier value, $Res Function(Panier) _then) = _$PanierCopyWithImpl;
@useResult
$Res call({
 FournisseurPanier fournisseur, CommandeEnregistree? commande,@JsonKey(name: 'livraison_prevue') DateTime? livraisonPrevue, List<LigneCommande> lignes
});


$FournisseurPanierCopyWith<$Res> get fournisseur;$CommandeEnregistreeCopyWith<$Res>? get commande;

}
/// @nodoc
class _$PanierCopyWithImpl<$Res>
    implements $PanierCopyWith<$Res> {
  _$PanierCopyWithImpl(this._self, this._then);

  final Panier _self;
  final $Res Function(Panier) _then;

/// Create a copy of Panier
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fournisseur = null,Object? commande = freezed,Object? livraisonPrevue = freezed,Object? lignes = null,}) {
  return _then(Panier(
fournisseur: null == fournisseur ? _self.fournisseur : fournisseur // ignore: cast_nullable_to_non_nullable
as FournisseurPanier,commande: freezed == commande ? _self.commande : commande // ignore: cast_nullable_to_non_nullable
as CommandeEnregistree?,livraisonPrevue: freezed == livraisonPrevue ? _self.livraisonPrevue : livraisonPrevue // ignore: cast_nullable_to_non_nullable
as DateTime?,lignes: null == lignes ? _self.lignes : lignes // ignore: cast_nullable_to_non_nullable
as List<LigneCommande>,
  ));
}
/// Create a copy of Panier
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FournisseurPanierCopyWith<$Res> get fournisseur {
  
  return $FournisseurPanierCopyWith<$Res>(_self.fournisseur, (value) {
    return _then(_self.copyWith(fournisseur: value));
  });
}/// Create a copy of Panier
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommandeEnregistreeCopyWith<$Res>? get commande {
    if (_self.commande == null) {
    return null;
  }

  return $CommandeEnregistreeCopyWith<$Res>(_self.commande!, (value) {
    return _then(_self.copyWith(commande: value));
  });
}
}


/// Adds pattern-matching-related methods to [Panier].
extension PanierPatterns on Panier {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Panier value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Panier() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Panier value)  $default,){
final _that = this;
switch (_that) {
case _Panier():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Panier value)?  $default,){
final _that = this;
switch (_that) {
case _Panier() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( FournisseurPanier fournisseur,  CommandeEnregistree? commande, @JsonKey(name: 'livraison_prevue')  DateTime? livraisonPrevue,  List<LigneCommande> lignes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Panier() when $default != null:
return $default(_that.fournisseur,_that.commande,_that.livraisonPrevue,_that.lignes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( FournisseurPanier fournisseur,  CommandeEnregistree? commande, @JsonKey(name: 'livraison_prevue')  DateTime? livraisonPrevue,  List<LigneCommande> lignes)  $default,) {final _that = this;
switch (_that) {
case _Panier():
return $default(_that.fournisseur,_that.commande,_that.livraisonPrevue,_that.lignes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( FournisseurPanier fournisseur,  CommandeEnregistree? commande, @JsonKey(name: 'livraison_prevue')  DateTime? livraisonPrevue,  List<LigneCommande> lignes)?  $default,) {final _that = this;
switch (_that) {
case _Panier() when $default != null:
return $default(_that.fournisseur,_that.commande,_that.livraisonPrevue,_that.lignes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Panier extends Panier {
  const _Panier({required this.fournisseur, this.commande, @JsonKey(name: 'livraison_prevue') this.livraisonPrevue,  List<LigneCommande> lignes = const <LigneCommande>[]}): _lignes = lignes,super._();
  factory _Panier.fromJson(Map<String, dynamic> json) => _$PanierFromJson(json);

@override final  FournisseurPanier fournisseur;
@override final  CommandeEnregistree? commande;
@override@JsonKey(name: 'livraison_prevue') final  DateTime? livraisonPrevue;
 final  List<LigneCommande> _lignes;
@override@JsonKey() List<LigneCommande> get lignes {
  if (_lignes is EqualUnmodifiableListView) return _lignes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lignes);
}


/// Create a copy of Panier
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PanierCopyWith<_Panier> get copyWith => __$PanierCopyWithImpl<_Panier>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PanierToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Panier&&(identical(other.fournisseur, fournisseur) || other.fournisseur == fournisseur)&&(identical(other.commande, commande) || other.commande == commande)&&(identical(other.livraisonPrevue, livraisonPrevue) || other.livraisonPrevue == livraisonPrevue)&&const DeepCollectionEquality().equals(other.lignes, _lignes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,fournisseur,commande,livraisonPrevue,const DeepCollectionEquality().hash(_lignes));
}

@override
String toString() {
    return 'Panier(fournisseur: $fournisseur, commande: $commande, livraisonPrevue: $livraisonPrevue, lignes: $lignes)';
}


}

/// @nodoc
abstract mixin class _$PanierCopyWith<$Res> implements $PanierCopyWith<$Res> {
  factory _$PanierCopyWith(_Panier value, $Res Function(_Panier) _then) = __$PanierCopyWithImpl;
@override @useResult
$Res call({
 FournisseurPanier fournisseur, CommandeEnregistree? commande,@JsonKey(name: 'livraison_prevue') DateTime? livraisonPrevue, List<LigneCommande> lignes
});


@override $FournisseurPanierCopyWith<$Res> get fournisseur;@override $CommandeEnregistreeCopyWith<$Res>? get commande;

}
/// @nodoc
class __$PanierCopyWithImpl<$Res>
    implements _$PanierCopyWith<$Res> {
  __$PanierCopyWithImpl(this._self, this._then);

  final _Panier _self;
  final $Res Function(_Panier) _then;

/// Create a copy of Panier
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fournisseur = null,Object? commande = freezed,Object? livraisonPrevue = freezed,Object? lignes = null,}) {
  return _then(_Panier(
fournisseur: null == fournisseur ? _self.fournisseur : fournisseur // ignore: cast_nullable_to_non_nullable
as FournisseurPanier,commande: freezed == commande ? _self.commande : commande // ignore: cast_nullable_to_non_nullable
as CommandeEnregistree?,livraisonPrevue: freezed == livraisonPrevue ? _self.livraisonPrevue : livraisonPrevue // ignore: cast_nullable_to_non_nullable
as DateTime?,lignes: null == lignes ? _self._lignes : lignes // ignore: cast_nullable_to_non_nullable
as List<LigneCommande>,
  ));
}

/// Create a copy of Panier
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FournisseurPanierCopyWith<$Res> get fournisseur {
  
  return $FournisseurPanierCopyWith<$Res>(_self.fournisseur, (value) {
    return _then(_self.copyWith(fournisseur: value));
  });
}/// Create a copy of Panier
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommandeEnregistreeCopyWith<$Res>? get commande {
    if (_self.commande == null) {
    return null;
  }

  return $CommandeEnregistreeCopyWith<$Res>(_self.commande!, (value) {
    return _then(_self.copyWith(commande: value));
  });
}
}


/// @nodoc
mixin _$Budget {

 double get budget; double get recu; double get engage; double get propose; double? get reste;
/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BudgetCopyWith<Budget> get copyWith => _$BudgetCopyWithImpl<Budget>(this as Budget, _$identity);

  /// Serializes this Budget to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Budget;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Budget&&(identical(other.budget, _this.budget) || other.budget == _this.budget)&&(identical(other.recu, _this.recu) || other.recu == _this.recu)&&(identical(other.engage, _this.engage) || other.engage == _this.engage)&&(identical(other.propose, _this.propose) || other.propose == _this.propose)&&(identical(other.reste, _this.reste) || other.reste == _this.reste));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Budget;
  return Object.hash(runtimeType,_this.budget,_this.recu,_this.engage,_this.propose,_this.reste);
}

@override
String toString() {
  final _this = this as Budget;
  return 'Budget(budget: ${_this.budget}, recu: ${_this.recu}, engage: ${_this.engage}, propose: ${_this.propose}, reste: ${_this.reste})';
}


}

/// @nodoc
abstract mixin class $BudgetCopyWith<$Res>  {
  factory $BudgetCopyWith(Budget value, $Res Function(Budget) _then) = _$BudgetCopyWithImpl;
@useResult
$Res call({
 double budget, double recu, double engage, double propose, double? reste
});




}
/// @nodoc
class _$BudgetCopyWithImpl<$Res>
    implements $BudgetCopyWith<$Res> {
  _$BudgetCopyWithImpl(this._self, this._then);

  final Budget _self;
  final $Res Function(Budget) _then;

/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? budget = null,Object? recu = null,Object? engage = null,Object? propose = null,Object? reste = freezed,}) {
  return _then(Budget(
budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as double,recu: null == recu ? _self.recu : recu // ignore: cast_nullable_to_non_nullable
as double,engage: null == engage ? _self.engage : engage // ignore: cast_nullable_to_non_nullable
as double,propose: null == propose ? _self.propose : propose // ignore: cast_nullable_to_non_nullable
as double,reste: freezed == reste ? _self.reste : reste // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [Budget].
extension BudgetPatterns on Budget {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Budget value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Budget() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Budget value)  $default,){
final _that = this;
switch (_that) {
case _Budget():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Budget value)?  $default,){
final _that = this;
switch (_that) {
case _Budget() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double budget,  double recu,  double engage,  double propose,  double? reste)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Budget() when $default != null:
return $default(_that.budget,_that.recu,_that.engage,_that.propose,_that.reste);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double budget,  double recu,  double engage,  double propose,  double? reste)  $default,) {final _that = this;
switch (_that) {
case _Budget():
return $default(_that.budget,_that.recu,_that.engage,_that.propose,_that.reste);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double budget,  double recu,  double engage,  double propose,  double? reste)?  $default,) {final _that = this;
switch (_that) {
case _Budget() when $default != null:
return $default(_that.budget,_that.recu,_that.engage,_that.propose,_that.reste);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Budget extends Budget {
  const _Budget({this.budget = 0, this.recu = 0, this.engage = 0, this.propose = 0, this.reste}): super._();
  factory _Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);

@override@JsonKey() final  double budget;
@override@JsonKey() final  double recu;
@override@JsonKey() final  double engage;
@override@JsonKey() final  double propose;
@override final  double? reste;

/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BudgetCopyWith<_Budget> get copyWith => __$BudgetCopyWithImpl<_Budget>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BudgetToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Budget&&(identical(other.budget, budget) || other.budget == budget)&&(identical(other.recu, recu) || other.recu == recu)&&(identical(other.engage, engage) || other.engage == engage)&&(identical(other.propose, propose) || other.propose == propose)&&(identical(other.reste, reste) || other.reste == reste));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,budget,recu,engage,propose,reste);
}

@override
String toString() {
    return 'Budget(budget: $budget, recu: $recu, engage: $engage, propose: $propose, reste: $reste)';
}


}

/// @nodoc
abstract mixin class _$BudgetCopyWith<$Res> implements $BudgetCopyWith<$Res> {
  factory _$BudgetCopyWith(_Budget value, $Res Function(_Budget) _then) = __$BudgetCopyWithImpl;
@override @useResult
$Res call({
 double budget, double recu, double engage, double propose, double? reste
});




}
/// @nodoc
class __$BudgetCopyWithImpl<$Res>
    implements _$BudgetCopyWith<$Res> {
  __$BudgetCopyWithImpl(this._self, this._then);

  final _Budget _self;
  final $Res Function(_Budget) _then;

/// Create a copy of Budget
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? budget = null,Object? recu = null,Object? engage = null,Object? propose = null,Object? reste = freezed,}) {
  return _then(_Budget(
budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as double,recu: null == recu ? _self.recu : recu // ignore: cast_nullable_to_non_nullable
as double,engage: null == engage ? _self.engage : engage // ignore: cast_nullable_to_non_nullable
as double,propose: null == propose ? _self.propose : propose // ignore: cast_nullable_to_non_nullable
as double,reste: freezed == reste ? _self.reste : reste // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$JourneeCommandes {

 DateTime get jour;@JsonKey(name: 'donnees_du') DateTime? get donneesDu;@JsonKey(name: 'peut_valider') bool get peutValider; bool get ferme; List<Panier> get paniers; List<LigneCommande> get psychotropes;@JsonKey(name: 'sans_fournisseur') List<LigneCommande> get sansFournisseur; Budget get budget;
/// Create a copy of JourneeCommandes
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JourneeCommandesCopyWith<JourneeCommandes> get copyWith => _$JourneeCommandesCopyWithImpl<JourneeCommandes>(this as JourneeCommandes, _$identity);

  /// Serializes this JourneeCommandes to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as JourneeCommandes;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JourneeCommandes&&(identical(other.jour, _this.jour) || other.jour == _this.jour)&&(identical(other.donneesDu, _this.donneesDu) || other.donneesDu == _this.donneesDu)&&(identical(other.peutValider, _this.peutValider) || other.peutValider == _this.peutValider)&&(identical(other.ferme, _this.ferme) || other.ferme == _this.ferme)&&const DeepCollectionEquality().equals(other.paniers, _this.paniers)&&const DeepCollectionEquality().equals(other.psychotropes, _this.psychotropes)&&const DeepCollectionEquality().equals(other.sansFournisseur, _this.sansFournisseur)&&(identical(other.budget, _this.budget) || other.budget == _this.budget));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as JourneeCommandes;
  return Object.hash(runtimeType,_this.jour,_this.donneesDu,_this.peutValider,_this.ferme,const DeepCollectionEquality().hash(_this.paniers),const DeepCollectionEquality().hash(_this.psychotropes),const DeepCollectionEquality().hash(_this.sansFournisseur),_this.budget);
}

@override
String toString() {
  final _this = this as JourneeCommandes;
  return 'JourneeCommandes(jour: ${_this.jour}, donneesDu: ${_this.donneesDu}, peutValider: ${_this.peutValider}, ferme: ${_this.ferme}, paniers: ${_this.paniers}, psychotropes: ${_this.psychotropes}, sansFournisseur: ${_this.sansFournisseur}, budget: ${_this.budget})';
}


}

/// @nodoc
abstract mixin class $JourneeCommandesCopyWith<$Res>  {
  factory $JourneeCommandesCopyWith(JourneeCommandes value, $Res Function(JourneeCommandes) _then) = _$JourneeCommandesCopyWithImpl;
@useResult
$Res call({
 DateTime jour,@JsonKey(name: 'donnees_du') DateTime? donneesDu,@JsonKey(name: 'peut_valider') bool peutValider, bool ferme, List<Panier> paniers, List<LigneCommande> psychotropes,@JsonKey(name: 'sans_fournisseur') List<LigneCommande> sansFournisseur, Budget budget
});


$BudgetCopyWith<$Res> get budget;

}
/// @nodoc
class _$JourneeCommandesCopyWithImpl<$Res>
    implements $JourneeCommandesCopyWith<$Res> {
  _$JourneeCommandesCopyWithImpl(this._self, this._then);

  final JourneeCommandes _self;
  final $Res Function(JourneeCommandes) _then;

/// Create a copy of JourneeCommandes
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jour = null,Object? donneesDu = freezed,Object? peutValider = null,Object? ferme = null,Object? paniers = null,Object? psychotropes = null,Object? sansFournisseur = null,Object? budget = null,}) {
  return _then(JourneeCommandes(
jour: null == jour ? _self.jour : jour // ignore: cast_nullable_to_non_nullable
as DateTime,donneesDu: freezed == donneesDu ? _self.donneesDu : donneesDu // ignore: cast_nullable_to_non_nullable
as DateTime?,peutValider: null == peutValider ? _self.peutValider : peutValider // ignore: cast_nullable_to_non_nullable
as bool,ferme: null == ferme ? _self.ferme : ferme // ignore: cast_nullable_to_non_nullable
as bool,paniers: null == paniers ? _self.paniers : paniers // ignore: cast_nullable_to_non_nullable
as List<Panier>,psychotropes: null == psychotropes ? _self.psychotropes : psychotropes // ignore: cast_nullable_to_non_nullable
as List<LigneCommande>,sansFournisseur: null == sansFournisseur ? _self.sansFournisseur : sansFournisseur // ignore: cast_nullable_to_non_nullable
as List<LigneCommande>,budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as Budget,
  ));
}
/// Create a copy of JourneeCommandes
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BudgetCopyWith<$Res> get budget {
  
  return $BudgetCopyWith<$Res>(_self.budget, (value) {
    return _then(_self.copyWith(budget: value));
  });
}
}


/// Adds pattern-matching-related methods to [JourneeCommandes].
extension JourneeCommandesPatterns on JourneeCommandes {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JourneeCommandes value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JourneeCommandes() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JourneeCommandes value)  $default,){
final _that = this;
switch (_that) {
case _JourneeCommandes():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JourneeCommandes value)?  $default,){
final _that = this;
switch (_that) {
case _JourneeCommandes() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime jour, @JsonKey(name: 'donnees_du')  DateTime? donneesDu, @JsonKey(name: 'peut_valider')  bool peutValider,  bool ferme,  List<Panier> paniers,  List<LigneCommande> psychotropes, @JsonKey(name: 'sans_fournisseur')  List<LigneCommande> sansFournisseur,  Budget budget)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JourneeCommandes() when $default != null:
return $default(_that.jour,_that.donneesDu,_that.peutValider,_that.ferme,_that.paniers,_that.psychotropes,_that.sansFournisseur,_that.budget);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime jour, @JsonKey(name: 'donnees_du')  DateTime? donneesDu, @JsonKey(name: 'peut_valider')  bool peutValider,  bool ferme,  List<Panier> paniers,  List<LigneCommande> psychotropes, @JsonKey(name: 'sans_fournisseur')  List<LigneCommande> sansFournisseur,  Budget budget)  $default,) {final _that = this;
switch (_that) {
case _JourneeCommandes():
return $default(_that.jour,_that.donneesDu,_that.peutValider,_that.ferme,_that.paniers,_that.psychotropes,_that.sansFournisseur,_that.budget);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime jour, @JsonKey(name: 'donnees_du')  DateTime? donneesDu, @JsonKey(name: 'peut_valider')  bool peutValider,  bool ferme,  List<Panier> paniers,  List<LigneCommande> psychotropes, @JsonKey(name: 'sans_fournisseur')  List<LigneCommande> sansFournisseur,  Budget budget)?  $default,) {final _that = this;
switch (_that) {
case _JourneeCommandes() when $default != null:
return $default(_that.jour,_that.donneesDu,_that.peutValider,_that.ferme,_that.paniers,_that.psychotropes,_that.sansFournisseur,_that.budget);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JourneeCommandes extends JourneeCommandes {
  const _JourneeCommandes({required this.jour, @JsonKey(name: 'donnees_du') this.donneesDu, @JsonKey(name: 'peut_valider') this.peutValider = false, this.ferme = false,  List<Panier> paniers = const <Panier>[],  List<LigneCommande> psychotropes = const <LigneCommande>[], @JsonKey(name: 'sans_fournisseur')  List<LigneCommande> sansFournisseur = const <LigneCommande>[], this.budget = const Budget()}): _paniers = paniers,_psychotropes = psychotropes,_sansFournisseur = sansFournisseur,super._();
  factory _JourneeCommandes.fromJson(Map<String, dynamic> json) => _$JourneeCommandesFromJson(json);

@override final  DateTime jour;
@override@JsonKey(name: 'donnees_du') final  DateTime? donneesDu;
@override@JsonKey(name: 'peut_valider') final  bool peutValider;
@override@JsonKey() final  bool ferme;
 final  List<Panier> _paniers;
@override@JsonKey() List<Panier> get paniers {
  if (_paniers is EqualUnmodifiableListView) return _paniers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_paniers);
}

 final  List<LigneCommande> _psychotropes;
@override@JsonKey() List<LigneCommande> get psychotropes {
  if (_psychotropes is EqualUnmodifiableListView) return _psychotropes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_psychotropes);
}

 final  List<LigneCommande> _sansFournisseur;
@override@JsonKey(name: 'sans_fournisseur') List<LigneCommande> get sansFournisseur {
  if (_sansFournisseur is EqualUnmodifiableListView) return _sansFournisseur;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sansFournisseur);
}

@override@JsonKey() final  Budget budget;

/// Create a copy of JourneeCommandes
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JourneeCommandesCopyWith<_JourneeCommandes> get copyWith => __$JourneeCommandesCopyWithImpl<_JourneeCommandes>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JourneeCommandesToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _JourneeCommandes&&(identical(other.jour, jour) || other.jour == jour)&&(identical(other.donneesDu, donneesDu) || other.donneesDu == donneesDu)&&(identical(other.peutValider, peutValider) || other.peutValider == peutValider)&&(identical(other.ferme, ferme) || other.ferme == ferme)&&const DeepCollectionEquality().equals(other.paniers, _paniers)&&const DeepCollectionEquality().equals(other.psychotropes, _psychotropes)&&const DeepCollectionEquality().equals(other.sansFournisseur, _sansFournisseur)&&(identical(other.budget, budget) || other.budget == budget));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,jour,donneesDu,peutValider,ferme,const DeepCollectionEquality().hash(_paniers),const DeepCollectionEquality().hash(_psychotropes),const DeepCollectionEquality().hash(_sansFournisseur),budget);
}

@override
String toString() {
    return 'JourneeCommandes(jour: $jour, donneesDu: $donneesDu, peutValider: $peutValider, ferme: $ferme, paniers: $paniers, psychotropes: $psychotropes, sansFournisseur: $sansFournisseur, budget: $budget)';
}


}

/// @nodoc
abstract mixin class _$JourneeCommandesCopyWith<$Res> implements $JourneeCommandesCopyWith<$Res> {
  factory _$JourneeCommandesCopyWith(_JourneeCommandes value, $Res Function(_JourneeCommandes) _then) = __$JourneeCommandesCopyWithImpl;
@override @useResult
$Res call({
 DateTime jour,@JsonKey(name: 'donnees_du') DateTime? donneesDu,@JsonKey(name: 'peut_valider') bool peutValider, bool ferme, List<Panier> paniers, List<LigneCommande> psychotropes,@JsonKey(name: 'sans_fournisseur') List<LigneCommande> sansFournisseur, Budget budget
});


@override $BudgetCopyWith<$Res> get budget;

}
/// @nodoc
class __$JourneeCommandesCopyWithImpl<$Res>
    implements _$JourneeCommandesCopyWith<$Res> {
  __$JourneeCommandesCopyWithImpl(this._self, this._then);

  final _JourneeCommandes _self;
  final $Res Function(_JourneeCommandes) _then;

/// Create a copy of JourneeCommandes
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jour = null,Object? donneesDu = freezed,Object? peutValider = null,Object? ferme = null,Object? paniers = null,Object? psychotropes = null,Object? sansFournisseur = null,Object? budget = null,}) {
  return _then(_JourneeCommandes(
jour: null == jour ? _self.jour : jour // ignore: cast_nullable_to_non_nullable
as DateTime,donneesDu: freezed == donneesDu ? _self.donneesDu : donneesDu // ignore: cast_nullable_to_non_nullable
as DateTime?,peutValider: null == peutValider ? _self.peutValider : peutValider // ignore: cast_nullable_to_non_nullable
as bool,ferme: null == ferme ? _self.ferme : ferme // ignore: cast_nullable_to_non_nullable
as bool,paniers: null == paniers ? _self._paniers : paniers // ignore: cast_nullable_to_non_nullable
as List<Panier>,psychotropes: null == psychotropes ? _self._psychotropes : psychotropes // ignore: cast_nullable_to_non_nullable
as List<LigneCommande>,sansFournisseur: null == sansFournisseur ? _self._sansFournisseur : sansFournisseur // ignore: cast_nullable_to_non_nullable
as List<LigneCommande>,budget: null == budget ? _self.budget : budget // ignore: cast_nullable_to_non_nullable
as Budget,
  ));
}

/// Create a copy of JourneeCommandes
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BudgetCopyWith<$Res> get budget {
  
  return $BudgetCopyWith<$Res>(_self.budget, (value) {
    return _then(_self.copyWith(budget: value));
  });
}
}


/// @nodoc
mixin _$BonCommande {

@JsonKey(name: 'id_commande') int get idCommande; String? get fournisseur; String? get whatsapp; String get texte;
/// Create a copy of BonCommande
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BonCommandeCopyWith<BonCommande> get copyWith => _$BonCommandeCopyWithImpl<BonCommande>(this as BonCommande, _$identity);

  /// Serializes this BonCommande to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BonCommande;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BonCommande&&(identical(other.idCommande, _this.idCommande) || other.idCommande == _this.idCommande)&&(identical(other.fournisseur, _this.fournisseur) || other.fournisseur == _this.fournisseur)&&(identical(other.whatsapp, _this.whatsapp) || other.whatsapp == _this.whatsapp)&&(identical(other.texte, _this.texte) || other.texte == _this.texte));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BonCommande;
  return Object.hash(runtimeType,_this.idCommande,_this.fournisseur,_this.whatsapp,_this.texte);
}

@override
String toString() {
  final _this = this as BonCommande;
  return 'BonCommande(idCommande: ${_this.idCommande}, fournisseur: ${_this.fournisseur}, whatsapp: ${_this.whatsapp}, texte: ${_this.texte})';
}


}

/// @nodoc
abstract mixin class $BonCommandeCopyWith<$Res>  {
  factory $BonCommandeCopyWith(BonCommande value, $Res Function(BonCommande) _then) = _$BonCommandeCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id_commande') int idCommande, String? fournisseur, String? whatsapp, String texte
});




}
/// @nodoc
class _$BonCommandeCopyWithImpl<$Res>
    implements $BonCommandeCopyWith<$Res> {
  _$BonCommandeCopyWithImpl(this._self, this._then);

  final BonCommande _self;
  final $Res Function(BonCommande) _then;

/// Create a copy of BonCommande
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? idCommande = null,Object? fournisseur = freezed,Object? whatsapp = freezed,Object? texte = null,}) {
  return _then(BonCommande(
idCommande: null == idCommande ? _self.idCommande : idCommande // ignore: cast_nullable_to_non_nullable
as int,fournisseur: freezed == fournisseur ? _self.fournisseur : fournisseur // ignore: cast_nullable_to_non_nullable
as String?,whatsapp: freezed == whatsapp ? _self.whatsapp : whatsapp // ignore: cast_nullable_to_non_nullable
as String?,texte: null == texte ? _self.texte : texte // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BonCommande].
extension BonCommandePatterns on BonCommande {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BonCommande value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BonCommande() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BonCommande value)  $default,){
final _that = this;
switch (_that) {
case _BonCommande():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BonCommande value)?  $default,){
final _that = this;
switch (_that) {
case _BonCommande() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id_commande')  int idCommande,  String? fournisseur,  String? whatsapp,  String texte)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BonCommande() when $default != null:
return $default(_that.idCommande,_that.fournisseur,_that.whatsapp,_that.texte);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id_commande')  int idCommande,  String? fournisseur,  String? whatsapp,  String texte)  $default,) {final _that = this;
switch (_that) {
case _BonCommande():
return $default(_that.idCommande,_that.fournisseur,_that.whatsapp,_that.texte);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id_commande')  int idCommande,  String? fournisseur,  String? whatsapp,  String texte)?  $default,) {final _that = this;
switch (_that) {
case _BonCommande() when $default != null:
return $default(_that.idCommande,_that.fournisseur,_that.whatsapp,_that.texte);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BonCommande extends BonCommande {
  const _BonCommande({@JsonKey(name: 'id_commande') required this.idCommande, this.fournisseur, this.whatsapp, required this.texte}): super._();
  factory _BonCommande.fromJson(Map<String, dynamic> json) => _$BonCommandeFromJson(json);

@override@JsonKey(name: 'id_commande') final  int idCommande;
@override final  String? fournisseur;
@override final  String? whatsapp;
@override final  String texte;

/// Create a copy of BonCommande
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BonCommandeCopyWith<_BonCommande> get copyWith => __$BonCommandeCopyWithImpl<_BonCommande>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BonCommandeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BonCommande&&(identical(other.idCommande, idCommande) || other.idCommande == idCommande)&&(identical(other.fournisseur, fournisseur) || other.fournisseur == fournisseur)&&(identical(other.whatsapp, whatsapp) || other.whatsapp == whatsapp)&&(identical(other.texte, texte) || other.texte == texte));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,idCommande,fournisseur,whatsapp,texte);
}

@override
String toString() {
    return 'BonCommande(idCommande: $idCommande, fournisseur: $fournisseur, whatsapp: $whatsapp, texte: $texte)';
}


}

/// @nodoc
abstract mixin class _$BonCommandeCopyWith<$Res> implements $BonCommandeCopyWith<$Res> {
  factory _$BonCommandeCopyWith(_BonCommande value, $Res Function(_BonCommande) _then) = __$BonCommandeCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id_commande') int idCommande, String? fournisseur, String? whatsapp, String texte
});




}
/// @nodoc
class __$BonCommandeCopyWithImpl<$Res>
    implements _$BonCommandeCopyWith<$Res> {
  __$BonCommandeCopyWithImpl(this._self, this._then);

  final _BonCommande _self;
  final $Res Function(_BonCommande) _then;

/// Create a copy of BonCommande
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? idCommande = null,Object? fournisseur = freezed,Object? whatsapp = freezed,Object? texte = null,}) {
  return _then(_BonCommande(
idCommande: null == idCommande ? _self.idCommande : idCommande // ignore: cast_nullable_to_non_nullable
as int,fournisseur: freezed == fournisseur ? _self.fournisseur : fournisseur // ignore: cast_nullable_to_non_nullable
as String?,whatsapp: freezed == whatsapp ? _self.whatsapp : whatsapp // ignore: cast_nullable_to_non_nullable
as String?,texte: null == texte ? _self.texte : texte // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$FournisseurReglage {

 int get id; String? get nom; TypeFournisseur get type; bool get actif; String? get whatsapp;@JsonKey(name: 'delai_livraison') int? get delaiLivraison;
/// Create a copy of FournisseurReglage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FournisseurReglageCopyWith<FournisseurReglage> get copyWith => _$FournisseurReglageCopyWithImpl<FournisseurReglage>(this as FournisseurReglage, _$identity);

  /// Serializes this FournisseurReglage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FournisseurReglage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FournisseurReglage&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nom, _this.nom) || other.nom == _this.nom)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.actif, _this.actif) || other.actif == _this.actif)&&(identical(other.whatsapp, _this.whatsapp) || other.whatsapp == _this.whatsapp)&&(identical(other.delaiLivraison, _this.delaiLivraison) || other.delaiLivraison == _this.delaiLivraison));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FournisseurReglage;
  return Object.hash(runtimeType,_this.id,_this.nom,_this.type,_this.actif,_this.whatsapp,_this.delaiLivraison);
}

@override
String toString() {
  final _this = this as FournisseurReglage;
  return 'FournisseurReglage(id: ${_this.id}, nom: ${_this.nom}, type: ${_this.type}, actif: ${_this.actif}, whatsapp: ${_this.whatsapp}, delaiLivraison: ${_this.delaiLivraison})';
}


}

/// @nodoc
abstract mixin class $FournisseurReglageCopyWith<$Res>  {
  factory $FournisseurReglageCopyWith(FournisseurReglage value, $Res Function(FournisseurReglage) _then) = _$FournisseurReglageCopyWithImpl;
@useResult
$Res call({
 int id, String? nom, TypeFournisseur type, bool actif, String? whatsapp,@JsonKey(name: 'delai_livraison') int? delaiLivraison
});




}
/// @nodoc
class _$FournisseurReglageCopyWithImpl<$Res>
    implements $FournisseurReglageCopyWith<$Res> {
  _$FournisseurReglageCopyWithImpl(this._self, this._then);

  final FournisseurReglage _self;
  final $Res Function(FournisseurReglage) _then;

/// Create a copy of FournisseurReglage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nom = freezed,Object? type = null,Object? actif = null,Object? whatsapp = freezed,Object? delaiLivraison = freezed,}) {
  return _then(FournisseurReglage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nom: freezed == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeFournisseur,actif: null == actif ? _self.actif : actif // ignore: cast_nullable_to_non_nullable
as bool,whatsapp: freezed == whatsapp ? _self.whatsapp : whatsapp // ignore: cast_nullable_to_non_nullable
as String?,delaiLivraison: freezed == delaiLivraison ? _self.delaiLivraison : delaiLivraison // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [FournisseurReglage].
extension FournisseurReglagePatterns on FournisseurReglage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FournisseurReglage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FournisseurReglage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FournisseurReglage value)  $default,){
final _that = this;
switch (_that) {
case _FournisseurReglage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FournisseurReglage value)?  $default,){
final _that = this;
switch (_that) {
case _FournisseurReglage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? nom,  TypeFournisseur type,  bool actif,  String? whatsapp, @JsonKey(name: 'delai_livraison')  int? delaiLivraison)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FournisseurReglage() when $default != null:
return $default(_that.id,_that.nom,_that.type,_that.actif,_that.whatsapp,_that.delaiLivraison);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? nom,  TypeFournisseur type,  bool actif,  String? whatsapp, @JsonKey(name: 'delai_livraison')  int? delaiLivraison)  $default,) {final _that = this;
switch (_that) {
case _FournisseurReglage():
return $default(_that.id,_that.nom,_that.type,_that.actif,_that.whatsapp,_that.delaiLivraison);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? nom,  TypeFournisseur type,  bool actif,  String? whatsapp, @JsonKey(name: 'delai_livraison')  int? delaiLivraison)?  $default,) {final _that = this;
switch (_that) {
case _FournisseurReglage() when $default != null:
return $default(_that.id,_that.nom,_that.type,_that.actif,_that.whatsapp,_that.delaiLivraison);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FournisseurReglage implements FournisseurReglage {
  const _FournisseurReglage({required this.id, this.nom, this.type = TypeFournisseur.pharma, this.actif = true, this.whatsapp, @JsonKey(name: 'delai_livraison') this.delaiLivraison});
  factory _FournisseurReglage.fromJson(Map<String, dynamic> json) => _$FournisseurReglageFromJson(json);

@override final  int id;
@override final  String? nom;
@override@JsonKey() final  TypeFournisseur type;
@override@JsonKey() final  bool actif;
@override final  String? whatsapp;
@override@JsonKey(name: 'delai_livraison') final  int? delaiLivraison;

/// Create a copy of FournisseurReglage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FournisseurReglageCopyWith<_FournisseurReglage> get copyWith => __$FournisseurReglageCopyWithImpl<_FournisseurReglage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FournisseurReglageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FournisseurReglage&&(identical(other.id, id) || other.id == id)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.type, type) || other.type == type)&&(identical(other.actif, actif) || other.actif == actif)&&(identical(other.whatsapp, whatsapp) || other.whatsapp == whatsapp)&&(identical(other.delaiLivraison, delaiLivraison) || other.delaiLivraison == delaiLivraison));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,nom,type,actif,whatsapp,delaiLivraison);
}

@override
String toString() {
    return 'FournisseurReglage(id: $id, nom: $nom, type: $type, actif: $actif, whatsapp: $whatsapp, delaiLivraison: $delaiLivraison)';
}


}

/// @nodoc
abstract mixin class _$FournisseurReglageCopyWith<$Res> implements $FournisseurReglageCopyWith<$Res> {
  factory _$FournisseurReglageCopyWith(_FournisseurReglage value, $Res Function(_FournisseurReglage) _then) = __$FournisseurReglageCopyWithImpl;
@override @useResult
$Res call({
 int id, String? nom, TypeFournisseur type, bool actif, String? whatsapp,@JsonKey(name: 'delai_livraison') int? delaiLivraison
});




}
/// @nodoc
class __$FournisseurReglageCopyWithImpl<$Res>
    implements _$FournisseurReglageCopyWith<$Res> {
  __$FournisseurReglageCopyWithImpl(this._self, this._then);

  final _FournisseurReglage _self;
  final $Res Function(_FournisseurReglage) _then;

/// Create a copy of FournisseurReglage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nom = freezed,Object? type = null,Object? actif = null,Object? whatsapp = freezed,Object? delaiLivraison = freezed,}) {
  return _then(_FournisseurReglage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nom: freezed == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeFournisseur,actif: null == actif ? _self.actif : actif // ignore: cast_nullable_to_non_nullable
as bool,whatsapp: freezed == whatsapp ? _self.whatsapp : whatsapp // ignore: cast_nullable_to_non_nullable
as String?,delaiLivraison: freezed == delaiLivraison ? _self.delaiLivraison : delaiLivraison // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
