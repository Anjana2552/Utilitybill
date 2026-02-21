import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../config/api_config.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<Uint8List> _buildReceiptBytes(Map<String, dynamic> payment) async {
    // Use default PDF fonts (Helvetica). Avoid Unicode-only characters.
    final doc = pw.Document();
    final billId = (payment['bill_id'] ?? '').toString();
    final amount = (payment['amount'] ?? '').toString();
    final method = (payment['payment_method'] ?? '').toString();
    final date = (payment['payment_date'] ?? '').toString();

    doc.addPage(
      pw.Page(
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Payment Receipt',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text('Bill ID: $billId'),
                pw.Text('Amount: INR $amount'),
                pw.Text('Method: $method'),
                pw.Text('Date: $date'),
                pw.SizedBox(height: 12),
                pw.Divider(),
                pw.Text(
                  'Status: Paid',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  'Thank you for your payment.',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );

    return await doc.save();
  }

  Future<void> _previewReceipt(Map<String, dynamic> payment) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Receipt Preview'),
          content: SizedBox(
            width: 500,
            height: 500,
            child: PdfPreview(
              build: (format) => _buildReceiptBytes(payment),
              allowPrinting: false,
              allowSharing: false,
              canChangePageFormat: false,
              canChangeOrientation: false,
              pdfFileName:
                  'receipt_${(payment['bill_id'] ?? '').toString()}.pdf',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Download'),
              onPressed: () async {
                try {
                  final bytes = await _buildReceiptBytes(payment);
                  await Printing.sharePdf(
                    bytes: bytes,
                    filename:
                        'receipt_${(payment['bill_id'] ?? '').toString()}.pdf',
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (_) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to download receipt'),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('user_username') ?? '';
      if (username.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      // Load user's bills to filter payment results
      final utilUri = Uri.parse(
        '${ApiConfig.baseUrl}/user-utility/list/?user_name=${Uri.encodeQueryComponent(username)}',
      );
      final utilResp = await http.get(
        utilUri,
        headers: {'Content-Type': 'application/json'},
      );
      final Set<String> userBillIds = <String>{};
      if (utilResp.statusCode == 200) {
        final utilJson = jsonDecode(utilResp.body) as Map<String, dynamic>;
        final List<dynamic> utilities =
            (utilJson['results'] as List<dynamic>?) ?? const [];
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
          if (respUB.statusCode == 200) {
            final obj = jsonDecode(respUB.body) as Map<String, dynamic>;
            final List<dynamic> results =
                (obj['results'] as List<dynamic>?) ?? const [];
            for (final r in results) {
              final m = r as Map<String, dynamic>;
              final id = (m['bill_id'] ?? '').toString();
              if (id.isNotEmpty) userBillIds.add(id);
            }
          }
        }
      }

      // Fetch approved payments and filter by user's bills
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
        final List<Map<String, dynamic>> pays = [];
        for (final p in presults) {
          final m = p as Map<String, dynamic>;
          final bid = (m['bill_id'] ?? '').toString();
          if (userBillIds.contains(bid)) pays.add(m);
        }
        // Sort by date desc
        DateTime parse(dynamic v) {
          try {
            return DateTime.parse(v.toString());
          } catch (_) {
            return DateTime.fromMillisecondsSinceEpoch(0);
          }
        }

        pays.sort(
          (a, b) =>
              parse(b['payment_date']).compareTo(parse(a['payment_date'])),
        );
        _payments = pays;
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
      backgroundColor: scheme.surface,
      appBar: AppBar(title: const Text('Payment History')),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _loading ? 1 : _payments.length,
          itemBuilder: (context, index) {
            if (_loading) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (_payments.isEmpty) {
              return const Center(child: Text('No payment history'));
            }
            final p = _payments[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(Icons.receipt_long, color: scheme.secondary),
                title: Text('Bill: ${(p['bill_id'] ?? '').toString()}'),
                subtitle: Text((p['payment_date'] ?? '').toString()),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹ ${(p['amount'] ?? '').toString()}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          (p['payment_method'] ?? '').toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Receipt',
                      icon: const Icon(Icons.visibility),
                      onPressed: () => _previewReceipt(p),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
