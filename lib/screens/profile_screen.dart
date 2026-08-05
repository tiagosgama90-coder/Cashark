import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/currency_bar.dart';
import 'cashout_screen.dart';
import 'language_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _openPrivacy() async {
    // Bundled privacy page hosted as a simple HTTPS paste — replace with your domain.
    final uri = Uri.parse('https://cashark.app/privacy');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = state.l10n;
    final u = state.user!;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l.t('profile'), style: GoogleFonts.fredoka(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  ClipOval(
                    child: Image.asset('assets/images/cashark_logo.png', width: 72, height: 72, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.displayName, style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w700)),
                        Text(u.email, style: GoogleFonts.fredoka(color: AppColors.inkSoft, fontSize: 13)),
                        if (u.vip)
                          Text('👑 VIP', style: GoogleFonts.fredoka(color: AppColors.goldDeep, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const CurrencyBar(),
            const SizedBox(height: 16),
            Text(l.t('stats'), style: GoogleFonts.fredoka(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _StatTile(label: l.t('points'), value: '${u.points}'),
            _StatTile(label: l.t('pearls'), value: '${u.pearls}'),
            _StatTile(label: l.t('spins_done'), value: '${u.spinsPlayed}'),
            _StatTile(label: l.t('kills'), value: '${u.enemiesDefeated}'),
            _StatTile(label: l.t('lives'), value: '${u.lives}'),
            _StatTile(label: l.t('free_spins'), value: '${u.freeSpins}'),
            if (u.isAdFree) _StatTile(label: l.t('adfree_title'), value: '✓'),
            if (u.googleLinked) _StatTile(label: l.t('google_sign_in'), value: '✓'),
            const SizedBox(height: 12),
            Text(l.t('min_cash'), style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.mint),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CashoutScreen()),
                );
              },
              child: Text(l.t('cashout')),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LanguageScreen(fromProfile: true)));
              },
              child: Text('${l.t('choose_language')} (${state.lang.flag} ${state.lang.label})'),
            ),
            TextButton(
              onPressed: _openPrivacy,
              child: Text(l.t('privacy'), style: GoogleFonts.fredoka(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                await state.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                }
              },
              child: Text(l.t('logout'), style: GoogleFonts.fredoka(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: GoogleFonts.fredoka(fontWeight: FontWeight.w600))),
          Text(value, style: GoogleFonts.fredoka(fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      ),
    );
  }
}
