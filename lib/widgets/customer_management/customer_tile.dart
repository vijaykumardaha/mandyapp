import 'package:flutter/material.dart';
import 'package:mandiapp/dao/order_dao.dart';
import 'package:mandiapp/dao/order_payment_dao.dart';
import 'package:mandiapp/models/customer_model.dart';
import 'package:mandiapp/screens/customer_bills_screen.dart';
import 'package:mandiapp/screens/payment_histories_screen.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';

class CustomerTile extends StatefulWidget {
  final Customer customer;
  final ThemeData theme;
  final bool isAdmin;
  final VoidCallback onEdit;

  const CustomerTile({
    super.key,
    required this.customer,
    required this.theme,
    this.isAdmin = true,
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
      final payments =
          await orderPaymentDAO.getOrderPaymentsByOrderId(order.id!);
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
    final displayName = hasName ? customer.name!.trim() : 'Unnamed Customer';

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
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                  if (_loaded && _billCount > 0) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _StatChip(
                          label: 'Bills',
                          value: '$_billCount',
                          color: theme.colorScheme.primary,
                          theme: theme,
                        ),
                        if (_totalReceived > 0) ...[
                          const SizedBox(width: 4),
                          _StatChip(
                            label: 'Received',
                            value: '₹${_totalReceived.toStringAsFixed(0)}',
                            color: Colors.green,
                            theme: theme,
                          ),
                        ],
                        if (_totalPaid > 0) ...[
                          const SizedBox(width: 4),
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
                      builder: (context) =>
                          PaymentHistoriesScreen(customer: customer),
                    ),
                  );
                } else if (value == 'bills') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CustomerBillsScreen(customer: customer),
                    ),
                  );
                }
              },
              itemBuilder: (context) => [
                if (widget.isAdmin)
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
        color: color.withValues(alpha: 0.1),
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
