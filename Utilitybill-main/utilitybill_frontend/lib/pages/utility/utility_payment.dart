import 'package:flutter/material.dart';
import '../../widgets/theme_header.dart';

class UtilityPaymentPage extends StatelessWidget {
  const UtilityPaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CurvedHeaderPage(
      title: 'Payments',
      headerHeight: 180,
      headerColor: const Color(0xFF4C6EF5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFF7FD9CE), child: Icon(Icons.receipt_long, color: Colors.white)),
              title: const Text('Make a Payment'),
              subtitle: const Text('Pay your latest utility bill'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment flow coming soon')),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text('Recent Payments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.payment, color: Colors.green),
                  title: Text('Invoice #${1001 + index}'),
                  subtitle: const Text('Paid via UPI'),
                  trailing: const Text('₹ 1,250', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
