import 'package:flutter/material.dart';
import 'package:mandyapp/blocs/customer/customer_bloc.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/utils/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CustomerDetailsScreen extends StatelessWidget {
  final Customer customer;
  
  const CustomerDetailsScreen({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name ?? 'Customer Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditCustomerDialog(context, customer),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Info Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          radius: 30,
                          child: Text(
                            customer.name?.isNotEmpty ?? false 
                                ? customer.name![0].toUpperCase() 
                                : '?',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.name ?? 'No Name',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (customer.phone?.isNotEmpty ?? false) ...[
                                const SizedBox(height: 4),
                                Text(
                                  customer.phone!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAmountCard(
                          context,
                          'Borrowed',
                          currencyFormat.format(customer.borrowAmount),
                          Icons.call_received,
                          Colors.red,
                        ),
                        _buildAmountCard(
                          context,
                          'Advanced',
                          currencyFormat.format(customer.advancedAmount),
                          Icons.call_made,
                          Colors.green,
                        ),
                        _buildAmountCard(
                          context,
                          'Balance',
                          currencyFormat.format(customer.borrowAmount - customer.advancedAmount),
                          Icons.account_balance_wallet,
                          theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Transaction History Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction History',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Implement view all transactions
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            
            // Recent Transactions List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5, // Show last 5 transactions (replace with actual data)
              itemBuilder: (context, index) {
                // TODO: Replace with actual transaction data
                return _buildTransactionItem(
                  context,
                  title: 'Transaction ${index + 1}',
                  amount: 100.0 * (index + 1),
                  date: DateTime.now().subtract(Duration(days: index)),
                  isCredit: index % 2 == 0,
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implement add payment
                    },
                    icon: const Icon(Icons.payment),
                    label: const Text('Add Payment'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implement add transaction
                    },
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Add Transaction'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard(
    BuildContext context,
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    BuildContext context, {
    required String title,
    required double amount,
    required DateTime date,
    required bool isCredit,
  }) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCredit 
              ? Colors.green.withOpacity(0.1) 
              : Colors.red.withOpacity(0.1),
          child: Icon(
            isCredit ? Icons.arrow_downward : Icons.arrow_upward,
            color: isCredit ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Text(title),
        subtitle: Text(dateFormat.format(date)),
        trailing: Text(
          '${isCredit ? '+' : '-'}₹${amount.toStringAsFixed(2)}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: isCredit ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () {
          // TODO: Handle transaction tap
        },
      ),
    );
  }

  void _showEditCustomerDialog(BuildContext context, Customer customer) {
    final nameController = TextEditingController(text: customer.name ?? '');
    final phoneController = TextEditingController(text: customer.phone ?? '');
    final borrowController = TextEditingController(text: customer.borrowAmount.toString());
    final advanceController = TextEditingController(text: customer.advancedAmount.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: borrowController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Borrow Amount',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: advanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Advanced Amount',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedCustomer = customer.copyWith(
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                borrowAmount: double.tryParse(borrowController.text) ?? customer.borrowAmount,
                advancedAmount: double.tryParse(advanceController.text) ?? customer.advancedAmount,
              );
              
              context.read<CustomerBloc>().add(
                UpdateCustomer(
                  customer: updatedCustomer,
                  query: '', // You might want to pass the current search query
                ),
              );
              
              Navigator.pop(context);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }
}
