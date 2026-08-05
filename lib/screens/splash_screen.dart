import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';
import 'language_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5, curve: Curves.easeOut));
    _ctrl.forward();
    _boot();
  }

  Future<void> _boot() async {
    final state = context.read<AppState>();
    // Wait for logo animation + state ready
    while (!state.ready) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    Widget next;
    if (!state.langPicked) {
      next = const LanguageScreen();
    } else if (state.user == null) {
      next = const LoginScreen();
    } else {
      next = const HomeShell();
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset('assets/images/cashark_logo.png', fit: BoxFit.cover),
                ),
                const SizedBox(height: 28),
                Text(
                  'Cashark',
                  style: GoogleFonts.fredoka(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: const [Shadow(blurRadius: 12, color: Colors.black26)],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.watch<AppState>().l10n.t('tagline'),
                  style: GoogleFonts.fredoka(fontSize: 18, color: Colors.white.withValues(alpha: 0.95)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
