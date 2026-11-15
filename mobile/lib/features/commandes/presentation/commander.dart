import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/api/client_api.dart';
import '../../../data/api/commandes_api.dart';
import '../application/commandes_providers.dart';

/// « Commander » depuis le Stock : ajoute le produit au brouillon du jour de
/// son fournisseur principal (le panier proposé est préparé au besoin), puis
/// propose d'ouvrir ce panier.
Future<void> commanderProduit(BuildContext context, WidgetRef ref, int idNom) async {
  final messager = ScaffoldMessenger.of(context);
  final routeur = GoRouter.of(context);
  messager
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('Ajout à la commande du jour…'), duration: Duration(seconds: 30)));
  try {
    final a = await ref.read(commandesApiProvider).ajouter(idNom);
    ref.invalidate(journeeProvider);
    final chez = a.fournisseur ?? 'son fournisseur';
    messager
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            a.dejaPresent
                ? 'Déjà dans la commande de $chez (${a.qte} boîte${a.qte > 1 ? 's' : ''}).'
                : 'Ajouté à la commande de $chez : ${a.qte} boîte${a.qte > 1 ? 's' : ''}.',
          ),
          action: SnackBarAction(label: 'Voir', onPressed: () => routeur.go('/commandes/${a.idFournisseur}')),
        ),
      );
  } catch (e) {
    messager
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(ErreurApi.depuis(e).message)));
  }
}
