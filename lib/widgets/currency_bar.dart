import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme/app_theme.dart';

class CurrencyBar extends StatelessWidget {
  const CurrencyBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final u = state.user!;
    final l = state.l10n;
    return Row(
      children: [
        Expanded(
          child: _Chip(
            emoji: '🪙',
            label: l.t('cash'),
            value: '€${u.cash.toStringAsFixed(2)}',
            colors: const [AppColors.gold, AppColors.goldDeep],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Chip(
            emoji: '🦈',
            label: l.t('sharks'),
            value: '${u.sharks}',
            colors: const [AppColors.sky, AppColors.skyDeep],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Chip(
            emoji: '⭐',
            label: l.t('points'),
            value: '${u.points}',
            colors: const [AppColors.magenta, AppColors.violet],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final List<Color> colors;

  const _Chip({
    required this.emoji,
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: colors.last.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$emoji $label', style: GoogleFonts.fredoka(color: Colors.white, fontSize: 11)),
          Text(value, style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
        ],
      ),
    );
  }
}
