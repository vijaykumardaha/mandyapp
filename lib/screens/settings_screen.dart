import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:krishimandi/blocs/login/login_bloc.dart';
import 'package:krishimandi/helpers/theme/app_theme.dart';
import 'package:krishimandi/widgets/common/common_app_bar.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';
import 'package:krishimandi/widgets/settings/settings_tile.dart';

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
      appBar: const CommonAppBar(
        showBackButton: false,
        title: 'Mandi Settings',
      ),
      body: SafeArea(
        child: BlocListener<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is LogoutSuccess) {
              context.go('/login');
            }
          },
          child: ListView(
            padding: MySpacing.all(16),
            children: [
              MySpacing.height(8),

              SettingsTile(
                icon: Icons.person_outline,
                title: 'Profile',
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
                icon: Icons.inventory,
                title: 'Stocks',
                theme: theme,
                onTap: () => context.push('/stock'),
              ),
              SettingsTile(
                icon: Icons.receipt_long_outlined,
                title: 'Transaction',
                theme: theme,
                onTap: () => context.push('/other-transactions'),
              ),
              SettingsTile(
                icon: Icons.print_outlined,
                title: 'Printer',
                theme: theme,
                onTap: () => context.push('/printer-settings'),
              ),

              MySpacing.height(24),

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
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const MyText.titleMedium('Logout', fontWeight: 600),
        content: const MyText.bodyMedium('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: MyText.bodyMedium(
              'Cancel',
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<LoginBloc>().add(LogoutSubmit());
            },
            child: const MyText.bodyMedium(
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
