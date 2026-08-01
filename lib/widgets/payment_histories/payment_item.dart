import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:krishimandi/models/customer_payment_model.dart';

class PaymentItem extends StatelessWidget {
  final CustomerPayment payment;

  const PaymentItem({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReceived = payment.type == 'received';
    final date = DateTime.fromMillisecondsSinceEpoch(payment.paymentDate);
    final timeStr = DateFormat('hh:mm a').format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isReceived ? Colors.green : Colors.red)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isReceived
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: isReceived ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.note.isNotEmpty
                        ? payment.note
                        : payment.source.toUpperCase(),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${payment.source.toUpperCase()} • $timeStr',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isReceived ? '+' : '-'}₹${payment.amount.toStringAsFixed(2)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isReceived ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
