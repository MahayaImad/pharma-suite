import 'package:flutter_test/flutter_test.dart';
import 'package:pharmasuite/domain/format.dart';
import 'package:pharmasuite/domain/stock.dart';

void main() {
  group('état du stock (mêmes règles que l\'API)', () {
    test('en stock, sous le seuil (strictement), rupture, inactif', () {
      expect(etatStock(stock: 10, seuil: 5, actif: true), EtatStock.enStock);
      expect(etatStock(stock: 5, seuil: 5, actif: true), EtatStock.enStock); // pas « < »
      expect(etatStock(stock: 4, seuil: 5, actif: true), EtatStock.sousSeuil);
      expect(etatStock(stock: 4, seuil: 0, actif: true), EtatStock.enStock); // seuil non défini
      expect(etatStock(stock: 0, seuil: 5, actif: true), EtatStock.rupture);
      expect(etatStock(stock: 0, actif: false), EtatStock.inactif); // pas une rupture
      expect(etatStock(stock: 2, seuil: 5, actif: true, quota: true), EtatStock.quota);
    });
  });

  test('taux de marge sur le prix d\'achat', () {
    expect(tauxMarge(150, 100), 50);
    expect(tauxMarge(150, 0), isNull);
  });

  group('péremption MM/YY : bonne jusqu\'à la fin du mois', () {
    final jour = DateTime(2026, 11, 11);
    test('cas', () {
      expect(etatPeremption(DateTime(2026, 11, 1), jour), EtatPeremption.proche); // finit le 30/11
      expect(etatPeremption(DateTime(2026, 10, 1), jour), EtatPeremption.perime);
      expect(etatPeremption(DateTime(2027, 1, 1), jour), EtatPeremption.proche); // fin janvier < 11/02
      expect(etatPeremption(DateTime(2027, 2, 1), jour), EtatPeremption.bonne); // fin février > 11/02
      expect(etatPeremption(null, jour), EtatPeremption.inconnue);
    });
  });

  group('mise en forme', () {
    test('montants', () {
      expect(entier(1234567), '1 234 567');
      expect(dinars(185), '185 DA');
      expect(dinars(12.5), '12,50 DA');
      expect(dinars(1250), '1 250 DA');
      expect(dinarsCourt(15900000), '15,9 M DA');
      expect(dinarsCourt(2000000), '2 M DA');
      expect(dinarsCourt(830400), '830 k DA');
      expect(pourcent(42.857), '42,9 %');
      expect(pourcent(50), '50 %');
    });

    test('heure d\'Alger (UTC+1) et horodatage', () {
      final maintenant = DateTime.utc(2026, 11, 11, 15);
      expect(horodatage(DateTime.utc(2026, 11, 11, 13, 32), maintenant), "aujourd'hui à 14:32");
      // 23:30 UTC le 10 = 00:30 le 11 à Alger : c'est aujourd'hui.
      expect(horodatage(DateTime.utc(2026, 11, 10, 23, 30), maintenant), "aujourd'hui à 00:30");
      expect(horodatage(DateTime.utc(2026, 11, 10, 9), maintenant), 'hier à 10:00');
      expect(horodatage(DateTime.utc(2026, 11, 2, 9), maintenant), 'le 02/11 à 10:00');
    });

    test('ancienneté d\'une vente', () {
      final j = DateTime(2026, 11, 11);
      expect(depuis(DateTime(2026, 11, 11), j), "aujourd'hui");
      expect(depuis(DateTime(2026, 11, 10), j), 'hier');
      expect(depuis(DateTime(2026, 11, 1), j), 'il y a 10 jours');
      expect(depuis(DateTime(2026, 7, 1), j), 'il y a 4 mois');
      expect(depuis(DateTime(2024, 1, 1), j), 'il y a 2 ans');
    });

    test('libellés de famille saisis en capitales', () {
      expect(libelle('BEBE ET MAMAN'), 'Bebe et maman');
      expect(libelle('Médicaments'), 'Médicaments');
      expect(duree(12), '12 jours');
      expect(duree(90), '3 mois');
      expect(duree(400), "plus d'un an");
    });
  });

  test('désignation : le dosage n\'est pas répété', () {
    expect(
      const Produit(id: 1, nom: 'DOLIPRANE', dosage: '1000 MG', formeAbr: 'CPR').designation,
      'DOLIPRANE 1000 MG CPR',
    );
    expect(const Produit(id: 1, nom: 'DOLIPRANE 1000 MG', dosage: '1000 MG').designation, 'DOLIPRANE 1000 MG');
  });

  test('lecture JSON de l\'API', () {
    final p = Produit.fromJson({
      'id': 7,
      'nom': 'X',
      'stock': 3.0,
      'qte_alerte': 5,
      'prix_vente': 120.0,
      'id_famille': 15,
      'famille': 'BEBE ET MAMAN',
      'actif': true,
      'derniere_vente': '2026-11-10',
    });
    expect((p.etat, p.idFamille, p.derniereVente), (EtatStock.sousSeuil, 15, DateTime(2026, 11, 10)));
    final l = Lot.fromJson({'id': 1, 'stock': 4, 'bloque': 1, 'peremption_date': '2027-03-01'});
    expect((l.bloque, l.peremptionDate), (true, DateTime(2027, 3, 1)));
  });

  group('projection du stock (FEFO)', () {
    test('lots vendus dans l\'ordre, perte à la péremption', () {
      // CMJ 2 : lot A 30 u (DVR 19) vendu en 15 j ; lot C 100 u (DVR 81) :
      // vendu de j15 à j81 → 132 u possibles ≥ 100 → épuisé à j65.
      final p = projectionStock([(stock: 100, dvr: 81), (stock: 30, dvr: 19)], 2);
      expect(p, [(jour: 0.0, stock: 130.0), (jour: 15.0, stock: 100.0), (jour: 65.0, stock: 0.0)]);
    });

    test('lot qui ne sera pas vendu à temps : chute à sa péremption', () {
      // CMJ 0,05, 9 u, DVR 81 → 4,05 vendues, 4,95 perdues à j81
      final p = projectionStock([(stock: 9, dvr: 81)], 0.05);
      expect(p.length, 3);
      expect(p[1].jour, 81);
      expect(p[1].stock, closeTo(4.95, 1e-9));
      expect(p[2], (jour: 81.0, stock: 0.0));
    });

    test('sans vente : rien ne baisse avant la péremption', () {
      expect(projectionStock([(stock: 6, dvr: 40)], 0), [
        (jour: 0.0, stock: 6.0),
        (jour: 40.0, stock: 6.0),
        (jour: 40.0, stock: 0.0),
      ]);
      expect(projectionStock([(stock: 6, dvr: null)], 0), [(jour: 0.0, stock: 6.0)]);
    });
  });

  group('conseil', () {
    const i = IndicateursProduit(cmm: 30, cmj: 1, stockSecurite: 5, stockMaximum: 40, couverture: 20);
    test('péremption d\'abord, puis rupture, stock bas, surstock, rien', () {
      expect(
        conseil(const Produit(id: 1, stock: 20, actif: true), i.copyWith(qteARisque: 3)).niveau,
        NiveauConseil.risque,
      );
      expect(conseil(const Produit(id: 1, stock: 0, actif: true), i).niveau, NiveauConseil.urgent);
      expect(conseil(const Produit(id: 1, stock: 3, actif: true), i).niveau, NiveauConseil.attention);
      expect(conseil(const Produit(id: 1, stock: 90, actif: true), i).niveau, NiveauConseil.info);
      expect(conseil(const Produit(id: 1, stock: 20, actif: true), i).niveau, NiveauConseil.bon);
    });
  });

  test('noms lisibles', () {
    expect(libelleProduit('DOLIPRANE 1000 MG'), 'Doliprane 1000 mg');
    expect(libelleProduit('LA ROCHE-POSAY'), 'La Roche-Posay');
    expect(libelleProduit('MAGNE B6'), 'Magne B6');
    expect(libelleProduit('AMOXICILLINE 500MG'), 'Amoxicilline 500mg');
    expect(libelleProduit('LAIT DE CROISSANCE ET CEREALES'), 'Lait de Croissance et Cereales');
    expect(libelleProduit('Déjà lisible'), 'Déjà lisible');
  });

  test('signal : un problème de stock passe avant la péremption', () {
    expect(const Produit(id: 1, stock: 0, actif: true, qteARisque: 2).signal, Signal.rupture);
    expect(const Produit(id: 1, stock: 9, actif: true, qteARisque: 2).signal, Signal.risque);
    expect(const Produit(id: 1, stock: 9, actif: true, qteSurstock: 2).signal, Signal.surstock);
    expect(const Produit(id: 1, stock: 9, actif: true).signal, Signal.ok);
  });
}
