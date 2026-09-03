import 'package:flutter/material.dart';
import '../../data/models/notification.dart';
import '../../data/mock/mock_notifications.dart';

class NotificationsProvider extends ChangeNotifier {
  List<NotificationItem> _notifications = List.from(mockNotifications);

  List<NotificationItem> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  List<NotificationItem> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  List<NotificationItem> get readNotifications =>
      _notifications.where((n) => n.isRead).toList();

  /// Get notifications filtered by type. Pass null to get all.
  List<NotificationItem> getByType(NotificationType? type) {
    if (type == null) return _notifications;
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Mark a single notification as read
  void markAsRead(String id) {
    _notifications = _notifications.map((n) {
      if (n.id == id) return n.copyWith(isRead: true);
      return n;
    }).toList();
    notifyListeners();
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
  }

  /// Delete a single notification
  void deleteNotification(String id) {
    _notifications = _notifications.where((n) => n.id != id).toList();
    notifyListeners();
  }

  /// Clear all notifications
  void clearAll() {
    _notifications = [];
    notifyListeners();
  }
}
