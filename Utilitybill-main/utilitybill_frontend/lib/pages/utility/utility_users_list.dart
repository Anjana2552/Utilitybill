import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

class UtilityUsersListPage extends StatefulWidget {
  final String providerName;

  const UtilityUsersListPage({super.key, required this.providerName});

  @override
  State<UtilityUsersListPage> createState() => _UtilityUsersListPageState();
}

class _UtilityUsersListPageState extends State<UtilityUsersListPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/user-utility/list/?provider_name=${Uri.encodeQueryComponent(widget.providerName)}',
      );
      final resp = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final results = (body['results'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

        // Sort by user_name, fallback by id
        results.sort(
          (a, b) => (a['user_name'] ?? '').toString().toLowerCase().compareTo(
            (b['user_name'] ?? '').toString().toLowerCase(),
          ),
        );

        if (!mounted) return;
        setState(() {
          _entries = results;
          _loading = false;
        });
      } else {
        throw Exception('HTTP ${resp.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = '${widget.providerName.toUpperCase()} Users';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              )
            : _entries.isEmpty
            ? ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No users found for this provider.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                itemCount: _entries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _entries[index];
                  final userName = (item['user_name']?.toString() ?? '').trim();
                  final displayName = userName.isEmpty
                      ? 'User #${item['user'] ?? '?'}'
                      : userName;
                  final consumerNumber =
                      (item['consumer_number']?.toString() ?? '').trim();
                  final meterNumber = (item['meter_number']?.toString() ?? '')
                      .trim();

                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE8F6F4),
                      child: Icon(Icons.person, color: Color(0xFF34B3A0)),
                    ),
                    title: Text(displayName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (consumerNumber.isNotEmpty)
                          Text('Consumer: $consumerNumber'),
                        if (meterNumber.isNotEmpty) Text('Meter: $meterNumber'),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
