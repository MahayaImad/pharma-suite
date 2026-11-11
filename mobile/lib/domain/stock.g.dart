// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FamilleStock _$FamilleStockFromJson(Map<String, dynamic> json) =>
    _FamilleStock(
      id: (json['id'] as num?)?.toInt(),
      famille: json['famille'] as String,
      produitsActifs: (json['produits_actifs'] as num?)?.toInt() ?? 0,
      produitsEnStock: (json['produits_en_stock'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$FamilleStockToJson(_FamilleStock instance) =>
    <String, dynamic>{
      'id': instance.id,
      'famille': instance.famille,
      'produits_actifs': instance.produitsActifs,
      'produits_en_stock': instance.produitsEnStock,
    };

_ResumeStock _$ResumeStockFromJson(Map<String, dynamic> json) => _ResumeStock(
  donneesDu: json['donnees_du'] == null
      ? null
      : DateTime.parse(json['donnees_du'] as String),
  produitsActifs: (json['produits_actifs'] as num?)?.toInt() ?? 0,
  produitsEnStock: (json['produits_en_stock'] as num?)?.toInt() ?? 0,
  valeurAchat: (json['valeur_achat'] as num?)?.toDouble() ?? 0,
  valeurVente: (json['valeur_vente'] as num?)?.toDouble() ?? 0,
  familles:
      (json['familles'] as List<dynamic>?)
          ?.map((e) => FamilleStock.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <FamilleStock>[],
);

Map<String, dynamic> _$ResumeStockToJson(_ResumeStock instance) =>
    <String, dynamic>{
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
  derniereVente: json['derniere_vente'] == null
      ? null
      : DateTime.parse(json['derniere_vente'] as String),
  actif: json['actif'] as bool? ?? false,
  classeAbc: json['segment_abc'] as String?,
  classeXyz: json['segment_xyz'] as String?,
  categorie: json['categorie'] as String?,
  disponibilite: json['disponibilite'] as String?,
  psychotrope: (json['psychotrope'] as num?)?.toInt(),
  remboursable: (json['remb_cvm'] as num?)?.toInt(),
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
};

_Lot _$LotFromJson(Map<String, dynamic> json) => _Lot(
  id: (json['id'] as num).toInt(),
  lot: json['lot'] as String?,
  peremption: json['peremption'] as String?,
  peremptionDate: json['peremption_date'] == null
      ? null
      : DateTime.parse(json['peremption_date'] as String),
  stock: (json['stock'] as num?)?.toInt() ?? 0,
  qteEntree: (json['qte_entree'] as num?)?.toInt() ?? 0,
  prixAchat: (json['prix_achat'] as num?)?.toDouble() ?? 0,
  prixVente: (json['prix_vente'] as num?)?.toDouble() ?? 0,
  fournisseur: json['fournisseur'] as String?,
  dateEntree: json['date_entree'] == null
      ? null
      : DateTime.parse(json['date_entree'] as String),
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

_PageProduits _$PageProduitsFromJson(Map<String, dynamic> json) =>
    _PageProduits(
      total: (json['total'] as num?)?.toInt() ?? 0,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => Produit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Produit>[],
    );

Map<String, dynamic> _$PageProduitsToJson(_PageProduits instance) =>
    <String, dynamic>{'total': instance.total, 'items': instance.items};
