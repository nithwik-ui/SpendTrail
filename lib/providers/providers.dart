import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../database/database_service.dart';

final categoriesProvider = FutureProvider<List<ExpenseCategory>>((ref) async {
  return await DatabaseService.instance.readAllCategories();
});

class SearchQueryNotifier extends Notifier<String> {
  @override String build() => '';
  void updateValue(String value) => state = value;
}
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

enum PeriodFilter { today, yesterday, last7Days, last30Days, thisMonth, lastMonth, thisYear, custom, allTime }

class PeriodFilterNotifier extends Notifier<PeriodFilter> {
  @override PeriodFilter build() => PeriodFilter.thisMonth;
  void updateValue(PeriodFilter value) => state = value;
}
final periodFilterProvider = NotifierProvider<PeriodFilterNotifier, PeriodFilter>(PeriodFilterNotifier.new);

class CustomDateRangeNotifier extends Notifier<DateTimeRange?> {
  @override DateTimeRange? build() => null;
  void updateValue(DateTimeRange? value) => state = value;
}
final customDateRangeProvider = NotifierProvider<CustomDateRangeNotifier, DateTimeRange?>(CustomDateRangeNotifier.new);

final expensesProvider = FutureProvider<List<Expense>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  List<Expense> expenses;
  if (query.isNotEmpty) {
    expenses = await DatabaseService.instance.searchExpenses(query);
  } else {
    expenses = await DatabaseService.instance.readAllExpenses();
  }
  
  final filter = ref.watch(periodFilterProvider);
  final customRange = ref.watch(customDateRangeProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  
  return expenses.where((e) {
    final d = e.date;
    final expenseDate = DateTime(d.year, d.month, d.day);
    
    switch (filter) {
      case PeriodFilter.today:
        return expenseDate == today;
      case PeriodFilter.yesterday:
        return expenseDate == today.subtract(const Duration(days: 1));
      case PeriodFilter.last7Days:
        return expenseDate.isAfter(today.subtract(const Duration(days: 7)));
      case PeriodFilter.last30Days:
        return expenseDate.isAfter(today.subtract(const Duration(days: 30)));
      case PeriodFilter.thisMonth:
        return d.year == now.year && d.month == now.month;
      case PeriodFilter.lastMonth:
        final lastMonth = now.month == 1 ? 12 : now.month - 1;
        final year = now.month == 1 ? now.year - 1 : now.year;
        return d.year == year && d.month == lastMonth;
      case PeriodFilter.thisYear:
        return d.year == now.year;
      case PeriodFilter.custom:
        if (customRange != null) {
          final start = DateTime(customRange.start.year, customRange.start.month, customRange.start.day);
          final end = DateTime(customRange.end.year, customRange.end.month, customRange.end.day, 23, 59, 59);
          return d.isAfter(start.subtract(const Duration(seconds: 1))) && d.isBefore(end.add(const Duration(seconds: 1)));
        }
        return true;
      case PeriodFilter.allTime:
        return true;
    }
  }).toList();
});

final todayTotalProvider = FutureProvider<double>((ref) async {
  final expenses = await ref.watch(expensesProvider.future);
  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  return expenses
      .where((e) => DateTime(e.date.year, e.date.month, e.date.day) == today)
      .fold<double>(0.0, (sum, item) => sum + item.amount);
});

final weekTotalProvider = FutureProvider<double>((ref) async {
  final expenses = await ref.watch(expensesProvider.future);
  final weekAgo = DateTime.now().subtract(const Duration(days: 7));
  return expenses
      .where((e) => e.date.isAfter(weekAgo))
      .fold<double>(0.0, (sum, item) => sum + item.amount);
});

final monthTotalProvider = FutureProvider<double>((ref) async {
  final expenses = await ref.watch(expensesProvider.future);
  final now = DateTime.now();
  return expenses
      .where((e) => e.date.year == now.year && e.date.month == now.month)
      .fold<double>(0.0, (sum, item) => sum + item.amount);
});
