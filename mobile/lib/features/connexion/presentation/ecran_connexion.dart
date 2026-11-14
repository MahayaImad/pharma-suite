import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/coquille.dart' show largeurPc;
import '../../../core/widgets/logo.dart';
import '../../../domain/session.dart';
import '../application/session_controller.dart';

const _titre = 'Sora';
const _bleu = Color(0xFF1F5FBF);
const _bleuFonce = Color(0xFF174A96);

/// Écran de connexion : la photo de l'officine d'un côté, le formulaire de
/// l'autre. Sur portable, la photo devient un bandeau au-dessus du formulaire.
class EcranConnexion extends StatelessWidget {
  const EcranConnexion({super.key});

  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.sizeOf(context).width >= largeurPc;
    return Scaffold(
      backgroundColor: Colors.white,
      body: large
          ? const Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _Volet(compact: false)),
                Expanded(
                  child: _FondDoux(child: Center(child: _Formulaire())),
                ),
              ],
            )
          : const _FondDoux(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 340, child: _Volet(compact: true)),
                    Padding(padding: EdgeInsets.fromLTRB(20, 26, 20, 32), child: _Formulaire()),
                  ],
                ),
              ),
            ),
    );
  }
}

/// La photo, un voile bleu en bas, le logo et la phrase d'accueil.
class _Volet extends StatelessWidget {
  const _Volet({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/connexion.webp',
          fit: BoxFit.cover,
          alignment: const Alignment(-.45, 0),
          excludeFromSemantics: true,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: compact ? const [.25, .62, 1] : const [.48, .78, 1],
              colors: [_bleuFonce.withValues(alpha: 0), _bleuFonce.withValues(alpha: .84), _bleuFonce],
            ),
          ),
        ),
        Padding(
          padding: compact ? const EdgeInsets.fromLTRB(20, 22, 20, 22) : const EdgeInsets.fromLTRB(52, 44, 52, 44),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .92),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Color(0x330B2552), blurRadius: 24, offset: Offset(0, 8))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LogoPharmaSuite(taille: compact ? 34 : 40),
                    const SizedBox(width: 10),
                    Text(
                      'PharmaSuite',
                      style: TextStyle(
                        fontFamily: _titre,
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 17 : 19,
                        color: const Color(0xFF131732),
                        letterSpacing: -.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 470),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Votre officine, pilotée au quotidien.',
                      style: TextStyle(
                        fontFamily: _titre,
                        fontWeight: FontWeight.w600,
                        fontSize: compact ? 21 : 32,
                        height: 1.15,
                        letterSpacing: compact ? -.6 : -1.1,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 16),
                    Text(
                      "Le complément d'EASYPHARM : tableaux de bord, stock et commandes, "
                      'équipe et paie, trésorerie et CHIFA.',
                      style: TextStyle(
                        fontSize: compact ? 13.5 : 16,
                        height: 1.5,
                        color: Colors.white.withValues(alpha: .9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Fond bleu très doux, à halos, derrière le formulaire.
class _FondDoux extends StatelessWidget {
  const _FondDoux({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget halo(Alignment ou, Color couleur) => Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(center: ou, radius: .75, colors: [couleur, couleur.withValues(alpha: 0)]),
        ),
      ),
    );
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: Color(0xFFEEF3FB))),
        halo(const Alignment(-.6, -.7), const Color(0xFFC6DAF7)),
        halo(const Alignment(.7, .8), const Color(0xFFC9DCF8)),
        halo(const Alignment(.8, -.8), const Color(0xFFE3ECFA)),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Formulaire extends ConsumerStatefulWidget {
  const _Formulaire();

  @override
  ConsumerState<_Formulaire> createState() => _EtatFormulaire();
}

class _EtatFormulaire extends ConsumerState<_Formulaire> {
  final _cle = GlobalKey<FormState>();
  final _utilisateur = TextEditingController();
  final _motDePasse = TextEditingController();
  final _focusMotDePasse = FocusNode();
  bool _masque = true;
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _utilisateur.dispose();
    _motDePasse.dispose();
    _focusMotDePasse.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    if (_enCours || !_cle.currentState!.validate()) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await ref.read(sessionProvider.notifier).ouvrir(_utilisateur.text, _motDePasse.text);
      // Le routeur suit la session : il ouvre l'application tout seul.
    } on ErreurConnexion catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e.echec.message);
      if (e.echec == EchecConnexion.identifiants) {
        _motDePasse.clear();
        _focusMotDePasse.requestFocus();
      }
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  InputDecoration _decoration({Widget? suffixe}) => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    suffixIcon: suffixe,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDCE3EE)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _bleu, width: 1.5),
    ),
  );

  @override
  Widget build(BuildContext context) {
    const etiquette = TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF55657D));
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Form(
        key: _cle,
        child: AutofillGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Connexion',
                style: TextStyle(
                  fontFamily: _titre,
                  fontWeight: FontWeight.w700,
                  fontSize: 32,
                  letterSpacing: -1.1,
                  color: Color(0xFF10203A),
                ),
              ),
              const SizedBox(height: 6),
              const Text('Avec votre compte EASYPHARM', style: TextStyle(fontSize: 15, color: Color(0xFF55657D))),
              const SizedBox(height: 26),
              if (_erreur != null) ...[_MessageErreur(_erreur!), const SizedBox(height: 16)],
              const Text('Utilisateur', style: etiquette),
              const SizedBox(height: 7),
              TextFormField(
                key: const ValueKey('champ-utilisateur'),
                controller: _utilisateur,
                enabled: !_enCours,
                autofillHints: const [AutofillHints.username],
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: _decoration(),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Indiquez votre utilisateur.' : null,
                onFieldSubmitted: (_) => _focusMotDePasse.requestFocus(),
              ),
              const SizedBox(height: 16),
              const Text('Mot de passe', style: etiquette),
              const SizedBox(height: 7),
              TextFormField(
                key: const ValueKey('champ-mot-de-passe'),
                controller: _motDePasse,
                focusNode: _focusMotDePasse,
                enabled: !_enCours,
                obscureText: _masque,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.go,
                decoration: _decoration(
                  suffixe: TextButton(
                    onPressed: () => setState(() => _masque = !_masque),
                    child: Text(
                      _masque ? 'Afficher' : 'Masquer',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF8B98AD)),
                    ),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Indiquez votre mot de passe.' : null,
                onFieldSubmitted: (_) => _envoyer(),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                child: FilledButton(
                  key: const ValueKey('bouton-connexion'),
                  onPressed: _enCours ? null : _envoyer,
                  style: FilledButton.styleFrom(
                    backgroundColor: _bleu,
                    disabledBackgroundColor: _bleu.withValues(alpha: .7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontFamily: _titre, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  child: _enCours
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Text('Se connecter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageErreur extends StatelessWidget {
  const _MessageErreur(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      decoration: BoxDecoration(color: const Color(0xFFFBE9E9), borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 20, color: Color(0xFFC62F2F)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: Color(0xFF8E1F1F), fontSize: 14, height: 1.4)),
          ),
        ],
      ),
    ),
  );
}
