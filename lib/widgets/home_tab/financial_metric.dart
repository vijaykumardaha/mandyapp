import 'package:flutter/material.dart';
import 'package:mandiapp/widgets/common/my_text.dart';

class FinancialMetric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final ThemeData theme;

  const FinancialMetric({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        MyText.bodySmall(
          title,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          fontWeight: 500,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        MyText.titleSmall(
          value,
          fontWeight: 700,
          color: theme.colorScheme.onSurface,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
