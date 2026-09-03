import '../models/sales_data.dart';
import '../mock/mock_sales.dart';

class SalesRepository {
  List<TransactionRecord> getAllTransactions() {
    return List.unmodifiable(mockTransactions);
  }

  List<TransactionRecord> getTransactionsByStatus(String status) {
    return mockTransactions.where((t) => t.status == status).toList();
  }

  List<TransactionRecord> getTransactionsByDateRange(DateTime start, DateTime end) {
    return mockTransactions.where((t) {
      return t.date.isAfter(start) && t.date.isBefore(end);
    }).toList();
  }

  List<TransactionRecord> getTodayTransactions() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getTransactionsByDateRange(startOfDay, endOfDay);
  }

  List<TransactionRecord> getWeekTransactions() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(const Duration(days: 7));
    return getTransactionsByDateRange(startOfWeek, now);
  }

  List<TransactionRecord> getMonthTransactions() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return getTransactionsByDateRange(startOfMonth, now);
  }

  SalesSummary getSalesSummary() {
    return getMockSalesSummary();
  }

  SalesSummary getSalesSummaryForPeriod(DateTime start, DateTime end) {
    final transactions = getTransactionsByDateRange(start, end);
    final completed = transactions.where((t) => t.status == 'completed').toList();
    final totalSales = completed.fold<double>(0, (sum, t) => sum + t.totalAmount);
    final totalCommission = completed.fold<double>(0, (sum, t) => sum + t.commission);
    final totalEarnings = completed.fold<double>(0, (sum, t) => sum + t.vendorEarning);
    final orderIds = completed.map((t) => t.orderId).toSet();

    return SalesSummary(
      totalSales: totalSales,
      vendorEarnings: totalEarnings,
      growboxCommission: totalCommission,
      completedOrders: orderIds.length,
      totalOrders: transactions.map((t) => t.orderId).toSet().length,
    );
  }

  List<SalesByPeriod> getWeeklyChartData() {
    return List.unmodifiable(mockWeeklySales);
  }
}