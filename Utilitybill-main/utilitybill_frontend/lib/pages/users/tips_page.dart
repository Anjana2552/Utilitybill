import 'package:flutter/material.dart';

class TipsPage extends StatelessWidget {
  const TipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Payment Tips'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    size: 40,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Helpful Tips',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Learn about different utility bills',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Electricity Bill Card
          _buildTipCard(
            context,
            icon: Icons.electric_bolt,
            iconColor: Colors.amber,
            title: 'Electricity Bill',
            description: 'Pay your electricity bills on time to avoid disconnection. Check your meter reading regularly and report any discrepancies immediately.',
            tips: [
              'Save energy by using LED bulbs',
              'Unplug devices when not in use',
              'Pay before due date to avoid penalties',
              'Set up auto-pay for convenience',
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Water Bill Card
          _buildTipCard(
            context,
            icon: Icons.water_drop,
            iconColor: Colors.blue,
            title: 'Water Bill',
            description: 'Regular water bill payments ensure uninterrupted water supply. Monitor your water usage to manage costs effectively.',
            tips: [
              'Fix leaking taps to save water',
              'Check for unusual consumption patterns',
              'Pay bills to avoid supply disruption',
              'Report meter issues promptly',
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Gas Bill Card
          _buildTipCard(
            context,
            icon: Icons.local_fire_department,
            iconColor: Colors.orange,
            title: 'Gas Bill',
            description: 'Keep track of your gas consumption and pay bills on time for continuous service.',
            tips: [
              'Ensure proper gas connection maintenance',
              'Report gas leaks immediately',
              'Schedule regular safety inspections',
              'Pay bills to maintain supply',
            ],
          ),
          
          const SizedBox(height: 16),
          
          // WiFi Bill Card
          _buildTipCard(
            context,
            icon: Icons.wifi,
            iconColor: Colors.purple,
            title: 'WiFi Bill',
            description: 'Timely payment ensures uninterrupted internet connectivity for your home or office.',
            tips: [
              'Restart router if connection is slow',
              'Change password regularly for security',
              'Monitor data usage if capped',
              'Pay before due date to avoid disconnection',
            ],
          ),
          
          const SizedBox(height: 16),
          
          // DTH Bill Card
          _buildTipCard(
            context,
            icon: Icons.tv,
            iconColor: Colors.teal,
            title: 'DTH Bill',
            description: 'Keep your DTH subscription active by paying bills on time to enjoy uninterrupted entertainment.',
            tips: [
              'Recharge before expiry date',
              'Choose plans based on viewing habits',
              'Check for promotional offers',
              'Keep account details updated',
            ],
          ),
          
          const SizedBox(height: 20),
          
          // General Tips Card
          Card(
            elevation: 2,
            color: scheme.primaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tips_and_updates, color: scheme.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Text(
                        'General Payment Tips',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildBulletPoint('Always keep bill receipts for reference'),
                  _buildBulletPoint('Set reminders for due dates'),
                  _buildBulletPoint('Use wallet feature for faster payments'),
                  _buildBulletPoint('Check notifications regularly'),
                  _buildBulletPoint('Contact provider for billing disputes'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTipCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required List<String> tips,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tips:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...tips.map((tip) => _buildBulletPoint(tip)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
