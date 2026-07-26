import 'package:flutter/material.dart';
import 'package:mandyapp/widgets/common/my_spacing.dart';
import 'package:mandyapp/widgets/common/my_text.dart';

class ReportSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const ReportSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: MySpacing.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          MyText.bodySmall(title, color: color, fontWeight: 600),
          MySpacing.height(2),
          MyText.titleSmall(value, fontWeight: 700, color: color),
        ],
      ),
    );
  }
}
