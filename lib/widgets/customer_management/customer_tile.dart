import 'package:flutter/material.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/screens/customer_bills_screen.dart';
import 'package:mandyapp/screens/payment_histories_screen.dart';

class CustomerTile extends StatelessWidget {
  final Customer customer;
  final ThemeData theme;
  final VoidCallback onEdit;

  const CustomerTile({
    super.key,
    required this.customer,
    required this.theme,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hasName = customer.name?.trim().isNotEmpty == true;
    final hasPhone = customer.phone?.trim().isNotEmpty == true;
    final displayName = hasName ? customer.name!.trim() : 'Unnamed Customer';
    final displayPhone = hasPhone ? customer.phone!.trim() : null;
    final title = displayPhone != null ? '$displayName ($displayPhone)' : displayName;

    final nameParts = displayName.split(RegExp(r'\s+'));
    final initials = nameParts.length >= 2
        ? '${nameParts.first[0]}${nameParts.last[0]}'
        : nameParts.first[0];

    return Card(
      margin: MySpacing.bottom(12),
      child: Padding(
        padding: MySpacing.xy(12, 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Text(
                initials.toUpperCase(),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText.bodyLarge(
                    title,
                    fontWeight: 600,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'payments') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentHistoriesScreen(customer: customer),
                    ),
                  );
                } else if (value == 'bills') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomerBillsScreen(customer: customer),
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'payments', child: Text('Payments')),
                const PopupMenuItem(value: 'bills', child: Text('Bills')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
