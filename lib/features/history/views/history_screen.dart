import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/constants.dart';
import '../../../core/models/expense.dart';
import '../../../core/providers/expense_provider.dart';
import '../../../core/widgets/spendtrail_header.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(historyFilterProvider);
    _searchController = TextEditingController(text: filter.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(historyFilterProvider);
    final historyState = ref.watch(historyExpensesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final cardBgColor = isDark ? const Color(0xFF1E293B) : AppColors.surfaceContainerLowest;
    final inputBgColor = isDark ? const Color(0xFF0F172A) : AppColors.surfaceContainerLow;
    final borderColor = isDark ? const Color(0xFF334155) : AppColors.surfaceContainer;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Custom SpendTrail AppBar
      appBar: const SpendTrailHeader(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. SEARCH & FILTER HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Column(
              children: [
                // Search Input Field
                Container(
                  height: 48.0,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: inputBgColor,
                    borderRadius: BorderRadius.circular(12.0), // rounded-xl (12px)
                    border: Border.all(color: borderColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: secondaryTextColor.withOpacity(0.5)),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search transactions...',
                            hintStyle: AppConstants.getBodyMdStyle(color: secondaryTextColor.withOpacity(0.5)),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          style: AppConstants.getBodyMdStyle(color: primaryTextColor),
                          onChanged: (val) {
                            ref.read(historyFilterProvider.notifier).setSearchQuery(val);
                          },
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _searchController.clear();
                            ref.read(historyFilterProvider.notifier).setSearchQuery('');
                          },
                          child: Icon(Icons.clear_rounded, color: secondaryTextColor),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),

                // Filter chips and date selector
                SizedBox(
                  height: 40.0,
                  child: Row(
                    children: [
                      // Horizontal scroll chips
                      Expanded(
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            // "All" Chip
                            _buildChoiceChip(
                              label: 'All',
                              isSelected: filter.selectedCategoryId == null || filter.selectedCategoryId == 'all',
                              onSelected: (_) {
                                HapticFeedback.lightImpact();
                                ref.read(historyFilterProvider.notifier).setCategory(null);
                              },
                              cardBgColor: cardBgColor,
                              borderColor: borderColor,
                              secondaryTextColor: secondaryTextColor,
                            ),
                            const SizedBox(width: 8.0),
                            // Category chips
                            ...AppConstants.categories.map((cat) {
                              final isSelected = filter.selectedCategoryId == cat.id;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: _buildChoiceChip(
                                  label: cat.name.split(' ').first, // match HTML space
                                  isSelected: isSelected,
                                  onSelected: (_) {
                                    HapticFeedback.lightImpact();
                                    ref.read(historyFilterProvider.notifier).setCategory(cat.id);
                                  },
                                  activeColor: cat.color,
                                  cardBgColor: cardBgColor,
                                  borderColor: borderColor,
                                  secondaryTextColor: secondaryTextColor,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      // Date Selector circular button
                      InkWell(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            initialDateRange: filter.startDate != null && filter.endDate != null
                                ? DateTimeRange(start: filter.startDate!, end: filter.endDate!)
                                : null,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AppColors.primary,
                                    onPrimary: Colors.white,
                                    surface: AppColors.surfaceContainerLowest,
                                    onSurface: AppColors.textPrimary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            ref.read(historyFilterProvider.notifier).setDateRange(picked.start, picked.end);
                          }
                        },
                        borderRadius: BorderRadius.circular(20.0),
                        child: Container(
                          width: 40.0,
                          height: 40.0,
                          decoration: BoxDecoration(
                            color: filter.startDate != null
                                ? AppColors.primary.withOpacity(0.08)
                                : inputBgColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: filter.startDate != null ? AppColors.primary : borderColor,
                            ),
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 18.0,
                            color: filter.startDate != null ? AppColors.primary : secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),

          // 2. GROUPED TRANSACTIONS LIST
          Expanded(
            child: historyState.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, stack) => Center(
                child: Text('Failed to load: $err', style: AppConstants.getBodyMdStyle(color: AppColors.tertiary)),
              ),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return _buildEmptyState(cardBgColor, borderColor, secondaryTextColor);
                }

                // Group by Month Year
                final grouped = _groupExpensesByMonth(expenses);
                final monthKeys = grouped.keys.toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  itemCount: monthKeys.length,
                  itemBuilder: (context, index) {
                    final monthTitle = monthKeys[index];
                    final monthSpends = grouped[monthTitle]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Section Header: "OCTOBER 2023"
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 16.0, bottom: 8.0),
                          child: Text(
                            monthTitle.toUpperCase(),
                            style: AppConstants.getLabelSmStyle(color: secondaryTextColor).copyWith(
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Monthly Card Container containing all items
                        Container(
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(16.0), // rounded-xl (16px) audit
                            border: Border.all(color: borderColor.withOpacity(0.5)),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: List.generate(monthSpends.length, (idx) {
                              final expense = monthSpends[idx];
                              return _buildTransactionRow(
                                context,
                                ref,
                                expense,
                                idx == monthSpends.length - 1,
                                borderColor,
                                primaryTextColor,
                                secondaryTextColor,
                              );
                            }),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
    Color? activeColor,
    required Color cardBgColor,
    required Color borderColor,
    required Color secondaryTextColor,
  }) {
    final chipColor = activeColor ?? AppColors.primary;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: chipColor.withOpacity(0.12),
      checkmarkColor: chipColor,
      backgroundColor: cardBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(
          color: isSelected ? chipColor : borderColor,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      labelStyle: AppConstants.getLabelSmStyle(
        color: isSelected ? chipColor : secondaryTextColor,
      ).copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
    );
  }

  Widget _buildTransactionRow(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
    bool isLast,
    Color borderColor,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    final category = AppConstants.getCategoryById(expense.category);

    return Dismissible(
      key: Key('hist-row-${expense.id}'),
      background: Container(
        color: AppColors.tertiary.withOpacity(0.12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete_rounded, color: AppColors.tertiary),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        HapticFeedback.mediumImpact();
        if (expense.id != null) {
          ref.read(expenseProvider.notifier).deleteExpense(
                expense.id!,
                expense.amount,
                expense.date,
              );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Spend deleted successfully')),
          );
        }
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                // Category Icon Circle Container
                Container(
                  width: 48.0,
                  height: 48.0,
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Icon(
                    category.icon,
                    color: category.color,
                    size: 22.0,
                  ),
                ),
                const SizedBox(width: 14.0),
                // Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.note != null && expense.note!.isNotEmpty
                            ? expense.note!
                            : category.name,
                        style: AppConstants.getBodyMdStyle(color: primaryTextColor).copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Text(
                            category.name,
                            style: AppConstants.getLabelSmStyle(color: secondaryTextColor),
                          ),
                          const SizedBox(width: 6.0),
                          Container(width: 4.0, height: 4.0, decoration: BoxDecoration(shape: BoxShape.circle, color: secondaryTextColor.withOpacity(0.4))),
                          const SizedBox(width: 6.0),
                          Text(
                            _formatDayAndMonth(expense.date),
                            style: AppConstants.getLabelSmStyle(color: secondaryTextColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Amount
                Text(
                  '-${AppConstants.formatCurrency(expense.amount)}',
                  style: AppConstants.getHeadlineSmStyle(color: primaryTextColor).copyWith(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (!isLast)
            Padding(
              padding: const EdgeInsets.only(left: 78.0),
              child: Divider(
                height: 1.0,
                thickness: 1.0,
                color: borderColor.withOpacity(0.4),
              ),
            ),
        ],
      ).animate().fadeIn(duration: 250.ms, curve: Curves.easeOutCubic).slideX(begin: 0.05, end: 0),
    );
  }

  Widget _buildEmptyState(Color cardBgColor, Color borderColor, Color secondaryTextColor) {
    return Container(
      margin: const EdgeInsets.all(20.0),
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_rounded, size: 64.0, color: secondaryTextColor.withOpacity(0.3)),
          const SizedBox(height: 16.0),
          Text(
            'No spends match active filters.',
            style: AppConstants.getBodyMdStyle(color: secondaryTextColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Monthly date grouping helper
  Map<String, List<Expense>> _groupExpensesByMonth(List<Expense> expenses) {
    final Map<String, List<Expense>> grouped = {};
    for (var exp in expenses) {
      final key = _getMonthGroupKey(exp.date);
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(exp);
    }
    return grouped;
  }

  String _getMonthGroupKey(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDayAndMonth(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}';
  }
}
