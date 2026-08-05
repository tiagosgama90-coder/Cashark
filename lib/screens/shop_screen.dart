import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/economy.dart';
import '../services/app_state.dart';
import '../services/stripe_service.dart';
import '../theme/app_theme.dart';
import '../widgets/currency_bar.dart';

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

    // Claim last session if we just returned from Checkout
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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final stripe = context.watch<StripeService>();
    final l = state.l10n;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.shopGradient),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Text(l.t('shop'),
                      style: GoogleFonts.fredoka(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(
                    stripe.configured ? l.t('stripe_on') : l.t('stripe_off'),
                    style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  const CurrencyBar(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _claimPending,
                      icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                      label: Text(l.t('stripe_claim'), style: GoogleFonts.fredoka(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                itemCount: shopCatalog.length,
                itemBuilder: (context, i) {
                  final item = shopCatalog[i];
                  final colors = [
                    [const Color(0xFFFF5252), const Color(0xFFFF1744)],
                    [const Color(0xFF7C4DFF), const Color(0xFF651FFF)],
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
                      boxShadow: [
                        BoxShadow(color: colors.last.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
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
                                  Text(l.t(item.titleKey),
                                      style: GoogleFonts.fredoka(
                                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                                  Text(l.t(item.descKey),
                                      style: GoogleFonts.fredoka(
                                          color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
