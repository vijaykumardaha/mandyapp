import 'package:flutter/material.dart';
import 'package:krishimandi/widgets/common/my_text.dart';

class CalculationStep {
  final String label;
  final String amount;
  final bool isDeduction;

  const CalculationStep({
    required this.label,
    required this.amount,
    this.isDeduction = false,
  });
}

class CalculationInfoDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<CalculationStep> steps;
  final String summary;
  final String? description;

  const CalculationInfoDialog({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.steps,
    required this.summary,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: MyText.titleMedium(title, fontWeight: 700),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: MyText.bodySmall(summary, fontWeight: 600),
            ),
            const SizedBox(height: 16),
            const MyText.titleSmall('How it is calculated', fontWeight: 700),
            const SizedBox(height: 12),
            ...steps.map(
              (step) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: (step.isDeduction ? Colors.red : Colors.green)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: MyText.labelMedium(
                        step.isDeduction ? '−' : '+',
                        color: step.isDeduction ? Colors.red : Colors.green,
                        fontWeight: 700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: MyText.bodySmall(step.label, fontWeight: 500),
                    ),
                    const SizedBox(width: 8),
                    MyText.bodySmall(
                      step.amount,
                      fontWeight: 700,
                      color: step.isDeduction ? Colors.red : Colors.green,
                    ),
                  ],
                ),
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 12),
              MyText.bodySmall(
                description!,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
      ],
    );
  }
}
