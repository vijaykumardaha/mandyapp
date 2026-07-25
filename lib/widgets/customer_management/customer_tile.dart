import 'package:flutter/material.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/dao/order_dao.dart';
import 'package:mandyapp/dao/order_payment_dao.dart';
import 'package:mandyapp/screens/customer_bills_screen.dart';
import 'package:mandyapp/screens/payment_histories_screen.dart';

class CustomerTile extends StatefulWidget {
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
  State<CustomerTile> createState() => _CustomerTileState();
}

class _CustomerTileState extends State<CustomerTile> {
  int _billCount = 0;
  double _totalPaid = 0;
  double _totalReceived = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final orderDAO = OrderDAO();
    final orderPaymentDAO = OrderPaymentDAO();

    final orders = await orderDAO.getOrdersByCustomer(widget.customer.id!);
    double paid = 0;
    double received = 0;

    for (final order in orders) {
      final payments = await orderPaymentDAO.getOrderPaymentsByOrderId(order.id!);
      for (final payment in payments) {
        if (order.orderFor == 'buyer') {
          received += payment.amount;
        } else {
          paid += payment.amount;
        }
      }
    }

    if (mounted) {
      setState(() {
        _billCount = orders.length;
        _totalPaid = paid;
        _totalReceived = received;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;
    final hasName = customer.name?.trim().isNotEmpty == true;
    final hasPhone = customer.phone?.trim().isNotEmpty == true;
    final displayName = hasName ? customer.name!.trim() : 'Unnamed Customer';
    final displayPhone = hasPhone ? customer.phone!.trim() : null;

    final nameParts = displayName.split(RegExp(r'\s+'));
    final initials = nameParts.length >= 2
        ? '${nameParts.first[0]}${nameParts.last[0]}'
        : nameParts.first[0];

    final theme = widget.theme;

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
                    displayName,
                    fontWeight: 600,
                  ),
                  if (displayPhone != null) ...[
                    const SizedBox(height: 2),
                    MyText.bodySmall(
                      displayPhone,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ],
                  if (_loaded && _billCount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _StatChip(
                          label: 'Bills',
                          value: '$_billCount',
                          color: theme.colorScheme.primary,
                          theme: theme,
                        ),
                        const SizedBox(width: 8),
                        if (_totalReceived > 0)
                          _StatChip(
                            label: 'Received',
                            value: '₹${_totalReceived.toStringAsFixed(0)}',
                            color: Colors.green,
                            theme: theme,
                          ),
                        if (_totalPaid > 0) ...[
                          const SizedBox(width: 8),
                          _StatChip(
                            label: 'Paid',
                            value: '₹${_totalPaid.toStringAsFixed(0)}',
                            color: Colors.orange,
                            theme: theme,
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  widget.onEdit();
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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: MyText.bodySmall(
        '$label: $value',
        color: color,
        fontWeight: 500,
        fontSize: 10,
      ),
    );
  }
}
