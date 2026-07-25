import 'package:flutter/material.dart';

class PaymentSummaryBar extends StatelessWidget {
  final double totalReceived;
  final double totalPaid;

  const PaymentSummaryBar({
    super.key,
    required this.totalReceived,
    required this.totalPaid,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryChip(theme, 'Received', totalReceived, Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryChip(theme, 'Paid', totalPaid, Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(ThemeData theme, String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
