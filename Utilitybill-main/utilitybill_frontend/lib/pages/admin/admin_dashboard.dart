import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';
import '../../widgets/theme_header.dart';
import 'admin_Authorities.dart';
import 'admin_profile.dart';
import 'add_authority_form.dart';
import 'admin_users_page.dart';
import '../bills_page.dart';
import '../payment_reports_page.dart';
import 'admin_payment_request_page.dart';

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
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvoked: (didPop) {
        if (!didPop && _selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        }
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
                colors: [Color(0xFF7FD9CE), Color(0xFF4B9A8F)],
              ),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: Colors.transparent),
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
                  leading: const Icon(Icons.group, color: Colors.white),
                  title: const Text(
                    'Users',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminUsersListPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.account_balance,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Authorities',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  selected: _selectedIndex == 1,
                  onTap: () => _onMenuItemSelected(1),
                ),
                ListTile(
                  leading: const Icon(Icons.receipt_long, color: Colors.white),
                  title: const Text(
                    'View Bills',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminBillsListPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.payments_outlined,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Payment Reports',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminPaymentReportsPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.pending_actions,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Payment Request',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminPaymentRequestPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.white),
                  title: const Text(
                    'Profile',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  selected: _selectedIndex == 2,
                  onTap: () => _onMenuItemSelected(2),
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
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _usersCount = 0;
  int _authoritiesCount = 0;
  int _totalBillsCount = 0;
  int _totalPaymentsCount = 0;
  bool _loadingCounts = true;

  @override
  void initState() {
    super.initState();
    _fetchCounts();
  }

  Future<void> _fetchCounts() async {
    setState(() => _loadingCounts = true);
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/profiles/');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final sessionId = prefs.getString('sessionid');
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Token $token';
      } else if (sessionId != null && sessionId.isNotEmpty) {
        headers['Cookie'] = 'sessionid=$sessionId';
      }
      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        int users = 0;
        int utilities = 0;
        if (data is List) {
          for (final item in data) {
            final role = (item['role'] ?? '').toString().toLowerCase();
            if (role == 'user') users++;
            if (role == 'utility') utilities++;
          }
        }
        if (!mounted) return;
        setState(() {
          _usersCount = users;
          _authoritiesCount = utilities;
          _loadingCounts = false;
        });
      } else {
        if (mounted) setState(() => _loadingCounts = false);
      }

      // Fetch total utility bills count (includes authority-added bills)
      try {
        final billsUri = Uri.parse('${ApiConfig.baseUrl}/utility-bill/list/');
        final billsResp = await http.get(
          billsUri,
          headers: {'Content-Type': 'application/json'},
        );
        if (billsResp.statusCode == 200) {
          final obj = jsonDecode(billsResp.body) as Map<String, dynamic>;
          final List<dynamic> results =
              (obj['results'] as List<dynamic>?) ?? const [];
          if (mounted) setState(() => _totalBillsCount = results.length);
        }
      } catch (_) {}

      // Fetch total payments count (using utility_bill entries as payment records)
      try {
        final payUri = Uri.parse('${ApiConfig.baseUrl}/utility-bill/list/');
        final payResp = await http.get(
          payUri,
          headers: {'Content-Type': 'application/json'},
        );
        if (payResp.statusCode == 200) {
          final obj = jsonDecode(payResp.body) as Map<String, dynamic>;
          final List<dynamic> results =
              (obj['results'] as List<dynamic>?) ?? const [];
          if (mounted) setState(() => _totalPaymentsCount = results.length);
        }
      } catch (_) {}
      // Fetch total payments count (only actual recorded payments)
      try {
        final payUri = Uri.parse('${ApiConfig.baseUrl}/payments/list/');
        final payResp = await http.get(
          payUri,
          headers: {'Content-Type': 'application/json'},
        );
        if (payResp.statusCode == 200) {
          final obj = jsonDecode(payResp.body) as Map<String, dynamic>;
          final List<dynamic> results =
              (obj['results'] as List<dynamic>?) ?? const [];
          if (mounted) setState(() => _totalPaymentsCount = results.length);
        }
      } catch (_) {}
    } catch (_) {
      if (mounted) setState(() => _loadingCounts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BlueGreenHeader(height: 260, title: 'Welcome, Admin'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatBox(
                                  title: 'All Users',
                                  value: _loadingCounts
                                      ? '—'
                                      : _usersCount.toString(),
                                  color: const Color(0xFF34B3A0),
                                  icon: Icons.people_outline,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AdminUsersListPage(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatBox(
                                  title: 'All Authorities',
                                  value: _loadingCounts
                                      ? '—'
                                      : _authoritiesCount.toString(),
                                  color: const Color(0xFF4B9A8F),
                                  icon: Icons.account_balance_outlined,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AdminAuthoritiesPage(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatBox(
                                  title: 'Total Bills',
                                  value: _loadingCounts
                                      ? '—'
                                      : _totalBillsCount.toString(),
                                  color: const Color(0xFF7FD9CE),
                                  icon: Icons.receipt_long,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AdminBillsListPage(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatBox(
                                  title: 'Total Payments',
                                  value: _loadingCounts
                                      ? '—'
                                      : _totalPaymentsCount.toString(),
                                  color: const Color(0xFF6C81FF),
                                  icon: Icons.payments_outlined,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AdminPaymentReportsPage(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white, size: 26),
                  onPressed: () {
                    Scaffold.of(ctx).openDrawer();
                  },
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 28),
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

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  const _StatBox({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
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
