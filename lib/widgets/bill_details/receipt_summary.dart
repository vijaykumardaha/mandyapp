import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandiapp/widgets/bill_details/bill_details_data.dart';
import 'package:mandiapp/widgets/bill_details/summary_row.dart';

class ReceiptSummary extends StatelessWidget {
  final BillDetailsData data;
  final NumberFormat currency;
  final ThemeData theme;

  const ReceiptSummary({
    super.key,
    required this.data,
    required this.currency,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isSeller = data.order.orderFor == 'seller';
    final chargesPrefix = isSeller ? '- ' : '+ ';
    final expensesPrefix = isSeller ? '- ' : '+ ';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          SummaryRow(
              label: 'Item Total',
              value: currency.format(data.itemTotal),
              theme: theme),
          const SizedBox(height: 4),
          SummaryRow(
              label: 'Total Charges',
              value: '$chargesPrefix${currency.format(data.chargesTotal)}',
              theme: theme),
          const SizedBox(height: 4),
          SummaryRow(
              label: 'Total Expenses',
              value: '$expensesPrefix${currency.format(data.expensesTotal)}',
              theme: theme),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grand Total',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                currency.format(data.grandTotal),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
