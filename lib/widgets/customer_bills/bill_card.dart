import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandyapp/models/order_model.dart';
import 'package:mandyapp/screens/bill_details_screen.dart';
import 'package:mandyapp/widgets/customer_bills/info_chip.dart';

class BillCard extends StatelessWidget {
  final Order order;

  const BillCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    DateTime? createdAt;
    try {
      createdAt = DateTime.parse(order.createdAt);
    } catch (_) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(order.updatedAt ?? 0);
    }

    final orderForLabel = order.orderFor == 'seller' ? 'Seller' : 'Buyer';

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
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Bill #${order.id ?? '-'}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    dateFormat.format(createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  InfoChip(label: orderForLabel, icon: Icons.person_outline),
                  const SizedBox(width: 8),
                  InfoChip(label: '${order.lineItemCount} items', icon: Icons.shopping_bag_outlined),
                  const Spacer(),
                  Text(
                    '₹${order.totalPrice.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
