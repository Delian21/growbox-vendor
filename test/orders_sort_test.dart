import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:growbox_vendor/app/providers/orders_provider.dart';
import 'package:growbox_vendor/data/models/order.dart';

/// Only the fields the sort reads matter here, so the factory stays tiny.
Order order(String id, OrderStatus status, Duration age) => Order(
      id: id,
      customerName: 'Customer $id',
      customerPhone: '+234 800 000 0000',
      items: [
        OrderItem(
          productId: '1',
          productName: 'Fresh Tomatoes',
          quantity: 1,
          price: 1000,
        ),
      ],
      status: status,
      createdAt: DateTime.now().subtract(age),
    );

List<String> idsOf(List<Order> orders) => orders.map((o) => o.id).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Deliberately shuffled input: a non-pending order newer than both pending
  // ones, and the pending pair out of chronological order.
  List<Order> seed() => [
        order('#ORD-A', OrderStatus.pending, const Duration(minutes: 10)),
        order('#ORD-B', OrderStatus.accepted, const Duration(minutes: 1)),
        order('#ORD-C', OrderStatus.pending, const Duration(minutes: 3)),
        order('#ORD-D', OrderStatus.completed, const Duration(minutes: 30)),
        order('#ORD-E', OrderStatus.preparing, const Duration(minutes: 2)),
      ];

  /// Pending group newest→oldest (C 3 min, A 10 min), then every other
  /// status newest→oldest (B 1 min, E 2 min, D 30 min). B is newer than both
  /// pending orders, so its position after them is what proves pending leads.
  const expected = ['#ORD-C', '#ORD-A', '#ORD-B', '#ORD-E', '#ORD-D'];

  test('default order: pending first, then everything else newest to oldest',
      () async {
    SharedPreferences.setMockInitialValues({});
    final provider = OrdersProvider(initialOrders: seed());

    expect(idsOf(provider.orders), expected,
        reason: 'the list the Orders page renders must lead with pending');
  });

  test('allOrders (dashboard, sales) reports the same sequence', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = OrdersProvider(initialOrders: seed());

    expect(idsOf(provider.allOrders), expected,
        reason: 'unfiltered readers must agree with the Orders page');
  });

  test('status chips still filter on top of the sorted list', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = OrdersProvider(initialOrders: seed());

    provider.setFilter(OrderStatus.pending);
    expect(idsOf(provider.orders), ['#ORD-C', '#ORD-A'],
        reason: 'pending chip keeps newest→oldest within the group');


    provider.setFilter(OrderStatus.accepted);
    expect(idsOf(provider.orders), ['#ORD-B']);

    provider.setFilter(OrderStatus.completed);
    expect(idsOf(provider.orders), ['#ORD-D']);

    provider.setFilter(null);
    expect(idsOf(provider.orders), expected,
        reason: 'clearing the filter restores the full canonical order');
  });
}
