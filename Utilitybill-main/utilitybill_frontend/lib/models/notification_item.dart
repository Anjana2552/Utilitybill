class NotificationItem {
  final String id; // unique key (e.g., type+refId)
  final String type; // bill_generated, payment_initiated, payment_pending, payment_approved, payment_rejected, bill_due, bill_overdue, profile_updated
  final String title;
  final String message;
  final DateTime timestamp;
  final String username; // username this notification belongs to
  final String? utilityType; // utility type (kseb, water, gas, wifi, dth) for utility authority notifications
  final String? billId; // bill ID for bill-related notifications (pay now action)
  bool read;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.username,
    this.utilityType,
    this.billId,
    this.read = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'username': username,
        'utilityType': utilityType,
        'billId': billId,
        'read': read,
      };

  factory NotificationItem.fromJson(Map<String, dynamic> m) {
    return NotificationItem(
      id: (m['id'] ?? '').toString(),
      type: (m['type'] ?? '').toString(),
      title: (m['title'] ?? '').toString(),
      message: (m['message'] ?? '').toString(),
      timestamp: DateTime.tryParse((m['timestamp'] ?? '').toString()) ?? DateTime.now(),
      username: (m['username'] ?? '').toString(),
      utilityType: m['utilityType']?.toString(),
      billId: m['billId']?.toString(),
      read: (m['read'] ?? false) == true,
    );
  }
}
