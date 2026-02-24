import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import '../../config/api_config.dart';
import '../../widgets/theme_header.dart';
import 'admin_Authorities.dart';
import 'admin_profile.dart';
import 'add_authority_form.dart';
import 'admin_users_page.dart';
import '../bills_page.dart';
import '../payment_reports_page.dart';
import 'admin_payment_request_page.dart';
import 'admin_reviews_page.dart';

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
    // Reload to get latest data from persistent storage
    await prefs.reload();
    final reviews = prefs.getString('saved_reviews_v1');
    final notifications = prefs.getString('notifications_list_v1');
    final paymentMethods = prefs.getString('saved_payment_methods_v1');
    await prefs.clear();
    if (reviews != null && reviews.isNotEmpty) {
      await prefs.setString('saved_reviews_v1', reviews);
    }
    if (notifications != null && notifications.isNotEmpty) {
      await prefs.setString('notifications_list_v1', notifications);
    }
    if (paymentMethods != null && paymentMethods.isNotEmpty) {
      await prefs.setString('saved_payment_methods_v1', paymentMethods);
    }
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
        backgroundColor: Theme.of(context).colorScheme.background,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _pages[_selectedIndex],
        ),
        drawer: Drawer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.primary,
                ],
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
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: 50,
                          color: Theme.of(context).colorScheme.secondary,
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
                  leading: const Icon(
                    Icons.rate_review,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Reviews',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminReviewsPage(),
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
        bottomNavigationBar: _selectedIndex == 0
            ? Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: BottomNavigationBar(
                    type: BottomNavigationBarType.fixed,
                    backgroundColor: Colors.white,
                    selectedFontSize: 12,
                    unselectedFontSize: 12,
                    showSelectedLabels: true,
                    showUnselectedLabels: true,
                    onTap: (index) {
                      if (index == 0) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminUsersListPage(),
                          ),
                        );
                      } else if (index == 1) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminBillsListPage(),
                          ),
                        );
                      } else if (index == 2) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminAuthoritiesPage(),
                          ),
                        );
                      } else if (index == 3) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AdminPaymentReportsPage(),
                          ),
                        );
                      }
                    },
                    items: [
                      BottomNavigationBarItem(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.group,
                            color: Color(0xFFE91E63),
                            size: 24,
                          ),
                        ),
                        label: 'Users',
                      ),
                      BottomNavigationBarItem(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: Color(0xFF2196F3),
                            size: 24,
                          ),
                        ),
                        label: 'Bills',
                      ),
                      BottomNavigationBarItem(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E5F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance,
                            color: Color(0xFF9C27B0),
                            size: 24,
                          ),
                        ),
                        label: 'Authorities',
                      ),
                      BottomNavigationBarItem(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.payment,
                            color: Color(0xFF4CAF50),
                            size: 24,
                          ),
                        ),
                        label: 'Payments',
                      ),
                    ],
                  ),
                ),
              )
            : null,
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
  bool _loadingPending = true;
  List<Map<String, dynamic>> _pendingPayments = [];
  Map<String, Map<String, dynamic>> _billById = {}; // bill_id -> bill
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _fetchCounts();
  }

  Future<void> _fetchCounts() async {
    setState(() {
      _loadingCounts = true;
      _refreshing = true;
    });
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
      // Fetch pending payments (for dashboard preview)
      try {
        setState(() => _loadingPending = true);
        final payUri = Uri.parse('${ApiConfig.baseUrl}/payments/list/?status=pending');
        final payResp = await http.get(
          payUri,
          headers: {'Content-Type': 'application/json'},
        );
        if (payResp.statusCode == 200) {
          final obj = jsonDecode(payResp.body) as Map<String, dynamic>;
          final List<dynamic> results =
              (obj['results'] as List<dynamic>?) ?? const [];
          _pendingPayments = results.cast<Map<String, dynamic>>();
        }
        // Enrich with bill details
        final utilUri = Uri.parse('${ApiConfig.baseUrl}/utility-bill/list/');
        final utilResp = await http.get(
          utilUri,
          headers: {'Content-Type': 'application/json'},
        );
        if (utilResp.statusCode == 200) {
          final uobj = jsonDecode(utilResp.body) as Map<String, dynamic>;
          final List<dynamic> uresults =
              (uobj['results'] as List<dynamic>?) ?? const [];
          _billById.clear();
          for (final b in uresults) {
            final bid = (b['bill_id'] ?? '').toString();
            if (bid.isNotEmpty) _billById[bid] = b as Map<String, dynamic>;
          }
        }
        if (mounted) setState(() => _loadingPending = false);
      } catch (_) {
        if (mounted) setState(() => _loadingPending = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCounts = false);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.background,
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
                                  color: Theme.of(context).colorScheme.primary,
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
                                  color: Theme.of(context).colorScheme.secondary,
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
                                  color: Theme.of(context).colorScheme.primary,
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
                      const SizedBox(height: 16),
                      // Pending requests preview
                      Row(
                        children: [
                          const Text(
                            'Pending Requests',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AdminPaymentRequestPage(),
                                ),
                              );
                            },
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_loadingPending)
                        const Center(child: CircularProgressIndicator())
                      else if (_pendingPayments.isEmpty)
                        Card(
                          elevation: 1,
                          child: ListTile(
                            leading: const Icon(Icons.inbox_outlined),
                            title: const Text('No pending requests'),
                            subtitle: const Text('New approval requests appear here'),
                            trailing: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AdminPaymentRequestPage(),
                                  ),
                                );
                              },
                              child: const Text('Open'),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _pendingPayments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final p = _pendingPayments[index];
                            final billId = (p['bill_id'] ?? '').toString();
                            final shortId = billId.isEmpty
                                ? '--'
                                : (billId.length > 4
                                    ? billId.substring(billId.length - 4)
                                    : billId);
                            final bill = _billById[billId];
                            final utility = (bill?['utility_type'] ?? '')
                                .toString();
                            final amount = (p['amount'] ?? '').toString();
                            final date = (p['payment_date'] ?? '').toString();
                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: Icon(Icons.list_alt,
                                  color: Theme.of(context).colorScheme.secondary),
                                title: Text('Bill #$shortId'),
                                subtitle: Text(
                                  utility.isEmpty ? date : '$utility • $date',
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade700
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    amount.isEmpty ? '₹ --' : '₹ $amount',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2D3142)),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AdminPaymentRequestPage(),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                      // User Statistics Chart
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'User Statistics',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 280,
                                child: _loadingCounts
                                    ? const Center(child: CircularProgressIndicator())
                                    : Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: PieChart(
                                              PieChartData(
                                                sectionsSpace: 2,
                                                centerSpaceRadius: 50,
                                                sections: [
                                                  PieChartSectionData(
                                                    value: _usersCount.toDouble(),
                                                    title: '$_usersCount',
                                                    color: const Color(0xFFE91E63),
                                                    radius: 60,
                                                    titleStyle: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  PieChartSectionData(
                                                    value: _authoritiesCount.toDouble(),
                                                    title: '$_authoritiesCount',
                                                    color: const Color(0xFF9C27B0),
                                                    radius: 60,
                                                    titleStyle: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  PieChartSectionData(
                                                    value: _totalBillsCount.toDouble(),
                                                    title: '$_totalBillsCount',
                                                    color: const Color(0xFF2196F3),
                                                    radius: 60,
                                                    titleStyle: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  PieChartSectionData(
                                                    value: _totalPaymentsCount.toDouble(),
                                                    title: '$_totalPaymentsCount',
                                                    color: const Color(0xFF4CAF50),
                                                    radius: 60,
                                                    titleStyle: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                                pieTouchData: PieTouchData(
                                                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                                    // Handle touch events if needed
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            flex: 1,
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _LegendItem(
                                                  color: const Color(0xFFE91E63),
                                                  label: 'Users',
                                                  value: _usersCount.toString(),
                                                ),
                                                const SizedBox(height: 12),
                                                _LegendItem(
                                                  color: const Color(0xFF9C27B0),
                                                  label: 'Authorities',
                                                  value: _authoritiesCount.toString(),
                                                ),
                                                const SizedBox(height: 12),
                                                _LegendItem(
                                                  color: const Color(0xFF2196F3),
                                                  label: 'Bills',
                                                  value: _totalBillsCount.toString(),
                                                ),
                                                const SizedBox(height: 12),
                                                _LegendItem(
                                                  color: const Color(0xFF4CAF50),
                                                  label: 'Payments',
                                                  value: _totalPaymentsCount.toString(),
                                                ),
                                              ],
                                            ),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _refreshing ? null : _fetchCounts,
                    icon: _refreshing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.refresh, color: Colors.white, size: 26),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white, size: 28),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddAuthorityForm(),
                        ),
                      ).then((_) => _fetchCounts());
                    },
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

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
