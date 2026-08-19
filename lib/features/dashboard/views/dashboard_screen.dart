import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/constants.dart';
import '../../../core/providers/expense_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/widgets/spendtrail_header.dart';
import '../../add_expense/views/add_expense_sheet.dart';
import '../../history/views/history_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseState = ref.watch(expenseProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final cardBgColor = isDark ? const Color(0xFF1E293B) : AppColors.surfaceContainerLow;
    final borderColor = isDark ? const Color(0xFF334155) : AppColors.surfaceContainer;

    // Dynamically compute progress
    final double budgetLimit = settings.monthlyBudget;
    final double spentAmount = expenseState.monthTotal;
    final double budgetPercent = budgetLimit > 0
        ? (spentAmount / budgetLimit).clamp(0.0, 1.0)
        : 0.0;
    final int progressPercent = (budgetPercent * 100).toInt();

    // Get first name for welcome greeting
    final String firstName = settings.userName.split(' ').first;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Reusable Header matching HTML layout specs
      appBar: const SpendTrailHeader(),
      body: expenseState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () => ref.read(expenseProvider.notifier).loadInitialData(),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. WELCOME GREETING
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello,',
                          style: AppConstants.getBodyLgStyle(color: secondaryTextColor),
                        ),
                        Text(
                          '$firstName 👋',
                          style: AppConstants.getHeadlineLgStyle(color: primaryTextColor).copyWith(
                            fontSize: 28.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOutCubic),
                    const SizedBox(height: 20.0),

                    // 2. BUDGET CARD (Bento Style with Circular Ring)
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(16.0), // rounded-xl (16px) audit
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          // Circular Progress Ring Indicator
                          SizedBox(
                            width: 88.0,
                            height: 88.0,
                            child: Stack(
                              children: [
                                Center(
                                  child: SizedBox(
                                    width: 80.0,
                                    height: 80.0,
                                    child: CircularProgressIndicator(
                                      value: budgetPercent,
                                      strokeWidth: 8.0,
                                      backgroundColor: AppColors.primary.withOpacity(0.1),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        budgetPercent >= 0.9 ? AppColors.tertiary : AppColors.primary,
                                      ),
                                      strokeCap: StrokeCap.round,
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.pie_chart_rounded,
                                        color: AppColors.primary,
                                        size: 18.0,
                                      ),
                                      const SizedBox(height: 2.0),
                                      Text(
                                        '$progressPercent%',
                                        style: AppConstants.getLabelSmStyle(color: primaryTextColor).copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20.0),
                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Monthly Budget',
                                  style: AppConstants.getHeadlineSmStyle(color: primaryTextColor).copyWith(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  'SPENT',
                                  style: AppConstants.getLabelSmStyle(color: secondaryTextColor).copyWith(
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  AppConstants.formatCurrency(spentAmount),
                                  style: AppConstants.getDisplayCurrencyStyle(color: primaryTextColor).copyWith(
                                    fontSize: 32.0,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  'of ${AppConstants.formatCurrency(budgetLimit)} limit',
                                  style: AppConstants.getBodyMdStyle(color: secondaryTextColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 450.ms, curve: Curves.easeOutCubic).slideY(begin: 0.05, end: 0),
                    const SizedBox(height: 16.0),

                    // 3. QUICK ACTIONS GRID (Glassmorphism-lite style)
                    Row(
                      children: [
                        // Scan & Pay Button
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Scan & Pay: Coming soon!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryContainer.withOpacity(isDark ? 0.08 : 0.25),
                                border: Border.all(
                                  color: AppColors.secondaryContainer.withOpacity(isDark ? 0.15 : 0.4),
                                ),
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32.0,
                                    height: 32.0,
                                    decoration: const BoxDecoration(
                                      color: AppColors.secondaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.qr_code_scanner_rounded,
                                      color: AppColors.secondary,
                                      size: 18.0,
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Text(
                                    'Scan & Pay',
                                    style: AppConstants.getLabelMdStyle(color: primaryTextColor).copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        // Split Bill Button
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _showSplitBillDialog(context);
                            },
                            borderRadius: BorderRadius.circular(16.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
                              decoration: BoxDecoration(
                                color: AppColors.tertiary.withOpacity(0.08),
                                border: Border.all(
                                  color: AppColors.tertiary.withOpacity(0.15),
                                ),
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32.0,
                                    height: 32.0,
                                    decoration: BoxDecoration(
                                      color: AppColors.tertiary.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.receipt_rounded,
                                      color: AppColors.tertiary,
                                      size: 18.0,
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Text(
                                    'Split Bill',
                                    style: AppConstants.getLabelMdStyle(color: primaryTextColor).copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 500.ms, curve: Curves.easeOutCubic),
                    const SizedBox(height: 28.0),

                    // 4. RECENT TRANSACTIONS HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Transactions',
                          style: AppConstants.getHeadlineSmStyle(color: primaryTextColor),
                        ),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const HistoryScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'See all',
                            style: AppConstants.getLabelMdStyle(color: AppColors.primary).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),

                    // 5. TRANSACTIONS LIST (Grouped by Today/Yesterday)
                    expenseState.recentExpenses.isEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 40.0),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16.0),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long_rounded,
                                  size: 48.0,
                                  color: secondaryTextColor.withOpacity(0.3),
                                ),
                                const SizedBox(height: 12.0),
                                Text(
                                  'No spends logged today. Tap + to start!',
                                  style: AppConstants.getLabelMdStyle(color: secondaryTextColor),
                                ),
                              ],
                            ),
                          )
                        : _buildGroupedRecentSpends(
                            context,
                            ref,
                            expenseState.recentExpenses,
                            isDark,
                            borderColor,
                            primaryTextColor,
                            secondaryTextColor,
                          ),
                  ],
                ),
              ),
            ),
      // Action Floating Action Button
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {
          HapticFeedback.lightImpact();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddExpenseSheet(),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // rounded-xl (16px) audit
        ),
        child: const Icon(Icons.add_rounded, size: 36.0),
      ),
    );
  }

  Widget _buildGroupedRecentSpends(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> expenses,
    bool isDark,
    Color borderColor,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    // Separate into Today and Yesterday/Older
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todaySpends = expenses.where((exp) {
      final expDate = DateTime(exp.date.year, exp.date.month, exp.date.day);
      return expDate == today;
    }).toList();

    final olderSpends = expenses.where((exp) {
      final expDate = DateTime(exp.date.year, exp.date.month, exp.date.day);
      return expDate != today;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (todaySpends.isNotEmpty) ...[
          _buildGroupHeader('Today', secondaryTextColor),
          const SizedBox(height: 6.0),
          _buildSpendsList(context, ref, todaySpends, isDark, borderColor, primaryTextColor, secondaryTextColor),
          const SizedBox(height: 16.0),
        ],
        if (olderSpends.isNotEmpty) ...[
          _buildGroupHeader(
            olderSpends.any((exp) {
              final expDate = DateTime(exp.date.year, exp.date.month, exp.date.day);
              return expDate == yesterday;
            }) ? 'Yesterday' : 'Older Spends',
            secondaryTextColor,
          ),
          const SizedBox(height: 6.0),
          _buildSpendsList(context, ref, olderSpends, isDark, borderColor, primaryTextColor, secondaryTextColor),
        ],
      ],
    );
  }

  Widget _buildGroupHeader(String label, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        label.toUpperCase(),
        style: AppConstants.getLabelSmStyle(color: textColor).copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSpendsList(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> spends,
    bool isDark,
    Color borderColor,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return Column(
      children: List.generate(spends.length, (index) {
        final expense = spends[index];
        final category = AppConstants.getCategoryById(expense.category);

        return Dismissible(
          key: Key('recent-${expense.id}'),
          background: Container(
            decoration: BoxDecoration(
              color: AppColors.tertiary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(
              Icons.delete_sweep_rounded,
              color: AppColors.tertiary,
              size: 24.0,
            ),
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
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Row(
                  children: [
                    // Icon inside rounded container
                    Container(
                      width: 48.0,
                      height: 48.0,
                      decoration: BoxDecoration(
                        color: category.color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12.0), // rounded-md
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
                          Text(
                            category.name,
                            style: AppConstants.getLabelSmStyle(color: secondaryTextColor),
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
              // Thin divider, aligned like HTML list
              if (index < spends.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 62.0),
                  child: Divider(
                    height: 1.0,
                    thickness: 1.0,
                    color: borderColor.withOpacity(0.5),
                  ),
                ),
            ],
          ).animate().fadeIn(delay: (index * 50).ms, duration: 300.ms, curve: Curves.easeOutCubic).slideX(begin: 0.05, end: 0),
        );
      }),
    );
  }

  void _showSplitBillDialog(BuildContext context) {
    final totalController = TextEditingController();
    final peopleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

        return AlertDialog(
          title: Text(
            'Split Bill',
            style: AppConstants.getHeadlineSmStyle(color: AppColors.primary).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: totalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Total Bill Amount (${AppConstants.defaultCurrencySymbol})',
                  labelStyle: AppConstants.getLabelSmStyle(color: AppColors.textSecondary),
                ),
                style: AppConstants.getBodyMdStyle(color: primaryTextColor),
              ),
              const SizedBox(height: 12.0),
              TextField(
                controller: peopleController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Number of Friends',
                  labelStyle: AppConstants.getLabelSmStyle(color: AppColors.textSecondary),
                ),
                style: AppConstants.getBodyMdStyle(color: primaryTextColor),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppConstants.getLabelMdStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final double? total = double.tryParse(totalController.text.trim());
                final int? people = int.tryParse(peopleController.text.trim());

                if (total == null || people == null || people <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid split parameters')),
                  );
                  return;
                }

                final split = total / people;
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Each person owes: ${AppConstants.formatCurrency(split)}',
                      style: AppConstants.getLabelMdStyle(color: Colors.white),
                    ),
                    backgroundColor: AppColors.primary,
                    duration: const Duration(seconds: 4),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(
                'Split',
                style: AppConstants.getLabelMdStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
