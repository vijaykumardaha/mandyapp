import 'package:flutter/material.dart';

class InvoiceItem extends StatelessWidget {
  final String productName;
  final double quantity;
  final String unit;
  final double price;
  final double total;
  final String? seller;

  const InvoiceItem({
    super.key,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.total,
    this.seller,
  });

  String get _quantityLabel {
    if (quantity % 1 == 0) {
      return quantity.toStringAsFixed(0);
    }
    return quantity.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (seller != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        seller!,
                        style: textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_quantityLabel} ${unit.isNotEmpty ? unit : 'pc'}' ,
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${price.toStringAsFixed(2)}',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1),
        ],
      ),
    );
  }
}
