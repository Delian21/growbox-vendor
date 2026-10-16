import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/category_colors.dart';
import '../../core/utils/formatters.dart';
import '../../app/providers/orders_provider.dart';
import '../../app/providers/sales_provider.dart';
import '../../app/providers/store_provider.dart';
import '../../data/models/order.dart';
import '../../shared/utils/snackbar_helper.dart';
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

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  _DateRange _selectedRange = _DateRange.all;
  bool _isRefreshing = false;

  // Index of the highlighted Sales-by-Category ring segment (null = idle).
  int? _selectedCategory;

  // Selection state as of the START of the current focus animation. The
  // painter cross-fades every segment's dim amount between this value and
  // _selectedCategory, so greying in/out animates instead of snapping.
  int? _prevCategory;

  // Drives the smooth color cross-fade when a segment is focused/unfocused.
  late final AnimationController _ringFocus = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  // Recent-order rows held as STATE: the inline Accept action flips
  // pending → accepted on the very instance the widget tree renders, so
  // the list must outlive a rebuild — re-creating these literals inside
  // build() would silently discard the change on the next frame.
  final List<_OrderItem> _recentOrders = [
    _OrderItem(id: '#ORD-001', customer: 'Chidi Okonkwo', items: 'Fresh Tomatoes (5), Onions (2)', amount: formatCurrency(14900), status: 'pending', time: '2 min ago'),
    _OrderItem(id: '#ORD-002', customer: 'Amina Bello', items: 'Bell Peppers (3)', amount: formatCurrency(9600), status: 'preparing', time: '15 min ago'),
    _OrderItem(id: '#ORD-003', customer: 'Emeka Nwosu', items: 'Organic Lettuce (2)', amount: formatCurrency(3000), status: 'ready', time: '32 min ago'),
    _OrderItem(id: '#ORD-004', customer: 'Fatima Abdullahi', items: 'Sweet Potatoes (10)', amount: formatCurrency(18000), status: 'completed', time: '1 hour ago'),
    _OrderItem(id: '#ORD-005', customer: 'Bola Adeyemi', items: 'Carrots (4), Onions (3)', amount: formatCurrency(10800), status: 'cancelled', time: '2 hours ago'),
  ];

  @override
  void dispose() {
    _ringFocus.dispose();
    super.dispose();
  }

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
  //
  // Slices below this share (%) merge into the single "Others" bucket —
  // several hairline slivers read worse than one small slice. With the
  // current data only "Others" (5%) is under the cutoff, so the ring is
  // unchanged; raise the constant to fold more categories in.
  static const _mergedShareCutoff = 6;

  // Card inner width from which the legend moves beside the ring
  // (ring 220 + gap 16 + ~165 for the longest label row).
  static const _legendBesideMinWidth = 400.0;

  static final _categoryData = _aggregateSmallCategories([
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
  ]);

  // Folds every non-"Others" category under the cutoff into one slice
  // (data unchanged — same percentages, just re-bucketed for display).
  static List<_CategoryData> _aggregateSmallCategories(
      List<_CategoryData> cats) {
    final small = cats
        .where((c) => c.label != 'Others' && c.percentage < _mergedShareCutoff)
        .toList();
    if (small.isEmpty) return cats;
    final merged = small.fold<int>(0, (sum, c) => sum + c.percentage);
    return [
      for (final c in cats)
        if (c.label != 'Others' && c.percentage >= _mergedShareCutoff) c,
      _CategoryData(
        label: 'Others',
        percentage: merged,
        color: CategoryColors.forCategory('Others')!,
      ),
    ];
  }

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
                // ── Row 1: Subtitle (welcome title removed) ──
                _buildSubtitleHeader(context, isDark),
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

  // ── SUBTITLE HEADER — status line above the stats (welcome title removed) ──
  Widget _buildSubtitleHeader(BuildContext context, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            "Here's what's happening with your store today",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ),
        // Store status — real StoreProvider state and a working toggle,
        // with an explicit "Store:" prefix so it can't be read as a
        // connection or session indicator.
        InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          onTap: () => context.read<StoreProvider>().toggleStoreStatus(),
          child: Builder(builder: (context) {
            final isOpen = context.watch<StoreProvider>().isOpen;
            return GrowboxBadge(
              label: isOpen ? 'Store: Online' : 'Store: Offline',
              backgroundColor: isOpen
                  ? AppColors.successLight
                  : AppColors.errorLight,
              textColor: isOpen ? AppColors.success : AppColors.error,
            );
          }),
        ),
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
    // Every trend pill names its period — "+3" over what?
    const secondary = [
      _StatCard(title: 'Orders', value: '156', change: '+8.2%', changeNote: 'this month'),
      _StatCard(title: 'Products', value: '42', change: '+3', changeNote: 'this month'),
      _StatCard(title: 'Rating', value: '4.8', change: '+0.2', changeNote: 'this month'),
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
    // The rating has a natural ceiling (5), so it renders as an arc gauge
    // instead of the plain value row.
    if (stat.title == 'Rating') return _buildRatingStatCard(context, stat, isDark);
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
            _changeBadge(stat.change!, isDark, note: stat.changeNote, isSmall: true),
          ],
        ],
      ),
    );
  }

  // ── RATING STAT — arc gauge, because a score has a real ceiling ──
  Widget _buildRatingStatCard(BuildContext context, _StatCard stat, bool isDark) {
    final value = double.tryParse(stat.value) ?? 0;
    return GrowboxCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                if (stat.change != null) _changeBadge(stat.change!, isDark, note: stat.changeNote, isSmall: true),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _RatingGauge(value: value, maxValue: 5, isDark: isDark),
        ],
      ),
    );
  }

  // ── BENTO CHARTS ROW — sales chart left, category + quick actions right ──
  Widget _buildBentoChartsRow(BuildContext context, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 700) {
          // Right column (flex 4) card inner width decides where the
          // category legend goes: beside the ring when there's room for
          // ring 220 + gap 16 + ~165 for the longest label row.
          final rightInner =
              (constraints.maxWidth - AppDimensions.lg) * 0.4 -
                  AppDimensions.cardPadding * 2;
          final legendBeside = rightInner >= _legendBesideMinWidth;
          // IntrinsicHeight + stretch: the row lives in a vertical scroll
          // view (unbounded height), so stretch alone is invalid —
          // IntrinsicHeight first measures the taller column and hands
          // BOTH columns that exact height. The shorter side's card then
          // grows to meet it instead of leaving a dead band on the page;
          // any slack lands INSIDE a card as breathing room.
          return IntrinsicHeight(
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: Sales Overview + Quick Actions stacked — together
              // they match the Category card's height, so the columns
              // end at the same line and nothing floats in empty space.
              Expanded(
                flex: 6,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSalesOverviewChart(context, isDark),
                    const SizedBox(height: AppDimensions.lg),
                    _buildQuickActionsBento(context, isDark),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.lg),
              // Right: Category alone — the row height matches it to the
              // left stack, and the card stretches to fill.
              Expanded(
                flex: 4,
                child: _buildSalesByCategoryChart(context, isDark,
                    legendBeside: legendBeside),
              ),
            ],
            ),
          );
        }
        // Mobile: stack everything
        return Column(
          children: [
            _buildSalesOverviewChart(context, isDark, isNarrow: true),
            const SizedBox(height: AppDimensions.lg),
            _buildSalesByCategoryChart(context, isDark,
                legendBeside: constraints.maxWidth -
                        AppDimensions.cardPadding * 2 >=
                    _legendBesideMinWidth),
            const SizedBox(height: AppDimensions.lg),
            _buildQuickActionsBento(context, isDark),
          ],
        );
      },
    );
  }

  // ── SALES OVERVIEW LINE CHART (dual-line) ──
  Widget _buildSalesOverviewChart(BuildContext context, bool isDark, {bool isNarrow = false}) {
    final filteredData = _filteredSalesData;
    final maxSales = filteredData.map((d) => d.amount).reduce((a, b) => a > b ? a : b);
    final maxOrders = filteredData.map((d) => d.orders).reduce((a, b) => a > b ? a : b);

    // "Nice" axis top: a 10k-rounded step ≈ top/3, then round the top up to
    // it — the sales axis lands on clean ticks (₦40k/₦80k/₦120k for this
    // data) instead of fl_chart's uneven auto intervals.
    final axisTop = maxSales * 1.15;
    final axisSteps = (axisTop / 3 / 10000).ceil();
    final axisStep = (axisSteps < 1 ? 1 : axisSteps) * 10000.0;
    final axisMaxY = (axisTop / axisStep).ceil() * axisStep;

    // Orders get their OWN axis (counts): a 10-based step ≈ top/3 so the
    // right-hand labels are clean numbers (20/40/60 for this data) sitting
    // on the same gridlines as the ₦ ticks. Reading counts off the sales
    // axis was misleading — ₦ and items are different units.
    var axisOrdersStep = ((maxOrders * 1.15 / 3 / 10).ceil()) * 10;
    if (axisOrdersStep < 10) axisOrdersStep = 10;
    final axisOrdersMax = ((maxOrders * 1.15 / axisOrdersStep).ceil()) *
        axisOrdersStep;

    return GrowboxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title on its own line; legend + range dropdown get a full row
          // below, so the three items stop competing for one line.
          Text(
            'Sales Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLegendDot(AppColors.primary, 'Sales', isDark),
              const SizedBox(width: 12),
              _buildLegendDot(AppColors.brandOrange, 'Orders', isDark),
              const Spacer(),
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
                      // Narrow screens: 3 date ticks instead of 5 so
                      // labels have room and can't collide.
                      interval: (filteredData.length / (isNarrow ? 3 : 5)).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        final interval = (filteredData.length / (isNarrow ? 3 : 5)).ceil();
                        if (index >= 0 && index < filteredData.length && index % interval == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              filteredData[index].day,
                              style: TextStyle(
                                fontSize: 10,
                                // Secondary, not tertiary: tertiary fails
                                // WCAG AA (≈3.2:1) on the light card.
                                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
                      interval: axisStep,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        return Text(
                          '₦${(value / 1000).toStringAsFixed(0)}k',
                          style: TextStyle(
                            fontSize: 10,
                            // AA-compliant contrast (see dates above).
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  // Orders count axis (right) — the dashed line's own
                  // scale, colour-tied to the line it belongs to. Values
                  // are converted from chart space (₦ gridlines) to counts
                  // so labels sit ON the same gridlines as the left axis:
                  // 40k→20, 80k→40, 120k→60 for this data.
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: axisStep,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        final count =
                            (value / axisMaxY * axisOrdersMax).round();
                        return Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            // Neutral secondary instead of brandOrange: the
                            // orange (≈2.9:1 on white) fails AA at 10px;
                            // the dashed orange line still ties label→line.
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: axisMaxY,
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
                    // No idle dots — the touched-spot indicator below
                    // draws a dot per point on hover/tap instead.
                    dotData: FlDotData(show: false),
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
                      // Plot counts on the ORDERS scale (axisOrdersMax at the
                      // plot top), so the right-hand labels read true values.
                      final scaledOrders =
                          (entry.value.orders / axisOrdersMax) * axisMaxY;
                      return FlSpot(entry.key.toDouble(), scaledOrders);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.brandOrange,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dashArray: [6, 4],
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                lineTouchData: LineTouchData(
                  // Idle: no dots on the 31 points. When the chart is
                  // touched/hovered, fl_chart asks for these indicators per
                  // touched spot — a single ringed dot on each point under
                  // the finger/cursor (no vertical stalk).
                  getTouchedSpotIndicator: (barData, indexes) {
                    return indexes.map((_) {
                      return TouchedSpotIndicatorData(
                        // FlLine has no `show` flag in fl_chart 1.x —
                        // a transparent stroke hides the vertical stalk.
                        const FlLine(color: Colors.transparent),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: barData.color ?? AppColors.primary,
                              strokeWidth: 1.5,
                              strokeColor:
                                  isDark ? AppColors.darkSurface : AppColors.surface,
                            );
                          },
                        ),
                      );
                    }).toList();
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => isDark ? const Color(0xFF1A1D1A) : Colors.white,
                    tooltipBorderRadius: BorderRadius.circular(8),
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isSales = spot.barIndex == 0;
                        final label = isSales
                            ? 'Sales: ${formatCurrency(spot.y)}'
                            // Undo the plot scaling: y → count on the Orders axis.
                            : 'Orders: ${maxOrders > 0 ? ((spot.y / axisMaxY) * axisOrdersMax).round() : 0}';
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

  // ── CATEGORY RING INTERACTION ──
  // Single funnel for every selection change (ring tap, ring hover, legend
  // tap, hover exit): records the outgoing state for the cross-fade and
  // restarts the focus animation from 0.
  void _setCategory(int? next) {
    if (next == _selectedCategory) return; // no-op hover moves stay cheap
    setState(() {
      _prevCategory = _selectedCategory;
      _selectedCategory = next;
    });
    _ringFocus.forward(from: 0);
  }

  void _toggleCategoryAt(Offset pos, Size size) {
    final hit = _categoryHitTest(pos, size);
    _setCategory(hit == _selectedCategory ? null : hit);
  }

  void _hoverCategoryAt(Offset pos, Size size) {
    _setCategory(_categoryHitTest(pos, size));
  }

  void _clearCategory() {
    _setCategory(null);
  }

  // Mirrors _RingDonutPainter's geometry so taps land on the right slice.
  int? _categoryHitTest(Offset pos, Size size) {
    final center = size.center(Offset.zero);
    final midRadius = size.shortestSide / 2 - 2 - _RingDonutPainter.strokeWidth / 2;
    final delta = pos - center;
    final distance = delta.distance;
    if (distance < midRadius - _RingDonutPainter.strokeWidth / 2 - 8 ||
        distance > midRadius + _RingDonutPainter.strokeWidth / 2 + 8) {
      return null; // inside the hole or outside the ring
    }
    // 0° at 12 o'clock, growing clockwise — same frame as paint().
    final degrees = (math.atan2(delta.dy, delta.dx) * 180 / math.pi + 90) % 360;
    final scale = _RingDonutPainter.sweepScale(_categoryData.length);
    var cursor = 0.0;
    for (var i = 0; i < _categoryData.length; i++) {
      final sweep = _categoryData[i].percentage * 3.6 * scale;
      if (degrees >= cursor && degrees < cursor + sweep) return i;
      cursor += sweep + _RingDonutPainter.gapDegrees;
    }
    return null; // tapped a gap
  }

  // Info chip shown top-left while a segment is selected — mirrors the
  // reference: category name, then its value and percent secondary.
  Widget _buildCategoryChip(_CategoryData cat, double totalSales, bool isDark) {
    final amount = (totalSales * cat.percentage) / 100.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            cat.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${formatCurrency(amount)} (${cat.percentage}%)',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── SALES BY CATEGORY — RING DONUT (UI-Pro style) ──
  // Idle: a clean rounded-cap ring with no labels. Hover (desktop) or
  // tap (touch) a segment: the others dim and a value chip appears
  // top-left; tap the gap or the same segment again to return to idle.
  Widget _buildSalesByCategoryChart(BuildContext context, bool isDark,
      {required bool legendBeside}) {
    final summary = context.watch<SalesProvider>().summary;
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
          // [legendBeside] is decided by the bento row's width math: a wide
          // card puts the legend BESIDE the ring (saves ~250px of height);
          // a narrow one stacks it below, as before. Decided upstream because
          // a LayoutBuilder here would break the row's IntrinsicHeight
          // (intrinsics can't be computed through layout callbacks).
          Builder(
            builder: (context) {
              final beside = legendBeside;
              final ring = SizedBox(
                height: 220,
                // Full width when stacked: without it the Stack shrink-wraps
                // to the center KPI and the ring hugs the card edge.
                width: beside ? 220 : double.infinity,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final chartSize = constraints.biggest;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            onHover: (e) => _hoverCategoryAt(e.localPosition, chartSize),
                            onExit: (_) => _clearCategory(),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              // onTapUp (not onTapDown): the gesture must WIN the
                              // arena against the page's scroll view before it
                              // counts, so a flick that starts a scroll no longer
                              // selects a segment, and a clean touch always does.
                              onTapUp: (d) =>
                                  _toggleCategoryAt(d.localPosition, chartSize),
                              child: AnimatedBuilder(
                                animation: _ringFocus,
                                builder: (context, _) => CustomPaint(
                                  key: const Key('sales-category-ring'),
                                  painter: _RingDonutPainter(
                                    categories: _categoryData,
                                    selected: _selectedCategory,
                                    previous: _prevCategory,
                                    focusT: _ringFocus.value,
                                    isDark: isDark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Center KPI stays constant (like the reference);
                        // IgnorePointer keeps ring taps/hovers reaching the chart.
                        IgnorePointer(
                          child: SizedBox(
                            width: 100,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    formatCurrency(summary.totalSales),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Total Sales',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
              // Legend rows are tappable too — on phones a precise arc tap is
              // fiddly, and the row gives the same select/deselect + chip flow.
              final legend = _categoryData
                  .map((cat) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                            onTap: () {
                              final hit = _categoryData.indexOf(cat);
                              _setCategory(hit == _selectedCategory ? null : hit);
                            },
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
                          ),
                        ),
                      ))
                  .toList();
              final body = beside
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ring,
                        const SizedBox(width: AppDimensions.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: legend,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ring,
                        const SizedBox(height: AppDimensions.md),
                        ...legend,
                      ],
                    );
              // Info chip floats above the ring's top-left in BOTH layouts;
              // outside the ring box so it can't clip against it. IgnorePointer
              // keeps its Texts out of hit testing (RenderParagraph.hitTestSelf
              // is true since Flutter 3.35 — otherwise the chip would steal the
              // ring's hover over the "Others" pill and flicker).
              return Stack(
                children: [
                  body,
                  if (_selectedCategory != null)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: IgnorePointer(
                        child: _buildCategoryChip(
                          _categoryData[_selectedCategory!],
                          summary.totalSales,
                          isDark,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ── RECENT ORDERS ──
  Widget _buildRecentOrdersSection(BuildContext context, bool isDark) {
    final isMobile = MediaQuery.sizeOf(context).width < AppDimensions.tablet;

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
              ..._recentOrders.map((order) => _buildOrderRow(context, order, isDark)),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusBadge(order.status),
                      if (order.status == 'pending') ...[
                        const SizedBox(width: 8),
                        _acceptOrderButton(order),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.sm),
              Text(order.items, style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: AppDimensions.sm),
              Row(
                children: [
                  Text(order.amount, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
                  const Spacer(),
                  Text(order.time, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
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
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusBadge(order.status),
                    if (order.status == 'pending') ...[
                      const SizedBox(width: 8),
                      _acceptOrderButton(order),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(order.time, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  // Inline accept for pending rows — same terminal state as the Orders
  // screen's accept flow (status → Accepted), without leaving the dashboard.
  Widget _acceptOrderButton(_OrderItem order) {
    return TextButton(
      onPressed: () => setState(() => order.status = 'accepted'),
      style: TextButton.styleFrom(
        backgroundColor: AppColors.successLight,
        foregroundColor: AppColors.success,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        minimumSize: Size.zero,
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      child: const Text('Accept'),
    );
  }

  Widget _buildStatusBadge(String status) {
    return switch (status) {
      'pending' => const GrowboxBadge(label: 'Pending', backgroundColor: AppColors.pendingLight, textColor: AppColors.pending, isSmall: true),
      'preparing' => const GrowboxBadge(label: 'Preparing', backgroundColor: AppColors.preparingLight, textColor: AppColors.preparing, isSmall: true),
      // Same tokens as the Orders screen's Accepted badge.
      'accepted' => const GrowboxBadge(label: 'Accepted', backgroundColor: AppColors.acceptedLight, textColor: AppColors.accepted, isSmall: true),
      'ready' => const GrowboxBadge(label: 'Ready', backgroundColor: AppColors.readyLight, textColor: AppColors.ready, isSmall: true),
      'completed' => const GrowboxBadge(label: 'Completed', backgroundColor: AppColors.completedLight, textColor: AppColors.completed, isSmall: true),
      'cancelled' => const GrowboxBadge(label: 'Cancelled', backgroundColor: AppColors.cancelledLight, textColor: AppColors.cancelled, isSmall: true),
      _ => const SizedBox.shrink(),
    };
  }

  // Quick action: flip the oldest pending order to Ready and confirm —
  // a real task from the Orders provider, not a link to the Orders screen.
  Future<void> _markNextOrderReady(BuildContext context) async {
    final provider = context.read<OrdersProvider>();
    final pending =
        provider.orders.where((o) => o.status == OrderStatus.pending).toList();
    if (pending.isEmpty) {
      SnackbarHelper.showError(context, 'No pending orders to mark ready');
      return;
    }
    final order = pending.first;
    final ok = await provider.updateOrderStatus(order.id, OrderStatus.ready);
    if (!context.mounted) return;
    if (ok) {
      SnackbarHelper.showSuccess(context, 'Order ${order.id} is ready');
    } else {
      SnackbarHelper.showError(context, 'Could not update ${order.id}');
    }
  }

  // ── QUICK ACTIONS — compact bento (vertical stack for right column) ──
  Widget _buildQuickActionsBento(BuildContext context, bool isDark) {
    final actions = [
      // Kept: the one task the sidebar doesn't lead with.
      _QuickAction(icon: Icons.add_shopping_cart_outlined, label: 'Add Product', route: '/products'),
      // Replacements for the sidebar clones: two actions + a pre-filtered
      // view — none of them are plain navigation any more.
      _QuickAction(icon: Icons.check_circle_outline, label: 'Mark order ready', run: () => _markNextOrderReady(context)),
      // Stock lives on the product cards — the screen that shows it.
      _QuickAction(icon: Icons.inventory_2_outlined, label: 'Update stock', route: '/products'),
      _QuickAction(
        icon: Icons.pending_actions_outlined,
        label: 'Review pending orders',
        run: () {
          context.read<OrdersProvider>().setFilter(OrderStatus.pending);
          context.go('/orders');
        },
      ),
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
                // Actions run in place; navigation tiles still deep-link.
                onTap: action.run ?? () => context.go(action.route!),
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

/// Semicircular arc gauge: value swept left→right across its max, with the
/// number sitting in the bowl. Only for metrics that have a real ceiling.
class _RatingGauge extends StatelessWidget {
  const _RatingGauge({
    required this.value,
    required this.maxValue,
    required this.isDark,
  });

  final double value;
  final double maxValue;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final progress = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    return SizedBox(
      width: 72,
      height: 36,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ArcGaugePainter(
                progress: progress,
                trackColor: isDark ? AppColors.darkBorder : AppColors.borderLight,
                valueColor: AppColors.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text.rich(
              TextSpan(
                text: value % 1 == 0
                    ? value.toStringAsFixed(0)
                    : value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  height: 1.1,
                ),
                children: [
                  TextSpan(
                    text: '/${maxValue.round()}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  const _ArcGaugePainter({
    required this.progress,
    required this.trackColor,
    required this.valueColor,
  });

  final double progress;
  final Color trackColor;
  final Color valueColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height - stroke / 2),
      radius: size.width / 2 - stroke / 2,
    );
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    // Upper semicircle: start angle π (left), sweeping clockwise over the top.
    canvas.drawArc(rect, math.pi, math.pi, false, base..color = trackColor);
    canvas.drawArc(rect, math.pi, math.pi * progress, false, base..color = valueColor);
  }

  @override
  bool shouldRepaint(_ArcGaugePainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.valueColor != valueColor;
}

class _OrderItem {
  final String id, customer, items, amount, time;

  // Mutable: the inline Accept action promotes pending → accepted in place.
  String status;
  _OrderItem({required this.id, required this.customer, required this.items, required this.amount, required this.status, required this.time});
}

class _QuickAction {
  final IconData icon;
  final String label;

  // Either a destination (route) or an in-place action (run).
  final String? route;
  final VoidCallback? run;
  _QuickAction({required this.icon, required this.label, this.route, this.run});
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

// ── RING DONUT PAINTER — rounded-cap arcs over a faint track ──
// fl_chart's pie draws filled wedges with sharp corners, so the UI-Pro
// look (pill-shaped segment ends, no labels) is painted directly.
class _RingDonutPainter extends CustomPainter {
  /// Ring thickness in px; also drives the hit-test band in the screen.
  static const double strokeWidth = 16;

  /// Gap between segments in degrees — wide enough that the round caps
  /// (which extend strokeWidth/2 past each arc end) don't touch.
  static const double gapDegrees = 14;

  final List<_CategoryData> categories;
  final int? selected;

  /// Selection state at the START of the focus animation and its progress
  /// (0→1). Each segment lerps its dim amount between the two states so
  /// the greying in/out is a smooth cross-fade, not a snap.
  final int? previous;
  final double focusT;

  final bool isDark;

  const _RingDonutPainter({
    required this.categories,
    required this.selected,
    required this.previous,
    required this.focusT,
    required this.isDark,
  });

  /// Percent → degrees after subtracting the fixed gaps.
  static double sweepScale(int count) => (360 - gapDegrees * count) / 360;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final midRadius = size.shortestSide / 2 - 2 - strokeWidth / 2;
    final arcRect = Rect.fromCircle(center: center, radius: midRadius);

    // Faint full-circle track behind the segments (UI-Pro reference).
    canvas.drawCircle(
      center,
      midRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.borderLight,
    );

    final scale = sweepScale(categories.length);
    var startDegrees = -90.0; // 12 o'clock
    for (var i = 0; i < categories.length; i++) {
      final sweep = categories[i].percentage * 3.6 * scale;
      // Dim factor per state: a segment is greyed when something ELSE is
      // focused. Cross-fade old → new with the animation progress.
      double dim(int? focus) => (focus != null && focus != i) ? 1.0 : 0.0;
      final d = (dim(previous) + (dim(selected) - dim(previous)) * focusT)
          .clamp(0.0, 1.0);
      canvas.drawArc(
        arcRect,
        startDegrees * math.pi / 180,
        sweep * math.pi / 180,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidth
          ..color = Color.lerp(
            categories[i].color,
            categories[i].color.withValues(alpha: 0.26),
            d,
          )!,
      );
      startDegrees += sweep + gapDegrees;
    }
  }

  @override
  bool shouldRepaint(_RingDonutPainter old) =>
      old.selected != selected ||
      old.previous != previous ||
      old.focusT != focusT ||
      old.isDark != isDark ||
      old.categories != categories;
}