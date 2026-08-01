import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:krishimandi/widgets/bill_details/bill_details_data.dart';
import 'package:krishimandi/widgets/bill_details/info_row.dart';

class ReceiptInfo extends StatelessWidget {
  final BillDetailsData data;
  final DateTime createdAt;
  final ThemeData theme;

  const ReceiptInfo({
    super.key,
    required this.data,
    required this.createdAt,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy hh:mm a');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          InfoRow(
              label: 'Date', value: dateFormat.format(createdAt), theme: theme),
          const SizedBox(height: 4),
          InfoRow(
              label: 'Type',
              value: data.order.orderFor == 'seller' ? 'Seller' : 'Buyer',
              theme: theme),
        ],
      ),
    );
  }
}
