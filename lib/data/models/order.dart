enum OrderStatus {
  pending,
  accepted,
  preparing,
  ready,
  completed,
  cancelled,
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;
}

class Order {
  final String id;
  final String customerName;
  final String customerPhone;
  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime createdAt;
  final String? notes;

  Order({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.status,
    required this.createdAt,
    this.notes,
  });

  double get totalAmount =>
      items.fold(0, (sum, item) => sum + item.total);

  int get totalItems =>
      items.fold(0, (sum, item) => sum + item.quantity);

  Order copyWith({
    String? customerName,
    String? customerPhone,
    List<OrderItem>? items,
    OrderStatus? status,
    DateTime? createdAt,
    String? notes,
  }) {
    return Order(
      id: id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      items: items ?? this.items,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }
}