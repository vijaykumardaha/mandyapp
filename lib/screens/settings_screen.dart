import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mandiapp/blocs/login/login_bloc.dart';
import 'package:mandiapp/helpers/theme/app_theme.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';
import 'package:mandiapp/widgets/settings/settings_tile.dart';

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
            
            // Business Section
            SettingsSectionHeader(title: 'Business', theme: theme),
            SettingsTile(
              icon: Icons.person_outline,
              title: 'My Profile',
              theme: theme,
              onTap: () => context.push('/profile'),
            ),
            SettingsTile(
              icon: Icons.help_center,
              title: 'Staff',
              theme: theme,
              onTap: () => context.push('/staff'),
            ),
            SettingsTile(
              icon: Icons.inventory_2,
              title: 'Products',
              theme: theme,
              onTap: () => context.push('/products'),
            ),
            SettingsTile(
              icon: Icons.account_balance_wallet,
              title: 'Charges',
              theme: theme,
              onTap: () => context.push('/charges'),
            ),
            SettingsTile(
              icon: Icons.print_outlined,
              title: 'Printer',
              theme: theme,
              onTap: () => context.push('/printer-settings'),
            ),
            
            MySpacing.height(24),
            
            // About Section
            SettingsSectionHeader(title: 'About', theme: theme),
            SettingsTile(
              icon: Icons.info_outline,
              title: 'About App',
              theme: theme,
              onTap: () => context.push('/about'),
            ),
            SettingsTile(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              theme: theme,
              onTap: () => context.push('/privacy-policy'),
            ),
            SettingsTile(
              icon: Icons.description,
              title: 'Terms & Conditions',
              theme: theme,
              onTap: () => context.push('/terms-conditions'),
            ),
            
            MySpacing.height(24),
            
            // Logout Section
            SettingsSectionHeader(title: 'Account', theme: theme),
            SettingsTile(
              icon: Icons.logout,
              title: 'Logout',
              theme: theme,
              iconColor: Colors.red,
              titleColor: Colors.red,
              onTap: () => _showLogoutDialog(),
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
