import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandiapp/models/order_model.dart';
import 'package:mandiapp/screens/bill_details_screen.dart';

class BillCard extends StatelessWidget {
  final Order order;
  final double? grandTotal;
  final double? receivedAmount;

  const BillCard({
    super.key,
    required this.order,
    this.grandTotal,
    this.receivedAmount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final orderDate = DateTime.fromMillisecondsSinceEpoch(order.updatedAt ?? 0);

    return GestureDetector(
      onTap: () {
        if (order.id != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BillDetailsScreen(orderId: order.id!),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
          border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#${order.id}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order.orderFor == 'seller' ? 'Seller' : 'Buyer',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: order.orderFor == 'buyer'
                              ? Colors.blue
                              : Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(orderDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (grandTotal != null &&
                    receivedAmount != null &&
                    (receivedAmount! - grandTotal!).abs() > 0.01)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      receivedAmount! >= grandTotal!
                          ? '₹${(receivedAmount! - grandTotal!).toStringAsFixed(2)} Refund'
                          : '₹${(grandTotal! - receivedAmount!).toStringAsFixed(2)} Dues',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: receivedAmount! >= grandTotal!
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Text(
                  '₹${(grandTotal ?? order.totalPrice).toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
