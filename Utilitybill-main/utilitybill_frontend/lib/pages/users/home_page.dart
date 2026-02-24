import 'package:flutter/material.dart';
import 'dart:math' as math;
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
import 'rewards_page.dart';
import 'settings_page.dart';
import 'complaint_page.dart';
import 'utility_health_score_page.dart';
import '../admin/admin_dashboard.dart';
import '../utility/utility_dashboard.dart';
// Theme toggling removed; single theme app

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String _fullName = '';
  String _userRole = 'user'; // user, admin, or utility
  Map<String, dynamic>? _latestBill; // latest bill for this user
  bool _loadingLatestBill = false;
  int _unreadNotifCount = 0;
  int _unreadChatCount = 0;
  String? _walletBalance; // user's wallet balance
  bool _loadingWallet = false;
  List<Map<String, dynamic>> _userUtilities = []; // user's utilities/categories
  bool _loadingUtilities = false;
  List<Map<String, dynamic>> _billHistory = []; // last 6 months bill data
  bool _loadingBillHistory = false;

  @override
  void initState() {
    super.initState();
    _loadName();
    _loadUserRole();
    _loadLatestBill();
    _loadUnreadNotifications();
    _loadUnreadChats();
    _loadWalletBalance();
    _loadUserUtilities();
    _loadBillHistory();
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_username') ?? '';
      if (username.isEmpty) return;
      
      final svc = NotificationsService();
      final notifications = await svc.loadFromBackend(username);
      final unreadCount = notifications.where((n) => !n.read).length;
      if (mounted) setState(() => _unreadNotifCount = unreadCount);
    } catch (_) {}
  }

  Future<void> _loadUnreadChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_username') ?? '';
      final role = (prefs.getString('user_role') ?? 'user').toLowerCase();
      if (username.isEmpty) return;
      
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/chat/unread-counts/?username=${Uri.encodeQueryComponent(username)}&role=${Uri.encodeQueryComponent(role)}',
      );
      final resp = await http.get(uri, headers: {'Content-Type': 'application/json'});
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final unreadList = (data['unread_counts'] as List<dynamic>?) ?? [];
        int totalUnread = 0;
        for (final item in unreadList) {
          final count = ((item as Map<String, dynamic>)['unread_count'] ?? 0) as int;
          totalUnread += count;
        }
        if (mounted) setState(() => _unreadChatCount = totalUnread);
      }
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

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = (prefs.getString('user_role') ?? 'user').toLowerCase();
    if (!mounted) return;
    setState(() {
      _userRole = role;
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
          try {
            final pobj = jsonDecode(paidResp.body) as Map<String, dynamic>;
            final List<dynamic> presults =
                (pobj['results'] as List<dynamic>?) ?? const [];
            for (final p in presults) {
              final id = ((p as Map<String, dynamic>)['bill_id'] ?? '')
                  .toString();
              if (id.isNotEmpty) approvedBillIds.add(id);
            }
          } catch (e) {
            // Skip if JSON parsing fails
            print('Error parsing payments list: $e');
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
        
        // Add specific error handling for JSON parsing
        Map<String, dynamic> obj;
        try {
          obj = jsonDecode(resp.body) as Map<String, dynamic>;
        } on FormatException catch (e) {
          print('JSON decode error for bills/list: $e');
          print('Response body: ${resp.body.substring(0, math.min(200, resp.body.length))}');
          continue;
        }
        
        final List<dynamic> results =
            (obj['results'] as List<dynamic>?) ?? const [];
        if (results.isEmpty) continue;
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

  Future<void> _loadBillHistory() async {
    setState(() => _loadingBillHistory = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_username') ?? '';
      if (username.isEmpty) {
        setState(() => _loadingBillHistory = false);
        return;
      }
      
      // Get user's utilities
      final utilUri = Uri.parse(
        '${ApiConfig.baseUrl}/user-utility/list/?user_name=${Uri.encodeQueryComponent(username)}',
      );
      final utilResp = await http.get(
        utilUri,
        headers: {'Content-Type': 'application/json'},
      );
      
      Map<String, Map<String, dynamic>> billsByType = {};
      
      if (utilResp.statusCode == 200) {
        final utilJson = jsonDecode(utilResp.body) as Map<String, dynamic>;
        final List<dynamic> utilities = (utilJson['results'] as List<dynamic>?) ?? [];
        
        // Get payments for each utility type
        for (final utility in utilities) {
          final utilityType = (utility['utility_type'] ?? '').toString().toLowerCase();
          String displayType = _getDisplayName(utilityType);
          
          // Get the consumer ID/number based on type
          String consumerId = '';
          if (utilityType == 'electricity') {
            consumerId = (utility['consumer_number'] ?? '').toString();
          } else if (utilityType == 'water') {
            consumerId = (utility['water_connection_number'] ?? '').toString();
          } else if (utilityType == 'gas') {
            consumerId = (utility['gas_connection_id'] ?? '').toString();
          } else if (utilityType == 'wifi') {
            consumerId = (utility['wifi_account_number'] ?? '').toString();
          } else if (utilityType == 'dth') {
            consumerId = (utility['dth_subscriber_id'] ?? '').toString();
          }
          
          if (consumerId.isEmpty) continue;
          
          // Get bills for this utility from UtilityBill
          final billsUri = Uri.parse(
            '${ApiConfig.baseUrl}/utility-bill/list/?consumer_id=${Uri.encodeQueryComponent(consumerId)}',
          );
          
          try {
            final billsResp = await http.get(
              billsUri,
              headers: {'Content-Type': 'application/json'},
            );
            
            if (billsResp.statusCode == 200) {
              final billsJson = jsonDecode(billsResp.body) as Map<String, dynamic>;
              final List<dynamic> bills = (billsJson['results'] as List<dynamic>?) ?? [];
              
              double totalAmount = 0;
              int billCount = 0;
              
              for (final bill in bills) {
                final b = bill as Map<String, dynamic>;
                final amount = double.tryParse((b['total_amount'] ?? b['amount'] ?? '0').toString()) ?? 0.0;
                totalAmount += amount;
                billCount++;
              }
              
              if (billCount > 0) {
                billsByType[displayType] = {
                  'type': displayType,
                  'total': totalAmount,
                  'count': billCount,
                  'average': totalAmount / billCount,
                  'color': _getColorForUtility(utilityType),
                  'icon': _getIconForUtility(utilityType),
                };
              }
            }
          } catch (_) {}
        }
      }
      
      // Convert to list and sort by total amount
      List<Map<String, dynamic>> history = billsByType.values.toList();
      history.sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));
      
      if (mounted) {
        setState(() {
          _billHistory = history;
          _loadingBillHistory = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingBillHistory = false);
    }
  }

  String _getDisplayName(String utilityType) {
    switch (utilityType) {
      case 'electricity':
      case 'kseb':
        return 'Electricity';
      case 'water':
      case 'kwa':
        return 'Water';
      case 'gas':
        return 'Gas';
      case 'wifi':
        return 'WiFi';
      case 'dth':
        return 'DTH';
      case 'others':
      case 'other':
        return 'Others';
      default:
        return utilityType.replaceFirst(
          utilityType[0],
          utilityType[0].toUpperCase(),
        );
    }
  }

  IconData _getIconForUtility(String utilityType) {
    switch (utilityType) {
      case 'electricity':
      case 'kseb':
        return Icons.flash_on;
      case 'water':
      case 'kwa':
        return Icons.water_drop;
      case 'gas':
        return Icons.local_gas_station;
      case 'wifi':
        return Icons.wifi;
      case 'dth':
        return Icons.live_tv;
      case 'others':
      case 'other':
        return Icons.category;
      default:
        return Icons.category;
    }
  }

  Color _getColorForUtility(String utilityType) {
    switch (utilityType) {
      case 'electricity':
      case 'kseb':
        return Colors.orange.shade600;
      case 'water':
      case 'kwa':
        return Colors.blue.shade500;
      case 'gas':
        return Colors.purple.shade400;
      case 'wifi':
        return Colors.blue.shade600;
      case 'dth':
        return Colors.blue.shade700;
      case 'others':
      case 'other':
        return Colors.pink.shade400;
      default:
        return Colors.indigo.shade400;
    }
  }

  Future<void> _loadUserUtilities() async {
    setState(() => _loadingUtilities = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_username') ?? '';
      if (username.isEmpty) {
        setState(() => _loadingUtilities = false);
        return;
      }
      final utilUri = Uri.parse(
        '${ApiConfig.baseUrl}/user-utility/list/?user_name=${Uri.encodeQueryComponent(username)}',
      );
      final resp = await http.get(
        utilUri,
        headers: {'Content-Type': 'application/json'},
      );
      if (resp.statusCode == 200) {
        final obj = jsonDecode(resp.body) as Map<String, dynamic>;
        final List<dynamic> results = (obj['results'] as List<dynamic>?) ?? [];
        if (mounted) {
          setState(() {
            _userUtilities = results.cast<Map<String, dynamic>>();
          });
        }
      }
    } catch (e) {
      print('Error loading utilities: $e');
    } finally {
      if (mounted) setState(() => _loadingUtilities = false);
    }
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
    final tabs = [
      _HomeTab(
        latestBill: _latestBill,
        loading: _loadingLatestBill,
        onRefresh: _loadLatestBill,
        userUtilities: _userUtilities,
        onRefreshUtilities: _loadUserUtilities,
        walletBalance: _walletBalance,
        loadingWallet: _loadingWallet,
        billHistory: _billHistory,
        loadingBillHistory: _loadingBillHistory,
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
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade50,
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Custom Header with Wave Background
                Stack(
                  children: [
                    ClipPath(
                      clipper: DrawerWaveClipper(),
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF1e3c72),
                              Color(0xFF2a5298),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 32,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _fullName,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    InkWell(
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        setState(() => _currentIndex = 0);
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const UserProfilePage(),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.person_outline,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Profile',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                                size: 24,
                              ),
                            ],
                          ),
                          SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
                // MAIN Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'MAIN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _DrawerMenuItem(
                  icon: Icons.home,
                  title: 'Home',
                  isSelected: _currentIndex == 0,
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() => _currentIndex = 0);
                  },
                ),
                _DrawerMenuItem(
                  icon: Icons.receipt_long,
                  title: 'My Bills',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ViewBillsPage(),
                      ),
                    );
                  },
                ),
                _DrawerMenuItem(
                  icon: Icons.credit_card,
                  title: 'Pay Bills',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, '/user/bill_payment');
                  },
                ),
                _DrawerMenuItem(
                  icon: Icons.analytics_outlined,
                  title: 'Utility Health Score',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const UtilityHealthScorePage(),
                      ),
                    );
                  },
                ),
                // PAYMENTS Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'PAYMENTS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _DrawerMenuItem(
                  icon: Icons.history,
                  title: 'Payment History',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, '/user/payment_history');
                  },
                ),
                _DrawerMenuItem(
                  icon: Icons.credit_card_outlined,
                  title: 'Payment Methods',
                  trailing: Text(
                    '₹${_walletBalance ?? '0.00'}',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    // Navigate to payment methods if route exists
                  },
                ),
                _DrawerMenuItem(
                  icon: Icons.account_balance_wallet,
                  title: 'Wallet',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, '/user/wallet');
                  },
                ),
                // ACCOUNT Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'ACCOUNT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                _DrawerMenuItem(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() => _currentIndex = 0);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UserProfilePage()),
                    );
                  },
                ),
                _DrawerMenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SettingsPage(),
                      ),
                    );
                  },
                ),
                _DrawerMenuItem(
                  icon: Icons.report_problem_outlined,
                  title: 'Complaints',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ComplaintPage(),
                      ),
                    );
                  },
                ),
                _DrawerMenuItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () async {
                    Navigator.of(context).pop();
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsPage(),
                      ),
                    );
                    await _loadUnreadNotifications();
                  },
                ),
                // Role-based navigation
                if (_userRole == 'admin') ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'ADMINISTRATION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _DrawerMenuItem(
                    icon: Icons.admin_panel_settings,
                    title: 'Admin Dashboard',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const AdminDashboard(),
                        ),
                      );
                    },
                  ),
                ],
                if (_userRole == 'utility') ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'UTILITY MANAGEMENT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _DrawerMenuItem(
                    icon: Icons.dashboard,
                    title: 'Utility Dashboard',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const UtilityDashboard(),
                        ),
                      );
                    },
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Material(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: _handleLogout,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.logout,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
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
          child: tabs[_currentIndex],
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 26,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              if (_unreadChatCount > 0)
                Positioned(
                  right: -8,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _unreadChatCount > 9 ? '9+' : '$_unreadChatCount',
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
        ],
        color: Theme.of(context).colorScheme.primary,
        buttonBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
        backgroundColor: Theme.of(context).colorScheme.surface,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) async {
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
            await Navigator.pushNamed(context, '/user/chat');
            // Reload unread count when returning from chat
            _loadUnreadChats();
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
  final List<Map<String, dynamic>> userUtilities;
  final Future<void> Function() onRefreshUtilities;
  final String? walletBalance;
  final bool loadingWallet;
  final List<Map<String, dynamic>> billHistory;
  final bool loadingBillHistory;
  
  const _HomeTab({
    required this.latestBill,
    required this.loading,
    required this.onRefresh,
    required this.userUtilities,
    required this.onRefreshUtilities,
    required this.walletBalance,
    required this.loadingWallet,
    required this.billHistory,
    required this.loadingBillHistory,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Wallet Section with Background
          ClipPath(
            clipper: WaveClipper(),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1e3c72),
                    Color(0xFF2a5298),
                    Color(0xFF7e8eb8),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Background illustration with curved bottom
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.6,
                      child: Image.asset(
                        'assets/images/landing_bg_mobile.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        // Wallet Card
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue.shade600.withOpacity(0.9),
                                Colors.blue.shade400.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'My Wallet',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Text(
                                loadingWallet
                                    ? 'Loading...'
                                    : '₹${walletBalance ?? '0.00'}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/user/wallet');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade600,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 4,
                                ),
                                child: Text(
                                  'Add Money',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                ],
              ),
            ),
          ),
          // Main Content Section
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categories Section
                  if (userUtilities.isNotEmpty) ...[
                    Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: userUtilities.map((utility) {
                          final utilityType = (utility['utility_type'] ?? '').toString().toLowerCase();
                          final displayName = _getDisplayName(utilityType);
                          final icon = _getIconForUtility(utilityType);
                          final color = _getColorForUtility(utilityType);
                          
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: _CategoryIcon(
                              label: displayName,
                              icon: icon,
                              color: color,
                              onTap: () {
                                Navigator.pushNamed(context, '/user/bill_payment');
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 24),
                  ],
                  // Upcoming Bill Section
                  if (latestBill != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Upcoming Bill',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ViewBillsPage(),
                              ),
                            );
                          },
                          child: Text(
                            'Read more',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _BillCard(bill: latestBill!),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Upcoming Bill',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ViewBillsPage(),
                              ),
                            );
                          },
                          child: Text(
                            'Read more',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No upcoming bills',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add a bill to get reminders and track payments.',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  // Bill Comparison Chart Section - Always show
                  SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bill Comparison Chart',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Track your monthly bill trends',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.blue.shade600,
                        size: 28,
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  if (loadingBillHistory)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  else if (billHistory.isEmpty)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No Bill History Yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Pay your bills to see comparison charts here',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    _BillComparisonChart(billHistory: billHistory),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayName(String utilityType) {
    switch (utilityType) {
      case 'electricity':
      case 'kseb':
        return 'Electricity';
      case 'water':
      case 'kwa':
        return 'Water';
      case 'gas':
        return 'Gas';
      case 'wifi':
        return 'WiFi';
      case 'dth':
        return 'DTH';
      case 'others':
      case 'other':
        return 'Others';
      default:
        return utilityType.replaceFirst(utilityType[0], utilityType[0].toUpperCase());
    }
  }

  IconData _getIconForUtility(String utilityType) {
    switch (utilityType) {
      case 'electricity':
      case 'kseb':
        return Icons.flash_on;
      case 'water':
      case 'kwa':
        return Icons.water_drop;
      case 'gas':
        return Icons.local_gas_station;
      case 'wifi':
        return Icons.wifi;
      case 'dth':
        return Icons.live_tv;
      case 'others':
      case 'other':
        return Icons.category;
      default:
        return Icons.category;
    }
  }

  Color _getColorForUtility(String utilityType) {
    switch (utilityType) {
      case 'electricity':
      case 'kseb':
        return Colors.orange.shade600;
      case 'water':
      case 'kwa':
        return Colors.blue.shade500;
      case 'gas':
        return Colors.purple.shade400;
      case 'wifi':
        return Colors.blue.shade600;
      case 'dth':
        return Colors.blue.shade700;
      case 'others':
      case 'other':
        return Colors.pink.shade400;
      default:
        return Colors.indigo.shade400;
    }
  }
}

// Bill Comparison Chart Widget
class _BillComparisonChart extends StatelessWidget {
  final List<Map<String, dynamic>> billHistory;
  
  const _BillComparisonChart({required this.billHistory});
  
  @override
  Widget build(BuildContext context) {
    if (billHistory.isEmpty) {
      return SizedBox.shrink();
    }
    
    // Calculate totals
    double grandTotal = 0;
    int totalBills = 0;
    for (final bill in billHistory) {
      grandTotal += (bill['total'] as double?) ?? 0;
      totalBills += (bill['count'] as int?) ?? 0;
    }

    final segments = billHistory.map((bill) {
      final type = (bill['type'] as String?) ?? '';
      final amount = (bill['total'] as double?) ?? 0;
      final count = (bill['count'] as int?) ?? 0;
      final color = bill['color'] as Color? ?? Colors.blue.shade500;
      final icon = bill['icon'] as IconData? ?? Icons.receipt;
      return _BillSegment(
        label: type,
        value: amount,
        count: count,
        color: color,
        icon: icon,
      );
    }).where((s) => s.value > 0).toList();

    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    
    return Card(
      elevation: 3,
      shadowColor: Colors.blue.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.blue.shade50.withOpacity(0.3),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bill Breakdown by Type',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Total: ${billHistory.length} utility types',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalBills Bills',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              // Circular chart with legend
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 520;
                  final chart = SizedBox(
                    height: 200,
                    width: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(180, 180),
                          painter: _BillPieChartPainter(
                            segments: segments,
                            total: total,
                            strokeWidth: 22,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '₹${grandTotal.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );

                  final legend = Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: segments.map((s) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: s.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            '${s.label}  ₹${s.value.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Center(child: chart),
                        ),
                        SizedBox(width: 20),
                        Expanded(child: legend),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Center(child: chart),
                      SizedBox(height: 16),
                      legend,
                    ],
                  );
                },
              ),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 12),
              // Summary info with icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Grand Total
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                size: 16,
                                color: Colors.green.shade700,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Total Spent',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            '₹${grandTotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  // Average per bill
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.trending_up,
                                size: 16,
                                color: Colors.blue.shade700,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Avg/Bill',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            '₹${totalBills > 0 ? (grandTotal / totalBills).toStringAsFixed(2) : '0.00'}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // Highest bill indicator
              if (billHistory.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.priority_high,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Highest: ${billHistory[0]['type']} - ₹${(billHistory[0]['total'] as double).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BillSegment {
  final String label;
  final double value;
  final int count;
  final Color color;
  final IconData icon;

  const _BillSegment({
    required this.label,
    required this.value,
    required this.count,
    required this.color,
    required this.icon,
  });
}

class _BillPieChartPainter extends CustomPainter {
  final List<_BillSegment> segments;
  final double total;
  final double strokeWidth;

  _BillPieChartPainter({
    required this.segments,
    required this.total,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty || total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double startAngle = -math.pi / 2;
    for (final segment in segments) {
      final sweep = (segment.value / total) * math.pi * 2;
      paint.color = segment.color;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _BillPieChartPainter oldDelegate) {
    return oldDelegate.segments != segments || oldDelegate.total != total;
  }
}

// New Category Icon Widget
class _CategoryIcon extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  
  const _CategoryIcon({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 32,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

// Drawer Menu Item Widget
class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isSelected;
  final Widget? trailing;

  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isSelected = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: isSelected 
            ? Colors.blue.shade500
            : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
        elevation: isSelected ? 4 : 1,
        shadowColor: isSelected 
            ? Colors.blue.withOpacity(0.4)
            : Colors.grey.withOpacity(0.2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.3)
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected 
                        ? Colors.white
                        : Colors.blue.shade700,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? Colors.white
                          : Colors.grey.shade800,
                    ),
                  ),
                ),
                if (trailing != null)
                  trailing!
                else
                  Icon(
                    Icons.chevron_right,
                    color: isSelected 
                        ? Colors.white
                        : Colors.grey.shade400,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Drawer Wave Clipper
class DrawerWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 20);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    
    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 40);
    var secondEndPoint = Offset(size.width, size.height - 30);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _BillCard extends StatelessWidget {
  final Map<String, dynamic> bill;
  const _BillCard({required this.bill});

  IconData _getUtilityIcon(String utilityType) {
    final type = utilityType.toLowerCase();
    switch (type) {
      case 'electricity':
      case 'kseb':
        return Icons.flash_on;
      case 'water':
      case 'kwa':
        return Icons.water_drop;
      case 'wifi':
        return Icons.wifi;
      case 'dth':
        return Icons.live_tv;
      case 'gas':
        return Icons.local_gas_station;
      default:
        return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context) {
    final utility = (bill['utility_type'] ?? 'Bill').toString();
    final billId = (bill['bill_id'] ?? '').toString();
    final amount = (bill['total_amount'] ?? '0').toString();
    // Use due_date, expiry_date, or last_date for the deadline
    final dateText = (bill['due_date'] ?? bill['expiry_date'] ?? bill['last_date'] ?? bill['created_at'] ?? '').toString();
    
    // Parse date and check if overdue
    String formattedDate = '';
    bool isOverdue = false;
    try {
      final date = DateTime.parse(dateText);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final billDate = DateTime(date.year, date.month, date.day);
      
      isOverdue = billDate.isBefore(today);
      
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      formattedDate = '${date.day} ${months[date.month - 1]}';
    } catch (_) {
      formattedDate = dateText;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOverdue ? Colors.red.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getUtilityIcon(utility),
              color: isOverdue ? Colors.red.shade700 : Colors.orange.shade700,
              size: 28,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${utility.replaceFirst(utility[0], utility[0].toUpperCase())} Bill',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: isOverdue ? Colors.red.shade600 : Colors.blue.shade600,
                    ),
                    SizedBox(width: 4),
                    Text(
                      isOverdue ? 'Overdue: ' : 'Pay by: ',
                      style: TextStyle(
                        fontSize: 13,
                        color: isOverdue ? Colors.red.shade600 : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 14,
                        color: isOverdue ? Colors.red.shade600 : Colors.grey.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isOverdue ? Colors.red.shade600 : Colors.blue.shade600,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '₹$amount',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
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

// Custom Wave Clipper for curved bottom
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    
    // Create a smooth wave curve
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 30);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    
    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 60);
    var secondEndPoint = Offset(size.width, size.height - 50);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Unused overlay and avatar edit widgets removed
