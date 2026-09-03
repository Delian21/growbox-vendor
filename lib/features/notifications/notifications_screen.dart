import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../data/models/notification.dart';
import '../../data/mock/mock_images.dart';
import '../../app/providers/notifications_provider.dart';
import '../../shared/widgets/growbox_card.dart';
import '../../shared/widgets/growbox_empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  NotificationType? _selectedFilter;

  final List<_FilterTab> _tabs = [
    const _FilterTab(label: 'All', type: null),
    const _FilterTab(label: 'Orders', type: NotificationType.order),
    const _FilterTab(label: 'Payments', type: NotificationType.payment),
    const _FilterTab(label: 'Store', type: NotificationType.store),
    const _FilterTab(label: 'System', type: NotificationType.system),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _selectedFilter = _tabs[_tabController.index].type;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<NotificationsProvider>();
    final filtered = provider.getByType(_selectedFilter);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, provider, isDark),
        const SizedBox(height: AppDimensions.lg),
        _buildStatsRow(provider, isDark),
        const SizedBox(height: AppDimensions.xl),
        _buildFilterTabs(isDark),
        const SizedBox(height: AppDimensions.lg),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState(isDark)
              : _buildNotificationList(filtered, isDark),
        ),
      ],
    );
  }

  // ── HEADER ──
  Widget _buildHeader(BuildContext context, NotificationsProvider provider, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              if (provider.unreadCount > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '${provider.unreadCount} unread',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (provider.unreadCount > 0)
          TextButton.icon(
            onPressed: () => _showMarkAllReadDialog(context, provider),
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Mark all read'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
      ],
    );
  }

  // ── STATS ROW ──
  Widget _buildStatsRow(NotificationsProvider provider, bool isDark) {
    return Row(
      children: [
        _buildStatChip(icon: Icons.notifications_none, label: '${provider.notifications.length} Total', color: AppColors.info, bgColor: AppColors.infoLight),
        const SizedBox(width: AppDimensions.sm),
        _buildStatChip(icon: Icons.mark_email_unread_outlined, label: '${provider.unreadCount} Unread', color: AppColors.primary, bgColor: AppColors.primarySurface),
        const SizedBox(width: AppDimensions.sm),
        _buildStatChip(icon: Icons.mark_email_read_outlined, label: '${provider.notifications.length - provider.unreadCount} Read', color: AppColors.textTertiary, bgColor: AppColors.surfaceVariant),
      ],
    );
  }

  Widget _buildStatChip({required IconData icon, required String label, required Color color, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  // ── FILTER TABS ──
  Widget _buildFilterTabs(bool isDark) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          final isSelected = _selectedFilter == tab.type;
          return GestureDetector(
            onTap: () => _tabController.animateTo(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : (isDark ? AppColors.darkSurface : AppColors.surface),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(
                  color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.border),
                  width: 1,
                ),
              ),
              child: Text(
                tab.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── NOTIFICATION LIST ──
  Widget _buildNotificationList(List<NotificationItem> notifications, bool isDark) {
    final grouped = _groupByDate(notifications);
    final dateKeys = grouped.keys.toList();
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppDimensions.xl),
      itemCount: dateKeys.length,
      itemBuilder: (context, sectionIndex) {
        final date = dateKeys[sectionIndex];
        final items = grouped[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, top: AppDimensions.sm, bottom: AppDimensions.sm),
              child: Text(
                date.toUpperCase(),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary, letterSpacing: 0.5),
              ),
            ),
            ...items.map((n) => Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildNotificationTile(n, isDark))),
          ],
        );
      },
    );
  }

  Widget _buildNotificationTile(NotificationItem notification, bool isDark) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimensions.lg),
        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
      ),
      onDismissed: (_) {
        context.read<NotificationsProvider>().deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Notification deleted'), backgroundColor: AppColors.darkSurface, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        );
      },
      child: GrowboxCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            context.read<NotificationsProvider>().markAsRead(notification.id);
            _showNotificationDetail(notification, isDark);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationIcon(notification),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(fontSize: 14, fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(width: 8, height: 8, margin: const EdgeInsets.only(left: 8), decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, height: 1.4, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(_formatTimeAgo(notification.createdAt), style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary)),
                    ],
                  ),
                ),
                if (notification.priority == NotificationPriority.high)
                  const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.priority_high, size: 18, color: AppColors.error)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationItem notification) {
    final image = _imageForNotification(notification);
    return Container(
      width: 40, height: 40,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(color: _getBgColorForType(notification.type), borderRadius: BorderRadius.circular(10)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(child: Icon(_getIconForType(notification.type), size: 20, color: _getColorForType(notification.type))),
          if (image != null)
            Image.asset(image, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
        ],
      ),
    );
  }

  /// Picks a photo for a notification when its message references one of our
  /// bundled products (e.g. "Organic Maize", "Yam", "Cassava Flour").
  String? _productImageInMessage(String message) {
    final lowerMessage = message.toLowerCase();
    for (final entry in MockImages.products.entries) {
      if (lowerMessage.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return null;
  }

  /// Photos for notifications that reference something visual:
  /// order & store notifications show a relevant photo (falling back to the
  /// store image), and payment / promotion / system notifications also show a
  /// product photo when their message names one (e.g. low-stock alerts).
  /// Notifications with nothing photographic fall back to their type icon.
  String? _imageForNotification(NotificationItem notification) {
    final productImage = _productImageInMessage(notification.message);
    switch (notification.type) {
      case NotificationType.order:
        return productImage ?? MockImages.storeLogo;
      case NotificationType.store:
        return MockImages.storeLogo;
      case NotificationType.payment:
      case NotificationType.promotion:
      case NotificationType.system:
        return productImage;
    }
  }

  // ── EMPTY STATE ──
  Widget _buildEmptyState(bool isDark) {
    return GrowboxEmptyState(
      icon: Icons.notifications_off_outlined,
      title: 'No notifications',
      subtitle: "You're all caught up!",
    );
  }

  // ── DETAIL BOTTOM SHEET ──
  void _showNotificationDetail(NotificationItem notification, bool isDark) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5, minChildSize: 0.3, maxChildSize: 0.85, expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.all(AppDimensions.xl),
          child: ListView(
            controller: scrollController,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(ctx).dividerColor, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: AppDimensions.xl),
              Row(
                children: [
                  _buildNotificationIcon(notification),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(_formatFullDate(notification.createdAt), style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary)),
                      ],
                    ),
                  ),
                  _buildPriorityBadge(notification.priority),
                ],
              ),
              const SizedBox(height: AppDimensions.xl),
              Text(notification.message, style: TextStyle(fontSize: 15, height: 1.6, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
              const SizedBox(height: AppDimensions.xl),
              Row(
                children: [
                  Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _getBgColorForType(notification.type), borderRadius: BorderRadius.circular(AppDimensions.radiusFull)),
                    child: Text(_getTypeLabel(notification.type), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _getColorForType(notification.type))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(AppDimensions.radiusFull)),
          child: const Text('Urgent', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error)),
        );
      case NotificationPriority.medium:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(AppDimensions.radiusFull)),
          child: const Text('Normal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning)),
        );
      case NotificationPriority.low:
        return const SizedBox.shrink();
    }
  }

  // ── MARK ALL READ DIALOG ──
  void _showMarkAllReadDialog(BuildContext context, NotificationsProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark all as read?'),
        content: Text('This will mark all ${provider.unreadCount} unread notifications as read.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () { provider.markAllAsRead(); Navigator.pop(ctx); },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ──
  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.order: return Icons.shopping_bag_outlined;
      case NotificationType.payment: return Icons.payments_outlined;
      case NotificationType.store: return Icons.store_outlined;
      case NotificationType.promotion: return Icons.campaign_outlined;
      case NotificationType.system: return Icons.info_outline;
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.order: return AppColors.primary;
      case NotificationType.payment: return AppColors.success;
      case NotificationType.store: return AppColors.info;
      case NotificationType.promotion: return AppColors.warning;
      case NotificationType.system: return AppColors.textTertiary;
    }
  }

  Color _getBgColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.order: return AppColors.primarySurface;
      case NotificationType.payment: return AppColors.successLight;
      case NotificationType.store: return AppColors.infoLight;
      case NotificationType.promotion: return AppColors.warningLight;
      case NotificationType.system: return AppColors.surfaceVariant;
    }
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.order: return 'Order';
      case NotificationType.payment: return 'Payment';
      case NotificationType.store: return 'Store';
      case NotificationType.promotion: return 'Promotion';
      case NotificationType.system: return 'System';
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }

  String _formatFullDate(DateTime dateTime) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dateTime.hour == 0 ? 12 : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final ampm = dateTime.hour < 12 ? 'AM' : 'PM';
    return '${months[dateTime.month]} ${dateTime.day}, ${dateTime.year} • $hour:$minute $ampm';
  }

  Map<String, List<NotificationItem>> _groupByDate(List<NotificationItem> notifications) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final Map<String, List<NotificationItem>> grouped = {};
    for (final n in notifications) {
      final nDate = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      String key;
      if (nDate == today) {
        key = 'Today';
      } else if (nDate == yesterday) {
        key = 'Yesterday';
      } else {
        const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        key = '${days[n.createdAt.weekday]}, ${months[n.createdAt.month]} ${n.createdAt.day}';
      }
      grouped.putIfAbsent(key, () => []).add(n);
    }
    return grouped;
  }
}

class _FilterTab {
  final String label;
  final NotificationType? type;
  const _FilterTab({required this.label, required this.type});
}