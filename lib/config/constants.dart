import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand Colors (Warm Minimalist Notebook Palette)
  static const Color primary = Color(0xFF00535B); // Deep Teal
  static const Color primaryContainer = Color(0xFF006D77); // Muted Teal Accent
  static const Color onPrimary = Colors.white;
  
  static const Color secondary = Color(0xFF236863); // Soft Mint (Used for active items / income)
  static const Color secondaryContainer = Color(0xFFA9ECE5);
  
  static const Color tertiary = Color(0xFF743B24); // Warm Sand / Terracotta (Used for expense indicator)
  
  static const Color error = Color(0xFFBA1A1A); // Rose Red
  static const Color errorContainer = Color(0xFFFFDAD6);

  // Background / Surface Colors (Cream notebook paper)
  static const Color paperBg = Color(0xFFFCF9F8); // Warm Cream Paper
  static const Color surfaceContainerLow = Color(0xFFF6F3F2);
  static const Color surfaceContainer = Color(0xFFF0EDED);
  static const Color surfaceContainerHigh = Color(0xFFEAE7E7);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  // Typography Colors
  static const Color textPrimary = Color(0xFF1B1C1C); // Dark Charcoal
  static const Color textSecondary = Color(0xFF3E494A); // Slate/Charcoal Variant
  
  // Borders
  static const Color outline = Color(0xFF6F797A);
  static const Color outlineVariant = Color(0xFFBEC8CA);

  // Sleek Dark Theme Colors
  static const Color darkBg = Color(0xFF090E11);
  static const Color darkCard = Color(0xFF141C22);
  static const Color darkTextPrimary = Color(0xFFF0F4F8);
  static const Color darkTextSecondary = Color(0xFF90A0B0);
  static const Color darkBorder = Color(0xFF222D37);
}

class AppCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const AppCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class AppConstants {
  static const String appName = 'SpendTrail';
  static const String defaultCurrencySymbol = '₹';

  // Categories aligned with visual layout
  static const List<AppCategory> categories = [
    AppCategory(
      id: 'food',
      name: 'Food',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFD35400),
    ),
    AppCategory(
      id: 'travel',
      name: 'Travel',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF2980B9),
    ),
    AppCategory(
      id: 'hostel',
      name: 'Hostel',
      icon: Icons.bed_rounded,
      color: Color(0xFFE67E22),
    ),
    AppCategory(
      id: 'shopping',
      name: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFFC0392B),
    ),
    AppCategory(
      id: 'academics',
      name: 'Academics',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF16A085),
    ),
    AppCategory(
      id: 'entertainment',
      name: 'Entertainment',
      icon: Icons.play_circle_fill_rounded,
      color: Color(0xFF27AE60),
    ),
    AppCategory(
      id: 'bills',
      name: 'Bills',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFF8E44AD),
    ),
    AppCategory(
      id: 'others',
      name: 'Other',
      icon: Icons.more_horiz_rounded,
      color: Color(0xFF7F8C8D),
    ),
  ];

  // Helper to format currency dynamically
  static String formatCurrency(double amount, {String symbol = defaultCurrencySymbol}) {
    if (amount % 1 == 0) {
      return '$symbol${amount.toInt().toString()}';
    }
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  // Get Category by ID helper
  static AppCategory getCategoryById(String id) {
    return categories.firstWhere(
      (cat) => cat.id == id,
      orElse: () => categories.last, // Fallback to 'Others'
    );
  }

  // Curated Text Styles pairing Montserrat and Inter
  static TextStyle getDisplayCurrencyStyle({Color color = AppColors.textPrimary}) {
    return GoogleFonts.montserrat(
      fontSize: 40.0,
      fontWeight: FontWeight.bold,
      color: color,
      height: 1.2,
      letterSpacing: -1.0,
    );
  }

  static TextStyle getHeadlineLgStyle({Color color = AppColors.textPrimary}) {
    return GoogleFonts.montserrat(
      fontSize: 28.0, //headline-lg-mobile from DESIGN.md
      fontWeight: FontWeight.bold,
      color: color,
      height: 1.25,
    );
  }

  static TextStyle getHeadlineMdStyle({Color color = AppColors.textPrimary}) {
    return GoogleFonts.montserrat(
      fontSize: 24.0,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.3,
    );
  }

  static TextStyle getHeadlineSmStyle({Color color = AppColors.textPrimary}) {
    return GoogleFonts.montserrat(
      fontSize: 20.0,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.4,
    );
  }

  static TextStyle getBodyLgStyle({Color color = AppColors.textPrimary}) {
    return GoogleFonts.inter(
      fontSize: 18.0,
      fontWeight: FontWeight.normal,
      color: color,
      height: 1.55,
    );
  }

  static TextStyle getBodyMdStyle({Color color = AppColors.textPrimary}) {
    return GoogleFonts.inter(
      fontSize: 16.0,
      fontWeight: FontWeight.normal,
      color: color,
      height: 1.5,
    );
  }

  static TextStyle getLabelMdStyle({Color color = AppColors.textSecondary}) {
    return GoogleFonts.inter(
      fontSize: 14.0,
      fontWeight: FontWeight.w500,
      color: color,
      height: 1.4,
      letterSpacing: 0.5,
    );
  }

  static TextStyle getLabelSmStyle({Color color = AppColors.textSecondary}) {
    return GoogleFonts.inter(
      fontSize: 12.0,
      fontWeight: FontWeight.w500,
      color: color,
      height: 1.3,
    );
  }
}
