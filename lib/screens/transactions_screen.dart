import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../providers/currency_provider.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const _FilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final filter = ref.watch(periodFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => ref.read(searchQueryProvider.notifier).updateValue(value),
                    decoration: InputDecoration(
                      hintText: 'Search note, amount, category...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.tune, color: filter != PeriodFilter.allTime ? Theme.of(context).colorScheme.primary : null),
                  onPressed: _showFilterSheet,
                ),
              ],
            ),
          ),
        ),
      ),
      body: expensesAsync.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No transactions found.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return _ExpenseListTile(expense: expense, currency: currency);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(periodFilterProvider);
    final filters = {
      PeriodFilter.today: 'Today',
      PeriodFilter.yesterday: 'Yesterday',
      PeriodFilter.last7Days: 'Last 7 Days',
      PeriodFilter.last30Days: 'Last 30 Days',
      PeriodFilter.thisMonth: 'This Month',
      PeriodFilter.lastMonth: 'Last Month',
      PeriodFilter.thisYear: 'This Year',
      PeriodFilter.custom: 'Custom Range',
      PeriodFilter.allTime: 'All Time',
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter by Date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: filters.entries.map((entry) {
                final isSelected = currentFilter == entry.key;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: FilterChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (selected) async {
                      if (entry.key == PeriodFilter.custom) {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          ref.read(customDateRangeProvider.notifier).updateValue(picked);
                          ref.read(periodFilterProvider.notifier).updateValue(PeriodFilter.custom);
                        }
                      } else {
                        ref.read(periodFilterProvider.notifier).updateValue(entry.key);
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                );
              }).toList(),
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
    final dateFormat = DateFormat('MMM d, yyyy');

    return categoriesAsync.when(
      data: (categories) {
        final category = categories.firstWhere((c) => c.id == expense.categoryId);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Color(category.colorValue).withValues(alpha: 0.2),
            child: Icon(IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'), color: Color(category.colorValue)),
          ),
          title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (expense.note.isNotEmpty) Text(expense.note, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(dateFormat.format(expense.date), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
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
