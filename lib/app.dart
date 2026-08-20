import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/constants.dart';
import 'core/providers/settings_provider.dart';
import 'features/dashboard/views/home_navigation_parent.dart';
import 'features/onboarding/views/onboarding_screen.dart';

class SpendTrailApp extends ConsumerWidget {
  const SpendTrailApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    // Generate text themes with Inter as default and Montserrat for headers
    final interTextTheme = GoogleFonts.interTextTheme();
    final montserratTextTheme = GoogleFonts.montserratTextTheme();

    final textTheme = interTextTheme.copyWith(
      displayLarge: montserratTextTheme.displayLarge,
      displayMedium: montserratTextTheme.displayMedium,
      displaySmall: montserratTextTheme.displaySmall,
      headlineLarge: montserratTextTheme.headlineLarge,
      headlineMedium: montserratTextTheme.headlineMedium,
      headlineSmall: montserratTextTheme.headlineSmall,
    );

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      
      // Theme toggling driven reactively by settings provider
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Warm Cream Paper Theme (Default Light Theme from Stitch)
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.paperBg,
        primaryColor: AppColors.primary,
        textTheme: textTheme,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surfaceContainerLowest,
          onSurface: AppColors.textPrimary,
          background: AppColors.paperBg,
          outline: AppColors.outline,
          outlineVariant: AppColors.outlineVariant,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surfaceContainerLowest,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // 16px radius audit
            side: const BorderSide(color: AppColors.surfaceContainer, width: 1),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.paperBg,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
      ),

      // Premium Dark Theme
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBg,
        primaryColor: AppColors.primaryContainer,
        textTheme: textTheme,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryContainer,
          secondary: AppColors.secondary,
          surface: AppColors.darkCard,
          onSurface: AppColors.darkTextPrimary,
          background: AppColors.darkBg,
          outline: AppColors.darkBorder,
          outlineVariant: Color(0xFF1E2833),
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: const BorderSide(color: AppColors.darkBorder, width: 1),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkBg,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
        ),
      ),
      
      // Launch into bottom-navigation layout parent
      home: settings.hasCompletedOnboarding
          ? const HomeNavigationParent()
          : const OnboardingScreen(),
    );
  }
}
