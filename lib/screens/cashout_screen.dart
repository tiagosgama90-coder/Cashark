import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/economy.dart';
import '../models/payout.dart';
import '../services/app_state.dart';
import '../services/payout_service.dart';
import '../theme/app_theme.dart';

class CashoutScreen extends StatefulWidget {
  const CashoutScreen({super.key});

  @override
  State<CashoutScreen> createState() => _CashoutScreenState();
}

class _CashoutScreenState extends State<CashoutScreen> {
  PayoutMethod method = PayoutMethod.paypal;
  final amountCtrl = TextEditingController();
  final destCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    final cash = context.read<AppState>().user?.cash ?? 0;
    amountCtrl.text = cash >= EconomyConfig.minCashEuro
        ? cash.toStringAsFixed(2)
        : EconomyConfig.minCashEuro.toStringAsFixed(2);
    final email = context.read<AppState>().user?.email ?? '';
    destCtrl.text = email;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final payouts = context.read<PayoutService>();
      final email = context.read<AppState>().user?.email;
      payouts.ping();
      if (email != null) payouts.refreshFromApi(email);
    });
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    destCtrl.dispose();
    nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final state = context.read<AppState>();
    final payouts = context.read<PayoutService>();
    final l = state.l10n;
    final u = state.user!;
    final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;

    if (amount < EconomyConfig.minCashEuro) {
      _toast(l.t('cashout_need'));
      return;
    }
    if (amount > u.cash + 0.001) {
      _toast(l.t('not_enough'));
      return;
    }
    if (destCtrl.text.trim().isEmpty) {
      _toast(l.t('cashout_dest_required'));
      return;
    }
    if (method == PayoutMethod.paypal && !_validEmail(destCtrl.text.trim())) {
      _toast(l.t('cashout_paypal_email'));
      return;
    }

    setState(() => submitting = true);
    try {
      final locked = await state.lockCashForCashout(amount);
      if (locked != null) {
        _toast(locked);
        return;
      }

      final req = await payouts.submitCashout(
        userEmail: u.email,
        amountEuro: amount,
        method: method,
        destination: destCtrl.text.trim(),
        accountName: nameCtrl.text.trim().isEmpty ? u.displayName : nameCtrl.text.trim(),
      );

      if (!mounted) return;
      final statusMsg = switch (req.status) {
        CashoutStatus.paid => l.t('cashout_paid'),
        CashoutStatus.failed => l.t('cashout_failed'),
        CashoutStatus.processing => l.t('cashout_processing'),
        _ => l.t('cashout_pending'),
      };
      _toast(statusMsg);
      if (req.status == CashoutStatus.failed) {
        await state.refundCashout(amount);
      }
    } catch (_) {
      _toast(l.t('cashout_failed'));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  bool _validEmail(String e) => RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(e);

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final payouts = context.watch<PayoutService>();
    final l = state.l10n;
    final cash = state.user?.cash ?? 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        l.t('cashout_title'),
                        style: GoogleFonts.fredoka(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: payouts.apiReachable ? AppColors.mint : Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        payouts.apiReachable ? l.t('api_online') : l.t('api_offline'),
                        style: GoogleFonts.fredoka(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l.t('cash')}: €${cash.toStringAsFixed(2)}',
                            style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                          Text(l.t('min_cash'), style: GoogleFonts.fredoka(color: AppColors.inkSoft)),
                          Text(l.t('cashout_flow_hint'), style: GoogleFonts.fredoka(fontSize: 12, color: AppColors.inkSoft)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(l.t('cashout_method'), style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: PayoutMethod.values.map((m) {
                        final selected = method == m;
                        return ChoiceChip(
                          selected: selected,
                          label: Text('${m.emoji} ${m.title}'),
                          selectedColor: AppColors.sky,
                          labelStyle: GoogleFonts.fredoka(
                            color: selected ? Colors.white : AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setState(() => method = m),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                      decoration: InputDecoration(
                        labelText: l.t('cashout_amount'),
                        prefixText: '€ ',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: destCtrl,
                      decoration: InputDecoration(
                        labelText: method.fieldHint,
                        prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: l.t('cashout_account_name'),
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mint,
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(l.t('cashout_send'), style: GoogleFonts.fredoka(fontWeight: FontWeight.w800, fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l.t('cashout_legal'),
                      style: GoogleFonts.fredoka(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 20),
                    Text(l.t('cashout_history'), style: GoogleFonts.fredoka(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                    const SizedBox(height: 8),
                    if (payouts.history.isEmpty)
                      Text(l.t('cashout_history_empty'), style: GoogleFonts.fredoka(color: Colors.white70))
                    else
                      ...payouts.history.take(20).map((c) => _HistoryTile(c: c)),
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

class _HistoryTile extends StatelessWidget {
  final CashoutRequest c;
  const _HistoryTile({required this.c});

  Color get _color => switch (c.status) {
        CashoutStatus.paid => AppColors.mint,
        CashoutStatus.failed || CashoutStatus.rejected => Colors.redAccent,
        CashoutStatus.processing => AppColors.goldDeep,
        CashoutStatus.pending => AppColors.sky,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: _color, width: 5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${c.method.emoji} ${c.method.title} · €${c.amountEuro.toStringAsFixed(2)}',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.w700),
          ),
          Text(c.destination, style: GoogleFonts.fredoka(fontSize: 12, color: AppColors.inkSoft)),
          Text(
            '${c.status.name.toUpperCase()} · ${c.createdAt.substring(0, 16).replaceAll('T', ' ')}',
            style: GoogleFonts.fredoka(fontSize: 12, color: _color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
