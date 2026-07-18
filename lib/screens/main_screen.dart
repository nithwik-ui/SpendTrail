import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'categories_screen.dart';
import 'settings_screen.dart';
import '../widgets/quick_add_sheet.dart';

import 'package:quick_actions/quick_actions.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter/services.dart';
import '../services/widget_service.dart';
import '../providers/providers.dart';
import '../providers/currency_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionsScreen(),
    const CategoriesScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initFastEntry();
  }

  void _initFastEntry() {
    // App Shortcuts
    const QuickActions quickActions = QuickActions();
    quickActions.initialize((String shortcutType) {
      if (shortcutType == 'action_add_expense') {
        _openQuickAdd();
      }
    });
    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'action_add_expense',
        localizedTitle: 'Add Expense',
        icon: 'ic_add',
      ),
    ]);

    // Home Widget Intents
    HomeWidget.initiallyLaunchedFromHomeWidget().then((Uri? uri) {
      if (uri?.host == 'quickadd') {
        _openQuickAdd();
      }
    });
    HomeWidget.widgetClicked.listen((Uri? uri) {
      if (uri?.host == 'quickadd') {
        _openQuickAdd();
      }
    });

    // Quick Settings Tile
    const platform = MethodChannel('com.spendtrail.app/quick_tile');
    
    // Check initial launch
    platform.invokeMethod<bool>('getTileLaunchState').then((launched) {
      if (launched == true) {
        _openQuickAdd();
      }
    });
    
    // Listen for events while app is running
    platform.setMethodCallHandler((call) async {
      if (call.method == 'tileClicked') {
        _openQuickAdd();
      }
    });
  }

  void _openQuickAdd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => const QuickAddSheet(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to expenses to update the home widget automatically
    ref.listen(expensesProvider, (previous, next) {
      next.whenData((expenses) {
        final currentCurrency = ref.read(currencyProvider);
        WidgetService.updateWidget(expenses, currency: currentCurrency);
      });
    });

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        indicatorColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (context) => const QuickAddSheet(),
          );
        },
        elevation: 2,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
