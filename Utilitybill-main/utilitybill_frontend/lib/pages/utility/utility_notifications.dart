import 'package:flutter/material.dart';
import '../../widgets/theme_header.dart';

class UtilityNotificationsPage extends StatefulWidget {
  const UtilityNotificationsPage({super.key});

  @override
  State<UtilityNotificationsPage> createState() => _UtilityNotificationsPageState();
}

class _UtilityNotificationsPageState extends State<UtilityNotificationsPage> {
  late Map<String, bool> _notificationSettings;

  @override
  void initState() {
    super.initState();
    _notificationSettings = {
      'Alert Broadcasts': true,
      'System Updates': true,
      'User Inquiries': true,
      'Payment Confirmations': true,
      'Email Notifications': true,
    };
  }

  @override
  Widget build(BuildContext context) {
    return CurvedHeaderPage(
      title: 'Notification Settings',
      headerHeight: 140,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Back',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manage your notification preferences',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: _notificationSettings.entries.indexed.map((indexed) {
                final (index, entry) = indexed;
                final (key, value) = (entry.key, entry.value);
                
                return Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        _getNotificationIcon(key),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(key),
                      trailing: Switch.adaptive(
                        value: value,
                        onChanged: (newValue) {
                          setState(() {
                            _notificationSettings[key] = newValue;
                          });
                        },
                      ),
                    ),
                    if (index < _notificationSettings.length - 1)
                      const Divider(height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification settings saved'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String title) {
    switch (title) {
      case 'Alert Broadcasts':
        return Icons.campaign;
      case 'System Updates':
        return Icons.update;
      case 'User Inquiries':
        return Icons.mail_outline;
      case 'Payment Confirmations':
        return Icons.check_circle_outline;
      case 'Email Notifications':
        return Icons.email;
      default:
        return Icons.notifications;
    }
  }
}
