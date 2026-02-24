import 'package:flutter/material.dart';
import '../../widgets/theme_header.dart';

class UtilityPrivacyPage extends StatelessWidget {
  const UtilityPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CurvedHeaderPage(
      title: 'Privacy Policy',
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
            const Text(
              'Your Privacy Matters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Data Collection',
              'We collect utility account information that you voluntarily provide, including your name, email, and utility type details. This data is securely stored and used solely for bill management, notifications, and improving your experience.',
            ),
            _buildSection(
              'Data Usage',
              'Your information is used to:\n• Send utility bills and notifications\n• Process payments securely\n• Generate health scores and reports\n• Communicate important updates\n• Improve service quality',
            ),
            _buildSection(
              'Data Security',
              'We implement industry-standard security measures including encryption, secure authentication, and regular security audits to protect your personal and financial information.',
            ),
            _buildSection(
              'Third-Party Sharing',
              'We do not sell or share your personal information with third parties. Information is only shared with your utility provider as part of the service and with payment processors for transaction handling.',
            ),
            _buildSection(
              'Your Rights',
              'You have the right to:\n• Access your stored information\n• Request corrections to your data\n• Request deletion of your account\n• Opt-out of promotional communications',
            ),
            _buildSection(
              'Contact Us',
              'For privacy concerns or inquiries, please contact our support team at support@utilitybill.com or call our helpline.',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Last updated: February 24, 2026',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
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
