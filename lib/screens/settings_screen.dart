import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mandyapp/blocs/login/login_bloc.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemeData theme;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LogoutSuccess) {
            context.go('/login');
          }
        },
        child: ListView(
          padding: MySpacing.all(16),
          children: [
            MySpacing.height(40),
            
            // Profile Section
            _buildSectionHeader('Profile'),
            _buildSettingsTile(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () {
                // Navigate to profile screen
                context.push('/profile');
              },
            ),
            
            MySpacing.height(24),
            
            // App Settings Section
            _buildSectionHeader('App Settings'),
            _buildSettingsTile(
              icon: Icons.notifications_none,
              title: 'Notifications',
              onTap: () {
                context.push('/notification-settings');
              },
            ),
            _buildSettingsTile(
              icon: Icons.language,
              title: 'Language',
              onTap: () {
                context.push('/language-settings');
              },
            ),
            _buildSettingsTile(
              icon: Icons.palette,
              title: 'Theme',
              onTap: () {
                context.push('/theme-settings');
              },
            ),
            
            MySpacing.height(24),
            
            // About Section
            _buildSectionHeader('About'),
            _buildSettingsTile(
              icon: Icons.info_outline,
              title: 'About App',
              onTap: () {
                context.push('/about');
              },
            ),
            _buildSettingsTile(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              onTap: () {
                context.push('/privacy-policy');
              },
            ),
            _buildSettingsTile(
              icon: Icons.description,
              title: 'Terms & Conditions',
              onTap: () {
                context.push('/terms-conditions');
              },
            ),
            
            MySpacing.height(24),
            
            // Logout Section
            _buildSectionHeader('Account'),
            _buildSettingsTile(
              icon: Icons.logout,
              title: 'Logout',
              iconColor: Colors.red,
              titleColor: Colors.red,
              onTap: () {
                _showLogoutDialog();
              },
            ),
            
            MySpacing.height(40),
            
            // App Version
            Center(
              child: MyText.bodySmall(
                'Version 1.0.0',
                color: theme.colorScheme.onBackground.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: MySpacing.bottom(12),
      child: MyText.titleSmall(
        title,
        fontWeight: 600,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: MySpacing.xy(12, 16),
        margin: MySpacing.bottom(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.dividerColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: iconColor ?? theme.colorScheme.onBackground.withOpacity(0.7),
            ),
            MySpacing.width(16),
            Expanded(
              child: MyText.bodyMedium(
                title,
                fontWeight: 500,
                color: titleColor ?? theme.colorScheme.onBackground,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onBackground.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: MyText.titleMedium('Logout', fontWeight: 600),
        content: MyText.bodyMedium('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: MyText.bodyMedium(
              'Cancel',
              color: theme.colorScheme.onBackground.withOpacity(0.6),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<LoginBloc>().add(LogoutSubmit());
            },
            child: MyText.bodyMedium(
              'Logout',
              color: Colors.red,
              fontWeight: 600,
            ),
          ),
        ],
      ),
    );
  }
}
