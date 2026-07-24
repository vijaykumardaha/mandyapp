import 'package:flutter/material.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';

class ExpenseSectionWidget extends StatelessWidget {
  final String orderFor;
  final List<Map<String, dynamic>> expenses;
  final Function(List<Map<String, dynamic>>) onExpensesChanged;

  const ExpenseSectionWidget({
    super.key,
    required this.orderFor,
    required this.expenses,
    required this.onExpensesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: MySpacing.bottom(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: MySpacing.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                MySpacing.width(8),
                MyText.bodyMedium('Expenses', fontWeight: 600),
                const Spacer(),
                InkWell(
                  onTap: () => _showAddExpenseDialog(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16, color: Theme.of(context).colorScheme.primary),
                        MySpacing.width(4),
                        MyText.bodySmall('Add', color: Theme.of(context).colorScheme.primary, fontWeight: 600),
                      ],
                    ),
                  ),
                ),
                MySpacing.width(4),
              ],
            ),
          ),
          if (expenses.isEmpty)
            Padding(
              padding: MySpacing.horizontal(16),
              child: MyText.bodySmall(
                'No expenses added',
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            )
          else
            ...expenses.asMap().entries.map((entry) {
              final index = entry.key;
              final expense = entry.value;
              return Padding(
                padding: MySpacing.horizontal(16),
                child: ListTile(
                  leading: Icon(
                    Icons.check_circle,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MyText.bodyMedium(
                        expense['description'] ?? 'Expense',
                        fontWeight: 500,
                      ),
                      MyText.bodySmall(
                        '₹${(expense['amount'] as double).toStringAsFixed(2)}',
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    onPressed: () {
                      final updated = List<Map<String, dynamic>>.from(expenses);
                      updated.removeAt(index);
                      onExpensesChanged(updated);
                    },
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  dense: true,
                ),
              );
            }),
          MySpacing.height(8),
        ],
      ),
    );
  }

  Future<void> _showAddExpenseDialog(BuildContext context) async {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MyText.titleMedium('Add Expense', fontWeight: 600),
              MySpacing.height(16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              MySpacing.height(12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹',
                  border: OutlineInputBorder(),
                ),
              ),
              MySpacing.height(16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: MyText.bodyMedium('Cancel'),
                    ),
                  ),
                  MySpacing.width(12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final amount = double.tryParse(amountController.text);
                        if (descriptionController.text.trim().isNotEmpty && amount != null && amount > 0) {
                          Navigator.pop(sheetContext, {
                            'description': descriptionController.text.trim(),
                            'amount': amount,
                          });
                        }
                      },
                      child: MyText.bodyMedium('Add', color: Colors.white),
                    ),
                  ),
                ],
              ),
              MySpacing.height(16),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      onExpensesChanged([...expenses, result]);
    }
  }
}
