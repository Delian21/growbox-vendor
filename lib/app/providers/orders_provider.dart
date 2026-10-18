import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/order.dart';

class OrdersProvider extends ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  OrderStatus? _filterStatus;

  /// Filtered view, sorted for action: pending orders first (they need a
  /// decision), then newest to oldest within each group.
  List<Order> get orders {
    final list = _filterStatus == null
        ? List<Order>.from(_orders)
        : _orders.where((o) => o.status == _filterStatus).toList();
    list.sort((a, b) {
      final aPending = a.status == OrderStatus.pending ? 0 : 1;
      final bPending = b.status == OrderStatus.pending ? 0 : 1;
      if (aPending != bPending) return aPending - bPending;
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  bool get isLoading => _isLoading;
  OrderStatus? get filterStatus => _filterStatus;
  int get totalCount => _orders.length;
  int get pendingCount =>
      _orders.where((o) => o.status == OrderStatus.pending).length;

  /// Live per-status count for filter chip labels; [status] null = all.
  int countFor(OrderStatus? status) => status == null
      ? _orders.length
      : _orders.where((o) => o.status == status).length;

  /// Unfiltered orders. Consumers that need the whole picture (e.g. the
  /// Sales page's revenue) must not be affected by the Orders page's
  /// status filter, so they read this instead of [orders].
  List<Order> get allOrders => List.unmodifiable(_orders);

  /// Prefs key holding the decided-state overlay (status + rejection
  /// reason per order id) so decisions survive a page reload.
  static const String _stateKey = 'orders_state';

  /// [initialOrders] injects seed data (widget tests); production loads
  /// the in-memory demo orders. Decided states saved earlier (accept /
  /// reject + reason) are re-applied on top of the seed.
  OrdersProvider({List<Order>? initialOrders}) {
    if (initialOrders != null) {
      _orders = List.of(initialOrders);
    } else {
      _loadMockOrders();
    }
    _restoreState();
  }

  /// Re-applies persisted decisions (status + notes) onto the seed orders.
  /// Fire-and-forget: a brief flash of seed state on first paint is
  /// acceptable for the demo data set.
  Future<void> _restoreState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_stateKey);
      if (raw == null) return;
      final Map<String, dynamic> saved = jsonDecode(raw);

      var changed = false;
      final restored = <Order>[];
      for (final order in _orders) {
        final entry = saved[order.id];
        if (entry is! Map<String, dynamic>) {
          restored.add(order);
          continue;
        }
        final status = OrderStatus.values.asNameMap()[entry['status']];
        if (status == null) {
          restored.add(order);
          continue;
        }
        final notes = entry['notes'];
        restored.add(order.copyWith(
          status: status,
          notes: notes is String && notes.isNotEmpty ? notes : null,
        ));
        changed = true;
      }
      _orders = restored;
      if (changed) notifyListeners();
    } catch (_) {
      // A corrupt/absent store just means "all seed orders" — never crash.
    }
  }

  /// Writes every order's current status (+ rejection reason) to prefs —
  /// the overlay [_restoreState] replays on the next launch.
  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    final state = {
      for (final o in _orders)
        o.id: {
          'status': o.status.name,
          if (o.notes != null && o.notes!.isNotEmpty) 'notes': o.notes,
        },
    };
    await prefs.setString(_stateKey, jsonEncode(state));
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

  Future<bool> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    String? notes,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(status: newStatus, notes: notes);
      await _persistState();
    }

    _isLoading = false;
    notifyListeners();
    return index != -1;
  }

  /// Accepts several pending orders in one action: one simulated latency,
  /// one persist, one repaint. Non-pending or unknown ids are skipped;
  /// returns how many orders were actually accepted.
  Future<int> acceptOrders(List<String> orderIds) async {
    if (orderIds.isEmpty) return 0;

    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final wanted = orderIds.toSet();
    var accepted = 0;
    for (var i = 0; i < _orders.length; i++) {
      final order = _orders[i];
      if (wanted.contains(order.id) && order.status == OrderStatus.pending) {
        _orders[i] = order.copyWith(status: OrderStatus.accepted);
        accepted++;
      }
    }
    if (accepted > 0) await _persistState();

    _isLoading = false;
    notifyListeners();
    return accepted;
  }

  Order? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }
}