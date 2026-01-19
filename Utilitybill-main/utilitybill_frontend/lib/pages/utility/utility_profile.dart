import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/theme_header.dart';

class UtilityProfilePage extends StatefulWidget {
  const UtilityProfilePage({super.key});

  @override
  State<UtilityProfilePage> createState() => _UtilityProfilePageState();
}

class _UtilityProfilePageState extends State<UtilityProfilePage> {
  String _fullName = 'User';
  String _email = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullName = prefs.getString('full_name') ?? 'User';
      _email = prefs.getString('user_email') ?? '';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return CurvedHeaderPage(
      title: 'Profile',
      headerHeight: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF7FD9CE),
                    child: Text(
                      _fullName.isNotEmpty ? _fullName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(_email, style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Account Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Column(
              children: [
                ListTile(leading: Icon(Icons.lock_outline), title: Text('Change Password')),
                Divider(height: 1),
                ListTile(leading: Icon(Icons.notifications_none), title: Text('Notifications')),
                Divider(height: 1),
                ListTile(leading: Icon(Icons.privacy_tip_outlined), title: Text('Privacy')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
