import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'shop_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final l = context.watch<AppState>().l10n;
    final pages = const [HomeScreen(), ShopScreen(), ProfileScreen()];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.orangeDeep, AppColors.orange.withValues(alpha: 0.95)],
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => setState(() => index = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          selectedLabelStyle: GoogleFonts.fredoka(fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.fredoka(),
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.casino), label: l.t('home')),
            BottomNavigationBarItem(icon: const Icon(Icons.storefront), label: l.t('shop')),
            BottomNavigationBarItem(icon: const Icon(Icons.person), label: l.t('profile')),
          ],
        ),
      ),
    );
  }
}
