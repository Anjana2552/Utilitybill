import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/theme_header.dart';
import '../config/api_config.dart';

class AdminBillsListPage extends StatefulWidget {
  final String? restrictedUtilityType; // e.g., 'Electricity', 'Water', 'Gas'
  const AdminBillsListPage({super.key, this.restrictedUtilityType});

  @override
  State<AdminBillsListPage> createState() => _AdminBillsListPageState();
}

class _AdminBillsListPageState extends State<AdminBillsListPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _utilityBills = [];
  bool _filterOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedUtility = 'All Utilities';
  int _selectedMonth = 0; // 0 = All months, 1..12 specific
  final Map<String, double> _paymentsByBill = {}; // bill_id -> total paid
  final Map<String, bool> _hasPendingByBill = {}; // bill_id -> has pending payment

  @override
  void initState() {
    super.initState();
    _fetchBills();
  }

  Future<void> _fetchBills() async {
    setState(() => _loading = true);
    try {
      // Utility bills
      final utilUri = Uri.parse('${ApiConfig.baseUrl}/utility-bill/list/');
      final utilResp = await http.get(
        utilUri,
        headers: {'Content-Type': 'application/json'},
      );
      if (utilResp.statusCode == 200) {
        final obj = jsonDecode(utilResp.body) as Map<String, dynamic>;
        final List<dynamic> results =
            (obj['results'] as List<dynamic>?) ?? const [];
        _utilityBills = results.cast<Map<String, dynamic>>();
        // Apply restriction by utility type if provided
        if (widget.restrictedUtilityType != null && widget.restrictedUtilityType!.isNotEmpty) {
          final restrict = widget.restrictedUtilityType!.toLowerCase();
          _utilityBills = _utilityBills
              .where((e) => (e['utility_type'] ?? '').toString().toLowerCase() == restrict)
              .toList();
        }
      }

      // Fetch approved payments to compute bill status
      try {
        final payUri = Uri.parse('${ApiConfig.baseUrl}/payments/list/?status=approved');
        final payResp = await http.get(
          payUri,
          headers: {'Content-Type': 'application/json'},
        );
        if (payResp.statusCode == 200) {
          final pobj = jsonDecode(payResp.body) as Map<String, dynamic>;
          final List<dynamic> presults =
              (pobj['results'] as List<dynamic>?) ?? const [];
          _paymentsByBill.clear();
          final allowedIds = _utilityBills
              .map((b) => (b['bill_id'] ?? '').toString())
              .where((id) => id.isNotEmpty)
              .toSet();
          for (final p in presults) {
            final bid = (p['bill_id'] ?? '').toString();
            if (bid.isEmpty) continue;
            if (allowedIds.isNotEmpty && !allowedIds.contains(bid)) continue;
            final amtStr = (p['amount'] ?? '0').toString();
            final amt = double.tryParse(amtStr) ?? 0.0;
            _paymentsByBill.update(bid, (v) => v + amt, ifAbsent: () => amt);
          }
        }

        // Fetch pending payments to mark pending status
        final pendUri = Uri.parse('${ApiConfig.baseUrl}/payments/list/?status=pending');
        final pendResp = await http.get(
          pendUri,
          headers: {'Content-Type': 'application/json'},
        );
        if (pendResp.statusCode == 200) {
          final pobj = jsonDecode(pendResp.body) as Map<String, dynamic>;
          final List<dynamic> presults = (pobj['results'] as List<dynamic>?) ?? const [];
          _hasPendingByBill.clear();
          final allowedIds = _utilityBills
              .map((b) => (b['bill_id'] ?? '').toString())
              .where((id) => id.isNotEmpty)
              .toSet();
          for (final p in presults) {
            final bid = (p['bill_id'] ?? '').toString();
            if (bid.isEmpty) continue;
            if (allowedIds.isNotEmpty && !allowedIds.contains(bid)) continue;
            _hasPendingByBill[bid] = true;
          }
        }
      } catch (_) {
        // ignore payments fetch errors
      }

      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearch(String value) {
    setState(() => _searchQuery = value.trim());
  }

  List<String> _utilityTypeOptions() {
    final types = _utilityBills
        .map((e) => (e['utility_type'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return ['All Utilities', ...types];
  }

  String _monthLabel(int m) {
    const names = [
      'All Months',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    if (m < 0 || m > 12) return 'All Months';
    return names[m];
  }

  double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  Widget _statusChipForBill(Map<String, dynamic> bill) {
    final billId = (bill['bill_id'] ?? '').toString();
    final total = _parseAmount(bill['total_amount']);
    final paid = _paymentsByBill[billId] ?? 0.0;
    final hasPending = _hasPendingByBill[billId] == true;
    String label;
    Color color;
    if (total <= 0) {
      if (paid > 0) {
        label = 'Paid';
        color = Colors.green.shade600;
      } else if (hasPending) {
        label = 'Pending';
        color = Colors.orange.shade700;
      } else {
        label = 'Unpaid';
        color = Colors.red.shade600;
      }
    } else if (paid >= total - 0.01) { // allow tiny rounding tolerance
      label = 'Paid';
      color = Colors.green.shade600;
    } else if (paid > 0 && paid < total) {
      label = 'Pending';
      color = Colors.orange.shade700;
    } else if (hasPending) {
      label = 'Pending';
      color = Colors.orange.shade700;
    } else {
      label = 'Unpaid';
      color = Colors.red.shade600;
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

  @override
  Widget build(BuildContext context) {
    // Build filtered list based on current filters
    final displayBills = _utilityBills.where((bill) {
      final matchesText = () {
        if (_searchQuery.isEmpty) return true;
        final q = _searchQuery.toLowerCase();
        final fields = [
          bill['bill_id']?.toString(),
          bill['consumer_name']?.toString(),
          bill['utility_type']?.toString(),
        ];
        return fields
            .where((e) => e != null)
            .map((e) => e!.toLowerCase())
            .any((v) => v.contains(q));
      }();

      final matchesUtility = _selectedUtility == 'All Utilities'
          ? true
          : (bill['utility_type'] ?? '').toString().toLowerCase() ==
              _selectedUtility.toLowerCase();

      final matchesMonth = () {
        if (_selectedMonth == 0) return true;
        final created = bill['created_at']?.toString();
        if (created == null || created.isEmpty) return false;
        final dt = DateTime.tryParse(created);
        if (dt != null) return dt.month == _selectedMonth;
        // Fallback: try to extract month from formats like YYYY-MM or YYYY/MM/DD
        final parts = RegExp(r"\d{4}[-/](\d{1,2})").firstMatch(created);
        if (parts != null) {
          final m = int.tryParse(parts.group(1)!);
          if (m != null) return m == _selectedMonth;
        }
        return false;
      }();

      return matchesText && matchesUtility && matchesMonth;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Utility Bills'),
        backgroundColor: const Color(0xFF7FD9CE),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchBills,
          child: CurvedHeaderPage(
            title: 'Utility Bills',
            headerHeight: 180,
            titleAlignment: HeaderTitleAlignment.left,
            bottomLeft: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _filterOpen
                  ? Container(
                      key: const ValueKey('open'),
                      constraints: const BoxConstraints(maxWidth: 640),
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
                          SizedBox(
                            width: 220,
                            child: TextField(
                              controller: _searchController,
                              onChanged: _updateSearch,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                hintText: 'Search bills',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          DropdownButtonHideUnderline(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black26),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: DropdownButton<String>(
                                value: _utilityTypeOptions().contains(_selectedUtility)
                                    ? _selectedUtility
                                    : 'All Utilities',
                                items: _utilityTypeOptions()
                                    .map((t) => DropdownMenuItem<String>(
                                          value: t,
                                          child: Text(t),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() => _selectedUtility = v);
                                },
                              ),
                            ),
                          ),
                          DropdownButtonHideUnderline(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black26),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: DropdownButton<int>(
                                value: _selectedMonth,
                                items: List.generate(
                                  13,
                                  (i) => DropdownMenuItem<int>(
                                    value: i,
                                    child: Text(_monthLabel(i)),
                                  ),
                                ),
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() => _selectedMonth = v);
                                },
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _selectedUtility = 'All Utilities';
                                _selectedMonth = 0;
                              });
                            },
                          ),
                          IconButton(
                            tooltip: 'Close',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _filterOpen = false;
                                _searchController.clear();
                                _searchQuery = '';
                                _selectedUtility = 'All Utilities';
                                _selectedMonth = 0;
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
                      onPressed: () => setState(() => _filterOpen = true),
                      icon: const Icon(Icons.search),
                      label: const Text('Search / Filter'),
                    ),
            ),
            child: Builder(builder: (context) {
              if (_loading) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: displayBills.length,
                itemBuilder: (context, index) {
                  final bill = displayBills[index];
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
                                Icons.list_alt,
                                color: Color(0xFF4B9A8F),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (bill['bill_id'] ?? '').toString(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      (bill['utility_type'] ?? '').toString(),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _statusChipForBill(bill),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  (bill['consumer_name'] ?? '').toString(),
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
                                Icons.attach_money,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                (bill['total_amount'] ?? '').toString(),
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
                                Icons.calendar_month_outlined,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                (bill['created_at'] ?? '').toString(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
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
            }),
          ),
        ),
      ),
    );
  }
}
