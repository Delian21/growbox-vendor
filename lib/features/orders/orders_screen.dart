import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../app/providers/orders_provider.dart';
import '../../shared/widgets/growbox_filter_chip.dart';
import '../../shared/widgets/growbox_button.dart';
import '../../shared/widgets/growbox_card.dart';
import '../../shared/widgets/growbox_empty_state.dart';
import '../../shared/widgets/growbox_page_header.dart';
import '../../shared/widgets/growbox_status_pill.dart';
import '../../shared/widgets/growbox_table.dart';
import '../../shared/widgets/growbox_table_action.dart';
import '../../data/models/order.dart';
import '../../shared/widgets/shimmer_loader.dart';
import '../../shared/utils/snackbar_helper.dart';
import '../../core/utils/formatters.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  /// Pending orders ticked for the bulk "Accept selected" action.
  final Set<String> _selectedPending = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ordersProvider = context.watch<OrdersProvider>();
    final orders = ordersProvider.orders;

    // Drop selections whose orders are no longer pending in the current
    // view (accepted elsewhere, rejected, filtered out).
    _selectedPending.removeWhere((id) =>
        !orders.any((o) => o.id == id && o.status == OrderStatus.pending));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GrowboxPageHeader(subtitle: '${ordersProvider.totalCount} total orders'),
          const SizedBox(height: AppDimensions.lg),
          _buildTabs(context, isDark, ordersProvider),
          const SizedBox(height: AppDimensions.lg),
          if (_selectedPending.isNotEmpty) ...[
            _buildBulkBar(context, isDark),
            const SizedBox(height: AppDimensions.lg),
          ],
          if (ordersProvider.isLoading)
            GrowboxCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: List.generate(3, (_) => const OrderCardSkeleton()),
              ),
            )
          else if (orders.isEmpty)
            _buildEmptyState(context, isDark, ordersProvider)
          else
            _buildOrdersTable(context, isDark, orders),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context, bool isDark, OrdersProvider provider) {
    // Counts come from the provider (live per-status), not hardcoded labels.
    final tabs = [
      _TabItem(label: 'All', status: null),
      _TabItem(label: 'Pending', status: OrderStatus.pending),
      _TabItem(label: 'Accepted', status: OrderStatus.accepted),
      _TabItem(label: 'Preparing', status: OrderStatus.preparing),
      _TabItem(label: 'Ready', status: OrderStatus.ready),
      _TabItem(label: 'Completed', status: OrderStatus.completed),
      _TabItem(label: 'Cancelled', status: OrderStatus.cancelled),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.sm),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isSelected = provider.filterStatus == tab.status;

          return GrowboxFilterChip(
            label: tab.label,
            count: provider.countFor(tab.status),
            selected: isSelected,
            onSelected: (_) => provider.setFilter(tab.status),
          );
        },
      ),
    );
  }

  // ── Column geometry shared by the header row and EVERY data row, so
  // Order / Items / Amount / Status / Time / Actions line up at all times.
  // Status is a fixed pill width; Actions is always reserved (empty on
  // non-pending rows) so nothing shifts when a row has buttons.
  static const double _statusColWidth = 90;
  static const double _timeColWidth = 80;
  static const double _actionsColWidth = 176;

  Widget _buildOrdersTable(BuildContext context, bool isDark, List<Order> orders) {
    final isMobile = MediaQuery.sizeOf(context).width < AppDimensions.tablet;

    return GrowboxCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row mirrors the dashboard's Recent Orders table style.
          if (!isMobile) ...[
            _buildTableHeader(context, isDark),
            GrowboxTable.headerDivider(isDark),
          ],
          ...orders.map((order) => _buildOrderRow(context, order, isDark)),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context, bool isDark) {
    return GrowboxTable.headerRow(
      children: [
        // Same flex/fixed widths as _buildOrderRow's desktop branch.
        Expanded(flex: 2, child: GrowboxTable.headerCell('Order', isDark)),
        Expanded(flex: 3, child: GrowboxTable.headerCell('Items', isDark)),
        Expanded(flex: 2, child: GrowboxTable.headerCell('Amount', isDark)),
        SizedBox(width: _statusColWidth, child: GrowboxTable.headerCell('Status', isDark)),
        const SizedBox(width: AppDimensions.md),
        SizedBox(width: _timeColWidth, child: GrowboxTable.headerCell('Time', isDark)),
        SizedBox(
          width: _actionsColWidth,
          child: Align(
            alignment: Alignment.centerRight,
            child: GrowboxTable.headerCell('Actions', isDark),
          ),
        ),
      ],
    );
  }




  Widget _buildOrderRow(BuildContext context, Order order, bool isDark) {
    final itemsText = order.items.map((i) => '${i.productName} (${i.quantity})').join(', '); 
    final isMobile = MediaQuery.sizeOf(context).width < AppDimensions.tablet;

    // Mobile: Card layout
    if (isMobile) {
      return GrowboxTable.row(
        isDark: isDark,
        mobile: true,
        onTap: () => // Percent-encode: ids start with '#', which GoRouter would
        // otherwise treat as a URL fragment and drop the path
        // parameter (the row would never navigate).
        context.go('/orders/${Uri.encodeComponent(order.id)}'),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.id, style: GrowboxTable.strongStyle(isDark)),
                        const SizedBox(height: 2),
                        Text(order.customerName, style: GrowboxTable.metaStyle(isDark)),
                      ],
                    ),
                  ),
                  GrowboxStatusPill(status: order.status.name),
                ],
              ),
              const SizedBox(height: AppDimensions.sm),
              Text(itemsText, style: GrowboxTable.secondaryStyle(isDark), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: AppDimensions.sm),
              Row(
                children: [
                  Text(formatCurrency(order.totalAmount), style: GrowboxTable.strongStyle(isDark)),
                  const Spacer(),
                  // Time — secondary text (same as the dashboard table) for contrast.
                  Text(timeAgo(order.createdAt), style: GrowboxTable.metaStyle(isDark)),
                ],
              ),
              if (order.status == OrderStatus.pending) ...[
                const SizedBox(height: AppDimensions.sm),                  Row(
                    children: [
                      // Bulk-select tick — pending orders only.
                      Checkbox(
                        value: _selectedPending.contains(order.id),
                        onChanged: (v) => _toggleSelected(order.id, v),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Expanded(
                        child: GrowboxButton(
                          label: 'Accept',
                          onPressed: () => _acceptOrder(context, order),
                          icon: Icons.check_circle_outline,
                        ),
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    // Ghost destructive: outlined red instead of solid fill.
                    Expanded(
                      child: GrowboxButton(
                        label: 'Reject',
                        onPressed: () => _rejectOrder(context, order),
                        variant: GrowboxButtonVariant.dangerOutline,
                        icon: Icons.cancel_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
      );
    }

    // Desktop: Table row
    return GrowboxTable.row(
      isDark: isDark,
      onTap: () => // Percent-encode: ids start with '#', which GoRouter would
        // otherwise treat as a URL fragment and drop the path
        // parameter (the row would never navigate).
        context.go('/orders/${Uri.encodeComponent(order.id)}'),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Order ID + Customer
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(order.id, style: GrowboxTable.strongStyle(isDark)),
                  const SizedBox(height: 2),
                  Text(order.customerName, style: GrowboxTable.metaStyle(isDark)),
                ],
              ),
            ),
            // Items
            Expanded(
              flex: 3,
              child: Text(itemsText, style: GrowboxTable.secondaryStyle(isDark), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            // Amount
            Expanded(
              flex: 2,
              child: Text(formatCurrency(order.totalAmount), style: GrowboxTable.strongStyle(isDark)),
            ),
            // Status — fixed pill width shared with the header row.
            SizedBox(
              width: _statusColWidth,
              child: Align(alignment: Alignment.centerLeft, child: GrowboxStatusPill(status: order.status.name)),
            ),
            const SizedBox(width: AppDimensions.md),
            // Time — secondary text (same as the dashboard table) for contrast.
            SizedBox(
              width: _timeColWidth,
              child: Text(timeAgo(order.createdAt), style: GrowboxTable.metaStyle(isDark)),
            ),
            // Actions — reserved on EVERY row so columns never shift; only
            // pending orders get buttons.
            SizedBox(
              width: _actionsColWidth,
              child: order.status == OrderStatus.pending
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Bulk-select tick — pending orders only.
                        Checkbox(
                          value: _selectedPending.contains(order.id),
                          onChanged: (v) => _toggleSelected(order.id, v),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 4),
                        // Accept stays the solid, primary action — the same
                        // shared table-action component the dashboard uses.
                        GrowboxTableAction(
                          label: 'Accept',
                          onTap: () => _acceptOrder(context, order),
                        ),
                        const SizedBox(width: 6),
                        // Reject is a ghost/outlined action — less weight.
                        GrowboxTableAction(
                          label: 'Reject',
                          variant: GrowboxTableActionVariant.outline,
                          onTap: () => _rejectOrder(context, order),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, OrdersProvider provider) {
    return GrowboxCard(
      child: GrowboxEmptyState(
        icon: Icons.receipt_long_outlined,
        title: provider.filterStatus == null ? 'No orders yet' : 'No ${provider.filterStatus!.name} orders',
        subtitle: 'Orders from customers will appear here.',
      ),
    );
  }

  Future<void> _acceptOrder(BuildContext context, Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Order'),
        content: Text('Accept order ${order.id} from ${order.customerName}?\n\nThis will notify the customer that their order has been accepted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Accept')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final success = await context.read<OrdersProvider>().updateOrderStatus(order.id, OrderStatus.accepted);
      if (success && context.mounted) {
        SnackbarHelper.showSuccess(context, 'Order ${order.id} accepted');
      }
    }
  }

  void _toggleSelected(String orderId, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedPending.add(orderId);
      } else {
        _selectedPending.remove(orderId);
      }
    });
  }

  // The selection bar shown above the table while ticked orders exist.
  Widget _buildBulkBar(BuildContext context, bool isDark) {
    return GrowboxCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.lg,
        vertical: AppDimensions.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.checklist, size: 18, color: AppColors.primary),
          const SizedBox(width: AppDimensions.sm),
          Text(
            '${_selectedPending.length} pending order${_selectedPending.length == 1 ? '' : 's'} selected',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() => _selectedPending.clear()),
            child: const Text('Clear'),
          ),
          const SizedBox(width: AppDimensions.sm),
          GrowboxButton(
            label: 'Accept selected (${_selectedPending.length})',
            icon: Icons.check_circle_outline,
            onPressed: () => _acceptSelected(context),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptSelected(BuildContext context) async {
    final provider = context.read<OrdersProvider>();
    final count = await provider.acceptOrders(_selectedPending.toList());
    if (!context.mounted) return;
    setState(_selectedPending.clear);
    if (count > 0) {
      SnackbarHelper.showSuccess(
          context, '$count order${count == 1 ? '' : 's'} accepted');
    } else {
      SnackbarHelper.showError(context, 'No pending orders in the selection');
    }
  }

  Future<void> _rejectOrder(BuildContext context, Order order) async {
    // The dialog returns the trimmed reason on confirm (possibly empty —
    // skipping it still rejects) and null when the vendor keeps the order.
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _RejectOrderDialog(order: order),
    );

    if (reason != null && context.mounted) {
      final success = await context.read<OrdersProvider>().updateOrderStatus(
        order.id,
        OrderStatus.cancelled,
        notes: reason.isEmpty ? null : reason,
      );
      if (success && context.mounted) {
        SnackbarHelper.showSuccess(context, 'Order ${order.id} rejected');
      }
    }
  }
}

class _TabItem {
  final String label;
  final OrderStatus? status;
  _TabItem({required this.label, required this.status});
}

/// Confirmation dialog for rejecting an order, with an optional reason.
///
/// It owns its [TextEditingController] so disposal happens in
/// [State.dispose] — after the dialog's exit animation finishes — instead
/// of the moment `showDialog` completes, which would crash the still-
/// animating TextField.
class _RejectOrderDialog extends StatefulWidget {
  final Order order;

  const _RejectOrderDialog({required this.order});

  @override
  State<_RejectOrderDialog> createState() => _RejectOrderDialogState();
}

class _RejectOrderDialogState extends State<_RejectOrderDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Order'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reject order ${widget.order.id} from ${widget.order.customerName}?\n\nThis action cannot be undone and the customer will be notified.'),
          const SizedBox(height: AppDimensions.lg),
          // Optional: a short reason the customer can be told; skipping it
          // still rejects the order.
          TextField(
            controller: _reasonController,
            maxLines: 3,
            maxLength: 200,
            decoration: const InputDecoration(
              counterText: '',
              labelText: 'Reason (optional)',
              hintText: 'e.g. Out of stock today',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep Order'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, _reasonController.text.trim()),
          child: const Text('Reject Order', style: TextStyle(color: AppColors.error)),
        ),
      ],
    );
  }
}