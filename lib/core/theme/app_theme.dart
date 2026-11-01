import 'package:flutter/material.dart';

/// Brand palette from the brief.
class AppColors {
  static const maroon = Color(0xFF8B1E3F);
  static const gold = Color(0xFFF4B400);
  static const background = Color(0xFFFFF8F0);
}

/// Poppins for headings, Inter for body. The font files go in assets/fonts/
/// (see README "Pending"); until then Flutter falls back to the default font.
class AppTheme {
  static const headingFont = 'Poppins';
  static const bodyFont = 'Inter';

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.maroon,
      primary: AppColors.maroon,
      secondary: AppColors.gold,
      surface: AppColors.background,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: bodyFont,
    );
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displayLarge: base.textTheme.displayLarge?.copyWith(fontFamily: headingFont),
        displayMedium: base.textTheme.displayMedium?.copyWith(fontFamily: headingFont),
        displaySmall: base.textTheme.displaySmall?.copyWith(fontFamily: headingFont),
        headlineLarge: base.textTheme.headlineLarge?.copyWith(fontFamily: headingFont),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(fontFamily: headingFont),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(fontFamily: headingFont),
        titleLarge: base.textTheme.titleLarge?.copyWith(fontFamily: headingFont),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.maroon,
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData get dark => light;
}
