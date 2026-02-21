import 'package:flutter/material.dart';
import '../../widgets/theme_header.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Admin Profile'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BlueGreenHeader(height: 200, title: 'Profile'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Admin Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 40),
                    Expanded(
                      child: ListView(
                        children: [
                          ListTile(
                            leading: Icon(Icons.person),
                            title: Text('Personal Information'),
                            trailing: Icon(Icons.chevron_right),
                          ),
                          Divider(),
                          ListTile(
                            leading: Icon(Icons.settings),
                            title: Text('Settings'),
                            trailing: Icon(Icons.chevron_right),
                          ),
                          Divider(),
                          ListTile(
                            leading: Icon(Icons.logout),
                            title: Text('Logout'),
                            trailing: Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
