import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import '../../app/providers/sales_provider.dart';
import '../../data/models/sales_data.dart';
import '../../shared/widgets/growbox_card.dart';
import '../../shared/widgets/growbox_filter_chip.dart';
import '../../shared/widgets/growbox_page_header.dart';
import '../../shared/widgets/growbox_status_pill.dart';
import '../../shared/widgets/growbox_table.dart';
import '../../shared/widgets/growbox_table_action.dart';
import '../../shared/widgets/growbox_empty_state.dart';
import '../../shared/widgets/growbox_responsive_grid.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  /// Fixed width of the trailing Actions column — the same 96px the
  /// Dashboard's Recent Orders table uses, so the right-aligned heading
  /// and every row's reserved cell share one right gutter with the other
  /// two tables.
  static const double _actionsColWidth = 96;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GrowboxPageHeader(
            subtitle: 'Revenue, earnings and transactions from completed orders',
          ),
          const SizedBox(height: AppDimensions.lg),
          _buildPeriodFilter(context, isDark),
          const SizedBox(height: AppDimensions.xl),
          _buildSummaryCards(context, isDark),
          const SizedBox(height: AppDimensions.xl),
          _buildSalesChart(context, isDark),
          const SizedBox(height: AppDimensions.xl),
          _buildTransactionsTable(context, isDark),
        ],
      ),
    );
  }

  // ── PERIOD FILTER ──
  Widget _buildPeriodFilter(BuildContext context, bool isDark) {
    final provider = context.watch<SalesProvider>();
    final periods = [
      _PeriodOption(label: 'All', value: 'all'),
      _PeriodOption(label: 'Today', value: 'today'),
      _PeriodOption(label: 'This Week', value: 'week'),
      _PeriodOption(label: 'This Month', value: 'month'),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: periods.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.sm),
        itemBuilder: (context, index) {
          final period = periods[index];
          final isSelected = provider.selectedPeriod == period.value;

          return GrowboxFilterChip(
            label: period.label,
            selected: isSelected,
            onSelected: (_) => provider.setPeriod(period.value),
          );
        },
      ),
    );
  }

  // ── SUMMARY — 1 primary metric, 3 secondary ──
  Widget _buildSummaryCards(BuildContext context, bool isDark) {
    final provider = context.watch<SalesProvider>();
    final summary = provider.summary;
    final period = provider.selectedPeriod;

    final primary = _SummaryCard(
      title: 'Total Sales',
      value: formatCurrency(summary.totalSales),
    );
    // 'All' shows the raw total only — no sparkline, no comparison. The
    // other filters get a trend line plus a correctly labelled change vs
    // the equivalent previous window (yesterday / last week / last month).
    final showComparison = period != 'all';
    final sparkSpots =
        showComparison ? _sparkSpots(provider.transactions, period) : const <FlSpot>[];
    final sparkDelta =        showComparison ? provider.revenueDelta(period) : null;
    final cards = [
      _SummaryCard(
        title: 'Vendor Earnings',
        value: formatCurrency(summary.vendorEarnings),
        icon: Icons.savings_outlined,
      ),
      _SummaryCard(
        title: 'Commission',
        value: formatCurrency(summary.growboxCommission),
        icon: Icons.payments_outlined,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPrimaryCard(context, primary, isDark, sparkSpots, sparkDelta,
            period),
        const SizedBox(height: AppDimensions.lg),
        GrowboxResponsiveGrid(
          items: [
            ResponsiveGridItem(
              _buildSummaryCard(context, cards[0], isDark),
            ),
            ResponsiveGridItem(
              _buildSummaryCard(context, cards[1], isDark),
            ),
            // Full row on the narrow layout so there's no orphaned empty cell;
            // at 3 columns it sits alongside the two single-span cards.
            ResponsiveGridItem(
              _buildOrderStatusDoughnut(context, isDark, summary),
              narrowSpan: 2,
              wideSpan: 1,
            ),
          ],
        ),
      ],
    );
  }

  // Primary metric — the one thing the eye should land on.
  // Sparkline + delta badge mirror the dashboard hero and follow the
  // selected period filter.
  Widget _buildPrimaryCard(
    BuildContext context,
    _SummaryCard card,
    bool isDark,
    List<FlSpot> sparkSpots,
    double? sparkDelta,
    String period,
  ) {
    final hasSpark = sparkSpots.length >= 2;
    final minY = hasSpark ? sparkSpots.map((s) => s.y).reduce((a, b) => a < b ? a : b) : 0.0;
    final maxY = hasSpark ? sparkSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b) : 1.0;

    return GrowboxCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            card.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    card.value,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      height: 1.05,
                    ),
                  ),
                ),
              ),
              if (hasSpark) ...[
                const SizedBox(width: 16),
                SizedBox(
                  width: 96,
                  height: 36,
                  child: LineChart(
                    LineChartData(
                      minY: minY * 0.96,
                      maxY: maxY * 1.04,
                      lineTouchData: LineTouchData(enabled: false),
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: sparkSpots,
                          isCurved: true,
                          color: isDark ? AppColors.darkPrimary : AppColors.success,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (sparkDelta != null) ...[
            const SizedBox(height: 10),
            _changeBadge(sparkDelta, isDark, period: period),
          ],
        ],
      ),
    );
  }  // Delta pill — trend arrow + change vs the equivalent previous window.
  // Neutral (grey, flat icon) when the change is exactly 0%.
  Widget _changeBadge(double deltaPct, bool isDark, {required String period}) {
    final neutral = deltaPct == 0;
    final positive = deltaPct > 0;
    final note = switch (period) {
      'today' => 'vs yesterday',
      'week' => 'vs last week',
      'month' => 'vs last month',
      _ => 'vs previous period',
    };

    final Color color;
    final Color bg;
    final IconData icon;
    if (neutral) {
      color = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
      bg = isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
      icon = Icons.trending_flat;
    } else if (positive) {
      color = isDark ? AppColors.darkPrimary : AppColors.success;
      bg = isDark
          ? AppColors.success.withValues(alpha: 0.15)
          : AppColors.successLight;
      icon = Icons.trending_up;
    } else {
      color = AppColors.error;
      bg = isDark
          ? AppColors.error.withValues(alpha: 0.15)
          : AppColors.errorLight;
      icon = Icons.trending_down;
    }

    final text =
        '${neutral ? '' : (positive ? '+' : '')}${deltaPct.toStringAsFixed(1)}% $note';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Period-aware revenue series for the sparkline: transactions bucketed by
  // hour for 'today', by day otherwise. Completed (revenue-bearing)
  // transactions only, so the line always agrees with the Total Sales card.
  List<FlSpot> _sparkSpots(List<TransactionRecord> txns, String period) {
    final grouped = <String, double>{};
    for (final t in txns) {
      if (t.status != 'completed') continue;
      final d = t.date;
      final key = period == 'today'
          ? '${d.hour.toString().padLeft(2, '0')}:00'
          : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      grouped[key] = (grouped[key] ?? 0) + t.totalAmount;
    }
    final keys = grouped.keys.toList()..sort();
    if (keys.isEmpty) return const [];
    final spots = [
      for (var i = 0; i < keys.length; i++) FlSpot(i.toDouble(), grouped[keys[i]]!),
    ];
    // A single point draws nothing on a line chart — flatten it instead.
    if (spots.length == 1) return [spots.first, FlSpot(1, spots.first.y)];
    return spots;
  }

  Widget _buildSummaryCard(BuildContext context, _SummaryCard card, bool isDark) {
    return GrowboxCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              card.icon,
              size: 18,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            card.value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            card.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── ORDER STATUS DOUGHNUT ──
  Widget _buildOrderStatusDoughnut(
    BuildContext context,
    bool isDark,
    SalesSummary summary,
  ) {
    final completed = summary.completedOrders.toDouble();
    final total = summary.totalOrders > 0 ? summary.totalOrders.toDouble() : 1.0;
    final pending = total - completed;
    final pct = total > 0 ? (completed / total * 100).round() : 0;

    return GrowboxCard(
      padding: const EdgeInsets.all(14),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Icon + label (same structure as other cards)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.pie_chart_outline,
                  size: 18,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${summary.completedOrders}/${summary.totalOrders}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Completed Orders',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          // Donut chart pinned to the far right of the full-width card
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: SizedBox(
                height: 56,
                width: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 18,
                        sections: [
                          PieChartSectionData(
                            value: completed,
                            color: AppColors.success,
                            radius: 8,
                            title: '',
                          ),
                          PieChartSectionData(
                            value: pending,
                            color: isDark ? AppColors.darkBorder : AppColors.border,
                            radius: 8,
                            title: '',
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SALES CHART ──
  Widget _buildSalesChart(BuildContext context, bool isDark) {
    final provider = context.watch<SalesProvider>();
    final chartData = provider.chartData;
    // Round, evenly spaced ticks starting at 0: a "nice" step targeting
    // ~5 intervals, with the top snapped up to a multiple of it so the
    // highest label can never overlap the plot edge (the old free-range
    // axis produced colliding "107k" labels and hid the zero).
    final maxAmount = chartData.isNotEmpty
        ? chartData.map((e) => e.amount).reduce((a, b) => a > b ? a : b)
        : 0.0;
    final axis = _niceAxis(maxAmount);

    return GrowboxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Weekly Sales',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: axis.maxY,
                barTouchData: BarTouchData(
                  // Built-in touches cover tap (touch) and hover (mouse/web).
                  mouseCursorResolver: (
                    FlTouchEvent event,
                    BarTouchResponse? response,
                  ) =>
                      SystemMouseCursors.click,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.textPrimary,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${chartData[groupIndex].label} · ${formatCurrency(rod.toY)}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < chartData.length) {
                          return Text(
                            chartData[index].label,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: axis.interval,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _axisLabel(value),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: chartData.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.amount,
                        color: AppColors.primary,
                        width: 18,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppDimensions.radiusSm),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // "Nice" chart axis: a round step (1/2/2.5/5 × 10ⁿ) targeting ~5
  // intervals, with the top snapped up to a whole multiple of it — ticks
  // are evenly spaced, start at 0, and the top label always sits exactly
  // on the plot's upper bound instead of colliding with its neighbour.
  ({double maxY, double interval}) _niceAxis(double maxValue) {
    if (maxValue <= 0) return (maxY: 1000, interval: 500);
    final target = maxValue / 5;
    final magnitude =
        math.pow(10, (math.log(target) / math.ln10).floor()).toDouble();
    final step = [1, 2, 2.5, 5, 10]
        .map((m) => m * magnitude)
        .firstWhere((s) => s >= target, orElse: () => 10 * magnitude);
    final intervals = (maxValue / step).ceil();
    return (maxY: intervals * step, interval: step);
  }

  // Compact axis label with the dashboard's ₦ symbol: ₦0, ₦5k, ₦20k …
  String _axisLabel(double value) {
    if (value == 0) return '₦0';
    if (value % 1000 == 0) return '₦${value ~/ 1000}k';
    return '₦${(value / 1000).toStringAsFixed(1)}k';
  }

  // ── TRANSACTIONS TABLE ──
  Widget _buildTransactionsTable(BuildContext context, bool isDark) {
    final provider = context.watch<SalesProvider>();
    final transactions = provider.transactions;

    if (transactions.isEmpty) {        return GrowboxCard(
          child: GrowboxEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No transactions yet',
            subtitle: 'Orders appear here as transactions while they progress.',
          ),
        );
    }

    final isMobile = MediaQuery.sizeOf(context).width < AppDimensions.tablet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transactions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.sm),
        GrowboxCard(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMobile) ...[
                _buildTableHeader(isDark),
                GrowboxTable.headerDivider(isDark),
              ],
              ...transactions.map((txn) => _buildTransactionRow(context, txn, isDark)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(bool isDark) {
    return GrowboxTable.headerRow(
      children: [
        Expanded(flex: 2, child: GrowboxTable.headerCell('Transaction', isDark)),
        Expanded(flex: 2, child: GrowboxTable.headerCell('Order', isDark)),
        Expanded(flex: 3, child: GrowboxTable.headerCell('Product', isDark)),
        Expanded(flex: 1, child: GrowboxTable.headerCell('Qty', isDark)),
        Expanded(flex: 2, child: GrowboxTable.headerCell('Amount', isDark)),
        Container(
          constraints: const BoxConstraints(minWidth: 100),
          child: GrowboxTable.headerCell('Status', isDark),
        ),
        const SizedBox(width: 12),
        SizedBox(width: 80, child: GrowboxTable.headerCell('Date', isDark)),
        // Trailing Actions heading, right-aligned over the reserved cell
        // — the same treatment as the Dashboard and Orders tables.
        const SizedBox(width: AppDimensions.md),
        SizedBox(
          width: _actionsColWidth,
          child: Align(
            alignment: Alignment.centerRight,
            child: GrowboxTable.headerCell('Actions', isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionRow(BuildContext context, TransactionRecord txn, bool isDark) {
    final isMobile = MediaQuery.sizeOf(context).width < AppDimensions.tablet;

    // Mobile: Card layout
    if (isMobile) {
      return GrowboxTable.row(
        isDark: isDark,
        mobile: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [                        Text(
                          txn.productName,
                          style: GrowboxTable.strongStyle(isDark),
                        ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            txn.id,
                            style: GrowboxTable.metaStyle(isDark),
                          ),
                          const SizedBox(width: 6),
                          // Order ID links through to the order details.
                          _orderLink(context, txn.orderId, isDark, fontSize: 12),
                        ],
                      ),
                    ],
                  ),
                ),
                GrowboxStatusPill(status: txn.status),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            Row(
              children: [
                Text(
                  'Qty: ${txn.quantity} ${txn.unit}',
                  style: GrowboxTable.metaStyle(isDark),
                ),
                const SizedBox(width: AppDimensions.md),
                Text(
                  formatCurrency(txn.totalAmount),
                  style: GrowboxTable.strongStyle(isDark),
                ),
                const Spacer(),
                Text(
                  _formatDate(txn.date),
                  style: GrowboxTable.metaStyle(isDark),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Desktop: Table row
    return GrowboxTable.row(
      isDark: isDark,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              txn.id,
              style: GrowboxTable.strongStyle(isDark),
            ),
          ),
          Expanded(
            flex: 2,
            child: _orderLink(context, txn.orderId, isDark),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.productName,
                  style: GrowboxTable.secondaryStyle(isDark),
                ),
                Text(
                  '${formatCurrency(txn.unitPrice)} / ${txn.unit}',
                  style: GrowboxTable.mutedStyle(isDark),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${txn.quantity} ${txn.unit}',
              style: GrowboxTable.secondaryStyle(isDark),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatCurrency(txn.totalAmount),
              style: GrowboxTable.strongStyle(isDark),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 100),
            child: GrowboxStatusPill(status: txn.status),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              _formatDate(txn.date),
              style: GrowboxTable.metaStyle(isDark),
            ),
          ),
          // Reserved Actions cell on EVERY row, right-aligned like the
          // other tables, so columns never shift. Transactions are
          // read-only, so the action is the neutral "View" — it deep-links
          // to the same encoded order route as the Order column.
          const SizedBox(width: AppDimensions.md),
          SizedBox(
            width: _actionsColWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: GrowboxTableAction(
                label: 'View',
                variant: GrowboxTableActionVariant.neutral,
                onTap: () =>
                    context.go('/orders/${Uri.encodeComponent(txn.orderId)}'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // The Order ID as a link to that order's details page. Uses the primary
  // token at w600 — a real affordance (click cursor + tap target) and a
  // big contrast jump from the old grey secondary text.
  Widget _orderLink(
    BuildContext context,
    String orderId,
    bool isDark, {
    double fontSize = 13,
  }) {
    return InkWell(
      // Percent-encode: ids start with '#', which GoRouter would otherwise
      // treat as a URL fragment and drop the path parameter.
      onTap: () => context.go('/orders/${Uri.encodeComponent(orderId)}'),
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          orderId,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkPrimary : AppColors.primary,
            decoration: TextDecoration.underline,
            decorationColor: (isDark ? AppColors.darkPrimary : AppColors.primary)
                .withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _SummaryCard {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    this.icon = Icons.payments_outlined,
  });
}

class _PeriodOption {
  final String label;
  final String value;

  const _PeriodOption({required this.label, required this.value});
}