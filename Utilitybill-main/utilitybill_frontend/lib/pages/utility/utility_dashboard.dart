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
import 'send_alert_message_page.dart';
import '../users/chat_page.dart';
import 'utility_reviews_page.dart';
import '../../services/notifications_service.dart';

// Helper to convert provider name to utility type
String? _utilityTypeForProvider(String provider) {
  final p = provider.toLowerCase();
  if (p == 'kseb') return 'Electricity';
  if (p == 'water' || p == 'kwa') return 'Water';
  if (p == 'gas') return 'Gas';
  if (p == 'wifi') return 'WiFi';
  if (p == 'dth') return 'DTH';
  if (p == 'others' || p == 'other') return 'Others';
  return null;
}

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
  bool _refreshing = false;
  int _unreadNotificationCount = 0;
  int _unreadChatCount = 0;
  final _notificationsService = NotificationsService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUnreadCount();
    _loadUnreadChats();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _fullName = prefs.getString('full_name') ?? 'Utility Authority';
    _email = prefs.getString('user_email') ?? '';
    _username = prefs.getString('user_username') ?? '';

    // Detect provider from username or email suffix/content
    final uLower = _username.toLowerCase();
    final eLower = _email.toLowerCase();
    final text = '$uLower $eLower';
    if (text.contains('kseb')) {
      _providerName = 'kseb';
      // ignore: unawaited_futures
      _fetchProviderUserCount('kseb');
      // ignore: unawaited_futures
      _fetchProviderBills('kseb');
    } else if (text.contains('kwa') || text.contains('water')) {
      _providerName = 'water';
      // ignore: unawaited_futures
      _fetchProviderUserCount('water');
      // ignore: unawaited_futures
      _fetchProviderBills('water');
    } else if (text.contains('gas')) {
      _providerName = 'gas';
      // ignore: unawaited_futures
      _fetchProviderUserCount('gas');
      // ignore: unawaited_futures
      _fetchProviderBills('gas');
    } else if (text.contains('wifi')) {
      _providerName = 'wifi';
      // ignore: unawaited_futures
      _fetchProviderUserCount('wifi');
      // ignore: unawaited_futures
      _fetchProviderBills('wifi');
    } else if (text.contains('dth')) {
      _providerName = 'dth';
      // ignore: unawaited_futures
      _fetchProviderUserCount('dth');
      // ignore: unawaited_futures
      _fetchProviderBills('dth');
    } else if (text.contains('other') || text.contains('others')) {
      _providerName = 'others';
      // ignore: unawaited_futures
      _fetchProviderUserCount('others');
      // ignore: unawaited_futures
      _fetchProviderBills('others');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    if (_providerName.isEmpty) return;
    setState(() => _refreshing = true);
    try {
      await Future.wait([
        _fetchProviderUserCount(_providerName),
        _fetchProviderBills(_providerName),
        _loadUnreadCount(),
      ]);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationsService.unreadCount(_username);
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (e) {
      // Silently handle errors
    }
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

  Future<void> _fetchProviderUserCount(String provider) async {
    try {
      // Prefer utility_type filter for consistent grouping
      String type;
      switch (provider.toLowerCase()) {
        case 'kseb':
          type = 'Electricity';
          break;
        case 'water':
        case 'kwa':
          type = 'Water';
          break;
        case 'gas':
          type = 'Gas';
          break;
        case 'wifi':
          type = 'Wifi';
          break;
        case 'dth':
          type = 'DTH';
          break;
        case 'others':
        case 'other':
          type = 'Others';
          break;
        default:
          type = '';
      }
      final base = Uri.parse('${ApiConfig.baseUrl}/user-utility/list/');
      final uri = type.isEmpty
          ? base.replace(queryParameters: {
              'provider_name': provider,
            })
          : base.replace(queryParameters: {
              'utility_type': type,
            });
      final resp = await http.get(uri, headers: {'Content-Type': 'application/json'});
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final results = (body['results'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        if (!mounted) return;
        setState(() => _providerUserCount = results.length);
      }
    } catch (_) {
      // Silent failure; keep existing count
    }
  }

  Future<void> _fetchProviderBills(String provider) async {
    setState(() => _loadingProviderBills = true);
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/utility-bill/list/?provider_name=${Uri.encodeQueryComponent(provider)}',
      );
      final resp = await http.get(uri, headers: {'Content-Type': 'application/json'});
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final results = (body['results'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        if (!mounted) return;
        setState(() => _providerBills = results);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _providerBills = []);
    } finally {
      if (mounted) setState(() => _loadingProviderBills = false);
    }
  }

  void _openProviderUsers() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UtilityUsersListPage(providerName: _providerName),
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
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
    } catch (_) {}
    if (!mounted) return;
    // Navigate to landing screen and replace current route stack
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    // Debug logging
    print('🏢 Provider Name: $_providerName');
    print('🔧 Utility Type: ${_utilityTypeForProvider(_providerName)}');
    
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
        onRefresh: _refreshAll,
        refreshingGetter: () => _refreshing,
        unreadNotificationCountGetter: () => _unreadNotificationCount,
        loadUnreadCount: _loadUnreadCount,
      ),
      const GenerateBillPage(),
      AdminPaymentReportsPage(
        restrictedUtilityType: _utilityTypeForProvider(_providerName),
        restrictedProviderName: _providerName,
      ),
      ChatPage(
        showBottomNav: false,
        showHeaderBack: false,
        authorityMode: true,
        providerName: _providerName,
      ),
    ];

    final items = <Widget>[
      const Icon(Icons.home, size: 28, color: Colors.white),
      const Icon(Icons.receipt_long, size: 28, color: Colors.white),
      const Icon(Icons.payment, size: 28, color: Colors.white),
      Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 28, color: Colors.white),
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
    ];

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: null,
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
                          case 'wifi':
                            utilityType = 'WiFi';
                            break;
                          case 'dth':
                            utilityType = 'DTH';
                            break;
                          case 'others':
                          case 'other':
                            utilityType = 'Others';
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
                  title: const Text('Payment Reports'),
                  selected: _currentIndex == 2,
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() => _currentIndex = 2);
                  },
                ),
                ListTile(
                  leading: Badge(
                    isLabelVisible: _unreadNotificationCount > 0,
                    label: Text('$_unreadNotificationCount'),
                    child: const Icon(Icons.notifications_none),
                  ),
                  title: const Text('Notifications'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final utilityType = _utilityTypeForProvider(_providerName);
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NotificationsPage(utilityType: utilityType),
                      ),
                    );
                    // Reload count after viewing notifications
                    _loadUnreadCount();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.campaign),
                  title: const Text('Send Alert Message'),
                  onTap: () {
                    Navigator.of(context).pop();
                    final utilityType = _utilityTypeForProvider(_providerName);
                    if (utilityType != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SendAlertMessagePage(
                            utilityType: utilityType,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unable to determine utility type'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
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
          items: items
              .map((w) => IconTheme(
                    data: IconThemeData(
                        color: Theme.of(context).colorScheme.onPrimary),
                    child: w,
                  ))
              .toList(),
          index: _currentIndex,
          onTap: (i) {
            setState(() => _currentIndex = i);
            // Reload unread chat count when navigating away from chat page
            if (_currentIndex == 3 && i != 3) {
              _loadUnreadChats();
            }
          },
          color: Theme.of(context).colorScheme.primary,
          buttonBackgroundColor:
              Theme.of(context).colorScheme.primaryContainer,
          backgroundColor: Theme.of(context).colorScheme.surface,
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 300),
          height: 60,
        ),
      ),
    );
  }
}

class _HomeSection extends StatelessWidget {
  final VoidCallback onReadyLogout;
  final VoidCallback onTapCount;
  final String Function() fullNameGetter;
  final String Function() emailGetter;
  final bool Function() isLoadingGetter;
  final String Function() providerNameGetter;
  final int Function() providerUserCountGetter;
  final List<Map<String, dynamic>> Function() billsGetter;
  final bool Function() billsLoadingGetter;
  final Future<void> Function() onRefresh;
  final bool Function() refreshingGetter;
  final int Function() unreadNotificationCountGetter;
  final VoidCallback loadUnreadCount;

  const _HomeSection({
    super.key,
    required this.onReadyLogout,
    required this.onTapCount,
    required this.fullNameGetter,
    required this.emailGetter,
    required this.isLoadingGetter,
    required this.providerNameGetter,
    required this.providerUserCountGetter,
    required this.billsGetter,
    required this.billsLoadingGetter,
    required this.onRefresh,
    required this.unreadNotificationCountGetter,
    required this.loadUnreadCount,
    required this.refreshingGetter,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = isLoadingGetter();
    final providerName = providerNameGetter();
    final providerUserCount = providerUserCountGetter();
    final bills = billsGetter();
    final billsLoading = billsLoadingGetter();
    final refreshing = refreshingGetter();

    return CurvedHeaderPage(
      title: 'Utility Dashboard',
      titleAlignment: HeaderTitleAlignment.left,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
          tooltip: 'Menu',
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () async {
            final utilityType = _utilityTypeForProvider(providerName);
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => NotificationsPage(utilityType: utilityType)),
            );
            // Reload count after viewing notifications
            loadUnreadCount();
          },
          icon: Badge(
            isLabelVisible: unreadNotificationCountGetter() > 0,
            label: Text('${unreadNotificationCountGetter()}'),
            child: const Icon(Icons.notifications_none, color: Colors.white),
          ),
        ),
        IconButton(
          tooltip: 'Profile',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UtilityProfilePage()),
            );
          },
          icon: const Icon(Icons.person_outline, color: Colors.white),
        ),
        IconButton(
          onPressed: refreshing ? null : onRefresh,
          icon: refreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Refresh',
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _RoundAction(
                  label: 'Users',
                  color: const Color(0xFFFFE082),
                  icon: Icons.group,
                  badge: providerUserCount > 0
                      ? providerUserCount.toString()
                      : null,
                  onTap: onTapCount,
                ),
                _RoundAction(
                  label: 'Bills',
                  color: const Color(0xFF90CAF9),
                  icon: Icons.receipt_long,
                  onTap: () {
                    String? utilityType;
                    switch (providerName.toLowerCase()) {
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
                      case 'wifi':
                        utilityType = 'WiFi';
                        break;
                      case 'dth':
                        utilityType = 'DTH';
                        break;
                      case 'others':
                      case 'other':
                        utilityType = 'Others';
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
                _RoundAction(
                  label: 'Notify',
                  color: const Color(0xFF95A0FF),
                  icon: Icons.notifications_none,
                  badgeCount: unreadNotificationCountGetter(),
                  onTap: () async {
                    String? utilityType;
                    switch (providerName.toLowerCase()) {
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
                      case 'wifi':
                        utilityType = 'WiFi';
                        break;
                      case 'dth':
                        utilityType = 'DTH';
                        break;
                      case 'others':
                      case 'other':
                        utilityType = 'Others';
                        break;
                      default:
                        utilityType = null;
                    }
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NotificationsPage(utilityType: utilityType),
                      ),
                    );
                    // Reload count after viewing notifications
                    loadUnreadCount();
                  },
                ),
                _RoundAction(
                  label: 'Reviews',
                  color: const Color(0xFFA5D6A7),
                  icon: Icons.rate_review_outlined,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => UtilityReviewsPage(
                          providerName: providerName,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Recent Bills section removed as requested
          ],
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  final String? badge;
  final int? badgeCount;

  const _RoundAction({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
    this.onTap,
    this.badge,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    // Use badgeCount if provided, otherwise use badge string
    final showBadge = (badgeCount != null && badgeCount! > 0) || (badge != null && badge!.isNotEmpty);
    final badgeText = badgeCount != null ? '$badgeCount' : (badge ?? '');
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
            ),
            if (showBadge)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
