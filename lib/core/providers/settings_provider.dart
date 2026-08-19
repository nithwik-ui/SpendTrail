import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final double monthlyBudget;
  final String defaultCurrency;
  final bool isDarkMode;
  final String userName;
  final String userDescription;
  final String? profileImagePath;
  final bool hasCompletedOnboarding;

  SettingsState({
    required this.monthlyBudget,
    required this.defaultCurrency,
    required this.isDarkMode,
    required this.userName,
    required this.userDescription,
    this.profileImagePath,
    this.hasCompletedOnboarding = false,
  });

  SettingsState copyWith({
    double? monthlyBudget,
    String? defaultCurrency,
    bool? isDarkMode,
    String? userName,
    String? userDescription,
    String? profileImagePath,
    bool? hasCompletedOnboarding,
    bool clearProfileImage = false,
  }) {
    return SettingsState(
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      userName: userName ?? this.userName,
      userDescription: userDescription ?? this.userDescription,
      profileImagePath: clearProfileImage ? null : (profileImagePath ?? this.profileImagePath),
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier()
      : super(SettingsState(
          monthlyBudget: 12000.0,
          defaultCurrency: 'INR',
          isDarkMode: false,
          userName: 'Aarav Patel',
          userDescription: 'Computer Science, 2nd Year',
          profileImagePath: null,
          hasCompletedOnboarding: false,
        )) {
    loadSettings();
  }

  // Load preferences from local storage on launch
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCompleted = prefs.getBool('hasCompletedOnboarding') ?? false;
      if (hasCompleted) {
        state = SettingsState(
          monthlyBudget: prefs.getDouble('monthlyBudget') ?? 12000.0,
          defaultCurrency: prefs.getString('defaultCurrency') ?? 'INR',
          isDarkMode: prefs.getBool('isDarkMode') ?? false,
          userName: prefs.getString('userName') ?? 'Aarav Patel',
          userDescription: prefs.getString('userDescription') ?? 'Computer Science, 2nd Year',
          profileImagePath: prefs.getString('profileImagePath'),
          hasCompletedOnboarding: true,
        );
      }
    } catch (e) {
      // Ignore load errors, fallback to default Aarav mock details
    }
  }

  // Complete onboarding inputs
  Future<void> completeOnboarding({
    required String name,
    required double budget,
    required String currency,
    required String? profilePath,
  }) async {
    state = SettingsState(
      userName: name,
      monthlyBudget: budget,
      defaultCurrency: currency,
      isDarkMode: false,
      userDescription: 'Computer Science, 2nd Year', // default student description
      profileImagePath: profilePath,
      hasCompletedOnboarding: true,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedOnboarding', true);
    await prefs.setString('userName', name);
    await prefs.setDouble('monthlyBudget', budget);
    await prefs.setString('defaultCurrency', currency);
    if (profilePath != null) {
      await prefs.setString('profileImagePath', profilePath);
    }
  }

  Future<void> updateName(String name) async {
    state = state.copyWith(userName: name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
  }

  Future<void> restoreSettings({
    required String name,
    required double budget,
    required String currency,
    required String? profilePath,
  }) async {
    state = SettingsState(
      userName: name,
      monthlyBudget: budget,
      defaultCurrency: currency,
      isDarkMode: state.isDarkMode,
      userDescription: 'Computer Science, 2nd Year',
      profileImagePath: profilePath,
      hasCompletedOnboarding: true,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setDouble('monthlyBudget', budget);
    await prefs.setString('defaultCurrency', currency);
    if (profilePath != null) {
      await prefs.setString('profileImagePath', profilePath);
    } else {
      await prefs.remove('profileImagePath');
    }
  }

  Future<void> updateBudget(double budget) async {
    state = state.copyWith(monthlyBudget: budget);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthlyBudget', budget);
  }

  Future<void> updateCurrency(String currency) async {
    state = state.copyWith(defaultCurrency: currency);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('defaultCurrency', currency);
  }

  Future<void> toggleDarkMode(bool isDark) async {
    state = state.copyWith(isDarkMode: isDark);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  Future<void> updateProfilePhoto(String? path) async {
    if (path == null) {
      state = state.copyWith(clearProfileImage: true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profileImagePath');
    } else {
      state = state.copyWith(profileImagePath: path);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImagePath', path);
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
