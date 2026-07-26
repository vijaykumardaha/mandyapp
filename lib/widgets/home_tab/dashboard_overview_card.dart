import 'package:flutter/material.dart';
import 'package:mandyapp/widgets/common/my_text.dart';

class DashboardOverviewCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final ThemeData theme;

  const DashboardOverviewCard({
    super.key,
    required this.title,
    required this.children,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.titleMedium(title, fontWeight: 600),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
