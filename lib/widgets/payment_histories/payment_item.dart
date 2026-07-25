import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandyapp/models/customer_payment_model.dart';

class PaymentItem extends StatelessWidget {
  final CustomerPayment payment;

  const PaymentItem({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
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
}
