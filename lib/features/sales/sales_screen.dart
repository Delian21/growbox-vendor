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
    final secondary = [
      _SummaryCard(title: 'Vendor Earnings', value: formatCurrency(summary.vendorEarnings)),
      _SummaryCard(title: 'Commission', value: formatCurrency(summary.growboxCommission)),
      _SummaryCard(
        title: 'Completed Orders',
        value: '${summary.completedOrders}/${summary.totalOrders}',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Narrow screens: stack the secondary cards full-width instead of
        // squeezing three columns into a phone row.
        final stacked = constraints.maxWidth < 520;
        return Column(
          children: [
            _buildPrimaryCard(context, primary, isDark),
            const SizedBox(height: AppDimensions.lg),
            if (stacked)
              Column(
                children: [
                  for (var i = 0; i < secondary.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppDimensions.lg),
                    _buildSecondaryCard(context, secondary[i], isDark),
                  ],
                ],
              )
            else
              Row(
                children: [
                  for (var i = 0; i < secondary.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppDimensions.lg),
                    Expanded(child: _buildSecondaryCard(context, secondary[i], isDark)),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }

  // Primary metric — the one thing the eye should land on.
  Widget _buildPrimaryCard(BuildContext context, _SummaryCard card, bool isDark) {
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
          FittedBox(
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
        ],
      ),
    );
  }

  // Secondary metrics — quiet supporting numbers.
  Widget _buildSecondaryCard(BuildContext context, _SummaryCard card, bool isDark) {
    return GrowboxCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              card.value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            card.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
                        width: 28,
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

  const _SummaryCard({
    required this.title,
    required this.value,
  });
}

class _PeriodOption {
  final String label;
  final String value;

  const _PeriodOption({required this.label, required this.value});
}