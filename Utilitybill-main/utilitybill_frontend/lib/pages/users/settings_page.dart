import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../widgets/theme_header.dart';
import 'privacy_center_page.dart';
import 'terms_disclaimer_page.dart';
import 'about_us_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushNotifications = true;
  bool _billReminders = true;
  bool _paymentAlerts = true;
  String _appVersion = '1.0.0';
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('user_username') ?? '';
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _billReminders = prefs.getBool('bill_reminders') ?? true;
      _paymentAlerts = prefs.getBool('payment_alerts') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications', _pushNotifications);
    await prefs.setBool('bill_reminders', _billReminders);
    await prefs.setBool('payment_alerts', _paymentAlerts);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_clock),
                  ),
                  validator: (value) {
                    if (value != newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await _changePassword(
                  oldPasswordController.text,
                  newPasswordController.text,
                );
                if (mounted) Navigator.of(context).pop();
              }
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(String oldPassword, String newPassword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/change-password/');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error['error'] ?? 'Failed to change password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: scheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Stack(
              children: [
                BlueGreenHeader(
                  height: 140,
                  overlay: null,
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: scheme.onPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
            
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Account Section
                  _buildSectionHeader('Account', Icons.person_outline),
                  const SizedBox(height: 8),
                  _buildSettingCard(
                    icon: Icons.person,
                    title: 'Username',
                    subtitle: _username,
                    onTap: null, // Username is not editable
                  ),
                  _buildSettingCard(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    subtitle: 'Update your password',
                    onTap: _showChangePasswordDialog,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Notifications Section
                  _buildSectionHeader('Notifications', Icons.notifications_outlined),
                  const SizedBox(height: 8),
                  _buildSwitchCard(
                    icon: Icons.notifications_active_outlined,
                    title: 'Push Notifications',
                    subtitle: 'Receive push notifications',
                    value: _pushNotifications,
                    onChanged: (value) {
                      setState(() => _pushNotifications = value);
                      _saveSettings();
                    },
                  ),
                  _buildSwitchCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'Bill Reminders',
                    subtitle: 'Get reminders for upcoming bills',
                    value: _billReminders,
                    onChanged: (value) {
                      setState(() => _billReminders = value);
                      _saveSettings();
                    },
                  ),
                  _buildSwitchCard(
                    icon: Icons.payment_outlined,
                    title: 'Payment Alerts',
                    subtitle: 'Get alerts for payment confirmations',
                    value: _paymentAlerts,
                    onChanged: (value) {
                      setState(() => _paymentAlerts = value);
                      _saveSettings();
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Privacy & Security Section
                  _buildSectionHeader('Privacy & Security', Icons.security_outlined),
                  const SizedBox(height: 8),
                  _buildSettingCard(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Center',
                    subtitle: 'Manage your privacy settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyCenterPage(),
                        ),
                      );
                    },
                  ),
                  _buildSettingCard(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    subtitle: 'View terms of service',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermsDisclaimerPage(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // App Settings Section
                  _buildSectionHeader('App Settings', Icons.settings_applications_outlined),
                  const SizedBox(height: 8),
                  _buildSettingCard(
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: 'App information and credits',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutUsPage(),
                        ),
                      );
                    },
                  ),
                  _buildSettingCard(
                    icon: Icons.app_settings_alt_outlined,
                    title: 'App Version',
                    subtitle: _appVersion,
                    onTap: null,
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue.shade700),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: onTap != null
            ? Icon(Icons.chevron_right, color: Colors.grey.shade400)
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue.shade700),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
