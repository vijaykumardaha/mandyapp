import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mandyapp/helpers/theme/app_notifier.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/theme/theme_type.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:provider/provider.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
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
        title: MyText.titleMedium('Theme Settings', fontWeight: 600),
      ),
      body: Consumer<AppNotifier>(
        builder: (context, appNotifier, child) {
          return ListView(
            padding: MySpacing.all(20),
            children: [
              MySpacing.height(8),
              
              // Header
              MyText.bodyMedium(
                'Choose your preferred theme',
                color: theme.colorScheme.onBackground.withOpacity(0.6),
              ),
              
              MySpacing.height(24),
              
              // Light Theme Option
              _buildThemeOption(
                context: context,
                themeType: ThemeType.light,
                title: 'Light Theme',
                description: 'Classic light appearance',
                icon: Icons.light_mode,
                isSelected: AppTheme.themeType == ThemeType.light,
                onTap: () {
                  appNotifier.updateTheme(ThemeType.light);
                  setState(() {
                    theme = AppTheme.shoppingManagerTheme;
                  });
                },
              ),
              
              MySpacing.height(16),
              
              // Dark Theme Option
              _buildThemeOption(
                context: context,
                themeType: ThemeType.dark,
                title: 'Dark Theme',
                description: 'Easy on the eyes in low light',
                icon: Icons.dark_mode,
                isSelected: AppTheme.themeType == ThemeType.dark,
                onTap: () {
                  appNotifier.updateTheme(ThemeType.dark);
                  setState(() {
                    theme = AppTheme.shoppingManagerTheme;
                  });
                },
              ),
              
              MySpacing.height(32),
              
              // Info Card
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
                        'Your theme preference will be saved and applied across the entire app.',
                        color: theme.colorScheme.onBackground.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required ThemeType themeType,
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: MySpacing.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            // Theme Icon
            Container(
              padding: MySpacing.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withOpacity(0.2)
                    : theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
            
            MySpacing.width(16),
            
            // Theme Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText.bodyLarge(
                    title,
                    fontWeight: 600,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onBackground,
                  ),
                  MySpacing.height(4),
                  MyText.bodySmall(
                    description,
                    color: theme.colorScheme.onBackground.withOpacity(0.6),
                  ),
                ],
              ),
            ),
            
            // Selection Indicator
            if (isSelected)
              Container(
                padding: MySpacing.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: 16,
                  color: theme.colorScheme.onPrimary,
                ),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.dividerColor,
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
