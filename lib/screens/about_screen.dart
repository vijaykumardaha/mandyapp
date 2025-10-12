import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
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
        title: MyText.titleMedium('About', fontWeight: 600),
      ),
      body: SingleChildScrollView(
        padding: MySpacing.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MySpacing.height(20),
            
            // App Icon/Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.shopping_bag,
                size: 60,
                color: theme.colorScheme.primary,
              ),
            ),
            
            MySpacing.height(24),
            
            // App Name
            MyText.headlineSmall(
              'My Mandy',
              fontWeight: 700,
              textAlign: TextAlign.center,
            ),
            
            MySpacing.height(8),
            
            // Version
            MyText.bodyMedium(
              'Version 1.0.0',
              color: theme.colorScheme.onBackground.withOpacity(0.6),
              textAlign: TextAlign.center,
            ),
            
            MySpacing.height(32),
            
            // Description
            Container(
              padding: MySpacing.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: MyText.bodyMedium(
                'My Mandy is a comprehensive business management application designed to help you manage your customers, suppliers, and transactions efficiently.',
                textAlign: TextAlign.center,
                color: theme.colorScheme.onBackground.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            
            MySpacing.height(32),
            
            // Features Section
            _buildSectionTitle('Features'),
            MySpacing.height(16),
            
            _buildFeatureItem(
              icon: Icons.people,
              title: 'Customer Management',
              description: 'Manage your customers and their transactions',
            ),
            
            _buildFeatureItem(
              icon: Icons.business,
              title: 'Supplier Management',
              description: 'Keep track of your suppliers and purchases',
            ),
            
            _buildFeatureItem(
              icon: Icons.receipt_long,
              title: 'Transaction History',
              description: 'View and manage all your business transactions',
            ),
            
            _buildFeatureItem(
              icon: Icons.analytics,
              title: 'Reports & Analytics',
              description: 'Get insights into your business performance',
            ),
            
            MySpacing.height(32),
            
            // Contact Information
            _buildSectionTitle('Contact Us'),
            MySpacing.height(16),
            
            _buildContactItem(
              icon: Icons.email,
              text: 'support@mymandy.com',
            ),
            
            _buildContactItem(
              icon: Icons.phone,
              text: '+91 1234567890',
            ),
            
            _buildContactItem(
              icon: Icons.language,
              text: 'www.mymandy.com',
            ),
            
            MySpacing.height(32),
            
            // Developer Info
            Container(
              padding: MySpacing.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.dividerColor,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  MyText.bodySmall(
                    'Developed with ❤️ by',
                    color: theme.colorScheme.onBackground.withOpacity(0.6),
                  ),
                  MySpacing.height(8),
                  MyText.bodyMedium(
                    'Mandy Team',
                    fontWeight: 600,
                  ),
                ],
              ),
            ),
            
            MySpacing.height(32),
            
            // Copyright
            MyText.bodySmall(
              '© 2025 My Mandy. All rights reserved.',
              color: theme.colorScheme.onBackground.withOpacity(0.4),
              textAlign: TextAlign.center,
            ),
            
            MySpacing.height(20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: MyText.titleMedium(
        title,
        fontWeight: 600,
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: MySpacing.bottom(12),
      padding: MySpacing.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: MySpacing.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 24,
              color: theme.colorScheme.primary,
            ),
          ),
          MySpacing.width(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText.bodyMedium(
                  title,
                  fontWeight: 600,
                ),
                MySpacing.height(4),
                MyText.bodySmall(
                  description,
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                  height: 1.4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String text,
  }) {
    return Container(
      margin: MySpacing.bottom(12),
      padding: MySpacing.xy(16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          MySpacing.width(12),
          MyText.bodyMedium(
            text,
            color: theme.colorScheme.onBackground.withOpacity(0.8),
          ),
        ],
      ),
    );
  }
}
