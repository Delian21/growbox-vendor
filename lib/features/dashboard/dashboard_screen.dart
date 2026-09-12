import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/category_colors.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/growbox_badge.dart';
import '../../shared/widgets/growbox_card.dart';
import '../../shared/widgets/shimmer_loader.dart';

enum _DateRange { all, week, twoWeeks, month }

extension _DateRangeLabel on _DateRange {
  String get label => switch (this) {
    _DateRange.all => 'All',
    _DateRange.week => '7 Days',
    _DateRange.twoWeeks => '14 Days',
    _DateRange.month => '30 Days',
  };
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  _DateRange _selectedRange = _DateRange.all;
  bool _isRefreshing = false;

  // ── MOCK CHART DATA ──
  static const _salesOverviewData = [
    _ChartData(day: 'May 1', amount: 28000, orders: 12),
    _ChartData(day: 'May 2', amount: 30000, orders: 14),
    _ChartData(day: 'May 3', amount: 35000, orders: 16),
    _ChartData(day: 'May 4', amount: 33000, orders: 15),
    _ChartData(day: 'May 5', amount: 32000, orders: 14),
    _ChartData(day: 'May 6', amount: 38000, orders: 17),
    _ChartData(day: 'May 7', amount: 45000, orders: 20),
    _ChartData(day: 'May 8', amount: 42000, orders: 19),
    _ChartData(day: 'May 9', amount: 38000, orders: 17),
    _ChartData(day: 'May 10', amount: 44000, orders: 20),
    _ChartData(day: 'May 11', amount: 52000, orders: 23),
    _ChartData(day: 'May 12', amount: 50000, orders: 22),
    _ChartData(day: 'May 13', amount: 48000, orders: 21),
    _ChartData(day: 'May 14', amount: 54000, orders: 24),
    _ChartData(day: 'May 15', amount: 61000, orders: 27),
    _ChartData(day: 'May 16', amount: 58000, orders: 26),
    _ChartData(day: 'May 17', amount: 55000, orders: 24),
    _ChartData(day: 'May 18', amount: 63000, orders: 28),
    _ChartData(day: 'May 19', amount: 72000, orders: 32),
    _ChartData(day: 'May 20', amount: 70000, orders: 31),
    _ChartData(day: 'May 21', amount: 68000, orders: 30),
    _ChartData(day: 'May 22', amount: 75000, orders: 33),
    _ChartData(day: 'May 23', amount: 85000, orders: 37),
    _ChartData(day: 'May 24', amount: 82000, orders: 36),
    _ChartData(day: 'May 25', amount: 79000, orders: 35),
    _ChartData(day: 'May 26', amount: 86000, orders: 38),
    _ChartData(day: 'May 27', amount: 95000, orders: 42),
    _ChartData(day: 'May 28', amount: 92000, orders: 41),
    _ChartData(day: 'May 29', amount: 88000, orders: 39),
    _ChartData(day: 'May 30', amount: 96000, orders: 43),
    _ChartData(day: 'May 31', amount: 104000, orders: 46),
  ];

  List<_ChartData> get _filteredSalesData {
    if (_selectedRange == _DateRange.all || _selectedRange == _DateRange.month) {
      return _salesOverviewData;
    }
    // Parse the last date from the dataset (e.g. "May 31" -> 31)
    final lastDay = int.tryParse(_salesOverviewData.last.day.split(' ').last) ?? 31;
    final daysBack = switch (_selectedRange) {
      _DateRange.week => 7,
      _DateRange.twoWeeks => 14,
      _ => 30,
    };
    final cutoffDay = lastDay - daysBack;
    return _salesOverviewData.where((d) {
      final day = int.tryParse(d.day.split(' ').last) ?? 0;
      return day > cutoffDay;
    }).toList();
  }

  // Shares its palette with the products filter chips via CategoryColors —
  // one hue per category, consistent app-wide.
  static final _categoryData = [
    for (final e in const {
      'Vegetables': 30,
      'Fruits': 20,
      'Grains & Cereals': 13,
      'Legumes & Pulses': 10,
      'Tuber & Roots': 8,
      'Oils': 8,
      'Fresh Proteins': 6,
      'Others': 5,
    }.entries)
      _CategoryData(
        label: e.key,
        percentage: e.value,
        color: CategoryColors.forCategory(e.key)!,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.primary,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      displacement: 60,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
      child: AnimationLimiter(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 375),
              childAnimationBuilder: (widget) => SlideAnimation(
                verticalOffset: 30.0,
                child: FadeInAnimation(
                  child: widget,
                ),
              ),
              children: [
                // ── Row 1: Welcome ──
                _buildWelcomeHeader(context, isDark),
                const SizedBox(height: AppDimensions.xl),

                // ── Row 2: Stats — 4-card bento grid ──
                _buildStatsGrid(context, isDark),
                const SizedBox(height: AppDimensions.xl),

                // ── Row 3: Sales chart (60%) + Category + Quick Actions (40%) ──
                _buildBentoChartsRow(context, isDark),
                const SizedBox(height: AppDimensions.xl),

                // ── Row 4: Recent Orders — full width ──
                _buildRecentOrdersSection(context, isDark),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _isRefreshing = false);
  }

  // ── WELCOME HEADER ──
  Widget _buildWelcomeHeader(BuildContext context, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, Farm Fresh',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Here's what's happening with your store today",
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const GrowboxBadge(label: 'Online', backgroundColor: AppColors.successLight, textColor: AppColors.success),
      ],
    );
  }

  // ── STATS — 1 primary metric, 3 secondary ──
  Widget _buildStatsGrid(BuildContext context, bool isDark) {
    final primary = _StatCard(
      title: 'Total Revenue',
      value: formatCurrency(2450000),
      change: '+12.5%',
      changeNote: 'from last month',
    );
    const secondary = [
      _StatCard(title: 'Orders', value: '156', change: '+8.2%'),
      _StatCard(title: 'Products', value: '42', change: '+3'),
      _StatCard(title: 'Rating', value: '4.8', change: '+0.2'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Narrow screens: stack the secondary cards full-width instead of
        // squeezing three columns into a phone row.
        final stacked = constraints.maxWidth < 520;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _isRefreshing
              ? Column(
                  key: const ValueKey('skeleton'),
                  children: [
                    const GrowboxCard(padding: EdgeInsets.all(20), child: StatCardSkeleton()),
                    const SizedBox(height: AppDimensions.lg),
                    if (stacked)
                      const Column(
                        children: [
                          GrowboxCard(padding: EdgeInsets.all(14), child: StatCardSkeleton()),
                          SizedBox(height: AppDimensions.lg),
                          GrowboxCard(padding: EdgeInsets.all(14), child: StatCardSkeleton()),
                          SizedBox(height: AppDimensions.lg),
                          GrowboxCard(padding: EdgeInsets.all(14), child: StatCardSkeleton()),
                        ],
                      )
                    else
                      Row(
                        children: [
                          for (var i = 0; i < 3; i++) ...[
                            if (i > 0) const SizedBox(width: AppDimensions.lg),
                            const Expanded(child: GrowboxCard(padding: EdgeInsets.all(14), child: StatCardSkeleton())),
                          ],
                        ],
                      ),
                  ],
                )
              : Column(
                  key: const ValueKey('data'),
                  children: [
                    _buildPrimaryStatCard(context, primary, isDark),
                    const SizedBox(height: AppDimensions.lg),
                    if (stacked)
                      Column(
                        children: [
                          for (var i = 0; i < secondary.length; i++) ...[
                            if (i > 0) const SizedBox(height: AppDimensions.lg),
                            _buildSecondaryStatCard(context, secondary[i], isDark),
                          ],
                        ],
                      )
                    else
                      Row(
                        children: [
                          for (var i = 0; i < secondary.length; i++) ...[
                            if (i > 0) const SizedBox(width: AppDimensions.lg),
                            Expanded(child: _buildSecondaryStatCard(context, secondary[i], isDark)),
                          ],
                        ],
                      ),
                  ],
                ),
        );
      },
    );
  }

  // Primary metric — the one thing the eye should land on.
  // A quiet sparkline sits beside the number, showing the trend's shape
  // instead of a coloured badge.
  Widget _buildPrimaryStatCard(BuildContext context, _StatCard stat, bool isDark) {
    final sparkWindow = _salesOverviewData.length > 7
        ? _salesOverviewData.sublist(_salesOverviewData.length - 7)
        : _salesOverviewData;
    final spots = [
      for (var i = 0; i < sparkWindow.length; i++) FlSpot(i.toDouble(), sparkWindow[i].amount),
    ];
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return GrowboxCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            stat.title,
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
                    stat.value,
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
                        spots: spots,
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
          ),
          if (stat.change != null) ...[
            const SizedBox(height: 10),
            _changeBadge(stat.change!, isDark, note: stat.changeNote),
          ],
        ],
      ),
    );
  }

  // Green delta pill — trend arrow + change, optionally with a qualifier
  // ("from last month").
  Widget _changeBadge(String change, bool isDark, {String? note, bool isSmall = false}) {
    final color = isDark ? AppColors.darkPrimary : AppColors.success;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 6 : 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.successLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, size: isSmall ? 10 : 12, color: color),
          const SizedBox(width: 3),
          Text(
            note == null ? change : '$change $note',
            style: TextStyle(
              fontSize: isSmall ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Secondary metrics — label over number, delta badge on the right,
  // mirroring the reference layout.
  Widget _buildSecondaryStatCard(BuildContext context, _StatCard stat, bool isDark) {
    return GrowboxCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stat.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    stat.value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (stat.change != null) ...[
            const SizedBox(width: 8),
            _changeBadge(stat.change!, isDark, isSmall: true),
          ],
        ],
      ),
    );
  }

  // ── BENTO CHARTS ROW — sales chart left, category + quick actions right ──
  Widget _buildBentoChartsRow(BuildContext context, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 700) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Sales Overview (wider)
              Expanded(
                flex: 6,
                child: _buildSalesOverviewChart(context, isDark),
              ),
              const SizedBox(width: AppDimensions.lg),
              // Right: Category + Quick Actions stacked
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSalesByCategoryChart(context, isDark),
                    const SizedBox(height: AppDimensions.lg),
                    _buildQuickActionsBento(context, isDark),
                  ],
                ),
              ),
            ],
          );
        }
        // Mobile: stack everything
        return Column(
          children: [
            _buildSalesOverviewChart(context, isDark),
            const SizedBox(height: AppDimensions.lg),
            _buildSalesByCategoryChart(context, isDark),
            const SizedBox(height: AppDimensions.lg),
            _buildQuickActionsBento(context, isDark),
          ],
        );
      },
    );
  }

  // ── SALES OVERVIEW LINE CHART (dual-line) ──
  Widget _buildSalesOverviewChart(BuildContext context, bool isDark) {
    final filteredData = _filteredSalesData;
    final maxSales = filteredData.map((d) => d.amount).reduce((a, b) => a > b ? a : b);
    final maxOrders = filteredData.map((d) => d.orders).reduce((a, b) => a > b ? a : b);

    return GrowboxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Text(
                'Sales Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendDot(AppColors.primary, 'Sales', isDark),
                  const SizedBox(width: 8),
                  _buildLegendDot(AppColors.brandOrange, 'Orders', isDark),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<_DateRange>(
                        value: _selectedRange,
                        isDense: true,
                        icon: Icon(Icons.keyboard_arrow_down, size: 16, color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                        dropdownColor: isDark ? AppColors.darkSurfaceVariant : AppColors.surface,
                        items: _DateRange.values.map((range) {
                          return DropdownMenuItem<_DateRange>(
                            value: range,
                            child: Text(range.label),
                          );
                        }).toList(),
                        onChanged: (range) {
                          if (range != null) setState(() => _selectedRange = range);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : AppColors.border,
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: (filteredData.length / 5).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        final interval = (filteredData.length / 5).ceil();
                        if (index >= 0 && index < filteredData.length && index % interval == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              filteredData[index].day,
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        return Text(
                          '₦${(value / 1000).toStringAsFixed(0)}k',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: maxSales * 1.15,
                extraLinesData: const ExtraLinesData(),
                lineBarsData: [
                  // ── Sales line (green, solid, area fill) ──
                  LineChartBarData(
                    spots: filteredData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.amount.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: AppColors.primary,
                          strokeWidth: 1.5,
                          strokeColor: isDark ? AppColors.darkSurface : AppColors.surface,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.25),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  // ── Orders line (orange, dashed, secondary axis) ──
                  LineChartBarData(
                    spots: filteredData.asMap().entries.map((entry) {
                      // Scale orders to sales Y-axis so they share the same chart space
                      final scaledOrders = (entry.value.orders / maxOrders) * maxSales;
                      return FlSpot(entry.key.toDouble(), scaledOrders);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.brandOrange,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dashArray: [6, 4],
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: AppColors.brandOrange,
                          strokeWidth: 1.5,
                          strokeColor: isDark ? AppColors.darkSurface : AppColors.surface,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => isDark ? const Color(0xFF1A1D1A) : Colors.white,
                    tooltipBorderRadius: BorderRadius.circular(8),
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isSales = spot.barIndex == 0;
                        final label = isSales
                            ? 'Sales: ${formatCurrency(spot.y)}'
                            : 'Orders: ${maxOrders > 0 ? ((spot.y / maxSales) * maxOrders).round() : 0}';
                        return LineTooltipItem(
                          label,
                          TextStyle(
                            color: isSales ? AppColors.primary : AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Legend swatch for the category list: a solid rounded square in the
  // category colour, matching the pie slice colour.
  Widget _buildCategoryLegendIcon(_CategoryData cat) {
    return Container(
      width: 20,
      height: 20,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: cat.color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ── SALES BY CATEGORY PIE CHART ──
  Widget _buildSalesByCategoryChart(BuildContext context, bool isDark) {
    return GrowboxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sales by Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: _categoryData.map((cat) {
                  return PieChartSectionData(
                    value: cat.percentage.toDouble(),
                    color: cat.color,
                    radius: 32,
                    title: '${cat.percentage}%',
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1)),
                      ],
                    ),
                    badgeWidget: null,
                    titlePositionPercentageOffset: 0.55,
                    // Hairline in the card's surface colour — keeps adjacent
                    // ramp shades distinguishable without adding new hues.
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkSurface : AppColors.secondarySurface,
                      width: 2,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          ..._categoryData.map((cat) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                _buildCategoryLegendIcon(cat),
                const SizedBox(width: 8),
                Text(
                  cat.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${cat.percentage}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ── RECENT ORDERS ──
  Widget _buildRecentOrdersSection(BuildContext context, bool isDark) {
    final isMobile = MediaQuery.sizeOf(context).width < AppDimensions.tablet;
    final orders = [
      _OrderItem(id: '#ORD-001', customer: 'Chidi Okonkwo', items: 'Fresh Tomatoes (5), Onions (2)', amount: formatCurrency(14900), status: 'pending', time: '2 min ago'),
      _OrderItem(id: '#ORD-002', customer: 'Amina Bello', items: 'Bell Peppers (3)', amount: formatCurrency(9600), status: 'preparing', time: '15 min ago'),
      _OrderItem(id: '#ORD-003', customer: 'Emeka Nwosu', items: 'Organic Lettuce (2)', amount: formatCurrency(3000), status: 'ready', time: '32 min ago'),
      _OrderItem(id: '#ORD-004', customer: 'Fatima Abdullahi', items: 'Sweet Potatoes (10)', amount: formatCurrency(18000), status: 'completed', time: '1 hour ago'),
      _OrderItem(id: '#ORD-005', customer: 'Bola Adeyemi', items: 'Carrots (4), Onions (3)', amount: formatCurrency(10800), status: 'cancelled', time: '2 hours ago'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Orders',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
            ),
            const Spacer(),
            TextButton(onPressed: () => context.go('/orders'), child: const Text('View All')),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),
        GrowboxCard(
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMobile) ...[
                _buildOrdersTableHeader(isDark),
                Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
              ],
              ...orders.map((order) => _buildOrderRow(context, order, isDark)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersTableHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.md),
      child: Row(
        children: [
          Expanded(flex: 2, child: _tableHeader('Order', isDark)),
          Expanded(flex: 3, child: _tableHeader('Items', isDark)),
          Expanded(flex: 2, child: _tableHeader('Amount', isDark)),
          Expanded(flex: 2, child: _tableHeader('Status', isDark)),
          Expanded(flex: 1, child: _tableHeader('Time', isDark)),
        ],
      ),
    );
  }

  Widget _tableHeader(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary, letterSpacing: 0.5),
    );
  }

  Widget _buildOrderRow(BuildContext context, _OrderItem order, bool isDark) {
    final isMobile = MediaQuery.sizeOf(context).width < AppDimensions.tablet;

    // Mobile: Card layout
    if (isMobile) {
      return InkWell(
        onTap: () => context.go('/orders'),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.lg),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border, width: 0.5)),
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
                        Text(order.id, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(order.customer, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  _buildStatusBadge(order.status),
                ],
              ),
              const SizedBox(height: AppDimensions.sm),
              Text(order.items, style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: AppDimensions.sm),
              Row(
                children: [
                  Text(order.amount, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
                  const Spacer(),
                  Text(order.time, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary)),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Desktop: Table row
    return InkWell(
      onTap: () => context.go('/orders'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.md),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border, width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(order.id, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
                  Text(order.customer, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(order.items, style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 2,
              child: Text(order.amount, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
            ),
            Expanded(
              flex: 2,
              child: Align(alignment: Alignment.centerLeft, child: _buildStatusBadge(order.status)),
            ),
            Expanded(
              flex: 1,
              child: Text(order.time, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return switch (status) {
      'pending' => const GrowboxBadge(label: 'Pending', backgroundColor: AppColors.pendingLight, textColor: AppColors.pending, isSmall: true),
      'preparing' => const GrowboxBadge(label: 'Preparing', backgroundColor: AppColors.preparingLight, textColor: AppColors.preparing, isSmall: true),
      'ready' => const GrowboxBadge(label: 'Ready', backgroundColor: AppColors.readyLight, textColor: AppColors.ready, isSmall: true),
      'completed' => const GrowboxBadge(label: 'Completed', backgroundColor: AppColors.completedLight, textColor: AppColors.completed, isSmall: true),
      'cancelled' => const GrowboxBadge(label: 'Cancelled', backgroundColor: AppColors.cancelledLight, textColor: AppColors.cancelled, isSmall: true),
      _ => const SizedBox.shrink(),
    };
  }

  // ── QUICK ACTIONS — compact bento (vertical stack for right column) ──
  Widget _buildQuickActionsBento(BuildContext context, bool isDark) {
    final actions = [
      _QuickAction(icon: Icons.add_shopping_cart_outlined, label: 'Add Product', route: '/products'),
      _QuickAction(icon: Icons.receipt_long_outlined, label: 'View Orders', route: '/orders'),
      _QuickAction(icon: Icons.bar_chart_outlined, label: 'Sales Report', route: '/sales'),
      _QuickAction(icon: Icons.store_outlined, label: 'My Store', route: '/store'),
    ];

    return GrowboxCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ...actions.map((action) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.go(action.route),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Icon(action.icon, size: 18, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(action.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 12, color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                    ],
                  ),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

// ── HELPER CLASSES ──
class _StatCard {
  final String title, value;
  final String? change;
  final String? changeNote;
  const _StatCard({required this.title, required this.value, this.change, this.changeNote});
}

class _OrderItem {
  final String id, customer, items, amount, status, time;
  _OrderItem({required this.id, required this.customer, required this.items, required this.amount, required this.status, required this.time});
}

class _QuickAction {
  final IconData icon;
  final String label, route;
  _QuickAction({required this.icon, required this.label, required this.route});
}

class _ChartData {
  final String day;
  final double amount;
  final int orders;
  const _ChartData({required this.day, required this.amount, this.orders = 0});
}

class _CategoryData {
  final String label;
  final int percentage;
  final Color color;
  const _CategoryData({required this.label, required this.percentage, required this.color});
}