import 'dart:math' as math;
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

  // ─── Category metrics calculation ─────────────────────────────────
  Map<AppCategory, _CategoryMetric> _calculateCategoryMetrics(
      List<Expense> expenses, double total) {
    final Map<String, double> categorySums = {};
    for (final exp in expenses) {
      categorySums[exp.category] =
          (categorySums[exp.category] ?? 0.0) + exp.amount;
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

  // ─── Build 30-day bar groups for Daily Trend ──────────────────────
  List<BarChartGroupData> _buildTrendBarGroups(
      List<Expense> expenses, bool isDark) {
    final DateTime now = DateTime.now();
    const int displayDays = 30;

    // Build daily sums for last 30 days
    final Map<int, double> dailySums = {};
    for (int i = 0; i < displayDays; i++) {
      dailySums[i] = 0.0;
    }

    for (final exp in expenses) {
      final int daysAgo = now.difference(exp.date).inDays;
      if (daysAgo >= 0 && daysAgo < displayDays) {
        final int index = displayDays - 1 - daysAgo; // 0 = oldest, 29 = today
        dailySums[index] = (dailySums[index] ?? 0.0) + exp.amount;
      }
    }

    // Find max for relative sizing
    final double maxVal =
        dailySums.values.fold(0.0, (a, b) => math.max(a, b));

    final List<BarChartGroupData> groups = [];
    for (int i = 0; i < displayDays; i++) {
      final double val = dailySums[i] ?? 0.0;
      final bool hasValue = val > 0;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: hasValue ? val : (maxVal > 0 ? maxVal * 0.03 : 50.0),
              color: hasValue
                  ? AppColors.primary
                  : (isDark
                      ? const Color(0xFF1E2430)
                      : const Color(0xFFE2E8F0)),
              width: 6.0,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3.0),
                topRight: Radius.circular(3.0),
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

    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final cardBgColor =
        isDark ? AppColors.darkCard : AppColors.surfaceContainerLowest;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.surfaceContainer;

    // Calculate metrics
    final totalSpent = state.currentTotal;
    final prevTotal = state.previousTotal;
    final metrics =
        _calculateCategoryMetrics(state.currentPeriodExpenses, totalSpent);

    // Variance
    double variancePercentage = 0.0;
    bool isIncrease = true;
    if (prevTotal > 0.0) {
      variancePercentage = ((totalSpent - prevTotal) / prevTotal) * 100.0;
      isIncrease = variancePercentage >= 0.0;
    } else if (totalSpent > 0.0) {
      variancePercentage = 100.0;
      isIncrease = true;
    }

    // Sort categories descending
    final sortedCategories = metrics.keys.toList()
      ..sort((a, b) =>
          (metrics[b]?.amount ?? 0.0).compareTo(metrics[a]?.amount ?? 0.0));

    // ─── Card decorator ───────────────────────────────────────────────
    BoxDecoration cardDecoration() => BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
              color: borderColor.withOpacity(isDark ? 0.5 : 0.7), width: 0.5),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 16.0,
                offset: const Offset(0, 6),
              ),
          ],
        );

    // ─── Smooth spring curve ──────────────────────────────────────────
    const springCurve = Curves.easeOutCubic;
    const animDuration = Duration(milliseconds: 500);

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
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ──── 1. HEADER & RANGE DROPDOWN ────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Insights',
                          style: AppConstants.getHeadlineLgStyle(
                                  color: AppColors.primary)
                              .copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 28.0,
                          ),
                        ),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14.0),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1A1A1A)
                                : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14.0),
                            border: Border.all(color: borderColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: state.selectedFilter,
                              dropdownColor: cardBgColor,
                              style: AppConstants.getLabelSmStyle(
                                      color: primaryTextColor)
                                  .copyWith(fontWeight: FontWeight.bold),
                              icon: Icon(Icons.keyboard_arrow_down_rounded,
                                  color: primaryTextColor, size: 20.0),
                              items: const [
                                DropdownMenuItem(
                                    value: 'this_month',
                                    child: Text('This Month')),
                                DropdownMenuItem(
                                    value: 'last_month',
                                    child: Text('Last Month')),
                                DropdownMenuItem(
                                    value: 'last_3_months',
                                    child: Text('Last 3 Months')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  HapticFeedback.selectionClick();
                                  ref
                                      .read(analyticsProvider.notifier)
                                      .setFilter(val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20.0),

                    if (state.currentPeriodExpenses.isEmpty) ...[
                      // ──── EMPTY STATE ─────────────────────────────
                      const SizedBox(height: 60.0),
                      Container(
                        padding: const EdgeInsets.all(32.0),
                        decoration: cardDecoration(),
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
                              style: AppConstants.getHeadlineSmStyle(
                                      color: primaryTextColor)
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Add some transactions on the Home screen to populate charts.',
                              style: AppConstants.getBodyMdStyle(
                                  color: secondaryTextColor),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(
                          duration: animDuration, curve: springCurve),
                    ] else ...[
                      // ──── 2. TOTAL SPENT CARD ─────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 24.0, horizontal: 20.0),
                        decoration: cardDecoration(),
                        child: Column(
                          children: [
                            Text(
                              'Total Spent',
                              style: AppConstants.getLabelSmStyle(
                                      color: secondaryTextColor)
                                  .copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.0,
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            Text(
                              AppConstants.formatCurrency(totalSpent),
                              style: AppConstants.getHeadlineLgStyle(
                                      color: AppColors.primary)
                                  .copyWith(
                                fontSize: 38.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -1.2,
                              ),
                            ),
                            const SizedBox(height: 10.0),
                            // Variance badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 5.0),
                              decoration: BoxDecoration(
                                color: isIncrease
                                    ? AppColors.error.withOpacity(0.08)
                                    : AppColors.secondary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isIncrease
                                        ? Icons.trending_up_rounded
                                        : Icons.trending_down_rounded,
                                    size: 15.0,
                                    color: isIncrease
                                        ? AppColors.error
                                        : AppColors.secondary,
                                  ),
                                  const SizedBox(width: 5.0),
                                  Text(
                                    '${isIncrease ? '+' : ''}${variancePercentage.abs().toStringAsFixed(0)}% vs last month',
                                    style: AppConstants.getLabelSmStyle(
                                      color: isIncrease
                                          ? AppColors.error
                                          : AppColors.secondary,
                                    ).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: animDuration, curve: springCurve)
                          .slideY(
                              begin: 0.06,
                              end: 0,
                              duration: animDuration,
                              curve: springCurve),

                      const SizedBox(height: 16.0),

                      // ──── 3. BREAKDOWN DONUT CHART ────────────────
                      Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Breakdown',
                              style: AppConstants.getHeadlineSmStyle(
                                      color: primaryTextColor)
                                  .copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 20.0,
                              ),
                            ),
                            const SizedBox(height: 28.0),
                            // Donut chart with center icon
                            Center(
                              child: SizedBox(
                                height: 200.0,
                                width: 200.0,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    PieChart(
                                      PieChartData(
                                        sectionsSpace: 3,
                                        centerSpaceRadius: 56,
                                        sections:
                                            sortedCategories.map((cat) {
                                          final metric = metrics[cat]!;
                                          return PieChartSectionData(
                                            color: cat.color,
                                            value: metric.amount,
                                            title: '',
                                            radius: 28.0,
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    // Center logo icon
                                    Container(
                                      width: 48.0,
                                      height: 48.0,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDark
                                            ? const Color(0xFF1A1A1A)
                                            : const Color(0xFFF5F5F5),
                                      ),
                                      child: Icon(
                                        Icons.currency_rupee_rounded,
                                        size: 22.0,
                                        color:
                                            secondaryTextColor.withOpacity(0.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(
                              delay: 80.ms,
                              duration: animDuration,
                              curve: springCurve)
                          .slideY(
                              begin: 0.06,
                              end: 0,
                              delay: 80.ms,
                              duration: animDuration,
                              curve: springCurve),

                      const SizedBox(height: 16.0),

                      // ──── 4. CATEGORIES LIST CARD ─────────────────
                      Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Categories',
                              style: AppConstants.getHeadlineSmStyle(
                                      color: primaryTextColor)
                                  .copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 20.0,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            ...List.generate(sortedCategories.length, (index) {
                              final cat = sortedCategories[index];
                              final metric = metrics[cat]!;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10.0),
                                child: Row(
                                  children: [
                                    // Category icon bubble
                                    Container(
                                      padding: const EdgeInsets.all(10.0),
                                      decoration: BoxDecoration(
                                        color: cat.color.withOpacity(0.10),
                                        borderRadius:
                                            BorderRadius.circular(14.0),
                                      ),
                                      child: Icon(cat.icon,
                                          color: cat.color, size: 22.0),
                                    ),
                                    const SizedBox(width: 14.0),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cat.name,
                                            style:
                                                AppConstants.getBodyMdStyle(
                                                        color:
                                                            primaryTextColor)
                                                    .copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15.0,
                                            ),
                                          ),
                                          const SizedBox(height: 2.0),
                                          Text(
                                            '${metric.percentage.toStringAsFixed(0)}% of total',
                                            style:
                                                AppConstants.getLabelSmStyle(
                                                    color:
                                                        secondaryTextColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      AppConstants.formatCurrency(
                                          metric.amount),
                                      style: AppConstants.getBodyMdStyle(
                                              color: primaryTextColor)
                                          .copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.0,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                                  .animate()
                                  .fadeIn(
                                      delay: Duration(
                                          milliseconds: 160 + index * 60),
                                      duration: 350.ms,
                                      curve: springCurve)
                                  .slideX(
                                      begin: 0.05,
                                      end: 0,
                                      delay: Duration(
                                          milliseconds: 160 + index * 60),
                                      duration: 350.ms,
                                      curve: springCurve);
                            }),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(
                              delay: 160.ms,
                              duration: animDuration,
                              curve: springCurve)
                          .slideY(
                              begin: 0.06,
                              end: 0,
                              delay: 160.ms,
                              duration: animDuration,
                              curve: springCurve),

                      const SizedBox(height: 16.0),

                      // ──── 5. DAILY TREND BAR CHART ────────────────
                      Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Daily Trend',
                                  style: AppConstants.getHeadlineSmStyle(
                                          color: primaryTextColor)
                                      .copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20.0,
                                  ),
                                ),
                                Text(
                                  'Last 30 days',
                                  style: AppConstants.getLabelSmStyle(
                                      color: secondaryTextColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28.0),
                            SizedBox(
                              height: 160.0,
                              child: BarChart(
                                BarChartData(
                                  barGroups: _buildTrendBarGroups(
                                      state.currentPeriodExpenses, isDark),
                                  borderData: FlBorderData(show: false),
                                  gridData: const FlGridData(show: false),
                                  barTouchData: BarTouchData(
                                    touchTooltipData: BarTouchTooltipData(
                                      tooltipBorderRadius: BorderRadius.circular(10.0),
                                      getTooltipItem: (group, groupIndex,
                                          rod, rodIndex) {
                                        return BarTooltipItem(
                                          AppConstants.formatCurrency(rod.toY),
                                          TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12.0,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    leftTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    rightTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: 6,
                                        getTitlesWidget: (val, meta) {
                                          final int dayIndex = val.toInt();
                                          if (dayIndex % 6 != 0) {
                                            return const SizedBox.shrink();
                                          }
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              '${dayIndex + 1}',
                                              style:
                                                  AppConstants.getLabelSmStyle(
                                                color: secondaryTextColor
                                                    .withOpacity(0.5),
                                              ).copyWith(fontSize: 10.0),
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
                      )
                          .animate()
                          .fadeIn(
                              delay: 240.ms,
                              duration: animDuration,
                              curve: springCurve)
                          .slideY(
                              begin: 0.06,
                              end: 0,
                              delay: 240.ms,
                              duration: animDuration,
                              curve: springCurve),
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
