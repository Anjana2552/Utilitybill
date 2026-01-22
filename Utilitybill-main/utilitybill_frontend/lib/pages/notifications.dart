import 'package:flutter/material.dart';
import '../widgets/theme_header.dart';

class NotificationsPage extends StatelessWidget {
	const NotificationsPage({super.key});

	@override
	Widget build(BuildContext context) {
		return CurvedHeaderPage(
			title: 'Notifications',
			headerHeight: 200,
			titleAlignment: HeaderTitleAlignment.left,
			leading: IconButton(
				icon: const Icon(Icons.arrow_back, color: Colors.white),
				onPressed: () => Navigator.of(context).pop(),
			),
			child: Padding(
				padding: const EdgeInsets.all(16.0),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						const SizedBox(height: 8),
						const Text(
							'Recent',
							style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
						),
						const SizedBox(height: 12),
						// Use a non-scrollable, shrink-wrapped list inside CurvedHeaderPage
						// to avoid nested scroll/size issues.
						ListView(
							shrinkWrap: true,
							physics: const NeverScrollableScrollPhysics(),
							children: const [
								_EmptyNotificationCard(),
							],
						),
					],
				),
			),
		);
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
								color: const Color(0xFF34B3A0).withOpacity(0.12),
								borderRadius: BorderRadius.circular(10),
							),
							child: const Icon(Icons.notifications_none, color: Color(0xFF34B3A0)),
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

