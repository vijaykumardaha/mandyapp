import 'package:flutter/material.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;
  final ThemeData theme;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.titleColor,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: MySpacing.xy(12, 16),
        margin: MySpacing.bottom(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.dividerColor,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: iconColor ??
                  theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            MySpacing.width(16),
            Expanded(
              child: MyText.bodyMedium(
                title,
                fontWeight: 500,
                color: titleColor ?? theme.colorScheme.onSurface,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
