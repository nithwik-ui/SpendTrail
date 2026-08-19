import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/constants.dart';
import '../../../core/models/expense.dart';
import '../../../core/widgets/spendtrail_header.dart';
import '../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  // Groups current period expenses by category
  Map<AppCategory, _CategoryMetric> _calculateCategoryMetrics(List<Expense> expenses, double total) {
    final Map<String, double> categorySums = {};
    for (final exp in expenses) {
      categorySums[exp.category] = (categorySums[exp.category] ?? 0.0) + exp.amount;
    }

    final Map<AppCategory, _CategoryMetric> metrics = {};
    for (final cat in AppConstants.categories) {
      final double sum = categorySums[cat.id] ?? 0.0;
      if (sum > 0.0) {
        final double percentage = total > 0.0 ? (sum / total) * 100.0 : 0.0;
        metrics[cat] = _CategoryMetric(amount: sum, percentage: percentage);
      }
    }
    return metrics;
  }

  // Helper to construct trend bar data
  List<BarChartGroupData> _buildTrendBarGroups(List<Expense> expenses, bool isDark) {
    if (expenses.isEmpty) return [];

    // Group sums by date key (YYYY-MM-DD)
    final Map<String, double> dailySums = {};
    final DateTime now = DateTime.now();

    // Determine number of days to show based on dataset
    final int displayDays = 7; // Show last 7 active days for clean visual layout
    
    // Aggregate last 7 days
    for (int i = 0; i < displayDays; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      dailySums[dateKey] = 0.0;
    }

    for (final exp in expenses) {
      final dateKey = "${exp.date.year}-${exp.date.month.toString().padLeft(2, '0')}-${exp.date.day.toString().padLeft(2, '0')}";
      if (dailySums.containsKey(dateKey)) {
        dailySums[dateKey] = dailySums[dateKey]! + exp.amount;
      }
    }

    final List<BarChartGroupData> groups = [];
    final List<String> sortedKeys = dailySums.keys.toList()..sort();

    for (int index = 0; index < sortedKeys.length; index++) {
      final val = dailySums[sortedKeys[index]] ?? 0.0;
      groups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: val == 0.0 ? 50.0 : val, // Minimal visual bar placeholder if zero
              color: val == 0.0 
                  ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))
                  : AppColors.primary,
              width: 14.0,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4.0),
                topRight: Radius.circular(4.0),
              ),
            ),
          ],
        ),
      );
    }
    return groups;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final cardBgColor = isDark ? const Color(0xFF121212) : AppColors.surfaceContainerLowest;
    final borderColor = isDark ? const Color(0xFF222222) : AppColors.surfaceContainer;

    // Calculate metrics
    final totalSpent = state.currentTotal;
    final prevTotal = state.previousTotal;
    final metrics = _calculateCategoryMetrics(state.currentPeriodExpenses, totalSpent);

    // Calculate comparative variance
    double variancePercentage = 0.0;
    bool isIncrease = true;
    if (prevTotal > 0.0) {
      variancePercentage = ((totalSpent - prevTotal) / prevTotal) * 100.0;
      isIncrease = variancePercentage >= 0.0;
    } else if (totalSpent > 0.0) {
      variancePercentage = 100.0;
      isIncrease = true;
    }

    // Sort category metrics by amount descending
    final sortedCategories = metrics.keys.toList()
      ..sort((a, b) => (metrics[b]?.amount ?? 0.0).compareTo(metrics[a]?.amount ?? 0.0));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const SpendTrailHeader(),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                HapticFeedback.lightImpact();
                await ref.read(analyticsProvider.notifier).loadAnalytics();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. HEADER & RANGE DROPDOWN SELECTOR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Insights',
                          style: AppConstants.getHeadlineLgStyle(color: AppColors.primary).copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 26.0,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A1A1A) : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: borderColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: state.selectedFilter,
                              dropdownColor: cardBgColor,
                              style: AppConstants.getLabelSmStyle(color: primaryTextColor).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              items: const [
                                DropdownMenuItem(value: 'this_month', child: Text('This Month')),
                                DropdownMenuItem(value: 'last_month', child: Text('Last Month')),
                                DropdownMenuItem(value: 'last_3_months', child: Text('Last 3 Months')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  HapticFeedback.selectionClick();
                                  ref.read(analyticsProvider.notifier).setFilter(val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20.0),

                    if (state.currentPeriodExpenses.isEmpty) ...[
                      // EMPTY STATE VIEW
                      const SizedBox(height: 60.0),
                      Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: borderColor, style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              size: 72.0,
                              color: secondaryTextColor.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              'No insights available yet',
                              style: AppConstants.getHeadlineSmStyle(color: primaryTextColor).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Add some transactions on the Home screen to populate charts.',
                              style: AppConstants.getBodyMdStyle(color: secondaryTextColor),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOutCubic),
                    ] else ...[
                      // 2. TOTAL SPENT CARD WITH VARIANCES
                      Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.transparent : Colors.black.withOpacity(0.02),
                              blurRadius: 12.0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Total Spent',
                              style: AppConstants.getLabelSmStyle(color: secondaryTextColor).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              AppConstants.formatCurrency(totalSpent),
                              style: AppConstants.getHeadlineLgStyle(color: AppColors.primary).copyWith(
                                fontSize: 36.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            // Variation Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: isIncrease 
                                    ? AppColors.error.withOpacity(0.08) 
                                    : AppColors.secondary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isIncrease ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                    size: 14.0,
                                    color: isIncrease ? AppColors.error : AppColors.secondary,
                                  ),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    '${variancePercentage.abs().toStringAsFixed(0)}% vs previous period',
                                    style: AppConstants.getLabelSmStyle(
                                      color: isIncrease ? AppColors.error : AppColors.secondary,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOutCubic),

                      const SizedBox(height: 20.0),

                      // 3. CATEGORY DONUT CHART & METRICS
                      Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Breakdown',
                              style: AppConstants.getHeadlineSmStyle(color: primaryTextColor).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24.0),
                            // Donut Chart container
                            Center(
                              child: SizedBox(
                                height: 160.0,
                                width: 160.0,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 3,
                                    centerSpaceRadius: 46,
                                    sections: sortedCategories.map((cat) {
                                      final metric = metrics[cat]!;
                                      return PieChartSectionData(
                                        color: cat.color,
                                        value: metric.amount,
                                        title: '', // Hide label inside chart slices
                                        radius: 18.0,
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24.0),
                            // Detailed list
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: sortedCategories.length,
                              separatorBuilder: (context, index) => const Divider(height: 1.0, thickness: 0.5),
                              itemBuilder: (context, index) {
                                final cat = sortedCategories[index];
                                final metric = metrics[cat]!;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          color: cat.color.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(cat.icon, color: cat.color, size: 20.0),
                                      ),
                                      const SizedBox(width: 12.0),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              cat.name,
                                              style: AppConstants.getBodyMdStyle(color: primaryTextColor).copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2.0),
                                            Text(
                                              '${metric.percentage.toStringAsFixed(0)}% of total',
                                              style: AppConstants.getLabelSmStyle(color: secondaryTextColor),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        AppConstants.formatCurrency(metric.amount),
                                        style: AppConstants.getBodyMdStyle(color: primaryTextColor).copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutCubic),

                      const SizedBox(height: 20.0),

                      // 4. DAILY TREND BAR CHART
                      Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Daily Trend',
                                  style: AppConstants.getHeadlineSmStyle(color: primaryTextColor).copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Active Days',
                                  style: AppConstants.getLabelSmStyle(color: secondaryTextColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28.0),
                            SizedBox(
                              height: 180.0,
                              child: BarChart(
                                BarChartData(
                                  barGroups: _buildTrendBarGroups(state.currentPeriodExpenses, isDark),
                                  borderData: FlBorderData(show: false),
                                  gridData: const FlGridData(show: false),
                                  titlesData: FlTitlesData(
                                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (val, meta) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 6.0),
                                            child: Text(
                                              'D${val.toInt() + 1}',
                                              style: AppConstants.getLabelSmStyle(
                                                color: secondaryTextColor.withOpacity(0.5),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutCubic),
                    ],
                    const SizedBox(height: 32.0),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CategoryMetric {
  final double amount;
  final double percentage;

  const _CategoryMetric({required this.amount, required this.percentage});
}
