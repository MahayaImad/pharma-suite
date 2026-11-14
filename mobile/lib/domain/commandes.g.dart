// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commandes.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Raison _$RaisonFromJson(Map<String, dynamic> json) => _Raison(
  type: json['type'] as String? ?? '',
  rythme: (json['rythme'] as num?)?.toDouble() ?? 0,
  joursCouverts: (json['jours_couverts'] as num?)?.toInt() ?? 0,
  prevu: (json['prevu'] as num?)?.toDouble() ?? 0,
  securite: (json['securite'] as num?)?.toDouble() ?? 0,
  cible: (json['cible'] as num?)?.toDouble() ?? 0,
  stock: (json['stock'] as num?)?.toDouble() ?? 0,
  enCours: (json['en_cours'] as num?)?.toDouble() ?? 0,
);

Map<String, dynamic> _$RaisonToJson(_Raison instance) => <String, dynamic>{
  'type': instance.type,
  'rythme': instance.rythme,
  'jours_couverts': instance.joursCouverts,
  'prevu': instance.prevu,
  'securite': instance.securite,
  'cible': instance.cible,
  'stock': instance.stock,
  'en_cours': instance.enCours,
};

_LigneCommande _$LigneCommandeFromJson(Map<String, dynamic> json) => _LigneCommande(
  idNom: (json['id_nom'] as num).toInt(),
  nom: json['nom'] as String?,
  famille: json['famille'] as String?,
  classeAbc: json['classe_abc'] as String?,
  stock: (json['stock'] as num?)?.toInt() ?? 0,
  qte: (json['qte'] as num).toInt(),
  qteProposee: (json['qte_proposee'] as num?)?.toInt(),
  prixAchat: (json['prix_achat'] as num?)?.toDouble() ?? 0,
  montant: (json['montant'] as num?)?.toDouble() ?? 0,
  raison: json['raison'] == null ? null : Raison.fromJson(json['raison'] as Map<String, dynamic>),
  fournisseur: json['fournisseur'] as String?,
);

Map<String, dynamic> _$LigneCommandeToJson(_LigneCommande instance) => <String, dynamic>{
  'id_nom': instance.idNom,
  'nom': instance.nom,
  'famille': instance.famille,
  'classe_abc': instance.classeAbc,
  'stock': instance.stock,
  'qte': instance.qte,
  'qte_proposee': instance.qteProposee,
  'prix_achat': instance.prixAchat,
  'montant': instance.montant,
  'raison': instance.raison,
  'fournisseur': instance.fournisseur,
};

_FournisseurPanier _$FournisseurPanierFromJson(Map<String, dynamic> json) => _FournisseurPanier(
  id: (json['id'] as num).toInt(),
  nom: json['nom'] as String?,
  type: $enumDecodeNullable(_$TypeFournisseurEnumMap, json['type']) ?? TypeFournisseur.pharma,
  whatsapp: json['whatsapp'] as String?,
);

Map<String, dynamic> _$FournisseurPanierToJson(_FournisseurPanier instance) => <String, dynamic>{
  'id': instance.id,
  'nom': instance.nom,
  'type': _$TypeFournisseurEnumMap[instance.type]!,
  'whatsapp': instance.whatsapp,
};

const _$TypeFournisseurEnumMap = {TypeFournisseur.pharma: 'pharma', TypeFournisseur.para: 'para'};

_CommandeEnregistree _$CommandeEnregistreeFromJson(Map<String, dynamic> json) => _CommandeEnregistree(
  id: (json['id'] as num).toInt(),
  jour: DateTime.parse(json['jour'] as String),
  statut: $enumDecode(_$StatutCommandeEnumMap, json['statut']),
  livraisonPrevue: json['livraison_prevue'] == null ? null : DateTime.parse(json['livraison_prevue'] as String),
  creePar: json['cree_par'] as String?,
  validePar: json['valide_par'] as String?,
);

Map<String, dynamic> _$CommandeEnregistreeToJson(_CommandeEnregistree instance) => <String, dynamic>{
  'id': instance.id,
  'jour': instance.jour.toIso8601String(),
  'statut': _$StatutCommandeEnumMap[instance.statut]!,
  'livraison_prevue': instance.livraisonPrevue?.toIso8601String(),
  'cree_par': instance.creePar,
  'valide_par': instance.validePar,
};

const _$StatutCommandeEnumMap = {
  StatutCommande.brouillon: 'brouillon',
  StatutCommande.validee: 'validee',
  StatutCommande.envoyee: 'envoyee',
  StatutCommande.annulee: 'annulee',
};

_Panier _$PanierFromJson(Map<String, dynamic> json) => _Panier(
  fournisseur: FournisseurPanier.fromJson(json['fournisseur'] as Map<String, dynamic>),
  commande: json['commande'] == null ? null : CommandeEnregistree.fromJson(json['commande'] as Map<String, dynamic>),
  livraisonPrevue: json['livraison_prevue'] == null ? null : DateTime.parse(json['livraison_prevue'] as String),
  lignes:
      (json['lignes'] as List<dynamic>?)?.map((e) => LigneCommande.fromJson(e as Map<String, dynamic>)).toList() ??
      const <LigneCommande>[],
);

Map<String, dynamic> _$PanierToJson(_Panier instance) => <String, dynamic>{
  'fournisseur': instance.fournisseur,
  'commande': instance.commande,
  'livraison_prevue': instance.livraisonPrevue?.toIso8601String(),
  'lignes': instance.lignes,
};

_Budget _$BudgetFromJson(Map<String, dynamic> json) => _Budget(
  budget: (json['budget'] as num?)?.toDouble() ?? 0,
  recu: (json['recu'] as num?)?.toDouble() ?? 0,
  engage: (json['engage'] as num?)?.toDouble() ?? 0,
  propose: (json['propose'] as num?)?.toDouble() ?? 0,
  reste: (json['reste'] as num?)?.toDouble(),
);

Map<String, dynamic> _$BudgetToJson(_Budget instance) => <String, dynamic>{
  'budget': instance.budget,
  'recu': instance.recu,
  'engage': instance.engage,
  'propose': instance.propose,
  'reste': instance.reste,
};

_JourneeCommandes _$JourneeCommandesFromJson(Map<String, dynamic> json) => _JourneeCommandes(
  jour: DateTime.parse(json['jour'] as String),
  donneesDu: json['donnees_du'] == null ? null : DateTime.parse(json['donnees_du'] as String),
  peutValider: json['peut_valider'] as bool? ?? false,
  ferme: json['ferme'] as bool? ?? false,
  paniers:
      (json['paniers'] as List<dynamic>?)?.map((e) => Panier.fromJson(e as Map<String, dynamic>)).toList() ??
      const <Panier>[],
  psychotropes:
      (json['psychotropes'] as List<dynamic>?)
          ?.map((e) => LigneCommande.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <LigneCommande>[],
  sansFournisseur:
      (json['sans_fournisseur'] as List<dynamic>?)
          ?.map((e) => LigneCommande.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <LigneCommande>[],
  budget: json['budget'] == null ? const Budget() : Budget.fromJson(json['budget'] as Map<String, dynamic>),
);

Map<String, dynamic> _$JourneeCommandesToJson(_JourneeCommandes instance) => <String, dynamic>{
  'jour': instance.jour.toIso8601String(),
  'donnees_du': instance.donneesDu?.toIso8601String(),
  'peut_valider': instance.peutValider,
  'ferme': instance.ferme,
  'paniers': instance.paniers,
  'psychotropes': instance.psychotropes,
  'sans_fournisseur': instance.sansFournisseur,
  'budget': instance.budget,
};

_BonCommande _$BonCommandeFromJson(Map<String, dynamic> json) => _BonCommande(
  idCommande: (json['id_commande'] as num).toInt(),
  fournisseur: json['fournisseur'] as String?,
  whatsapp: json['whatsapp'] as String?,
  texte: json['texte'] as String,
);

Map<String, dynamic> _$BonCommandeToJson(_BonCommande instance) => <String, dynamic>{
  'id_commande': instance.idCommande,
  'fournisseur': instance.fournisseur,
  'whatsapp': instance.whatsapp,
  'texte': instance.texte,
};

_FournisseurReglage _$FournisseurReglageFromJson(Map<String, dynamic> json) => _FournisseurReglage(
  id: (json['id'] as num).toInt(),
  nom: json['nom'] as String?,
  type: $enumDecodeNullable(_$TypeFournisseurEnumMap, json['type']) ?? TypeFournisseur.pharma,
  actif: json['actif'] as bool? ?? true,
  auto: json['auto'] as bool? ?? true,
  whatsapp: json['whatsapp'] as String?,
  telephone: json['telephone'] as String?,
  derniereCommande: json['derniere_commande'] == null ? null : DateTime.parse(json['derniere_commande'] as String),
  delaiLivraison: (json['delai_livraison'] as num?)?.toInt(),
);

Map<String, dynamic> _$FournisseurReglageToJson(_FournisseurReglage instance) => <String, dynamic>{
  'id': instance.id,
  'nom': instance.nom,
  'type': _$TypeFournisseurEnumMap[instance.type]!,
  'actif': instance.actif,
  'auto': instance.auto,
  'whatsapp': instance.whatsapp,
  'telephone': instance.telephone,
  'derniere_commande': instance.derniereCommande?.toIso8601String(),
  'delai_livraison': instance.delaiLivraison,
};

_Compte _$CompteFromJson(Map<String, dynamic> json) => _Compte(
  username: json['username'] as String,
  role: json['role'] as String? ?? 'employee',
  nom: json['nom'] as String?,
  prenom: json['prenom'] as String?,
  actif: json['is_active'] as bool? ?? true,
);

Map<String, dynamic> _$CompteToJson(_Compte instance) => <String, dynamic>{
  'username': instance.username,
  'role': instance.role,
  'nom': instance.nom,
  'prenom': instance.prenom,
  'is_active': instance.actif,
};
