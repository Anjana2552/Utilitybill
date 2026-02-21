import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item.dart';

class NotificationsService {
  static const _storageKey = 'notifications_list_v1';
  static const _lastReminderKeyPrefix = 'notif_last_due_reminder_';

  Future<List<NotificationItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('user_username') ?? '';
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
      final allNotifications = list.map(NotificationItem.fromJson).toList();
      // Filter notifications for current user only
      final userNotifications = allNotifications
          .where((n) => n.username == currentUsername)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return userNotifications;
    } catch (_) {
      return [];
    }
  }

  /// Load notifications for a specific utility type (for utility authorities)
  Future<List<NotificationItem>> loadForUtility(String utilityType) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
      final allNotifications = list.map(NotificationItem.fromJson).toList();
      
      // Count before cleanup
      final beforeCount = allNotifications.length;
      
      // Remove any notifications with null or "null" utilityType (cleanup old broken data)
      allNotifications.removeWhere((n) => 
        n.utilityType == null || 
        n.utilityType == 'null' || 
        n.utilityType!.isEmpty
      );
      
      // Save cleaned notifications back if we removed any
      if (allNotifications.length < beforeCount) {
        final encoded = jsonEncode(allNotifications.map((e) => e.toJson()).toList());
        await prefs.setString(_storageKey, encoded);
      }
      
      // Filter notifications for this utility type
      final utilityNotifications = allNotifications
          .where((n) => n.utilityType == utilityType)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return utilityNotifications;
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<NotificationItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    // Load all existing notifications first
    final raw = prefs.getString(_storageKey);
    List<NotificationItem> allNotifications = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        final existing = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
        allNotifications = existing.map(NotificationItem.fromJson).toList();
      } catch (_) {}
    }
    // Get current username
    final currentUsername = prefs.getString('user_username') ?? '';
    // Remove old notifications for current user
    allNotifications.removeWhere((n) => n.username == currentUsername);
    // Add new notifications for current user
    allNotifications.addAll(list);
    // Save all notifications
    final encoded = jsonEncode(allNotifications.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> addUnique(NotificationItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    List<NotificationItem> allNotifications = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
        allNotifications = list.map(NotificationItem.fromJson).toList();
      } catch (_) {}
    }
    if (!allNotifications.any((n) => n.id == item.id)) {
      allNotifications.add(item);
      final encoded = jsonEncode(allNotifications.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    }
  }

  Future<void> addOrUpdate(NotificationItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    List<NotificationItem> allNotifications = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
        allNotifications = list.map(NotificationItem.fromJson).toList();
      } catch (_) {}
    }
    final index = allNotifications.indexWhere((n) => n.id == item.id);
    if (index == -1) {
      allNotifications.add(item);
    } else {
      final existing = allNotifications[index];
      allNotifications[index] = NotificationItem(
        id: item.id,
        type: item.type,
        title: item.title,
        message: item.message,
        timestamp: item.timestamp,
        username: item.username,
        utilityType: item.utilityType,
        read: existing.read,
      );
    }
    final encoded = jsonEncode(allNotifications.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
      final allNotifications = list.map(NotificationItem.fromJson).toList();
      for (final n in allNotifications) {
        if (n.id == id) {
          n.read = true;
          break;
        }
      }
      final encoded = jsonEncode(allNotifications.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('user_username') ?? '';
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
      final allNotifications = list.map(NotificationItem.fromJson).toList();
      for (final n in allNotifications) {
        // Only mark current user's notifications as read
        if (n.username == currentUsername) {
          n.read = true;
        }
      }
      final encoded = jsonEncode(allNotifications.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }

  Future<int> unreadCount() async {
    final list = await load();
    return list.where((n) => !n.read).length;
  }

  Future<DateTime?> getLastDueReminder(String billId) async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('$_lastReminderKeyPrefix$billId');
    if (s == null) return null;
    return DateTime.tryParse(s);
  }

  Future<void> setLastDueReminder(String billId, DateTime when) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_lastReminderKeyPrefix$billId', when.toIso8601String());
  }
}
