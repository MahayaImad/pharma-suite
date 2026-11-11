// Modèles et règles du module stock — Dart pur, sans Flutter.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock.freezed.dart';
part 'stock.g.dart';

/// Une famille de produits et ses effectifs (`GET /stock/resume`).
/// [id] est null pour « Sans famille ».
@freezed
abstract class FamilleStock with _$FamilleStock {
  const factory FamilleStock({
    int? id,
    required String famille,
    @JsonKey(name: 'produits_actifs') @Default(0) int produitsActifs,
    @JsonKey(name: 'produits_en_stock') @Default(0) int produitsEnStock,
  }) = _FamilleStock;

  factory FamilleStock.fromJson(Map<String, dynamic> json) => _$FamilleStockFromJson(json);
}

/// En-tête des écrans stock.
@freezed
abstract class ResumeStock with _$ResumeStock {
  const factory ResumeStock({
    /// Heure du dernier calcul du stock, en UTC ; null s'il n'a jamais eu lieu.
    @JsonKey(name: 'donnees_du') DateTime? donneesDu,
    @JsonKey(name: 'produits_actifs') @Default(0) int produitsActifs,
    @JsonKey(name: 'produits_en_stock') @Default(0) int produitsEnStock,
    @JsonKey(name: 'valeur_achat') @Default(0) double valeurAchat,
    @JsonKey(name: 'valeur_vente') @Default(0) double valeurVente,
    @Default(<FamilleStock>[]) List<FamilleStock> familles,
  }) = _ResumeStock;

  factory ResumeStock.fromJson(Map<String, dynamic> json) => _$ResumeStockFromJson(json);
}

/// Un produit, tel que le donnent la liste et la fiche.
@freezed
abstract class Produit with _$Produit {
  const Produit._();

  const factory Produit({
    required int id,
    @Default('') String nom,
    String? dci,
    String? dosage,
    String? forme,
    @JsonKey(name: 'forme_abr') String? formeAbr,
    @JsonKey(name: 'id_famille') int? idFamille,
    String? famille,
    String? labo,
    @JsonKey(name: 'code_barre_original') String? codeBarre,
    String? conditionnement,
    @Default(0) double stock,
    @JsonKey(name: 'qte_alerte') int? seuil,
    @JsonKey(name: 'prix_vente') @Default(0) double prixVente,
    @JsonKey(name: 'prix_achat_moyen') @Default(0) double prixAchat,
    @JsonKey(name: 'valeur_achat') @Default(0) double valeurAchat,
    @JsonKey(name: 'valeur_vente') @Default(0) double valeurVente,
    @JsonKey(name: 'qte_vendue_12m') int? vendu12Mois,
    @JsonKey(name: 'derniere_vente') DateTime? derniereVente,
    @Default(false) bool actif,
    @JsonKey(name: 'segment_abc') String? classeAbc,
    @JsonKey(name: 'segment_xyz') String? classeXyz,
    String? categorie,
    String? disponibilite,
    int? psychotrope,
    @JsonKey(name: 'remb_cvm') int? remboursable,
  }) = _Produit;

  factory Produit.fromJson(Map<String, dynamic> json) => _$ProduitFromJson(json);

  /// « DOLIPRANE 1000 MG CPR » : nom, dosage s'il n'y est pas déjà, forme.
  String get designation {
    final morceaux = [nom];
    if (dosage != null && dosage!.isNotEmpty && !nom.contains(dosage!)) morceaux.add(dosage!);
    if (formeAbr != null && formeAbr!.isNotEmpty) morceaux.add(formeAbr!);
    return morceaux.join(' ');
  }

  EtatStock get etat => etatStock(
      stock: stock, seuil: seuil, actif: actif, quota: disponibilite == 'quota');
}

/// Un lot (ligne de `entrees_produits`).
@freezed
abstract class Lot with _$Lot {
  const factory Lot({
    required int id,
    String? lot,
    /// Texte EASYPHARM, format MM/YY.
    String? peremption,
    @JsonKey(name: 'peremption_date') DateTime? peremptionDate,
    @Default(0) int stock,
    @JsonKey(name: 'qte_entree') @Default(0) int qteEntree,
    @JsonKey(name: 'prix_achat') @Default(0) double prixAchat,
    @JsonKey(name: 'prix_vente') @Default(0) double prixVente,
    String? fournisseur,
    @JsonKey(name: 'date_entree') DateTime? dateEntree,
    @JsonKey(name: 'num_bl') String? numBl,
    @JsonKey(fromJson: _versBool) @Default(false) bool bloque,
  }) = _Lot;

  factory Lot.fromJson(Map<String, dynamic> json) => _$LotFromJson(json);
}

/// `bloque` arrive en booléen ou en 0/1 selon la source.
bool _versBool(Object? v) => v == true || v == 1 || v == '1';

/// Risque de péremption d'un lot, calculé en FEFO par l'API.
@freezed
abstract class RisqueLot with _$RisqueLot {
  const factory RisqueLot({
    required int id,
    /// Durée de vie restante en jours ; null si la date est inconnue.
    int? dvr,
    /// Ce que le lot vendra avant sa péremption ; null s'il est hors calcul
    /// (bloqué, sans date).
    int? ecoulable,
    @JsonKey(name: 'a_risque') int? aRisque,
    @JsonKey(name: 'valeur_a_risque') double? valeurARisque,
  }) = _RisqueLot;

  factory RisqueLot.fromJson(Map<String, dynamic> json) => _$RisqueLotFromJson(json);
}

/// Fournisseur principal d'un produit (celui de la dernière entrée).
@freezed
abstract class FournisseurPrincipal with _$FournisseurPrincipal {
  const factory FournisseurPrincipal({
    int? id,
    String? nom,
    @JsonKey(name: 'delai_jours_ouvres') @Default(1) int delaiJoursOuvres,
    /// Faux : délai par défaut des réglages, non saisi pour ce fournisseur.
    @JsonKey(name: 'delai_saisi') @Default(false) bool delaiSaisi,
  }) = _FournisseurPrincipal;

  factory FournisseurPrincipal.fromJson(Map<String, dynamic> json) =>
      _$FournisseurPrincipalFromJson(json);
}

/// Indicateurs de gestion d'un produit (`GET /stock/products/{id}/indicateurs`).
/// Définitions : docs/05-stock-guide.md, section 5.
@freezed
abstract class IndicateursProduit with _$IndicateursProduit {
  const IndicateursProduit._();

  const factory IndicateursProduit({
    @JsonKey(name: 'ventes_12_mois') @Default(0) double ventes12Mois,
    @JsonKey(name: 'mois_historique') @Default(12) int moisHistorique,
    @Default(0) double cmm,
    @Default(0) double cmj,
    FournisseurPrincipal? fournisseur,
    @JsonKey(name: 'delai_livraison_jours') @Default(1) int delaiLivraison,
    @JsonKey(name: 'date_livraison') DateTime? dateLivraison,
    @JsonKey(name: 'stock_securite') @Default(0) int stockSecurite,
    @JsonKey(name: 'stock_securite_simple') @Default(0) int stockSecuriteSimple,
    @JsonKey(name: 'delai_securite_jours') @Default(0) double delaiSecurite,
    @JsonKey(name: 'periode_commande_jours') @Default(0) double periodeCommande,
    @JsonKey(name: 'stock_maximum') @Default(0) int stockMaximum,
    @JsonKey(name: 'couverture_jours') int? couverture,
    @JsonKey(name: 'dvr_max') int? dvrMax,
    @JsonKey(name: 'qte_a_risque') @Default(0) int qteARisque,
    @JsonKey(name: 'valeur_a_risque') @Default(0) double valeurARisque,
    @Default(<RisqueLot>[]) List<RisqueLot> lots,
  }) = _IndicateursProduit;

  factory IndicateursProduit.fromJson(Map<String, dynamic> json) => _$IndicateursProduitFromJson(json);

  /// La couverture dépasse la durée de vie du lot le plus long : une partie
  /// du stock périmera avant d'être vendue.
  bool get couvertureTropLongue => couverture != null && dvrMax != null && couverture! > dvrMax!;

  RisqueLot? risque(int idLot) => lots.where((l) => l.id == idLot).firstOrNull;
}

/// Une page de la liste des produits.
@freezed
abstract class PageProduits with _$PageProduits {
  const factory PageProduits({
    @Default(0) int total,
    @Default(<Produit>[]) List<Produit> items,
  }) = _PageProduits;

  factory PageProduits.fromJson(Map<String, dynamic> json) => _$PageProduitsFromJson(json);
}

/// Filtre `etat` de `GET /stock/products`.
enum FiltreEtat {
  enStock('en_stock', 'En stock'),
  sousSeuil('sous_seuil', 'Sous le seuil'),
  rupture('rupture', 'Rupture');

  const FiltreEtat(this.api, this.libelle);
  final String api, libelle;
}

/// Ordre de la liste (`tri`).
enum TriProduits {
  nom('nom', 'Nom'),
  stock('stock', 'Stock'),
  valeur('valeur', 'Valeur'),
  derniereVente('derniere_vente', 'Dernière vente');

  const TriProduits(this.api, this.libelle);
  final String api, libelle;
}

/// Ce que l'utilisateur a choisi au-dessus de la liste.
@freezed
abstract class FiltreProduits with _$FiltreProduits {
  const factory FiltreProduits({
    @Default('') String recherche,
    int? idFamille,
    FiltreEtat? etat,
    @Default(TriProduits.nom) TriProduits tri,
  }) = _FiltreProduits;
}

// ── Règles ─────────────────────────────────────────────────────────────────

/// État de stock d'un produit, avec les mêmes règles que l'API
/// (`/stock/alerts`, `etat=`) : une rupture ne concerne qu'un produit actif,
/// « sous le seuil » veut dire strictement sous `qte_alerte`.
enum EtatStock { enStock, sousSeuil, rupture, quota, inactif }

EtatStock etatStock({required double stock, int? seuil, required bool actif, bool quota = false}) {
  if (quota && stock <= (seuil ?? 0)) return EtatStock.quota;
  if (stock <= 0) return actif ? EtatStock.rupture : EtatStock.inactif;
  if (seuil != null && seuil > 0 && stock < seuil) return EtatStock.sousSeuil;
  return EtatStock.enStock;
}

/// Taux de marge sur le prix d'achat : (PV − PA) ÷ PA, en %. C'est la
/// lecture de la réglementation algérienne des marges. Null si PA inconnu.
double? tauxMarge(double prixVente, double prixAchat) {
  if (prixAchat <= 0 || prixVente <= 0) return null;
  return (prixVente - prixAchat) / prixAchat * 100;
}

/// Péremption d'un lot, vue du jour [aujourdhui].
enum EtatPeremption { perime, proche, bonne, inconnue }

/// Un lot daté MM/YY est bon jusqu'à la fin de ce mois. « Proche » : moins
/// de 3 mois (règle `ventes_peremption_3` et alertes péremption).
EtatPeremption etatPeremption(DateTime? peremption, DateTime aujourdhui) {
  if (peremption == null) return EtatPeremption.inconnue;
  final finDuMois = DateTime(peremption.year, peremption.month + 1, 1);
  final jour = DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day);
  if (!finDuMois.isAfter(jour)) return EtatPeremption.perime;
  if (finDuMois.isBefore(DateTime(jour.year, jour.month + 3, jour.day))) return EtatPeremption.proche;
  return EtatPeremption.bonne;
}
