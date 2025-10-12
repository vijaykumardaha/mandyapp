import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
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
        title: MyText.titleMedium('Privacy Policy', fontWeight: 600),
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
            _buildSectionTitle('Introduction'),
            MySpacing.height(12),
            _buildParagraph(
              'Welcome to My Mandy. We respect your privacy and are committed to protecting your personal data. This privacy policy will inform you about how we handle your personal data when you use our application.',
            ),
            
            MySpacing.height(24),
            
            // Information We Collect
            _buildSectionTitle('Information We Collect'),
            MySpacing.height(12),
            _buildParagraph(
              'We collect and process the following types of information:',
            ),
            MySpacing.height(8),
            _buildBulletPoint('Personal identification information (Name, Mobile Number)'),
            _buildBulletPoint('Business information (Customer and Supplier details)'),
            _buildBulletPoint('Transaction records and payment information'),
            _buildBulletPoint('Device information and usage data'),
            
            MySpacing.height(24),
            
            // How We Use Your Information
            _buildSectionTitle('How We Use Your Information'),
            MySpacing.height(12),
            _buildParagraph(
              'We use the information we collect for the following purposes:',
            ),
            MySpacing.height(8),
            _buildBulletPoint('To provide and maintain our service'),
            _buildBulletPoint('To manage your account and business operations'),
            _buildBulletPoint('To process transactions and maintain records'),
            _buildBulletPoint('To improve our application and user experience'),
            _buildBulletPoint('To send you notifications and updates'),
            
            MySpacing.height(24),
            
            // Data Storage and Security
            _buildSectionTitle('Data Storage and Security'),
            MySpacing.height(12),
            _buildParagraph(
              'Your data is stored locally on your device using secure SQLite database. We implement appropriate security measures to protect your personal information from unauthorized access, alteration, disclosure, or destruction.',
            ),
            MySpacing.height(12),
            _buildParagraph(
              'However, please note that no method of electronic storage is 100% secure, and we cannot guarantee absolute security.',
            ),
            
            MySpacing.height(24),
            
            // Data Sharing
            _buildSectionTitle('Data Sharing and Disclosure'),
            MySpacing.height(12),
            _buildParagraph(
              'We do not sell, trade, or rent your personal information to third parties. Your data remains on your device and is not transmitted to external servers unless explicitly stated for specific features.',
            ),
            MySpacing.height(12),
            _buildParagraph(
              'We may share your information only in the following circumstances:',
            ),
            MySpacing.height(8),
            _buildBulletPoint('With your explicit consent'),
            _buildBulletPoint('To comply with legal obligations'),
            _buildBulletPoint('To protect our rights and safety'),
            
            MySpacing.height(24),
            
            // Your Rights
            _buildSectionTitle('Your Rights'),
            MySpacing.height(12),
            _buildParagraph(
              'You have the right to:',
            ),
            MySpacing.height(8),
            _buildBulletPoint('Access your personal data'),
            _buildBulletPoint('Correct inaccurate data'),
            _buildBulletPoint('Delete your data'),
            _buildBulletPoint('Export your data'),
            _buildBulletPoint('Withdraw consent at any time'),
            
            MySpacing.height(24),
            
            // SMS Permissions
            _buildSectionTitle('SMS Permissions'),
            MySpacing.height(12),
            _buildParagraph(
              'Our app requests SMS permissions to send transaction notifications to your customers. These permissions are used solely for business communication purposes and we do not read or store your personal SMS messages.',
            ),
            
            MySpacing.height(24),
            
            // Contacts Permissions
            _buildSectionTitle('Contacts Permissions'),
            MySpacing.height(12),
            _buildParagraph(
              'We request access to your contacts to help you quickly add customers and suppliers. Contact information is stored locally and is not shared with any third parties.',
            ),
            
            MySpacing.height(24),
            
            // Children\'s Privacy
            _buildSectionTitle('Children\'s Privacy'),
            MySpacing.height(12),
            _buildParagraph(
              'Our service is not intended for use by children under the age of 13. We do not knowingly collect personal information from children under 13.',
            ),
            
            MySpacing.height(24),
            
            // Changes to Privacy Policy
            _buildSectionTitle('Changes to This Privacy Policy'),
            MySpacing.height(12),
            _buildParagraph(
              'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.',
            ),
            
            MySpacing.height(24),
            
            // Contact Us
            _buildSectionTitle('Contact Us'),
            MySpacing.height(12),
            _buildParagraph(
              'If you have any questions about this Privacy Policy, please contact us:',
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
            
            // Agreement Notice
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
                    Icons.info_outline,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  MySpacing.width(12),
                  Expanded(
                    child: MyText.bodySmall(
                      'By using My Mandy, you agree to the collection and use of information in accordance with this Privacy Policy.',
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
