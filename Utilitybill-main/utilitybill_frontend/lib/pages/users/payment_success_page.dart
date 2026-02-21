import 'package:flutter/material.dart';

class PaymentSuccessPage extends StatelessWidget {
  final int billsCount;
  final double totalAmount;
  final String methodLabel;

  const PaymentSuccessPage({
    super.key,
    this.billsCount = 0,
    this.totalAmount = 0.0,
    this.methodLabel = '',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(title: const Text('Payment')), 
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 16),
              const Text(
                'Payment Successful',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Waiting for admin approval within 24 hrs',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              if (billsCount > 0)
                Text(
                  '$billsCount bill(s) • ₹ ${totalAmount.toStringAsFixed(2)} via $methodLabel',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, '/user/payment_history'),
                    child: const Text('View History'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                    child: const Text('Go Home'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
