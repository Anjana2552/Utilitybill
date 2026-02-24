import 'package:flutter/material.dart';

class PrivacyCenterPage extends StatelessWidget {
  const PrivacyCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to Utility Bill App',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your information when you use our mobile application and services.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section 1: Information We Collect
              _buildSection(
                context,
                number: '1️⃣',
                title: 'Information We Collect',
                children: [
                  _buildSubsection('Personal Information', [
                    'Name',
                    'Email address',
                    'Mobile number',
                    'Account login details',
                  ]),
                  const SizedBox(height: 16),
                  _buildSubsection('Billing Information', [
                    'Utility account numbers',
                    'Payment history',
                    'Transaction details',
                  ]),
                  const SizedBox(height: 16),
                  _buildSubsection('Device Information', [
                    'Device type',
                    'Operating system',
                    'App usage data',
                  ]),
                  const SizedBox(height: 16),
                  const Text(
                    'We collect this information only to provide better service and improve user experience.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                ],
              ),

              // Section 2: How We Use Your Information
              _buildSection(
                context,
                number: '2️⃣',
                title: 'How We Use Your Information',
                children: [
                  _buildBulletList([
                    'Provide bill payment services',
                    'Process transactions securely',
                    'Show payment history',
                    'Send important notifications',
                    'Improve application performance',
                    'Provide customer support',
                  ]),
                  const SizedBox(height: 16),
                  const Text(
                    'We do not sell or rent your personal data to third parties.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // Section 3: Payment Security
              _buildSection(
                context,
                number: '3️⃣',
                title: 'Payment Security',
                children: [
                  _buildBulletList([
                    'All payments are processed through secure third-party payment gateways',
                    'We do not store your debit/credit card details on our servers',
                  ]),
                ],
              ),

              // Section 4: Data Protection
              _buildSection(
                context,
                number: '4️⃣',
                title: 'Data Protection',
                children: [
                  const Text(
                    'We implement industry-standard security measures to protect your data from:',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletList([
                    'Unauthorized access',
                    'Data loss',
                    'Misuse or alteration',
                  ]),
                  const SizedBox(height: 12),
                  const Text(
                    'However, no internet transmission is 100% secure.',
                    style: TextStyle(fontSize: 13, color: Colors.orange, fontStyle: FontStyle.italic),
                  ),
                ],
              ),

              // Section 5: Sharing of Information
              _buildSection(
                context,
                number: '5️⃣',
                title: 'Sharing of Information',
                children: [
                  const Text(
                    'We may share limited information only with:',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletList([
                    'Payment service providers',
                    'Legal authorities when required by law',
                    'Service partners necessary for app functionality',
                  ]),
                ],
              ),

              // Section 6: User Responsibilities
              _buildSection(
                context,
                number: '6️⃣',
                title: 'User Responsibilities',
                children: [
                  const Text(
                    'Users are responsible for:',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletList([
                    'Keeping login credentials secure',
                    'Not sharing passwords with others',
                    'Reporting suspicious activity immediately',
                  ]),
                ],
              ),

              // Section 7: Cookies & Analytics
              _buildSection(
                context,
                number: '7️⃣',
                title: 'Cookies & Analytics',
                children: [
                  _buildBulletList([
                    'The app may use analytics tools to understand usage patterns and improve services',
                    'No personally identifiable information is tracked without consent',
                  ]),
                ],
              ),

              // Section 8: Changes to Privacy Policy
              _buildSection(
                context,
                number: '8️⃣',
                title: 'Changes to Privacy Policy',
                children: [
                  _buildBulletList([
                    'We may update this Privacy Policy from time to time',
                    'Users will be notified through the application when significant changes occur',
                  ]),
                ],
              ),

              // Section 9: Contact Us
              _buildSection(
                context,
                number: '9️⃣',
                title: 'Contact Us',
                children: [
                  const Text(
                    'If you have any questions regarding this Privacy Policy, contact us:',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.email_outlined, color: Colors.blue.shade600, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Email: support@utilitybillapp.com',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, color: Colors.blue.shade600, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Address: Utility Bill App',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Last Updated
              Center(
                child: Text(
                  'Last updated: February 22, 2026',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String number,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              number,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSubsection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '✅ $title',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 13)),
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            Expanded(
              child: Text(
                item,
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}
