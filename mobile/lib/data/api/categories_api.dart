import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/categories.dart';
import 'client_api.dart';

/// Catégories de prime (`/categories`, réponses `{data, error}`), titulaire seulement. Lève [ErreurApi].
abstract interface class CategoriesApi {
  Future<PrimeCategories> mois(int annee, int mois);
  Future<PageLaboratoires> laboratoires(int annee, int mois, {String? recherche, int limite = 6});
  Future<List<ProduitCategorie>> produits(int annee, int mois);
  Future<void> marquerLaboratoire(int id, bool generique);

  /// [categorie] null rend le produit au classement automatique.
  Future<void> choisir(int idNom, String? categorie);
  Future<ResultatClassement> classer(double seuilMarge, {bool tout = false});
}

class CategoriesApiDio implements CategoriesApi {
  CategoriesApiDio(this._dio);
  final Dio _dio;

  Future<T> _appel<T>(Future<Response<Object?>> Function() requete, T Function(Object? data) lire) async {
    try {
      final r = await requete();
      final corps = r.data;
      return lire(corps is Map<String, dynamic> && corps.containsKey('data') ? corps['data'] : corps);
    } on DioException catch (e) {
      final corps = e.response?.data;
      if (corps is Map && corps['error'] is Map) {
        throw ErreurApi((corps['error'] as Map)['message'] as String? ?? 'Erreur.');
      }
      if (corps is Map && corps['detail'] is String) throw ErreurApi(corps['detail'] as String);
      throw ErreurApi.depuis(e);
    } catch (e) {
      throw ErreurApi.depuis(e);
    }
  }

  static final _long = Options(receiveTimeout: const Duration(minutes: 3));

  @override
  Future<PrimeCategories> mois(int annee, int mois) =>
      _appel(() => _dio.get('/categories/$annee/$mois'), (d) => PrimeCategories.fromJson(d as Map<String, dynamic>));

  @override
  Future<PageLaboratoires> laboratoires(int annee, int mois, {String? recherche, int limite = 6}) => _appel(
    () => _dio.get(
      '/categories/$annee/$mois/laboratoires',
      queryParameters: {'limite': limite, if (recherche != null && recherche.isNotEmpty) 'q': recherche},
    ),
    (d) => PageLaboratoires.fromJson(d as Map<String, dynamic>),
  );

  @override
  Future<List<ProduitCategorie>> produits(int annee, int mois) => _appel(
    () => _dio.get('/categories/$annee/$mois/produits'),
    (d) => [for (final p in d as List) ProduitCategorie.fromJson(p as Map<String, dynamic>)],
  );

  @override
  Future<void> marquerLaboratoire(int id, bool generique) =>
      _appel(() => _dio.put('/categories/laboratoires/$id', data: {'generique': generique}), (_) {});

  @override
  Future<void> choisir(int idNom, String? categorie) =>
      _appel(() => _dio.put('/categories/produits/$idNom', data: {'categorie': categorie}), (_) {});

  @override
  Future<ResultatClassement> classer(double seuilMarge, {bool tout = false}) => _appel(
    () => _dio.post('/categories/classer', data: {'seuil_marge': seuilMarge, 'tout': tout}, options: _long),
    (d) => ResultatClassement.fromJson(d as Map<String, dynamic>),
  );
}

final categoriesApiProvider = Provider<CategoriesApi>((ref) => CategoriesApiDio(ref.watch(dioProvider)));
