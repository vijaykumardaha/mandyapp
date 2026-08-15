import 'package:flutter/material.dart';
import 'package:krishimandi/widgets/common/my_text.dart';

class DashboardOverviewCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final ThemeData theme;

  const DashboardOverviewCard({
    super.key,
    required this.title,
    this.subtitle,
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
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: MyText.titleMedium(title, fontWeight: 600),
              ),
              if (subtitle != null)
                MyText.bodySmall(
                  subtitle!,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
