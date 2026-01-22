import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/theme_header.dart';
import '../../config/api_config.dart';

class AdminPaymentRequestPage extends StatefulWidget {
  const AdminPaymentRequestPage({super.key});

  @override
  State<AdminPaymentRequestPage> createState() => _AdminPaymentRequestPageState();
}

class _AdminPaymentRequestPageState extends State<AdminPaymentRequestPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _pendingPayments = [];
  Map<String, Map<String, dynamic>> _billById = {}; // bill_id -> bill
  

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      // Fetch pending payments
      final payUri = Uri.parse('${ApiConfig.baseUrl}/payments/list/?status=pending');
      final payResp = await http.get(payUri, headers: {'Content-Type': 'application/json'});
      if (payResp.statusCode == 200) {
        final obj = jsonDecode(payResp.body) as Map<String, dynamic>;
        final List<dynamic> results = (obj['results'] as List<dynamic>?) ?? const [];
        _pendingPayments = results.cast<Map<String, dynamic>>();
      }

      // Fetch utility bills to enrich payment display
      final utilUri = Uri.parse('${ApiConfig.baseUrl}/utility-bill/list/');
      final utilResp = await http.get(utilUri, headers: {'Content-Type': 'application/json'});
      if (utilResp.statusCode == 200) {
        final uobj = jsonDecode(utilResp.body) as Map<String, dynamic>;
        final List<dynamic> uresults = (uobj['results'] as List<dynamic>?) ?? const [];
        _billById.clear();
        for (final b in uresults) {
          final bid = (b['bill_id'] ?? '').toString();
          if (bid.isNotEmpty) _billById[bid] = b as Map<String, dynamic>;
        }
      }

      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _updatePaymentStatus(dynamic id, bool approve) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/${approve ? 'payments/approve/' : 'payments/reject/'}');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show all pending payments without filters
    final filtered = _pendingPayments;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Payment Request'),
        backgroundColor: const Color(0xFF7FD9CE),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          child: CurvedHeaderPage(
            headerHeight: 160,
            titleAlignment: HeaderTitleAlignment.left,
            bottomLeft: const SizedBox.shrink(),
            child: Builder(builder: (context) {
              if (_loading) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (filtered.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No pending payment requests'),
                );
              }
              return ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final p = filtered[index];
                  final billId = (p['bill_id'] ?? '').toString();
                  final bill = _billById[billId];
                  final consumerName = (bill?['consumer_name'] ?? '').toString();
                  final utilityType = (bill?['utility_type'] ?? '').toString();

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.list_alt, color: Color(0xFF4B9A8F)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      billId,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      utilityType.isEmpty ? 'Utility' : utilityType,
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade700.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange.shade700.withOpacity(0.5)),
                                ),
                                child: Text(
                                  'Pending',
                                  style: TextStyle(color: Colors.orange.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (consumerName.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Expanded(child: Text(consumerName, style: const TextStyle(fontSize: 13))),
                              ],
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text((p['amount'] ?? '').toString(), style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_outlined, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text((p['payment_date'] ?? '').toString(), style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () async {
                                  final ok = await _updatePaymentStatus(p['id'], true);
                                  if (!mounted) return;
                                  if (ok) {
                                    setState(() {
                                      _pendingPayments.removeWhere((e) => e['id'] == p['id']);
                                    });
                                  }
                                },
                                icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                label: const Text('Approve', style: TextStyle(color: Colors.green)),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () async {
                                  final ok = await _updatePaymentStatus(p['id'], false);
                                  if (!mounted) return;
                                  if (ok) {
                                    setState(() {
                                      _pendingPayments.removeWhere((e) => e['id'] == p['id']);
                                    });
                                  }
                                },
                                icon: const Icon(Icons.highlight_off, color: Colors.redAccent),
                                label: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}
