class SalesSummary {
  final double totalSales;
  final double vendorEarnings;
  final double growboxCommission;
  final int completedOrders;
  final int totalOrders;

  const SalesSummary({
    required this.totalSales,
    required this.vendorEarnings,
    required this.growboxCommission,
    required this.completedOrders,
    required this.totalOrders,
  });
}

class TransactionRecord {
  final String id;
  final String orderId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final double commission;
  final double vendorEarning;
  final DateTime date;
  final String status; // 'completed', 'pending', 'refunded'

  const TransactionRecord({
    required this.id,
    required this.orderId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.commission,
    required this.vendorEarning,
    required this.date,
    required this.status,
  });
}

class SalesByPeriod {
  final String label;
  final double amount;

  const SalesByPeriod({
    required this.label,
    required this.amount,
  });
}