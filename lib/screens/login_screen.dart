import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  bool registerMode = false;
  bool busy = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => busy = true);
    final state = context.read<AppState>();
    final err = registerMode
        ? await state.register(emailCtrl.text, passCtrl.text, nameCtrl.text)
        : await state.login(emailCtrl.text, passCtrl.text);
    setState(() => busy = false);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.watch<AppState>().l10n;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    ClipOval(
                      child: Image.asset('assets/images/cashark_logo.png', width: 120, height: 120, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 12),
                    Text('Cashark', style: GoogleFonts.fredoka(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(l.t('tagline'), style: GoogleFonts.fredoka(color: Colors.white70)),
                    const SizedBox(height: 24),
                    if (registerMode) ...[
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(hintText: l.t('display_name'), prefixIcon: const Icon(Icons.person)),
                      ),
                      const SizedBox(height: 10),
                    ],
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(hintText: l.t('email'), prefixIcon: const Icon(Icons.email_outlined)),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: InputDecoration(hintText: l.t('password'), prefixIcon: const Icon(Icons.lock_outline)),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: busy ? null : _submit,
                        child: busy
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(registerMode ? l.t('register') : l.t('login')),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => registerMode = !registerMode),
                      child: Text(
                        registerMode ? l.t('login') : l.t('register'),
                        style: GoogleFonts.fredoka(color: Colors.white, decoration: TextDecoration.underline),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.t('test_hint'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        emailCtrl.text = 'teste_samsung@email.com';
                        passCtrl.text = 'SenhaTeste123';
                        setState(() => registerMode = false);
                      },
                      child: Text('Fill review account', style: GoogleFonts.fredoka(color: AppColors.gold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
