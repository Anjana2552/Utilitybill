import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';
import 'user_profile.dart';

class ChatPage extends StatefulWidget {
  final bool showBottomNav;
  final bool showHeaderBack;
  // Authority mode shows a list of users for a specific provider/utility
  final bool authorityMode;
  final String? providerName;
  const ChatPage({
    super.key,
    this.showBottomNav = true,
    this.showHeaderBack = true,
    this.authorityMode = false,
    this.providerName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // Loading and authority selection state
  bool _loading = true;
  String? _error;
  List<_Authority> _authorities = const [];
  _Authority? _active;
  String _myRole = 'user';
  String _username = '';

  // Per-authority message threads
  final Map<String, List<_Message>> _threads = <String, List<_Message>>{};
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadAuthorities();
  }

  Future<void> _loadAuthorities() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = (prefs.getString('user_role') ?? '').toLowerCase();
      final username = prefs.getString('user_username') ?? '';
      _myRole = role.isNotEmpty ? role : 'user';
      _username = username;
      if (username.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Missing user. Please login again.';
        });
        return;
      }

      Uri uri;
      String? restrictType;
      if (widget.authorityMode || role == 'utility') {
        // Determine provider and utility type
        final p = (widget.providerName ?? '').toLowerCase();
        String provider = p.isNotEmpty
            ? p
            : _inferProviderFromUsername(username);
        restrictType = _mapProviderToUtilityType(provider);
        final base = Uri.parse('${ApiConfig.baseUrl}/user-utility/list/');
        // Prefer server-side filtering by utility_type for accuracy
        if (restrictType.isNotEmpty) {
          uri = base.replace(queryParameters: {'utility_type': restrictType});
        } else {
          // Fallback to provider_name if type inference failed
          uri = base.replace(queryParameters: {'provider_name': provider});
        }
      } else {
        uri = Uri.parse(
          '${ApiConfig.baseUrl}/user-utility/list/?user_name=${Uri.encodeQueryComponent(username)}',
        );
      }
      final resp = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      if (resp.statusCode != 200) {
        setState(() {
          _loading = false;
          _error = 'Failed to load: ${resp.statusCode}';
        });
        return;
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = (data['results'] as List<dynamic>?) ?? const [];

      final seen = <String>{};
      final list = <_Authority>[];
      if (widget.authorityMode || role == 'utility') {
        // For authorities: show distinct users who have this provider/type
        for (final raw in results) {
          final m = (raw as Map<String, dynamic>);
          final type = (m['utility_type'] ?? '').toString();
          if (restrictType != null && restrictType.isNotEmpty) {
            if (type.toLowerCase() != restrictType.toLowerCase()) continue;
          }
          String pick(Map<String, dynamic> m, String key) =>
              (m[key]?.toString() ?? '').trim();
          String norm(String s) => s.trim();
          bool isGeneric(String s) =>
              s.isEmpty ||
              s.toLowerCase() == 'user' ||
              s.toLowerCase() == 'unknown';
          final uname = [
            pick(m, 'user_name'),
            pick(m, 'username'),
            pick(m, 'user_username'),
            pick(m, 'email'),
          ].firstWhere((s) => s.isNotEmpty, orElse: () => '');
          final candidates = <String>[
            pick(m, 'full_name'),
            pick(m, 'user_name'),
            pick(m, 'username'),
            pick(m, 'user_username'),
            pick(m, 'name'),
            pick(m, 'email'),
          ].map(norm).toList();
          String display = candidates.firstWhere(
            (s) => !isGeneric(s),
            orElse: () => uname,
          );
          if (uname.isEmpty) continue;
          if (seen.add(uname)) {
            list.add(_Authority(key: uname, title: display, utilityType: type));
          }
        }
      } else {
        // For users: list authorities/providers
        for (final raw in results) {
          final m = (raw as Map<String, dynamic>);
          final type = (m['utility_type'] ?? '').toString();
          final provider = (m['provider_name'] ?? '').toString();
          final key = (provider.isNotEmpty ? provider : type).trim();
          if (key.isEmpty) continue;
          if (seen.add(key)) {
            list.add(_Authority(key: key, title: key, utilityType: type));
          }
        }
      }

      // If exactly one authority, auto-select (no system welcome message)
      if (list.length == 1) {
        final a = list.first;
        _threads.putIfAbsent(a.key, () => <_Message>[]);
        setState(() {
          _authorities = list;
          _active = a;
          _loading = false;
        });
        await _loadThread(a);
      } else {
        setState(() {
          _authorities = list;
          _loading = false;
        });
        // Load unread counts
        await _loadUnreadCounts();
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Error: $e';
      });
    }
  }

  Future<void> _loadUnreadCounts() async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/chat/unread-counts/?username=${Uri.encodeQueryComponent(_username)}&role=${Uri.encodeQueryComponent(_myRole)}',
      );
      final resp = await http.get(uri, headers: {'Content-Type': 'application/json'});
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final unreadList = (data['unread_counts'] as List<dynamic>?) ?? [];
        final Map<String, int> unreadMap = {};
        for (final item in unreadList) {
          final m = item as Map<String, dynamic>;
          final key = (m['key'] ?? '').toString();
          final count = (m['unread_count'] ?? 0) as int;
          unreadMap[key] = count;
        }
        
        // Update authorities with unread counts
        setState(() {
          _authorities = _authorities.map((a) {
            final unread = unreadMap[a.key] ?? 0;
            return _Authority(
              key: a.key,
              title: a.title,
              utilityType: a.utilityType,
              unreadCount: unread,
            );
          }).toList();
        });
      }
    } catch (e) {
      // Silently fail - unread counts are not critical
      print('Failed to load unread counts: $e');
    }
  }

  String _inferProviderFromUsername(String username) {
    final u = username.toLowerCase();
    if (u.contains('kseb')) return 'kseb';
    if (u.contains('kwa') || u.contains('water')) return 'water';
    if (u.contains('gas')) return 'gas';
    if (u.contains('wifi')) return 'wifi';
    if (u.contains('dth')) return 'dth';
    if (u.contains('other') || u.contains('others')) return 'others';
    return '';
  }

  String _mapProviderToUtilityType(String provider) {
    final p = provider.toLowerCase();
    if (p == 'kseb') return 'Electricity';
    if (p == 'water' || p == 'kwa') return 'Water';
    if (p == 'gas') return 'Gas';
    if (p == 'wifi') return 'Wifi';
    if (p == 'dth') return 'DTH';
    if (p == 'others' || p == 'other') return 'Others';
    return '';
  }

  void _openAuthority(_Authority a) {
    setState(() {
      _active = a;
      _threads.putIfAbsent(a.key, () => <_Message>[]);
      // Reset unread count when opening
      _authorities = _authorities.map((auth) {
        if (auth.key == a.key) {
          return _Authority(
            key: auth.key,
            title: auth.title,
            utilityType: auth.utilityType,
            unreadCount: 0,
          );
        }
        return auth;
      }).toList();
    });
    _loadThread(a);
  }

  String _providerFor(_Authority a) {
    // Prefer explicit providerName in authority mode
    final p = (widget.providerName ?? '').trim();
    if (p.isNotEmpty) return p;
    return a.key; // in user mode key is provider or type
  }

  Future<void> _loadThread(_Authority a) async {
    final provider = _providerFor(a);
    // In authority mode (or when logged-in role is utility), the conversation's
    // user_name should be the selected user's username (a.key). Otherwise,
    // for regular users, it's the logged-in username.
    final convoUserName =
        (widget.authorityMode || _myRole.toLowerCase() == 'utility')
        ? a.key
        : _username;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/chat/thread/?user_name=${Uri.encodeQueryComponent(convoUserName)}&provider_name=${Uri.encodeQueryComponent(provider)}',
      );
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Token $token';
      }
      final resp = await http.get(uri, headers: headers);
      if (resp.statusCode != 200) return;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = (data['results'] as List<dynamic>?) ?? const [];
      final thread = <_Message>[];
      for (final raw in results) {
        final m = raw as Map<String, dynamic>;
        final text = (m['text'] ?? '').toString();
        final role = (m['sender_role'] ?? '').toString();
        final fromMe = role.toLowerCase() == _myRole.toLowerCase();
        if (text.isNotEmpty) thread.add(_Message(text: text, fromMe: fromMe));
      }
      setState(() {
        _threads[a.key] = thread;
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _active == null) return;
    setState(() {
      _sending = true;
    });
    final a = _active;
    if (a == null) {
      if (mounted) setState(() => _sending = false);
      return;
    }
    final provider = _providerFor(a);
    // Target user name is the selected user in authority mode/utility role,
    // otherwise the logged-in user.
    final convoUserName =
        (widget.authorityMode || _myRole.toLowerCase() == 'utility')
        ? a.key
        : _username;
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/chat/send/');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Token $token';
      }
      final resp = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'user_name': convoUserName,
          'provider_name': provider,
          'text': text,
        }),
      );
      if (resp.statusCode == 201) {
        // Append to thread and clear
        final thread = _threads[a.key] ??= <_Message>[];
        thread.add(_Message(text: text, fromMe: true));
        _controller.clear();
        // Reload thread to include any responses
        await _loadThread(a);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    if (_loading) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        ),
      );
    } else if (_active == null) {
      // Show authority list
      bodyContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_authorities.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                (widget.authorityMode
                    ? 'No users found for chat.'
                    : 'No utilities found for chat.'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _authorities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final a = _authorities[i];

                // If the list is all the same utility type (e.g., authority mode),
                // cycle through a palette so each row gets a distinct color.
                final allTypes = _authorities
                    .map((e) => (e.utilityType).toLowerCase())
                    .toSet();
                final uniformType = allTypes.length == 1;

                List<Color>? colors;
                if (uniformType) {
                  const palette = [
                    [Color(0xFFF06292), Color(0xFFBA68C8)], // pink->purple
                    [Color(0xFF4DD0E1), Color(0xFF00796B)], // teal shades
                    [
                      Color(0xFFFFA726),
                      Color(0xFFF4511E),
                    ], // orange->deep orange
                    [
                      Color(0xFF7E57C2),
                      Color(0xFF5E35B1),
                    ], // indigo->deep purple
                    [Color(0xFFAB47BC), Color(0xFF8E24AA)], // purple shades
                    [Color(0xFF66BB6A), Color(0xFF2E7D32)], // green shades
                    [Color(0xFF42A5F5), Color(0xFF1565C0)], // blue shades
                  ];
                  colors = palette[i % palette.length];
                }

                return _AuthorityTile(
                  authority: a,
                  onTap: () => _openAuthority(a),
                  gradientColors: colors, // null => use utility-based mapping
                );
              },
            ),
        ],
      );
    } else {
      final a = _active;
      if (a == null) {
        bodyContent = const SizedBox.shrink();
      } else {
        bodyContent = _ConversationView(
          title: a.title,
          thread: _threads[a.key] ?? const <_Message>[],
          controller: _controller,
          sending: _sending,
          onBack: () => setState(() => _active = null),
          onSend: _send,
        );
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _active == null
          ? AppBar(
              title: const Text('Chat'),
              leading: widget.showHeaderBack
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).maybePop(),
                      tooltip: 'Back',
                    )
                  : null,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reload',
                  onPressed: _loadAuthorities,
                ),
              ],
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: bodyContent,
      ),
      bottomNavigationBar: widget.showBottomNav
          ? CurvedNavigationBar(
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
                  Icons.chat_bubble_outline,
                  size: 26,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                Icon(
                  Icons.person,
                  size: 26,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ],
              index: 2,
              color: Theme.of(context).colorScheme.primary,
              buttonBackgroundColor: Theme.of(
                context,
              ).colorScheme.primaryContainer,
              backgroundColor: Theme.of(context).colorScheme.surface,
              animationCurve: Curves.easeInOut,
              animationDuration: const Duration(milliseconds: 300),
              onTap: (index) {
                if (index == 0) {
                  Navigator.pushReplacementNamed(context, '/home');
                  return;
                }
                if (index == 1) {
                  Navigator.pushNamed(context, '/user/bill_payment');
                  return;
                }
                if (index == 3) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const UserProfilePage()),
                  );
                  return;
                }
                // index==2 stays on chat
              },
            )
          : null,
    );
  }
}

/// Conversation view styled similar to modern chat UIs.
class _ConversationView extends StatelessWidget {
  final String title;
  final List<_Message> thread;
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onBack;
  final Future<void> Function() onSend;

  const _ConversationView({
    required this.title,
    required this.thread,
    required this.controller,
    required this.sending,
    required this.onBack,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    const gradStart = Color(0xFF7E57C2); // indigo
    const gradEnd = Color(0xFF5E35B1); // deep purple
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [gradStart, gradEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top bar with back + title (no call/video)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: onBack,
                  ),
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.account_circle, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          'Online',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: Colors.white70),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                reverse: true,
                itemCount: thread.length,
                itemBuilder: (context, index) {
                  final msg = thread[thread.length - 1 - index];
                  final align = msg.fromMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft;
                  final bubbleColor = msg.fromMe
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.18);
                  final textColor = msg.fromMe ? Colors.black87 : Colors.white;
                  return Align(
                    alignment: align,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(color: textColor, fontSize: 14),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Input bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: TextField(
                        controller: controller,
                        style: const TextStyle(
                          color: Color(0xFF2D3142),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(
                            color: Color(0xFF7B7B8B),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: sending ? null : () => onSend(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send, color: Color(0xFF5E35B1)),
                      ),
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

class _Message {
  final String text;
  final bool fromMe;
  const _Message({required this.text, required this.fromMe});
}

class _Authority {
  final String key;
  final String title;
  final String utilityType;
  final int unreadCount;
  const _Authority({
    required this.key,
    required this.title,
    required this.utilityType,
    this.unreadCount = 0,
  });
}

class _AuthorityTile extends StatelessWidget {
  final _Authority authority;
  final VoidCallback onTap;
  final List<Color>? gradientColors;
  const _AuthorityTile({
    required this.authority,
    required this.onTap,
    this.gradientColors,
  });

  IconData _iconFor(String t, String title) {
    final lower = t.toLowerCase();
    if (title.toLowerCase().contains('kseb') || lower == 'electricity') {
      return Icons.electric_bolt_outlined;
    }
    if (title.toLowerCase().contains('kwa') || lower == 'water') {
      return Icons.water_drop_outlined;
    }
    if (lower == 'gas') return Icons.local_gas_station_outlined;
    if (lower == 'wifi' || lower == 'internet') return Icons.wifi;
    if (lower == 'dth') return Icons.tv_outlined;
    return Icons.account_balance_outlined;
  }

  List<Color> _gradientForUtility(String t) {
    switch (t.toLowerCase()) {
      case 'electricity':
        return const [Color(0xFFF06292), Color(0xFFBA68C8)]; // pink -> purple
      case 'water':
        return const [Color(0xFF4DD0E1), Color(0xFF00796B)]; // teal shades
      case 'gas':
        return const [
          Color(0xFFFFA726),
          Color(0xFFF4511E),
        ]; // orange -> deep orange
      case 'wifi':
        return const [
          Color(0xFF7E57C2),
          Color(0xFF5E35B1),
        ]; // indigo -> deep purple
      case 'dth':
        return const [Color(0xFFAB47BC), Color(0xFF8E24AA)]; // purple shades
      default:
        return const [Color(0xFF90A4AE), Color(0xFF607D8B)]; // blue grey
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _iconFor(authority.utilityType, authority.title);
    final gradient =
        gradientColors ?? _gradientForUtility(authority.utilityType);
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          leading: Container(
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white),
          ),
          title: Text(
            authority.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            authority.utilityType.isEmpty ? 'Utility' : authority.utilityType,
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (authority.unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    authority.unreadCount > 99 ? '99+' : '${authority.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
