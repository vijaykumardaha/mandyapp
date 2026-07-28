import 'package:flutter/material.dart';
import 'package:mandiapp/widgets/bill_details/bill_details_data.dart';

class ReceiptHeader extends StatelessWidget {
  final BillDetailsData data;
  final ThemeData theme;

  const ReceiptHeader({
    super.key,
    required this.data,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final orderForLabel = data.order.orderFor == 'seller' ? 'Seller' : 'Buyer';
    return Column(
      children: [
        Text(
          '#${data.order.id ?? '-'}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$orderForLabel • ${data.customerName}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
