import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';
import 'user_profile.dart';
import '../../services/notifications_service.dart';
import '../../models/notification_item.dart';
import 'payment_success_page.dart';
import 'payment_method_selection.dart';

// Normalize utility type to match dashboard provider names
String _normalizeUtilityType(String utilityType) {
  final lower = utilityType.toLowerCase();
  if (lower == 'electricity') return 'kseb';
  if (lower == 'water') return 'water';
  if (lower == 'gas') return 'gas';
  if (lower == 'wifi') return 'wifi';
  if (lower == 'dth') return 'dth';
  return lower;
}

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
  final NotificationsService _notifications = NotificationsService();
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

      final List<NotificationItem> toNotify = [];
      if (_statusesInitialized) {
        newStatuses.forEach((billId, newStatus) {
          final oldStatus = _statusByBillId[billId];
          if (oldStatus != null && newStatus != oldStatus) {
            final latestEntry = latest[billId] ?? const <String, dynamic>{};
            final amountStr = (latestEntry['amount'] ?? '').toString();
            final methodCode = (latestEntry['payment_method'] ?? '').toString();
            final methodLabel = _labelForMethod(methodCode);
            
            // Get utility type from bill data
            final bill = _bills.firstWhere(
              (b) => (b['bill_id'] ?? '').toString() == billId,
              orElse: () => const <String, dynamic>{},
            );
            final rawUtilityType = (bill['utility_type'] ?? '').toString();
            final utilityType = _normalizeUtilityType(rawUtilityType);
            
            if (newStatus == 'approved') {
              // Notification for user
              toNotify.add(
                NotificationItem(
                  id: 'payment_approved_${username}_$billId',
                  type: 'payment_approved',
                  title: 'Payment approved',
                  message:
                      'Invoice $billId approved • Amount INR $amountStr via $methodLabel',
                  timestamp: DateTime.now(),
                  username: username,
                  utilityType: utilityType,
                ),
              );
              
              // Notification for utility authority
              if (utilityType.isNotEmpty) {
                toNotify.add(
                  NotificationItem(
                    id: 'payment_approved_utility_${utilityType}_$billId',
                    type: 'payment_approved',
                    title: 'Payment Approved',
                    message:
                        'User $username payment approved for Invoice $billId • Amount INR $amountStr',
                    timestamp: DateTime.now(),
                    username: 'utility_$utilityType',
                    utilityType: utilityType,
                  ),
                );
              }
            } else if (newStatus == 'rejected') {
              // Notification for user
              toNotify.add(
                NotificationItem(
                  id: 'payment_rejected_${username}_$billId',
                  type: 'payment_rejected',
                  title: 'Payment rejected',
                  message:
                      'Invoice $billId was rejected. Amount credited to your wallet.',
                  timestamp: DateTime.now(),
                  username: username,
                  utilityType: utilityType,
                ),
              );
              
              // Notification for utility authority
              if (utilityType.isNotEmpty) {
                toNotify.add(
                  NotificationItem(
                    id: 'payment_rejected_utility_${utilityType}_$billId',
                    type: 'payment_rejected',
                    title: 'Payment Rejected',
                    message:
                        'User $username payment rejected for Invoice $billId • Amount INR $amountStr',
                    timestamp: DateTime.now(),
                    username: 'utility_$utilityType',
                    utilityType: utilityType,
                  ),
                );
              }
              
              // Also fetch and show updated wallet balance
              _showUpdatedWalletBalance();
            }
          }
        });
      }

      setState(() {
        _statusByBillId
          ..clear()
          ..addAll(newStatuses);
        _statusesInitialized = true;
      });

      for (final n in toNotify) {
        await _notifications.addUnique(n);
      }
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
        final rawUtilityType = (bill['utility_type'] ?? '').toString();
        final utilityType = _normalizeUtilityType(rawUtilityType);
        
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
          final methodLabel = _labelForMethod(method);
          
          // Notification for user
          await _notifications.addUnique(
            NotificationItem(
              id: 'payment_initiated_${username}_$id',
              type: 'payment_initiated',
              title: 'Payment initiated',
              message:
                  'Invoice $id • Amount INR ${amount.toStringAsFixed(2)} via $methodLabel',
              timestamp: DateTime.now(),
              username: username,
              utilityType: utilityType,
            ),
          );
          
          // Notification for utility authority
          if (utilityType.isNotEmpty) {
            await _notifications.addUnique(
              NotificationItem(
                id: 'payment_initiated_utility_${utilityType}_$id',
                type: 'payment_initiated',
                title: 'Payment Received',
                message:
                    'User $username initiated payment for Invoice $id • Amount INR ${amount.toStringAsFixed(2)}',
                timestamp: DateTime.now(),
                username: 'utility_$utilityType',
                utilityType: utilityType,
              ),
            );
          }
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
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header title handled in curved header; list starts directly
            // Build visible indices excluding fully paid (approved) bills
            Builder(
              builder: (context) {
                final List<int> visibleIndices = [];
                for (int i = 0; i < _bills.length; i++) {
                  final id = (_bills[i]['bill_id'] ?? '').toString();
                  final status = _statusByBillId[id];
                  if (status == 'approved') continue; // hide completed payments
                  visibleIndices.add(i);
                }
                if (_bills.isEmpty || visibleIndices.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No payable bills'),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visibleIndices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final index = visibleIndices[idx];
                    final bill = _bills[index];
                    final id = (bill['bill_id'] ?? '').toString();
                    final type = (bill['utility_type'] ?? '').toString();
                    final amount = (bill['total_amount'] ?? '').toString();
                    final dateText =
                        (bill['due_date'] ?? bill['created_at'] ?? '')
                            .toString();
                    final status = _statusByBillId[id];
                    final isSelected = _selectedIndices.contains(index);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (checked) => (status == 'pending')
                          ? null
                          : _onToggle(index, checked ?? false),
                      title: Text('Invoice $id'),
                      subtitle: Text(
                        '$type • ${dateText.isEmpty ? '-' : dateText}${status == null ? '' : ' • Status: ${_formatStatus(status)}'}',
                      ),
                      secondary: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            amount.isEmpty ? '' : '₹ $amount',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
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
            onPressed: (_selectedIndices.isEmpty || _isSubmitting)
                ? null
                : _onPay,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Pay'),
          ),
        ),
        if (_isSubmitting)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Waiting for approval…',
              style: TextStyle(color: Colors.black54),
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

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Payments'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            child: Column(
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
                const SizedBox(height: 4),
                Text(
                  _formatSelectedTotal(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(16), child: content)),
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
        backgroundColor: Theme.of(context).colorScheme.surface,
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
