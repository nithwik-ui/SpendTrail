import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryTeal = Color(0xFF00535B);
  static const Color mutedTeal = Color(0xFF236863);
  static const Color deepCharcoal = Color(0xFF181C1D);
  static const Color offWhite = Color(0xFFF7FAFB);
  static const Color darkCharcoal = Color(0xFF1A1C1D);

  // Spacing & Border Radius
  static const double spacingBase = 8.0;
  static const double paddingContainer = 24.0;
  static const double radiusStandard = 8.0;
  static const double radiusLarge = 16.0;

  static TextTheme _buildTextTheme(TextTheme base, Color color) {
    return GoogleFonts.interTextTheme(base).copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 44,
        fontWeight: FontWeight.w600,
        height: 52 / 44,
        letterSpacing: -0.02,
        color: color,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 40 / 32,
        letterSpacing: -0.02,
        color: color,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        letterSpacing: -0.01,
        color: color,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 24 / 18,
        color: color,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: color,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: color,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        letterSpacing: 0.05,
        color: color,
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        primary: primaryTeal,
        secondary: mutedTeal,
        surface: offWhite,
        onSurface: deepCharcoal,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: offWhite,
      textTheme: _buildTextTheme(base.textTheme, deepCharcoal),
      appBarTheme: AppBarTheme(
        backgroundColor: offWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: deepCharcoal),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: deepCharcoal,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: offWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLarge)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE0E3E4)),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE0E3E4)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: primaryTeal, width: 2.0),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    final Color desaturatedPrimary = HSLColor.fromColor(primaryTeal)
        .withSaturation(
            (HSLColor.fromColor(primaryTeal).saturation - 0.15).clamp(0.0, 1.0))
        .toColor();

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: desaturatedPrimary,
        primary: desaturatedPrimary,
        secondary: mutedTeal,
        surface: darkCharcoal,
        onSurface: Colors.white,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkCharcoal,
      textTheme: _buildTextTheme(base.textTheme, Colors.white),
      appBarTheme: AppBarTheme(
        backgroundColor: darkCharcoal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkCharcoal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLarge)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: desaturatedPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF3E494A)),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF3E494A)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: desaturatedPrimary, width: 2.0),
        ),
      ),
    );
  }
}
