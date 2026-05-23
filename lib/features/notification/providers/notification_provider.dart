import 'package:flutter/foundation.dart';
import '../../../core/services/api_client.dart';

class NotificationProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh) _notifications = [];
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiClient.instance.get('/notifications');
      final data = res.data['data'];
      _notifications = List<Map<String, dynamic>>.from(data['notifications'] ?? []);
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadUnreadCount() async {
    try {
      final res = await ApiClient.instance.get('/notifications/unread-count');
      _unreadCount = (res.data['data']['count'] as num?)?.toInt() ?? 0;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    try {
      await ApiClient.instance.patch('/notifications/$id/read');
      final idx = _notifications.indexWhere((n) => n['id'] == id);
      if (idx != -1 && _notifications[idx]['isRead'] == false) {
        _notifications[idx] = {..._notifications[idx], 'isRead': true};
        _unreadCount = (_unreadCount - 1).clamp(0, 9999);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await ApiClient.instance.patch('/notifications/read-all');
      _notifications = _notifications.map((n) => {...n, 'isRead': true}).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }
}
