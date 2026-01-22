import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../payment_reports_page.dart';
import 'utility_profile.dart';
import 'generate_bill.dart';
import '../../widgets/theme_header.dart';
import 'utility_users_list.dart';
import '../bills_page.dart';
import '../notifications.dart';

class UtilityDashboard extends StatefulWidget {
  const UtilityDashboard({super.key});

  @override
  State<UtilityDashboard> createState() => _UtilityDashboardState();
}

class _UtilityDashboardState extends State<UtilityDashboard> {
  String _fullName = '';
  String _email = '';
  bool _isLoading = true;
  int _currentIndex = 0;
  String _providerName = '';
  int _providerUserCount = 0;
  String _username = '';
  List<Map<String, dynamic>> _providerBills = [];
  bool _loadingProviderBills = false;
  // Users list moved to a dedicated page; keep only count here.

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _fullName = prefs.getString('full_name') ?? 'Utility Authority';
    _email = prefs.getString('user_email') ?? '';
    _username = prefs.getString('user_username') ?? '';

    // Detect provider name from username suffix
    final uLower = _username.toLowerCase();
    if (uLower.contains('kseb')) {
      _providerName = 'kseb';
      // ignore: unawaited_futures
      _fetchProviderUserCount('kseb');
      // ignore: unawaited_futures
      _fetchProviderBills('kseb');
    } else if (uLower.contains('kwa') || uLower.contains('water')) {
      _providerName = 'water';
      // ignore: unawaited_futures
      _fetchProviderUserCount('water');
      // ignore: unawaited_futures
      _fetchProviderBills('water');
    } else if (uLower.contains('gas')) {
      _providerName = 'gas';
      // ignore: unawaited_futures
      _fetchProviderUserCount('gas');
      // ignore: unawaited_futures
      _fetchProviderBills('gas');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  Future<void> _fetchProviderUserCount(String provider) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/user-utility/count/?provider_name=${Uri.encodeQueryComponent(provider)}',
      );
      final resp = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final count = int.tryParse(data['count']?.toString() ?? '0') ?? 0;
        if (!mounted) return;
        setState(() {
          _providerUserCount = count;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchProviderBills(String provider) async {
    setState(() => _loadingProviderBills = true);
    try {
      // For now, fetch from utility-bill list filtered by utility type.
      // Map provider name to utility type label used in bills
      String utilityFilter;
      switch (provider.toLowerCase()) {
        case 'kseb':
          utilityFilter = 'Electricity';
          break;
        case 'water':
        case 'kwa':
          utilityFilter = 'Water';
          break;
        case 'gas':
          utilityFilter = 'Gas';
          break;
        default:
          utilityFilter = '';
      }
      final base = Uri.parse('${ApiConfig.baseUrl}/utility-bill/list/');
      final uri = utilityFilter.isEmpty
          ? base
          : base.replace(queryParameters: {'utility_type': utilityFilter});
      final resp = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final List<dynamic> results =
            (data['results'] as List<dynamic>?) ?? const [];
        if (!mounted) return;
        setState(() {
          _providerBills = results.cast<Map<String, dynamic>>();
          _loadingProviderBills = false;
        });
      } else {
        if (mounted) setState(() => _loadingProviderBills = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProviderBills = false);
    }
  }

  // Removed inline users fetching; handled in UtilityUsersListPage

  @override
  Widget build(BuildContext context) {
    // Map provider name to utility type label used in bills
    String? _utilityTypeForProvider(String provider) {
      final p = provider.toLowerCase();
      if (p == 'kseb') return 'Electricity';
      if (p == 'water') return 'Water';
      if (p == 'gas') return 'Gas';
      return null;
    }

    final pages = <Widget>[
      _HomeSection(
        onReadyLogout: _handleLogout,
        onTapCount: _openProviderUsers,
        fullNameGetter: () => _fullName,
        emailGetter: () => _email,
        isLoadingGetter: () => _isLoading,
        providerNameGetter: () => _providerName,
        providerUserCountGetter: () => _providerUserCount,
        billsGetter: () => _providerBills,
        billsLoadingGetter: () => _loadingProviderBills,
      ),
      const GenerateBillPage(),
      AdminPaymentReportsPage(
        restrictedUtilityType: _utilityTypeForProvider(_providerName),
      ),
      const UtilityProfilePage(),
    ];
    final items = <Widget>[
      const Icon(Icons.home, size: 28, color: Colors.white),
      const Icon(Icons.receipt_long, size: 28, color: Colors.white),
      const Icon(Icons.payment, size: 28, color: Colors.white),
      const Icon(Icons.person, size: 28, color: Colors.white),
    ];

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvoked: (didPop) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFF7FD9CE)),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                selected: _currentIndex == 0,
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() => _currentIndex = 0);
                },
              ),
              ExpansionTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('Bills'),
                childrenPadding: const EdgeInsets.only(left: 24),
                children: [
                  ListTile(
                    leading: const Icon(Icons.playlist_add_outlined),
                    title: const Text('Generate Bill'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const GenerateBillPage(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.visibility_outlined),
                    title: const Text('View Bill'),
                    onTap: () {
                      Navigator.of(context).pop();
                      String? utilityType;
                      switch (_providerName.toLowerCase()) {
                        case 'kseb':
                          utilityType = 'Electricity';
                          break;
                        case 'water':
                        case 'kwa':
                          utilityType = 'Water';
                          break;
                        case 'gas':
                          utilityType = 'Gas';
                          break;
                        default:
                          utilityType = null;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminBillsListPage(
                            restrictedUtilityType: utilityType,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              ListTile(
                leading: const Icon(Icons.payment),
                title: const Text('Payment'),
                selected: _currentIndex == 2,
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() => _currentIndex = 2);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_none),
                title: const Text('Notifications'),
                onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsPage(),
                      ),
                    );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: _handleLogout,
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: CurvedNavigationBar(
        items: items,
        index: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        color: const Color(0xFF34B3A0),
        buttonBackgroundColor: const Color(0xFF34B3A0),
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        height: 60,
      ),
      ),
    );
  }

  void _openProviderUsers() {
    if (_providerName.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UtilityUsersListPage(providerName: _providerName),
      ),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
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

class _HomeSection extends StatelessWidget {
  final Future<void> Function() onReadyLogout;
  final VoidCallback onTapCount;
  final String Function() fullNameGetter;
  final String Function() emailGetter;
  final bool Function() isLoadingGetter;
  final String Function() providerNameGetter;
  final int Function() providerUserCountGetter;
  final List<Map<String, dynamic>> Function() billsGetter;
  final bool Function() billsLoadingGetter;

  const _HomeSection({
    required this.onReadyLogout,
    required this.onTapCount,
    required this.fullNameGetter,
    required this.emailGetter,
    required this.isLoadingGetter,
    required this.providerNameGetter,
    required this.providerUserCountGetter,
    required this.billsGetter,
    required this.billsLoadingGetter,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = isLoadingGetter();
    final fullName = fullNameGetter();
    final email = emailGetter();
    final providerName = providerNameGetter();
    final providerUserCount = providerUserCountGetter();
    final bills = billsGetter();
    final billsLoading = billsLoadingGetter();

    return CurvedHeaderPage(
      title: 'Welcome back, ${fullName.isNotEmpty ? fullName : ''}',
      headerHeight: 220,
      titleAlignment: HeaderTitleAlignment.left,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
          tooltip: 'Menu',
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            if (providerName.toLowerCase() == 'kseb') ...[
              _DashboardPill(
                title: 'Total Users',
                subtitle: 'KSEB',
                badgeText: providerUserCount.toString(),
                onTap: onTapCount,
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Recent Bills',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (billsLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (bills.isEmpty)
              Card(
                elevation: 1,
                child: ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: const Text('No bills yet'),
                  subtitle: Text(
                    'Provider: ${providerName.isEmpty ? '-' : providerName.toUpperCase()}',
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bills.length.clamp(0, 5),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final bill = bills[index];
                  final id = (bill['bill_id'] ?? '').toString();
                  final type = (bill['utility_type'] ?? '').toString();
                  final amount = (bill['total_amount'] ?? '').toString();
                  final dueOrCreated =
                      (bill['due_date'] ?? bill['created_at'] ?? '').toString();
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.receipt_long,
                        color: Color(0xFF34B3A0),
                      ),
                      title: Text('Invoice $id'),
                      subtitle: Text(
                        dueOrCreated.isEmpty
                            ? type
                            : '$type • ${bill.containsKey('due_date') ? 'Due' : 'On'} $dueOrCreated',
                      ),
                      trailing: Text(
                        amount.isEmpty ? '' : '₹ $amount',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}

class _DashboardPill extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String badgeText;
  final VoidCallback? onTap;

  const _DashboardPill({
    required this.title,
    this.subtitle,
    required this.badgeText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF34B3A0), Color(0xFF7FD9CE)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Color(0xFF34B3A0),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
