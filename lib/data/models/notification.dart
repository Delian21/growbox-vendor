enum NotificationType {
  order,
  payment,
  store,
  promotion,
  system,
}

enum NotificationPriority {
  low,
  medium,
  high,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.medium,
    this.isRead = false,
    required this.createdAt,
  });

  NotificationItem copyWith({
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
