// Commandes fournisseurs : journée, paniers, lignes, budget — Dart pur.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'format.dart';

part 'commandes.freezed.dart';
part 'commandes.g.dart';

enum StatutCommande {
  @JsonValue('brouillon')
  brouillon('Brouillon'),
  @JsonValue('validee')
  validee('Validée'),
  @JsonValue('envoyee')
  envoyee('Envoyée'),
  @JsonValue('annulee')
  annulee('Annulée');

  const StatutCommande(this.libelle);
  final String libelle;
}

enum TypeFournisseur {
  @JsonValue('pharma')
  pharma('Pharmaceutique'),
  @JsonValue('para')
  para('Parapharmaceutique');

  const TypeFournisseur(this.libelle);
  final String libelle;

  String get api => this == TypeFournisseur.pharma ? 'pharma' : 'para';
}

/// Décomposition du calcul d'une quantité proposée.
@freezed
abstract class Raison with _$Raison {
  const factory Raison({
    @Default('') String type,
    @Default(0) double rythme,
    @JsonKey(name: 'jours_couverts') @Default(0) int joursCouverts,
    @Default(0) double prevu,
    @Default(0) double securite,
    @Default(0) double cible,
    @Default(0) double stock,
    @JsonKey(name: 'en_cours') @Default(0) double enCours,

    /// Marques remplacées (génériques) dont ce produit reprend la demande.
    @Default(<String>[]) List<String> reprend,

    /// Générique remplacé à la main par ce produit.
    String? remplace,

    // Mini / maxi (stratégie du 2026-11-16).
    @Default(0) double mini,
    @Default(0) double maxi,
    @Default(0) int couverture,
    @Default(0) int ordonnance,
    @Default(0) int lot,
    @Default(false) bool tension,

    /// Produit lent et cher : pas de stock, commandé à la demande.
    @JsonKey(name: 'sur_demande') @Default(false) bool surDemande,

    /// Pourquoi pas de stock (« Parapharmacie de classe C… »).
    String? motif,

    /// Génériques interchangeables calculés ensemble : code DCI, part de la
    /// marque, stock et maxi du groupe.
    String? groupe,
    @Default(1) double part,
    @JsonKey(name: 'stock_groupe') @Default(0) double stockGroupe,
    @JsonKey(name: 'maxi_groupe') @Default(0) double maxiGroupe,
  }) = _Raison;

  factory Raison.fromJson(Map<String, dynamic> json) => _$RaisonFromJson(json);
}

@freezed
abstract class LigneCommande with _$LigneCommande {
  const LigneCommande._();

  const factory LigneCommande({
    @JsonKey(name: 'id_nom') required int idNom,
    String? nom,
    String? famille,
    @JsonKey(name: 'classe_abc') String? classeAbc,
    @Default(0) int stock,
    required int qte,
    @JsonKey(name: 'qte_proposee') int? qteProposee,
    @JsonKey(name: 'prix_achat') @Default(0) double prixAchat,
    @Default(0) double montant,
    Raison? raison,
    String? fournisseur,

    /// Code DCI : présent si le produit peut avoir des génériques.
    @JsonKey(name: 'code_dci') String? codeDci,

    /// Ce grossiste a été retenu pour ce produit (sinon : celui du dernier achat).
    @JsonKey(name: 'grossiste_prefere') @Default(false) bool grossistePrefere,
  }) = _LigneCommande;

  factory LigneCommande.fromJson(Map<String, dynamic> json) => _$LigneCommandeFromJson(json);

  bool get rupture => stock <= 0;

  /// Produit en tension (quota chez les grossistes) confirmé.
  bool get enTension => raison?.tension ?? false;

  /// Quantité changée à la main (ou produit ajouté à la main).
  bool get modifiee => qteProposee != qte;

  bool get ajoutManuel => qteProposee == null;

  /// Avec une autre quantité : montant recalculé au prix d'achat.
  LigneCommande avecQuantite(int q) => copyWith(qte: q, montant: q * prixAchat);

  /// « 3,1/j × 2 j + sécurité 2 − stock 0 » : pourquoi cette quantité.
  String get explication {
    final r = raison;
    if (r == null) return ajoutManuel ? 'Ajouté à la main' : '';
    final reprise = r.reprend.isEmpty ? '' : ' · reprend ${r.reprend.map(libelleProduit).join(', ')}';
    final remplace = r.remplace == null ? '' : ' · à la place de ${libelleProduit(r.remplace!)}';
    if (r.maxi > 0 || r.mini > 0) {
      // Mini / maxi : « mini 8 · maxi 38 − stock 2 · lot habituel 30 ».
      final groupe = r.groupe != null;
      final stock = groupe ? r.stockGroupe : r.stock + r.enCours;
      final debut = r.type == 'lent'
          ? 'Vente rare : ${r.ordonnance > 1 ? 'une ordonnance de ${r.ordonnance}' : '1 boîte'} en rayon'
          : '${decimal(r.rythme)}/j · mini ${decimal(r.mini, chiffres: 0)} · maxi '
                '${decimal(groupe ? r.maxiGroupe : r.maxi, chiffres: 0)}';
      final morceaux = [
        debut,
        '− ${groupe ? 'stock DCI' : 'stock'} ${entier(stock)}',
        if (r.lot > 0) '· lot habituel ${r.lot}',
        if (r.type != 'lent' && r.ordonnance > 1) '· ordonnance de ${r.ordonnance}',
        if (groupe) '· ${(r.part * 100).round()} % des ventes de la DCI',
        if (r.tension) '· en tension : ${r.couverture} j',
      ];
      return morceaux.join(' ') + reprise + remplace;
    }
    if (r.type == 'lent') return 'Vente lente : garder 1 boîte en rayon';
    final morceaux = [
      '${decimal(r.rythme)}/j × ${r.joursCouverts} j',
      if (r.securite > 0) '+ sécurité ${decimal(r.securite, chiffres: 0)}',
      '− stock ${entier(r.stock)}',
      if (r.enCours > 0) '− en cours ${entier(r.enCours)}',
    ];
    return morceaux.join(' ') + reprise + remplace;
  }
}

/// Libellé du type de demande calculé par le serveur.
String libelleTypeDemande(String type) => switch (type) {
  'regulier' => 'régulier',
  'irregulier' => 'irrégulier',
  'intermittent' => 'intermittent',
  'sporadique' => 'sporadique',
  'lent' => 'lent',
  'nouveau' => 'nouveau',
  _ => type,
};

@freezed
abstract class FournisseurPanier with _$FournisseurPanier {
  const factory FournisseurPanier({
    required int id,
    String? nom,
    @Default(TypeFournisseur.pharma) TypeFournisseur type,
    String? whatsapp,
  }) = _FournisseurPanier;

  factory FournisseurPanier.fromJson(Map<String, dynamic> json) => _$FournisseurPanierFromJson(json);
}

@freezed
abstract class CommandeEnregistree with _$CommandeEnregistree {
  const factory CommandeEnregistree({
    required int id,
    required DateTime jour,
    required StatutCommande statut,
    @JsonKey(name: 'livraison_prevue') DateTime? livraisonPrevue,
    @JsonKey(name: 'cree_par') String? creePar,
    @JsonKey(name: 'valide_par') String? validePar,
  }) = _CommandeEnregistree;

  factory CommandeEnregistree.fromJson(Map<String, dynamic> json) => _$CommandeEnregistreeFromJson(json);
}

/// Où en est le panier d'un fournisseur ce soir.
enum EtapePanier {
  propose('Proposé'),
  brouillon('Brouillon'),
  validee('Validée'),
  envoyee('Envoyée');

  const EtapePanier(this.libelle);
  final String libelle;
}

@freezed
abstract class Panier with _$Panier {
  const Panier._();

  const factory Panier({
    required FournisseurPanier fournisseur,
    CommandeEnregistree? commande,
    @JsonKey(name: 'livraison_prevue') DateTime? livraisonPrevue,
    @Default(<LigneCommande>[]) List<LigneCommande> lignes,
  }) = _Panier;

  factory Panier.fromJson(Map<String, dynamic> json) => _$PanierFromJson(json);

  EtapePanier get etape => switch (commande?.statut) {
    null || StatutCommande.annulee => EtapePanier.propose,
    StatutCommande.brouillon => EtapePanier.brouillon,
    StatutCommande.validee => EtapePanier.validee,
    StatutCommande.envoyee => EtapePanier.envoyee,
  };

  int get nbLignes => lignes.length;
  int get boites => lignes.fold(0, (s, l) => s + l.qte);
  double get montant => lignes.fold(0.0, (s, l) => s + l.montant);
  int get ruptures => lignes.where((l) => l.rupture).length;

  /// Lignes modifiables : proposition (préparée au premier geste) ou brouillon.
  bool get modifiable => etape == EtapePanier.propose || etape == EtapePanier.brouillon;
}

@freezed
abstract class Budget with _$Budget {
  const Budget._();

  const factory Budget({
    @Default(0) double budget,
    @Default(0) double recu,
    @Default(0) double engage,
    @Default(0) double propose,
    double? reste,
  }) = _Budget;

  factory Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);

  bool get fixe => budget > 0;
  double get depense => recu + engage;

  /// Ce qui restera si l'on passe tout ce qui est proposé ce soir.
  double get resteApres => budget - depense - propose;
}

@freezed
abstract class JourneeCommandes with _$JourneeCommandes {
  const JourneeCommandes._();

  const factory JourneeCommandes({
    required DateTime jour,
    @JsonKey(name: 'donnees_du') DateTime? donneesDu,
    @JsonKey(name: 'peut_valider') @Default(false) bool peutValider,
    @Default(false) bool ferme,
    @Default(<Panier>[]) List<Panier> paniers,
    @Default(<LigneCommande>[]) List<LigneCommande> psychotropes,
    @JsonKey(name: 'sans_fournisseur') @Default(<LigneCommande>[]) List<LigneCommande> sansFournisseur,
    @Default(Budget()) Budget budget,
  }) = _JourneeCommandes;

  factory JourneeCommandes.fromJson(Map<String, dynamic> json) => _$JourneeCommandesFromJson(json);

  Panier? panier(int idFournisseur) {
    for (final p in paniers) {
      if (p.fournisseur.id == idFournisseur) return p;
    }
    return null;
  }

  List<Panier> paniersDe(TypeFournisseur type) => [
    for (final p in paniers)
      if (p.fournisseur.type == type) p,
  ];

  /// Des paniers sont encore à l'état de proposition (rien d'enregistré).
  bool get aPreparer => paniers.any((p) => p.etape == EtapePanier.propose && p.lignes.isNotEmpty);

  int get envoyees => paniers.where((p) => p.etape == EtapePanier.envoyee).length;

  /// La même journée, une ligne changée : totaux recalculés sur place.
  JourneeCommandes avecLigne(int idFournisseur, int idNom, int qte) => copyWith(
    paniers: [
      for (final p in paniers)
        if (p.fournisseur.id != idFournisseur)
          p
        else
          p.copyWith(
            lignes: [
              for (final l in p.lignes)
                if (l.idNom != idNom) l else if (qte > 0) l.avecQuantite(qte),
            ],
          ),
    ],
  );
}

@freezed
abstract class BonCommande with _$BonCommande {
  const BonCommande._();

  const factory BonCommande({
    @JsonKey(name: 'id_commande') required int idCommande,
    String? fournisseur,
    String? whatsapp,
    required String texte,
  }) = _BonCommande;

  factory BonCommande.fromJson(Map<String, dynamic> json) => _$BonCommandeFromJson(json);

  /// Lien WhatsApp avec le bon prérempli ; sans numéro, WhatsApp demande à
  /// qui l'envoyer.
  Uri get lienWhatsapp {
    final numero = numeroWhatsapp(whatsapp);
    return Uri.https('wa.me', numero == null ? '/' : '/$numero', {'text': texte});
  }
}

/// Numéro au format international sans « + » : « 0550 12 34 56 » →
/// « 213550123456 » (numéro algérien à 10 chiffres commençant par 0).
String? numeroWhatsapp(String? brut) {
  if (brut == null) return null;
  var n = brut.replaceAll(RegExp(r'[^0-9]'), '');
  if (n.isEmpty) return null;
  if (n.startsWith('00')) n = n.substring(2);
  if (n.length == 10 && n.startsWith('0')) n = '213${n.substring(1)}';
  return n;
}

@freezed
abstract class FournisseurReglage with _$FournisseurReglage {
  const FournisseurReglage._();

  const factory FournisseurReglage({
    required int id,
    String? nom,
    @Default(TypeFournisseur.pharma) TypeFournisseur type,
    @Default(true) bool actif,

    /// Pas encore réglé par le titulaire : actif s'il a livré ou reçu une
    /// commande dans les 30 derniers jours.
    @Default(true) bool auto,
    String? whatsapp,
    String? telephone,
    @JsonKey(name: 'derniere_commande') DateTime? derniereCommande,
    @JsonKey(name: 'delai_livraison') int? delaiLivraison,
  }) = _FournisseurReglage;

  factory FournisseurReglage.fromJson(Map<String, dynamic> json) => _$FournisseurReglageFromJson(json);

  FournisseurPanier get commePanier => FournisseurPanier(id: id, nom: nom, type: type, whatsapp: whatsapp);
}

/// Compte de l'application (`GET /auth/users`), pour désigner les valideurs.
@freezed
abstract class Compte with _$Compte {
  const Compte._();

  const factory Compte({
    required String username,
    @Default('employee') String role,
    String? nom,
    String? prenom,
    @JsonKey(name: 'is_active') @Default(true) bool actif,
  }) = _Compte;

  factory Compte.fromJson(Map<String, dynamic> json) => _$CompteFromJson(json);

  String get libelle {
    final complet = [prenom, nom].whereType<String>().where((x) => x.trim().isNotEmpty).join(' ');
    return complet.isEmpty ? username : '$complet ($username)';
  }
}

/// Une marque d'un groupe DCI (`GET /commandes/generiques/{id}`).
@freezed
abstract class MembreGenerique with _$MembreGenerique {
  const factory MembreGenerique({
    @JsonKey(name: 'id_nom') required int idNom,
    String? nom,
    @Default(0) int stock,
    @JsonKey(name: 'ventes_12m') @Default(0) double ventes12m,
    @Default(true) bool garde,

    /// Choix du titulaire : « garder », « exclure », ou null (automatique).
    String? choix,
  }) = _MembreGenerique;

  factory MembreGenerique.fromJson(Map<String, dynamic> json) => _$MembreGeneriqueFromJson(json);
}

/// Marques de même DCI et règle appliquée : toutes les marques (classe
/// chronique) ou seulement les plus vendues.
@freezed
abstract class GroupeGenerique with _$GroupeGenerique {
  const GroupeGenerique._();

  const factory GroupeGenerique({
    String? code,
    String? classe,
    @Default('toutes') String mode,
    @JsonKey(name: 'mode_force') String? modeForce,
    @Default(false) bool chronique,
    @JsonKey(name: 'nombre_gardes') @Default(2) int nombreGardes,
    @Default(<MembreGenerique>[]) List<MembreGenerique> membres,
  }) = _GroupeGenerique;

  factory GroupeGenerique.fromJson(Map<String, dynamic> json) => _$GroupeGeneriqueFromJson(json);

  bool get toutes => mode == 'toutes';
  bool get aPlusieursMarques => code != null && membres.length > 1;
}

/// Produit ajouté depuis le Stock au brouillon du jour (`POST /commandes/ajouter`).
@freezed
abstract class AjoutCommande with _$AjoutCommande {
  const factory AjoutCommande({
    @JsonKey(name: 'id_commande') required int idCommande,
    @JsonKey(name: 'id_fournisseur') required int idFournisseur,
    String? fournisseur,
    required int qte,
    @JsonKey(name: 'deja_present') @Default(false) bool dejaPresent,
  }) = _AjoutCommande;

  factory AjoutCommande.fromJson(Map<String, dynamic> json) => _$AjoutCommandeFromJson(json);
}

/// Détail du calcul d'une quantité proposée (`GET /commandes/calcul/{id}`).
@freezed
abstract class DetailCalcul with _$DetailCalcul {
  const factory DetailCalcul({
    @JsonKey(name: 'id_nom') required int idNom,
    String? nom,
    @Default('') String type,
    @JsonKey(name: 'jours_vente_12m') @Default(0) int joursVente12m,
    @JsonKey(name: 'fenetre_jours') @Default(0) int fenetreJours,
    @JsonKey(name: 'jours_ouverts') @Default(0) int joursOuverts,
    @JsonKey(name: 'jours_exclus_rupture') @Default(0) int joursExclusRupture,
    @JsonKey(name: 'jours_retenus') @Default(0) int joursRetenus,
    @JsonKey(name: 'jours_stock_nul') @Default(0) int joursStockNul,
    @JsonKey(name: 'vendu_fenetre') @Default(0) double venduFenetre,
    @JsonKey(name: 'vendu_jours_retenus') @Default(0) double venduJoursRetenus,
    @JsonKey(name: 'repris_generiques') @Default(0) double reprisGeneriques,
    @Default(0) double rythme,
    @JsonKey(name: 'moyenne_hors_ruptures') @Default(0) double moyenneHorsRuptures,
    @JsonKey(name: 'moyenne_brute') @Default(0) double moyenneBrute,
    @JsonKey(name: 'ventes_12m') @Default(0) double ventes12m,
    @JsonKey(name: 'moyenne_12m_jour_ouvert') @Default(0) double moyenne12m,
    @Default(0) double cmm,
    @JsonKey(name: 'plus_grosses_ventes')
    @Default(<Map<String, dynamic>>[])
    List<Map<String, dynamic>> plusGrossesVentes,

    /// Décision du soir (mini, maxi, couverture, lot…).
    Raison? decision,
  }) = _DetailCalcul;

  factory DetailCalcul.fromJson(Map<String, dynamic> json) => _$DetailCalculFromJson(json);
}

/// Produit en tension (`GET /commandes/tensions`) : détecté à confirmer, ou
/// décidé par le titulaire.
@freezed
abstract class Tension with _$Tension {
  const factory Tension({
    @JsonKey(name: 'id_nom') required int idNom,
    String? nom,
    @Default(0) double stock,
    @Default(true) bool tension,
    @Default(false) bool confirme,
    @Default('detection') String source,
    String? motif,
  }) = _Tension;

  factory Tension.fromJson(Map<String, dynamic> json) => _$TensionFromJson(json);
}

// ── Suivi des livraisons ───────────────────────────────────────────────────

/// Où en est une ligne commandée, d'après les réceptions d'EASYPHARM.
enum EtatLivraison {
  @JsonValue('manquante')
  manquante('Non livrés', 'Manquant'),
  @JsonValue('partielle')
  partielle('Partiels', 'Partiel'),
  @JsonValue('attendue')
  attendue('Attendus', 'Attendu'),
  @JsonValue('livree')
  livree('Livrés', 'Livré');

  const EtatLivraison(this.pluriel, this.libelle);
  final String pluriel;
  final String libelle;
}

@freezed
abstract class LigneSuivie with _$LigneSuivie {
  const factory LigneSuivie({
    @JsonKey(name: 'id_nom') required int idNom,
    String? nom,
    @Default(0) int qte,
    @Default(0) int recu,
    @Default(0) int reste,
    @JsonKey(name: 'recu_le') DateTime? recuLe,
    @Default(EtatLivraison.attendue) EtatLivraison etat,
    @Default(0) int stock,

    /// « proposee » (à confirmer), « confirmee », ou null.
    String? tension,
  }) = _LigneSuivie;

  factory LigneSuivie.fromJson(Map<String, dynamic> json) => _$LigneSuivieFromJson(json);
}

@freezed
abstract class CommandeSuivie with _$CommandeSuivie {
  const CommandeSuivie._();

  const factory CommandeSuivie({
    required int id,
    required DateTime jour,
    required FournisseurPanier fournisseur,
    @JsonKey(name: 'livraison_prevue') DateTime? livraisonPrevue,
    @Default(EtatLivraison.attendue) EtatLivraison etat,
    @Default(0) double montant,
    @JsonKey(name: 'montant_recu') @Default(0) double montantRecu,
    @Default(<LigneSuivie>[]) List<LigneSuivie> lignes,
  }) = _CommandeSuivie;

  factory CommandeSuivie.fromJson(Map<String, dynamic> json) => _$CommandeSuivieFromJson(json);

  List<LigneSuivie> lignesDe(EtatLivraison e) => [
    for (final l in lignes)
      if (l.etat == e) l,
  ];

  int get livrees => lignesDe(EtatLivraison.livree).length;

  /// Non livrées ou livrées en partie : ce qu'on peut recommander ailleurs.
  List<LigneSuivie> get aRecommander => [...lignesDe(EtatLivraison.manquante), ...lignesDe(EtatLivraison.partielle)];

  /// Dernière réception rapprochée de cette commande.
  DateTime? get recueLe => lignes
      .map((l) => l.recuLe)
      .whereType<DateTime>()
      .fold<DateTime?>(null, (m, d) => m == null || d.isAfter(m) ? d : m);
}

/// Taux de service d'un grossiste sur les commandes dont la date est passée.
@freezed
abstract class ServiceFournisseur with _$ServiceFournisseur {
  const factory ServiceFournisseur({
    required int id,
    String? nom,
    @Default(0) int commandes,
    @Default(0) int lignes,
    @Default(0) int qte,
    @Default(0) int recu,
    @JsonKey(name: 'taux_lignes') int? tauxLignes,
    @JsonKey(name: 'taux_quantite') int? tauxQuantite,
  }) = _ServiceFournisseur;

  factory ServiceFournisseur.fromJson(Map<String, dynamic> json) => _$ServiceFournisseurFromJson(json);
}

/// Une ligne suivie et la commande dont elle vient.
typedef LigneLivraison = ({LigneSuivie ligne, CommandeSuivie commande});

/// Commandes envoyées, rapprochées des réceptions (`GET /commandes/suivi`).
@freezed
abstract class SuiviLivraisons with _$SuiviLivraisons {
  const SuiviLivraisons._();

  const factory SuiviLivraisons({
    required DateTime jour,
    @Default(30) int jours,
    @JsonKey(name: 'donnees_du') DateTime? donneesDu,
    @Default(<CommandeSuivie>[]) List<CommandeSuivie> commandes,
    @Default(<ServiceFournisseur>[]) List<ServiceFournisseur> fournisseurs,
  }) = _SuiviLivraisons;

  factory SuiviLivraisons.fromJson(Map<String, dynamic> json) => _$SuiviLivraisonsFromJson(json);

  /// Les lignes dans cet état, commandes les plus récentes d'abord. Un
  /// produit non livré ou partiel n'apparaît qu'une fois : sa commande la
  /// plus récente (les anciennes sont déjà reproposées).
  List<LigneLivraison> lignesDe(EtatLivraison etat) {
    final vus = <int>{};
    return [
      for (final c in commandes)
        for (final l in c.lignes)
          if (l.etat == etat && (etat == EtatLivraison.livree || etat == EtatLivraison.attendue || vus.add(l.idNom)))
            (ligne: l, commande: c),
    ];
  }

  CommandeSuivie? commande(int id) => commandes.where((c) => c.id == id).firstOrNull;

  /// Taux de service (quantités) d'un grossiste, en % ; null s'il n'a pas de commande échue.
  int? tauxDe(int idFournisseur) => fournisseurs.where((f) => f.id == idFournisseur).firstOrNull?.tauxQuantite;

  /// Nombre de commandes où ce produit n'a rien reçu (date prévue dépassée).
  int commandesSansLivraison(int idNom) =>
      commandes.expand((c) => c.lignes).where((l) => l.idNom == idNom && l.etat == EtatLivraison.manquante).length;

  /// À vérifier : produits non livrés ou livrés en partie.
  int get aVerifier => lignesDe(EtatLivraison.manquante).length + lignesDe(EtatLivraison.partielle).length;

  /// Quantités reçues ÷ commandées, tous grossistes, en % ; null sans commande échue.
  int? get tauxService {
    final qte = fournisseurs.fold<int>(0, (s, f) => s + f.qte);
    if (qte == 0) return null;
    return (100 * fournisseurs.fold<int>(0, (s, f) => s + f.recu) / qte).round();
  }
}
