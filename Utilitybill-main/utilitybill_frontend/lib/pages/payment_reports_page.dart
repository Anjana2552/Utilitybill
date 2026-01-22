import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/theme_header.dart';
import '../config/api_config.dart';

class AdminPaymentReportsPage extends StatefulWidget {
  final String? initialStatus; // e.g., 'pending', 'approved', 'rejected'
  final String? restrictedUtilityType; // e.g., 'Electricity', 'Water'
  const AdminPaymentReportsPage({super.key, this.initialStatus, this.restrictedUtilityType});

  @override
  State<AdminPaymentReportsPage> createState() =>
      _AdminPaymentReportsPageState();
}

class _AdminPaymentReportsPageState extends State<AdminPaymentReportsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _utilityBills = [];
  final Map<String, double> _paymentsByBill = {}; // bill_id -> total paid
  double _totalCollected = 0.0;
  bool _filterOpen = false;
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatus;
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      // Fetch payments
      final payUri = Uri.parse(
          '${ApiConfig.baseUrl}/payments/list/${_statusFilter != null ? '?status=${_statusFilter}' : ''}');
      final payResp = await http.get(
        payUri,
        headers: {'Content-Type': 'application/json'},
      );
      if (payResp.statusCode == 200) {
        final obj = jsonDecode(payResp.body) as Map<String, dynamic>;
        final List<dynamic> results =
            (obj['results'] as List<dynamic>?) ?? const [];
        _payments = results.cast<Map<String, dynamic>>();
      }

      // Fetch utility bills for pending computation
      final utilUri = Uri.parse('${ApiConfig.baseUrl}/utility-bill/list/');
      final utilResp = await http.get(
        utilUri,
        headers: {'Content-Type': 'application/json'},
      );
      if (utilResp.statusCode == 200) {
        final uobj = jsonDecode(utilResp.body) as Map<String, dynamic>;
        final List<dynamic> uresults =
            (uobj['results'] as List<dynamic>?) ?? const [];
        _utilityBills = uresults.cast<Map<String, dynamic>>();
      }

      // If restricted by utility type (authority view), filter bills and payments
      if (widget.restrictedUtilityType != null && widget.restrictedUtilityType!.isNotEmpty) {
        final String restrict = widget.restrictedUtilityType!.toLowerCase();
        _utilityBills = _utilityBills.where((b) => (b['utility_type'] ?? '').toString().toLowerCase() == restrict).toList();
        final Set<String> allowedBillIds = _utilityBills.map((b) => (b['bill_id'] ?? '').toString()).where((id) => id.isNotEmpty).toSet();
        _payments = _payments.where((p) => allowedBillIds.contains((p['bill_id'] ?? '').toString())).toList();
      }

      // Recompute totals after any filtering
      _paymentsByBill.clear();
      double total = 0.0;
      for (final p in _payments) {
        final bid = (p['bill_id'] ?? '').toString();
        final amt = double.tryParse((p['amount'] ?? '0').toString()) ?? 0.0;
        total += amt;
        if (bid.isNotEmpty) {
          _paymentsByBill.update(bid, (v) => v + amt, ifAbsent: () => amt);
        }
      }
      _totalCollected = total;

      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    final dt = DateTime.tryParse(s);
    return dt;
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return 'Select';
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 5);
    final last = DateTime(now.year + 1, 12, 31);
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? now,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      setState(() => _fromDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 5);
    final last = DateTime(now.year + 1, 12, 31);
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate ?? now,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      setState(() => _toDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59));
    }
  }

  List<Map<String, dynamic>> _pendingBills() {
    final List<Map<String, dynamic>> list = [];
    for (final bill in _utilityBills) {
      final billId = (bill['bill_id'] ?? '').toString();
      if (billId.isEmpty) continue;
      final total = _parseAmount(bill['total_amount']);
      final paid = _paymentsByBill[billId] ?? 0.0;
      if (total > 0 && paid < total - 0.01) {
        list.add({
          'bill_id': billId,
          'consumer_name': (bill['consumer_name'] ?? '').toString(),
          'utility_type': (bill['utility_type'] ?? '').toString(),
          'due': (total - paid),
        });
      } else if (total <= 0 && paid == 0.0) {
        // If total unknown/zero and no payment, consider as unpaid
        list.add({
          'bill_id': billId,
          'consumer_name': (bill['consumer_name'] ?? '').toString(),
          'utility_type': (bill['utility_type'] ?? '').toString(),
          'due': 0.0,
        });
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pendingBills();
    // Apply date filter to payments
    final filteredPayments = _payments.where((p) {
      final dt = _parseDate(p['payment_date']);
      if (dt == null) return false;
      if (_fromDate != null && dt.isBefore(_fromDate!)) return false;
      if (_toDate != null && dt.isAfter(_toDate!)) return false;
      return true;
    }).toList();
    final filteredTotal = filteredPayments.fold<double>(0.0, (sum, p) => sum + _parseAmount(p['amount']));
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Payment Reports'),
        backgroundColor: const Color(0xFF7FD9CE),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchData,
          child: CurvedHeaderPage(
            headerHeight: 180,
            titleAlignment: HeaderTitleAlignment.left,
            bottomLeft: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _filterOpen
                  ? Container(
                      key: const ValueKey('open'),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.payments, color: Colors.black87),
                              const SizedBox(width: 6),
                              Text(
                                'Total: ${filteredTotal.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: _pickFromDate,
                            icon: const Icon(Icons.date_range),
                            label: Text('From: ${_fmtDate(_fromDate)}'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _pickToDate,
                            icon: const Icon(Icons.event),
                            label: Text('To: ${_fmtDate(_toDate)}'),
                          ),
                          IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _fromDate = null;
                                _toDate = null;
                              });
                            },
                          ),
                          IconButton(
                            tooltip: 'Close',
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _filterOpen = false),
                          ),
                        ],
                      ),
                    )
                  : Row(
                      key: const ValueKey('closed'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.payments, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Total Collected: ${_totalCollected.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                          ),
                          onPressed: () => setState(() => _filterOpen = true),
                          icon: const Icon(Icons.search),
                          label: const Text('Date Filter'),
                        ),
                      ],
                    ),
            ),
            child: Builder(builder: (context) {
              if (_loading) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Pending Payments',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (pending.isEmpty)
                    const Text('No pending payments')
                  else
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: pending.length,
                      itemBuilder: (context, index) {
                        final it = pending[index];
                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.person_outline, color: Color(0xFF4B9A8F)),
                            title: Text(it['consumer_name'].toString().isEmpty ? 'User' : it['consumer_name']),
                            subtitle: Text('Bill: ${it['bill_id']} • ${it['utility_type']}'),
                            trailing: (it['due'] as double) > 0
                                ? Text(
                                    'Due: ${(it['due'] as double).toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                                  )
                                : const Text('Unpaid', style: TextStyle(color: Colors.redAccent)),
                          ),
                        );
                      },
                    ),
                  // const SizedBox(height: 16),
                  // const Text(
                  //   'Payments',
                  //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  // ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: filteredPayments.length,
                    itemBuilder: (context, index) {
                      final p = filteredPayments[index];
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
                                    Icons.payments_outlined,
                                    color: Color(0xFF4B9A8F),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      (p['bill_id'] ?? '').toString(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _PaymentStatusChip(status: (p['status'] ?? 'pending').toString()),
                                      const SizedBox(width: 8),
                                      Text(
                                        (p['amount'] ?? '').toString(),
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
                                    Icons.calendar_month_outlined,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    (p['payment_date'] ?? '').toString(),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.receipt_long,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    (p['payment_method'] ?? '').toString(),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if ((p['status'] ?? 'pending') == 'pending')
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () async {
                                        final ok = await _updatePaymentStatus(p['id'], true);
                                        if (ok && mounted) setState(() { p['status'] = 'approved'; });
                                      },
                                      icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                      label: const Text('Approve', style: TextStyle(color: Colors.green)),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: () async {
                                        final ok = await _updatePaymentStatus(p['id'], false);
                                        if (ok && mounted) setState(() { p['status'] = 'rejected'; });
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
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _PaymentStatusChip extends StatelessWidget {
  final String status;
  const _PaymentStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green.shade600;
        label = 'Approved';
        break;
      case 'rejected':
        color = Colors.red.shade600;
        label = 'Rejected';
        break;
      default:
        color = Colors.orange.shade700;
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
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
