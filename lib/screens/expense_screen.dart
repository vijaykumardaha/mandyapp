import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/order_expense/order_expense_bloc.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/order_expense_model.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  late ThemeData theme;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    context.read<OrderExpenseBloc>().add(LoadOrderExpenses());
  }

  void _showExpenseDialog([OrderExpense? expense]) {
    final isEditing = expense != null;
    final nameController = TextEditingController(text: expense?.expenseName ?? '');
    final amountController = TextEditingController(
      text: expense?.expenseAmount.toString() ?? '',
    );
    final noteController = TextEditingController(text: expense?.expenseNote ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: MyText.titleMedium(
          isEditing ? 'Edit Expense' : 'Add Expense',
          fontWeight: 600,
        ),
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
                helperText: 'Enter expense amount in rupees',
              ),
              keyboardType: TextInputType.number,
            ),
            MySpacing.height(16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
                border: OutlineInputBorder(),
                helperText: 'Add any additional notes about this expense',
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
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.only(top: 16, left: 16, right: 16),
                    content: Text('Please enter expense name'),
                  ),
                );
                return;
              }

              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.only(top: 16, left: 16, right: 16),
                    content: Text('Please enter a valid amount'),
                  ),
                );
                return;
              }

              final newExpense = OrderExpense(
                id: expense?.id,
                expenseName: nameController.text.trim(),
                expenseAmount: amount,
                expenseNote: noteController.text.trim().isEmpty 
                    ? null 
                    : noteController.text.trim(),
                orderId: expense?.orderId,
                createdAt: expense?.createdAt ?? DateTime.now().toIso8601String(),
                updatedAt: DateTime.now().toIso8601String(),
              );

              if (isEditing) {
                context.read<OrderExpenseBloc>().add(UpdateOrderExpense(newExpense));
              } else {
                context.read<OrderExpenseBloc>().add(CreateOrderExpense(newExpense));
              }
              Navigator.pop(context);
            },
            child: MyText.bodyMedium(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _deleteExpense(OrderExpense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: MyText.titleMedium('Delete Expense', fontWeight: 600),
        content: MyText.bodyMedium(
          'Are you sure you want to delete "${expense.expenseName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: MyText.bodyMedium('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (expense.id != null) {
                context.read<OrderExpenseBloc>().add(DeleteOrderExpense(expense.id!));
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: MyText.bodyMedium('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyText.titleLarge('Expense Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showExpenseDialog(),
          ),
        ],
      ),
      body: BlocConsumer<OrderExpenseBloc, OrderExpenseState>(
        listener: (context, state) {
          if (state is OrderExpenseError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                content: Text(state.message),
              ),
            );
          } else if (state is OrderExpenseOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                content: Text(state.message),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is OrderExpenseLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is OrderExpensesLoaded) {
            if (state.orderExpenses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    MyText.bodyMedium(
                      'No expenses found',
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    MyText.bodySmall(
                      'Add your first expense to get started',
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.orderExpenses.length,
              itemBuilder: (context, index) {
                final expense = state.orderExpenses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                      ),
                    ),
                    title: MyText.bodyLarge(
                      expense.expenseName,
                      fontWeight: 500,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText.bodyMedium(
                          '₹${expense.expenseAmount.toStringAsFixed(2)}',
                          color: theme.colorScheme.primary,
                        ),
                        if (expense.expenseNote != null) ...[
                          MySpacing.height(4),
                          MyText.bodySmall(
                            expense.expenseNote!,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                        MySpacing.height(4),
                        MyText.bodySmall(
                          'Created: ${DateTime.parse(expense.createdAt).day}/${DateTime.parse(expense.createdAt).month}/${DateTime.parse(expense.createdAt).year}',
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showExpenseDialog(expense);
                        } else if (value == 'delete') {
                          _deleteExpense(expense);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(
              child: MyText.bodyMedium(
                'Tap the + button to add expenses',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            );
          }
        },
      ),
    );
  }
}
