import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:krishimandi/widgets/bill_details/bill_details_data.dart';

class ReceiptItems extends StatelessWidget {
  final BillDetailsData data;
  final NumberFormat currency;
  final ThemeData theme;

  const ReceiptItems({
    super.key,
    required this.data,
    required this.currency,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Product',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                'Amount',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        ...data.lineItems.map((item) {
          final isSellerOrder = data.order.orderFor == 'seller';
          final partnerLabel = isSellerOrder ? 'Buyer' : 'Seller';
          final partnerName = isSellerOrder
              ? data.customerById[item.sale.buyerId]?.name
              : item.sellerLabel;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${item.quantityLabel} × ${currency.format(item.sellingPrice)} = ${currency.format(item.totalPrice)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (partnerName != null && partnerName.isNotEmpty)
                  Text(
                    '$partnerLabel: $partnerName',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
