import 'package:pharmasuite/data/api/client_api.dart';
import 'package:pharmasuite/data/api/stock_api.dart';
import 'package:pharmasuite/domain/stock.dart';

/// API stock simulée, avec quelques produits vraisemblables.
class FausseStockApi implements StockApi {
  FausseStockApi({this.panne = false, List<Produit>? produits}) : _produits = produits ?? exemples;

  bool panne;
  final List<Produit> _produits;
  final demandes = <FiltreProduits>[];

  static final exemples = [
    Produit(
        id: 1, nom: 'DOLIPRANE', dosage: '1000 MG', formeAbr: 'CPR', dci: 'Paracétamol', labo: 'SANOFI',
        idFamille: 1, famille: 'Médicaments', stock: 48, seuil: 20, prixVente: 185, prixAchat: 130,
        valeurAchat: 6240, valeurVente: 8880, vendu12Mois: 612, actif: true, classeAbc: 'A', classeXyz: 'X',
        derniereVente: DateTime.now().subtract(const Duration(days: 1)), remboursable: 1),
    Produit(
        id: 2, nom: 'AUGMENTIN', dosage: '1 G', formeAbr: 'SACH', dci: 'Amoxicilline', labo: 'GSK',
        idFamille: 1, famille: 'Médicaments', stock: 3, seuil: 10, prixVente: 920, prixAchat: 700,
        actif: true, classeAbc: 'B', vendu12Mois: 90),
    const Produit(
        id: 3, nom: 'BIOGAIA', formeAbr: 'GTT', labo: 'BIOGAIA', idFamille: 15, famille: 'BEBE ET MAMAN',
        stock: 0, actif: true, prixVente: 1450),
  ];

  @override
  Future<ResumeStock> resume() async {
    if (panne) throw const ErreurApi('Le serveur ne répond pas.', reseau: true);
    return ResumeStock(
      donneesDu: DateTime.now().toUtc(),
      produitsActifs: 3,
      produitsEnStock: 2,
      valeurAchat: 15900000,
      valeurVente: 21300000,
      familles: const [
        FamilleStock(id: 1, famille: 'Médicaments', produitsActifs: 2, produitsEnStock: 2),
        FamilleStock(id: 3, famille: 'Cosmétiques'),
        FamilleStock(id: 15, famille: 'BEBE ET MAMAN', produitsActifs: 1),
      ],
    );
  }

  @override
  Future<PageProduits> produits(FiltreProduits filtre, {int offset = 0, int limite = 50}) async {
    demandes.add(filtre);
    if (panne) throw const ErreurApi("Le serveur de l'officine ne répond pas.", reseau: true);
    final q = filtre.recherche.toLowerCase();
    final retenus = _produits.where((p) {
      if (q.isNotEmpty && !p.nom.toLowerCase().contains(q) && !(p.dci ?? '').toLowerCase().contains(q)) {
        return false;
      }
      if (filtre.idFamille != null && p.idFamille != filtre.idFamille) return false;
      return switch (filtre.etat) {
        null => true,
        FiltreEtat.enStock => p.stock > 0,
        FiltreEtat.sousSeuil => p.etat == EtatStock.sousSeuil,
        FiltreEtat.rupture => p.etat == EtatStock.rupture,
      };
    }).toList();
    return PageProduits(total: retenus.length, items: retenus.skip(offset).take(limite).toList());
  }

  @override
  Future<Produit> fiche(int id) async {
    if (panne) throw const ErreurApi('Le serveur ne répond pas.', reseau: true);
    return _produits.firstWhere((p) => p.id == id);
  }

  @override
  Future<List<Lot>> lots(int id, {bool epuises = false}) async => [
        Lot(id: 10, lot: 'C7781', peremption: '01/26', peremptionDate: DateTime(2026, 1, 1), stock: 5,
            fournisseur: 'HYDRAPHARM', dateEntree: DateTime(2025, 2, 3)),
        Lot(id: 11, lot: 'A2341', peremption: '12/28', peremptionDate: DateTime(2028, 12, 1), stock: 43,
            fournisseur: 'BIOPURE', numBl: '4512'),
        if (epuises) const Lot(id: 12, lot: 'Z0001', peremption: '03/25', stock: 0),
      ];
}
