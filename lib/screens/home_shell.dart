import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/shark_nav_icon.dart';
import 'game_hub_screen.dart';
import 'home_screen.dart';
import 'raffle_screen.dart';
import 'shop_screen.dart';
import 'wallet_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 1; // Spin first (center-left of rewards apps)

  @override
  Widget build(BuildContext context) {
    final l = context.watch<AppState>().l10n;
    final pages = const [
      ShopScreen(),
      HomeScreen(),
      GameHubScreen(),
      RaffleScreen(),
      WalletScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.orangeDeep, AppColors.orange.withValues(alpha: 0.95)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => setState(() => index = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          selectedLabelStyle: GoogleFonts.fredoka(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.fredoka(fontSize: 10),
          items: [
            BottomNavigationBarItem(
              icon: SharkNavIcon(
                badge: Icons.storefront,
                selected: index == 0,
                badgeColor: const Color(0xFFFF7043),
              ),
              label: l.t('shop'),
            ),
            BottomNavigationBarItem(
              icon: SharkNavIcon(
                badge: Icons.casino,
                selected: index == 1,
                badgeColor: AppColors.magenta,
              ),
              label: l.t('spin'),
            ),
            BottomNavigationBarItem(
              icon: SharkNavIcon(
                badge: Icons.sports_esports,
                selected: index == 2,
                badgeColor: AppColors.sky,
              ),
              label: l.t('games'),
            ),
            BottomNavigationBarItem(
              icon: SharkNavIcon(
                badge: Icons.confirmation_number,
                selected: index == 3,
                badgeColor: AppColors.goldDeep,
              ),
              label: l.t('raffle'),
            ),
            BottomNavigationBarItem(
              icon: SharkNavIcon(
                badge: Icons.account_balance_wallet,
                selected: index == 4,
                badgeColor: AppColors.mint,
              ),
              label: l.t('wallet'),
            ),
          ],
        ),
      ),
    );
  }
}
