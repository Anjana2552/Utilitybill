import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/theme_header.dart';
import '../../config/api_config.dart';
import 'add_authority_form.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAuthoritiesPage extends StatefulWidget {
  const AdminAuthoritiesPage({super.key});

  @override
  State<AdminAuthoritiesPage> createState() => _AdminAuthoritiesPageState();
}

class _AdminAuthoritiesPageState extends State<AdminAuthoritiesPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _authorities = [];

  @override
  void initState() {
    super.initState();
    _fetchAuthorities();
  }

  String _inferUtilityType(String username) {
    final u = username.toLowerCase();
    if (u.contains('kseb') || u.contains('electric')) return 'Electricity';
    if (u.contains('water')) return 'Water';
    if (u.contains('gas')) return 'Gas';
    if (u.contains('wifi') || u.contains('internet')) return 'Wifi';
    if (u.contains('dth')) return 'DTH';
    return '—';
  }

  Future<void> _fetchAuthorities() async {
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
            if (role != 'utility') continue;
            final user = item['user'] as Map<String, dynamic>?;
            final username = (user?['username'] ?? '').toString();
            final email = (user?['email'] ?? '').toString();
            list.add({
              'name': username.isNotEmpty ? username : 'Authority',
              'utility_type': _inferUtilityType(username),
              'email': email,
              'phone': (item['phone'] ?? '').toString(),
              'address': (item['address'] ?? '').toString(),
            });
          }
        }
        if (!mounted) return;
        setState(() {
          _authorities = list;
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onAdd() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddAuthorityForm()));
  }

  void _onEdit(Map<String, dynamic> auth) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Edit ${auth['name']} coming soon')));
  }

  void _onDelete(Map<String, dynamic> auth) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Authority'),
        content: Text('Are you sure you want to delete ${auth['name']}?'),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Delete not implemented yet')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Authorities'),
        backgroundColor: const Color(0xFF7FD9CE),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAdd,
        backgroundColor: const Color(0xFF34B3A0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BlueGreenHeader(height: 200, title: 'Authorities'),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchAuthorities,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _loading ? 1 : _authorities.length,
                  itemBuilder: (context, index) {
                    if (_loading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final auth = _authorities[index];
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
                                  Icons.account_balance,
                                  color: Color(0xFF34B3A0),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    auth['name']?.toString() ?? 'Authority',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  auth['utility_type']?.toString() ?? '—',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
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
                                    auth['email']?.toString() ?? '',
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
                                  auth['phone']?.toString() ?? '',
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
                                    auth['address']?.toString() ?? '',
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
                                  onPressed: () => _onEdit(auth),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Edit'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _onDelete(auth),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
