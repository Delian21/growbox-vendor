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

  /// The product's selling unit (kg, bunch, litre, …) from the product
  /// catalog — shown for the unit price and the quantity.
  final String unit;
  final double unitPrice;
  final double totalAmount;
  final double commission;
  final double vendorEarning;
  final DateTime date;
  final String status; // 'completed', 'pending', 'cancelled'

  const TransactionRecord({
    required this.id,
    required this.orderId,
    required this.productName,
    required this.quantity,
    required this.unit,
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

/// One day of the dashboard's Sales Overview series: completed revenue
/// plus how many orders were CREATED that day (any status — the orange
/// "Orders" line measures activity, not revenue).
class DailyPoint {
  final DateTime day;
  final double revenue;
  final int orders;

  const DailyPoint({
    required this.day,
    required this.revenue,
    required this.orders,
  });
}

/// Completed revenue grouped by product category — the Sales by Category
/// ring on the dashboard.
class CategoryShare {
  final String category;
  final double amount;

  const CategoryShare({
    required this.category,
    required this.amount,
  });
}