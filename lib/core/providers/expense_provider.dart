import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/db_helper.dart';
import '../models/expense.dart';

class ExpenseState {
  final List<Expense> recentExpenses;
  final double todayTotal;
  final double monthTotal;
  final bool isLoading;

  ExpenseState({
    required this.recentExpenses,
    required this.todayTotal,
    required this.monthTotal,
    this.isLoading = false,
  });

  ExpenseState copyWith({
    List<Expense>? recentExpenses,
    double? todayTotal,
    double? monthTotal,
    bool? isLoading,
  }) {
    return ExpenseState(
      recentExpenses: recentExpenses ?? this.recentExpenses,
      todayTotal: todayTotal ?? this.todayTotal,
      monthTotal: monthTotal ?? this.monthTotal,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final DbHelper _dbHelper = DbHelper.instance;

  ExpenseNotifier()
      : super(ExpenseState(recentExpenses: [], todayTotal: 0.0, monthTotal: 0.0)) {
    loadInitialData();
  }

  // Load initial data from SQLite
  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true);
    try {
      final recentRows = await _dbHelper.queryRecentExpenses(15);
      final recent = recentRows.map((row) => Expense.fromMap(row)).toList();
      
      final today = await _dbHelper.getTodayTotalSpend();
      final month = await _dbHelper.getMonthTotalSpend();

      state = ExpenseState(
        recentExpenses: recent,
        todayTotal: today,
        monthTotal: month,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      // Handle error cleanly in production
    }
  }

  // Add Expense flow with optimistic UI updates
  Future<void> addExpense(Expense expense) async {
    final originalState = state;

    // 1. Optimistic Update: Update UI instantly
    final updatedExpenses = [expense, ...state.recentExpenses];
    if (updatedExpenses.length > 15) {
      updatedExpenses.removeLast(); // Keep recent list bounded
    }

    final isToday = _isSameDay(expense.date, DateTime.now());
    final isThisMonth = _isSameMonth(expense.date, DateTime.now());

    state = state.copyWith(
      recentExpenses: updatedExpenses,
      todayTotal: isToday ? state.todayTotal + expense.amount : state.todayTotal,
      monthTotal: isThisMonth ? state.monthTotal + expense.amount : state.monthTotal,
    );

    // 2. Perform DB write in background
    try {
      final insertedId = await _dbHelper.insertExpense(expense.toMap());
      
      // Update the temp ID of the optimistic expense with the actual auto-increment ID
      final updatedListWithId = state.recentExpenses.map((exp) {
        if (exp == expense) {
          return exp.copyWith(id: insertedId);
        }
        return exp;
      }).toList();
      
      state = state.copyWith(recentExpenses: updatedListWithId);
    } catch (e) {
      // Revert state if DB write fails
      state = originalState;
    }
  }

  // Delete Expense
  Future<void> deleteExpense(int id, double amount, DateTime date) async {
    final originalState = state;

    // Optimistic remove
    final updatedExpenses = state.recentExpenses.where((exp) => exp.id != id).toList();
    final isToday = _isSameDay(date, DateTime.now());
    final isThisMonth = _isSameMonth(date, DateTime.now());

    state = state.copyWith(
      recentExpenses: updatedExpenses,
      todayTotal: isToday ? state.todayTotal - amount : state.todayTotal,
      monthTotal: isThisMonth ? state.monthTotal - amount : state.monthTotal,
    );

    try {
      await _dbHelper.deleteExpense(id);
    } catch (e) {
      // Revert if database write fails
      state = originalState;
    }
  }

  // Helpers
  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  bool _isSameMonth(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month;
  }
}

// Global provider for expense state
final expenseProvider = StateNotifierProvider<ExpenseNotifier, ExpenseState>((ref) {
  return ExpenseNotifier();
});
