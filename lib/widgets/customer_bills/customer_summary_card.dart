import 'package:flutter/material.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';

class CustomerSummaryCard extends StatelessWidget {
  final String label;
  final String count;
  final String amount;
  final Color color;

  const CustomerSummaryCard({
    super.key,
    required this.label,
    required this.count,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: MySpacing.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          MyText.bodySmall(label, color: color, fontWeight: 600),
          MySpacing.height(2),
          MyText.titleSmall(count, fontWeight: 700),
          MySpacing.height(2),
          MyText.bodySmall(
            amount,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}
