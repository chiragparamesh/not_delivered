import 'package:flutter/material.dart';

/// Brand palette from the brief.
class AppColors {
  static const maroon = Color(0xFF8B1E3F);
  static const gold = Color(0xFFF4B400);
  static const background = Color(0xFFFFF8F0);
  static const veg = Color(0xFF2E7D32);
  static const nonVeg = Color(0xFFC62828);
  static const ink = Color(0xFF2B1A1F);
}

/// Poppins for headings, Inter for body (both bundled in assets/fonts, offline).
class AppTheme {
  static const headingFont = 'Poppins';
  static const bodyFont = 'Inter';

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.maroon,
      primary: AppColors.maroon,
      secondary: AppColors.gold,
      surface: Colors.white,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: bodyFont,
    );
    TextStyle? h(TextStyle? s) => s?.copyWith(fontFamily: headingFont, color: AppColors.ink);
    final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: h(base.textTheme.displaySmall),
        headlineLarge: h(base.textTheme.headlineLarge),
        headlineMedium: h(base.textTheme.headlineMedium),
        headlineSmall: h(base.textTheme.headlineSmall)?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: h(base.textTheme.titleLarge)?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: h(base.textTheme.titleMedium)?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(fontFamily: headingFont, fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.maroon.withValues(alpha: 0.08)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: rounded,
          textStyle: const TextStyle(fontFamily: headingFont, fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(shape: rounded)),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: AppColors.maroon.withValues(alpha: 0.2)),
        selectedColor: AppColors.maroon.withValues(alpha: 0.12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.gold.withValues(alpha: 0.35),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.background,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
    );
  }

  static ThemeData get dark => light;
}
