// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FamilleStock _$FamilleStockFromJson(Map<String, dynamic> json) => _FamilleStock(
  id: (json['id'] as num?)?.toInt(),
  famille: json['famille'] as String,
  produitsActifs: (json['produits_actifs'] as num?)?.toInt() ?? 0,
  produitsEnStock: (json['produits_en_stock'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$FamilleStockToJson(_FamilleStock instance) => <String, dynamic>{
  'id': instance.id,
  'famille': instance.famille,
  'produits_actifs': instance.produitsActifs,
  'produits_en_stock': instance.produitsEnStock,
};

_ResumeStock _$ResumeStockFromJson(Map<String, dynamic> json) => _ResumeStock(
  donneesDu: json['donnees_du'] == null ? null : DateTime.parse(json['donnees_du'] as String),
  produitsActifs: (json['produits_actifs'] as num?)?.toInt() ?? 0,
  produitsEnStock: (json['produits_en_stock'] as num?)?.toInt() ?? 0,
  valeurAchat: (json['valeur_achat'] as num?)?.toDouble() ?? 0,
  valeurVente: (json['valeur_vente'] as num?)?.toDouble() ?? 0,
  familles:
      (json['familles'] as List<dynamic>?)?.map((e) => FamilleStock.fromJson(e as Map<String, dynamic>)).toList() ??
      const <FamilleStock>[],
);

Map<String, dynamic> _$ResumeStockToJson(_ResumeStock instance) => <String, dynamic>{
  'donnees_du': instance.donneesDu?.toIso8601String(),
  'produits_actifs': instance.produitsActifs,
  'produits_en_stock': instance.produitsEnStock,
  'valeur_achat': instance.valeurAchat,
  'valeur_vente': instance.valeurVente,
  'familles': instance.familles,
};

_Produit _$ProduitFromJson(Map<String, dynamic> json) => _Produit(
  id: (json['id'] as num).toInt(),
  nom: json['nom'] as String? ?? '',
  dci: json['dci'] as String?,
  dosage: json['dosage'] as String?,
  forme: json['forme'] as String?,
  formeAbr: json['forme_abr'] as String?,
  idFamille: (json['id_famille'] as num?)?.toInt(),
  famille: json['famille'] as String?,
  labo: json['labo'] as String?,
  codeBarre: json['code_barre_original'] as String?,
  conditionnement: json['conditionnement'] as String?,
  stock: (json['stock'] as num?)?.toDouble() ?? 0,
  seuil: (json['qte_alerte'] as num?)?.toInt(),
  prixVente: (json['prix_vente'] as num?)?.toDouble() ?? 0,
  prixAchat: (json['prix_achat_moyen'] as num?)?.toDouble() ?? 0,
  valeurAchat: (json['valeur_achat'] as num?)?.toDouble() ?? 0,
  valeurVente: (json['valeur_vente'] as num?)?.toDouble() ?? 0,
  vendu12Mois: (json['qte_vendue_12m'] as num?)?.toInt(),
  derniereVente: json['derniere_vente'] == null ? null : DateTime.parse(json['derniere_vente'] as String),
  actif: json['actif'] as bool? ?? false,
  classeAbc: json['segment_abc'] as String?,
  classeXyz: json['segment_xyz'] as String?,
  categorie: json['categorie'] as String?,
  disponibilite: json['disponibilite'] as String?,
  psychotrope: (json['psychotrope'] as num?)?.toInt(),
  remboursable: (json['remb_cvm'] as num?)?.toInt(),
  cmm: (json['cmm'] as num?)?.toDouble() ?? 0,
  stockSecurite: (json['stock_securite'] as num?)?.toInt() ?? 0,
  stockMaximum: (json['stock_maximum'] as num?)?.toInt() ?? 0,
  couverture: (json['couverture_jours'] as num?)?.toInt(),
  qteARisque: (json['qte_a_risque'] as num?)?.toInt() ?? 0,
  valeurARisque: (json['valeur_a_risque'] as num?)?.toDouble() ?? 0,
  qteSurstock: (json['qte_surstock'] as num?)?.toInt() ?? 0,
  valeurSurstock: (json['valeur_surstock'] as num?)?.toDouble() ?? 0,
  consommable: json['consommable'] as bool? ?? false,
  consommablePropose: json['consommable_propose'] as bool? ?? false,
);

Map<String, dynamic> _$ProduitToJson(_Produit instance) => <String, dynamic>{
  'id': instance.id,
  'nom': instance.nom,
  'dci': instance.dci,
  'dosage': instance.dosage,
  'forme': instance.forme,
  'forme_abr': instance.formeAbr,
  'id_famille': instance.idFamille,
  'famille': instance.famille,
  'labo': instance.labo,
  'code_barre_original': instance.codeBarre,
  'conditionnement': instance.conditionnement,
  'stock': instance.stock,
  'qte_alerte': instance.seuil,
  'prix_vente': instance.prixVente,
  'prix_achat_moyen': instance.prixAchat,
  'valeur_achat': instance.valeurAchat,
  'valeur_vente': instance.valeurVente,
  'qte_vendue_12m': instance.vendu12Mois,
  'derniere_vente': instance.derniereVente?.toIso8601String(),
  'actif': instance.actif,
  'segment_abc': instance.classeAbc,
  'segment_xyz': instance.classeXyz,
  'categorie': instance.categorie,
  'disponibilite': instance.disponibilite,
  'psychotrope': instance.psychotrope,
  'remb_cvm': instance.remboursable,
  'cmm': instance.cmm,
  'stock_securite': instance.stockSecurite,
  'stock_maximum': instance.stockMaximum,
  'couverture_jours': instance.couverture,
  'qte_a_risque': instance.qteARisque,
  'valeur_a_risque': instance.valeurARisque,
  'qte_surstock': instance.qteSurstock,
  'valeur_surstock': instance.valeurSurstock,
  'consommable': instance.consommable,
  'consommable_propose': instance.consommablePropose,
};

_Lot _$LotFromJson(Map<String, dynamic> json) => _Lot(
  id: (json['id'] as num).toInt(),
  lot: json['lot'] as String?,
  peremption: json['peremption'] as String?,
  peremptionDate: json['peremption_date'] == null ? null : DateTime.parse(json['peremption_date'] as String),
  stock: (json['stock'] as num?)?.toInt() ?? 0,
  qteEntree: (json['qte_entree'] as num?)?.toInt() ?? 0,
  prixAchat: (json['prix_achat'] as num?)?.toDouble() ?? 0,
  prixVente: (json['prix_vente'] as num?)?.toDouble() ?? 0,
  fournisseur: json['fournisseur'] as String?,
  dateEntree: json['date_entree'] == null ? null : DateTime.parse(json['date_entree'] as String),
  numBl: json['num_bl'] as String?,
  bloque: json['bloque'] == null ? false : _versBool(json['bloque']),
);

Map<String, dynamic> _$LotToJson(_Lot instance) => <String, dynamic>{
  'id': instance.id,
  'lot': instance.lot,
  'peremption': instance.peremption,
  'peremption_date': instance.peremptionDate?.toIso8601String(),
  'stock': instance.stock,
  'qte_entree': instance.qteEntree,
  'prix_achat': instance.prixAchat,
  'prix_vente': instance.prixVente,
  'fournisseur': instance.fournisseur,
  'date_entree': instance.dateEntree?.toIso8601String(),
  'num_bl': instance.numBl,
  'bloque': instance.bloque,
};

_RisqueLot _$RisqueLotFromJson(Map<String, dynamic> json) => _RisqueLot(
  id: (json['id'] as num).toInt(),
  dvr: (json['dvr'] as num?)?.toInt(),
  ecoulable: (json['ecoulable'] as num?)?.toInt(),
  stock: (json['stock'] as num?)?.toInt() ?? 0,
  aRisque: (json['a_risque'] as num?)?.toInt(),
  valeurARisque: (json['valeur_a_risque'] as num?)?.toDouble(),
);

Map<String, dynamic> _$RisqueLotToJson(_RisqueLot instance) => <String, dynamic>{
  'id': instance.id,
  'dvr': instance.dvr,
  'ecoulable': instance.ecoulable,
  'stock': instance.stock,
  'a_risque': instance.aRisque,
  'valeur_a_risque': instance.valeurARisque,
};

_FournisseurPrincipal _$FournisseurPrincipalFromJson(Map<String, dynamic> json) => _FournisseurPrincipal(
  id: (json['id'] as num?)?.toInt(),
  nom: json['nom'] as String?,
  delaiJoursOuvres: (json['delai_jours_ouvres'] as num?)?.toInt() ?? 1,
  delaiSaisi: json['delai_saisi'] as bool? ?? false,
);

Map<String, dynamic> _$FournisseurPrincipalToJson(_FournisseurPrincipal instance) => <String, dynamic>{
  'id': instance.id,
  'nom': instance.nom,
  'delai_jours_ouvres': instance.delaiJoursOuvres,
  'delai_saisi': instance.delaiSaisi,
};

_IndicateursProduit _$IndicateursProduitFromJson(Map<String, dynamic> json) => _IndicateursProduit(
  ventes12Mois: (json['ventes_12_mois'] as num?)?.toDouble() ?? 0,
  moisHistorique: (json['mois_historique'] as num?)?.toInt() ?? 12,
  cmm: (json['cmm'] as num?)?.toDouble() ?? 0,
  cmj: (json['cmj'] as num?)?.toDouble() ?? 0,
  fournisseur: json['fournisseur'] == null
      ? null
      : FournisseurPrincipal.fromJson(json['fournisseur'] as Map<String, dynamic>),
  delaiLivraison: (json['delai_livraison_jours'] as num?)?.toInt() ?? 1,
  dateLivraison: json['date_livraison'] == null ? null : DateTime.parse(json['date_livraison'] as String),
  stockSecurite: (json['stock_securite'] as num?)?.toInt() ?? 0,
  stockSecuriteSimple: (json['stock_securite_simple'] as num?)?.toInt() ?? 0,
  delaiSecurite: (json['delai_securite_jours'] as num?)?.toDouble() ?? 0,
  periodeCommande: (json['periode_commande_jours'] as num?)?.toDouble() ?? 0,
  stockMaximum: (json['stock_maximum'] as num?)?.toInt() ?? 0,
  couverture: (json['couverture_jours'] as num?)?.toInt(),
  dvrMax: (json['dvr_max'] as num?)?.toInt(),
  qteARisque: (json['qte_a_risque'] as num?)?.toInt() ?? 0,
  valeurARisque: (json['valeur_a_risque'] as num?)?.toDouble() ?? 0,
  lots:
      (json['lots'] as List<dynamic>?)?.map((e) => RisqueLot.fromJson(e as Map<String, dynamic>)).toList() ??
      const <RisqueLot>[],
);

Map<String, dynamic> _$IndicateursProduitToJson(_IndicateursProduit instance) => <String, dynamic>{
  'ventes_12_mois': instance.ventes12Mois,
  'mois_historique': instance.moisHistorique,
  'cmm': instance.cmm,
  'cmj': instance.cmj,
  'fournisseur': instance.fournisseur,
  'delai_livraison_jours': instance.delaiLivraison,
  'date_livraison': instance.dateLivraison?.toIso8601String(),
  'stock_securite': instance.stockSecurite,
  'stock_securite_simple': instance.stockSecuriteSimple,
  'delai_securite_jours': instance.delaiSecurite,
  'periode_commande_jours': instance.periodeCommande,
  'stock_maximum': instance.stockMaximum,
  'couverture_jours': instance.couverture,
  'dvr_max': instance.dvrMax,
  'qte_a_risque': instance.qteARisque,
  'valeur_a_risque': instance.valeurARisque,
  'lots': instance.lots,
};

_Laboratoire _$LaboratoireFromJson(Map<String, dynamic> json) => _Laboratoire(
  labo: json['labo'] as String,
  produitsActifs: (json['produits_actifs'] as num?)?.toInt() ?? 0,
  produitsEnStock: (json['produits_en_stock'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$LaboratoireToJson(_Laboratoire instance) => <String, dynamic>{
  'labo': instance.labo,
  'produits_actifs': instance.produitsActifs,
  'produits_en_stock': instance.produitsEnStock,
};

_PageProduits _$PageProduitsFromJson(Map<String, dynamic> json) => _PageProduits(
  total: (json['total'] as num?)?.toInt() ?? 0,
  items:
      (json['items'] as List<dynamic>?)?.map((e) => Produit.fromJson(e as Map<String, dynamic>)).toList() ??
      const <Produit>[],
);

Map<String, dynamic> _$PageProduitsToJson(_PageProduits instance) => <String, dynamic>{
  'total': instance.total,
  'items': instance.items,
};

_Compteurs _$CompteursFromJson(Map<String, dynamic> json) => _Compteurs(
  ruptures: (json['ruptures'] as num?)?.toInt() ?? 0,
  sousSeuil: (json['sous_seuil'] as num?)?.toInt() ?? 0,
  aCommander: (json['a_commander'] as num?)?.toInt() ?? 0,
  aRisque: (json['a_risque'] as num?)?.toInt() ?? 0,
  valeurARisque: (json['valeur_a_risque'] as num?)?.toDouble() ?? 0,
  surstock: (json['surstock'] as num?)?.toInt() ?? 0,
  valeurSurstock: (json['valeur_surstock'] as num?)?.toDouble() ?? 0,
);

Map<String, dynamic> _$CompteursToJson(_Compteurs instance) => <String, dynamic>{
  'ruptures': instance.ruptures,
  'sous_seuil': instance.sousSeuil,
  'a_commander': instance.aCommander,
  'a_risque': instance.aRisque,
  'valeur_a_risque': instance.valeurARisque,
  'surstock': instance.surstock,
  'valeur_surstock': instance.valeurSurstock,
};

_ATraiter _$ATraiterFromJson(Map<String, dynamic> json) => _ATraiter(
  compteurs: json['compteurs'] == null
      ? const Compteurs()
      : Compteurs.fromJson(json['compteurs'] as Map<String, dynamic>),
  aCommander:
      (json['a_commander'] as List<dynamic>?)?.map((e) => Produit.fromJson(e as Map<String, dynamic>)).toList() ??
      const <Produit>[],
  aRisque:
      (json['a_risque'] as List<dynamic>?)?.map((e) => Produit.fromJson(e as Map<String, dynamic>)).toList() ??
      const <Produit>[],
  surstock:
      (json['surstock'] as List<dynamic>?)?.map((e) => Produit.fromJson(e as Map<String, dynamic>)).toList() ??
      const <Produit>[],
);

Map<String, dynamic> _$ATraiterToJson(_ATraiter instance) => <String, dynamic>{
  'compteurs': instance.compteurs,
  'a_commander': instance.aCommander,
  'a_risque': instance.aRisque,
  'surstock': instance.surstock,
};

_Consommable _$ConsommableFromJson(Map<String, dynamic> json) => _Consommable(
  id: (json['id'] as num).toInt(),
  nom: json['nom'] as String? ?? '',
  dosage: json['dosage'] as String?,
  formeAbr: json['forme_abr'] as String?,
  idFamille: (json['id_famille'] as num?)?.toInt(),
  confirme: json['confirme'] as bool? ?? false,
  stock: (json['stock'] as num?)?.toInt() ?? 0,
  unitesAjustees: (json['unites_ajustees_12m'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ConsommableToJson(_Consommable instance) => <String, dynamic>{
  'id': instance.id,
  'nom': instance.nom,
  'dosage': instance.dosage,
  'forme_abr': instance.formeAbr,
  'id_famille': instance.idFamille,
  'confirme': instance.confirme,
  'stock': instance.stock,
  'unites_ajustees_12m': instance.unitesAjustees,
};
