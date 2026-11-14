import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/order.dart';

/// Progress of the last status change made to one order. The Orders page
/// shows a spinner on a `pending` row and an inline Retry on a `failed` one,
/// so a single change never blocks or blanks the rest of the list.
enum OrderRowState { idle, pending, failed }

/// One row's in-flight change: what was asked for (so a failed change can be
/// retried without the caller remembering it) and where the row came from.
class _RowChange {
  const _RowChange(
    this.state, {
    this.error,
    this.target,
    this.notes,
    this.from,
    this.clearNotes = false,
    this.isRestore = false,
  });

  final OrderRowState state;
  final String? error;
  final OrderStatus? target;
  final String? notes;
  final OrderStatus? from;

  /// Restore/Undo drops the rejection reason; Retry must keep doing that.
  final bool clearNotes;

  /// True when this row's change is an Undo/Restore rather than a normal
  /// transition — the row uses it to tell the two apart while rendering.
  final bool isRestore;

  bool get isPending => state == OrderRowState.pending;
}

class OrdersProvider extends ChangeNotifier {
  List<Order> _orders = [];

  /// First load only (seed + restored decisions). Status changes never flip
  /// this, so the list is never replaced by the skeleton while the vendor
  /// works on a row.
  bool _initialising = true;
  OrderStatus? _filterStatus;

  /// Per-order change state, keyed by order id. Absent = idle.
  final Map<String, _RowChange> _rowStates = {};

  /// How long a status change simulates backend latency. Tests shorten it.
  /// DEBUG ONLY: release builds ignore this and always take the production
  /// half-second (see [_simulateLatency]) — a test hook must never be able to
  /// change timing in a shipped app.
  Duration debugChangeDelay = const Duration(milliseconds: 500);

  // ── TEST HOOKS — never surfaced in the UI, inert outside debug builds ──
  /// Makes the next single status change fail once (rolled back + failed).
  bool debugFailNext = false;

  /// Ids whose next status change fails, so a batch can fail partially.
  final Set<String> debugFailOrderIds = {};

  /// How many times one change/batch ran the simulated delay. Test-only, so
  /// the batch tests can count one delay instead of timing the clock.
  int debugDelayCount = 0;

  /// How many times the state was written to prefs. Test-only.
  int debugSaveCount = 0;

  // ── TRANSITION RULES ──
  /// The one explicit rule table for order status changes. Anything not in
  /// the set is refused before any state changes and reported on the row.
  /// Completed and Cancelled are final — Undo/Restore ([restoreOrders]) is
  /// the single documented exception, and it only leaves Cancelled for the
  /// status the order held before it was rejected.
  static const Map<OrderStatus, Set<OrderStatus>> transitions = {
    OrderStatus.pending: {OrderStatus.accepted, OrderStatus.cancelled},
    OrderStatus.accepted: {OrderStatus.preparing, OrderStatus.cancelled},
    OrderStatus.preparing: {OrderStatus.ready, OrderStatus.cancelled},
    OrderStatus.ready: {OrderStatus.completed, OrderStatus.cancelled},
    OrderStatus.completed: <OrderStatus>{},
    OrderStatus.cancelled: <OrderStatus>{},
  };

  /// Whether [from] → [to] is a normal, allowed change.
  static bool canTransition(OrderStatus from, OrderStatus to) =>
      transitions[from]!.contains(to);

  /// Human-readable status name for error messages.
  static String statusLabel(OrderStatus status) => switch (status) {
        OrderStatus.pending => 'Pending',
        OrderStatus.accepted => 'Accepted',
        OrderStatus.preparing => 'Preparing',
        OrderStatus.ready => 'Ready',
        OrderStatus.completed => 'Completed',
        OrderStatus.cancelled => 'Cancelled',
      };

  /// How long a rejected order stays restorable from the Cancelled tab.
  static const Duration restoreWindow = Duration(hours: 24);

  /// Where a Restore puts each cancelled order back to — the status it held
  /// just before it was cancelled. Persisted with the state overlay.
  final Map<String, OrderStatus> _restoreTargets = {};

  /// The one order every list in the app is shown in: pending first (those
  /// need a decision), then newest to oldest within each group.
  ///
  /// Exposed so the filtered view, [allOrders] and any future consumer sort
  /// identically — a second comparator elsewhere is how the Orders page and
  /// the dashboard's Recent Orders drift apart.
  static int compareForAction(Order a, Order b) {
    final aPending = a.status == OrderStatus.pending ? 0 : 1;
    final bPending = b.status == OrderStatus.pending ? 0 : 1;
    if (aPending != bPending) return aPending - bPending;
    return b.createdAt.compareTo(a.createdAt);
  }

  /// Filtered view in [compareForAction] order. The status filter runs over
  /// the canonical order, so the chips (All / Pending / …) keep the same
  /// pending-first, newest-to-oldest shape inside each status.
  List<Order> get orders {
    final list = _filterStatus == null
        ? List<Order>.from(_orders)
        // A row whose change is in flight keeps its place in the filter it was
        // shown in, even though its optimistic status no longer matches — it
        // must stay visible while pending.
        : _orders
            .where((o) =>
                o.status == _filterStatus ||
                (_rowStates[o.id]?.isPending == true &&
                    _rowStates[o.id]?.from == _filterStatus))
            .toList();
    list.sort(compareForAction);
    return list;
  }

  /// True only while the very first load is being restored.
  bool get isLoading => _initialising;

  // ── Per-row change state ──
  OrderRowState rowState(String orderId) =>
      _rowStates[orderId]?.state ?? OrderRowState.idle;

  String? rowError(String orderId) => _rowStates[orderId]?.error;

  /// The status the in-flight (or failed) change is aiming for, so the row can
  /// spin the button that was pressed and Retry can repeat it.
  OrderStatus? rowTarget(String orderId) => _rowStates[orderId]?.target;

  /// Retry only exists when the failed change had a target — a change refused
  /// by the transition table has nothing to repeat.
  bool canRetry(String orderId) => _rowStates[orderId]?.target != null;

  /// True while this row's change is an Undo/Restore.
  bool isRestoringRow(String orderId) =>
      _rowStates[orderId]?.isRestore ?? false;

  /// True when this row's in-flight (or failed) change is a Pending decision
  /// (Accept or Reject) — those two actions stay rendered for it while the
  /// optimistic status no longer reads "pending".
  bool isPendingDecisionRow(String orderId) {
    final change = _rowStates[orderId];
    return change != null &&
        !change.isRestore &&
        change.from == OrderStatus.pending;
  }

  /// A rejected order can be restored for [restoreWindow] after it was
  /// created; older cancelled orders are final.
  bool canRestore(Order order) =>
      order.status == OrderStatus.cancelled &&
      DateTime.now().difference(order.createdAt) < restoreWindow;

  /// The status a Restore targets for [orderId] (defaults to Pending when the
  /// pre-cancel status was never recorded, e.g. the seeded demo orders).
  OrderStatus restoreTargetFor(String orderId) =>
      _validRestoreTarget(_restoreTargets[orderId]);

  OrderStatus _validRestoreTarget(OrderStatus? stored) {
    if (stored != null &&
        stored != OrderStatus.cancelled &&
        stored != OrderStatus.completed) {
      return stored;
    }
    return OrderStatus.pending;
  }
  OrderStatus? get filterStatus => _filterStatus;
  int get totalCount => _orders.length;
  int get pendingCount =>
      _orders.where((o) => o.status == OrderStatus.pending).length;

  /// Live per-status count for filter chip labels; [status] null = all.
  int countFor(OrderStatus? status) => status == null
      ? _orders.length
      : _orders.where((o) => o.status == status).length;

  /// Unfiltered orders, in the same [compareForAction] order as [orders].
  /// Consumers that need the whole picture (e.g. the Sales page's revenue)
  /// must not be affected by the Orders page's status filter, so they read
  /// this instead of [orders] — but they get the identical sequence, so the
  /// dashboard's Recent Orders and the Orders table never disagree.
  List<Order> get allOrders => List.unmodifiable(
        List<Order>.from(_orders)..sort(compareForAction),
      );

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
        final restoreTo = OrderStatus.values.asNameMap()[entry['restoreTo']];
        if (status == OrderStatus.cancelled &&
            restoreTo != null &&
            restoreTo != OrderStatus.cancelled) {
          _restoreTargets[order.id] = restoreTo;
        }
        changed = true;
      }
      _orders = restored;
      if (changed) notifyListeners();
    } catch (_) {
      // A corrupt/absent store just means "all seed orders" — never crash.
    } finally {
      // First load ends here (including the no-saved-state and corrupt-store
      // paths); from now on the list is never replaced by the skeleton.
      _initialising = false;
      notifyListeners();
    }
  }

  /// Writes every order's current status (+ rejection reason) to prefs —
  /// the overlay [_restoreState] replays on the next launch.
  Future<void> _persistState() async {
    if (kDebugMode) debugSaveCount++;
    final prefs = await SharedPreferences.getInstance();
    final state = {
      for (final o in _orders)
        o.id: {
          'status': o.status.name,
          if (o.notes != null && o.notes!.isNotEmpty) 'notes': o.notes,
          // Remember where a Restore goes, so the 24h window survives reloads.
          if (o.status == OrderStatus.cancelled &&
              _restoreTargets[o.id] != null)
            'restoreTo': _restoreTargets[o.id]!.name,
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

  /// Changes one order optimistically: the row shows [newStatus] immediately,
  /// only its own [OrderRowState] goes pending, and a failure rolls the row
  /// back and marks it failed. Everything else in the list stays interactive.
  ///
  /// Refused up front when [transitions] doesn't allow the move — nothing is
  /// changed, and the row reports why.
  Future<bool> updateOrderStatus(
    String orderId,
    OrderStatus newStatus, {
    String? notes,
    bool clearNotes = false,
  }) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return false;

    final previous = _orders[index];
    if (!canTransition(previous.status, newStatus)) {
      _rowStates[orderId] = _RowChange(
        OrderRowState.failed,
        error: '${statusLabel(previous.status)} orders can\'t move to '
            '${statusLabel(newStatus)}.',
        from: previous.status,
      );
      notifyListeners();
      return false;
    }

    _rowStates[orderId] = _RowChange(
      OrderRowState.pending,
      target: newStatus,
      notes: notes,
      from: previous.status,
      clearNotes: clearNotes,
    );
    _orders[index] = previous.copyWith(
      status: newStatus,
      notes: notes,
      clearNotes: clearNotes,
    );
    notifyListeners();

    await _simulateLatency();

    if (_consumeFailure(orderId)) {
      _rollBack(orderId, previous, newStatus, notes);
      return false;
    }

    await _persistState();
    _rowStates[orderId] = const _RowChange(OrderRowState.idle);
    if (newStatus == OrderStatus.cancelled) {
      // Remember where a Restore/Undo should put this order back to.
      _restoreTargets[orderId] = previous.status;
    } else {
      _restoreTargets.remove(orderId);
    }
    notifyListeners();
    return true;
  }

  /// Repeats the change that failed on [orderId]; the failed state already
  /// remembers the target status and any rejection reason.
  Future<bool> retryOrderChange(String orderId) async {
    final change = _rowStates[orderId];
    final target = change?.target;
    if (change == null || change.state != OrderRowState.failed || target == null) {
      return false;
    }
    // An undo is repeated as an undo (it bypasses the table for Cancelled).
    if (change.isRestore) {
      final restored = await restoreOrders([orderId]);
      return restored > 0;
    }
    return updateOrderStatus(
      orderId,
      target,
      notes: change.notes,
      clearNotes: change.clearNotes,
    );
  }

  /// Accepts pending orders in one action. See [_applyBatch].
  Future<int> acceptOrders(List<String> orderIds) =>
      _applyBatch(orderIds, OrderStatus.accepted);

  /// Rejects orders in one action, applying [notes] (the dialog's optional
  /// reason) to each of them. Only ids the transition table allows to be
  /// cancelled take part. See [_applyBatch].
  Future<int> rejectOrders(List<String> orderIds, {String? notes}) =>
      _applyBatch(orderIds, OrderStatus.cancelled, notes: notes);

  /// Undo/Restore — the single documented exception to the table: a cancelled
  /// order goes back to the status it held before it was cancelled (Pending
  /// when that was never recorded). The rejection reason is removed.
  ///
  /// Uses the same per-row pending/failed state as every other change and one
  /// delay/save for the whole set, so a failed undo shows an inline error with
  /// Retry instead of doing nothing. Refuses orders outside the 24h window.
  Future<int> restoreOrders(List<String> orderIds) async {
    final wanted = orderIds.toSet();
    final previous = <String, Order>{};
    for (var i = 0; i < _orders.length; i++) {
      final order = _orders[i];
      if (!wanted.contains(order.id)) continue;
      if (order.status != OrderStatus.cancelled) continue;
      if (!canRestore(order)) continue;
      final target = restoreTargetFor(order.id);
      previous[order.id] = order;
      _rowStates[order.id] = _RowChange(
        OrderRowState.pending,
        target: target,
        from: order.status,
        clearNotes: true,
        isRestore: true,
      );
      _orders[i] = order.copyWith(status: target, clearNotes: true);
    }
    if (previous.isEmpty) return 0;

    notifyListeners();
    await _simulateLatency();

    var applied = 0;
    for (final entry in previous.entries) {
      final target = restoreTargetFor(entry.key);
      if (_consumeFailure(entry.key)) {
        _rollBack(entry.key, entry.value, target, null,
            clearNotes: true, isRestore: true);
        continue;
      }
      _restoreTargets.remove(entry.key);
      _rowStates[entry.key] = const _RowChange(OrderRowState.idle);
      applied++;
    }
    if (applied > 0) await _persistState();
    notifyListeners();
    return applied;
  }

  /// Applies [newStatus] to every eligible id with ONE simulated delay and ONE
  /// save. Each order gets its own pending → idle/failed transition, so a
  /// single failure never undoes the others. Non-matching ids are skipped;
  /// returns how many orders actually changed.
  Future<int> _applyBatch(
    List<String> orderIds,
    OrderStatus newStatus, {
    String? notes,
  }) async {
    final wanted = orderIds.toSet();
    final previous = <String, Order>{};
    for (var i = 0; i < _orders.length; i++) {
      final order = _orders[i];
      if (!wanted.contains(order.id)) continue;
      // The table decides eligibility — Completed/Cancelled ids are skipped.
      if (!canTransition(order.status, newStatus)) continue;
      previous[order.id] = order;
      _rowStates[order.id] = _RowChange(
        OrderRowState.pending,
        target: newStatus,
        notes: notes,
        from: order.status,
      );
      _orders[i] = order.copyWith(status: newStatus, notes: notes);
    }
    if (previous.isEmpty) return 0;

    notifyListeners();
    await _simulateLatency();

    var applied = 0;
    for (final entry in previous.entries) {
      if (_consumeFailure(entry.key)) {
        _rollBack(entry.key, entry.value, newStatus, notes);
        continue;
      }
      _rowStates[entry.key] = const _RowChange(OrderRowState.idle);
      if (newStatus == OrderStatus.cancelled) {
        _restoreTargets[entry.key] = entry.value.status;
      } else {
        _restoreTargets.remove(entry.key);
      }
      applied++;
    }
    if (applied > 0) await _persistState();
    notifyListeners();
    return applied;
  }

  /// True when this change is forced to fail (test hooks). Each hook is
  /// one-shot so a retry can succeed.
  bool _consumeFailure(String orderId) {
    // TEST HOOKS ARE DEBUG-ONLY: tests run with asserts enabled, so the guard
    // is always true there. In a release build the failures are impossible —
    // no stray flag or id can make a real vendor's order fail its save.
    if (!kDebugMode) return false;
    if (debugFailOrderIds.remove(orderId)) return true;
    if (debugFailNext) {
      debugFailNext = false;
      return true;
    }
    return false;
  }

  /// The mock backend's latency. Release builds always take the production
  /// half-second: [debugChangeDelay] is a debug-only test hook, so a
  /// non-default value in a release build is ignored rather than honoured.
  Future<void> _simulateLatency() async {
    if (kDebugMode) debugDelayCount++;
    await Future<void>.delayed(kDebugMode
        ? debugChangeDelay
        : const Duration(milliseconds: 500));
  }

  /// Puts the row back the way it was and records why, so the row can show an
  /// inline error with a Retry that repeats the same change.
  void _rollBack(
    String orderId,
    Order previous,
    OrderStatus target,
    String? notes, {
    bool clearNotes = false,
    bool isRestore = false,
  }) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) _orders[index] = previous;
    _rowStates[orderId] = _RowChange(
      OrderRowState.failed,
      error: 'Couldn\'t update this order. Check your connection and retry.',
      target: target,
      notes: notes,
      from: previous.status,
      clearNotes: clearNotes,
      isRestore: isRestore,
    );
    notifyListeners();
  }

  Order? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }
}