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
  reprend: (json['reprend'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const <String>[],
  remplace: json['remplace'] as String?,
  mini: (json['mini'] as num?)?.toDouble() ?? 0,
  maxi: (json['maxi'] as num?)?.toDouble() ?? 0,
  couverture: (json['couverture'] as num?)?.toInt() ?? 0,
  ordonnance: (json['ordonnance'] as num?)?.toInt() ?? 0,
  lot: (json['lot'] as num?)?.toInt() ?? 0,
  tension: json['tension'] as bool? ?? false,
  surDemande: json['sur_demande'] as bool? ?? false,
  motif: json['motif'] as String?,
  groupe: json['groupe'] as String?,
  part: (json['part'] as num?)?.toDouble() ?? 1,
  stockGroupe: (json['stock_groupe'] as num?)?.toDouble() ?? 0,
  maxiGroupe: (json['maxi_groupe'] as num?)?.toDouble() ?? 0,
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
  'reprend': instance.reprend,
  'remplace': instance.remplace,
  'mini': instance.mini,
  'maxi': instance.maxi,
  'couverture': instance.couverture,
  'ordonnance': instance.ordonnance,
  'lot': instance.lot,
  'tension': instance.tension,
  'sur_demande': instance.surDemande,
  'motif': instance.motif,
  'groupe': instance.groupe,
  'part': instance.part,
  'stock_groupe': instance.stockGroupe,
  'maxi_groupe': instance.maxiGroupe,
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
  codeDci: json['code_dci'] as String?,
  grossistePrefere: json['grossiste_prefere'] as bool? ?? false,
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
  'code_dci': instance.codeDci,
  'grossiste_prefere': instance.grossistePrefere,
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

_MembreGenerique _$MembreGeneriqueFromJson(Map<String, dynamic> json) => _MembreGenerique(
  idNom: (json['id_nom'] as num).toInt(),
  nom: json['nom'] as String?,
  stock: (json['stock'] as num?)?.toInt() ?? 0,
  ventes12m: (json['ventes_12m'] as num?)?.toDouble() ?? 0,
  garde: json['garde'] as bool? ?? true,
  choix: json['choix'] as String?,
);

Map<String, dynamic> _$MembreGeneriqueToJson(_MembreGenerique instance) => <String, dynamic>{
  'id_nom': instance.idNom,
  'nom': instance.nom,
  'stock': instance.stock,
  'ventes_12m': instance.ventes12m,
  'garde': instance.garde,
  'choix': instance.choix,
};

_GroupeGenerique _$GroupeGeneriqueFromJson(Map<String, dynamic> json) => _GroupeGenerique(
  code: json['code'] as String?,
  classe: json['classe'] as String?,
  mode: json['mode'] as String? ?? 'toutes',
  modeForce: json['mode_force'] as String?,
  chronique: json['chronique'] as bool? ?? false,
  nombreGardes: (json['nombre_gardes'] as num?)?.toInt() ?? 2,
  membres:
      (json['membres'] as List<dynamic>?)?.map((e) => MembreGenerique.fromJson(e as Map<String, dynamic>)).toList() ??
      const <MembreGenerique>[],
);

Map<String, dynamic> _$GroupeGeneriqueToJson(_GroupeGenerique instance) => <String, dynamic>{
  'code': instance.code,
  'classe': instance.classe,
  'mode': instance.mode,
  'mode_force': instance.modeForce,
  'chronique': instance.chronique,
  'nombre_gardes': instance.nombreGardes,
  'membres': instance.membres,
};

_AjoutCommande _$AjoutCommandeFromJson(Map<String, dynamic> json) => _AjoutCommande(
  idCommande: (json['id_commande'] as num).toInt(),
  idFournisseur: (json['id_fournisseur'] as num).toInt(),
  fournisseur: json['fournisseur'] as String?,
  qte: (json['qte'] as num).toInt(),
  dejaPresent: json['deja_present'] as bool? ?? false,
);

Map<String, dynamic> _$AjoutCommandeToJson(_AjoutCommande instance) => <String, dynamic>{
  'id_commande': instance.idCommande,
  'id_fournisseur': instance.idFournisseur,
  'fournisseur': instance.fournisseur,
  'qte': instance.qte,
  'deja_present': instance.dejaPresent,
};

_DetailCalcul _$DetailCalculFromJson(Map<String, dynamic> json) => _DetailCalcul(
  idNom: (json['id_nom'] as num).toInt(),
  nom: json['nom'] as String?,
  type: json['type'] as String? ?? '',
  joursVente12m: (json['jours_vente_12m'] as num?)?.toInt() ?? 0,
  fenetreJours: (json['fenetre_jours'] as num?)?.toInt() ?? 0,
  joursOuverts: (json['jours_ouverts'] as num?)?.toInt() ?? 0,
  joursExclusRupture: (json['jours_exclus_rupture'] as num?)?.toInt() ?? 0,
  joursRetenus: (json['jours_retenus'] as num?)?.toInt() ?? 0,
  joursStockNul: (json['jours_stock_nul'] as num?)?.toInt() ?? 0,
  venduFenetre: (json['vendu_fenetre'] as num?)?.toDouble() ?? 0,
  venduJoursRetenus: (json['vendu_jours_retenus'] as num?)?.toDouble() ?? 0,
  reprisGeneriques: (json['repris_generiques'] as num?)?.toDouble() ?? 0,
  rythme: (json['rythme'] as num?)?.toDouble() ?? 0,
  moyenneHorsRuptures: (json['moyenne_hors_ruptures'] as num?)?.toDouble() ?? 0,
  moyenneBrute: (json['moyenne_brute'] as num?)?.toDouble() ?? 0,
  ventes12m: (json['ventes_12m'] as num?)?.toDouble() ?? 0,
  moyenne12m: (json['moyenne_12m_jour_ouvert'] as num?)?.toDouble() ?? 0,
  cmm: (json['cmm'] as num?)?.toDouble() ?? 0,
  plusGrossesVentes:
      (json['plus_grosses_ventes'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ??
      const <Map<String, dynamic>>[],
  decision: json['decision'] == null ? null : Raison.fromJson(json['decision'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DetailCalculToJson(_DetailCalcul instance) => <String, dynamic>{
  'id_nom': instance.idNom,
  'nom': instance.nom,
  'type': instance.type,
  'jours_vente_12m': instance.joursVente12m,
  'fenetre_jours': instance.fenetreJours,
  'jours_ouverts': instance.joursOuverts,
  'jours_exclus_rupture': instance.joursExclusRupture,
  'jours_retenus': instance.joursRetenus,
  'jours_stock_nul': instance.joursStockNul,
  'vendu_fenetre': instance.venduFenetre,
  'vendu_jours_retenus': instance.venduJoursRetenus,
  'repris_generiques': instance.reprisGeneriques,
  'rythme': instance.rythme,
  'moyenne_hors_ruptures': instance.moyenneHorsRuptures,
  'moyenne_brute': instance.moyenneBrute,
  'ventes_12m': instance.ventes12m,
  'moyenne_12m_jour_ouvert': instance.moyenne12m,
  'cmm': instance.cmm,
  'plus_grosses_ventes': instance.plusGrossesVentes,
  'decision': instance.decision,
};

_Tension _$TensionFromJson(Map<String, dynamic> json) => _Tension(
  idNom: (json['id_nom'] as num).toInt(),
  nom: json['nom'] as String?,
  stock: (json['stock'] as num?)?.toDouble() ?? 0,
  tension: json['tension'] as bool? ?? true,
  confirme: json['confirme'] as bool? ?? false,
  source: json['source'] as String? ?? 'detection',
  motif: json['motif'] as String?,
);

Map<String, dynamic> _$TensionToJson(_Tension instance) => <String, dynamic>{
  'id_nom': instance.idNom,
  'nom': instance.nom,
  'stock': instance.stock,
  'tension': instance.tension,
  'confirme': instance.confirme,
  'source': instance.source,
  'motif': instance.motif,
};

_LigneSuivie _$LigneSuivieFromJson(Map<String, dynamic> json) => _LigneSuivie(
  idNom: (json['id_nom'] as num).toInt(),
  nom: json['nom'] as String?,
  qte: (json['qte'] as num?)?.toInt() ?? 0,
  recu: (json['recu'] as num?)?.toInt() ?? 0,
  reste: (json['reste'] as num?)?.toInt() ?? 0,
  recuLe: json['recu_le'] == null ? null : DateTime.parse(json['recu_le'] as String),
  etat: $enumDecodeNullable(_$EtatLivraisonEnumMap, json['etat']) ?? EtatLivraison.attendue,
  stock: (json['stock'] as num?)?.toInt() ?? 0,
  tension: json['tension'] as String?,
);

Map<String, dynamic> _$LigneSuivieToJson(_LigneSuivie instance) => <String, dynamic>{
  'id_nom': instance.idNom,
  'nom': instance.nom,
  'qte': instance.qte,
  'recu': instance.recu,
  'reste': instance.reste,
  'recu_le': instance.recuLe?.toIso8601String(),
  'etat': _$EtatLivraisonEnumMap[instance.etat]!,
  'stock': instance.stock,
  'tension': instance.tension,
};

const _$EtatLivraisonEnumMap = {
  EtatLivraison.manquante: 'manquante',
  EtatLivraison.partielle: 'partielle',
  EtatLivraison.attendue: 'attendue',
  EtatLivraison.livree: 'livree',
};

_CommandeSuivie _$CommandeSuivieFromJson(Map<String, dynamic> json) => _CommandeSuivie(
  id: (json['id'] as num).toInt(),
  jour: DateTime.parse(json['jour'] as String),
  fournisseur: FournisseurPanier.fromJson(json['fournisseur'] as Map<String, dynamic>),
  livraisonPrevue: json['livraison_prevue'] == null ? null : DateTime.parse(json['livraison_prevue'] as String),
  etat: $enumDecodeNullable(_$EtatLivraisonEnumMap, json['etat']) ?? EtatLivraison.attendue,
  lignes:
      (json['lignes'] as List<dynamic>?)?.map((e) => LigneSuivie.fromJson(e as Map<String, dynamic>)).toList() ??
      const <LigneSuivie>[],
);

Map<String, dynamic> _$CommandeSuivieToJson(_CommandeSuivie instance) => <String, dynamic>{
  'id': instance.id,
  'jour': instance.jour.toIso8601String(),
  'fournisseur': instance.fournisseur,
  'livraison_prevue': instance.livraisonPrevue?.toIso8601String(),
  'etat': _$EtatLivraisonEnumMap[instance.etat]!,
  'lignes': instance.lignes,
};

_ServiceFournisseur _$ServiceFournisseurFromJson(Map<String, dynamic> json) => _ServiceFournisseur(
  id: (json['id'] as num).toInt(),
  nom: json['nom'] as String?,
  commandes: (json['commandes'] as num?)?.toInt() ?? 0,
  lignes: (json['lignes'] as num?)?.toInt() ?? 0,
  qte: (json['qte'] as num?)?.toInt() ?? 0,
  recu: (json['recu'] as num?)?.toInt() ?? 0,
  tauxLignes: (json['taux_lignes'] as num?)?.toInt(),
  tauxQuantite: (json['taux_quantite'] as num?)?.toInt(),
);

Map<String, dynamic> _$ServiceFournisseurToJson(_ServiceFournisseur instance) => <String, dynamic>{
  'id': instance.id,
  'nom': instance.nom,
  'commandes': instance.commandes,
  'lignes': instance.lignes,
  'qte': instance.qte,
  'recu': instance.recu,
  'taux_lignes': instance.tauxLignes,
  'taux_quantite': instance.tauxQuantite,
};

_SuiviLivraisons _$SuiviLivraisonsFromJson(Map<String, dynamic> json) => _SuiviLivraisons(
  jour: DateTime.parse(json['jour'] as String),
  jours: (json['jours'] as num?)?.toInt() ?? 30,
  donneesDu: json['donnees_du'] == null ? null : DateTime.parse(json['donnees_du'] as String),
  commandes:
      (json['commandes'] as List<dynamic>?)?.map((e) => CommandeSuivie.fromJson(e as Map<String, dynamic>)).toList() ??
      const <CommandeSuivie>[],
  fournisseurs:
      (json['fournisseurs'] as List<dynamic>?)
          ?.map((e) => ServiceFournisseur.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ServiceFournisseur>[],
);

Map<String, dynamic> _$SuiviLivraisonsToJson(_SuiviLivraisons instance) => <String, dynamic>{
  'jour': instance.jour.toIso8601String(),
  'jours': instance.jours,
  'donnees_du': instance.donneesDu?.toIso8601String(),
  'commandes': instance.commandes,
  'fournisseurs': instance.fournisseurs,
};
