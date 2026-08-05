import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../game/space_shooter.dart';
import '../models/economy.dart';
import '../services/ads_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/currency_bar.dart';
import '../widgets/roulette_wheel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  RouletteSymbol? pendingResult;
  SpinResult? lastResult;
  String? banner;
  bool wheelSpinning = false;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    final state = context.read<AppState>();
    final l = state.l10n;
    if (wheelSpinning || state.spinning) return;
    if ((state.user?.freeSpins ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.t('no_spins'))));
      return;
    }

    state.beginSpin();
    final result = await state.spinRoulette();
    if (result == null || !mounted) {
      state.endSpin();
      return;
    }

    setState(() {
      pendingResult = result.symbol;
      lastResult = result;
      banner = null;
      wheelSpinning = true;
    });
  }

  void _onSpinEnd() {
    final state = context.read<AppState>();
    final l = state.l10n;
    final r = lastResult;
    state.endSpin();
    if (r == null || !mounted) return;
    setState(() {
      wheelSpinning = false;
      banner = r.symbol == RouletteSymbol.shark
          ? l.t('you_won_sharks', vars: {'n': '${r.sharks}'})
          : l.t('you_won_cash', vars: {'n': r.cash.toStringAsFixed(2)});
    });
  }

  Future<void> _watchAd() async {
    final ads = context.read<AdsService>();
    final state = context.read<AppState>();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.l10n.t('ad_loading'))));
    await ads.showRewarded(onReward: () => state.addSpinsFromAd());
  }

  Future<void> _convertPoints() async {
    final state = context.read<AppState>();
    final msg = await state.convertPointsToSharkcoins();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? '')));
  }

  Future<void> _convertSharkcoins() async {
    final state = context.read<AppState>();
    final msg = await state.convertSharks();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? '')));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = state.l10n;
    final u = state.user!;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.bgGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Column(
            children: [
              Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/images/cashark_logo.png',
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Cashark',
                    style: GoogleFonts.fredoka(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (u.vip)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('VIP', style: GoogleFonts.fredoka(fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              const CurrencyBar(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${l.t('free_spins')}: ${u.freeSpins}',
                    style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _watchAd,
                    icon: const Icon(Icons.ondemand_video, color: Colors.white),
                    label: Text(
                      l.t('watch_ad_spin'),
                      style: GoogleFonts.fredoka(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RouletteWheel(
                            spinning: wheelSpinning,
                            result: pendingResult,
                            onSpinEnd: _onSpinEnd,
                          ),
                          const SizedBox(height: 10),
                          if (banner != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                banner!,
                                style: GoogleFonts.fredoka(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          const SizedBox(height: 14),
                          ScaleTransition(
                            scale: Tween(begin: 0.96, end: 1.04).animate(_pulse),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.magenta,
                                minimumSize: const Size(160, 52),
                              ),
                              onPressed: wheelSpinning ? null : _spin,
                              child: Text(
                                l.t('spin'),
                                style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SideAction(
                            color: AppColors.sky,
                            emoji: '🦈',
                            label: l.t('play_win'),
                            subtitle: 'Ocean Stardust 3D',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SpaceShooterGame()),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          _SideAction(
                            color: AppColors.violet,
                            emoji: '⭐',
                            label: l.t('convert_points'),
                            subtitle: l.t('convert_points_hint'),
                            onTap: _convertPoints,
                          ),
                          const SizedBox(height: 8),
                          _SideAction(
                            color: AppColors.mint,
                            emoji: '💰',
                            label: l.t('convert'),
                            subtitle: l.t('convert_hint'),
                            onTap: _convertSharkcoins,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l.t('min_cash'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideAction extends StatelessWidget {
  final Color color;
  final String emoji;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _SideAction({
    required this.color,
    required this.emoji,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
