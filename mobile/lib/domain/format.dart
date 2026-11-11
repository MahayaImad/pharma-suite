// Mise en forme des nombres, dates et libellés — Dart pur.

const _espace = ' '; // espace fine insécable, séparateur de milliers

/// 1234567 → « 1 234 567 ».
String entier(num valeur) {
  final n = valeur.round().abs().toString();
  final groupes = <String>[];
  for (var fin = n.length; fin > 0; fin -= 3) {
    groupes.insert(0, n.substring(fin - 3 < 0 ? 0 : fin - 3, fin));
  }
  return '${valeur.round() < 0 ? '−' : ''}${groupes.join(_espace)}';
}

/// Montant en dinars, sans décimales inutiles : « 1 250 DA », « 12,50 DA ».
String dinars(num valeur) {
  final arrondi = (valeur * 100).round() / 100;
  if (arrondi == arrondi.roundToDouble()) return '${entier(arrondi)} DA';
  final cents = ((arrondi.abs() * 100).round() % 100).toString().padLeft(2, '0');
  return '${entier(arrondi.truncate())},$cents DA';
}

/// Grand montant abrégé : « 15,9 M DA », « 830 k DA », « 950 DA ».
String dinarsCourt(num valeur) {
  final v = valeur.abs();
  String une(double x) => x.toStringAsFixed(1).replaceAll('.', ',').replaceAll(',0', '');
  if (v >= 1e6) return '${une(valeur / 1e6)} M DA';
  if (v >= 1e4) return '${entier(valeur / 1e3)} k DA';
  return dinars(valeur);
}

/// Pourcentage à une décimale au plus : « 33 % », « 12,5 % ».
String pourcent(double valeur) {
  final t = valeur.toStringAsFixed(1).replaceAll('.', ',');
  return '${t.endsWith(',0') ? t.substring(0, t.length - 2) : t}$_espace%';
}

/// L'Algérie est en UTC+1 toute l'année (pas d'heure d'été) : affichage
/// `Africa/Algiers` sans base de fuseaux.
DateTime heureAlger(DateTime utc) => utc.toUtc().add(const Duration(hours: 1));

String _deux(int n) => n.toString().padLeft(2, '0');

/// « à 14:32 » aujourd'hui, « hier à 14:32 », sinon « le 09/11 à 14:32 ».
String horodatage(DateTime utc, DateTime maintenantUtc) {
  final h = heureAlger(utc), m = heureAlger(maintenantUtc);
  final heure = '${_deux(h.hour)}:${_deux(h.minute)}';
  final ecart = DateTime.utc(m.year, m.month, m.day).difference(DateTime.utc(h.year, h.month, h.day)).inDays;
  if (ecart == 0) return "aujourd'hui à $heure";
  if (ecart == 1) return 'hier à $heure';
  return 'le ${_deux(h.day)}/${_deux(h.month)} à $heure';
}

/// Ancienneté d'une date : « aujourd'hui », « hier », « il y a 5 jours »,
/// « il y a 3 mois », « il y a 2 ans ».
String depuis(DateTime date, DateTime aujourdhui) {
  final j = DateTime.utc(
    aujourdhui.year,
    aujourdhui.month,
    aujourdhui.day,
  ).difference(DateTime.utc(date.year, date.month, date.day)).inDays;
  if (j <= 0) return "aujourd'hui";
  if (j == 1) return 'hier';
  if (j < 31) return 'il y a $j jours';
  if (j < 365) return 'il y a ${j ~/ 30} mois';
  final ans = j ~/ 365;
  return 'il y a $ans an${ans > 1 ? 's' : ''}';
}

/// « 09/11/2026 ».
String date(DateTime d) => '${_deux(d.day)}/${_deux(d.month)}/${d.year}';

/// Libellé saisi en capitales dans EASYPHARM → « Bebe et maman ».
/// Un libellé déjà en casse mixte (« Médicaments ») est laissé tel quel.
String libelle(String brut) {
  final t = brut.trim();
  if (t.isEmpty || t != t.toUpperCase()) return t;
  final bas = t.toLowerCase();
  return bas[0].toUpperCase() + bas.substring(1);
}

/// Couverture lisible : « 12 jours », « 3 mois », « plus d'un an ».
String duree(int jours) {
  if (jours < 60) return '$jours jour${jours > 1 ? 's' : ''}';
  if (jours < 365) return '${(jours / 30).round()} mois';
  return "plus d'un an";
}

/// Nombre décimal à la française : « 3,04 », « 91,3 » ; entier sans virgule.
String decimal(num valeur, {int chiffres = 1}) {
  final t = valeur.toStringAsFixed(chiffres).replaceAll('.', ',');
  final propre = t.contains(',') ? t.replaceFirst(RegExp(r',?0+$'), '') : t;
  return propre.isEmpty ? '0' : propre;
}

const _jours = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];

/// « dimanche 15/11 ».
String jourEtDate(DateTime d) => '${_jours[d.weekday - 1]} ${_deux(d.day)}/${_deux(d.month)}';

const _unites = {'mg', 'g', 'kg', 'ml', 'l', 'ui', 'mcg', 'µg', 'cl', 'mmol'};
const _petitsMots = {
  'et',
  'de',
  'du',
  'des',
  'à',
  'au',
  'aux',
  'en',
  'pour',
  'avec',
  'sans',
  'la',
  'le',
  'les',
};

/// Nom saisi en capitales dans EASYPHARM → lisible :
/// « DOLIPRANE 1000 MG » → « Doliprane 1000 mg »,
/// « LA ROCHE-POSAY » → « La Roche-Posay ». Un nom déjà en casse mixte est
/// laissé tel quel ; un mot avec des chiffres garde sa forme (« B6 »), sauf
/// l'unité collée (« 500MG » → « 500mg »).
String libelleProduit(String brut) {
  final t = brut.trim();
  if (t.isEmpty || t != t.toUpperCase()) return t;
  final mots = t.split(RegExp(r'\s+'));
  return [
    for (final (i, mot) in mots.indexed)
      if (_unites.contains(mot.toLowerCase()))
        mot.toLowerCase()
      else if (mot.contains(RegExp(r'\d')))
        mot.replaceAllMapped(
          RegExp(r'(\d)(MG|G|ML|UI|MCG|CL|L|KG)\b'),
          (m) => '${m[1]}${m[2]!.toLowerCase()}',
        )
      else if (i > 0 && _petitsMots.contains(mot.toLowerCase()))
        mot.toLowerCase()
      else
        mot
            .toLowerCase()
            .split('-')
            .map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1))
            .join('-'),
  ].join(' ');
}
