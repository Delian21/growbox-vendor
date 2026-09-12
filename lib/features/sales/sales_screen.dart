import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/formatters.dart';
import '../../app/providers/sales_provider.dart';
import '../../data/models/sales_data.dart';
import '../../shared/widgets/growbox_card.dart';
import '../../shared/widgets/growbox_badge.dart';
import '../../shared/widgets/growbox_empty_state.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          return FilterChip(
            label: Text(period.label),
            selected: isSelected,
            onSelected: (_) => provider.setPeriod(period.value),
            selectedColor: AppColors.primary,
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            ),
            backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }

  // ── SUMMARY — 1 primary metric, 3 secondary ──
  Widget _buildSummaryCards(BuildContext context, bool isDark) {
    final provider = context.watch<SalesProvider>();
    final summary = provider.summary;

    final primary = _SummaryCard(
      title: 'Total Sales',
      value: formatCurrency(summary.totalSales),
    );
    final sparkSpots = _sparkSpots(provider.transactions, provider.selectedPeriod);
    final sparkDelta = _sparkDelta(sparkSpots);
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900 ? 3 : 2;
        final cardWidth = (constraints.maxWidth - (columns - 1) * 16) / columns;

        return Column(
          children: [
            _buildPrimaryCard(context, primary, isDark, sparkSpots, sparkDelta,
                provider.selectedPeriod),
            const SizedBox(height: AppDimensions.lg),
            Wrap(
              spacing: AppDimensions.lg,
              runSpacing: AppDimensions.lg,
              children: [
                ...cards.map((card) => SizedBox(
                  width: cardWidth,
                  child: _buildSummaryCard(context, card, isDark),
                )),
                // At 2 columns stretch it across the full row so there's no
                // orphaned empty cell; at 3 columns the row already fills
                // with single-width cards.
                SizedBox(
                  width: columns == 2 ? cardWidth * 2 + AppDimensions.lg : cardWidth,
                  height: 124.5,
                  child: _buildOrderStatusDoughnut(context, isDark, summary),
                ),
              ],
            ),
          ],
        );
      },
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
  }

  // Green/red delta pill — trend arrow + change vs the previous bucket,
  // matching the dashboard hero's badge style.
  Widget _changeBadge(double deltaPct, bool isDark, {required String period}) {
    final positive = deltaPct >= 0;
    final color = positive
        ? (isDark ? AppColors.darkPrimary : AppColors.success)
        : AppColors.error;
    final note = period == 'today' ? 'vs previous hour' : 'vs previous day';
    final text =
        '${positive ? '+' : ''}${deltaPct.toStringAsFixed(1)}% $note';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: positive
            ? (isDark
                ? AppColors.success.withValues(alpha: 0.15)
                : AppColors.successLight)
            : (isDark
                ? AppColors.error.withValues(alpha: 0.15)
                : AppColors.errorLight),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? Icons.trending_up : Icons.trending_down,
            size: 12,
            color: color,
          ),
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

  // Change between the last two sparkline buckets, as a fraction (e.g.
  // 0.125 for +12.5%). Null when it can't be computed.
  double? _sparkDelta(List<FlSpot> spots) {
    if (spots.length < 2) return null;
    final prev = spots[spots.length - 2].y;
    final last = spots.last.y;
    if (prev <= 0) return null;
    return (last - prev) / prev * 100;
  }

  // Period-aware revenue series for the sparkline: transactions bucketed by
  // hour for 'today', by day otherwise. Refunds excluded.
  List<FlSpot> _sparkSpots(List<TransactionRecord> txns, String period) {
    final grouped = <String, double>{};
    for (final t in txns) {
      if (t.status == 'refunded') continue;
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
                maxY: chartData.isNotEmpty
                    ? chartData.map((e) => e.amount).reduce((a, b) => a > b ? a : b) * 1.2
                    : 100000,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        formatCurrency(rod.toY),
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
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        return Text(
                          '${(value / 1000).toStringAsFixed(0)}k',
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
                        width: 10,
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

  // ── TRANSACTIONS TABLE ──
  Widget _buildTransactionsTable(BuildContext context, bool isDark) {
    final provider = context.watch<SalesProvider>();
    final transactions = provider.transactions;

    if (transactions.isEmpty) {
      return GrowboxCard(
        child: GrowboxEmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No transactions yet',
          subtitle: 'Completed orders will appear here as transactions.',
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
                Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
              ],
              ...transactions.map((txn) => _buildTransactionRow(context, txn, isDark)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical: AppDimensions.md,
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: _tableCol('Transaction', isDark)),
          Expanded(flex: 2, child: _tableCol('Order', isDark)),
          Expanded(flex: 3, child: _tableCol('Product', isDark)),
          Expanded(flex: 1, child: _tableCol('Qty', isDark)),
          Expanded(flex: 2, child: _tableCol('Amount', isDark)),
          Container(
            constraints: const BoxConstraints(minWidth: 100),
            child: _tableCol('Status', isDark),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 80, child: _tableCol('Date', isDark)),
        ],
      ),
    );
  }

  Widget _tableCol(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTransactionRow(BuildContext context, TransactionRecord txn, bool isDark) {
    final isMobile = MediaQuery.sizeOf(context).width < AppDimensions.tablet;

    // Mobile: Card layout
    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.lg),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              width: 0.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        txn.productName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        txn.id,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _txnStatusBadge(txn.status),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            Row(
              children: [
                Text(
                  'Qty: ${txn.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Text(
                  formatCurrency(txn.totalAmount),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(txn.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Desktop: Table row
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical: AppDimensions.md,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              txn.id,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              txn.orderId,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.productName,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${formatCurrency(txn.unitPrice)} / unit',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${txn.quantity}',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatCurrency(txn.totalAmount),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 100),
            child: _txnStatusBadge(txn.status),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              _formatDate(txn.date),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _txnStatusBadge(String status) {
    return switch (status) {
      'completed' => const GrowboxBadge(
          label: 'Completed',
          backgroundColor: AppColors.completedLight,
          textColor: AppColors.completed,
          isSmall: true,
        ),
      'pending' => const GrowboxBadge(
          label: 'Pending',
          backgroundColor: AppColors.pendingLight,
          textColor: AppColors.pending,
          isSmall: true,
        ),
      'refunded' => const GrowboxBadge(
          label: 'Refunded',
          backgroundColor: AppColors.cancelledLight,
          textColor: AppColors.cancelled,
          isSmall: true,
        ),
      _ => const SizedBox.shrink(),
    };
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