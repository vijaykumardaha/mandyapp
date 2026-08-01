import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:krishimandi/widgets/bill_details/bill_details_data.dart';
import 'package:krishimandi/widgets/bill_details/info_row.dart';

class ReceiptPayment extends StatelessWidget {
  final BillDetailsData data;
  final NumberFormat currency;
  final ThemeData theme;

  const ReceiptPayment({
    super.key,
    required this.data,
    required this.currency,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Info',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          InfoRow(
              label: 'Amount Paid',
              value: currency.format(data.receivedAmount),
              theme: theme),
          const SizedBox(height: 4),
          InfoRow(
              label: 'Amount Due',
              value: currency.format(data.pendingPayment.abs()),
              theme: theme),
          if (data.paymentMethodLabel.isNotEmpty &&
              data.paymentMethodLabel != 'Not recorded') ...[
            const SizedBox(height: 4),
            InfoRow(
                label: 'Payment Method',
                value: data.paymentMethodLabel,
                theme: theme),
          ],
        ],
      ),
    );
  }
}
