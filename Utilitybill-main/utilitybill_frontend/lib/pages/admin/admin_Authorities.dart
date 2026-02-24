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
    if (u.contains('wifi') || u.contains('internet')) return 'WiFi';
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
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Authorities'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAdd,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchAuthorities,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _authorities.length,
                  itemBuilder: (context, index) {
                    final auth = _authorities[index];
                    final name = auth['name']?.toString() ?? 'Authority';
                    final initials = name.isNotEmpty
                        ? name.split(' ').map((e) => e[0]).join()
                        : 'A';
                    final utilityType = auth['utility_type']?.toString() ?? '—';
                    
                    final colors = [
                      const Color(0xFF9C7DFF),
                      const Color(0xFF5DADE2),
                      const Color(0xFF52D4A4),
                      const Color(0xFFFFA500),
                      const Color(0xFFFF6B9D),
                    ];
                    final avatarColor = colors[index % colors.length];
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: avatarColor,
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                  child: Center(
                                    child: Text(
                                      initials.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2D3142),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        auth['email']?.toString() ?? '',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: avatarColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    utilityType,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: avatarColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _onEdit(auth),
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  label: const Text('Edit'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _onDelete(auth),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
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
    );
  }
}
