import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/theme_header.dart';
import '../../config/api_config.dart';
import 'add_bill_page.dart';

class ViewBillsPage extends StatefulWidget {
  const ViewBillsPage({super.key});

  @override
  State<ViewBillsPage> createState() => _ViewBillsPageState();
}

class _ViewBillsPageState extends State<ViewBillsPage> {
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      _userName = prefs.getString('full_name') ?? prefs.getString('user_username') ?? '';
      final uri = Uri.parse('${ApiConfig.baseUrl}/user-utility/list/?user_name=${Uri.encodeQueryComponent(_userName)}');
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        setState(() {
          _items = (data['results'] as List<dynamic>?) ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load: ${resp.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CurvedHeaderPage(
        title: 'My Bill',
        headerHeight: 180,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Reload',
            onPressed: _load,
          ),
        ],
        titleAlignment: HeaderTitleAlignment.left,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)));
    }
    if (_items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Center(child: Text('No bills found')),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final it = _items[i] as Map<String, dynamic>;
            final utilityType = (it['utility_type'] ?? '') as String;
            final provider = (it['provider_name'] ?? '') as String;
            final createdAt = (it['created_at'] ?? '') as String;
            final when = _formatDate(createdAt);
            final subtitle = _buildSubtitle(it);
            final icon = _iconForUtility(utilityType);
            final gradient = _gradientForUtility(utilityType);
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(icon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$utilityType • $provider',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              when,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20, color: Colors.white),
                                  tooltip: 'Edit',
                                  onPressed: () => _editItem(it),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.white),
                                  tooltip: 'Delete',
                                  onPressed: () => _confirmDelete(it),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _editItem(Map<String, dynamic> it) async {
    final res = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddBillPage(initial: it, recordId: it['id'] as int?),
      ),
    );
    if (res != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updated')),
      );
      await _load();
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> it) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete bill?'),
        content: const Text('This will permanently delete the record.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await _deleteItem(it['id'] as int?);
    }
  }

  Future<void> _deleteItem(int? id) async {
    if (id == null) return;
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/user-utility/$id/');
      final resp = await http.delete(uri);
      if (resp.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
        await _load();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: ${resp.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  String _buildSubtitle(Map<String, dynamic> it) {
    final b = StringBuffer();
    void add(String label, String? value) {
      if (value != null && value.isNotEmpty) {
        if (b.isNotEmpty) b.write(' • ');
        b.write('$label: $value');
      }
    }
    add('Connection', it['connection_type'] as String?);
    add('Consumer', it['consumer_number'] as String?);
    add('Water', it['water_connection_number'] as String?);
    add('Gas', it['gas_connection_number'] as String?);
    add('Wifi', it['wifi_consumer_id'] as String?);
    add('DTH', it['dth_subscriber_id'] as String?);
    add('Plan', it['plan_name'] as String?);
    add('Meter', it['meter_number'] as String?);
    return b.toString();
  }

  IconData _iconForUtility(String t) {
    switch (t.toLowerCase()) {
      case 'electricity':
        return Icons.electric_bolt_outlined;
      case 'water':
        return Icons.water_drop_outlined;
      case 'gas':
        return Icons.local_gas_station_outlined;
      case 'wifi':
        return Icons.wifi;
      case 'dth':
        return Icons.tv_outlined;
      default:
        return Icons.receipt_long;
    }
  }

  List<Color> _gradientForUtility(String t) {
    switch (t.toLowerCase()) {
      case 'electricity':
        return const [Color(0xFFF06292), Color(0xFFBA68C8)]; // pink -> purple
      case 'water':
        return const [Color(0xFF4DD0E1), Color(0xFF1E88E5)]; // teal -> blue
      case 'gas':
        return const [Color(0xFFFFA726), Color(0xFFF4511E)]; // orange -> deep orange
      case 'wifi':
        return const [Color(0xFF7E57C2), Color(0xFF5E35B1)]; // indigo -> deep purple
      case 'dth':
        return const [Color(0xFFAB47BC), Color(0xFF8E24AA)]; // purple shades
      default:
        return const [Color(0xFF90A4AE), Color(0xFF607D8B)]; // blue grey
    }
  }
}