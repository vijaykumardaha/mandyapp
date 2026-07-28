import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandiapp/widgets/bill_details/bill_details_data.dart';

class ReceiptCharges extends StatelessWidget {
  final BillDetailsData data;
  final NumberFormat currency;
  final ThemeData theme;

  const ReceiptCharges({
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
            'Charges',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          ...data.charges.map((charge) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  charge.chargeName,
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  currency.format(charge.chargeAmount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
