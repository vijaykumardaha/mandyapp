import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mandiapp/blocs/customer/customer_bloc.dart';
import 'package:mandiapp/blocs/customer_payment/customer_payment_bloc.dart';
import 'package:mandiapp/blocs/login/login_bloc.dart';
import 'package:mandiapp/blocs/order/order_bloc.dart';
import 'package:mandiapp/dao/order_charge_dao.dart';
import 'package:mandiapp/dao/order_expense_dao.dart';
import 'package:mandiapp/dao/order_payment_dao.dart';
import 'package:mandiapp/helpers/theme/app_theme.dart';
import 'package:mandiapp/models/customer_model.dart';
import 'package:mandiapp/models/order_model.dart';
import 'package:mandiapp/services/socket_service.dart';
import 'package:mandiapp/services/sync_service.dart';
import 'package:mandiapp/utils/app_helper.dart';
import 'package:mandiapp/widgets/common/my_text.dart';
import 'package:mandiapp/widgets/common/my_text_style.dart';
import 'package:mandiapp/widgets/customer_bills/bill_card.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomerBloc()..add(const LoadCurrentCustomer()),
      child: const _CustomerHomeScreenView(),
    );
  }
}

class _CustomerHomeScreenView extends StatefulWidget {
  const _CustomerHomeScreenView();

  @override
  State<_CustomerHomeScreenView> createState() =>
      _CustomerHomeScreenViewState();
}

class _CustomerHomeScreenViewState extends State<_CustomerHomeScreenView>
    with SingleTickerProviderStateMixin {
  late ThemeData theme;
  late TabController _tabController;
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  final DateFormat _dateFormatShort = DateFormat('dd MMM');
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final OrderChargeDAO _chargeDAO = OrderChargeDAO();
  final OrderExpenseDao _expenseDAO = OrderExpenseDao();
  final OrderPaymentDAO _paymentDAO = OrderPaymentDAO();
  final Map<int, _OrderFinancialSummary> _financialData = {};
  String _userName = 'Customer';
  Customer? _customer;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    _tabController = TabController(length: 2, vsync: this);
    _startConnectivityListener();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final userData = await AppHelper.getPreferences('user');
    if (userData == null) return;
    final user = userData as Map<String, dynamic>;
    setState(() => _userName = user['name'] ?? 'Customer');
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
      });
    }
  }

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (results) async {
        final hasConnection = results.any((r) => r != ConnectivityResult.none);

        if (hasConnection && _wasOffline) {
          if (!SocketService.instance.isConnected) {
            await SyncService.instance.connectAndSync();
          }
        }

        _wasOffline = !hasConnection;
      },
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isSyncing = context.select(
        (CustomerBloc bloc) => bloc.state is CurrentCustomerSyncLoading);

    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 56),
      child: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: kToolbarHeight + 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText.titleLarge(_userName, fontWeight: 700),
            MyText.bodyMedium(
              _dateFormat.format(DateTime.now()),
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
        titleTextStyle: MyTextStyle.bodyMedium(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: GestureDetector(
              onTap: isSyncing
                  ? null
                  : () {
                      context
                          .read<CustomerBloc>()
                          .add(const SyncCurrentCustomer());
                    },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isSyncing
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        : Icon(Icons.sync_rounded,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      isSyncing ? 'Syncing...' : 'Data Sync',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: GestureDetector(
              onTap: () {
                context.read<LoginBloc>().add(LogoutSubmit());
              },
              child: Icon(
                Icons.logout_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor:
              theme.colorScheme.onSurface.withValues(alpha: 0.6),
          labelStyle: MyTextStyle.bodyMedium(fontWeight: 600),
          tabs: const [
            Tab(text: 'Bills'),
            Tab(text: 'Payments'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LogoutSuccess) {
          context.go('/login');
        }
      },
      child: BlocListener<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is CurrentCustomerLoaded) {
            if (mounted) {
              _customer = state.customer;
              _financialData.clear();
              if (_customer != null) {
                context.read<OrderBloc>().add(
                      LoadOrdersByCustomer(_customer!.id!),
                    );
                context.read<CustomerPaymentBloc>().add(
                      FetchPayments(customerId: _customer!.id!),
                    );
              }
            }
          }
          if (state is CurrentCustomerSyncSuccess) {
            _customer = state.customer;
            if (mounted) {
              _financialData.clear();
              if (_customer != null) {
                context.read<OrderBloc>().add(
                      LoadOrdersByCustomer(_customer!.id!),
                    );
                context.read<CustomerPaymentBloc>().add(
                      FetchPayments(customerId: _customer!.id!),
                    );
              }
            }
          }
          if (state is CurrentCustomerError) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          }
        },
        child: Scaffold(
          appBar: _buildAppBar(context),
          body: SafeArea(
            child: BlocBuilder<CustomerBloc, CustomerState>(
              builder: (context, state) {
                if (state is CurrentCustomerLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is CurrentCustomerError) {
                  return Center(child: Text(state.message));
                }

                final customer = state is CurrentCustomerLoaded
                    ? state.customer
                    : state is CurrentCustomerSyncSuccess
                        ? state.customer
                        : state is CurrentCustomerSyncLoading
                            ? state.customer
                            : null;

                if (customer == null) {
                  return Center(
                    child: MyText.bodyMedium(
                      'No customer data found',
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBillsTab(context, customer),
                    _buildPaymentsTab(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillsTab(BuildContext context, Customer? customer) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrderLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is OrderError) {
          return Center(child: Text(state.message));
        }

        if (state is OrdersLoaded) {
          final orders = state.orders;
          if (orders.isEmpty) {
            return _buildEmptyState(
                Icons.receipt_long_outlined, 'No bills yet');
          }

          if (_financialData.isEmpty) {
            _loadFinancialData(orders);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final financial =
                  order.id != null ? _financialData[order.id] : null;
              return BillCard(
                order: order,
                grandTotal: financial?.grandTotal,
                receivedAmount: financial?.receivedAmount,
              );
            },
          );
        }

        return _buildEmptyState(Icons.receipt_long_outlined, 'No bills yet');
      },
    );
  }

  Widget _buildPaymentsTab() {
    return BlocBuilder<CustomerPaymentBloc, CustomerPaymentState>(
      builder: (context, state) {
        if (state is CustomerPaymentLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CustomerPaymentError) {
          return Center(child: Text(state.message));
        }

        if (state is CustomerPaymentsLoaded) {
          final payments = state.payments;
          if (payments.isEmpty) {
            return _buildEmptyState(
                Icons.payment_outlined, 'No payment history yet');
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              final paymentDate =
                  DateTime.fromMillisecondsSinceEpoch(payment.paymentDate);
              final isReceived = payment.type == 'received';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isReceived
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                                size: 16,
                                color: isReceived ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              MyText.bodySmall(
                                isReceived ? 'Received' : 'Paid',
                                fontWeight: 600,
                                color: isReceived ? Colors.green : Colors.red,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          MyText.bodySmall(
                            '${payment.source} · ${payment.note}',
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          MyText.bodySmall(
                            _dateFormatShort.format(paymentDate),
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                    MyText.bodyMedium(
                      '${isReceived ? "+" : "-"}${_currencyFormat.format(payment.amount)}',
                      fontWeight: 600,
                      color: isReceived ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              );
            },
          );
        }

        return _buildEmptyState(
            Icons.payment_outlined, 'No payment history yet');
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            MyText.bodyLarge(
              message,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
