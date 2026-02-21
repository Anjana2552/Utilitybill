import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../../widgets/theme_header.dart';
import 'user_profile.dart';
import 'view_bills_page.dart';
import 'add_bill_page.dart';
import 'bill_payment.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';
import '../notifications.dart';
import '../../services/notifications_service.dart';
import '../../services/notification_generator.dart';
import 'rewards_page.dart';
// Theme toggling removed; single theme app

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String _fullName = '';
  Map<String, dynamic>? _latestBill; // latest bill for this user
  bool _loadingLatestBill = false;
  int _unreadNotifCount = 0;
  String? _walletBalance; // user's wallet balance
  bool _loadingWallet = false;

  @override
  void initState() {
    super.initState();
    _loadName();
    _loadLatestBill();
    _loadUnreadNotifications();
    _loadWalletBalance();
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final generator = NotificationGenerator();
      await generator.generateAllNotifications();
      final svc = NotificationsService();
      final c = await svc.unreadCount();
      if (mounted) setState(() => _unreadNotifCount = c);
    } catch (_) {}
  }

  // Theme picker removed

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    final name =
        prefs.getString('full_name') ??
        prefs.getString('user_username') ??
        'User';
    if (!mounted) return;
    setState(() {
      _fullName = name;
    });
  }

  // Tabs are built in build() to pass latest bill state
  Future<void> _loadLatestBill() async {
    setState(() => _loadingLatestBill = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_username') ?? '';
      if (username.isEmpty) {
        setState(() => _loadingLatestBill = false);
        return;
      }
      // Fetch set of approved (paid) bill IDs to exclude from latest bill
      final Set<String> approvedBillIds = <String>{};
      try {
        final paidResp = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/payments/list/?status=approved'),
          headers: {'Content-Type': 'application/json'},
        );
        if (paidResp.statusCode == 200) {
          final pobj = jsonDecode(paidResp.body) as Map<String, dynamic>;
          final List<dynamic> presults =
              (pobj['results'] as List<dynamic>?) ?? const [];
          for (final p in presults) {
            final id = ((p as Map<String, dynamic>)['bill_id'] ?? '')
                .toString();
            if (id.isNotEmpty) approvedBillIds.add(id);
          }
        }
      } catch (_) {}
      final utilUri = Uri.parse(
        '${ApiConfig.baseUrl}/user-utility/list/?user_name=${Uri.encodeQueryComponent(username)}',
      );
      final utilResp = await http.get(
        utilUri,
        headers: {'Content-Type': 'application/json'},
      );
      final utilJson = jsonDecode(utilResp.body) as Map<String, dynamic>;
      final List<dynamic> utilities =
          (utilJson['results'] as List<dynamic>?) ?? const [];

      Map<String, dynamic>? earliestDueBill;
      DateTime? earliestDue;

      for (final u in utilities) {
        final type = (u['utility_type'] ?? '').toString().toLowerCase();
        final qp = <String, String>{};
        if (type == 'electricity') {
          final cn = (u['consumer_number'] ?? '').toString();
          if (cn.isEmpty) continue;
          // Try minimal UtilityBill first
          final utilBillsUri = Uri.parse(
            '${ApiConfig.baseUrl}/utility-bill/list/?consumer_id=${Uri.encodeQueryComponent(cn)}&utility_type=Electricity',
          );
          final respUB = await http.get(
            utilBillsUri,
            headers: {'Content-Type': 'application/json'},
          );
          if (respUB.statusCode == 200) {
            final obj = jsonDecode(respUB.body) as Map<String, dynamic>;
            final List<dynamic> results =
                (obj['results'] as List<dynamic>?) ?? const [];
            if (results.isNotEmpty) {
              final bill = results.first as Map<String, dynamic>;
              final id = (bill['bill_id'] ?? '').toString();
              if (id.isEmpty || approvedBillIds.contains(id)) {
                // skip paid or invalid bill
              } else {
                final dueStr =
                    (bill['due_date'] ??
                            bill['expiry_date'] ??
                            bill['created_at'] ??
                            '')
                        as String;
                DateTime due;
                try {
                  due = DateTime.parse(dueStr);
                } catch (_) {
                  due = DateTime.now();
                }
                if (earliestDue == null || due.isBefore(earliestDue)) {
                  earliestDue = due;
                  earliestDueBill = bill;
                }
              }
            }
          }
          // Also check GeneratedBill as fallback
          qp['consumer_number'] = cn;
          qp['utility_type'] = 'electricity';
        } else if (type == 'water') {
          final w = (u['water_connection_number'] ?? '').toString();
          if (w.isEmpty) continue;
          final utilBillsUri = Uri.parse(
            '${ApiConfig.baseUrl}/utility-bill/list/?consumer_id=${Uri.encodeQueryComponent(w)}&utility_type=Water',
          );
          final respUB = await http.get(
            utilBillsUri,
            headers: {'Content-Type': 'application/json'},
          );
          if (respUB.statusCode == 200) {
            final obj = jsonDecode(respUB.body) as Map<String, dynamic>;
            final List<dynamic> results =
                (obj['results'] as List<dynamic>?) ?? const [];
            if (results.isNotEmpty) {
              final bill = results.first as Map<String, dynamic>;
              final id = (bill['bill_id'] ?? '').toString();
              if (id.isEmpty || approvedBillIds.contains(id)) {
                // skip paid or invalid bill
              } else {
                final dueStr =
                    (bill['due_date'] ??
                            bill['expiry_date'] ??
                            bill['created_at'] ??
                            '')
                        as String;
                DateTime due;
                try {
                  due = DateTime.parse(dueStr);
                } catch (_) {
                  due = DateTime.now();
                }
                if (earliestDue == null || due.isBefore(earliestDue)) {
                  earliestDue = due;
                  earliestDueBill = bill;
                }
              }
            }
          }
          qp['water_connection_number'] = w;
          qp['utility_type'] = 'Water';
        } else if (type == 'gas') {
          final g = (u['gas_connection_number'] ?? '').toString();
          if (g.isEmpty) continue;
          final utilBillsUri = Uri.parse(
            '${ApiConfig.baseUrl}/utility-bill/list/?consumer_id=${Uri.encodeQueryComponent(g)}&utility_type=Gas',
          );
          final respUB = await http.get(
            utilBillsUri,
            headers: {'Content-Type': 'application/json'},
          );
          if (respUB.statusCode == 200) {
            final obj = jsonDecode(respUB.body) as Map<String, dynamic>;
            final List<dynamic> results =
                (obj['results'] as List<dynamic>?) ?? const [];
            if (results.isNotEmpty) {
              final bill = results.first as Map<String, dynamic>;
              final id = (bill['bill_id'] ?? '').toString();
              if (id.isEmpty || approvedBillIds.contains(id)) {
                // skip paid or invalid bill
              } else {
                final dueStr =
                    (bill['due_date'] ??
                            bill['expiry_date'] ??
                            bill['created_at'] ??
                            '')
                        as String;
                DateTime due;
                try {
                  due = DateTime.parse(dueStr);
                } catch (_) {
                  due = DateTime.now();
                }
                if (earliestDue == null || due.isBefore(earliestDue)) {
                  earliestDue = due;
                  earliestDueBill = bill;
                }
              }
            }
          }
          qp['gas_consumer_id'] = g;
          qp['utility_type'] = 'Gas';
        } else if (type == 'wifi' || type == 'internet') {
          final w = (u['wifi_consumer_id'] ?? '').toString();
          if (w.isEmpty) continue;
          final utilBillsUri = Uri.parse(
            '${ApiConfig.baseUrl}/utility-bill/list/?consumer_id=${Uri.encodeQueryComponent(w)}&utility_type=Wifi',
          );
          final respUB = await http.get(
            utilBillsUri,
            headers: {'Content-Type': 'application/json'},
          );
          if (respUB.statusCode == 200) {
            final obj = jsonDecode(respUB.body) as Map<String, dynamic>;
            final List<dynamic> results =
                (obj['results'] as List<dynamic>?) ?? const [];
            if (results.isNotEmpty) {
              final bill = results.first as Map<String, dynamic>;
              final id = (bill['bill_id'] ?? '').toString();
              if (id.isEmpty || approvedBillIds.contains(id)) {
                // skip paid or invalid bill
              } else {
                final dueStr =
                    (bill['due_date'] ??
                            bill['expiry_date'] ??
                            bill['created_at'] ??
                            '')
                        as String;
                DateTime due;
                try {
                  due = DateTime.parse(dueStr);
                } catch (_) {
                  due = DateTime.now();
                }
                if (earliestDue == null || due.isBefore(earliestDue)) {
                  earliestDue = due;
                  earliestDueBill = bill;
                }
              }
            }
          }
          qp['wifi_consumer_id'] = w;
          qp['utility_type'] = 'Wifi';
        } else if (type == 'dth') {
          final d = (u['dth_subscriber_id'] ?? '').toString();
          if (d.isEmpty) continue;
          final utilBillsUri = Uri.parse(
            '${ApiConfig.baseUrl}/utility-bill/list/?consumer_id=${Uri.encodeQueryComponent(d)}&utility_type=DTH',
          );
          final respUB = await http.get(
            utilBillsUri,
            headers: {'Content-Type': 'application/json'},
          );
          if (respUB.statusCode == 200) {
            final obj = jsonDecode(respUB.body) as Map<String, dynamic>;
            final List<dynamic> results =
                (obj['results'] as List<dynamic>?) ?? const [];
            if (results.isNotEmpty) {
              final bill = results.first as Map<String, dynamic>;
              final dueStr =
                  (bill['due_date'] ??
                          bill['expiry_date'] ??
                          bill['created_at'] ??
                          '')
                      as String;
              DateTime due;
              try {
                due = DateTime.parse(dueStr);
              } catch (_) {
                due = DateTime.now();
              }
              if (earliestDue == null || due.isBefore(earliestDue)) {
                earliestDue = due;
                earliestDueBill = bill;
              }
            }
          }
          qp['dth_subscriber_id'] = d;
          qp['utility_type'] = 'DTH';
        }

        if (qp.isEmpty) continue;
        final billsUri = Uri.parse(
          '${ApiConfig.baseUrl}/bills/list/',
        ).replace(queryParameters: qp);
        final resp = await http.get(
          billsUri,
          headers: {'Content-Type': 'application/json'},
        );
        if (resp.statusCode != 200) continue;
        final obj = jsonDecode(resp.body) as Map<String, dynamic>;
        final List<dynamic> results =
            (obj['results'] as List<dynamic>?) ?? const [];
        if (results.isEmpty) continue;
        final bill = results.first as Map<String, dynamic>;
        final bid = (bill['bill_id'] ?? '').toString();
        if (bid.isEmpty || approvedBillIds.contains(bid)) {
          // skip paid or invalid bill
          continue;
        }
        final dueStr =
            (bill['due_date'] ??
                    bill['expiry_date'] ??
                    bill['created_at'] ??
                    bill['reading_date'] ??
                    '')
                as String;
        DateTime due;
        try {
          due = DateTime.parse(dueStr);
        } catch (_) {
          due = DateTime.now();
        }
        if (earliestDue == null || due.isBefore(earliestDue)) {
          earliestDue = due;
          earliestDueBill = bill;
        }
      }

      if (mounted) {
        setState(() {
          _latestBill = earliestDueBill;
          _loadingLatestBill = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingLatestBill = false);
    }
  }

  Future<void> _loadWalletBalance() async {
    setState(() => _loadingWallet = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_username') ?? '';
      if (username.isEmpty) {
        setState(() => _loadingWallet = false);
        return;
      }
      final balUri = Uri.parse(
        '${ApiConfig.baseUrl}/wallet/balance/?username=${Uri.encodeQueryComponent(username)}',
      );
      final resp = await http.get(
        balUri,
        headers: {'Content-Type': 'application/json'},
      );
      if (resp.statusCode == 200) {
        final obj = jsonDecode(resp.body) as Map<String, dynamic>;
        final bal = (obj['balance'] ?? '0.00').toString();
        if (mounted) setState(() => _walletBalance = bal);
      }
    } catch (_) {
      // ignore errors; keep default
    } finally {
      if (mounted) setState(() => _loadingWallet = false);
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    final reviews = prefs.getString('saved_reviews_v1');
    final notifications = prefs.getString('notifications_list_v1');
    await prefs.clear();
    if (reviews != null && reviews.isNotEmpty) {
      await prefs.setString('saved_reviews_v1', reviews);
    }
    if (notifications != null && notifications.isNotEmpty) {
      await prefs.setString('notifications_list_v1', notifications);
    }
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _HomeTab(
        latestBill: _latestBill,
        loading: _loadingLatestBill,
        onRefresh: _loadLatestBill,
      ),
      BillPaymentPage(useHeader: false),
      const _ProfileTab(),
    ];
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
        title: Text(
          _currentIndex == 0
              ? 'Welcome back, $_fullName'
              : _currentIndex == 1
              ? 'Payments'
              : 'My Bills',
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                tooltip: 'Notifications',
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsPage(),
                    ),
                  );
                  await _loadUnreadNotifications();
                },
              ),
              if (_unreadNotifCount > 0)
                Positioned(
                  right: 8,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 18),
                    child: Text(
                      _unreadNotifCount > 9 ? '9+' : '$_unreadNotifCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Theme toggle removed
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () {
              // Ensure when returning from Profile, Home tab is shown.
              setState(() => _currentIndex = 0);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UserProfilePage()),
              );
            },
          ),
        ],
        elevation: 0,
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    'Menu',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
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
                title: const Text('My Bills'),
                childrenPadding: const EdgeInsets.only(left: 24),
                children: [
                  ListTile(
                    leading: const Icon(Icons.visibility_outlined),
                    title: const Text('View Bills'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ViewBillsPage(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.playlist_add_outlined),
                    title: const Text('Add Bill'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddBillPage()),
                      );
                    },
                  ),
                ],
              ),
              ListTile(
                leading: const Icon(Icons.payment),
                title: const Text('Payment'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/user/bill_payment');
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Payment History'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/user/payment_history');
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.of(context).pop();
                  // Ensure Home tab is selected when returning from Profile.
                  setState(() => _currentIndex = 0);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UserProfilePage()),
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BlueGreenHeader(
              height: 220,
              overlayYOffset: -30,
              title: 'My Wallet',
              subtitle: _loadingWallet
                  ? 'Loading...'
                  : '₹ ${_walletBalance ?? '0.00'}',
              titleAlignment: HeaderTitleAlignment.left,
            ),
            // No spacer needed when avatar is centered in the header
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(0.05, 0.02),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  key: ValueKey<int>(_currentIndex),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                  ),
                  child: tabs[_currentIndex],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        items: [
          Icon(
            Icons.home,
            size: 26,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          Icon(
            Icons.payment,
            size: 26,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          Icon(
            Icons.receipt_long,
            size: 26,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          Icon(
            Icons.chat_bubble_outline,
            size: 26,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ],
        color: Theme.of(context).colorScheme.primary,
        buttonBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
        backgroundColor: Theme.of(context).colorScheme.surface,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          if (index == 2) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ViewBillsPage()));
            return;
          }
          if (index == 1) {
            Navigator.pushNamed(context, '/user/bill_payment');
            return;
          }
          if (index == 3) {
            Navigator.pushNamed(context, '/user/chat');
            return;
          }
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final Map<String, dynamic>? latestBill;
  final bool loading;
  final Future<void> Function() onRefresh;
  const _HomeTab({
    required this.latestBill,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 16,
            children: [
              _RoundAction(
                label: 'Add Bill',
                icon: Icons.playlist_add,
                color: const Color(0xFF42A5F5), // blue
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddBillPage()),
                  );
                },
              ),
              _RoundAction(
                label: 'View Bills',
                icon: Icons.visibility,
                color: const Color(0xFFAB47BC), // purple
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ViewBillsPage()),
                  );
                },
              ),
              _RoundAction(
                label: 'Payment History',
                icon: Icons.history,
                color: const Color(0xFFFFA726), // orange
                onTap: () {
                  Navigator.pushNamed(context, '/user/payment_history');
                },
              ),
              _RoundAction(
                label: 'My Rewards',
                icon: Icons.card_giftcard,
                color: Theme.of(context).colorScheme.primary,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RewardsPage()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (latestBill != null) ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Upcoming Bill',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/user/bill_payment'),
                  child: const Text('Read more'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _BillCard(bill: latestBill!),
          ] else ...[
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Upcoming Bill',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/user/bill_payment'),
                  child: const Text('Read more'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'No upcoming bills',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 6),
                    Text('Add a bill to get reminders and track payments.'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _RoundAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 90,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _BillCard extends StatelessWidget {
  final Map<String, dynamic> bill;
  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    final utility = (bill['utility_type'] ?? '').toString();
    final billId = (bill['bill_id'] ?? '').toString();
    final amount = (bill['total_amount'] ?? '').toString();
    final dateText = (bill['due_date'] ?? bill['created_at'] ?? '').toString();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          Icons.receipt_long,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text('Invoice $billId'),
        subtitle: Text(
          dateText.isEmpty
              ? utility
              : '$utility • ${bill.containsKey('due_date') ? 'Due' : 'On'} $dateText',
        ),
        trailing: Text(
          amount.isEmpty ? '' : '₹ $amount',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  void _soon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Card(
          elevation: 1,
          child: ListTile(
            leading: Icon(Icons.person_outline, color: scheme.secondary),
            title: const Text('Personal Details'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _soon(context, 'Personal Details'),
          ),
        ),
        Card(
          elevation: 1,
          child: ListTile(
            leading: Icon(Icons.credit_card_outlined, color: scheme.secondary),
            title: const Text('Payment Details'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _soon(context, 'Payment Details'),
          ),
        ),
        Card(
          elevation: 1,
          child: ListTile(
            leading: Icon(Icons.settings_outlined, color: scheme.secondary),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _soon(context, 'Settings'),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: scheme.errorContainer,
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: Text(
              'Logout',
              style: TextStyle(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => _soon(context, 'Logout'),
          ),
        ),
      ],
    );
  }
}

// Unused overlay and avatar edit widgets removed
