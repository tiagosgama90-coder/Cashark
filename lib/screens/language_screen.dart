import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Text(
                  state.l10n.t('choose_language'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    itemCount: AppLang.values.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final lang = AppLang.values[i];
                      final selected = state.lang == lang;
                      return Material(
                        color: selected ? Colors.white : Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => state.setLanguage(lang),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            child: Row(
                              children: [
                                Text(lang.flag, style: const TextStyle(fontSize: 28)),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    lang.label,
                                    style: GoogleFonts.fredoka(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  const Icon(Icons.check_circle, color: AppColors.sky),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Text(state.l10n.t('continue')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
