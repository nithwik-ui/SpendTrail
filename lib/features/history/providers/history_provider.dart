import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/models/expense.dart';
import '../../../core/providers/expense_provider.dart';

class HistoryFilter {
  final String? selectedCategoryId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String searchQuery;

  HistoryFilter({
    this.selectedCategoryId,
    this.startDate,
    this.endDate,
    this.searchQuery = '',
  });

  HistoryFilter copyWith({
    String? selectedCategoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    bool clearDate = false,
  }) {
    return HistoryFilter(
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      startDate: clearDate ? null : (startDate ?? this.startDate),
      endDate: clearDate ? null : (endDate ?? this.endDate),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class HistoryFilterNotifier extends StateNotifier<HistoryFilter> {
  HistoryFilterNotifier() : super(HistoryFilter());

  void setCategory(String? categoryId) {
    if (state.selectedCategoryId == categoryId) {
      state = state.copyWith(selectedCategoryId: 'all');
    } else {
      state = state.copyWith(selectedCategoryId: categoryId);
    }
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  void clearDateRange() {
    state = state.copyWith(clearDate: true);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void reset() {
    state = HistoryFilter();
  }
}

// Manage filters state
final historyFilterProvider = StateNotifierProvider<HistoryFilterNotifier, HistoryFilter>((ref) {
  return HistoryFilterNotifier();
});

// Reactively query list from SQLite
final historyExpensesProvider = FutureProvider<List<Expense>>((ref) async {
  final filter = ref.watch(historyFilterProvider);
  
  // Watch the core provider so changes (Add/Delete) refresh history reactively
  ref.watch(expenseProvider);

  final rows = await DbHelper.instance.queryFilteredExpenses(
    categoryId: filter.selectedCategoryId,
    startDate: filter.startDate,
    endDate: filter.endDate,
  );
  
  final list = rows.map((row) => Expense.fromMap(row)).toList();
  
  // Perform client-side search on notes or categories if text is provided
  if (filter.searchQuery.isNotEmpty) {
    final query = filter.searchQuery.toLowerCase();
    return list.where((exp) {
      final noteMatch = exp.note?.toLowerCase().contains(query) ?? false;
      final catMatch = exp.category.toLowerCase().contains(query);
      return noteMatch || catMatch;
    }).toList();
  }
  
  return list;
});
