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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String _fullName = '';
  ImageProvider? _profileImage;
  Map<String, dynamic>? _latestBill; // latest bill for this user
  bool _loadingLatestBill = false;

  @override
  void initState() {
    super.initState();
    _loadName();
    _loadLatestBill();
  }

  void _showChangePhotoSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Image picker not set up yet'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Camera not set up yet')),
                  );
                },
              ),
              if (_profileImage != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _profileImage = null);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

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

      Map<String, dynamic>? mostRecent;
      DateTime? mostRecentCreated;

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
              final createdStr = (bill['created_at'] ?? '') as String;
              DateTime created;
              try {
                created = DateTime.parse(createdStr);
              } catch (_) {
                created = DateTime.now();
              }
              if (mostRecentCreated == null ||
                  created.isAfter(mostRecentCreated)) {
                mostRecentCreated = created;
                mostRecent = bill;
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
              final createdStr = (bill['created_at'] ?? '') as String;
              DateTime created;
              try {
                created = DateTime.parse(createdStr);
              } catch (_) {
                created = DateTime.now();
              }
              if (mostRecentCreated == null ||
                  created.isAfter(mostRecentCreated)) {
                mostRecentCreated = created;
                mostRecent = bill;
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
              final createdStr = (bill['created_at'] ?? '') as String;
              DateTime created;
              try {
                created = DateTime.parse(createdStr);
              } catch (_) {
                created = DateTime.now();
              }
              if (mostRecentCreated == null ||
                  created.isAfter(mostRecentCreated)) {
                mostRecentCreated = created;
                mostRecent = bill;
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
              final createdStr = (bill['created_at'] ?? '') as String;
              DateTime created;
              try {
                created = DateTime.parse(createdStr);
              } catch (_) {
                created = DateTime.now();
              }
              if (mostRecentCreated == null ||
                  created.isAfter(mostRecentCreated)) {
                mostRecentCreated = created;
                mostRecent = bill;
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
              final createdStr = (bill['created_at'] ?? '') as String;
              DateTime created;
              try {
                created = DateTime.parse(createdStr);
              } catch (_) {
                created = DateTime.now();
              }
              if (mostRecentCreated == null ||
                  created.isAfter(mostRecentCreated)) {
                mostRecentCreated = created;
                mostRecent = bill;
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
        final createdStr =
            (bill['created_at'] ?? bill['reading_date'] ?? '') as String;
        DateTime created;
        try {
          created = DateTime.parse(createdStr);
        } catch (_) {
          created = DateTime.now();
        }
        if (mostRecentCreated == null || created.isAfter(mostRecentCreated)) {
          mostRecentCreated = created;
          mostRecent = bill;
        }
      }

      if (mounted) {
        setState(() {
          _latestBill = mostRecent;
          _loadingLatestBill = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingLatestBill = false);
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
        title: Text(
          _currentIndex == 0
              ? 'Welcome back, $_fullName'
              : _currentIndex == 1
              ? 'Payments'
              : 'Profile',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon')),
              );
            },
          ),
        ],
        backgroundColor: const Color(0xFF7FD9CE),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment History coming soon'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.of(context).pop();
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
              overlay: _currentIndex == 2
                  ? _AvatarEdit(
                      image: _profileImage,
                      onTap: _showChangePhotoSheet,
                    )
                  : null,
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
                  color: Colors.white,
                  child: tabs[_currentIndex],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        items: const [
          Icon(Icons.home, size: 26, color: Colors.white),
          Icon(Icons.payment, size: 26, color: Colors.white),
          Icon(Icons.person, size: 26, color: Colors.white),
        ],
        color: const Color(0xFF7FD9CE),
        buttonBackgroundColor: const Color(0xFF4B9A8F),
        backgroundColor: Colors.white,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          if (index == 2) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const UserProfilePage()));
            return;
          }
          if (index == 1) {
            Navigator.pushNamed(context, '/user/bill_payment');
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
            'Latest Bill',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (latestBill == null)
            Card(
              elevation: 1,
              child: ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text('No bills yet'),
                subtitle: const Text(
                  'Bills generated by utility will appear here',
                ),
              ),
            )
          else
            _BillCard(bill: latestBill!),
        ],
      ),
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
        leading: const Icon(Icons.receipt_long, color: Colors.teal),
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
    const accent = Color(0xFF4B9A8F);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Card(
          elevation: 1,
          child: ListTile(
            leading: const Icon(Icons.person_outline, color: accent),
            title: const Text('Personal Details'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _soon(context, 'Personal Details'),
          ),
        ),
        Card(
          elevation: 1,
          child: ListTile(
            leading: const Icon(Icons.credit_card_outlined, color: accent),
            title: const Text('Payment Details'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _soon(context, 'Payment Details'),
          ),
        ),
        Card(
          elevation: 1,
          child: ListTile(
            leading: const Icon(Icons.settings_outlined, color: accent),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _soon(context, 'Settings'),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: Color(0xFFFFF1F1),
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.redAccent,
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

class _AvatarEdit extends StatelessWidget {
  final ImageProvider? image;
  final VoidCallback onTap;
  const _AvatarEdit({required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFFB2E8E1),
              backgroundImage: image,
              child: image == null
                  ? const Icon(Icons.person, size: 36, color: Colors.white)
                  : null,
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF4B9A8F),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
