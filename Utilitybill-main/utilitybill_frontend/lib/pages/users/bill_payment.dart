import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';
import '../../widgets/theme_header.dart';
import 'user_profile.dart';

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
          foundBills.add((r as Map<String, dynamic>));
        }
      }

      if (!mounted) return;
      setState(() {
        _bills = foundBills;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
    final ids = _selectedIndices
        .map((i) => (_bills[i]['bill_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList();
    final total = _selectedTotal();

    try {
      int success = 0;
      for (final id in ids) {
        final amountStr = (_bills.firstWhere((b) => (b['bill_id'] ?? '').toString() == id)['total_amount'] ?? '').toString();
        final amount = double.tryParse(amountStr.replaceAll(',', '').trim()) ?? 0.0;
        final uri = Uri.parse('${ApiConfig.baseUrl}/payments/add/');
        final resp = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'bill_id': id,
            'amount': amount,
            'payment_method': 'online',
          }),
        );
        if (resp.statusCode == 201) {
          success += 1;
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paid $success/${ids.length} bill(s) • ₹ ${total.toStringAsFixed(2)}'),
        ),
      );
      // Refresh bills after payment (optional: remove paid ones)
      await _loadUserBills();
      setState(() => _selectedIndices.clear());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment failed. Please try again.')),
      );
    }
  }

  Widget _buildList() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header title handled in curved header; list starts directly
            if (_bills.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No bills found'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _bills.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final bill = _bills[index];
                  final id = (bill['bill_id'] ?? '').toString();
                  final type = (bill['utility_type'] ?? '').toString();
                  final amount = (bill['total_amount'] ?? '').toString();
                  final dateText =
                      (bill['due_date'] ?? bill['created_at'] ?? '').toString();
                  final isSelected = _selectedIndices.contains(index);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (checked) => _onToggle(index, checked ?? false),
                    title: Text('Invoice $id'),
                    subtitle: Text(
                      '$type • ${dateText.isEmpty ? '-' : dateText}',
                    ),
                    secondary: Text(
                      amount.isEmpty ? '' : '₹ $amount',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildList(),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedIndices.isEmpty ? null : _onPay,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34B3A0),
              foregroundColor: Colors.white,
            ),
            child: const Text('Pay'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          : _buildContent(),
    );

    if (!widget.useHeader) {
      return SingleChildScrollView(child: content);
    }

    final headerPage = CurvedHeaderPage(
      title: 'Payments',
      headerHeight: 220,
      headerColor: const Color(0xFF7FD9CE),
      titleAlignment: HeaderTitleAlignment.left,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).maybePop(),
        tooltip: 'Back',
      ),
      bottomLeft: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My bill',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatSelectedTotal(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      child: content,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: headerPage,
      bottomNavigationBar: CurvedNavigationBar(
        items: const [
          Icon(Icons.home, size: 26, color: Colors.white),
          Icon(Icons.payment, size: 26, color: Colors.white),
          Icon(Icons.person, size: 26, color: Colors.white),
        ],
        index: 1,
        color: const Color(0xFF7FD9CE),
        buttonBackgroundColor: const Color(0xFF4B9A8F),
        backgroundColor: Colors.white,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 300),
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
            return;
          }
          if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UserProfilePage()),
            );
            return;
          }
        },
      ),
    );
  }
}
