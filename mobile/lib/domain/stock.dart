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
    // Indicateurs de gestion (liste) : jauge et groupes « à traiter ».
    @Default(0) double cmm,
    @JsonKey(name: 'stock_securite') @Default(0) int stockSecurite,
    @JsonKey(name: 'stock_maximum') @Default(0) int stockMaximum,
    @JsonKey(name: 'couverture_jours') int? couverture,
    @JsonKey(name: 'qte_a_risque') @Default(0) int qteARisque,
    @JsonKey(name: 'valeur_a_risque') @Default(0) double valeurARisque,
    @JsonKey(name: 'qte_surstock') @Default(0) int qteSurstock,
    @JsonKey(name: 'valeur_surstock') @Default(0) double valeurSurstock,
  }) = _Produit;

  factory Produit.fromJson(Map<String, dynamic> json) => _$ProduitFromJson(json);

  /// « DOLIPRANE 1000 MG CPR » : nom, dosage s'il n'y est pas déjà, forme.
  String get designation {
    final morceaux = [nom];
    if (dosage != null && dosage!.isNotEmpty && !nom.contains(dosage!)) morceaux.add(dosage!);
    if (formeAbr != null && formeAbr!.isNotEmpty) morceaux.add(formeAbr!);
    return morceaux.join(' ');
  }

  EtatStock get etat => etatStock(stock: stock, seuil: seuil, actif: actif, quota: disponibilite == 'quota');

  /// Ce qui ressort en premier sur la ligne : un problème de stock, sinon
  /// une péremption à risque, sinon un surstock.
  Signal get signal {
    final e = etat;
    if (e == EtatStock.rupture) return Signal.rupture;
    if (e == EtatStock.sousSeuil || e == EtatStock.quota) return Signal.sousSeuil;
    if (qteARisque > 0) return Signal.risque;
    if (qteSurstock > 0) return Signal.surstock;
    if (e == EtatStock.inactif) return Signal.inactif;
    return Signal.ok;
  }
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
    @Default(0) int stock,
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

  factory FournisseurPrincipal.fromJson(Map<String, dynamic> json) => _$FournisseurPrincipalFromJson(json);
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
  const factory PageProduits({@Default(0) int total, @Default(<Produit>[]) List<Produit> items}) =
      _PageProduits;

  factory PageProduits.fromJson(Map<String, dynamic> json) => _$PageProduitsFromJson(json);
}

/// Compteurs et premiers produits de chaque groupe (`GET /stock/a-traiter`).
@freezed
abstract class Compteurs with _$Compteurs {
  const factory Compteurs({
    @Default(0) int ruptures,
    @JsonKey(name: 'sous_seuil') @Default(0) int sousSeuil,
    @JsonKey(name: 'a_commander') @Default(0) int aCommander,
    @JsonKey(name: 'a_risque') @Default(0) int aRisque,
    @JsonKey(name: 'valeur_a_risque') @Default(0) double valeurARisque,
    @Default(0) int surstock,
    @JsonKey(name: 'valeur_surstock') @Default(0) double valeurSurstock,
  }) = _Compteurs;

  factory Compteurs.fromJson(Map<String, dynamic> json) => _$CompteursFromJson(json);
}

@freezed
abstract class ATraiter with _$ATraiter {
  const factory ATraiter({
    @Default(Compteurs()) Compteurs compteurs,
    @JsonKey(name: 'a_commander') @Default(<Produit>[]) List<Produit> aCommander,
    @JsonKey(name: 'a_risque') @Default(<Produit>[]) List<Produit> aRisque,
    @Default(<Produit>[]) List<Produit> surstock,
  }) = _ATraiter;

  factory ATraiter.fromJson(Map<String, dynamic> json) => _$ATraiterFromJson(json);
}

/// Ce que la ligne d'un produit met en avant.
enum Signal { rupture, sousSeuil, risque, surstock, ok, inactif }

/// Filtre `etat` de `GET /stock/products`.
enum FiltreEtat {
  enStock('en_stock', 'En stock'),
  sousSeuil('sous_seuil', 'Sous le seuil'),
  rupture('rupture', 'Ruptures'),
  aCommander('a_commander', 'À commander'),
  aRisque('a_risque', 'Péremption à risque'),
  surstock('surstock', 'Surstock');

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

// ── Projection du stock ────────────────────────────────────────────────────

/// Un point de la courbe de stock : jour (0 = aujourd'hui) et quantité.
typedef PointStock = ({double jour, double stock});

/// Stock dans le temps si l'on vend au rythme [cmj] sans recommander, en
/// FEFO : chaque lot se vend après ceux qui périment avant lui ; à sa
/// péremption, ce qui reste du lot est perdu (chute verticale de la courbe).
/// Les lots sans date se vendent en dernier et ne périment pas.
List<PointStock> projectionStock(List<({int stock, int? dvr})> lots, double cmj, {int horizon = 365}) {
  final dates = lots.where((l) => l.stock > 0).toList()
    ..sort((a, b) => (a.dvr ?? 1 << 30).compareTo(b.dvr ?? 1 << 30));
  var reste = dates.fold<double>(0, (s, l) => s + l.stock);
  final points = <PointStock>[(jour: 0, stock: reste)];
  var t = 0.0;
  for (final l in dates) {
    final duree = cmj > 0 ? l.stock / cmj : double.infinity;
    final limite = l.dvr?.toDouble();
    if (limite == null || t + duree <= limite) {
      if (duree.isInfinite) break;
      t += duree;
      reste -= l.stock;
      points.add((jour: t, stock: reste));
    } else {
      final vendu = limite > t ? cmj * (limite - t) : 0.0;
      if (limite > t) {
        reste -= vendu;
        points.add((jour: limite, stock: reste));
      }
      reste -= l.stock - vendu;
      points.add((jour: _plusGrand(t, limite), stock: reste < 0 ? 0 : reste));
      t = _plusGrand(t, limite);
    }
    if (t >= horizon) break;
  }
  return points;
}

double _plusGrand(double a, double b) => a > b ? a : b;

// ── Conseil ────────────────────────────────────────────────────────────────

enum NiveauConseil { urgent, attention, risque, info, bon }

/// Que faire de ce produit, en une phrase.
({NiveauConseil niveau, String texte}) conseil(Produit p, IndicateursProduit i) {
  final livraison = i.fournisseur?.nom == null ? '' : ' chez ${i.fournisseur!.nom}';
  if (i.qteARisque > 0) {
    return (
      niveau: NiveauConseil.risque,
      texte:
          '${i.qteARisque} unité${i.qteARisque > 1 ? 's' : ''} ne ser${i.qteARisque > 1 ? 'ont' : 'a'} pas '
          'vendue${i.qteARisque > 1 ? 's' : ''} avant leur péremption. Proposez un retour au fournisseur, '
          'un échange avec une pharmacie voisine ou une mise en avant au comptoir. '
          'Ne pas recommander pour l\'instant.',
    );
  }
  if (p.etat == EtatStock.rupture) {
    return (
      niveau: NiveauConseil.urgent,
      texte:
          'En rupture alors qu\'il se vend ${_un(i.cmm)} unité${i.cmm >= 2 ? 's' : ''} par mois. '
          'À commander en priorité$livraison, jusqu\'au stock maximum (${i.stockMaximum}).',
    );
  }
  if (p.stock < i.stockSecurite || p.etat == EtatStock.sousSeuil) {
    return (
      niveau: NiveauConseil.attention,
      texte:
          'Stock bas : ${_un(p.stock)} en stock pour un stock de sécurité de ${i.stockSecurite}. '
          'À commander$livraison, jusqu\'au stock maximum (${i.stockMaximum}).',
    );
  }
  if (i.stockMaximum > 0 && p.stock > i.stockMaximum && i.couverture != null) {
    return (
      niveau: NiveauConseil.info,
      texte:
          'Au-dessus du stock maximum (${i.stockMaximum}) : ${i.couverture} jours de couverture. '
          'Ne pas recommander avant que le stock repasse sous le maximum.',
    );
  }
  if (i.cmm <= 0) {
    return (
      niveau: NiveauConseil.info,
      texte: 'Aucune vente sur 12 mois : stock dormant, à écouler ou retourner.',
    );
  }
  return (
    niveau: NiveauConseil.bon,
    texte: 'Rien à faire : ${i.couverture ?? 0} jours de couverture, au-dessus du stock de sécurité.',
  );
}

String _un(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1).replaceAll('.', ',');
