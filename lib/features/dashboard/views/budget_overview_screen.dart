import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/constants.dart';
import '../../../core/providers/expense_provider.dart';
import '../../../core/providers/settings_provider.dart';

class BudgetOverviewScreen extends ConsumerStatefulWidget {
  const BudgetOverviewScreen({super.key});

  @override
  ConsumerState<BudgetOverviewScreen> createState() => _BudgetOverviewScreenState();
}

class _BudgetOverviewScreenState extends ConsumerState<BudgetOverviewScreen> {
  late TextEditingController _budgetEditController;

  @override
  void initState() {
    super.initState();
    _budgetEditController = TextEditingController();
  }

  @override
  void dispose() {
    _budgetEditController.dispose();
    super.dispose();
  }

  void _showEditBudgetDialog(double currentBudget) {
    _budgetEditController.text = currentBudget.toInt().toString();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final cardBgColor = theme.cardTheme.color ?? (isDark ? AppColors.darkCard : AppColors.surfaceContainerLowest);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardBgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
          title: Text(
            'Adjust Budget Limit',
            style: AppConstants.getHeadlineSmStyle(color: primaryTextColor).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Set your monthly spending budget limit.',
                style: AppConstants.getBodyMdStyle(color: secondaryTextColor),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _budgetEditController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: AppConstants.getHeadlineSmStyle(color: primaryTextColor),
                decoration: InputDecoration(
                  prefixText: '${AppConstants.defaultCurrencySymbol} ',
                  prefixStyle: AppConstants.getHeadlineSmStyle(color: AppColors.primary),
                  hintText: 'e.g. 15000',
                  hintStyle: AppConstants.getBodyMdStyle(color: secondaryTextColor),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E2630) : AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppConstants.getLabelMdStyle(color: secondaryTextColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final double? newBudget = double.tryParse(_budgetEditController.text);
                if (newBudget != null && newBudget > 0) {
                  ref.read(settingsProvider.notifier).updateBudget(newBudget);
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Budget limit updated to ${AppConstants.formatCurrency(newBudget)}'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final cardBgColor = theme.cardTheme.color ?? (isDark ? AppColors.darkCard : AppColors.surfaceContainerLowest);
    final borderColor = isDark ? AppColors.darkBorder : AppColors.surfaceContainer;

    final double budgetLimit = settings.monthlyBudget;
    final double spentAmount = expenseState.monthTotal;
    final double remainingBudget = (budgetLimit - spentAmount).clamp(0.0, double.infinity);
    final double budgetPercent = budgetLimit > 0
        ? (spentAmount / budgetLimit).clamp(0.0, 1.0)
        : 0.0;
    
    // Days calculation for Daily Allowance
    final now = DateTime.now();
    final totalDaysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final daysRemaining = (totalDaysInMonth - now.day + 1).clamp(1, 31);
    final daysPassed = now.day;

    final double dailyAllowance = remainingBudget / daysRemaining;
    final double projectedSpend = daysPassed > 0
        ? (spentAmount / daysPassed) * totalDaysInMonth
        : spentAmount;

    // Status warning text & color
    final double percentUsed = budgetPercent * 100;
    String statusMessage = 'On Track';
    Color statusColor = AppColors.secondary;
    if (percentUsed >= 100.0) {
      statusMessage = 'Budget Exceeded!';
      statusColor = AppColors.error;
    } else if (percentUsed >= 85.0) {
      statusMessage = 'Critical: Close to Limit';
      statusColor = AppColors.tertiary;
    } else if (percentUsed >= 60.0) {
      statusMessage = 'Approaching Half-Point';
      statusColor = AppColors.primary;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Wallet & Budget',
          style: AppConstants.getHeadlineSmStyle(color: primaryTextColor).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. MAIN CARD (Budget remaining and ring)
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Text(
                    'REMAINING BUDGET',
                    style: AppConstants.getLabelSmStyle(color: secondaryTextColor).copyWith(
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    AppConstants.formatCurrency(remainingBudget),
                    style: AppConstants.getHeadlineLgStyle(color: primaryTextColor).copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Circular Ring with remaining percentage
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 160.0,
                        height: 160.0,
                        child: CircularProgressIndicator(
                          value: 1.0 - budgetPercent,
                          strokeWidth: 16.0,
                          backgroundColor: isDark ? const Color(0xFF1E2630) : AppColors.surfaceContainerHigh,
                          color: statusColor,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            '${(100.0 - percentUsed).toInt()}%',
                            style: AppConstants.getHeadlineMdStyle(color: primaryTextColor).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Left',
                            style: AppConstants.getLabelSmStyle(color: secondaryTextColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),

                  // Spend statistics
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Spent so far',
                            style: AppConstants.getLabelSmStyle(color: secondaryTextColor),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            AppConstants.formatCurrency(spentAmount),
                            style: AppConstants.getBodyMdStyle(color: primaryTextColor).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          statusMessage,
                          style: AppConstants.getLabelSmStyle(color: statusColor).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total Limit',
                            style: AppConstants.getLabelSmStyle(color: secondaryTextColor),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            AppConstants.formatCurrency(budgetLimit),
                            style: AppConstants.getBodyMdStyle(color: primaryTextColor).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),

            // 2. METRICS & ANALYSIS SECTION
            Text(
              'BUDGET DETAILS & FORECAST',
              style: AppConstants.getLabelSmStyle(color: secondaryTextColor).copyWith(
                letterSpacing: 1.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),

            // Bento Grid for details
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    height: 124.0,
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.today_rounded, color: AppColors.primary, size: 22.0),
                        const SizedBox(height: 8.0),
                        Text(
                          'Daily Allowance',
                          style: AppConstants.getLabelSmStyle(color: secondaryTextColor),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          AppConstants.formatCurrency(dailyAllowance),
                          style: AppConstants.getBodyMdStyle(color: primaryTextColor).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    height: 124.0,
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.trending_up_rounded, color: AppColors.tertiary, size: 22.0),
                        const SizedBox(height: 8.0),
                        Text(
                          'Forecasted Spend',
                          style: AppConstants.getLabelSmStyle(color: secondaryTextColor),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          AppConstants.formatCurrency(projectedSpend),
                          style: AppConstants.getBodyMdStyle(color: primaryTextColor).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),

            // 3. EDIT BUTTON
            ElevatedButton.icon(
              onPressed: () => _showEditBudgetDialog(budgetLimit),
              icon: const Icon(Icons.edit_rounded, size: 18.0),
              label: Text(
                'Adjust Budget Limit',
                style: AppConstants.getLabelMdStyle(color: Colors.white).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
