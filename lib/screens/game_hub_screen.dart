import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../game/space_shooter.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/currency_bar.dart';

class GameHubScreen extends StatelessWidget {
  const GameHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.watch<AppState>().l10n;
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.oceanGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/images/cashark_logo.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Cashark',
                    style: GoogleFonts.fredoka(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const CurrencyBar(),
              const Spacer(),
              Text(
                l.t('play_win'),
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.t('game_hub_hint'),
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(color: AppColors.inkSoft, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Center(
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/cashark_logo.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sky,
                  minimumSize: const Size(double.infinity, 56),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SpaceShooterGame()),
                  );
                },
                child: Text(
                  'Ocean Stardust 3D',
                  style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
