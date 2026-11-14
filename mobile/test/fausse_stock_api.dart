import 'package:pharmasuite/data/api/client_api.dart';
import 'package:pharmasuite/data/api/stock_api.dart';
import 'package:pharmasuite/domain/stock.dart';

/// API stock simulée, avec quelques produits vraisemblables.
class FausseStockApi implements StockApi {
  FausseStockApi({this.panne = false, List<Produit>? produits}) : _produits = List.of(produits ?? exemples);

  bool panne;
  final List<Produit> _produits;
  final demandes = <FiltreProduits>[];

  static final exemples = [
    Produit(
      id: 1,
      nom: 'DOLIPRANE',
      dosage: '1000 MG',
      formeAbr: 'CPR',
      dci: 'Paracétamol',
      labo: 'SANOFI',
      idFamille: 1,
      famille: 'Médicaments',
      stock: 48,
      seuil: 20,
      prixVente: 185,
      prixAchat: 130,
      valeurAchat: 6240,
      valeurVente: 8880,
      vendu12Mois: 612,
      actif: true,
      classeAbc: 'A',
      classeXyz: 'X',
      derniereVente: DateTime.now().subtract(const Duration(days: 1)),
      remboursable: 1,
      cmm: 51,
      stockSecurite: 7,
      stockMaximum: 19,
      couverture: 28,
      qteARisque: 5,
      valeurARisque: 650,
    ),
    Produit(
      id: 2,
      nom: 'AUGMENTIN',
      dosage: '1 G',
      formeAbr: 'SACH',
      dci: 'Amoxicilline',
      labo: 'GSK',
      idFamille: 1,
      famille: 'Médicaments',
      stock: 3,
      seuil: 10,
      prixVente: 920,
      prixAchat: 700,
      actif: true,
      classeAbc: 'B',
      vendu12Mois: 90,
      cmm: 7.5,
      stockSecurite: 4,
      stockMaximum: 12,
      couverture: 12,
    ),
    const Produit(
      id: 3,
      nom: 'BIOGAIA',
      formeAbr: 'GTT',
      labo: 'BIOGAIA',
      idFamille: 15,
      famille: 'BEBE ET MAMAN',
      stock: 0,
      actif: true,
      prixVente: 1450,
      cmm: 3,
    ),
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
      if (filtre.labo != null && (p.labo ?? '').toUpperCase() != filtre.labo) return false;
      return switch (filtre.etat) {
        null => true,
        FiltreEtat.enStock => p.stock > 0,
        FiltreEtat.sousSeuil => p.etat == EtatStock.sousSeuil,
        FiltreEtat.rupture => p.etat == EtatStock.rupture,
        FiltreEtat.aCommander => p.etat == EtatStock.rupture || p.etat == EtatStock.sousSeuil,
        FiltreEtat.aRisque => p.qteARisque > 0,
        FiltreEtat.surstock => p.qteSurstock > 0,
      };
    }).toList();
    return PageProduits(total: retenus.length, items: retenus.skip(offset).take(limite).toList());
  }

  @override
  Future<Produit> fiche(int id) async {
    if (panne) throw const ErreurApi('Le serveur ne répond pas.', reseau: true);
    return _produits.firstWhere((p) => p.id == id);
  }

  final decisionsConsommable = <(int, bool)>[];
  final consommablesEnBase = <Consommable>[
    const Consommable(id: 21, nom: 'AIGUILLES INSUPEN', unitesAjustees: 600, stock: 120),
    const Consommable(id: 22, nom: 'SACHETS', unitesAjustees: 900, stock: 300),
    const Consommable(id: 23, nom: 'LECTEUR GLYCEMIE', confirme: true, unitesAjustees: 40, stock: 6),
  ];

  @override
  Future<List<Laboratoire>> laboratoires() async => const [
    Laboratoire(labo: 'SANOFI', produitsActifs: 2),
    Laboratoire(labo: 'SAIDAL', produitsActifs: 1),
  ];

  @override
  Future<List<Consommable>> consommables() async {
    if (panne) throw const ErreurApi('Le serveur ne répond pas.', reseau: true);
    return List.of(consommablesEnBase);
  }

  @override
  Future<void> deciderConsommable(int id, bool consommable) async {
    decisionsConsommable.add((id, consommable));
    final k = consommablesEnBase.indexWhere((c) => c.id == id);
    if (k >= 0) {
      if (consommable) {
        consommablesEnBase[k] = consommablesEnBase[k].copyWith(confirme: true);
      } else {
        consommablesEnBase.removeAt(k);
      }
    }
    final i = _produits.indexWhere((p) => p.id == id);
    if (i >= 0) _produits[i] = _produits[i].copyWith(consommable: consommable, consommablePropose: false);
  }

  @override
  Future<ATraiter> aTraiter() async {
    if (panne) throw const ErreurApi('Le serveur ne répond pas.', reseau: true);
    return ATraiter(
      compteurs: const Compteurs(ruptures: 1, sousSeuil: 1, aCommander: 2, aRisque: 1, valeurARisque: 650),
      aCommander: [exemples[2], exemples[1]],
      aRisque: [exemples[0]],
    );
  }

  @override
  Future<IndicateursProduit> indicateurs(int id) async {
    if (panne) throw const ErreurApi('Le serveur ne répond pas.', reseau: true);
    return IndicateursProduit(
      ventes12Mois: 612,
      cmm: 51,
      cmj: 1.7,
      fournisseur: const FournisseurPrincipal(nom: 'HYDRAPHARM', delaiSaisi: true),
      delaiLivraison: 3,
      dateLivraison: DateTime(2026, 11, 15),
      stockSecurite: 7,
      stockSecuriteSimple: 4,
      delaiSecurite: 2,
      periodeCommande: 7,
      stockMaximum: 19,
      couverture: 28,
      dvrMax: 400,
      qteARisque: 5,
      valeurARisque: 650,
      lots: const [
        RisqueLot(id: 10, stock: 5, dvr: 0, ecoulable: 0, aRisque: 5),
        RisqueLot(id: 11, stock: 43, dvr: 750, ecoulable: 43, aRisque: 0),
      ],
    );
  }

  @override
  Future<List<Lot>> lots(int id, {bool epuises = false}) async => [
    Lot(
      id: 10,
      lot: 'C7781',
      peremption: '01/26',
      peremptionDate: DateTime(2026, 1, 1),
      stock: 5,
      fournisseur: 'HYDRAPHARM',
      dateEntree: DateTime(2025, 2, 3),
    ),
    Lot(
      id: 11,
      lot: 'A2341',
      peremption: '12/28',
      peremptionDate: DateTime(2028, 12, 1),
      stock: 43,
      fournisseur: 'BIOPURE',
      numBl: '4512',
    ),
    if (epuises) const Lot(id: 12, lot: 'Z0001', peremption: '03/25', stock: 0),
  ];
}
