import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../providers/currency_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final todayTotalAsync = ref.watch(todayTotalProvider);
    final weekTotalAsync = ref.watch(weekTotalProvider);
    final monthTotalAsync = ref.watch(monthTotalProvider);
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Today',
                          amountAsync: todayTotalAsync,
                          currency: currency,
                          color: Theme.of(context).colorScheme.primaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'This Week',
                          amountAsync: weekTotalAsync,
                          currency: currency,
                          color: Theme.of(context).colorScheme.secondaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SummaryCard(
                    title: 'This Month',
                    amountAsync: monthTotalAsync,
                    currency: currency,
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    isLarge: true,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Recent Transactions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          expensesAsync.when(
            data: (expenses) {
              if (expenses.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('No expenses yet.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text('Tap + to add your first expense.', style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ),
                );
              }
              
              final recentExpenses = expenses.take(5).toList();
              
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final expense = recentExpenses[index];
                    return _ExpenseListTile(expense: expense, currency: currency);
                  },
                  childCount: recentExpenses.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, st) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)), // Bottom padding
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final AsyncValue<double> amountAsync;
  final String currency;
  final Color color;
  final bool isLarge;

  const _SummaryCard({
    required this.title,
    required this.amountAsync,
    required this.currency,
    required this.color,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.black87, fontSize: isLarge ? 16 : 14)),
            const SizedBox(height: 8),
            amountAsync.when(
              data: (amount) => TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: amount),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Text(
                    '$currency${value.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isLarge ? 32 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  );
                },
              ),
              loading: () => const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, st) => const Text('Error', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseListTile extends ConsumerWidget {
  final dynamic expense;
  final String currency;

  const _ExpenseListTile({required this.expense, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        final category = categories.firstWhere((c) => c.id == expense.categoryId);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Color(category.colorValue).withValues(alpha: 0.2),
            child: Icon(IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'), color: Color(category.colorValue)),
          ),
          title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(expense.note.isEmpty ? 'No note' : expense.note),
          trailing: Text(
            '-$currency${expense.amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        );
      },
      loading: () => const ListTile(title: Text('Loading...')),
      error: (e, st) => const ListTile(title: Text('Error')),
    );
  }
}
