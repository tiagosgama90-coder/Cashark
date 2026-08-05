import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/economy.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'cashout_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = state.l10n;
    final u = state.user!;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.oceanGradient),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const SizedBox(height: 12),
            Text(
              l.t('your_balance'),
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              '€${u.cash.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w800,
                shadows: const [Shadow(blurRadius: 8, color: Colors.black26)],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mint,
                  minimumSize: const Size(160, 48),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CashoutScreen()),
                  );
                },
                child: Text(l.t('withdraw')),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ClipOval(
                child: Image.asset(
                  'assets/images/cashark_logo.png',
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.ink,
                minimumSize: const Size(double.infinity, 52),
              ),
              onPressed: () => _showEarnSheet(context),
              child: Text(l.t('how_earn')),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  'PayPal',
                  style: GoogleFonts.fredoka(
                    color: const Color(0xFF003087),
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _InfoTile(
              emoji: '💵',
              title: l.t('how_withdraw'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CashoutScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
            _InfoTile(
              emoji: '🏦',
              title: l.t('where_rewards'),
              onTap: () => _showRewardsInfo(context),
            ),
            const SizedBox(height: 16),
            Text(
              l.t('exchange_title'),
              style: GoogleFonts.fredoka(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            _ActionTile(
              title: l.t('convert_points'),
              subtitle: l.t('convert_points_hint'),
              onTap: () async {
                final msg = await state.convertPointsToSharkcoins();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? '')));
              },
            ),
            const SizedBox(height: 8),
            _ActionTile(
              title: l.t('convert'),
              subtitle: l.t('convert_hint'),
              onTap: () async {
                final msg = await state.convertSharks();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? '')));
              },
            ),
            const SizedBox(height: 8),
            _ActionTile(
              title: l.t('pearls_to_sc'),
              subtitle: l.t('pearls_to_sc_hint'),
              onTap: () async {
                final msg = await state.exchangePearlsToSharkcoins(1);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? '')));
              },
            ),
            const SizedBox(height: 12),
            Text(
              '${l.t('sharks')}: ${u.sharks}  ·  ${l.t('points')}: ${u.points}  ·  ${l.t('pearls')}: ${u.pearls}',
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(color: AppColors.inkSoft, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              l.t('min_cash'),
              textAlign: TextAlign.center,
              style: GoogleFonts.fredoka(color: AppColors.inkSoft, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showEarnSheet(BuildContext context) {
    final l = context.read<AppState>().l10n;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.t('how_earn'), style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text('1. ${l.t('earn_spin')}', style: GoogleFonts.fredoka(fontSize: 15)),
            Text('2. ${l.t('earn_game')}', style: GoogleFonts.fredoka(fontSize: 15)),
            Text('3. ${l.t('earn_raffle')}', style: GoogleFonts.fredoka(fontSize: 15)),
            Text('4. ${l.t('earn_convert')}', style: GoogleFonts.fredoka(fontSize: 15)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showRewardsInfo(BuildContext context) {
    final l = context.read<AppState>().l10n;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.t('where_rewards'), style: GoogleFonts.fredoka(fontWeight: FontWeight.w800)),
        content: Text(l.t('where_rewards_body'), style: GoogleFonts.fredoka()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.t('continue'))),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String emoji;
  final String title;
  final VoidCallback onTap;

  const _InfoTile({required this.emoji, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: GoogleFonts.fredoka(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.fredoka(fontWeight: FontWeight.w800, fontSize: 16)),
              Text(subtitle, style: GoogleFonts.fredoka(color: AppColors.inkSoft, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                '€${EconomyConfig.minCashEuro.toStringAsFixed(0)}+',
                style: GoogleFonts.fredoka(color: AppColors.mint, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
