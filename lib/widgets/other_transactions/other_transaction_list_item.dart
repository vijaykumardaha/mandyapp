import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:krishimandi/models/other_transaction_model.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';

class OtherTransactionListItem extends StatelessWidget {
  final OtherTransaction transaction;
  final ThemeData theme;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const OtherTransactionListItem({
    super.key,
    required this.transaction,
    required this.theme,
    this.isAdmin = true,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDebit = transaction.isDebit;
    final date =
        DateTime.fromMillisecondsSinceEpoch(transaction.updatedAt ?? 0);
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(date);

    return Card(
      margin: MySpacing.bottom(8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              (isDebit ? Colors.red : Colors.green).withValues(alpha: 0.1),
          child: Icon(
            isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 18,
            color: isDebit ? Colors.red : Colors.green,
          ),
        ),
        title: MyText.bodyLarge(
          transaction.transactionNote,
          fontWeight: 500,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              Container(
                padding: MySpacing.xy(6, 2),
                decoration: BoxDecoration(
                  color: (isDebit ? Colors.red : Colors.green)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (isDebit ? Colors.red : Colors.green)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: MyText.bodySmall(
                  isDebit ? 'Debit' : 'Credit',
                  color: isDebit ? Colors.red : Colors.green,
                  fontWeight: 600,
                  fontSize: 10,
                ),
              ),
              Container(
                padding: MySpacing.xy(6, 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: MyText.bodySmall(
                  '₹${NumberFormat('#,##0.00').format(transaction.transactionAmount)}',
                  color: theme.colorScheme.primary,
                  fontWeight: 600,
                  fontSize: 10,
                ),
              ),
              MyText.bodySmall(
                dateStr,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ],
          ),
        ),
        trailing: isAdmin
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 20),
                        MySpacing.width(8),
                        const Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, size: 20, color: Colors.red),
                        MySpacing.width(8),
                        const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
