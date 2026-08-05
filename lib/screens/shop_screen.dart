import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/economy.dart';
import '../services/app_state.dart';
import '../services/stripe_service.dart';
import '../theme/app_theme.dart';
import '../widgets/currency_bar.dart';
import 'profile_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String? _lastSessionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final stripe = context.read<StripeService>();
      await stripe.refreshHealth();
      await _claimPending();
    });
  }

  Future<void> _claimPending() async {
    final state = context.read<AppState>();
    final stripe = context.read<StripeService>();
    final email = state.user?.email;
    if (email == null) return;

    if (_lastSessionId != null) {
      final sid = _lastSessionId!;
      final itemId = await stripe.claimSession(sessionId: sid, userEmail: email);
      if (!mounted) return;
      if (itemId != null) {
        final err = await state.fulfillPaidShopItem(itemId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err ?? state.l10n.t('stripe_ok'))),
        );
      }
      _lastSessionId = null;
    }

    final pending = await stripe.pendingPurchases(email);
    if (!mounted) return;
    for (final p in pending) {
      final sid = p['id'] as String? ?? p['stripeSessionId'] as String?;
      if (sid == null) continue;
      final claimed = await stripe.claimSession(sessionId: sid, userEmail: email);
      if (!mounted) return;
      if (claimed != null) {
        await state.fulfillPaidShopItem(claimed);
      }
    }
    if (!mounted) return;
    if (pending.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.l10n.t('stripe_ok'))),
      );
    }
  }

  ShopItem _asShopItem({
    required String id,
    required String titleKey,
    required String descKey,
    required String icon,
    required double priceEuro,
    required String kind,
  }) {
    return ShopItem(
      id: id,
      titleKey: titleKey,
      descKey: descKey,
      icon: icon,
      priceEuro: priceEuro,
      kind: kind,
    );
  }

  Future<void> _buyWithStripe(ShopItem item) async {
    final state = context.read<AppState>();
    final stripe = context.read<StripeService>();
    final l = state.l10n;
    if (!stripe.configured) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.t('stripe_off'))));
      return;
    }
    final sessionId = await stripe.startCheckout(userEmail: state.user!.email, item: item);
    if (!mounted) return;
    if (sessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(stripe.lastError ?? l.t('stripe_fail'))),
      );
      return;
    }
    _lastSessionId = sessionId;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.t('stripe_opened'))));
  }

  Future<void> _buyWithCashOrSharks(ShopItem item, {bool useSharks = false}) async {
    final state = context.read<AppState>();
    final err = await state.purchaseShopItem(item, useSharks: useSharks);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? state.l10n.t('purchase_ok'))),
    );
  }

  Future<void> _buyAdFree(AdFreePlan plan) async {
    final item = _asShopItem(
      id: plan.id,
      titleKey: plan.titleKey,
      descKey: 'adfree_desc',
      icon: '🛡️',
      priceEuro: plan.priceEuro,
      kind: plan.id,
    );
    await _buyWithStripe(item);
  }

  Future<void> _buyPearls(PearlPack pack) async {
    final item = _asShopItem(
      id: pack.id,
      titleKey: 'pearls',
      descKey: 'pearls_desc',
      icon: '💎',
      priceEuro: pack.priceEuro,
      kind: pack.id,
    );
    await _buyWithStripe(item);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final stripe = context.watch<StripeService>();
    final l = state.l10n;
    final u = state.user!;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.oceanGradient),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.t('shop'),
                          style: GoogleFonts.fredoka(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ProfileScreen()),
                          );
                        },
                        icon: const Icon(Icons.person, color: AppColors.ink),
                      ),
                    ],
                  ),
                  Text(
                    stripe.configured ? l.t('stripe_on') : l.t('stripe_off'),
                    style: GoogleFonts.fredoka(color: AppColors.inkSoft, fontSize: 12),
                  ),
                  if (u.isAdFree)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l.t('adfree_active'),
                        style: GoogleFonts.fredoka(color: AppColors.mint, fontWeight: FontWeight.w700),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const CurrencyBar(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _claimPending,
                      icon: const Icon(Icons.refresh, color: AppColors.ink, size: 18),
                      label: Text(l.t('stripe_claim'), style: GoogleFonts.fredoka(color: AppColors.ink)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                children: [
                  Text(
                    l.t('adfree_title'),
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.35,
                    children: adFreePlans.map((plan) {
                      final lifetime = plan.days == 0;
                      return Material(
                        color: lifetime ? const Color(0xFFFFF3C4) : Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: stripe.busy ? null : () => _buyAdFree(plan),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.t(plan.titleKey),
                                  style: GoogleFonts.fredoka(fontWeight: FontWeight.w800, fontSize: 16),
                                ),
                                const Spacer(),
                                if (plan.days >= 30 || lifetime)
                                  const Text('🛡️🚫ADS', style: TextStyle(fontSize: 18)),
                                Text(
                                  '€${plan.priceEuro.toStringAsFixed(2)}',
                                  style: GoogleFonts.fredoka(
                                    color: AppColors.skyDeep,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '${l.t('pearls')} ?',
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.t('pearls_desc'),
                    style: GoogleFonts.fredoka(color: AppColors.inkSoft, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  ...pearlPacks.map((pack) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5BA3E0), Color(0xFF7EC8F8)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('💎', style: TextStyle(fontSize: 40)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${pack.pearls} ${l.t('pearls')}',
                                      style: GoogleFonts.fredoka(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (pack.discountPercent != null)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.magenta,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '-${pack.discountPercent}%',
                                          style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.ink),
                                onPressed: stripe.busy ? null : () => _buyPearls(pack),
                                child: Text('€${pack.priceEuro.toStringAsFixed(2)}'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Text(
                    l.t('boosts_title'),
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),
                  ...shopCatalog.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    final colors = [
                      [const Color(0xFFFF5252), const Color(0xFFFF1744)],
                      [const Color(0xFFFF8A3D), const Color(0xFFFF6B1A)],
                      [const Color(0xFF00C853), const Color(0xFF00A844)],
                      [const Color(0xFFFFC107), const Color(0xFFFF9800)],
                      [const Color(0xFF40C4FF), const Color(0xFF2979FF)],
                      [const Color(0xFFE040FB), const Color(0xFFAA00FF)],
                      [const Color(0xFFFF6E40), const Color(0xFFFF3D00)],
                      [const Color(0xFF26A69A), const Color(0xFF00897B)],
                    ][i % 8];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: colors),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(item.icon, style: const TextStyle(fontSize: 36)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.t(item.titleKey),
                                      style: GoogleFonts.fredoka(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      l.t(item.descKey),
                                      style: GoogleFonts.fredoka(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF635BFF),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: stripe.busy ? null : () => _buyWithStripe(item),
                                icon: const Icon(Icons.credit_card, size: 18),
                                label: Text('Stripe €${item.priceEuro.toStringAsFixed(2)}'),
                              ),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white, width: 2),
                                ),
                                onPressed: () => _buyWithCashOrSharks(item),
                                child: Text('${l.t('cash')} €${item.priceEuro.toStringAsFixed(2)}'),
                              ),
                              if (item.priceSharks != null)
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white, width: 2),
                                  ),
                                  onPressed: () => _buyWithCashOrSharks(item, useSharks: true),
                                  child: Text('${item.priceSharks} 🦈'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
