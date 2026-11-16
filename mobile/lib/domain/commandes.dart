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
  }) = _LigneCommande;

  factory LigneCommande.fromJson(Map<String, dynamic> json) => _$LigneCommandeFromJson(json);

  bool get rupture => stock <= 0;

  /// Quantité changée à la main (ou produit ajouté à la main).
  bool get modifiee => qteProposee != qte;

  bool get ajoutManuel => qteProposee == null;

  /// Avec une autre quantité : montant recalculé au prix d'achat.
  LigneCommande avecQuantite(int q) => copyWith(qte: q, montant: q * prixAchat);

  /// « 3,1/j × 2 j + sécurité 2 − stock 0 » : pourquoi cette quantité.
  String get explication {
    final r = raison;
    if (r == null) return ajoutManuel ? 'Ajouté à la main' : '';
    if (r.type == 'lent') return 'Vente lente : garder 1 boîte en rayon';
    final morceaux = [
      '${decimal(r.rythme)}/j × ${r.joursCouverts} j',
      if (r.securite > 0) '+ sécurité ${decimal(r.securite, chiffres: 0)}',
      '− stock ${entier(r.stock)}',
      if (r.enCours > 0) '− en cours ${entier(r.enCours)}',
    ];
    final reprise = r.reprend.isEmpty ? '' : ' · reprend ${r.reprend.map(libelleProduit).join(', ')}';
    final remplace = r.remplace == null ? '' : ' · à la place de ${libelleProduit(r.remplace!)}';
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
    @JsonKey(name: 'ventes_12m') @Default(0) double ventes12m,
    @JsonKey(name: 'moyenne_12m_jour_ouvert') @Default(0) double moyenne12m,
    @Default(0) double cmm,
    @JsonKey(name: 'plus_grosses_ventes')
    @Default(<Map<String, dynamic>>[])
    List<Map<String, dynamic>> plusGrossesVentes,
  }) = _DetailCalcul;

  factory DetailCalcul.fromJson(Map<String, dynamic> json) => _$DetailCalculFromJson(json);
}
