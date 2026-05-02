import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/order_expense/order_expense_bloc.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/order_expense_model.dart';
import 'package:mandyapp/models/order_model.dart';

class ExpenseSection extends StatefulWidget {
  final Order order;
  final Function(OrderExpense) onExpenseAdded;
  final Function(int) onExpenseDeleted;
  final Function() onSchedulePersistCheckout;

  const ExpenseSection({
    Key? key,
    required this.order,
    required this.onExpenseAdded,
    required this.onExpenseDeleted,
    required this.onSchedulePersistCheckout,
  }) : super(key: key);

  
  @override
  State<ExpenseSection> createState() => _ExpenseSectionState();
}

class _ExpenseSectionState extends State<ExpenseSection> {
  bool _expensesExpanded = true;

  @override
  void initState() {
    super.initState();
    // Load expenses for this order
    context.read<OrderExpenseBloc>().add(LoadOrderExpensesByOrderId(widget.order.id!));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderExpenseBloc, OrderExpenseState>(
      listener: (context, state) {
        if (state is OrderExpenseOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          // Reload expenses after successful operation
          context.read<OrderExpenseBloc>().add(LoadOrderExpensesByOrderId(widget.order.id!));
        } else if (state is OrderExpenseError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is OrderExpenseLoading) {
          return _buildLoadingSection();
        }

        if (state is OrderExpensesLoaded) {
          final expenses = state.orderExpenses;
          if (expenses.isEmpty) {
            return _buildNoExpensesSection();
          }

          return _buildExpensesSection(expenses);
        }

        if (state is OrderExpenseError) {
          return _buildErrorSection(state.message);
        }

        return _buildLoadingSection();
      },
    );
  }

  Widget _buildNoExpensesSection() {
    return Container(
      margin: MySpacing.bottom(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: MySpacing.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 20,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                MySpacing.width(8),
                MyText.bodyLarge('Expenses', fontWeight: 600),
                const Spacer(),
                Container(
                  padding: MySpacing.xy(8, 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: MyText.bodySmall(
                    '0 Expenses',
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: 600,
                  ),
                ),
                MySpacing.width(8),
                InkWell(
                  onTap: () => _showExpenseDialog(),
                  child: Container(
                    padding: MySpacing.xy(8, 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.white,
                        ),
                        MySpacing.width(4),
                        MyText.bodySmall(
                          'Add',
                          color: Colors.white,
                          fontWeight: 600,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Empty State Content
          Padding(
            padding: MySpacing.all(16),
            child: Container(
              padding: MySpacing.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  MySpacing.width(8),
                  Expanded(
                    child: MyText.bodySmall(
                      'No expenses added for this order. Tap "Add" to create your first expense.',
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesSection(List<OrderExpense> expenses) {
    return Container(
      margin: MySpacing.bottom(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: MySpacing.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 20,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                MySpacing.width(8),
                MyText.bodyLarge('Expenses', fontWeight: 600),
                const Spacer(),
                Container(
                  padding: MySpacing.xy(8, 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: MyText.bodySmall(
                    '${expenses.length} Expense${expenses.length != 1 ? 's' : ''}',
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: 600,
                  ),
                ),
                MySpacing.width(8),
                InkWell(
                  onTap: () => _showExpenseDialog(),
                  child: Container(
                    padding: MySpacing.xy(8, 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.white,
                        ),
                        MySpacing.width(4),
                        MyText.bodySmall(
                          'Add',
                          color: Colors.white,
                          fontWeight: 600,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Expenses Content
          if (_expensesExpanded) ..._buildExpenseItems(expenses),
        ],
      ),
    );
  }

  List<Widget> _buildExpenseItems(List<OrderExpense> expenses) {
    return [
      MySpacing.height(12),
      ...expenses.map((expense) => _buildExpenseItem(expense)).toList(),
    ];
  }

  Widget _buildExpenseItem(OrderExpense expense) {
    return Padding(
      padding: MySpacing.bottom(12),
      child: Container(
        padding: MySpacing.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            // Expense Icon and Details
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    padding: MySpacing.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      size: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  MySpacing.width(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText.bodyMedium(
                          expense.expenseName,
                          fontWeight: 600,
                        ),
                        MySpacing.height(2),
                        if (expense.expenseNote != null && expense.expenseNote!.isNotEmpty)
                          MyText.bodySmall(
                            expense.expenseNote!,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            MySpacing.width(12),

            // Amount
            Expanded(
              flex: 1,
              child: Container(
                padding: MySpacing.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MyText.bodyMedium(
                      '₹${expense.expenseAmount.toStringAsFixed(2)}',
                      fontWeight: 600,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    MyText.bodySmall(
                      'Expense',
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
            ),
            MySpacing.width(8),

            // Delete Button
            InkWell(
              onTap: () {
                widget.onExpenseDeleted(expense.id!);
                widget.onSchedulePersistCheckout();
              },
              child: Container(
                padding: MySpacing.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Container(
      margin: MySpacing.bottom(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: MySpacing.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 20,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                MySpacing.width(8),
                MyText.bodyLarge('Expenses', fontWeight: 600),
                const Spacer(),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          // Loading Content
          Padding(
            padding: MySpacing.all(16),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  MySpacing.height(12),
                  MyText.bodyMedium(
                    'Loading expenses...',
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection(String message) {
    return Container(
      margin: MySpacing.bottom(12),
      padding: MySpacing.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                size: 20,
                color: Theme.of(context).colorScheme.error,
              ),
              MySpacing.width(8),
              MyText.bodyMedium('Expenses', fontWeight: 600),
              const Spacer(),
              Icon(
                Icons.error_outline,
                size: 20,
                color: Theme.of(context).colorScheme.error,
              ),
            ],
          ),
          MySpacing.height(8),
          MyText.bodySmall(
            message,
            color: Theme.of(context).colorScheme.error,
          ),
        ],
      ),
    );
  }

  void _showExpenseDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: MyText.titleMedium('Add Expense', fontWeight: 600),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Expense Name',
                border: OutlineInputBorder(),
              ),
            ),
            MySpacing.height(16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            MySpacing.height(16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: MyText.bodyMedium('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (nameController.text.isEmpty || amount == null || amount < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.only(top: 16, left: 16, right: 16),
                    content: Text('Please enter valid expense details'),
                  ),
                );
                return;
              }

              final now = DateTime.now().toIso8601String();
              final newExpense = OrderExpense(
                expenseName: nameController.text,
                expenseAmount: amount,
                expenseNote: noteController.text.isEmpty ? null : noteController.text,
                orderId: widget.order.id!,
                createdAt: now,
                updatedAt: now,
              );

              context.read<OrderExpenseBloc>().add(CreateOrderExpense(newExpense));
              widget.onExpenseAdded(newExpense);
              widget.onSchedulePersistCheckout();
              Navigator.pop(context);
            },
            child: MyText.bodyMedium('Add'),
          ),
        ],
      ),
    );
  }
}
