import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
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
              // App Logo/Icon Section
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.electric_bolt,
                    size: 60,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // App Name
              Center(
                child: Text(
                  'Utility Bill App',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
              const SizedBox(height: 8),

              // Version
              Center(
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // About Section
              _buildSection(
                context,
                title: 'Our Mission',
                icon: Icons.flag_outlined,
                children: [
                  const Text(
                    'Utility Bill App is designed to simplify and streamline the way you manage your utility bills. Our mission is to provide a convenient, secure, and efficient platform that empowers users to take control of their utility payments with ease.',
                    style: TextStyle(fontSize: 14, height: 1.6),
                  ),
                ],
              ),

              _buildSection(
                context,
                title: 'What We Offer',
                icon: Icons.check_circle_outline,
                children: [
                  _buildFeatureItem('Easy bill management and tracking'),
                  _buildFeatureItem('Secure online payment processing'),
                  _buildFeatureItem('Payment history and records'),
                  _buildFeatureItem('Real-time notifications and reminders'),
                  _buildFeatureItem('Multiple utility service support'),
                  _buildFeatureItem('24/7 customer support'),
                ],
              ),

              _buildSection(
                context,
                title: 'Our Values',
                icon: Icons.favorite_outline,
                children: [
                  _buildValueItem('Security First', 'Your data and transactions are protected with industry-leading security measures.'),
                  const SizedBox(height: 12),
                  _buildValueItem('User-Centric', 'We design every feature with your convenience and experience in mind.'),
                  const SizedBox(height: 12),
                  _buildValueItem('Transparency', 'No hidden fees, clear terms, and honest communication.'),
                  const SizedBox(height: 12),
                  _buildValueItem('Innovation', 'Continuously improving to provide the best utility management experience.'),
                ],
              ),

              _buildSection(
                context,
                title: 'Contact Us',
                icon: Icons.contact_support_outlined,
                children: [
                  _buildContactItem(Icons.email_outlined, 'Email', 'support@utilitybillapp.com'),
                  const SizedBox(height: 12),
                  _buildContactItem(Icons.phone_outlined, 'Phone', '+1 (800) 123-4567'),
                  const SizedBox(height: 12),
                  _buildContactItem(Icons.location_on_outlined, 'Address', '[Your Company Address]'),
                  const SizedBox(height: 12),
                  _buildContactItem(Icons.language_outlined, 'Website', 'www.utilitybillapp.com'),
                ],
              ),

              // Social Media Section
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.share_outlined, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Follow Us',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSocialButton(context, Icons.facebook, 'Facebook'),
                          _buildSocialButton(context, Icons.camera_alt, 'Instagram'),
                          _buildSocialButton(context, Icons.telegram, 'Twitter'),
                          _buildSocialButton(context, Icons.link, 'LinkedIn'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Footer
              Center(
                child: Column(
                  children: [
                    Text(
                      '© 2026 Utility Bill App',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All rights reserved',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
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
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
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

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton(BuildContext context, IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
