import 'package:flutter/material.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/order_model.dart';

class ExpenseSectionWidget extends StatefulWidget {
  final Order order;
  final String orderFor;

  const ExpenseSectionWidget({
    super.key,
    required this.order,
    required this.orderFor,
  });

  @override
  State<ExpenseSectionWidget> createState() => _ExpenseSectionWidgetState();
}

class _ExpenseSectionWidgetState extends State<ExpenseSectionWidget> {
  List<Map<String, dynamic>> _expenses = [];
  bool _expensesExpanded = true;

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
          // Header
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
                Spacer(),
                MyText.bodySmall(
                  '${_expenses.length} Added',
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _expensesExpanded = !_expensesExpanded;
                    });
                  },
                  icon: Icon(
                    _expensesExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Expenses List (when expanded)
          if (_expensesExpanded) ...[
            if (_expenses.isEmpty) ...[
              Padding(
                padding: MySpacing.horizontal(16),
                child: MyText.bodySmall(
                  'No expenses added',
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ] else ...[
              ..._expenses.asMap().entries.map((entry) {
                final index = entry.key;
                final expense = entry.value;
                return Padding(
                  padding: MySpacing.horizontal(16),
                  child: Container(
                    margin: MySpacing.bottom(8),
                    padding: MySpacing.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MyText.bodyMedium(
                                expense['description'] ?? 'Expense',
                                fontWeight: 500,
                              ),
                              MySpacing.height(4),
                              MyText.bodySmall(
                                '₹${(expense['amount'] as double).toStringAsFixed(2)}',
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _expenses.removeAt(index);
                            });
                          },
                          icon: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],

            // Add Expense Button
            Padding(
              padding: MySpacing.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showAddExpenseDialog(),
                  icon: const Icon(Icons.add),
                  label: MyText.bodyMedium('Add Expense'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showAddExpenseDialog() async {
    String description = '';
    String amountText = '';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: MyText.titleMedium('Add Expense', fontWeight: 600),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (value) => description = value,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            MySpacing.height(16),
            TextField(
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) => amountText = value,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountText);
              if (description.trim().isNotEmpty && amount != null && amount > 0) {
                Navigator.of(context).pop({
                  'description': description.trim(),
                  'amount': amount,
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _expenses.add(result);
      });
    }
  }
}
