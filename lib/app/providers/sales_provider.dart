import 'package:flutter/material.dart';
import '../../data/models/sales_data.dart';
import '../../data/repositories/sales_repository.dart';

class SalesProvider extends ChangeNotifier {
  final SalesRepository _repository = SalesRepository();

  List<TransactionRecord> _transactions = [];
  SalesSummary _summary = const SalesSummary(
    totalSales: 0,
    vendorEarnings: 0,
    growboxCommission: 0,
    completedOrders: 0,
    totalOrders: 0,
  );
  List<SalesByPeriod> _chartData = [];
  String _selectedPeriod = 'all';
  bool _isLoading = false;

  List<TransactionRecord> get transactions => _transactions;
  SalesSummary get summary => _summary;
  List<SalesByPeriod> get chartData => _chartData;
  String get selectedPeriod => _selectedPeriod;
  bool get isLoading => _isLoading;

  SalesProvider() {
    loadSalesData();
  }

  void loadSalesData() {
    _isLoading = true;
    notifyListeners();

    _transactions = _repository.getAllTransactions();
    _summary = _repository.getSalesSummary();
    _chartData = _repository.getWeeklyChartData();

    _isLoading = false;
    notifyListeners();
  }

  void setPeriod(String period) {
    _selectedPeriod = period;
    _isLoading = true;
    notifyListeners();

    final now = DateTime.now();

    switch (period) {
      case 'today':
        _transactions = _repository.getTodayTransactions();
        _summary = _repository.getSalesSummaryForPeriod(
          DateTime(now.year, now.month, now.day),
          now,
        );
        break;
      case 'week':
        _transactions = _repository.getWeekTransactions();
        _summary = _repository.getSalesSummaryForPeriod(
          now.subtract(const Duration(days: 7)),
          now,
        );
        break;
      case 'month':
        _transactions = _repository.getMonthTransactions();
        _summary = _repository.getSalesSummaryForPeriod(
          DateTime(now.year, now.month, 1),
          now,
        );
        break;
      default:
        _transactions = _repository.getAllTransactions();
        _summary = _repository.getSalesSummary();
    }

    _isLoading = false;
    notifyListeners();
  }

  List<TransactionRecord> getTransactionsByStatus(String status) {
    return _transactions.where((t) => t.status == status).toList();
  }
}