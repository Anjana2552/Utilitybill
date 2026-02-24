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
  final Map<String, bool> _hasPendingByBill =
      {}; // bill_id -> has pending payment

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
        if (widget.restrictedUtilityType != null &&
            widget.restrictedUtilityType!.isNotEmpty) {
          final restrict = widget.restrictedUtilityType!.toLowerCase();
          _utilityBills = _utilityBills
              .where(
                (e) =>
                    (e['utility_type'] ?? '').toString().toLowerCase() ==
                    restrict,
              )
              .toList();
        }
      }

      // Fetch approved payments to compute bill status
      try {
        final payUri = Uri.parse(
          '${ApiConfig.baseUrl}/payments/list/?status=approved',
        );
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
        final pendUri = Uri.parse(
          '${ApiConfig.baseUrl}/payments/list/?status=pending',
        );
        final pendResp = await http.get(
          pendUri,
          headers: {'Content-Type': 'application/json'},
        );
        if (pendResp.statusCode == 200) {
          final pobj = jsonDecode(pendResp.body) as Map<String, dynamic>;
          final List<dynamic> presults =
              (pobj['results'] as List<dynamic>?) ?? const [];
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
    final types =
        _utilityBills
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
    } else if (paid >= total - 0.01) {
      // allow tiny rounding tolerance
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ----- Gradient pill helpers for consistent colorful tiles -----
  static const List<List<Color>> _pillPalettes = [
    [Color(0xFF4FACFE), Color(0xFF00F2FE)], // blue → cyan
    [Color(0xFF36D1DC), Color(0xFF5B86E5)], // teal → blue
    [Color(0xFFFF9966), Color(0xFFFF5E62)], // orange → red
    [Color(0xFF9D50BB), Color(0xFF6E48AA)], // purple
    [Color(0xFF43CEA2), Color(0xFF185A9D)], // green → navy
    [Color(0xFFFF758C), Color(0xFFFF7EB3)], // pinks
  ];

  List<Color> _colorsForUtilityType(String utilityType, String seedKey) {
    final u = utilityType.toLowerCase();
    if (u.contains('electric') || u.contains('kseb') || u.contains('power')) {
      return _pillPalettes[0];
    }
    if (u.contains('water')) {
      return _pillPalettes[1];
    }
    if (u.contains('gas')) {
      return _pillPalettes[2];
    }
    if (u.contains('wifi') ||
        u.contains('internet') ||
        u.contains('broadband')) {
      return _pillPalettes[3];
    }
    if (u.contains('phone') || u.contains('telephone')) {
      return _pillPalettes[4];
    }
    // Seeded fallback for unknown types for pleasant variance
    final h = seedKey.codeUnits.fold<int>(
      0,
      (a, b) => (a * 31 + b) & 0x7fffffff,
    );
    return _pillPalettes[h % _pillPalettes.length];
  }

  IconData _iconForUtility(String utilityType) {
    final u = utilityType.toLowerCase();
    if (u.contains('electric') || u.contains('kseb') || u.contains('power')) {
      return Icons.electric_bolt;
    }
    if (u.contains('water')) {
      return Icons.water_drop;
    }
    if (u.contains('gas')) {
      return Icons.local_gas_station;
    }
    if (u.contains('wifi') ||
        u.contains('internet') ||
        u.contains('broadband')) {
      return Icons.wifi;
    }
    if (u.contains('phone') || u.contains('telephone')) {
      return Icons.call;
    }
    return Icons.receipt_long;
  }

  String _shortBillId(String billId) {
    final id = (billId).trim();
    if (id.isEmpty) return '';
    final digits = RegExp(r'\d+').allMatches(id).map((m) => m.group(0)!).join();
    if (digits.length >= 4) return digits.substring(digits.length - 4);
    return id.length > 4 ? id.substring(id.length - 4) : id;
  }

  String _formatDateShort(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return '';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return createdAt;
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$mm-$dd';
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Utility Bills')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchBills,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _filterOpen
                      ? Container(
                          key: const ValueKey('open'),
                          width: MediaQuery.of(context).size.width,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              SizedBox(
                                width: 180,
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black26),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                  ),
                                  child: DropdownButton<String>(
                                    value:
                                        _utilityTypeOptions().contains(
                                          _selectedUtility,
                                        )
                                        ? _selectedUtility
                                        : 'All Utilities',
                                    items: _utilityTypeOptions()
                                        .map(
                                          (t) => DropdownMenuItem<String>(
                                            value: t,
                                            child: Text(t),
                                          ),
                                        )
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
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
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          onPressed: () => setState(() => _filterOpen = true),
                          icon: const Icon(Icons.search),
                          label: const Text('Search / Filter'),
                        ),
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (_loading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: displayBills.length,
                      itemBuilder: (context, index) {
                        final bill = displayBills[index];
                        final utilityType = (bill['utility_type'] ?? '').toString();
                        final billId = (bill['bill_id'] ?? '').toString();
                        final colors = _colorsForUtilityType(utilityType, billId);
                        final createdAt = (bill['created_at'] ?? '').toString();
                        final dateShort = _formatDateShort(createdAt);
                        final amount = (bill['total_amount'] ?? '').toString();
                        final consumer = (bill['consumer_name'] ?? '').toString();
                        final trailingStatus = _statusChipForBill(bill);

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: colors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: colors.first.withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _iconForUtility(utilityType),
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${utilityType.isNotEmpty ? utilityType : 'Bill'} • ${_shortBillId(billId)}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          if (dateShort.isNotEmpty)
                                            Text(
                                              dateShort,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        consumer,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.attach_money,
                                            size: 16,
                                            color: Colors.white70,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            amount,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const Spacer(),
                                          trailingStatus,
                                        ],
                                      ),
                                    ],
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}
