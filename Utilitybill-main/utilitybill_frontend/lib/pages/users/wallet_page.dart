import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import 'tips_page.dart';
import 'wallet_success_page.dart';
import 'payment_details_page.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  String _balance = '0.00';
  List<Map<String, dynamic>> _txns = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_username') ?? '';
      if (username.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      final balUri = Uri.parse('${ApiConfig.baseUrl}/wallet/balance/?username=${Uri.encodeQueryComponent(username)}');
      final balResp = await http.get(balUri, headers: {'Content-Type': 'application/json'});
      if (balResp.statusCode == 200) {
        final obj = jsonDecode(balResp.body) as Map<String, dynamic>;
        _balance = (obj['balance'] ?? '0.00').toString();
      }
      final txUri = Uri.parse('${ApiConfig.baseUrl}/wallet/transactions/?username=${Uri.encodeQueryComponent(username)}&limit=20');
      final txResp = await http.get(txUri, headers: {'Content-Type': 'application/json'});
      if (txResp.statusCode == 200) {
        final obj = jsonDecode(txResp.body) as Map<String, dynamic>;
        _txns = ((obj['results'] as List<dynamic>?) ?? const []).cast<Map<String, dynamic>>();
      }
    } catch (_) {
      // ignore errors for now
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAddFundsDialog() async {
    final amountController = TextEditingController();
    
    // First, show amount input
    final amount = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter Amount', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                prefixText: '₹ ',
                hintText: '0.00',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final amt = amountController.text.trim();
              if (amt.isEmpty || double.tryParse(amt) == null || double.parse(amt) <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }
              Navigator.pop(ctx, amt);
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );

    if (amount == null || amount.isEmpty) return;

    // Then show payment method selection
    final selectedMethod = await _showPaymentMethodSelection();
    
    if (selectedMethod != null && selectedMethod.isNotEmpty) {
      await _addFunds(amount, selectedMethod);
    }
  }

  Future<String?> _showPaymentMethodSelection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_username') ?? '';
      if (username.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login first')),
          );
        }
        return null;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final uri = Uri.parse('${ApiConfig.baseUrl}/user-payment-methods/?username=${Uri.encodeQueryComponent(username)}');
      final resp = await http.get(uri, headers: {'Content-Type': 'application/json'});
      
      if (mounted) Navigator.pop(context); // Close loading

      List<Map<String, dynamic>> paymentMethods = [];
      
      if (resp.statusCode == 200) {
        try {
          final obj = jsonDecode(resp.body) as Map<String, dynamic>;
          paymentMethods = ((obj['payment_methods'] as List<dynamic>?) ?? [])
              .cast<Map<String, dynamic>>();
        } catch (e) {
          print('Error parsing payment methods: $e');
        }
      }

      // If no payment methods, navigate to payment details page
      if (paymentMethods.isEmpty) {
        if (mounted) {
          final result = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('No Payment Methods'),
              content: const Text('You haven\'t added any payment methods yet. Would you like to add one now?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Add Payment Method'),
                ),
              ],
            ),
          );

          if (result == true && mounted) {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaymentDetailsPage()),
            );
          }
        }
        return null;
      }

      // Map method names to icons
      final methodIcons = {
        'Credit Card': Icons.credit_card,
        'Bank Transfer': Icons.account_balance,
        'UPI': Icons.payment,
      };

      // Show payment method selection bottom sheet
      return await showModalBottomSheet<String>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Payment Method',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...paymentMethods.map((method) {
                final methodName = method['method'] as String;
                final icon = methodIcons[methodName] ?? Icons.payment;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx, methodName),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              methodName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade400, width: 2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading if still open
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _addFunds(String amount, String paymentMethod) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_username') ?? '';
      if (username.isEmpty) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final uri = Uri.parse('${ApiConfig.baseUrl}/wallet/add-funds/');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'amount': amount,
          'payment_method': paymentMethod,
        }),
      );

      if (mounted) Navigator.pop(context); // Close loading dialog

      // Log response for debugging
      print('Add funds response - Status: ${resp.statusCode}');
      print('Response body: ${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        try {
          final obj = jsonDecode(resp.body) as Map<String, dynamic>;
          final newBalance = obj['new_balance'] ?? '0.00';
          final cashback = obj['cashback'] ?? '0.00';
          
          if (mounted) {
            // Navigate to success page
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WalletSuccessPage(
                  amount: amount,
                  paymentMethod: paymentMethod,
                  newBalance: newBalance.toString(),
                  cashback: cashback.toString(),
                ),
              ),
            );
            // Reload wallet after returning from success page
            _loadWallet();
          }
        } catch (e) {
          print('Error parsing success response: $e');
          // Even if parsing fails, the transaction succeeded, so reload wallet
          if (mounted) {
            _loadWallet();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Funds added successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        // Log the error for debugging
        print('Add funds failed - Status: ${resp.statusCode}');
        print('Response body: ${resp.body}');
        
        try {
          final obj = jsonDecode(resp.body) as Map<String, dynamic>;
          final error = obj['error'] ?? 'Failed to add funds (Status: ${resp.statusCode})';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: Colors.red),
            );
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to add funds (Status: ${resp.statusCode})'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Exception in _addFunds: $e');
      if (mounted) Navigator.pop(context); // Close loading dialog if still open
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        actions: [
          IconButton(
            tooltip: 'Tips',
            icon: const Icon(Icons.lightbulb),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TipsPage()),
              );
            },
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadWallet,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: scheme.primaryContainer,
                          child: Icon(Icons.account_balance_wallet_outlined, color: scheme.onPrimaryContainer),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Wallet Balance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              Text('₹ $_balance', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 18, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        FilledButton(onPressed: _showAddFundsDialog, child: const Text('Add Funds')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Recent Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (_txns.isEmpty)
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: const ListTile(
                      leading: Icon(Icons.receipt_long_outlined),
                      title: Text('No transactions yet'),
                      subtitle: Text('Your wallet history will appear here.'),
                    ),
                  )
                else
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _txns.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final t = _txns[i];
                        final isCredit = (t['type'] ?? '') == 'credit';
                        final amt = (t['amount'] ?? '0').toString();
                        final reason = (t['reason'] ?? '').toString();
                        final when = (t['created_at'] ?? '').toString();
                        return ListTile(
                          leading: Icon(isCredit ? Icons.call_received : Icons.call_made,
                              color: isCredit ? Colors.green : Colors.redAccent),
                          title: Text(isCredit ? '+ ₹ $amt' : '- ₹ $amt', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(reason.isEmpty ? when : '$reason • $when'),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}
