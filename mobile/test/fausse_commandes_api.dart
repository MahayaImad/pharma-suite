import 'package:pharmasuite/data/api/client_api.dart';
import 'package:pharmasuite/data/api/commandes_api.dart';
import 'package:pharmasuite/domain/commandes.dart';

/// Faux serveur des commandes : une journée en mémoire, avec les mêmes
/// règles d'étapes que l'API (brouillon → validée → envoyée).
class FausseCommandesApi implements CommandesApi {
  FausseCommandesApi({this.peutValider = true, this.budget = 3000000, this.panne = false});

  bool peutValider;
  double budget;
  bool panne;
  final appels = <String>[];
  int _prochainId = 100;

  static final jour = DateTime(2026, 11, 14);
  static final dimanche = DateTime(2026, 11, 15);

  static const _raison = Raison(type: 'regulier', rythme: 3.1, joursCouverts: 2, prevu: 6.2, securite: 2, cible: 8.2);

  late List<Panier> paniers = [
    Panier(
      fournisseur: const FournisseurPanier(id: 1, nom: 'GROSSISTE ATLAS', whatsapp: '0550123456'),
      livraisonPrevue: dimanche,
      lignes: const [
        LigneCommande(
          idNom: 11,
          nom: 'PARACETAMOL 1G CPR B/8',
          classeAbc: 'A',
          stock: 0,
          qte: 8,
          qteProposee: 8,
          prixAchat: 96,
          montant: 768,
          raison: _raison,
        ),
        LigneCommande(
          idNom: 12,
          nom: 'AMOXICILLINE 1G CPR B/12',
          classeAbc: 'A',
          stock: 3,
          qte: 6,
          qteProposee: 6,
          prixAchat: 312,
          montant: 1872,
          raison: Raison(type: 'regulier', rythme: 1.8, joursCouverts: 2, securite: 2, cible: 9, stock: 3),
        ),
      ],
    ),
    Panier(
      fournisseur: const FournisseurPanier(id: 2, nom: 'PARA BELLA', type: TypeFournisseur.para),
      livraisonPrevue: dimanche,
      lignes: const [
        LigneCommande(
          idNom: 21,
          nom: 'CREME SOLAIRE SPF50',
          stock: 1,
          qte: 3,
          qteProposee: 3,
          prixAchat: 900,
          montant: 2700,
        ),
      ],
    ),
  ];

  void _verifier() {
    if (panne) throw const ErreurApi("Le serveur de l'officine ne répond pas.", reseau: true);
  }

  JourneeCommandes get _journee => JourneeCommandes(
    jour: jour,
    donneesDu: DateTime.now().toUtc(),
    peutValider: peutValider,
    paniers: paniers,
    psychotropes: const [
      LigneCommande(idNom: 31, nom: 'RIVOTRIL 2MG', qte: 1, qteProposee: 1, fournisseur: 'GROSSISTE ATLAS'),
    ],
    budget: Budget(
      budget: budget,
      recu: 1800000,
      engage: 120000,
      propose: paniers.where((p) => p.commande == null).fold(0.0, (s, p) => s + p.montant),
    ),
  );

  Panier _parCommande(int id) => paniers.firstWhere((p) => p.commande?.id == id);

  void _remplacer(Panier ancien, Panier nouveau) =>
      paniers = [for (final p in paniers) identical(p, ancien) ? nouveau : p];

  void _statut(int id, StatutCommande de, StatutCommande vers) {
    final p = _parCommande(id);
    if (p.commande!.statut != de) throw ErreurApi('Impossible : la commande est « ${p.commande!.statut.name} ».');
    _remplacer(
      p,
      p.copyWith(
        commande: p.commande!.copyWith(statut: vers, validePar: vers == StatutCommande.validee ? 'titulaire' : null),
      ),
    );
  }

  @override
  Future<JourneeCommandes> journee() async {
    _verifier();
    appels.add('journee');
    return _journee;
  }

  @override
  Future<JourneeCommandes> preparer() async {
    _verifier();
    appels.add('preparer');
    paniers = [
      for (final p in paniers)
        p.commande != null
            ? p
            : p.copyWith(
                commande: CommandeEnregistree(
                  id: _prochainId++,
                  jour: jour,
                  statut: StatutCommande.brouillon,
                  livraisonPrevue: dimanche,
                ),
              ),
    ];
    return _journee;
  }

  @override
  Future<void> modifierLigne(int idCommande, int idNom, int qte) async {
    _verifier();
    appels.add('ligne $idCommande $idNom $qte');
    final p = _parCommande(idCommande);
    final existe = p.lignes.any((l) => l.idNom == idNom);
    _remplacer(
      p,
      p.copyWith(
        lignes: [
          for (final l in p.lignes)
            if (l.idNom != idNom) l else if (qte > 0) l.avecQuantite(qte),
          if (!existe && qte > 0)
            LigneCommande(idNom: idNom, nom: 'PRODUIT $idNom', qte: qte, prixAchat: 100, montant: 100.0 * qte),
        ],
      ),
    );
  }

  @override
  Future<void> valider(int idCommande) async {
    appels.add('valider $idCommande');
    _statut(idCommande, StatutCommande.brouillon, StatutCommande.validee);
  }

  @override
  Future<void> rouvrir(int idCommande) async {
    appels.add('rouvrir $idCommande');
    _statut(idCommande, StatutCommande.validee, StatutCommande.brouillon);
  }

  @override
  Future<void> annuler(int idCommande) async {
    appels.add('annuler $idCommande');
    final p = _parCommande(idCommande);
    _remplacer(p, p.copyWith(commande: null));
  }

  @override
  Future<BonCommande> envoyer(int idCommande) async {
    appels.add('envoyer $idCommande');
    final b = await bon(idCommande);
    _statut(idCommande, StatutCommande.validee, StatutCommande.envoyee);
    return b;
  }

  @override
  Future<BonCommande> bon(int idCommande) async {
    final p = _parCommande(idCommande);
    return BonCommande(
      idCommande: idCommande,
      fournisseur: p.fournisseur.nom,
      whatsapp: p.fournisseur.whatsapp,
      texte: [
        'Bon de commande du samedi 14/11/2026',
        'Fournisseur : ${p.fournisseur.nom}',
        '',
        for (final (i, l) in p.lignes.indexed) '${i + 1}. ${l.nom} — ${l.qte}',
      ].join('\n'),
    );
  }

  List<FournisseurReglage> reglages = [
    FournisseurReglage(
      id: 1,
      nom: 'GROSSISTE ATLAS',
      auto: false,
      whatsapp: '0550123456',
      derniereCommande: DateTime.now(),
    ),
    const FournisseurReglage(id: 2, nom: 'PARA BELLA', type: TypeFournisseur.para),
    FournisseurReglage(id: 3, nom: 'ANCIEN GROSSISTE', actif: false, derniereCommande: DateTime(2025, 3, 2)),
  ];
  List<String> listeValideurs = ['karim'];

  @override
  Future<List<FournisseurReglage>> fournisseurs() async => reglages;

  @override
  Future<void> reglerFournisseur(int id, TypeFournisseur type, bool actif, String? whatsapp) async {
    appels.add('regler $id ${type.api} $actif $whatsapp');
    reglages = [
      for (final f in reglages) f.id == id ? f.copyWith(type: type, actif: actif, whatsapp: whatsapp, auto: false) : f,
    ];
  }

  @override
  Future<List<String>> valideurs() async => listeValideurs;

  @override
  Future<void> ajouterValideur(String username) async => listeValideurs = [...listeValideurs, username];

  @override
  Future<void> retirerValideur(String username) async => listeValideurs = [
    for (final u in listeValideurs)
      if (u != username) u,
  ];

  @override
  Future<List<Compte>> comptes() async => const [
    Compte(username: 'titulaire', role: 'admin'),
    Compte(username: 'karim'),
    Compte(username: 'sara', prenom: 'Sara', nom: 'B.'),
  ];
}
