import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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

  Future<void> _watchAdForSpin() async {
    final ads = context.read<AdsService>();
    final state = context.read<AppState>();
    if (state.user?.isAdFree ?? false) {
      await state.addSpinsFromAd();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.l10n.t('adfree_active'))));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.l10n.t('ad_loading'))));
    await ads.showRewarded(onReward: () => state.addSpinsFromAd());
  }

  Future<void> _pearlSpin() async {
    final state = context.read<AppState>();
    final err = await state.spendPearlForSpin();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? state.l10n.t('spin_ready'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = state.l10n;
    final u = state.user!;
    final streakDay = (u.dailyStreak % 7).clamp(1, 7);

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.oceanGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Column(
            children: [
              const CurrencyBar(),
              const SizedBox(height: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RouletteWheel(
                      spinning: wheelSpinning,
                      result: pendingResult,
                      onSpinEnd: _onSpinEnd,
                    ),
                    const SizedBox(height: 12),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Badge(
                          bg: AppColors.magenta,
                          label: l.t('daily_streak'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${u.dailyStreak}', style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.w800)),
                              const SizedBox(width: 6),
                              const Icon(Icons.casino, color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _Badge(
                          bg: Colors.white,
                          label: l.t('week_progress'),
                          darkLabel: true,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                              Text(
                                '$streakDay/7',
                                style: GoogleFonts.fredoka(color: AppColors.ink, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${l.t('free_spins')}: ${u.freeSpins}',
                      style: GoogleFonts.fredoka(color: AppColors.ink, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              ScaleTransition(
                scale: Tween(begin: 0.98, end: 1.03).animate(_pulse),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.ink,
                      minimumSize: const Size(double.infinity, 54),
                    ),
                    onPressed: wheelSpinning
                        ? null
                        : () {
                            if (u.freeSpins > 0) {
                              _spin();
                            } else {
                              _watchAdForSpin();
                            }
                          },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          u.freeSpins > 0 ? l.t('to_spin') : l.t('to_spin_ad'),
                          style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        if (u.freeSpins <= 0) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.videocam, size: 22),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _watchAdForSpin,
                      child: Text(l.t('watch_ad_spin'), style: GoogleFonts.fredoka(color: AppColors.inkSoft)),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: _pearlSpin,
                      child: Text(
                        '${l.t('pearl_spin')} (${EconomyConfig.pearlsForExtraSpin}💎)',
                        style: GoogleFonts.fredoka(color: AppColors.magenta),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final Color bg;
  final Widget child;
  final String label;
  final bool darkLabel;

  const _Badge({
    required this.bg,
    required this.child,
    required this.label,
    this.darkLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: child,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: darkLabel ? AppColors.inkSoft : AppColors.ink,
          ),
        ),
      ],
    );
  }
}
