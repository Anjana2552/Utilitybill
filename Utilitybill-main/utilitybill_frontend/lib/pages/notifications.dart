import 'package:flutter/material.dart';
import '../services/notifications_service.dart';
import '../services/notification_generator.dart';
import '../models/notification_item.dart';

class NotificationsPage extends StatefulWidget {
	final String? utilityType; // If provided, load notifications for this utility type
	
	const NotificationsPage({super.key, this.utilityType});

	@override
	State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
	final _service = NotificationsService();
	final _generator = NotificationGenerator();
	List<NotificationItem> _items = [];
	bool _loading = true;

	@override
	void initState() {
		super.initState();
		_load();
	}

	Future<void> _load() async {
		setState(() => _loading = true);
		// Generate all notifications before loading (only for regular users, not utilities)
		if (widget.utilityType == null) {
			await _generator.generateAllNotifications();
		}
		final list = widget.utilityType != null
				? await _service.loadForUtility(widget.utilityType!)
				: await _service.load();
		if (!mounted) return;
		
		// Debug: Print notification details for utility authorities
		if (widget.utilityType != null) {
			print('=== Utility Notifications Debug ===');
			print('Filtering for utilityType: ${widget.utilityType}');
			print('Found ${list.length} notifications');
			for (final n in list) {
				print('  - ${n.title}: utilityType=${n.utilityType}, username=${n.username}');
			}
		}
		
		setState(() {
			_items = list;
			_loading = false;
		});
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Notifications'),
				leading: IconButton(
					icon: const Icon(Icons.arrow_back),
					onPressed: () => Navigator.of(context).pop(),
				),
				backgroundColor: Theme.of(context).colorScheme.primary,
				foregroundColor: Theme.of(context).colorScheme.onPrimary,
			),
			body: _loading
				? const Center(
					child: Padding(
						padding: EdgeInsets.all(24),
						child: CircularProgressIndicator(),
					),
				)
				: (_items.isEmpty
					? const Padding(
						padding: EdgeInsets.all(16.0),
						child: _EmptyNotificationCard(),
					)
					: SingleChildScrollView(
						child: Padding(
							padding: const EdgeInsets.all(16.0),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									// Unread section
									if (_items.any((e) => !e.read)) ...[
										const Text('Unread', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
										const SizedBox(height: 8),
										..._items.where((n) => !n.read).map((n) => _NotificationTile(
											n: n,
											onMarkRead: () async {
												await _service.markAsRead(n.id);
												await _load();
											},
										)),
										const SizedBox(height: 16),
									],
									// Read section
									const Text('Read', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
									const SizedBox(height: 8),
									if (_items.any((e) => e.read))
										..._items.where((n) => n.read).map((n) => _NotificationTile(
												n: n,
												onMarkRead: null,
											)),
									if (!_items.any((e) => e.read))
										Card(
											shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
											child: const ListTile(
												leading: Icon(Icons.mark_email_read),
												title: Text('No read notifications yet'),
												subtitle: Text('Read items will appear here.'),
											),
										),
								],
							),
						),
					)),
		);
	}

}

class _NotificationTile extends StatelessWidget {
  final NotificationItem n;
  final Future<void> Function()? onMarkRead;
  const _NotificationTile({required this.n, required this.onMarkRead});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(n.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
        child: Row(children: [
          Icon(Icons.mark_email_read, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Mark read')
        ]),
      ),
      direction: (onMarkRead != null && !n.read)
          ? DismissDirection.startToEnd
          : DismissDirection.none,
      confirmDismiss: (_) async {
        if (onMarkRead != null) {
          await onMarkRead!();
        }
        return false;
      },
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(_iconForType(n.type), color: Theme.of(context).colorScheme.secondary),
          title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.w400 : FontWeight.w700)),
          subtitle: Text(n.message),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_formatTime(n.timestamp), style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 4),
              if (!n.read)
                Icon(Icons.brightness_1, size: 10, color: Theme.of(context).colorScheme.secondary),
            ],
          ),
          onTap: () async {
            if (!n.read && onMarkRead != null) {
              await onMarkRead!();
            }
          },
        ),
      ),
    );
  }

	IconData _iconForType(String t) {
		switch (t) {
			case 'bill_generated':
				return Icons.receipt_long;
			case 'bill_pending':
				return Icons.pending_actions;
			case 'payment_initiated':
				return Icons.payments_outlined;
			case 'payment_pending':
				return Icons.hourglass_bottom;
			case 'payment_approved':
				return Icons.check_circle_outline;
			case 'payment_rejected':
				return Icons.highlight_off;
			case 'bill_due':
				return Icons.notification_important_outlined;
			case 'bill_overdue':
				return Icons.error_outline;
			case 'reward_earned':
				return Icons.card_giftcard;
			case 'profile_updated':
				return Icons.person_outline;
			default:
				return Icons.notifications_none;
		}
	}

	String _formatTime(DateTime dt) {
		final now = DateTime.now();
		final diff = now.difference(dt);
		if (diff.inMinutes < 1) return 'just now';
		if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
		if (diff.inHours < 24) return '${diff.inHours}h ago';
		return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
	}
}

class _EmptyNotificationCard extends StatelessWidget {
	const _EmptyNotificationCard();

	@override
	Widget build(BuildContext context) {
		return Card(
			elevation: 2,
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
			child: Padding(
				padding: const EdgeInsets.all(16.0),
				child: Row(
					children: [
						Container(
							padding: const EdgeInsets.all(10),
							decoration: BoxDecoration(
								color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
								borderRadius: BorderRadius.circular(10),
							),
							child: Icon(Icons.notifications_none, color: Theme.of(context).colorScheme.primary),
						),
						const SizedBox(width: 12),
						const Expanded(
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(
										'No notifications yet',
										style: TextStyle(
											fontSize: 16,
											fontWeight: FontWeight.w600,
										),
									),
									SizedBox(height: 4),
									Text(
										'You will see updates and alerts here.',
										style: TextStyle(color: Colors.grey),
									),
								],
							),
						),
					],
				),
			),
		);
	}
}

