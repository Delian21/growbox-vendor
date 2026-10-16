import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../app/providers/orders_provider.dart';
import '../../shared/widgets/growbox_badge.dart';
import '../../shared/widgets/growbox_button.dart';
import '../../shared/widgets/growbox_card.dart';
import '../../shared/widgets/growbox_empty_state.dart';
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
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ordersProvider = context.watch<OrdersProvider>();
    final orders = ordersProvider.orders;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isDark, ordersProvider),
          const SizedBox(height: AppDimensions.lg),
          _buildTabs(context, isDark, ordersProvider),
          const SizedBox(height: AppDimensions.lg),
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

  Widget _buildHeader(BuildContext context, bool isDark, OrdersProvider provider) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Orders',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                '${provider.totalCount} total orders',
                style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
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

          return FilterChip(
            label: Text('${tab.label} (${provider.countFor(tab.status)})'),
            selected: isSelected,
            onSelected: (_) => provider.setFilter(tab.status),
            selectedColor: isDark ? AppColors.primaryDark : AppColors.primary,
            checkmarkColor: isDark ? AppColors.darkPrimary : Colors.white,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? (isDark ? AppColors.darkPrimary : Colors.white)
                  : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            ),
            backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusFull)),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
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
  static const double _actionsColWidth = 148;

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
            Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
          ],
          ...orders.map((order) => _buildOrderRow(context, order, isDark)),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.md),
      child: Row(
        children: [
          // Same flex/fixed widths as _buildOrderRow's desktop branch.
          Expanded(flex: 2, child: _tableHeader('Order', isDark)),
          Expanded(flex: 3, child: _tableHeader('Items', isDark)),
          Expanded(flex: 2, child: _tableHeader('Amount', isDark)),
          SizedBox(width: _statusColWidth, child: _tableHeader('Status', isDark)),
          const SizedBox(width: AppDimensions.md),
          SizedBox(width: _timeColWidth, child: _tableHeader('Time', isDark)),
          SizedBox(
            width: _actionsColWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: _tableHeader('Actions', isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary, letterSpacing: 0.5),
    );
  }



  Widget _buildOrderRow(BuildContext context, Order order, bool isDark) {
    final itemsText = order.items.map((i) => '${i.productName} (${i.quantity})').join(', '); 
    final isMobile = MediaQuery.sizeOf(context).width < AppDimensions.tablet;

    // Mobile: Card layout
    if (isMobile) {
      return InkWell(
        onTap: () => context.go('/orders/${order.id}'),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.lg),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border, width: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.id, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(order.customerName, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  _statusBadge(order.status),
                ],
              ),
              const SizedBox(height: AppDimensions.sm),
              Text(itemsText, style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: AppDimensions.sm),
              Row(
                children: [
                  Text(formatCurrency(order.totalAmount), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  const Spacer(),
                  // Time — secondary text (same as the dashboard table) for contrast.
                  Text(_timeAgo(order.createdAt), style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                ],
              ),
              if (order.status == OrderStatus.pending) ...[
                const SizedBox(height: AppDimensions.sm),
                Row(
                  children: [
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
        ),
      );
    }

    // Desktop: Table row
    return InkWell(
      onTap: () => context.go('/orders/${order.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg, vertical: AppDimensions.md),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: (isDark ? AppColors.darkBorder : AppColors.border).withValues(alpha: 0.5), width: 0.5)),
        ),
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
                  Text(order.id, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(order.customerName, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                ],
              ),
            ),
            // Items
            Expanded(
              flex: 3,
              child: Text(itemsText, style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            // Amount
            Expanded(
              flex: 2,
              child: Text(formatCurrency(order.totalAmount), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
            ),
            // Status — fixed pill width shared with the header row.
            SizedBox(
              width: _statusColWidth,
              child: Align(alignment: Alignment.centerLeft, child: _statusBadge(order.status)),
            ),
            const SizedBox(width: AppDimensions.md),
            // Time — secondary text (same as the dashboard table) for contrast.
            SizedBox(
              width: _timeColWidth,
              child: Text(_timeAgo(order.createdAt), style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
            ),
            // Actions — reserved on EVERY row so columns never shift; only
            // pending orders get buttons.
            SizedBox(
              width: _actionsColWidth,
              child: order.status == OrderStatus.pending
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Accept stays the solid, primary action.
                        GestureDetector(
                          onTap: () => _acceptOrder(context, order),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                            ),
                            child: const Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Reject is a ghost/outlined action — less weight.
                        GestureDetector(
                          onTap: () => _rejectOrder(context, order),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(color: AppColors.error, width: 1),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                            ),
                            child: const Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error)),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(OrderStatus status) {
    return switch (status) {
      OrderStatus.pending => const GrowboxBadge(label: 'Pending', backgroundColor: AppColors.pendingLight, textColor: AppColors.pending, isSmall: true),
      OrderStatus.accepted => const GrowboxBadge(label: 'Accepted', backgroundColor: AppColors.acceptedLight, textColor: AppColors.accepted, isSmall: true),
      OrderStatus.preparing => const GrowboxBadge(label: 'Preparing', backgroundColor: AppColors.preparingLight, textColor: AppColors.preparing, isSmall: true),
      OrderStatus.ready => const GrowboxBadge(label: 'Ready', backgroundColor: AppColors.readyLight, textColor: AppColors.ready, isSmall: true),
      OrderStatus.completed => const GrowboxBadge(label: 'Completed', backgroundColor: AppColors.completedLight, textColor: AppColors.completed, isSmall: true),
      OrderStatus.cancelled => const GrowboxBadge(label: 'Cancelled', backgroundColor: AppColors.cancelledLight, textColor: AppColors.cancelled, isSmall: true),
    };
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
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