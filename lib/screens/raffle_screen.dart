import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/economy.dart';
import '../services/ads_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/currency_bar.dart';

class RaffleScreen extends StatefulWidget {
  const RaffleScreen({super.key});

  @override
  State<RaffleScreen> createState() => _RaffleScreenState();
}

class _RaffleScreenState extends State<RaffleScreen> {
  final _rng = Random();
  late List<_RaffleCardState> _cards;

  @override
  void initState() {
    super.initState();
    _cards = [
      _RaffleCardState(prizeEuro: 10, hoursLeft: 1, minutesLeft: 40),
      _RaffleCardState(prizeEuro: 100, hoursLeft: 3, minutesLeft: 40),
    ];
  }

  Future<void> _flip(int cardIndex, int tileIndex, {required bool usePearl}) async {
    final state = context.read<AppState>();
    final l = state.l10n;
    final card = _cards[cardIndex];
    if (card.revealed[tileIndex]) return;

    if (usePearl) {
      final ok = await state.flipRaffleTile(usePearl: true);
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.t('need_pearls'))));
        return;
      }
    } else if (state.user?.isAdFree ?? false) {
      await state.flipRaffleTile(usePearl: false);
    } else {
      final ads = context.read<AdsService>();
      var rewarded = false;
      await ads.showRewarded(onReward: () {
        rewarded = true;
      });
      if (!rewarded) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.t('ad_loading'))));
        return;
      }
      await state.flipRaffleTile(usePearl: false);
    }

    final num = 10 + _rng.nextInt(90);
    setState(() {
      card.revealed[tileIndex] = true;
      card.numbers[tileIndex] = num;
      card.flippedCount += 1;
    });

    if (card.flippedCount >= 6) {
      final bonus = card.prizeEuro == 10 ? 0.05 : 0.12;
      await state.grantCashBonus(bonus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.t('raffle_bonus', vars: {'n': bonus.toStringAsFixed(2)}))),
      );
      setState(() {
        card.revealed = List.filled(6, false);
        card.numbers = List.filled(6, 0);
        card.flippedCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = state.l10n;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.oceanGradient),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Text(
                    l.t('raffle'),
                    style: GoogleFonts.fredoka(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const CurrencyBar(),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                itemCount: _cards.length,
                itemBuilder: (context, i) {
                  final card = _cards[i];
                  return _RaffleCard(
                    prizeEuro: card.prizeEuro,
                    hours: card.hoursLeft,
                    minutes: card.minutesLeft,
                    revealed: card.revealed,
                    numbers: card.numbers,
                    pearlsCost: EconomyConfig.pearlsForRaffleFlip,
                    onFlipPearl: (tile) => _flip(i, tile, usePearl: true),
                    onFlipAd: (tile) => _flip(i, tile, usePearl: false),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RaffleCardState {
  final int prizeEuro;
  final int hoursLeft;
  final int minutesLeft;
  List<bool> revealed = List.filled(6, false);
  List<int> numbers = List.filled(6, 0);
  int flippedCount = 0;

  _RaffleCardState({
    required this.prizeEuro,
    required this.hoursLeft,
    required this.minutesLeft,
  });
}

class _RaffleCard extends StatelessWidget {
  final int prizeEuro;
  final int hours;
  final int minutes;
  final List<bool> revealed;
  final List<int> numbers;
  final int pearlsCost;
  final ValueChanged<int> onFlipPearl;
  final ValueChanged<int> onFlipAd;

  const _RaffleCard({
    required this.prizeEuro,
    required this.hours,
    required this.minutes,
    required this.revealed,
    required this.numbers,
    required this.pearlsCost,
    required this.onFlipPearl,
    required this.onFlipAd,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.watch<AppState>().l10n;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.deepCard,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$$prizeEuro in CA\$H',
                      style: GoogleFonts.fredoka(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('💵', style: const TextStyle(fontSize: 36)),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.magenta,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${l.t('raffle_in')} $hours${l.t('hour_short')} $minutes${l.t('min_short')}',
                      style: GoogleFonts.fredoka(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PayPal\nINSTANT CASH',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, i) {
              final open = revealed[i];
              return Container(
                decoration: BoxDecoration(
                  color: open ? AppColors.sky : const Color(0xFF2C3E67),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  open ? '${numbers[i]}' : '?',
                  style: GoogleFonts.fredoka(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            l.t('raffle_hint'),
            style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.mint),
                  onPressed: () {
                    final next = revealed.indexWhere((e) => !e);
                    if (next >= 0) onFlipAd(next);
                  },
                  icon: const Icon(Icons.videocam, size: 18),
                  label: Text(l.t('raffle_flip_ad')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                  ),
                  onPressed: () {
                    final next = revealed.indexWhere((e) => !e);
                    if (next >= 0) onFlipPearl(next);
                  },
                  icon: const Text('💎'),
                  label: Text('$pearlsCost'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
