import 'package:flutter/material.dart';
import 'package:mandyapp/models/bill_summary_model.dart';

class BillCard extends StatelessWidget {
  final BillSummary bill;
  final ThemeData theme;
  final String billLabel;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const BillCard({
    Key? key,
    required this.bill,
    required this.theme,
    required this.billLabel,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String billTypeText;
    Color typeColor;
    Color paymentStatusColor;

    // Determine bill type text and color
    switch (bill.billType) {
      case 'sale':
        billTypeText = 'Sale';
        typeColor = Colors.blue;
        break;
      case 'purchase':
        billTypeText = 'Purchase';
        typeColor = Colors.orange;
        break;
      default:
        billTypeText = bill.billType ?? 'Other';
        typeColor = theme.colorScheme.onSurface.withOpacity(0.6);
    }

    // Determine payment status color
    switch (bill.paymentStatus?.toLowerCase()) {
      case 'paid':
        paymentStatusColor = Colors.green;
        break;
      case 'partially_paid':
        paymentStatusColor = Colors.orange;
        break;
      case 'unpaid':
        paymentStatusColor = theme.colorScheme.error;
        break;
      default:
        paymentStatusColor = theme.colorScheme.primary;
    }

    // Show delete confirmation dialog
    Future<void> _showDeleteDialog() async {
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Bill'),
          content: const Text('Are you sure you want to delete this bill? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              child: const Text('DELETE'),
            ),
          ],
        ),
      );

      if (shouldDelete == true && onDelete != null) {
        onDelete!();
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.05)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    billLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: paymentStatusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Payment: ${bill.paymentStatus ?? 'N/A'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: paymentStatusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Type: $billTypeText',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: typeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error.withOpacity(0.7),
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 20,
                onPressed: _showDeleteDialog,
              ),
          ],
        ),
      ),
    );
  }
}
