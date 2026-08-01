import 'package:flutter/material.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';

class ContentBulletPoint extends StatelessWidget {
  final String text;
  final ThemeData theme;

  const ContentBulletPoint({
    super.key,
    required this.text,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
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
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
