import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/notification_item.dart';

class NotificationsService {
  Future<List<NotificationItem>> loadFromBackend(String username) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/notifications-by-username/?username=${Uri.encodeQueryComponent(username)}',
      );
      final resp = await http.get(uri, headers: {'Content-Type': 'application/json'});

      if (resp.statusCode != 200) {
        return [];
      }

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final List<dynamic> notificationsData = (json['notifications'] as List<dynamic>?) ?? [];

      final notifications = <NotificationItem>[];
      for (final notifData in notificationsData) {
        final notifMap = notifData as Map<String, dynamic>;
        notifications.add(
          NotificationItem(
            id: (notifMap['id'] ?? '').toString(),
            type: (notifMap['notification_type'] ?? '').toString(),
            title: (notifMap['title'] ?? '').toString(),
            message: (notifMap['message'] ?? '').toString(),
            timestamp:
                DateTime.tryParse((notifMap['created_at'] ?? '').toString()) ?? DateTime.now(),
            username: username,
            utilityType: notifMap['utility_type']?.toString(),
            billId: notifMap['bill_id']?.toString(),
            read: (notifMap['read'] ?? false) == true,
          ),
        );
      }

      return notifications;
    } catch (_) {
      return [];
    }
  }

  Future<bool> markAsReadOnBackend(String notificationId, String username) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/notifications/mark-read/');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': int.tryParse(notificationId) ?? notificationId,
          'username': username,
        }),
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<int> unreadCount(String username) async {
    final list = await loadFromBackend(username);
    return list.where((n) => !n.read).length;
  }
}
