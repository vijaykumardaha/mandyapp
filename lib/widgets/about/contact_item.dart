import 'package:flutter/material.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';

class ContactItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final ThemeData theme;

  const ContactItem({
    super.key,
    required this.icon,
    required this.text,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
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
