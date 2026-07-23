import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mandyapp/blocs/customer_payment/customer_payment_bloc.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/models/customer_payment_model.dart';

class PaymentHistoriesScreen extends StatefulWidget {
  final Customer customer;

  const PaymentHistoriesScreen({
    super.key,
    required this.customer,
  });

  @override
  State<PaymentHistoriesScreen> createState() => _PaymentHistoriesScreenState();
}

class _PaymentHistoriesScreenState extends State<PaymentHistoriesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CustomerPaymentBloc>().add(FetchPayments(customerId: widget.customer.id!));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment History',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.customer.name ?? 'Customer',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 26),
              tooltip: 'Add Payment',
              onPressed: () => _showAddPaymentSheet(context),
            ),
          ),
        ],
      ),
      body: BlocBuilder<CustomerPaymentBloc, CustomerPaymentState>(
        builder: (context, state) {
          if (state is CustomerPaymentLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CustomerPaymentError) {
            return Center(child: Text(state.message));
          }

          if (state is CustomerPaymentsLoaded) {
            if (state.payments.isEmpty) {
              return _buildEmptyState(theme);
            }

            return Column(
              children: [
                _buildSummaryBar(theme, state),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.payments.length,
                    itemBuilder: (context, index) {
                      return _buildPaymentItem(context, state.payments[index]);
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSummaryBar(ThemeData theme, CustomerPaymentsLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryChip(theme, 'Received', state.totalReceived, Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryChip(theme, 'Paid', state.totalPaid, Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(ThemeData theme, String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No payments yet',
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(BuildContext context, CustomerPayment payment) {
    final theme = Theme.of(context);
    final isReceived = payment.type == 'received';
    final date = DateTime.fromMillisecondsSinceEpoch(payment.paymentDate);
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isReceived ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
          child: Icon(
            isReceived ? Icons.arrow_downward : Icons.arrow_upward,
            color: isReceived ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Text(payment.note.isNotEmpty ? payment.note : payment.source.toUpperCase()),
        subtitle: Text('${payment.source.toUpperCase()} • ${dateFormat.format(date)}'),
        trailing: Text(
          '${isReceived ? '+' : '-'}₹${payment.amount.toStringAsFixed(2)}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: isReceived ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showAddPaymentSheet(BuildContext context) {
    String selectedType = 'received';
    String selectedSource = 'cash';
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);
            final isReceived = selectedType == 'received';
            final accentColor = isReceived ? Colors.green : Colors.red;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Add Payment',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTypeTab(
                              context,
                              label: 'Received',
                              icon: Icons.arrow_downward_rounded,
                              isSelected: isReceived,
                              color: Colors.green,
                              onTap: () => setSheetState(() => selectedType = 'received'),
                            ),
                          ),
                          Expanded(
                            child: _buildTypeTab(
                              context,
                              label: 'Paid',
                              icon: Icons.arrow_upward_rounded,
                              isSelected: !isReceived,
                              color: Colors.red,
                              onTap: () => setSheetState(() => selectedType = 'paid'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₹ ',
                        prefixStyle: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: accentColor, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Enter amount';
                        final amount = double.tryParse(value.trim());
                        if (amount == null || amount <= 0) return 'Enter valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedSource,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      decoration: InputDecoration(
                        labelText: 'Source',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: accentColor, width: 2),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'upi', child: Text('UPI')),
                        DropdownMenuItem(value: 'card', child: Text('Card')),
                        DropdownMenuItem(value: 'credit', child: Text('Credit')),
                      ],
                      onChanged: (value) {
                        if (value != null) setSheetState(() => selectedSource = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: 'Note',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: accentColor, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Enter a note';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          final payment = CustomerPayment(
                            customerId: widget.customer.id!,
                            amount: double.parse(amountController.text.trim()),
                            type: selectedType,
                            source: selectedSource,
                            note: noteController.text.trim(),
                            paymentDate: DateTime.now().millisecondsSinceEpoch,
                          );
                          context.read<CustomerPaymentBloc>().add(AddPayment(payment: payment));
                          Navigator.pop(context);
                        },
                        child: Text(
                          isReceived ? 'Add Received Payment' : 'Add Paid Payment',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeTab(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: color.withOpacity(0.4), width: 1.5) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? color : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
