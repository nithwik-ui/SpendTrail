import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/models/expense.dart';
import '../../../core/providers/expense_provider.dart';

class AnalyticsState {
  final List<Expense> currentPeriodExpenses;
  final List<Expense> previousPeriodExpenses;
  final double currentTotal;
  final double previousTotal;
  final String selectedFilter; // 'this_month', 'last_month', 'last_3_months'
  final bool isLoading;

  AnalyticsState({
    required this.currentPeriodExpenses,
    required this.previousPeriodExpenses,
    required this.currentTotal,
    required this.previousTotal,
    required this.selectedFilter,
    this.isLoading = false,
  });

  AnalyticsState copyWith({
    List<Expense>? currentPeriodExpenses,
    List<Expense>? previousPeriodExpenses,
    double? currentTotal,
    double? previousTotal,
    String? selectedFilter,
    bool? isLoading,
  }) {
    return AnalyticsState(
      currentPeriodExpenses: currentPeriodExpenses ?? this.currentPeriodExpenses,
      previousPeriodExpenses: previousPeriodExpenses ?? this.previousPeriodExpenses,
      currentTotal: currentTotal ?? this.currentTotal,
      previousTotal: previousTotal ?? this.previousTotal,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final DbHelper _dbHelper = DbHelper.instance;

  AnalyticsNotifier()
      : super(AnalyticsState(
          currentPeriodExpenses: [],
          previousPeriodExpenses: [],
          currentTotal: 0.0,
          previousTotal: 0.0,
          selectedFilter: 'this_month',
        )) {
    loadAnalytics();
  }

  Future<void> setFilter(String filter) async {
    if (state.selectedFilter == filter) return;
    state = state.copyWith(selectedFilter: filter, isLoading: true);
    await loadAnalytics();
  }

  Future<void> loadAnalytics() async {
    state = state.copyWith(isLoading: true);
    try {
      final now = DateTime.now();
      DateTime currentStart;
      DateTime currentEnd;
      DateTime prevStart;
      DateTime prevEnd;

      if (state.selectedFilter == 'this_month') {
        currentStart = DateTime(now.year, now.month, 1);
        currentEnd = now;

        // Previous month full range
        prevStart = DateTime(now.year, now.month - 1, 1);
        prevEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
      } else if (state.selectedFilter == 'last_month') {
        currentStart = DateTime(now.year, now.month - 1, 1);
        currentEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

        prevStart = DateTime(now.year, now.month - 2, 1);
        prevEnd = DateTime(now.year, now.month - 1, 0, 23, 59, 59);
      } else {
        // last_3_months
        currentStart = now.subtract(const Duration(days: 90));
        currentEnd = now;

        prevStart = now.subtract(const Duration(days: 180));
        prevEnd = now.subtract(const Duration(days: 90));
      }

      // Fetch current period
      final currentRows = await _dbHelper.queryFilteredExpenses(
        startDate: currentStart,
        endDate: currentEnd,
      );
      final currentList = currentRows.map((r) => Expense.fromMap(r)).toList();
      final currentSum = currentList.fold<double>(0.0, (sum, exp) => sum + exp.amount);

      // Fetch previous period
      final prevRows = await _dbHelper.queryFilteredExpenses(
        startDate: prevStart,
        endDate: prevEnd,
      );
      final prevList = prevRows.map((r) => Expense.fromMap(r)).toList();
      final prevSum = prevList.fold<double>(0.0, (sum, exp) => sum + exp.amount);

      state = AnalyticsState(
        currentPeriodExpenses: currentList,
        previousPeriodExpenses: prevList,
        currentTotal: currentSum,
        previousTotal: prevSum,
        selectedFilter: state.selectedFilter,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

// Analytics provider
final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  // Reload analytics when the core expense database updates
  ref.watch(expenseProvider);
  return AnalyticsNotifier();
});
