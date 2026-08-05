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
            emoji: '💵',
            label: l.t('cash'),
            value: '€${u.cash.toStringAsFixed(2)}',
            colors: const [AppColors.mint, Color(0xFF00A844)],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Chip(
            emoji: '🦈',
            label: l.t('sharks'),
            value: _compact(u.sharks),
            colors: const [AppColors.gold, AppColors.goldDeep],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Chip(
            emoji: '💎',
            label: l.t('pearls'),
            value: '${u.pearls}',
            colors: const [Color(0xFFFF6FAE), Color(0xFFE91E63)],
          ),
        ),
      ],
    );
  }

  String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n >= 10000 ? 1 : 2)}K';
    return '$n';
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
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.fredoka(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
