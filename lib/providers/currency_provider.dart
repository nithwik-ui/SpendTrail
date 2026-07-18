import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

class CurrencyNotifier extends Notifier<String> {
  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('currency') ?? '₹';
  }

  void setCurrency(String symbol) {
    state = symbol;
    ref.read(sharedPreferencesProvider).setString('currency', symbol);
  }
}

final currencyProvider = NotifierProvider<CurrencyNotifier, String>(CurrencyNotifier.new);
