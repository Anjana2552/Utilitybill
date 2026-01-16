import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/theme_header.dart';
import 'admin_Authorities.dart';
import 'admin_servicepage.dart';
import 'admin_profile.dart';
import 'add_authority_form.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminHomePage(),
    const AdminAuthoritiesPage(),
    const AdminServicesPage(),
    const AdminProfilePage(),
  ];

  void _onMenuItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If not on Home tab, go back to Home instead of leaving
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return false; // prevent popping the route
        }
        return true; // allow default back behavior from Home
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _pages[_selectedIndex],
        ),
        drawer: Drawer(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF7FD9CE),
                  Color(0xFF4B9A8F),
                ],
              ),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          size: 50,
                          color: Color(0xFF4B9A8F),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Admin Panel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.home, color: Colors.white),
                  title: const Text(
                    'Home',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  selected: _selectedIndex == 0,
                  onTap: () => _onMenuItemSelected(0),
                ),
                ListTile(
                  leading:
                      const Icon(Icons.account_balance, color: Colors.white),
                  title: const Text(
                    'Authorities',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  selected: _selectedIndex == 1,
                  onTap: () => _onMenuItemSelected(1),
                ),
                ListTile(
                  leading: const Icon(Icons.miscellaneous_services,
                      color: Colors.white),
                  title: const Text(
                    'Services',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  selected: _selectedIndex == 2,
                  onTap: () => _onMenuItemSelected(2),
                ),
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.white),
                  title: const Text(
                    'Profile',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  selected: _selectedIndex == 3,
                  onTap: () => _onMenuItemSelected(3),
                ),
                const Divider(color: Colors.white30, height: 32, thickness: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white70),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _handleLogout();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

// Home Page
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                BlueGreenHeader(height: 260, title: 'Welcome, Admin'),
                Expanded(
                  child: Center(
                    child: Text(
                      'Admin Home',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            // Left-top menu icon to open drawer
            Positioned(
              top: 16,
              left: 16,
              child: Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(
                    Icons.menu,
                    color: Colors.white,
                    size: 26,
                  ),
                  onPressed: () {
                    Scaffold.of(ctx).openDrawer();
                  },
                ),
              ),
            ),
            // Right-top plus icon
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddAuthorityForm(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
