import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Romantic & Intimate Palette
  static const Color plum = Color(0xFF2C0E28);
  static const Color plumLight = Color(0xFF6B4867);
  static const Color deepBerry = Color(0xFF6B113B);
  static const Color crimson = Color(0xFFC0264D);
  static const Color roseGold = Color(0xFFE2847A);
  static const Color blush = Color(0xFFFDE8E9);
  static const Color backgroundLight = Color(0xFFFAF7F5);
  static const Color cardLight = Colors.white;

  // Stitch Warm Romantic Surface Tokens
  static const Color surfaceContainerLow = Color(0xFFFFEFF7);
  static const Color surfaceContainer = Color(0xFFFFE7F6);
  static const Color surfaceContainerHigh = Color(0xFFFFDFF4);
  static const Color onSurfaceVariant = Color(0xFF544247);
  static const Color secondaryContainer = Color(0xFFFE5678);
  static const Color primaryFixed = Color(0xFFFFD9E3);
  static const Color primaryFixedDim = Color(0xFFFFB0C9);

  // Status Colors for Fertility
  static const Color safeGreen = Color(0xFF10B981);
  static const Color safeGreenBg = Color(0xFFE8F5E9);
  static const Color cautionAmber = Color(0xFFF59E0B);
  static const Color cautionAmberBg = Color(0xFFFEF3C7);
  static const Color fertileRed = Color(0xFFEF4444);
  static const Color fertileRedBg = Color(0xFFFEE2E2);
  static const Color periodPurple = Color(0xFF8B5CF6);
  static const Color periodPurpleBg = Color(0xFFEDE9FE);

  static ThemeData get lightTheme {
    final outfitFont = GoogleFonts.outfit().fontFamily;

    return ThemeData(
      useMaterial3: true,
      fontFamily: outfitFont,
      colorScheme: ColorScheme.fromSeed(
        seedColor: deepBerry,
        primary: deepBerry,
        secondary: roseGold,
        surface: cardLight,
      ),
      scaffoldBackgroundColor: backgroundLight,
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: blush.withValues(alpha: 0.8), width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepBerry,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: deepBerry,
          side: const BorderSide(color: deepBerry, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundLight,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: plum),
        titleTextStyle: TextStyle(
          fontFamily: outfitFont,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: plum,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 4,
        indicatorColor: blush,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: plum,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: plumLight,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: crimson, size: 24);
          }
          return const IconThemeData(color: plumLight, size: 24);
        }),
      ),
    );
  }
}
