import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandyapp/dao/order_charge_dao.dart';
import 'package:mandyapp/dao/order_dao.dart';
import 'package:mandyapp/dao/order_payment_dao.dart';
import 'package:mandyapp/dao/order_expense_dao.dart';
import 'package:mandyapp/dao/product_dao.dart';
import 'package:mandyapp/dao/product_variant_dao.dart';
import 'package:mandyapp/dao/customer_dao.dart';
import 'package:mandyapp/models/order_charge_model.dart';
import 'package:mandyapp/models/order_expense_model.dart';
import 'package:mandyapp/models/order_model.dart';
import 'package:mandyapp/models/order_payment_model.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/utils/printer/printer_service.dart' as printer_service;
import 'package:mandyapp/widgets/billing/invoice_item.dart';
import 'package:mandyapp/widgets/billing/bill_line_item.dart';

class BillDetailsScreen extends StatefulWidget {
  final int orderId;

  const BillDetailsScreen({super.key, required this.orderId});

  @override
  State<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends State<BillDetailsScreen> {
  late Future<_BillDetailsData> _billFuture;

  @override
  void initState() {
    super.initState();
    _billFuture = _loadBillDetails();
  }

  Future<void> _handlePrint(_BillDetailsData data) async {
    final printerService = printer_service.PrinterService.instance;

    if (!printerService.connectionStatus.value) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No printer connected. Please connect a printer first.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!printerService.bluetoothEnabled.value) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth is not enabled. Please enable Bluetooth.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Printing invoice...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }

    final invoiceItems = data.lineItems.map((item) => InvoiceItem(
      productName: item.productName,
      quantity: item.sale.quantity,
      unit: item.unitLabel.isNotEmpty ? item.unitLabel : 'pc',
      price: item.sellingPrice,
      total: item.totalPrice,
    )).toList();

    final success = await printerService.printInvoice(
      cartId: data.order.id!,
      customerName: data.customerName,
      cartType: data.order.orderFor,
      items: invoiceItems,
      itemTotal: data.itemTotal,
      chargesTotal: data.chargesTotal,
      expensesTotal: data.expensesTotal,
      grandTotal: data.grandTotal,
      receivedAmount: data.receivedAmount,
      pendingAmount: data.pendingPayment,
      paymentMethod: data.paymentMethodLabel,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Invoice printed successfully!' : 'Failed to print invoice. Please try again.'),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<_BillDetailsData> _loadBillDetails() async {
    final orderDAO = OrderDAO();
    final orderChargeDAO = OrderChargeDAO();
    final orderPaymentDAO = OrderPaymentDAO();
    final orderExpenseDAO = OrderExpenseDao();
    final productDAO = ProductDAO();
    final productVariantDAO = ProductVariantDAO();
    final customerDAO = CustomerDAO();

    final order = await orderDAO.getOrderWithItems(widget.orderId);
    if (order == null) {
      throw StateError('Order not found');
    }

    final items = order.items ?? await orderDAO.getOrderItems(order.id!, orderFor: order.orderFor);
    final payments = await orderPaymentDAO.getOrderPaymentsByOrderId(order.id!);
    final charges = await orderChargeDAO.getOrderCharges(order.id.toString());
    final expenses = await orderExpenseDAO.getByOrderId(order.id!);
    final customers = await customerDAO.getCustomers();
    final Map<int, Customer> customerById = {
      for (final customer in customers)
        customer.id!: customer,
    };

    final List<BillLineItem> lineItems = [];
    for (final item in items) {
      final product = await productDAO.getProductById(item.productId);
      final variant = await productVariantDAO.getVariantById(item.variantId);
      lineItems.add(
        BillLineItem(
          sale: item,
          product: product,
          variant: variant,
          seller: customerById[item.sellerId],
        ),
      );
    }

    return _BillDetailsData(
      order: order,
      payments: payments,
      lineItems: lineItems,
      charges: charges,
      expenses: expenses,
      customerById: customerById,
    );
  }

  Future<void> _retry() async {
    setState(() {
      _billFuture = _loadBillDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<_BillDetailsData>(
          future: _billFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final data = snapshot.data!;
              final orderForLabel = data.order.orderFor == 'seller' ? 'Seller' : 'Buyer';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bill #${data.order.id ?? '-'}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$orderForLabel • ${data.customerName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }
            return const Text('Bill Details');
          },
        ),
        actions: [
          FutureBuilder<_BillDetailsData>(
            future: _billFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done ||
                  snapshot.hasError ||
                  !snapshot.hasData) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Print Bill'),
                        content: const Text('Do you really want to print this bill?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Print'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      _handlePrint(snapshot.data!);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.print_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Print',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<_BillDetailsData>(
        future: _billFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: theme.colorScheme.error.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Failed to load invoice',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Please try again later',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
          final createdAt = DateTime.fromMillisecondsSinceEpoch(data.order.updatedAt ?? DateTime.now().millisecondsSinceEpoch);

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 360),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildReceiptHeader(data, theme),
                      const SizedBox(height: 16),
                      const Divider(thickness: 1),
                      _buildReceiptInfo(data, createdAt, theme),
                      const SizedBox(height: 12),
                      const Divider(thickness: 1),
                      _buildReceiptItems(data, currency, theme),
                      const Divider(thickness: 1),
                      _buildReceiptSummary(data, currency, theme),
                      if (data.charges.isNotEmpty) ...[
                        _buildReceiptCharges(data, currency, theme),
                      ],
                      if (data.expenses.isNotEmpty) ...[
                        _buildReceiptExpenses(data, currency, theme),
                      ],
                      const Divider(thickness: 1),
                      _buildReceiptPayment(data, currency, theme),
                      const SizedBox(height: 16),
                      const Divider(thickness: 1),
                      Center(
                        child: Text(
                          'Thank you!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReceiptHeader(_BillDetailsData data, ThemeData theme) {
    final orderForLabel = data.order.orderFor == 'seller' ? 'Seller' : 'Buyer';
    return Column(
      children: [
        Text(
          'INVOICE',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '#${data.order.id ?? '-'}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$orderForLabel • ${data.customerName}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildReceiptInfo(_BillDetailsData data, DateTime createdAt, ThemeData theme) {
    final dateFormat = DateFormat('dd/MM/yyyy hh:mm a');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildInfoRow('Date', dateFormat.format(createdAt), theme),
          const SizedBox(height: 4),
          _buildInfoRow('Type', data.order.orderFor.toUpperCase(), theme),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptItems(_BillDetailsData data, NumberFormat currency, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Product',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                'Amount',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        ...data.lineItems.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.productName,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '${item.quantityLabel} × ${currency.format(item.sellingPrice)} = ${currency.format(item.totalPrice)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReceiptSummary(_BillDetailsData data, NumberFormat currency, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildSummaryRow('Item Total', currency.format(data.itemTotal), theme),
          const SizedBox(height: 4),
          _buildSummaryRow('Total Charges', currency.format(data.chargesTotal), theme),
          const SizedBox(height: 4),
          _buildSummaryRow('Total Expenses', currency.format(data.expensesTotal), theme),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GRAND TOTAL',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                currency.format(data.grandTotal),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildReceiptCharges(_BillDetailsData data, NumberFormat currency, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Charges',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          ...data.charges.map((charge) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  charge.chargeName,
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  currency.format(charge.chargeAmount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildReceiptExpenses(_BillDetailsData data, NumberFormat currency, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Expenses',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          ...data.expenses.map((expense) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    expense.expenseName,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  currency.format(expense.expenseAmount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildReceiptPayment(_BillDetailsData data, NumberFormat currency, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Info',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Amount Paid', currency.format(data.receivedAmount), theme),
          const SizedBox(height: 4),
          _buildInfoRow('Amount Due', currency.format(data.pendingPayment.abs()), theme),
          if (data.paymentMethodLabel.isNotEmpty && data.paymentMethodLabel != 'Not recorded') ...[
            const SizedBox(height: 4),
            _buildInfoRow('Payment Method', data.paymentMethodLabel, theme),
          ],
        ],
      ),
    );
  }
}

class _BillDetailsData {
  final Order order;
  final List<OrderPayment>? payments;
  final List<BillLineItem> lineItems;
  final List<OrderCharge> charges;
  final List<OrderExpense> expenses;
  final Map<int, Customer> customerById;

  const _BillDetailsData({
    required this.order,
    this.payments,
    required this.lineItems,
    required this.charges,
    required this.expenses,
    required this.customerById,
  });

  String get customerName {
    final customer = customerById[order.customerId];
    return customer?.name?.trim().isNotEmpty ?? false
        ? customer!.name!.trim()
        : 'Customer ${order.customerId}';
  }

  double get itemTotal {
    return lineItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get chargesTotal {
    return charges.fold(0.0, (sum, charge) => sum + charge.chargeAmount);
  }

  double get expensesTotal {
    return expenses.fold(0.0, (sum, expense) => sum + expense.expenseAmount);
  }

  double get grandTotal {
    if (order.orderFor == 'seller') {
      return itemTotal - chargesTotal;
    } else {
      return itemTotal + chargesTotal;
    }
  }

  double get receivedAmount {
    if (payments == null || payments!.isEmpty) {
      return 0.0;
    }
    return payments!.fold(0.0, (sum, payment) => sum + payment.amount);
  }

  double get outstandingAmount => grandTotal - receivedAmount;

  double get paymentAmount {
    if (order.orderFor == 'seller') {
      return grandTotal;
    } else {
      return receivedAmount;
    }
  }

  double get pendingPayment {
    if (order.orderFor == 'seller') {
      return paymentAmount - receivedAmount;
    } else {
      return outstandingAmount;
    }
  }

  String get paymentMethodLabel {
    if (payments == null || payments!.isEmpty) {
      return 'Not recorded';
    }
    final methods = <String>[];
    for (final payment in payments!) {
      switch (payment.source) {
        case 'cash':
          methods.add('Cash');
          break;
        case 'upi':
          methods.add('UPI');
          break;
        case 'card':
          methods.add('Card');
          break;
        case 'credit':
          methods.add('Credit');
          break;
      }
    }
    if (methods.isEmpty) {
      return 'Not recorded';
    }
    return methods.join(', ');
  }
}
