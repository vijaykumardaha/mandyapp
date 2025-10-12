import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  late ThemeData theme;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: MyText.titleMedium('Terms & Conditions', fontWeight: 600),
      ),
      body: SingleChildScrollView(
        padding: MySpacing.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last Updated
            Center(
              child: Text(
                'Last Updated: January 2025',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            
            MySpacing.height(24),
            
            // Introduction
            _buildSectionTitle('1. Agreement to Terms'),
            MySpacing.height(12),
            _buildParagraph(
              'By accessing and using My Mandy application, you accept and agree to be bound by the terms and provisions of this agreement. If you do not agree to these terms, please do not use this application.',
            ),
            
            MySpacing.height(24),
            
            // License
            _buildSectionTitle('2. License to Use'),
            MySpacing.height(12),
            _buildParagraph(
              'We grant you a limited, non-exclusive, non-transferable license to use My Mandy for your personal or business purposes, subject to these terms and conditions.',
            ),
            MySpacing.height(12),
            _buildParagraph('You agree NOT to:'),
            MySpacing.height(8),
            _buildBulletPoint('Modify, copy, or create derivative works of the application'),
            _buildBulletPoint('Reverse engineer or attempt to extract the source code'),
            _buildBulletPoint('Remove any copyright or proprietary notices'),
            _buildBulletPoint('Use the application for any illegal purposes'),
            _buildBulletPoint('Transfer, sell, or sublicense the application to others'),
            
            MySpacing.height(24),
            
            // User Accounts
            _buildSectionTitle('3. User Accounts and Responsibilities'),
            MySpacing.height(12),
            _buildParagraph(
              'You are responsible for:',
            ),
            MySpacing.height(8),
            _buildBulletPoint('Maintaining the confidentiality of your account credentials'),
            _buildBulletPoint('All activities that occur under your account'),
            _buildBulletPoint('Ensuring the accuracy of information you provide'),
            _buildBulletPoint('Notifying us immediately of any unauthorized access'),
            
            MySpacing.height(24),
            
            // Acceptable Use
            _buildSectionTitle('4. Acceptable Use Policy'),
            MySpacing.height(12),
            _buildParagraph(
              'You agree to use My Mandy only for lawful purposes and in accordance with these terms. You agree not to:',
            ),
            MySpacing.height(8),
            _buildBulletPoint('Violate any applicable laws or regulations'),
            _buildBulletPoint('Infringe upon the rights of others'),
            _buildBulletPoint('Transmit any harmful or malicious code'),
            _buildBulletPoint('Interfere with the proper functioning of the application'),
            _buildBulletPoint('Attempt to gain unauthorized access to any systems'),
            
            MySpacing.height(24),
            
            // Data and Privacy
            _buildSectionTitle('5. Data and Privacy'),
            MySpacing.height(12),
            _buildParagraph(
              'Your use of My Mandy is also governed by our Privacy Policy. By using the application, you consent to the collection and use of your information as described in the Privacy Policy.',
            ),
            MySpacing.height(12),
            _buildParagraph(
              'You retain ownership of all data you input into the application. We do not claim any ownership rights to your business data.',
            ),
            
            MySpacing.height(24),
            
            // Intellectual Property
            _buildSectionTitle('6. Intellectual Property Rights'),
            MySpacing.height(12),
            _buildParagraph(
              'The application and its original content, features, and functionality are owned by My Mandy and are protected by international copyright, trademark, patent, trade secret, and other intellectual property laws.',
            ),
            
            MySpacing.height(24),
            
            // Disclaimer
            _buildSectionTitle('7. Disclaimer of Warranties'),
            MySpacing.height(12),
            _buildParagraph(
              'My Mandy is provided "AS IS" and "AS AVAILABLE" without warranties of any kind, either express or implied, including but not limited to:',
            ),
            MySpacing.height(8),
            _buildBulletPoint('Merchantability or fitness for a particular purpose'),
            _buildBulletPoint('Accuracy, reliability, or completeness of information'),
            _buildBulletPoint('Uninterrupted or error-free operation'),
            _buildBulletPoint('Security of data or prevention of unauthorized access'),
            
            MySpacing.height(24),
            
            // Limitation of Liability
            _buildSectionTitle('8. Limitation of Liability'),
            MySpacing.height(12),
            _buildParagraph(
              'To the maximum extent permitted by law, My Mandy shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including but not limited to loss of profits, data, or business opportunities.',
            ),
            
            MySpacing.height(24),
            
            // Indemnification
            _buildSectionTitle('9. Indemnification'),
            MySpacing.height(12),
            _buildParagraph(
              'You agree to indemnify and hold harmless My Mandy and its affiliates from any claims, damages, losses, liabilities, and expenses arising from your use of the application or violation of these terms.',
            ),
            
            MySpacing.height(24),
            
            // Termination
            _buildSectionTitle('10. Termination'),
            MySpacing.height(12),
            _buildParagraph(
              'We reserve the right to terminate or suspend your access to the application at any time, without prior notice, for any reason, including breach of these terms.',
            ),
            MySpacing.height(12),
            _buildParagraph(
              'Upon termination, your right to use the application will immediately cease. You may also terminate your account at any time by uninstalling the application.',
            ),
            
            MySpacing.height(24),
            
            // Updates and Modifications
            _buildSectionTitle('11. Updates and Modifications'),
            MySpacing.height(12),
            _buildParagraph(
              'We reserve the right to modify or discontinue the application at any time, with or without notice. We may also update these terms from time to time. Continued use of the application after changes constitutes acceptance of the new terms.',
            ),
            
            MySpacing.height(24),
            
            // Third-Party Services
            _buildSectionTitle('12. Third-Party Services'),
            MySpacing.height(12),
            _buildParagraph(
              'The application may contain links to third-party services or integrate with third-party platforms. We are not responsible for the content, privacy policies, or practices of any third-party services.',
            ),
            
            MySpacing.height(24),
            
            // Governing Law
            _buildSectionTitle('13. Governing Law'),
            MySpacing.height(12),
            _buildParagraph(
              'These terms shall be governed by and construed in accordance with the laws of India, without regard to its conflict of law provisions.',
            ),
            
            MySpacing.height(24),
            
            // Dispute Resolution
            _buildSectionTitle('14. Dispute Resolution'),
            MySpacing.height(12),
            _buildParagraph(
              'Any disputes arising from these terms or your use of the application shall be resolved through binding arbitration in accordance with the rules of the Indian Arbitration and Conciliation Act.',
            ),
            
            MySpacing.height(24),
            
            // Severability
            _buildSectionTitle('15. Severability'),
            MySpacing.height(12),
            _buildParagraph(
              'If any provision of these terms is found to be unenforceable or invalid, that provision will be limited or eliminated to the minimum extent necessary, and the remaining provisions will remain in full force and effect.',
            ),
            
            MySpacing.height(24),
            
            // Contact Information
            _buildSectionTitle('16. Contact Information'),
            MySpacing.height(12),
            _buildParagraph(
              'If you have any questions about these Terms & Conditions, please contact us:',
            ),
            MySpacing.height(12),
            
            Container(
              padding: MySpacing.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContactRow(Icons.email, 'support@mymandy.com'),
                  MySpacing.height(8),
                  _buildContactRow(Icons.phone, '+91 1234567890'),
                  MySpacing.height(8),
                  _buildContactRow(Icons.language, 'www.mymandy.com'),
                ],
              ),
            ),
            
            MySpacing.height(32),
            
            // Acceptance Notice
            Container(
              padding: MySpacing.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  MySpacing.width(12),
                  Expanded(
                    child: MyText.bodySmall(
                      'By using My Mandy, you acknowledge that you have read, understood, and agree to be bound by these Terms & Conditions.',
                      color: theme.colorScheme.onBackground.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            MySpacing.height(20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return MyText.titleMedium(
      title,
      fontWeight: 600,
      color: theme.colorScheme.primary,
    );
  }

  Widget _buildParagraph(String text) {
    return MyText.bodyMedium(
      text,
      color: theme.colorScheme.onBackground.withOpacity(0.8),
      height: 1.6,
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: MySpacing.only(left: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.bodyMedium(
            '• ',
            color: theme.colorScheme.primary,
            fontWeight: 600,
          ),
          Expanded(
            child: MyText.bodyMedium(
              text,
              color: theme.colorScheme.onBackground.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        MySpacing.width(12),
        MyText.bodyMedium(
          text,
          color: theme.colorScheme.onBackground.withOpacity(0.8),
        ),
      ],
    );
  }
}
