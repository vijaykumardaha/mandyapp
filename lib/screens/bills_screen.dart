import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:krishimandi/dao/customer_dao.dart';
import 'package:krishimandi/dao/order_charge_dao.dart';
import 'package:krishimandi/dao/order_dao.dart';
import 'package:krishimandi/dao/order_expense_dao.dart';
import 'package:krishimandi/dao/order_payment_dao.dart';
import 'package:krishimandi/helpers/theme/app_theme.dart';
import 'package:krishimandi/models/customer_model.dart';
import 'package:krishimandi/models/order_model.dart';
import 'package:krishimandi/widgets/common/common_app_bar.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';

class _BillSearchResult {
  final Order order;
  final String customerName;
  final String customerPhone;
  final double totalAmount;
  final double receivedAmount;
  final double pendingAmount;

  const _BillSearchResult({
    required this.order,
    required this.customerName,
    required this.customerPhone,
    required this.totalAmount,
    required this.receivedAmount,
    required this.pendingAmount,
  });
}

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late ThemeData theme;
  List<_BillSearchResult> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  final DateFormat _shortDateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 30));
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _search(_searchController.text));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final orderDAO = OrderDAO();
      final customerDAO = CustomerDAO();
      final orderChargeDAO = OrderChargeDAO();
      final orderPaymentDAO = OrderPaymentDAO();
      final orderExpenseDAO = OrderExpenseDao();

      final allOrders = await orderDAO.getAllOrders();
      final queryLower = query.trim().toLowerCase();
      final queryInt = int.tryParse(query.trim());

      final filteredOrders = allOrders.where((order) {
        final orderDate =
            DateTime.fromMillisecondsSinceEpoch(order.updatedAt ?? 0);
        return !orderDate.isBefore(_startDate) &&
            !orderDate.isAfter(_endDate.add(const Duration(days: 1)));
      }).toList();

      final matchedOrders = filteredOrders.where((order) {
        if (queryInt != null && order.id == queryInt) return true;
        return false;
      }).toList();

      final customerCache = <int, Customer?>{};
      final nameMatchedOrders = <Order>[];
      final phoneMatchedOrders = <Order>[];

      for (final order in filteredOrders) {
        if (matchedOrders.contains(order)) continue;
        if (queryLower.isEmpty) {
          nameMatchedOrders.add(order);
          continue;
        }
        if (!customerCache.containsKey(order.customerId)) {
          customerCache[order.customerId] =
              await customerDAO.getCustomerById(order.customerId);
        }
        final customer = customerCache[order.customerId];
        if (customer == null) continue;

        final name = (customer.name ?? '').toLowerCase();
        final phone = (customer.phone ?? '').toLowerCase();

        if (name.contains(queryLower)) {
          nameMatchedOrders.add(order);
        } else if (phone.contains(queryLower)) {
          phoneMatchedOrders.add(order);
        }
      }

      final allMatched = [
        ...matchedOrders,
        ...nameMatchedOrders,
        ...phoneMatchedOrders
      ];

      final results = <_BillSearchResult>[];
      for (final order in allMatched) {
        final orderWithItems = await orderDAO.getOrderWithItems(order.id!);

        if (!customerCache.containsKey(order.customerId)) {
          customerCache[order.customerId] =
              await customerDAO.getCustomerById(order.customerId);
        }
        final customer = customerCache[order.customerId];

        final charges =
            await orderChargeDAO.getOrderCharges(order.id.toString());
        final expenses = await orderExpenseDAO.getByOrderId(order.id!);
        final payments =
            await orderPaymentDAO.getOrderPaymentsByOrderId(order.id!);

        final itemTotal = orderWithItems?.totalPrice ?? 0.0;
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

        results.add(_BillSearchResult(
          order: order,
          customerName: customer?.name ?? 'Unknown',
          customerPhone: customer?.phone ?? '',
          totalAmount: total,
          receivedAmount: received,
          pendingAmount: total - received,
        ));
      }

      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        showBackButton: false,
        titleWidget: TextField(
          controller: _searchController,
          onChanged: (q) => _search(q),
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search by bill ID, name or mobile...',
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            prefixIcon: Icon(Icons.search,
                size: 20, color: theme.colorScheme.onSurfaceVariant),
            prefixIconConstraints: const BoxConstraints(minWidth: 36),
            suffixIcon: GestureDetector(
              onTap: _showDateFilter,
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.date_range,
                    size: 20, color: theme.colorScheme.primary),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasSearched) {
      return Center(
        child: Padding(
          padding: MySpacing.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
              MySpacing.height(16),
              MyText.bodyLarge(
                'Search bills by ID, customer name or mobile number',
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Padding(
          padding: MySpacing.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off,
                  size: 64,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
              MySpacing.height(16),
              MyText.bodyLarge(
                'No bills found',
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.date_range,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              MyText.bodySmall(
                '${_shortDateFormat.format(_startDate)} - ${_shortDateFormat.format(_endDate)}',
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const Spacer(),
              MyText.bodySmall(
                '${_results.length} bill${_results.length == 1 ? '' : 's'}',
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: 600,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: MySpacing.xy(16, 4),
            itemCount: _results.length,
            itemBuilder: (context, index) => _buildBillTile(_results[index]),
          ),
        ),
      ],
    );
  }

  Future<void> _showDateFilter() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: theme.colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _search(_searchController.text);
    }
  }

  Widget _buildBillTile(_BillSearchResult result) {
    final order = result.order;

    return GestureDetector(
      onTap: () async {
        await context.push('/bill-details/${order.id}');
        if (mounted) _search(_searchController.text);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              color: theme.colorScheme.outline.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      MyText.bodySmall(
                        '#${order.id}',
                        fontWeight: 600,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      MyText.titleMedium(result.customerName, fontWeight: 600),
                    ],
                  ),
                  const SizedBox(height: 4),
                  MyText.bodySmall(
                    _shortDateFormat.format(DateTime.fromMillisecondsSinceEpoch(
                        order.updatedAt ?? 0)),
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (result.pendingAmount.abs() > 0.01) ...[
                      MyText.bodySmall(
                        '(${_currencyFormat.format(result.pendingAmount)} ${result.pendingAmount > 0 ? "Dues" : "Refund"})',
                        color: result.pendingAmount > 0
                            ? Colors.red
                            : Colors.green,
                        fontWeight: 500,
                      ),
                      const SizedBox(width: 8),
                    ],
                    MyText.bodyMedium(
                      _currencyFormat.format(result.totalAmount),
                      fontWeight: 600,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                MyText.bodySmall(
                  order.orderFor.toUpperCase(),
                  color: order.orderFor == 'buyer' ? Colors.blue : Colors.teal,
                  fontWeight: 500,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
