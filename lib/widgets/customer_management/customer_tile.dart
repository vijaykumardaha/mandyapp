import 'dart:async';

import 'package:flutter/material.dart';
import 'package:krishimandi/dao/customer_payment_dao.dart';
import 'package:krishimandi/models/customer_model.dart';
import 'package:krishimandi/screens/customer_bills_screen.dart';
import 'package:krishimandi/screens/payment_histories_screen.dart';
import 'package:krishimandi/services/sync_service.dart';
import 'package:krishimandi/utils/constants.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';

class CustomerTile extends StatefulWidget {
  final Customer customer;
  final ThemeData theme;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CustomerTile({
    super.key,
    required this.customer,
    required this.theme,
    this.isAdmin = true,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<CustomerTile> createState() => _CustomerTileState();
}

class _CustomerTileState extends State<CustomerTile> {
  double _totalPaid = 0;
  double _totalReceived = 0;
  bool _loaded = false;
  StreamSubscription<String>? _syncSubscription;

  double get _netBalance => _totalReceived - _totalPaid;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _syncSubscription = SyncService.instance.tableUpdates.listen((table) {
      if (!mounted) return;
      if (table == DbTables.customerPayments) {
        _loadStats();
      }
    });
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final paymentDAO = CustomerPaymentDAO();

    final received =
        await paymentDAO.getTotalByType(widget.customer.id!, 'received');
    final paid = await paymentDAO.getTotalByType(widget.customer.id!, 'paid');

    if (mounted) {
      setState(() {
        _totalPaid = paid;
        _totalReceived = received;
        _loaded = true;
      });
    }
  }

  Future<void> _openPayments() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentHistoriesScreen(customer: widget.customer),
      ),
    );
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;
    final hasName = customer.name?.trim().isNotEmpty == true;
    final displayName = hasName ? customer.name!.trim() : 'Unnamed Customer';

    final nameParts = displayName.split(RegExp(r'\s+'));
    final initials = nameParts.length >= 2
        ? '${nameParts.first[0]}${nameParts.last[0]}'
        : nameParts.first.length >= 2
            ? nameParts.first.substring(0, 2)
            : nameParts.first;

    final theme = widget.theme;

    return Card(
      margin: MySpacing.bottom(12),
      child: Padding(
        padding: MySpacing.xy(12, 10),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _openPayments,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        initials.toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
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
                          MyText.bodyMedium(
                            customer.phone != null &&
                                    customer.phone!.trim().isNotEmpty
                                ? '$displayName (${customer.phone!.trim()})'
                                : displayName,
                            fontWeight: 600,
                          ),
                          if (_loaded) ...[
                            const SizedBox(height: 2),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                _StatChip(
                                  label: 'Received',
                                  value:
                                      '₹${_totalReceived.toStringAsFixed(0)}',
                                  color: Colors.green,
                                  theme: theme,
                                ),
                                _StatChip(
                                  label: 'Paid',
                                  value: '₹${_totalPaid.toStringAsFixed(0)}',
                                  color: Colors.red,
                                  theme: theme,
                                ),
                                _StatChip(
                                  label: 'Balance',
                                  value: '₹${_netBalance.toStringAsFixed(0)}',
                                  color: _netBalance >= 0
                                      ? Colors.green
                                      : Colors.red,
                                  theme: theme,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  widget.onEdit();
                } else if (value == 'bills') {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CustomerBillsScreen(customer: customer),
                    ),
                  );
                  _loadStats();
                } else if (value == 'delete') {
                  widget.onDelete();
                }
              },
              itemBuilder: (context) => [
                if (widget.isAdmin)
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'bills', child: Text('Bills')),
                if (widget.isAdmin)
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
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
        fontSize: 12,
      ),
    );
  }
}
