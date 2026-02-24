import 'package:flutter/material.dart';
import '../services/notifications_service.dart';
import '../models/notification_item.dart';
import 'users/bill_payment.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsPage extends StatefulWidget {
	final String? utilityType; // If provided, load notifications for this utility type
	
	const NotificationsPage({super.key, this.utilityType});

	@override
	State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
	final _service = NotificationsService();
	List<NotificationItem> _items = [];
	bool _loading = true;
	String _filter = 'all'; // 'all', 'authority', 'system'

	@override
	void initState() {
		super.initState();
		_load();
	}

	Future<void> _load() async {
		setState(() => _loading = true);
		// Get current username
		final prefs = await SharedPreferences.getInstance();
		final username = prefs.getString('user_username') ?? '';
		
		if (username.isEmpty) {
			setState(() {
				_items = [];
				_loading = false;
			});
			return;
		}
		
		final list = await _service.loadFromBackend(username);
		if (!mounted) return;
		final utilityType = widget.utilityType;
		final filtered = (utilityType == null || utilityType.isEmpty)
				? list
				: list.where((n) => (n.utilityType ?? '').toLowerCase() == utilityType.toLowerCase()).toList();
		setState(() {
			_items = filtered;
			_loading = false;
		});
	}

	@override
	Widget build(BuildContext context) {
		// Apply filter
		List<NotificationItem> filteredItems = _items;
		if (_filter == 'authority') {
			filteredItems = _items.where((n) => _isAuthorityAlertStatic(n.type)).toList();
		} else if (_filter == 'system') {
			filteredItems = _items.where((n) => !_isAuthorityAlertStatic(n.type)).toList();
		}

		return Scaffold(
			appBar: AppBar(
				title: const Text('Notifications'),
				leading: IconButton(
					icon: const Icon(Icons.arrow_back),
					onPressed: () => Navigator.of(context).pop(),
				),
				actions: [
					IconButton(
						icon: const Icon(Icons.refresh),
						onPressed: _load,
						tooltip: 'Refresh',
					),
				],
				backgroundColor: Theme.of(context).colorScheme.primary,
				foregroundColor: Theme.of(context).colorScheme.onPrimary,
				bottom: PreferredSize(
					preferredSize: const Size.fromHeight(60),
					child: Container(
						color: Colors.white,
						padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
						child: Row(
							children: [
								_FilterChip(
									label: 'All',
									isSelected: _filter == 'all',
									onTap: () => setState(() => _filter = 'all'),
									icon: Icons.all_inbox,
								),
								const SizedBox(width: 8),
								_FilterChip(
									label: 'Authority Alerts',
									isSelected: _filter == 'authority',
									onTap: () => setState(() => _filter = 'authority'),
									icon: Icons.campaign,
								),
								const SizedBox(width: 8),
								_FilterChip(
									label: 'System',
									isSelected: _filter == 'system',
									onTap: () => setState(() => _filter = 'system'),
									icon: Icons.notifications,
								),
							],
						),
					),
				),
			),
			body: _loading
				? const Center(
					child: Padding(
						padding: EdgeInsets.all(24),
						child: CircularProgressIndicator(),
					),
				)
				: RefreshIndicator(
					onRefresh: _load,
					child: filteredItems.isEmpty
						? ListView(
							padding: const EdgeInsets.all(16.0),
							children: [_EmptyNotificationCard(filter: _filter)],
						)
						: ListView(
							padding: const EdgeInsets.all(16.0),
							children: [
									// Unread section
									if (filteredItems.any((e) => !e.read)) ...[
										const Text('Unread', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
										const SizedBox(height: 8),
										...filteredItems.where((n) => !n.read).map((n) => _NotificationTile(
											n: n,
											onMarkRead: () async {
												final prefs = await SharedPreferences.getInstance();
												final username = prefs.getString('user_username') ?? '';
												// Mark as read on backend
												await _service.markAsReadOnBackend(n.id, username);
												await _load();
											},
										)),
										const SizedBox(height: 16),
									],
									// Read section
									const Text('Read', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
									const SizedBox(height: 8),
									if (filteredItems.any((e) => e.read))
										...filteredItems.where((n) => n.read).map((n) => _NotificationTile(
												n: n,
												onMarkRead: null,
											)),
									if (!filteredItems.any((e) => e.read))
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
		);
	}

	static bool _isAuthorityAlertStatic(String type) {
		return type == 'alert' || type == 'urgent_alert';
	}

}

class _FilterChip extends StatelessWidget {
	final String label;
	final bool isSelected;
	final VoidCallback onTap;
	final IconData icon;

	const _FilterChip({
		required this.label,
		required this.isSelected,
		required this.onTap,
		required this.icon,
	});

	@override
	Widget build(BuildContext context) {
		return InkWell(
			onTap: onTap,
			borderRadius: BorderRadius.circular(20),
			child: Container(
				padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
				decoration: BoxDecoration(
					color: isSelected 
						? Theme.of(context).colorScheme.primary
						: Colors.grey.shade200,
					borderRadius: BorderRadius.circular(20),
				),
				child: Row(
					mainAxisSize: MainAxisSize.min,
					children: [
						Icon(
							icon,
							size: 16,
							color: isSelected ? Colors.white : Colors.grey.shade700,
						),
						const SizedBox(width: 4),
						Text(
							label,
							style: TextStyle(
								fontSize: 12,
								fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
								color: isSelected ? Colors.white : Colors.grey.shade700,
							),
						),
					],
				),
			),
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
        elevation: _isAuthorityAlert(n.type) ? 3 : 1,
        color: _isAuthorityAlert(n.type) 
            ? (n.type == 'urgent_alert' ? Colors.red.shade50 : Colors.blue.shade50)
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: _isAuthorityAlert(n.type)
              ? BorderSide(
                  color: n.type == 'urgent_alert' ? Colors.red.shade300 : Colors.blue.shade300,
                  width: 2,
                )
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Special header for authority alerts
              if (_isAuthorityAlert(n.type)) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: n.type == 'urgent_alert' ? Colors.red.shade700 : Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        n.type == 'urgent_alert' ? Icons.warning : Icons.campaign,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        n.type == 'urgent_alert' ? 'URGENT ALERT' : 'ANNOUNCEMENT',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Authority message display - clean and prominent
                Text(
                  n.title.replaceAll('URGENT: ', '').replaceAll('IMPORTANT: ', '').replaceAll('INFO: ', ''),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: n.type == 'urgent_alert' ? Colors.red.shade900 : Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    n.message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(n.timestamp),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    const Spacer(),
                    if (!n.read)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ] else ...[
                // Standard notification display for system messages
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_iconForType(n.type), color: Theme.of(context).colorScheme.secondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.w400 : FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(n.message, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                          const SizedBox(height: 6),
                          Text(_formatTime(n.timestamp), style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!n.read)
                      Icon(Icons.brightness_1, size: 10, color: Theme.of(context).colorScheme.secondary),
                  ],
                ),
              ],
              // Show "Pay Now" button for overdue bills
              if (n.type == 'bill_overdue' && n.billId != null && n.billId!.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BillPaymentPage()),
                      );
                      // Mark as read when user taps Pay Now
                      if (!n.read && onMarkRead != null) {
                        onMarkRead!();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _isAuthorityAlert(String type) {
    return type == 'alert' || type == 'urgent_alert';
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
			case 'alert':
				return Icons.campaign;
			case 'urgent_alert':
				return Icons.warning;
			case 'budget_exceeded':
				return Icons.money_off;
			case 'budget_nearing':
				return Icons.warning_amber;
			case 'budget_within':
				return Icons.check_circle;
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
	final String filter;
	const _EmptyNotificationCard({required this.filter});

	@override
	Widget build(BuildContext context) {
		String title;
		String subtitle;
		
		if (filter == 'authority') {
			title = 'No authority alerts';
			subtitle = 'Announcements from utility authorities will appear here.';
		} else if (filter == 'system') {
			title = 'No system notifications';
			subtitle = 'Bill updates and payment notifications will appear here.';
		} else {
			title = 'No notifications yet';
			subtitle = 'You will see updates and alerts here.';
		}

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
						Expanded(
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(
										title,
										style: const TextStyle(
											fontSize: 16,
											fontWeight: FontWeight.w600,
										),
									),
									const SizedBox(height: 4),
									Text(
										subtitle,
										style: const TextStyle(color: Colors.grey),
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

