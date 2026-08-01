import 'package:flutter/material.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';

class ContentContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ThemeData theme;

  const ContentContactRow({
    super.key,
    required this.icon,
    required this.text,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
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
          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ],
    );
  }
}
