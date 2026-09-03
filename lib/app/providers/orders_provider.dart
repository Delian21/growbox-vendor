import 'package:flutter/material.dart';
import '../../data/models/order.dart';

class OrdersProvider extends ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  OrderStatus? _filterStatus;

  List<Order> get orders => _filterStatus == null
      ? _orders
      : _orders.where((o) => o.status == _filterStatus).toList();
  bool get isLoading => _isLoading;
  OrderStatus? get filterStatus => _filterStatus;
  int get totalCount => _orders.length;
  int get pendingCount =>
      _orders.where((o) => o.status == OrderStatus.pending).length;

  OrdersProvider() {
    _loadMockOrders();
  }

  void _loadMockOrders() {
    final now = DateTime.now();
    _orders = [
      Order(
        id: '#ORD-001',
        customerName: 'Chidi Okonkwo',
        customerPhone: '+234 801 234 5678',
        items: [
          OrderItem(
              productId: '1', productName: 'Fresh Tomatoes', quantity: 5, price: 2500),
          OrderItem(
              productId: '5', productName: 'Onions', quantity: 2, price: 1200),
        ],
        status: OrderStatus.pending,
        createdAt: now.subtract(const Duration(minutes: 2)),
      ),
      Order(
        id: '#ORD-002',
        customerName: 'Amina Bello',
        customerPhone: '+234 802 345 6789',
        items: [
          OrderItem(
              productId: '3', productName: 'Bell Peppers', quantity: 3, price: 3200),
        ],
        status: OrderStatus.preparing,
        createdAt: now.subtract(const Duration(minutes: 15)),
      ),
      Order(
        id: '#ORD-003',
        customerName: 'Emeka Nwosu',
        customerPhone: '+234 803 456 7890',
        items: [
          OrderItem(
              productId: '4', productName: 'Organic Lettuce', quantity: 2, price: 1500),
        ],
        status: OrderStatus.ready,
        createdAt: now.subtract(const Duration(minutes: 32)),
      ),
      Order(
        id: '#ORD-004',
        customerName: 'Fatima Abdullahi',
        customerPhone: '+234 804 567 8901',
        items: [
          OrderItem(
              productId: '2', productName: 'Sweet Potatoes', quantity: 10, price: 1800),
        ],
        status: OrderStatus.completed,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      Order(
        id: '#ORD-005',
        customerName: 'Bola Adeyemi',
        customerPhone: '+234 805 678 9012',
        items: [
          OrderItem(
              productId: '6', productName: 'Carrots', quantity: 4, price: 1800),
          OrderItem(
              productId: '5', productName: 'Onions', quantity: 3, price: 1200),
        ],
        status: OrderStatus.cancelled,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      Order(
        id: '#ORD-006',
        customerName: 'Ibrahim Musa',
        customerPhone: '+234 806 789 0123',
        items: [
          OrderItem(
              productId: '9', productName: 'Brown Rice', quantity: 20, price: 850),
        ],
        status: OrderStatus.accepted,
        createdAt: now.subtract(const Duration(minutes: 45)),
      ),
      Order(
        id: '#ORD-007',
        customerName: 'Grace Obi',
        customerPhone: '+234 807 890 1234',
        items: [
          OrderItem(
              productId: '7', productName: 'Fresh Oranges', quantity: 8, price: 2000),
          OrderItem(
              productId: '10', productName: 'Fresh Basil', quantity: 2, price: 500),
        ],
        status: OrderStatus.pending,
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
    ];
    notifyListeners();
  }

  void setFilter(OrderStatus? status) {
    _filterStatus = status;
    notifyListeners();
  }

  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(status: newStatus);
    }

    _isLoading = false;
    notifyListeners();
    return index != -1;
  }

  Order? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }
}