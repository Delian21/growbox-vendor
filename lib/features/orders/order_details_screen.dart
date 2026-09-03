import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../app/providers/orders_provider.dart';
import '../../shared/widgets/growbox_badge.dart';
import '../../shared/widgets/growbox_button.dart';
import '../../shared/widgets/growbox_card.dart';
import '../../data/models/order.dart';
import '../../data/mock/mock_images.dart';
import '../../core/utils/formatters.dart';
import '../../shared/utils/snackbar_helper.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ordersProvider = context.watch<OrdersProvider>();
    final order = ordersProvider.getOrderById(widget.orderId);

    if (order == null) {
      return _buildNotFound(context, isDark);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isDark, order),
          const SizedBox(height: AppDimensions.xl),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 700) {
                return _buildDesktopLayout(context, isDark, order);
              }
              return _buildMobileLayout(context, isDark, order);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, Order order) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
          onPressed: () => context.go('/orders'),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Order ${order.id}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  _statusBadge(order.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Placed ${_formatDate(order.createdAt)}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isDark, Order order) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Order Items
        Expanded(
          flex: 3,
          child: _buildOrderItemsCard(context, isDark, order),
        ),
        const SizedBox(width: AppDimensions.xl),
        // Right: Customer Info + Status Update
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildCustomerCard(isDark, order),
              const SizedBox(height: AppDimensions.lg),
              _buildStatusUpdateCard(context, isDark, order),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isDark, Order order) {
    return Column(
      children: [
        _buildCustomerCard(isDark, order),
        const SizedBox(height: AppDimensions.lg),
        _buildStatusUpdateCard(context, isDark, order),
        const SizedBox(height: AppDimensions.lg),
        _buildOrderItemsCard(context, isDark, order),
      ],
    );
  }

  Widget _buildOrderItemsCard(BuildContext context, bool isDark, Order order) {
    return GrowboxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          ...order.items.map((item) => _buildOrderItem(isDark, item)),
          const Divider(height: AppDimensions.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total (${order.totalItems} items)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              Text(
                formatCurrency(order.totalAmount),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(bool isDark, OrderItem item) {
    final itemImage = MockImages.forProduct(item.productName);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.md),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: AppColors.primarySurface,
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  if (itemImage != null)
                    Image.asset(
                      itemImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.quantity} x \u20A6${item.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\u20A6${item.total.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(bool isDark, Order order) {
    return GrowboxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          _buildInfoRow(
            icon: Icons.person_outline,
            label: 'Name',
            value: order.customerName,
            isDark: isDark,
          ),
          const SizedBox(height: AppDimensions.md),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: order.customerPhone,
            isDark: isDark,
          ),
          if (order.notes != null) ...[
            const SizedBox(height: AppDimensions.md),
            _buildInfoRow(
              icon: Icons.notes_outlined,
              label: 'Notes',
              value: order.notes!,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusUpdateCard(BuildContext context, bool isDark, Order order) {
    return GrowboxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          _buildStatusTimeline(isDark, order),
          const SizedBox(height: AppDimensions.lg),
          _buildActionButtons(context, isDark, order),
        ],
      ),
    );
  }

  // ── Contextual action buttons based on current status ──
  Widget _buildActionButtons(BuildContext context, bool isDark, Order order) {
    switch (order.status) {
      case OrderStatus.pending:
        return Row(
          children: [
            Expanded(
              child: GrowboxButton(
                label: 'Accept Order',
                onPressed: () => _acceptOrder(context, order),
                isExpanded: true,
                icon: Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: GrowboxButton(
                label: 'Reject',
                onPressed: () => _rejectOrder(context, order),
                isExpanded: true,
                variant: GrowboxButtonVariant.danger,
                icon: Icons.cancel_outlined,
              ),
            ),
          ],
        );

      case OrderStatus.accepted:
        return Column(
          children: [
            GrowboxButton(
              label: 'Start Preparing',
              onPressed: () => _advanceStatus(context, order, OrderStatus.preparing),
              isExpanded: true,
              icon: Icons.kitchen,
            ),
            const SizedBox(height: AppDimensions.md),
            _buildCancelButton(context, order),
          ],
        );

      case OrderStatus.preparing:
        return Column(
          children: [
            GrowboxButton(
              label: 'Mark as Ready',
              onPressed: () => _advanceStatus(context, order, OrderStatus.ready),
              isExpanded: true,
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(height: AppDimensions.md),
            _buildCancelButton(context, order),
          ],
        );

      case OrderStatus.ready:
        return Column(
          children: [
            GrowboxButton(
              label: 'Mark as Completed',
              onPressed: () => _advanceStatus(context, order, OrderStatus.completed),
              isExpanded: true,
              icon: Icons.done_all,
            ),
            const SizedBox(height: AppDimensions.md),
            _buildCancelButton(context, order),
          ],
        );

      case OrderStatus.completed:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.lg),
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 20),
              const SizedBox(width: AppDimensions.sm),
              Text(
                'This order has been completed',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        );

      case OrderStatus.cancelled:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.lg),
          decoration: BoxDecoration(
            color: AppColors.cancelledLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cancel, color: AppColors.cancelled, size: 20),
              const SizedBox(width: AppDimensions.sm),
              Text(
                'This order has been cancelled',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cancelled,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildStatusTimeline(bool isDark, Order order) {
    final steps = [
      OrderStatus.pending,
      OrderStatus.accepted,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.completed,
    ];

    final currentIndex = steps.indexOf(order.status);

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;

        return Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.border),
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Text(
                step.name[0].toUpperCase() + step.name.substring(1),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  color: isCompleted
                      ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                      : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }



  Widget _statusBadge(OrderStatus status) {
    return switch (status) {
      OrderStatus.pending => const GrowboxBadge(
          label: 'Pending',
          backgroundColor: AppColors.pendingLight,
          textColor: AppColors.pending,
          isSmall: true,
        ),
      OrderStatus.accepted => const GrowboxBadge(
          label: 'Accepted',
          backgroundColor: AppColors.acceptedLight,
          textColor: AppColors.accepted,
          isSmall: true,
        ),
      OrderStatus.preparing => const GrowboxBadge(
          label: 'Preparing',
          backgroundColor: AppColors.preparingLight,
          textColor: AppColors.preparing,
          isSmall: true,
        ),
      OrderStatus.ready => const GrowboxBadge(
          label: 'Ready',
          backgroundColor: AppColors.readyLight,
          textColor: AppColors.ready,
          isSmall: true,
        ),
      OrderStatus.completed => const GrowboxBadge(
          label: 'Completed',
          backgroundColor: AppColors.completedLight,
          textColor: AppColors.completed,
          isSmall: true,
        ),
      OrderStatus.cancelled => const GrowboxBadge(
          label: 'Cancelled',
          backgroundColor: AppColors.cancelledLight,
          textColor: AppColors.cancelled,
          isSmall: true,
        ),
    };
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _acceptOrder(BuildContext context, Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Order'),
        content: Text(
          'Accept order ${order.id} from ${order.customerName}?\n\nThis will notify the customer that their order has been accepted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await context.read<OrdersProvider>().updateOrderStatus(
            order.id,
            OrderStatus.accepted,
          );
      if (success && context.mounted) {
        SnackbarHelper.showSuccess(context, 'Order ${order.id} accepted');
      }
    }
  }

  Future<void> _rejectOrder(BuildContext context, Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: Text(
          'Are you sure you want to reject order ${order.id} from ${order.customerName}?\n\nThis action cannot be undone and the customer will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Order'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Reject Order',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await context.read<OrdersProvider>().updateOrderStatus(
            order.id,
            OrderStatus.cancelled,
          );
      if (success && context.mounted) {
        SnackbarHelper.showSuccess(context, 'Order ${order.id} rejected');
      }
    }
  }

  Future<void> _advanceStatus(BuildContext context, Order order, OrderStatus nextStatus) async {
    final label = switch (nextStatus) {
      OrderStatus.preparing => 'Start Preparing',
      OrderStatus.ready => 'Mark as Ready',
      OrderStatus.completed => 'Mark as Completed',
      _ => 'Update',
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: Text(
          '$label for order ${order.id}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(label),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await context.read<OrdersProvider>().updateOrderStatus(
            order.id,
            nextStatus,
          );
      if (success && context.mounted) {
        SnackbarHelper.showSuccess(context, 'Order ${order.id} → ${nextStatus.name}');
      }
    }
  }

  // ── Cancel order (available for non-terminal statuses) ──
  Widget _buildCancelButton(BuildContext context, Order order) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _cancelOrder(context, order),
        icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.error),
        label: const Text(
          'Cancel Order',
          style: TextStyle(color: AppColors.error),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
        ),
      ),
    );
  }

  Future<void> _cancelOrder(BuildContext context, Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Text(
          'Are you sure you want to cancel order ${order.id} from ${order.customerName}?\n\nThis order is currently ${order.status.name}. The customer will be notified and a refund may be triggered.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Order'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cancel Order',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await context.read<OrdersProvider>().updateOrderStatus(
            order.id,
            OrderStatus.cancelled,
          );
      if (success && context.mounted) {
        SnackbarHelper.showSuccess(context, 'Order ${order.id} has been cancelled');
      }
    }
  }

  Widget _buildNotFound(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
          const SizedBox(height: AppDimensions.lg),
          Text(
            'Order not found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          GrowboxButton(
            label: 'Back to Orders',
            onPressed: () => context.go('/orders'),
          ),
        ],
      ),
    );
  }
}
