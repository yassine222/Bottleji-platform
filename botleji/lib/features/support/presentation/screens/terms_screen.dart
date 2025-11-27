import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms and Conditions'),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Terms of Service',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Last updated: March 15, 2024',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          const _TermsSection(
            title: '1. Acceptance of Terms',
            content:
                'By accessing and using the Bottleji application, you agree to be bound by these Terms and Conditions. If you disagree with any part of these terms, you may not access the application.',
          ),
          const _TermsSection(
            title: '2. User Responsibilities',
            content: '''As a user of Bottleji, you agree to:
• Provide accurate and complete information
• Maintain the security of your account
• Follow waste segregation guidelines
• Schedule collections responsibly
• Use the service in accordance with local laws''',
          ),
          const _TermsSection(
            title: '3. Service Description',
            content:
                'Bottleji provides a platform for bottle collection and recycling services. We facilitate the connection between bottle collectors and households, while promoting environmental sustainability.',
          ),
          const _TermsSection(
            title: '4. Privacy Policy',
            content:
                'Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect your personal information when you use our service.',
          ),
          const _TermsSection(
            title: '5. User Data',
            content:
                'We collect and process user data as described in our Privacy Policy. By using Bottleji, you consent to such processing and warrant that all data provided by you is accurate.',
          ),
          const _TermsSection(
            title: '6. Service Availability',
            content:
                'While we strive to provide uninterrupted service, we cannot guarantee that the service will be available at all times. We reserve the right to modify or discontinue the service with or without notice.',
          ),
          const _TermsSection(
            title: '7. Rewards Program',
            content:
                'Points and rewards earned through the app are subject to our Rewards Program Terms. We reserve the right to modify or terminate the rewards program at any time.',
          ),
          const _TermsSection(
            title: '8. Limitation of Liability',
            content:
                'Bottleji shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use or inability to use the service.',
          ),
          const _TermsSection(
            title: '9. Changes to Terms',
            content:
                'We reserve the right to modify these terms at any time. We will notify users of any material changes via the app or email.',
          ),
          const _TermsSection(
            title: '10. Contact Us',
            content:
                'If you have any questions about these Terms, please contact us at support@bottleji.com',
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('I Agree'),
          ),
        ],
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  final String title;
  final String content;

  const _TermsSection({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
