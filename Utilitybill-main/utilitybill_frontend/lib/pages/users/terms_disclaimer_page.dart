import 'package:flutter/material.dart';

class TermsDisclaimerPage extends StatelessWidget {
  const TermsDisclaimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Disclaimer'),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to Utility Bill App',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'By accessing or using this application, you agree to comply with the following Terms & Conditions.',
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

              // Section 1: Acceptance of Terms
              _buildSection(
                context,
                title: '  Acceptance of Terms',
                children: [
                  const Text(
                    'By creating an account or using our services, you agree to be bound by these terms. If you do not agree, please do not use the application.',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),

              // Section 2: Services Provided
              _buildSection(
                context,
                title: '  Services Provided',
                children: [
                  const Text(
                    'Utility Bill App allows users to:',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletList([
                    'Add and manage utility bills',
                    'View billing information',
                    'Make online payments',
                    'Track payment history',
                  ]),
                  const SizedBox(height: 12),
                  const Text(
                    'We reserve the right to modify or discontinue services at any time.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Section 3: User Account Responsibilities
              _buildSection(
                context,
                title: '  User Account Responsibilities',
                children: [
                  const Text(
                    'Users must:',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletList([
                    'Provide accurate information',
                    'Maintain confidentiality of login credentials',
                    'Be responsible for all activities under their account',
                  ]),
                  const SizedBox(height: 12),
                  const Text(
                    'We are not responsible for unauthorized access caused by user negligence.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Section 4: Payments
              _buildSection(
                context,
                title: '  Payments',
                children: [
                  _buildBulletList([
                    'Payments are processed via secure third-party payment gateways',
                    'Transaction success depends on banks and payment providers',
                    'We are not liable for delays or failures caused by external services',
                  ]),
                ],
              ),

              // Section 5: Prohibited Use
              _buildSection(
                context,
                title: '  Prohibited Use',
                children: [
                  const Text(
                    'Users must not:',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletList([
                    'Use the app for illegal activities',
                    'Attempt to hack or disrupt services',
                    'Misuse payment systems',
                  ]),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.red.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Violation may result in account suspension.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Section 6: Limitation of Liability
              _buildSection(
                context,
                title: '  Limitation of Liability',
                children: [
                  const Text(
                    'Utility Bill App is not responsible for:',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletList([
                    'Incorrect bill data provided by service providers',
                    'Payment gateway failures',
                    'Network or technical interruptions',
                  ]),
                ],
              ),

              // Section 7: Changes to Terms
              _buildSection(
                context,
                title: '  Changes to Terms',
                children: [
                  const Text(
                    'We may update these Terms & Conditions anytime. Continued use of the app means acceptance of updated terms.',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),

              // Section 8: Contact Information
              _buildSection(
                context,
                title: '  Contact Information',
                children: [
                  const Text(
                    'For support or queries:',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.email_outlined,
                            color: Colors.blue.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'support@utilitybillapp.com',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Disclaimer Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200, width: 2),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange.shade700, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          'Disclaimer',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDisclaimerText(
                      'The information and services provided in Utility Bill App are for convenience purposes only.',
                    ),
                    const SizedBox(height: 10),
                    _buildDisclaimerText(
                      'We do not guarantee accuracy of billing information received from third-party utility providers.',
                    ),
                    const SizedBox(height: 10),
                    _buildDisclaimerText(
                      'Payment confirmations depend on external banking systems.',
                    ),
                    const SizedBox(height: 10),
                    _buildDisclaimerText(
                      'Users should verify bill details before making payments.',
                    ),
                    const SizedBox(height: 10),
                    _buildDisclaimerText(
                      'The app shall not be held responsible for financial loss caused by incorrect user input or third-party service failure.',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Use of this application is at your own risk.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
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
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildBulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 13, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildDisclaimerText(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• ',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.orange.shade900,
            ),
          ),
        ),
      ],
    );
  }
}