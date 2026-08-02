import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:krishimandi/blocs/order/order_bloc.dart';
import 'package:krishimandi/dao/order_charge_dao.dart';
import 'package:krishimandi/dao/order_expense_dao.dart';
import 'package:krishimandi/dao/order_payment_dao.dart';
import 'package:krishimandi/models/customer_model.dart';
import 'package:krishimandi/models/order_model.dart';
import 'package:krishimandi/services/sync_service.dart';
import 'package:krishimandi/utils/constants.dart';
import 'package:krishimandi/widgets/common/common_app_bar.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/customer_bills/bill_card.dart';
import 'package:krishimandi/widgets/customer_bills/customer_summary_card.dart';

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
  final OrderChargeDAO _chargeDAO = OrderChargeDAO();
  final OrderExpenseDao _expenseDAO = OrderExpenseDao();
  final OrderPaymentDAO _paymentDAO = OrderPaymentDAO();
  final Map<int, _OrderFinancialSummary> _financialData = {};
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  int _buyerBillCount = 0;
  double _buyerBillTotal = 0;
  int _sellerBillCount = 0;
  double _sellerBillTotal = 0;
  int _buyerDueCount = 0;
  double _buyerDuesTotal = 0;
  int _sellerDueCount = 0;
  double _sellerDuesTotal = 0;

  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(LoadOrdersByCustomer(widget.customer.id!));

    _syncSubscription = SyncService.instance.tableUpdates.listen((table) {
      if (!mounted) return;
      if (table == DbTables.orders) {
        final state = context.read<OrderBloc>().state;
        if (state is OrdersLoaded) {
          context
              .read<OrderBloc>()
              .add(LoadOrdersByCustomer(widget.customer.id!));
        }
      }
    });
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadFinancialData(List<Order> orders) async {
    final data = <int, _OrderFinancialSummary>{};
    for (final order in orders) {
      if (order.id == null) continue;
      final charges = await _chargeDAO.getOrderCharges(order.id.toString());
      final expenses = await _expenseDAO.getByOrderId(order.id!);
      final payments = await _paymentDAO.getOrderPaymentsByOrderId(order.id!);

      final itemTotal = order.totalPrice;
      final chargesTotal =
          charges.fold<double>(0.0, (sum, c) => sum + c.chargeAmount);
      final expensesTotal =
          expenses.fold<double>(0.0, (sum, e) => sum + e.expenseAmount);
      final received = payments.fold<double>(0.0, (sum, p) => sum + p.amount);

      double total;
      if (order.orderFor == 'seller') {
        total = itemTotal - chargesTotal - expensesTotal;
      } else {
        total = itemTotal + chargesTotal + expensesTotal;
      }

      data[order.id!] = _OrderFinancialSummary(
        grandTotal: total,
        receivedAmount: received,
      );
    }
    if (mounted) {
      setState(() {
        _financialData.clear();
        _financialData.addAll(data);
        _buyerBillCount = 0;
        _buyerBillTotal = 0;
        _sellerBillCount = 0;
        _sellerBillTotal = 0;
        _buyerDueCount = 0;
        _buyerDuesTotal = 0;
        _sellerDueCount = 0;
        _sellerDuesTotal = 0;
        for (final order in orders) {
          final financial = order.id != null ? data[order.id] : null;
          if (financial == null) continue;
          final due = financial.grandTotal - financial.receivedAmount;
          if (order.orderFor == 'seller') {
            _sellerBillCount++;
            _sellerBillTotal += financial.grandTotal;
            if (due > 0.01) {
              _sellerDueCount++;
              _sellerDuesTotal += due;
            }
          } else {
            _buyerBillCount++;
            _buyerBillTotal += financial.grandTotal;
            if (due > 0.01) {
              _buyerDueCount++;
              _buyerDuesTotal += due;
            }
          }
        }
      });
    }
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

              if (_financialData.isEmpty) {
                _loadFinancialData(customerOrders);
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
      itemCount: orders.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSummarySection();
        }
        final order = orders[index - 1];
        final financial = order.id != null ? _financialData[order.id] : null;
        return BillCard(
          order: order,
          grandTotal: financial?.grandTotal,
          receivedAmount: financial?.receivedAmount,
        );
      },
    );
  }

  Widget _buildSummarySection() {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          SizedBox(
            width: 160,
            child: CustomerSummaryCard(
              label: 'Buyer Bills',
              count: '$_buyerBillCount bills',
              amount: _currencyFormat.format(_buyerBillTotal),
              color: Colors.blue,
            ),
          ),
          MySpacing.width(12),
          SizedBox(
            width: 160,
            child: CustomerSummaryCard(
              label: 'Seller Bills',
              count: '$_sellerBillCount bills',
              amount: _currencyFormat.format(_sellerBillTotal),
              color: Colors.teal,
            ),
          ),
          MySpacing.width(12),
          SizedBox(
            width: 160,
            child: CustomerSummaryCard(
              label: 'Buyer Dues',
              count: '$_buyerDueCount bills',
              amount: _currencyFormat.format(_buyerDuesTotal),
              color: Colors.red,
            ),
          ),
          MySpacing.width(12),
          SizedBox(
            width: 160,
            child: CustomerSummaryCard(
              label: 'Seller Dues',
              count: '$_sellerDueCount bills',
              amount: _currencyFormat.format(_sellerDuesTotal),
              color: Colors.green,
            ),
          ),
        ],
      ),
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
                color: theme.colorScheme.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
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
              'Bills for ${widget.customer.name ?? 'this customer'} will appear here once created',
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

class _OrderFinancialSummary {
  final double grandTotal;
  final double receivedAmount;

  const _OrderFinancialSummary({
    required this.grandTotal,
    required this.receivedAmount,
  });
}
