import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/economy.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/currency_bar.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  Future<void> _buy(BuildContext context, ShopItem item, {bool useSharks = false}) async {
    final state = context.read<AppState>();
    final err = await state.purchaseShopItem(item, useSharks: useSharks);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? state.l10n.t('purchase_ok'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
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
                  Text(l.t('shop'), style: GoogleFonts.fredoka(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 10),
                  const CurrencyBar(),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
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
                  ][i % 7];
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
                                      style: GoogleFonts.fredoka(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                                  Text(l.t(item.descKey),
                                      style: GoogleFonts.fredoka(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
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
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.ink),
                              onPressed: () => _buy(context, item),
                              child: Text('${l.t('buy')} €${item.priceEuro.toStringAsFixed(2)}'),
                            ),
                            if (item.priceSharks != null)
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white, width: 2),
                                ),
                                onPressed: () => _buy(context, item, useSharks: true),
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
