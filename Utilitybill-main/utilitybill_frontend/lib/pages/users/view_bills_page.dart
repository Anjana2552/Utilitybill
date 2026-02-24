import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import 'add_bill_page.dart';
import 'payment_history_page.dart';

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
  Map<String, Map<String, dynamic>> _upcomingBills = {};
  Set<String> _paidBillIds = {}; // Track paid bill IDs
  List<Map<String, dynamic>> _paidPayments = []; // Track all paid payments

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
      _userName =
          prefs.getString('user_username') ??
          prefs.getString('full_name') ??
          '';
      if (_userName.isEmpty) {
        setState(() {
          _items = [];
          _loading = false;
          _error = 'Missing user, please login again';
        });
        return;
      }

      // First, fetch all paid/approved payments to know which bills are paid
      await _loadPaidBills();

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/user-utility/list/?user_name=${Uri.encodeQueryComponent(_userName)}',
      );
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final items = (data['results'] as List<dynamic>?) ?? [];
        setState(() {
          _items = items;
        });
        
        // Fetch upcoming bills for each utility
        await _loadUpcomingBills(items);
        
        setState(() {
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

  Future<void> _loadPaidBills() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/payments/list/?status=approved');
      final resp = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final payments = (data['results'] as List<dynamic>?) ?? [];
        
        final paidIds = <String>{};
        final paidPayments = <Map<String, dynamic>>[];
        
        for (final payment in payments) {
          final paymentMap = payment as Map<String, dynamic>;
          final billId = (paymentMap['bill_id'] ?? '').toString();
          
          if (billId.isNotEmpty) {
            paidIds.add(billId);
            paidPayments.add(paymentMap);
          }
        }
        
        setState(() {
          _paidBillIds = paidIds;
          _paidPayments = paidPayments;
        });
      }
    } catch (_) {
      // If payment fetch fails, continue without filtering
    }
  }

  bool _isBillPaid(Map<String, dynamic> bill) {
    final billId = (bill['id'] ?? '').toString();
    
    // First check by bill ID
    if (_paidBillIds.contains(billId)) {
      return true;
    }
    
    // Also check by bill amount and due date (fallback matching)
    final billAmount = (bill['total_amount'] ?? '').toString();
    final billDueDate = (bill['due_date'] ?? bill['last_date'] ?? '').toString();
    
    for (final payment in _paidPayments) {
      final paymentAmount = (payment['amount'] ?? '').toString();
      // Match if amount and bill_id match, or if amounts are similar (within reasonable range)
      if (billAmount == paymentAmount || billId == (payment['bill_id'] ?? '').toString()) {
        return true;
      }
    }
    
    return false;
  }

  Future<void> _loadUpcomingBills(List<dynamic> utilities) async {
    final Map<String, Map<String, dynamic>> billsMap = {};
    
    for (final util in utilities) {
      final type = (util['utility_type'] ?? '').toString().toLowerCase();
      String consumerId = '';
      String utilityType = '';
      
      if (type == 'electricity') {
        consumerId = (util['consumer_number'] ?? '').toString();
        utilityType = 'Electricity';
      } else if (type == 'water') {
        consumerId = (util['water_connection_number'] ?? '').toString();
        utilityType = 'Water';
      } else if (type == 'gas') {
        consumerId = (util['gas_connection_number'] ?? '').toString();
        utilityType = 'Gas';
      } else if (type == 'wifi' || type == 'internet') {
        consumerId = (util['wifi_consumer_id'] ?? '').toString();
        utilityType = 'Wifi';
      } else if (type == 'dth') {
        consumerId = (util['dth_subscriber_id'] ?? '').toString();
        utilityType = 'DTH';
      }
      
      if (consumerId.isEmpty) continue;
      
      try {
        final billsUri = Uri.parse(
          '${ApiConfig.baseUrl}/utility-bill/list/?consumer_id=${Uri.encodeQueryComponent(consumerId)}&utility_type=$utilityType',
        );
        final billResp = await http.get(
          billsUri,
          headers: {'Content-Type': 'application/json'},
        );
        
        if (billResp.statusCode == 200) {
          final billData = jsonDecode(billResp.body) as Map<String, dynamic>;
          final bills = (billData['results'] as List<dynamic>?) ?? [];
          
          // Find the latest UNPAID bill
          if (bills.isNotEmpty) {
            Map<String, dynamic>? latestUnpaidBill;
            DateTime? latestDate;
            
            for (final bill in bills) {
              final billMap = bill as Map<String, dynamic>;
              
              // Skip if this bill is already paid
              if (_isBillPaid(billMap)) {
                continue;
              }
              
              final dateStr = (billMap['due_date'] ?? 
                              billMap['expiry_date'] ?? 
                              billMap['last_date'] ?? 
                              billMap['created_at'] ?? '').toString();
              
              if (dateStr.isNotEmpty) {
                try {
                  final dt = DateTime.parse(dateStr);
                  if (latestDate == null || dt.isAfter(latestDate)) {
                    latestDate = dt;
                    latestUnpaidBill = billMap;
                  }
                } catch (_) {}
              }
            }
            
            if (latestUnpaidBill != null) {
              final key = '${type}_$consumerId';
              billsMap[key] = latestUnpaidBill;
            }
          }
        }
      } catch (_) {
        // Ignore errors for individual bill fetches
      }
    }
    
    setState(() {
      _upcomingBills = billsMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bill'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Payment History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaymentHistoryPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Bill',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddBillPage()),
              );
              if (result == true && mounted) {
                _load(); // Reload bills after adding
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: _load,
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
      );
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
    
    // Filter items to only show utilities with unpaid bills
    final itemsWithUnpaidBills = _items.where((it) {
      final utilityType = (it['utility_type'] ?? '') as String;
      final type = utilityType.toLowerCase();
      String consumerId = '';
      
      if (type == 'electricity') {
        consumerId = (it['consumer_number'] ?? '').toString();
      } else if (type == 'water') {
        consumerId = (it['water_connection_number'] ?? '').toString();
      } else if (type == 'gas') {
        consumerId = (it['gas_connection_number'] ?? '').toString();
      } else if (type == 'wifi' || type == 'internet') {
        consumerId = (it['wifi_consumer_id'] ?? '').toString();
      } else if (type == 'dth') {
        consumerId = (it['dth_subscriber_id'] ?? '').toString();
      }
      
      final billKey = '${type}_$consumerId';
      // Only include utilities that have an unpaid bill
      return _upcomingBills.containsKey(billKey);
    }).toList();
    
    if (itemsWithUnpaidBills.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.green.shade400,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Unpaid Bills',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All your bills are paid! Great job.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
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
          itemCount: itemsWithUnpaidBills.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final it = itemsWithUnpaidBills[i] as Map<String, dynamic>;
            final utilityType = (it['utility_type'] ?? '') as String;
            final provider = (it['provider_name'] ?? '') as String;
            final createdAt = (it['created_at'] ?? '') as String;
            final when = _formatDate(createdAt);
            final subtitle = _buildSubtitle(it);
            final icon = _iconForUtility(utilityType);
            final gradient = _gradientForUtility(utilityType);
            
            // Get upcoming bill for this utility
            final type = utilityType.toLowerCase();
            String consumerId = '';
            if (type == 'electricity') {
              consumerId = (it['consumer_number'] ?? '').toString();
            } else if (type == 'water') {
              consumerId = (it['water_connection_number'] ?? '').toString();
            } else if (type == 'gas') {
              consumerId = (it['gas_connection_number'] ?? '').toString();
            } else if (type == 'wifi' || type == 'internet') {
              consumerId = (it['wifi_consumer_id'] ?? '').toString();
            } else if (type == 'dth') {
              consumerId = (it['dth_subscriber_id'] ?? '').toString();
            }
            
            final billKey = '${type}_$consumerId';
            final upcomingBill = _upcomingBills[billKey];
            
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                      tooltip: 'Edit',
                                      onPressed: () => _editItem(it),
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                        color: Colors.white,
                                      ),
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
                        // Upcoming bill details
                        if (upcomingBill != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Upcoming Bill',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getBillDate(upcomingBill),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Amount',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${upcomingBill['total_amount'] ?? '0.00'}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
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

  String _getBillDate(Map<String, dynamic> bill) {
    final dateStr = (bill['due_date'] ?? 
                     bill['expiry_date'] ?? 
                     bill['last_date'] ?? 
                     bill['created_at'] ?? '').toString();
    if (dateStr.isEmpty) return 'No date';
    
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final isOverdue = dt.isBefore(now);
      final formatted = _formatDate(dateStr);
      return isOverdue ? 'Due: $formatted' : 'Due: $formatted';
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _editItem(Map<String, dynamic> it) async {
    final res = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddBillPage(initial: it, recordId: it['id'] as int?),
      ),
    );
    if (res != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Updated')));
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Deleted')));
        await _load();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: ${resp.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
    add('WiFi', it['wifi_consumer_id'] as String?);
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
        return const [
          Color(0xFF4DD0E1),
          Color(0xFF00796B),
        ]; // teal -> dark teal
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
}
