import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../database/database_service.dart';
import '../providers/providers.dart';
import '../providers/currency_provider.dart';

class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key});

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();
  
  ExpenseCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // Auto-focus amount field for frictionless speed mechanic
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _amountFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _saveExpense() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty || _selectedCategory == null) return;
    
    final amount = double.tryParse(amountText);
    if (amount == null) return;

    // Provide haptic feedback on success
    HapticFeedback.mediumImpact();

    final expense = Expense(
      amount: amount,
      categoryId: _selectedCategory!.id!,
      date: DateTime.now(),
      note: _noteController.text.trim(),
    );

    await DatabaseService.instance.createExpense(expense);
    ref.invalidate(expensesProvider);
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    final currency = ref.watch(currencyProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _amountController,
            focusNode: _amountFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: '$currency ',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintStyle: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              hintText: 'Note (optional)',
            ),
          ),
          const SizedBox(height: 24),
          categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) return const SizedBox.shrink();
              _selectedCategory ??= categories.first;
              
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = _selectedCategory?.id == cat.id;
                    final catColor = Color(cat.colorValue);
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(cat.name),
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = cat;
                          });
                          HapticFeedback.selectionClick();
                        },
                        backgroundColor: catColor.withValues(alpha: 0.1),
                        selectedColor: catColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: const StadiumBorder(),
                        side: BorderSide.none,
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error: $err'),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saveExpense,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: const StadiumBorder(),
            ),
            child: const Text('Add Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
