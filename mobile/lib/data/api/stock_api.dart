import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/stock.dart';
import 'client_api.dart';

/// Lectures du module stock. Lève [ErreurApi].
abstract interface class StockApi {
  /// `GET /stock/resume`.
  Future<ResumeStock> resume();

  /// `GET /stock/products` : produits actifs par défaut.
  Future<PageProduits> produits(FiltreProduits filtre, {int offset = 0, int limite = 50});

  /// `GET /stock/products/{id}`.
  Future<Produit> fiche(int id);

  /// `GET /stock/consommables` : proposés d'abord, puis confirmés.
  Future<List<Consommable>> consommables();

  /// `PUT /stock/products/{id}/consommable` (titulaire).
  Future<void> deciderConsommable(int id, bool consommable);

  /// `GET /stock/a-traiter` : compteurs et premiers produits de chaque groupe.
  Future<ATraiter> aTraiter();

  /// `GET /stock/products/{id}/indicateurs`.
  Future<IndicateursProduit> indicateurs(int id);

  /// `GET /stock/products/{id}/lots`, triés par péremption.
  Future<List<Lot>> lots(int id, {bool epuises = false});
}

class StockApiDio implements StockApi {
  StockApiDio(this._dio);
  final Dio _dio;

  Future<T> _lire<T>(String chemin, T Function(Object? json) lire, {Map<String, dynamic>? parametres}) async {
    try {
      final r = await _dio.get<Object?>(chemin, queryParameters: parametres);
      return lire(r.data);
    } catch (e) {
      throw ErreurApi.depuis(e);
    }
  }

  @override
  Future<ResumeStock> resume() =>
      _lire('/stock/resume', (j) => ResumeStock.fromJson(j as Map<String, dynamic>));

  @override
  Future<PageProduits> produits(FiltreProduits filtre, {int offset = 0, int limite = 50}) {
    final recherche = filtre.recherche.trim();
    return _lire(
      '/stock/products',
      (j) => PageProduits.fromJson(j as Map<String, dynamic>),
      parametres: {
        if (recherche.isNotEmpty) 'q': recherche,
        if (filtre.idFamille != null) 'id_famille': filtre.idFamille,
        // Un filtre d'état suffit à lui-même ; sans lui, les produits actifs.
        if (filtre.etat != null) 'etat': filtre.etat!.api else 'actif': true,
        'tri': filtre.tri.api,
        'limit': limite,
        'offset': offset,
      },
    );
  }

  @override
  Future<Produit> fiche(int id) =>
      _lire('/stock/products/$id', (j) => Produit.fromJson(j as Map<String, dynamic>));

  @override
  Future<List<Consommable>> consommables() => _lire(
    '/stock/consommables',
    (j) => [for (final c in j as List) Consommable.fromJson(c as Map<String, dynamic>)],
  );

  @override
  Future<void> deciderConsommable(int id, bool consommable) async {
    try {
      await _dio.put<Object?>('/stock/products/$id/consommable', data: {'consommable': consommable});
    } catch (e) {
      throw ErreurApi.depuis(e);
    }
  }

  @override
  Future<ATraiter> aTraiter() =>
      _lire('/stock/a-traiter', (j) => ATraiter.fromJson(j as Map<String, dynamic>));

  @override
  Future<IndicateursProduit> indicateurs(int id) =>
      _lire('/stock/products/$id/indicateurs', (j) => IndicateursProduit.fromJson(j as Map<String, dynamic>));

  @override
  Future<List<Lot>> lots(int id, {bool epuises = false}) => _lire(
    '/stock/products/$id/lots',
    (j) => [for (final l in j as List) Lot.fromJson(l as Map<String, dynamic>)],
    parametres: {'in_stock_only': !epuises},
  );
}

final stockApiProvider = Provider<StockApi>((ref) => StockApiDio(ref.watch(dioProvider)));
