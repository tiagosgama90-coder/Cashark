import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cheerful orange-forward Cashark palette.
class AppColors {
  static const orange = Color(0xFFFF6B1A);
  static const orangeDeep = Color(0xFFE85A0A);
  static const orangeSoft = Color(0xFFFFB074);
  static const sky = Color(0xFF1E90FF);
  static const skyDeep = Color(0xFF0B5CAD);
  static const gold = Color(0xFFFFC107);
  static const goldDeep = Color(0xFFFF9800);
  static const mint = Color(0xFF00C853);
  static const magenta = Color(0xFFE91E63);
  static const violet = Color(0xFF7C4DFF);
  static const cream = Color(0xFFFFF4E8);
  static const ink = Color(0xFF1A120B);
  static const inkSoft = Color(0xFF4A3426);

  static const bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8A3D), Color(0xFFFF6B1A), Color(0xFFFF9A4A)],
  );

  static const shopGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFB347), Color(0xFFFF7A18), Color(0xFFFF4E00)],
  );

  /// Soft ocean sky for Spin / Raffle / Wallet (still branded with orange CTAs).
  static const oceanGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF7EC8F8), Color(0xFFB8E0FF), Color(0xFFE8F6FF)],
  );

  static const deepCard = Color(0xFF1B2A4A);
}

ThemeData buildCasharkTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.orange,
      primary: AppColors.orange,
      secondary: AppColors.sky,
      tertiary: AppColors.gold,
      surface: AppColors.cream,
    ),
  );

  return base.copyWith(
    textTheme: GoogleFonts.fredokaTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    scaffoldBackgroundColor: AppColors.orange,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.fredoka(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.sky,
        foregroundColor: Colors.white,
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: GoogleFonts.fredoka(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.92),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
