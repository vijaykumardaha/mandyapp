import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandiapp/blocs/order/order_bloc.dart';
import 'package:mandiapp/models/customer_model.dart';
import 'package:mandiapp/models/order_model.dart';
import 'package:mandiapp/services/sync_service.dart';
import 'package:mandiapp/widgets/common/common_app_bar.dart';
import 'package:mandiapp/widgets/customer_bills/bill_card.dart';

class CustomerBillsScreen extends StatefulWidget {
  final Customer customer;

  const CustomerBillsScreen({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerBillsScreen> createState() => _CustomerBillsScreenState();
}

class _CustomerBillsScreenState extends State<CustomerBillsScreen> {
  StreamSubscription<String>? _syncSubscription;

  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(LoadOrdersByCustomer(widget.customer.id!));

    _syncSubscription = SyncService.instance.tableUpdates.listen((table) {
      if (!mounted) return;
      if (table == 'orders') {
        final state = context.read<OrderBloc>().state;
        if (state is OrdersLoaded) {
          context.read<OrderBloc>().add(LoadOrdersByCustomer(widget.customer.id!));
        }
      }
    });
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CommonAppBar(
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bills',
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
      ),
      body: SafeArea(
        child: BlocBuilder<OrderBloc, OrderState>(
          builder: (context, state) {
            if (state is OrderLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is OrderError) {
              return Center(child: Text(state.message));
            }

            if (state is OrdersLoaded) {
              final customerOrders = state.orders;

              if (customerOrders.isEmpty) {
                return _buildEmptyState(theme);
              }

              return _buildBillsList(customerOrders);
            }

            if (state is OrderEmpty) {
              return _buildEmptyState(theme);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildBillsList(List<Order> orders) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return BillCard(order: orders[index]);
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No bills yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bills will appear here once created',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
