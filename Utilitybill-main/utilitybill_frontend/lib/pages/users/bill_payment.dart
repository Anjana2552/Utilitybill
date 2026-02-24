import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';
import 'user_profile.dart';
import 'payment_success_page.dart';
import 'payment_method_selection.dart';

class BillPaymentPage extends StatefulWidget {
  final bool useHeader;
  const BillPaymentPage({super.key, this.useHeader = true});

  @override
  State<BillPaymentPage> createState() => _BillPaymentPageState();
}

class _BillPaymentPageState extends State<BillPaymentPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _bills = [];
  final Set<int> _selectedIndices = <int>{};
  bool _isSubmitting = false;
  final Map<String, String> _statusByBillId = <String, String>{};
  bool _statusesInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadUserBills();
  }

  Future<void> _loadUserBills() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_username') ?? '';
      if (username.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final utilUri = Uri.parse(
        '${ApiConfig.baseUrl}/user-utility/list/?user_name=${Uri.encodeQueryComponent(username)}',
      );
      final utilResp = await http.get(
        utilUri,
        headers: {'Content-Type': 'application/json'},
      );
      if (utilResp.statusCode != 200) {
        setState(() => _loading = false);
        return;
      }

      final utilJson = jsonDecode(utilResp.body) as Map<String, dynamic>;
      final List<dynamic> utilities =
          (utilJson['results'] as List<dynamic>?) ?? const [];
      final List<Map<String, dynamic>> foundBills = [];

      for (final u in utilities) {
        final type = (u['utility_type'] ?? '').toString().toLowerCase();
        String consumerId = '';
        String utilityType = '';
        if (type == 'electricity') {
          consumerId = (u['consumer_number'] ?? '').toString();
          utilityType = 'Electricity';
        } else if (type == 'water') {
          consumerId = (u['water_connection_number'] ?? '').toString();
          utilityType = 'Water';
        } else if (type == 'gas') {
          consumerId = (u['gas_connection_number'] ?? '').toString();
          utilityType = 'Gas';
        } else if (type == 'wifi' || type == 'internet') {
          consumerId = (u['wifi_consumer_id'] ?? '').toString();
          utilityType = 'Wifi';
        } else if (type == 'dth') {
          consumerId = (u['dth_subscriber_id'] ?? '').toString();
          utilityType = 'DTH';
        }
        if (consumerId.isEmpty) continue;

        final billsUri = Uri.parse(
          '${ApiConfig.baseUrl}/utility-bill/list/?consumer_id=${Uri.encodeQueryComponent(consumerId)}&utility_type=$utilityType',
        );
        final respUB = await http.get(
          billsUri,
          headers: {'Content-Type': 'application/json'},
        );
        if (respUB.statusCode != 200) continue;
        final obj = jsonDecode(respUB.body) as Map<String, dynamic>;
        final List<dynamic> results =
            (obj['results'] as List<dynamic>?) ?? const [];
        for (final r in results) {
          final billData = r as Map<String, dynamic>;

          foundBills.add(billData);
        }
      }

      if (!mounted) return;
      setState(() {
        _bills = foundBills;
        _loading = false;
      });
      await _loadPaymentStatuses();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPaymentStatuses() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/payments/list/');
      final resp = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      if (resp.statusCode != 200) return;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = (data['results'] as List<dynamic>?) ?? const [];
      final Map<String, Map<String, dynamic>> latest = {};
      DateTime parse(dynamic v) {
        try {
          return DateTime.parse(v.toString());
        } catch (_) {
          return DateTime.fromMillisecondsSinceEpoch(0);
        }
      }

      for (final r in results) {
        final m = r as Map<String, dynamic>;
        final billId = (m['bill_id'] ?? '').toString();
        if (billId.isEmpty) continue;
        final dt = parse(m['payment_date']);
        final prev = latest[billId];
        if (prev == null || parse(prev['payment_date']).isBefore(dt)) {
          latest[billId] = m;
        }
      }
      if (!mounted) return;

      final Map<String, String> newStatuses = {};
      latest.forEach((billId, m) {
        newStatuses[billId] = (m['status'] ?? '').toString();
      });

      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_username') ?? '';

      if (_statusesInitialized) {
        newStatuses.forEach((billId, newStatus) {
          final oldStatus = _statusByBillId[billId];
          if (oldStatus != null && newStatus != oldStatus && newStatus == 'rejected') {
            _showUpdatedWalletBalance();
          }
        });
      }

      setState(() {
        _statusByBillId
          ..clear()
          ..addAll(newStatuses);
        _statusesInitialized = true;
      });

    } catch (_) {
      // ignore
    }
  }

  Future<void> _showUpdatedWalletBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_username') ?? '';
      if (username.isEmpty || !mounted) return;
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/wallet/balance/?username=${Uri.encodeQueryComponent(username)}',
      );
      final resp = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      if (resp.statusCode == 200) {
        final obj = jsonDecode(resp.body) as Map<String, dynamic>;
        final bal = (obj['balance'] ?? '0.00').toString();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Wallet updated: ₹ $bal')));
      }
    } catch (_) {
      // ignore
    }
  }

  void _onToggle(int index, bool selected) {
    setState(() {
      if (selected) {
        _selectedIndices.add(index);
      } else {
        _selectedIndices.remove(index);
      }
    });
  }

  double _selectedTotal() {
    double total = 0.0;
    for (final i in _selectedIndices) {
      final bill = _bills[i];
      final amountStr = (bill['total_amount'] ?? '').toString();
      final amount =
          double.tryParse(amountStr.replaceAll(',', '').trim()) ?? 0.0;
      total += amount;
    }
    return total;
  }

  String _formatSelectedTotal() {
    final total = _selectedTotal();
    final s = total.toStringAsFixed(2);
    final parts = s.split('.');
    final intPart = parts[0].padLeft(2, '0');
    return '$intPart.${parts[1]}';
  }

  Future<void> _onPay() async {
    if (_selectedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select one or more bills to pay')),
      );
      return;
    }
    final method = await _choosePaymentMethod();
    if (method == null) return;
    if (!mounted) return;

    // Check wallet balance if wallet method is selected
    if (method == 'wallet') {
      final total = _selectedTotal();
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_username') ?? '';
      if (username.isNotEmpty) {
        try {
          final resp = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/wallet/balance/?username=${Uri.encodeQueryComponent(username)}'),
            headers: {'Content-Type': 'application/json'},
          );
          if (resp.statusCode == 200) {
            final obj = jsonDecode(resp.body) as Map<String, dynamic>;
            final balStr = (obj['balance'] ?? '0.00').toString();
            final balance = double.tryParse(balStr) ?? 0.0;
            if (balance < total) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Insufficient wallet balance. Available: ₹$balStr, Required: ₹${total.toStringAsFixed(2)}'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
          }
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not verify wallet balance')),
          );
          return;
        }
      }
    }

    // Immediate feedback on confirmation
    final methodLabel = _labelForMethod(method);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment initiated via $methodLabel'),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );

    final ids = _selectedIndices
        .map((i) => (_bills[i]['bill_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList();
    final total = _selectedTotal();

    setState(() => _isSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_username') ?? '';
      int success = 0;
      for (final id in ids) {
        final bill = _bills.firstWhere(
          (b) => (b['bill_id'] ?? '').toString() == id,
        );
        final amountStr = (bill['total_amount'] ?? '').toString();
        final amount =
            double.tryParse(amountStr.replaceAll(',', '').trim()) ?? 0.0;
        final uri = Uri.parse('${ApiConfig.baseUrl}/payments/add/');
        final resp = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'bill_id': id,
            'amount': amount,
            'payment_method': method,
          }),
        );
        if (resp.statusCode == 201) {
          success += 1;
          _statusByBillId[id] = 'pending';
        }
      }
      if (!mounted) return;
      // Navigate to success page with approval notice
      if (success > 0) {
        final methodLabel = _labelForMethod(method);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PaymentSuccessPage(
              billsCount: success,
              totalAmount: total,
              methodLabel: methodLabel,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment request submitted for $success/${ids.length} bill(s) • ₹ ${total.toStringAsFixed(2)}',
            ),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
      setState(() => _selectedIndices.clear());
      await _loadPaymentStatuses();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment failed. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<String?> _choosePaymentMethod() async {
    final method = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const PaymentMethodSelectionPage()),
    );
    return method;
  }

  // Removed unused _iconForMethod() helper.

  String _labelForMethod(String method) {
    switch (method) {
      case 'wallet':
        return 'Wallet';
      case 'upi':
      case 'online':
        return 'UPI';
      case 'credit_card':
        return 'Credit Card';
      case 'debit_card':
        return 'Debit Card';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'other':
        return 'Other Payment';
      default:
        return 'Payment';
    }
  }

  Widget _buildList() {
    final List<int> visibleIndices = [];
    for (int i = 0; i < _bills.length; i++) {
      final id = (_bills[i]['bill_id'] ?? '').toString();
      final status = _statusByBillId[id];
      if (status == 'approved') continue; // hide completed payments
      visibleIndices.add(i);
    }

    if (_bills.isEmpty || visibleIndices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No payable bills',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    return Column(
      children: visibleIndices.map((index) {
        final bill = _bills[index];
        final id = (bill['bill_id'] ?? '').toString();
        final type = (bill['utility_type'] ?? '').toString();
        final amount = (bill['total_amount'] ?? '').toString();
        final dateText = (bill['created_at'] ?? '').toString();
        final status = _statusByBillId[id];
        final isSelected = _selectedIndices.contains(index);
        final isPending = status == 'pending';

        return GestureDetector(
          onTap: isPending ? null : () => _onToggle(index, !isSelected),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: const Color.fromARGB(255, 1, 45, 83), width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Invoice ID
                Text(
                  'Invoice $id',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                // Utility type with icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        size: 18,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$type +',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          if (dateText.isNotEmpty)
                            Text(
                              dateText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (status != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: status == 'pending'
                          ? Colors.orange.shade50
                          : status == 'rejected'
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatStatus(status),
                      style: TextStyle(
                        fontSize: 12,
                        color: status == 'pending'
                            ? Colors.orange.shade700
                            : status == 'rejected'
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildList(),
        const SizedBox(height: 20),
        // Pay Button
        Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: (_selectedIndices.isEmpty || _isSubmitting)
                ? Colors.grey.shade400
                : Colors.blue.shade600,
            borderRadius: BorderRadius.circular(12),
            boxShadow: (_selectedIndices.isEmpty || _isSubmitting)
                ? []
                : [
                    BoxShadow(
                      color: const Color.fromARGB(255, 2, 44, 79).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: (_selectedIndices.isEmpty || _isSubmitting) ? null : _onPay,
              child: Center(
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Pay',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ),
        if (_isSubmitting)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(
              child: Text(
                'Waiting for approval…',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatStatus(String s) {
    switch (s) {
      case 'approved':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      default:
        return s;
    }
  }

  // Removed unused _showReceipt() method.

  @override
  Widget build(BuildContext context) {
    if (!widget.useHeader) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _buildContent(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header with curved bottom
          ClipPath(
            clipper: PaymentWaveClipper(),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color.fromARGB(255, 1, 36, 64), const Color.fromARGB(255, 0, 58, 116)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top bar with title and icons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Payments',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
                                onPressed: _loadUserBills,
                              ),
                              IconButton(
                                icon: const Icon(Icons.search, color: Colors.white, size: 24),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Amount
                      Text(
                        '₹ ${_formatSelectedTotal()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _loading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _buildContent(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        items: [
          Icon(
            Icons.home,
            size: 26,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          Icon(
            Icons.payment,
            size: 26,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          Icon(
            Icons.chat_bubble_outline,
            size: 26,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          Icon(
            Icons.person,
            size: 26,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ],
        index: 1,
        color: Theme.of(context).colorScheme.primary,
        buttonBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
        backgroundColor: Colors.white,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
            return;
          }
          if (index == 3) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const UserProfilePage()));
            return;
          }
          if (index == 2) {
            Navigator.pushNamed(context, '/user/chat');
            return;
          }
        },
      ),
    );
  }
}

// Custom clipper for curved header
class PaymentWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
