import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import 'wallet_page.dart';
import 'tips_page.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  bool _loading = false;
  double _rewardAmount = 0.0;
  List<Map<String, dynamic>> _rewards = const [];

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_username') ?? '';
      if (username.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      // Fetch wallet transactions and filter rewards: credits with refund reason
      final txUri = Uri.parse(
          '${ApiConfig.baseUrl}/wallet/transactions/?username=${Uri.encodeQueryComponent(username)}&limit=50');
      final txResp = await http.get(txUri, headers: {'Content-Type': 'application/json'});
      if (txResp.statusCode == 200) {
        final obj = jsonDecode(txResp.body) as Map<String, dynamic>;
        final list = ((obj['results'] as List<dynamic>?) ?? const [])
            .cast<Map<String, dynamic>>();
        final rewards = list.where((t) {
          final type = (t['type'] ?? '').toString().toLowerCase();
          final reason = (t['reason'] ?? '').toString().toLowerCase();
          return type == 'credit' && reason.contains('refund for rejected payment');
        }).toList();
        double total = 0.0;
        for (final r in rewards) {
          final amt = double.tryParse((r['amount'] ?? '0').toString()) ?? 0.0;
          total += amt;
        }
        _rewards = rewards;
        _rewardAmount = total;
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rewards'),
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
            onPressed: _loading ? null : _loadRewards,
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
                          child: Icon(Icons.card_giftcard, color: scheme.onPrimaryContainer),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Reward Amount',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'You have ₹ ${_rewardAmount.toStringAsFixed(2)}',
                                style: TextStyle(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: null, // Disabled until redemption flow exists
                          child: const Text('Redeem'),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    title: const Text('My Wallet'),
                    subtitle: const Text('View balance and transactions'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const WalletPage()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Recent Rewards',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (_rewards.isEmpty)
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: const ListTile(
                      leading: Icon(Icons.local_offer_outlined),
                      title: Text('No rewards yet'),
                      subtitle: Text('Rejected payment refunds will appear here.'),
                    ),
                  )
                else
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _rewards.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final r = _rewards[i];
                        final amt = (r['amount'] ?? '0').toString();
                        final reason = (r['reason'] ?? '').toString();
                        final when = (r['created_at'] ?? '').toString();
                        return ListTile(
                          leading: const Icon(Icons.card_giftcard_outlined, color: Colors.green),
                          title: Text('+ ₹ $amt', style: const TextStyle(fontWeight: FontWeight.w600)),
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
