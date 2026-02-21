import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        actions: [
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
                        FilledButton(onPressed: () {}, child: const Text('Add Funds')),
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
