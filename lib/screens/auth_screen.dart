import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Remplissez tous les champs');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
    } on AuthException catch (e) {
      setState(() => _error = _friendlyError(e.message));
    } catch (e) {
      setState(() => _error = 'Erreur de connexion');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _register() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Remplissez tous les champs');
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Les mots de passe ne correspondent pas');
      return;
    }
    if (_passCtrl.text.length < 8) {
      setState(() => _error = 'Mot de passe trop court (8 caractères min)');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        data: {'full_name': _nameCtrl.text.trim()},
      );
    } on AuthException catch (e) {
      setState(() => _error = _friendlyError(e.message));
    } catch (e) {
      setState(() => _error = 'Erreur lors de l\'inscription');
    }
    if (mounted) setState(() => _loading = false);
  }

  String _friendlyError(String msg) {
    if (msg.contains('Invalid login')) return 'Email ou mot de passe incorrect';
    if (msg.contains('already registered')) return 'Cet email est déjà utilisé';
    if (msg.contains('Email not confirmed')) return 'Confirmez votre email d\'abord';
    if (msg.contains('Network')) return 'Erreur réseau — vérifiez votre connexion';
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const SizedBox(height: 40),
            // Logo
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary.withOpacity(0.4), width: 2),
              ),
              child: const Icon(Icons.directions_car_rounded, color: AppTheme.primary, size: 44),
            ),
            const SizedBox(height: 20),
            const Text('AutoTrack', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text('Votre carnet de bord intelligent', style: TextStyle(color: Colors.white38, fontSize: 14)),
            const SizedBox(height: 40),

            // Tab bar
            Container(
              decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(14)),
              child: TabBar(
                controller: _tabs,
                indicator: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.white38,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [Tab(text: 'Connexion'), Tab(text: 'Inscription')],
              ),
            ),
            const SizedBox(height: 28),

            // Error
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.danger.withOpacity(0.4))),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            // Form
            TabBarView(
              controller: _tabs,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // LOGIN
                Column(children: [
                  _field(_emailCtrl, 'Email', Icons.email_rounded, keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 14),
                  _passField(_passCtrl, 'Mot de passe'),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPassword,
                      child: const Text('Mot de passe oublié ?', style: TextStyle(color: AppTheme.primary, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _submitBtn('Se connecter', _login),
                ]),

                // REGISTER
                Column(children: [
                  _field(_nameCtrl, 'Prénom & Nom', Icons.person_rounded),
                  const SizedBox(height: 14),
                  _field(_emailCtrl, 'Email', Icons.email_rounded, keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 14),
                  _passField(_passCtrl, 'Mot de passe (8 car. min)'),
                  const SizedBox(height: 14),
                  _passField(_confirmCtrl, 'Confirmer le mot de passe'),
                  const SizedBox(height: 24),
                  _submitBtn('Créer mon compte', _register),
                  const SizedBox(height: 12),
                  const Text('Un email de confirmation vous sera envoyé', style: TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center),
                ]),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {TextInputType keyboard = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }

  Widget _passField(TextEditingController ctrl, String label) {
    return TextFormField(
      controller: ctrl,
      obscureText: _obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_rounded),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.white38),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }

  Widget _submitBtn(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        child: _loading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : Text(label),
      ),
    );
  }

  Future<void> _forgotPassword() async {
    if (_emailCtrl.text.isEmpty) {
      setState(() => _error = 'Entrez votre email d\'abord');
      return;
    }
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(_emailCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email de réinitialisation envoyé'), backgroundColor: Colors.green));
      }
    } catch (e) {
      setState(() => _error = 'Erreur lors de l\'envoi');
    }
    if (mounted) setState(() => _loading = false);
  }
}
