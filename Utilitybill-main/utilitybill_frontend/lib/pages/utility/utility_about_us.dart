import 'package:flutter/material.dart';
import '../../widgets/theme_header.dart';

class UtilityAboutUsPage extends StatelessWidget {
  const UtilityAboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CurvedHeaderPage(
      title: 'About Us',
      headerHeight: 140,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Back',
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.build,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Utility Bill Management System',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildSection(
              'Our Mission',
              'We aim to simplify utility bill management by providing a unified platform for tracking, paying, and managing all your utility expenses in one place.',
            ),
            _buildSection(
              'What We Offer',
              '• Centralized bill management across multiple utilities\n• Real-time health score tracking\n• Secure payment processing\n• Instant notifications and updates\n• Budget and spending analytics\n• Rewards and cashback programs',
            ),
            _buildSection(
              'Our Values',
              '• Security: Your data is protected with industry-standard encryption\n• Transparency: Clear information about all fees and charges\n• Customer Focus: We prioritize your satisfaction and feedback\n• Innovation: Continuously improving to serve you better',
            ),
            _buildSection(
              'Recent Updates',
              '• Added alert broadcast system for utility authorities\n• Enhanced notification preferences\n• Improved user dashboard and health scores\n• New wallet and cashback features',
            ),
            _buildSection(
              'Support',
              'Need help? Contact our support team:\n• Email: support@utilitybill.com\n• Phone: 1-800-UTILITY\n• Website: www.utilitybill.com\n• Hours: 24/7 customer support',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  const Text(
                    'Thank You!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We appreciate your trust and continued support. Together, we\'re making utility bill management simpler and more accessible.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
