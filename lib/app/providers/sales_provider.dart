import 'package:flutter/material.dart';

import '../../data/models/order.dart';
import '../../data/models/sales_data.dart';
import '../../features/products/product_catalog.dart';
import 'orders_provider.dart';

/// Sales data derived from [OrdersProvider] — the single source of truth.
///
/// Every number on the Sales page (cards, chart, transactions) comes from
/// the same derivation over the live orders:
///  * one [TransactionRecord] per order item; its status mirrors the ORDER
///    (only `completed` orders produce completed records — a cancelled
///    order can never contribute revenue),
///  * revenue = sum of completed records only,
///  * the weekly chart buckets those same completed records by day.
class SalesProvider extends ChangeNotifier {
  SalesProvider(this._orders) {
    _orders.addListener(_onOrdersChanged);
  }

  final OrdersProvider _orders;

  /// Growbox's cut per sale — kept from the original mock rates (10%).
  static const double commissionRate = 0.10;

  String _selectedPeriod = 'all';

  String get selectedPeriod => _selectedPeriod;
  bool get isLoading => false;

  void _onOrdersChanged() => notifyListeners();

  @override
  void dispose() {
    _orders.removeListener(_onOrdersChanged);
    super.dispose();
  }

  // ── TRANSACTIONS ──

  /// Every order item of every order (unfiltered by period).
  List<TransactionRecord> get _allTransactions {
    final result = <TransactionRecord>[];
    for (final order in _orders.allOrders) {
      final status = switch (order.status) {
        OrderStatus.completed => 'completed',
        OrderStatus.cancelled => 'cancelled',
        _ => 'pending',
      };
      for (var i = 0; i < order.items.length; i++) {
        final item = order.items[i];
        final commission = item.total * commissionRate;
        result.add(TransactionRecord(
          id: 'TXN-${order.id.replaceFirst('#', '')}-${i + 1}',
          orderId: order.id,
          productName: item.productName,
          quantity: item.quantity,
          unit: unitFor(item.productName),
          unitPrice: item.price,
          totalAmount: item.total,
          commission: commission,
          vendorEarning: item.total - commission,
          date: order.createdAt,
          status: status,
        ));
      }
    }
    return result;
  }

  /// The product catalog is the master data for units and categories;
  /// orders only carry a product name, so resolve it by name — falling
  /// back to the last word for renamed products ('Organic Lettuce' →
  /// 'Fresh Lettuce'). Null when the product is unknown.
  static ProductItem? _catalogMatch(String productName) {
    final products = ProductCatalog.instance.items;
    for (final p in products) {
      if (p.name == productName) return p;
    }
    final lastWord = productName.split(' ').last.toLowerCase();
    for (final p in products) {
      if (p.name.toLowerCase().contains(lastWord)) return p;
    }
    return null;
  }

  static String unitFor(String productName) =>
      _catalogMatch(productName)?.unit ?? 'item';

  /// The catalog category for a product name; 'Others' when unknown.
  static String categoryFor(String productName) =>
      _catalogMatch(productName)?.category ?? 'Others';

  /// Transactions of the selected period, newest first.
  List<TransactionRecord> get transactions {
    final now = DateTime.now();
    final (start, end) = _periodWindow(_selectedPeriod, now);
    final list = _allTransactions
        .where((t) => !t.date.isBefore(start) && t.date.isBefore(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<TransactionRecord> getTransactionsByStatus(String status) {
    return transactions.where((t) => t.status == status).toList();
  }

  // ── SUMMARY ──

  /// Revenue/earnings for the selected period — completed records only.
  SalesSummary get summary => _summaryFor(_selectedPeriod);

  /// All-time totals, INDEPENDENT of the Sales page's period chip — for
  /// consumers that must not change when the Sales page filter does (the
  /// dashboard's stats and category ring).
  SalesSummary get allTimeSummary => _summaryFor('all');

  SalesSummary _summaryFor(String period) {
    final now = DateTime.now();
    final (start, end) = _periodWindow(period, now);
    final inWindow = _allTransactions
        .where((t) => !t.date.isBefore(start) && t.date.isBefore(end))
        .toList();
    final completed = inWindow.where((t) => t.status == 'completed').toList();

    return SalesSummary(
      totalSales: completed.fold<double>(0, (sum, t) => sum + t.totalAmount),
      vendorEarnings:
          completed.fold<double>(0, (sum, t) => sum + t.vendorEarning),
      growboxCommission:
          completed.fold<double>(0, (sum, t) => sum + t.commission),
      completedOrders: completed.map((t) => t.orderId).toSet().length,
      totalOrders: inWindow.map((t) => t.orderId).toSet().length,
    );
  }

  // ── DAILY SERIES (dashboard Sales Overview) ──

  /// Completed revenue + order counts per day for the last [days] days
  /// (oldest → newest). Buckets the same records as [summary], so the
  /// dashboard chart and sparkline always reconcile with the Total Sales
  /// card on the Sales page.
  List<DailyPoint> dailySeries(int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final completed =
        _allTransactions.where((t) => t.status == 'completed').toList();
    return List.generate(days, (i) {
      final day = today.subtract(Duration(days: days - 1 - i));
      final nextDay = day.add(const Duration(days: 1));
      final revenue = completed
          .where((t) => !t.date.isBefore(day) && t.date.isBefore(nextDay))
          .fold<double>(0, (sum, t) => sum + t.totalAmount);
      final orders = _orders.allOrders
          .where((o) => !o.createdAt.isBefore(day) && o.createdAt.isBefore(nextDay))
          .length;
      return DailyPoint(day: day, revenue: revenue, orders: orders);
    });
  }

  /// Completed revenue grouped by product category, highest first — the
  /// dashboard's Sales by Category ring reads this instead of a hardcoded
  /// percentage split, so ring, legend and center KPI always agree with
  /// the orders.
  List<CategoryShare> get categoryShares {
    final amounts = <String, double>{};
    for (final t in _allTransactions) {
      if (t.status != 'completed') continue;
      final category = categoryFor(t.productName);
      amounts[category] = (amounts[category] ?? 0) + t.totalAmount;
    }
    final entries = amounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final e in entries) CategoryShare(category: e.key, amount: e.value),
    ];
  }

  // ── WEEKLY CHART ──

  /// Completed revenue per day for the last 7 days (oldest → newest).
  /// Cut from the same [dailySeries] buckets as the dashboard, so both
  /// charts and the Total Sales card always reconcile.
  List<SalesByPeriod> get chartData => [
        for (final p in dailySeries(7))
          SalesByPeriod(label: _weekdayLabel(p.day), amount: p.revenue),
      ];

  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  String _weekdayLabel(DateTime day) => _weekdays[day.weekday - 1];

  // ── COMPARISON ──

  /// Revenue change of the selected period against the equivalent previous
  /// window, as a percentage (e.g. 12.5 for +12.5%).
  ///
  /// Both windows empty → 0.0 (rendered as the neutral badge); previous
  /// empty with a positive current → 100.0 (new activity). Null for 'all',
  /// where no comparison is shown.
  double? revenueDelta(String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    double revenueIn(DateTime start, DateTime end) => _allTransactions
        .where((t) =>
            t.status == 'completed' &&
            !t.date.isBefore(start) &&
            t.date.isBefore(end))
        .fold<double>(0, (sum, t) => sum + t.totalAmount);

    final double current;
    final double previous;
    switch (period) {
      case 'today':
        current = revenueIn(today, now);
        previous = revenueIn(today.subtract(const Duration(days: 1)), today);
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        current = revenueIn(weekAgo, now);
        previous = revenueIn(now.subtract(const Duration(days: 14)), weekAgo);
      case 'month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        final startOfPrevMonth = DateTime(now.year, now.month - 1, 1);
        current = revenueIn(startOfMonth, now);
        previous = revenueIn(startOfPrevMonth, startOfMonth);
      default:
        return null;
    }

    if (previous == 0) return current == 0 ? 0.0 : 100.0;
    return (current - previous) / previous * 100;
  }

  // ── PERIODS ──

  /// Half-open window [start, end) for a period filter.
  (DateTime, DateTime) _periodWindow(String period, DateTime now) {
    switch (period) {
      case 'today':
        return (DateTime(now.year, now.month, now.day), now);
      case 'week':
        return (now.subtract(const Duration(days: 7)), now);
      case 'month':
        return (DateTime(now.year, now.month, 1), now);
      default:
        return (DateTime(2000), now);
    }
  }

  void setPeriod(String period) {
    if (_selectedPeriod == period) return;
    _selectedPeriod = period;
    notifyListeners();
  }
}