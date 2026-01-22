import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/theme_header.dart';
import '../../config/api_config.dart';

class AdminUsersListPage extends StatefulWidget {
  const AdminUsersListPage({super.key});

  @override
  State<AdminUsersListPage> createState() => _AdminUsersListPageState();
}

class _AdminUsersListPageState extends State<AdminUsersListPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _users = [];
  bool _searchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _loading = true);
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
        final List<Map<String, dynamic>> list = [];
        if (data is List) {
          for (final item in data) {
            final role = (item['role'] ?? '').toString().toLowerCase();
            if (role != 'user') continue;
            final user = item['user'] as Map<String, dynamic>?;
            final username = (user?['username'] ?? '').toString();
            final email = (user?['email'] ?? '').toString();
            final isActive = (user?['is_active'] ?? true) == true;
            final fullName = (item['full_name'] ?? '').toString();
            final profileId = (item['id'] ?? 0) as int;
            final userId = (user?['id'] ?? 0) as int;
            list.add({
              'name': fullName.isNotEmpty ? fullName : username,
              'username': username,
              'email': email,
              'phone': (item['phone'] ?? '').toString(),
              'address': (item['address'] ?? '').toString(),
              'profile_id': profileId,
              'user_id': userId,
              'is_active': isActive,
            });
          }
        }
        if (!mounted) return;
        setState(() {
          _users = list;
          _loading = false;
          // Re-apply search if there is an active query
          if (_searchQuery.isNotEmpty) {
            _searchController.text = _searchQuery;
          }
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _updateSearch(String value) {
    setState(() {
      _searchQuery = value.trim();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _setActive(Map<String, dynamic> u, bool active) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/admin/set-user-active/');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': u['user_id'], 'is_active': active}),
      );
      if (resp.statusCode == 200) {
        setState(() {
          u['is_active'] = active;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update active status')),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating active status')),
      );
    }
  }

  Future<void> _editUser(Map<String, dynamic> u) async {
    final nameCtrl = TextEditingController(text: u['name']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: u['email']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: u['phone']?.toString() ?? '');
    final addrCtrl = TextEditingController(
      text: u['address']?.toString() ?? '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextField(
                controller: addrCtrl,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/profiles/${u['profile_id']}/',
      );
      final resp = await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': nameCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'phone': phoneCtrl.text.trim(),
          'address': addrCtrl.text.trim(),
        }),
      );
      if (resp.statusCode == 200) {
        await _fetchUsers();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User updated')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to update user')));
      }
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error updating user')));
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${u['username']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/admin/delete-user/');
      final resp = await http.delete(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': u['user_id']}),
      );
      if (resp.statusCode == 200) {
        await _fetchUsers();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User deleted')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to delete user')));
      }
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error deleting user')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> displayUsers = _searchQuery.isEmpty
        ? _users
        : _users.where((u) {
            final q = _searchQuery.toLowerCase();
            return [
              u['name']?.toString(),
              u['username']?.toString(),
              u['email']?.toString(),
              u['phone']?.toString(),
              u['address']?.toString(),
            ].where((v) => v != null)
                .map((v) => v!.toLowerCase())
                .any((v) => v.contains(q));
          }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: const Color(0xFF7FD9CE),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchUsers,
          child: CurvedHeaderPage(
            title: 'Users',
            headerHeight: 180,
            titleAlignment: HeaderTitleAlignment.left,
            bottomLeft: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _searchOpen
                  ? Container(
                      key: const ValueKey('open'),
                      width: MediaQuery.of(context).size.width * 0.8,
                      constraints: const BoxConstraints(maxWidth: 520),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Color(0xFF34B3A0)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: _updateSearch,
                              decoration: const InputDecoration(
                                hintText: 'Search by name, username, or email',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _updateSearch('');
                            },
                          ),
                          IconButton(
                            tooltip: 'Close',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _searchOpen = false;
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          ),
                        ],
                      ),
                    )
                  : OutlinedButton.icon(
                      key: const ValueKey('closed'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                      ),
                      onPressed: () => setState(() => _searchOpen = true),
                      icon: const Icon(Icons.search),
                      label: const Text('Search Users'),
                    ),
            ),
            child: Builder(
              builder: (context) {
                if (_loading) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: displayUsers.length,
                  itemBuilder: (context, index) {
                    final user = displayUsers[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  color: Color(0xFF34B3A0),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    user['name']?.toString() ?? 'User',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Switch(
                                      value:
                                          (user['is_active'] ?? true) == true,
                                      onChanged: (val) => _setActive(user, val),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      user['username']?.toString() ?? '',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.email_outlined,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    user['email']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone_outlined,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  user['phone']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    user['address']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _editUser(user),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Edit'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _deleteUser(user),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                  label: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
