import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/notification_item.dart';
import 'notifications_service.dart';

/// Service to generate notifications for pending bills, rejected payments, due dates, and rewards
class NotificationGenerator {
  final _notificationService = NotificationsService();

  /// Generate all notifications by checking:
  /// - Pending bills (unpaid bills)
  /// - Rejected payments
  /// - Due date countdowns (within 3 days)
  /// - New rewards
  Future<void> generateAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_username') ?? '';
      if (username.isEmpty) return;

      await Future.wait([
        _generatePendingBillNotifications(username),
        _generateRejectedPaymentNotifications(username),
        _generateDueDateNotifications(username),
        _generateRewardNotifications(username),
        _generateBillAddedNotifications(username),
      ]);
    } catch (e) {
      // Silently fail - don't interrupt user experience
      print('Error generating notifications: $e');
    }
  }

  /// Generate notifications for pending (unpaid) bills
  Future<void> _generatePendingBillNotifications(String username) async {
    try {
      // Fetch all bills for the user
      final userUtilResp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/user-utility/list/?user_name=${Uri.encodeQueryComponent(username)}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (userUtilResp.statusCode != 200) return;

      final utilJson = jsonDecode(userUtilResp.body) as Map<String, dynamic>;
      final List<dynamic> utilities = (utilJson['results'] as List<dynamic>?) ?? [];

      // Fetch approved payments to know which bills are paid
      final paymentResp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/payments/list/?status=approved'),
        headers: {'Content-Type': 'application/json'},
      );

      Set<String> paidBillIds = {};
      if (paymentResp.statusCode == 200) {
        final paymentJson = jsonDecode(paymentResp.body) as Map<String, dynamic>;
        final List<dynamic> payments = (paymentJson['results'] as List<dynamic>?) ?? [];
        for (final payment in payments) {
          final billId = ((payment as Map<String, dynamic>)['bill_id'] ?? '').toString();
          if (billId.isNotEmpty) paidBillIds.add(billId);
        }
      }

      // Check each utility for unpaid bills
      for (final util in utilities) {
        final utilMap = util as Map<String, dynamic>;
        final consumerId = (utilMap['consumer_id'] ?? '').toString();
        final utilityType = (utilMap['utility_type'] ?? '').toString();

        if (consumerId.isEmpty || utilityType.isEmpty) continue;

        final billResp = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/utility-bill/list/?consumer_id=${Uri.encodeQueryComponent(consumerId)}&utility_type=$utilityType'),
          headers: {'Content-Type': 'application/json'},
        );

        if (billResp.statusCode != 200) continue;

        final billJson = jsonDecode(billResp.body) as Map<String, dynamic>;
        final List<dynamic> bills = (billJson['results'] as List<dynamic>?) ?? [];

        // Find unpaid bills
        for (final bill in bills) {
          final billMap = bill as Map<String, dynamic>;
          final billId = (billMap['bill_id'] ?? '').toString();
          final amount = (billMap['total_amount'] ?? billMap['amount'] ?? 0).toString();

          if (billId.isNotEmpty && !paidBillIds.contains(billId)) {
            // This is a pending (unpaid) bill
            await _notificationService.addOrUpdate(
              NotificationItem(
                id: 'bill_pending_${username}_$billId',
                type: 'bill_pending',
                title: 'Pending bill: $utilityType',
                message: 'Invoice $billId for $utilityType is pending payment • Amount INR $amount',
                timestamp: DateTime.now(),
                username: username,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error generating pending bill notifications: $e');
    }
  }

  /// Generate notifications for rejected payments
  Future<void> _generateRejectedPaymentNotifications(String username) async {
    try {
      // Get user utilities to check if payment belongs to this user
      final userUtilResp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/user-utility/list/?user_name=${Uri.encodeQueryComponent(username)}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (userUtilResp.statusCode != 200) return;

      final utilJson = jsonDecode(userUtilResp.body) as Map<String, dynamic>;
      final List<dynamic> utilities = (utilJson['results'] as List<dynamic>?) ?? [];
      Set<String> userConsumerIds = {};
      for (final util in utilities) {
        final consumerId = ((util as Map<String, dynamic>)['consumer_id'] ?? '').toString();
        if (consumerId.isNotEmpty) userConsumerIds.add(consumerId);
      }

      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/payments/list/?status=rejected'),
        headers: {'Content-Type': 'application/json'},
      );

      if (resp.statusCode != 200) return;

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final List<dynamic> payments = (json['results'] as List<dynamic>?) ?? [];

      for (final payment in payments) {
        final paymentMap = payment as Map<String, dynamic>;
        final billId = (paymentMap['bill_id'] ?? '').toString();
        final amount = (paymentMap['amount'] ?? 0).toString();
        final consumerId = (paymentMap['consumer_id'] ?? '').toString();

        // Only create notification if this bill belongs to current user
        if (billId.isNotEmpty && userConsumerIds.contains(consumerId)) {
          await _notificationService.addOrUpdate(
            NotificationItem(
              id: 'payment_rejected_${username}_$billId',
              type: 'payment_rejected',
              title: 'Payment rejected',
              message: 'Invoice $billId was rejected • Amount INR $amount credited to your wallet',
              timestamp: DateTime.now(),
              username: username,
            ),
          );
        }
      }
    } catch (e) {
      print('Error generating rejected payment notifications: $e');
    }
  }

  /// Generate notifications for bills with upcoming due dates (within 3 days)
  Future<void> _generateDueDateNotifications(String username) async {
    try {
      final userUtilResp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/user-utility/list/?user_name=${Uri.encodeQueryComponent(username)}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (userUtilResp.statusCode != 200) return;

      final utilJson = jsonDecode(userUtilResp.body) as Map<String, dynamic>;
      final List<dynamic> utilities = (utilJson['results'] as List<dynamic>?) ?? [];

      // Fetch approved payments to know which bills are paid
      final paymentResp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/payments/list/?status=approved'),
        headers: {'Content-Type': 'application/json'},
      );

      Set<String> paidBillIds = {};
      if (paymentResp.statusCode == 200) {
        final paymentJson = jsonDecode(paymentResp.body) as Map<String, dynamic>;
        final List<dynamic> payments = (paymentJson['results'] as List<dynamic>?) ?? [];
        for (final payment in payments) {
          final billId = ((payment as Map<String, dynamic>)['bill_id'] ?? '').toString();
          if (billId.isNotEmpty) paidBillIds.add(billId);
        }
      }

      final now = DateTime.now();

      // Check each utility for bills with upcoming due dates
      for (final util in utilities) {
        final utilMap = util as Map<String, dynamic>;
        final consumerId = (utilMap['consumer_id'] ?? '').toString();
        final utilityType = (utilMap['utility_type'] ?? '').toString();

        if (consumerId.isEmpty || utilityType.isEmpty) continue;

        final billResp = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/utility-bill/list/?consumer_id=${Uri.encodeQueryComponent(consumerId)}&utility_type=$utilityType'),
          headers: {'Content-Type': 'application/json'},
        );

        if (billResp.statusCode != 200) continue;

        final billJson = jsonDecode(billResp.body) as Map<String, dynamic>;
        final List<dynamic> bills = (billJson['results'] as List<dynamic>?) ?? [];

        for (final bill in bills) {
          final billMap = bill as Map<String, dynamic>;
          final billId = (billMap['bill_id'] ?? '').toString();
          final dueDateStr = (billMap['due_date'] ?? '').toString();
          final amount = (billMap['total_amount'] ?? billMap['amount'] ?? 0).toString();

          if (billId.isEmpty || paidBillIds.contains(billId)) continue;

          final dueDate = DateTime.tryParse(dueDateStr);
          if (dueDate != null) {
            final daysUntilDue = dueDate.difference(now).inDays;

            // Generate notification if overdue
            if (daysUntilDue < 0) {
              final daysOverdue = -daysUntilDue;
              await _notificationService.addOrUpdate(
                NotificationItem(
                  id: 'bill_overdue_${username}_$billId',
                  type: 'bill_overdue',
                  title: 'Bill is overdue!',
                  message: 'Invoice $billId for $utilityType is $daysOverdue days overdue • Amount INR $amount',
                  timestamp: DateTime.now(),
                  username: username,
                ),
              );
            } 
            // Generate notification if due within 3 days
            else if (daysUntilDue >= 0 && daysUntilDue <= 3) {
              String message;
              if (daysUntilDue == 0) {
                message = 'Invoice $billId for $utilityType is due TODAY • Amount INR $amount';
              } else if (daysUntilDue == 1) {
                message = 'Invoice $billId for $utilityType is due TOMORROW • Amount INR $amount';
              } else {
                message = 'Invoice $billId for $utilityType is due in $daysUntilDue days • Amount INR $amount';
              }

              await _notificationService.addOrUpdate(
                NotificationItem(
                  id: 'bill_due_${username}_$billId',
                  type: 'bill_due',
                  title: 'Bill due soon',
                  message: message,
                  timestamp: DateTime.now(),
                  username: username,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error generating due date notifications: $e');
    }
  }

  /// Generate notifications for new rewards
  Future<void> _generateRewardNotifications(String username) async {
    try {
      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/wallet/transactions/?username=${Uri.encodeQueryComponent(username)}&limit=50'),
        headers: {'Content-Type': 'application/json'},
      );

      if (resp.statusCode != 200) return;

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final List<dynamic> transactions = (json['results'] as List<dynamic>?) ?? [];

      // Find credit transactions with reasons (rewards/refunds)
      for (final tx in transactions) {
        final txMap = tx as Map<String, dynamic>;
        final txType = (txMap['transaction_type'] ?? '').toString();
        final reason = (txMap['reason'] ?? '').toString();
        final amount = (txMap['amount'] ?? 0).toString();
        final txId = (txMap['id'] ?? txMap['transaction_id'] ?? '').toString();

        if (txType == 'credit' && reason.isNotEmpty && txId.isNotEmpty) {
              await _notificationService.addOrUpdate(
            NotificationItem(
              id: 'reward_${username}_$txId',
              type: 'reward_earned',
              title: 'Reward earned!',
              message: 'You received INR $amount • $reason',
              timestamp: DateTime.now(),
              username: username,
            ),
          );
        }
      }
    } catch (e) {
      print('Error generating reward notifications: $e');
    }
  }

  /// Generate notifications for newly added bills
  Future<void> _generateBillAddedNotifications(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seenBillsKey = 'seen_bills_$username';
      final seenBillsRaw = prefs.getString(seenBillsKey) ?? '[]';
      Set<String> seenBills = {};
      try {
        seenBills = (jsonDecode(seenBillsRaw) as List<dynamic>)
            .map((e) => e.toString())
            .toSet();
      } catch (_) {}

      final userUtilResp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/user-utility/list/?user_name=${Uri.encodeQueryComponent(username)}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (userUtilResp.statusCode != 200) return;

      final utilJson = jsonDecode(userUtilResp.body) as Map<String, dynamic>;
      final List<dynamic> utilities = (utilJson['results'] as List<dynamic>?) ?? [];

      Set<String> currentBills = {};

      for (final util in utilities) {
        final utilMap = util as Map<String, dynamic>;
        final consumerId = (utilMap['consumer_id'] ?? '').toString();
        final utilityType = (utilMap['utility_type'] ?? '').toString();

        if (consumerId.isEmpty || utilityType.isEmpty) continue;

        final billResp = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/utility-bill/list/?consumer_id=${Uri.encodeQueryComponent(consumerId)}&utility_type=$utilityType'),
          headers: {'Content-Type': 'application/json'},
        );

        if (billResp.statusCode != 200) continue;

        final billJson = jsonDecode(billResp.body) as Map<String, dynamic>;
        final List<dynamic> bills = (billJson['results'] as List<dynamic>?) ?? [];

        for (final bill in bills) {
          final billMap = bill as Map<String, dynamic>;
          final billId = (billMap['bill_id'] ?? '').toString();
          final amount = (billMap['total_amount'] ?? billMap['amount'] ?? 0).toString();

          if (billId.isNotEmpty) {
            currentBills.add(billId);

            // If this is a new bill (not seen before), create notification
            if (!seenBills.contains(billId)) {
              await _notificationService.addOrUpdate(
                NotificationItem(
                  id: 'bill_added_${username}_$billId',
                  type: 'bill_generated',
                  title: 'New bill added',
                  message: 'New bill $billId for $utilityType has been generated • Amount INR $amount',
                  timestamp: DateTime.now(),
                  username: username,
                ),
              );
            }
          }
        }
      }

      // Update seen bills
      await prefs.setString(seenBillsKey, jsonEncode(currentBills.toList()));
    } catch (e) {
      print('Error generating bill added notifications: $e');
    }
  }
}
