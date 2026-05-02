import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandyapp/dao/order_charge_dao.dart';
import 'package:mandyapp/dao/order_dao.dart';
import 'package:mandyapp/dao/order_payment_dao.dart';
import 'package:mandyapp/dao/order_expense_dao.dart';
import 'package:mandyapp/dao/product_dao.dart';
import 'package:mandyapp/dao/product_variant_dao.dart';
import 'package:mandyapp/dao/customer_dao.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/order_charge_model.dart';
import 'package:mandyapp/models/order_expense_model.dart';
import 'package:mandyapp/models/order_model.dart';
import 'package:mandyapp/models/order_payment_model.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/screens/checkout_screen.dart';
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

  Future<void> _handleEdit(_BillDetailsData data) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          orderId: data.order.id!,
          isEdit: true,
        ),
      ),
    );

    if (!mounted) return;

    setState(() {
      _billFuture = _loadBillDetails();
    });
  }

  Future<void> _handlePrint(_BillDetailsData data) async {
    final printerService = printer_service.PrinterService.instance;

    // Check if printer is connected
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

    // Check if Bluetooth is enabled
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

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Printing invoice...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Convert line items to invoice items
    final invoiceItems = data.lineItems.map((item) => InvoiceItem(
      productName: item.productName,
      quantity: item.sale.quantity,
      unit: item.unitLabel.isNotEmpty ? item.unitLabel : 'pc',
      price: item.sellingPrice,
      total: item.totalPrice,
    )).toList();

    // Print the invoice
    final success = await printerService.printInvoice(
      cartId: data.order.id!,
      customerName: data.customerName,
      cartType: data.order.orderFor,
      items: invoiceItems,
      itemTotal: data.itemTotal,
      chargesTotal: data.chargesTotal,
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
    final payment = await orderPaymentDAO.getOrderPaymentByOrderId(order.id!);
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
      payment: payment,
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
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(''),
        actions: [
          Builder(
            builder: (context) {
              return FutureBuilder<_BillDetailsData>(
                future: _billFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done || 
                      snapshot.hasError || 
                      !snapshot.hasData) {
                    return const SizedBox.shrink();
                  }
                  
                  final data = snapshot.data!;
                  return Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _handleEdit(data),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.print_outlined),
                        onPressed: () => _handlePrint(data),
                        tooltip: 'Print',
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<_BillDetailsData>(
        future: _billFuture,
        builder: (context, snapshot) {
          // Return loading indicator or error if needed
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MyText.titleMedium('Failed to load invoice', fontWeight: 600),
                  const SizedBox(height: 12),
                  MyText.bodyMedium('Please try again later.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _retry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          final data = snapshot.data!;
          final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
          final dateFormat = DateFormat('dd MMM yyyy | hh:mm a');
          final createdAt = DateTime.tryParse(data.order.createdAt) ?? DateTime.now();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          color: theme.colorScheme.primary.withOpacity(0.04),
                          border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.08))),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                MyText.bodySmall('Created:', color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                const SizedBox(width: 6),
                                MyText.bodySmall(dateFormat.format(createdAt), fontWeight: 600),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: _buildInfoMetric(
                                      'Payment Method',
                                      data.paymentMethodLabel,
                                      theme,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: _buildInfoMetric(
                                      data.order.orderFor == 'seller' ? 'Amount Received' : 'Received Amount',
                                      currency.format(data.receivedAmount),
                                      theme,
                                      valueColor: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: _buildInfoMetric(
                                      data.order.orderFor == 'seller' ? 'Amount Pending' : 'Pending Amount',
                                      currency.format(data.outstandingAmount.abs()),
                                      theme,
                                      valueColor: data.outstandingAmount > 0
                                          ? Colors.orange
                                          : (data.outstandingAmount < 0 ? Colors.green : null),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildItemsSection(data, currency, theme),
                            const SizedBox(height: 24),
                            _buildBillChangesSection(data, currency, theme),
                            const SizedBox(height: 24),
                            _buildExpensesSection(data, currency, theme),
                            const SizedBox(height: 24),
                            _buildSummarySection(data, currency, theme),
                            const SizedBox(height: 24),
                            Center(
                              child: MyText.bodySmall(
                                'Thank you for shopping with us!',
                                fontWeight: 500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemsSection(_BillDetailsData data, NumberFormat currency, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: MyText.bodySmall('PRODUCT', fontWeight: 600, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: MyText.bodySmall('QTY', fontWeight: 600, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: MyText.bodySmall('RATE', fontWeight: 600, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: MyText.bodySmall('TOTAL', fontWeight: 600, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  ),
                ),
              ],
            ),
          ),
          // Items
          ...data.lineItems.map((item) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name Column
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (item.seller?.name != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Seller: ${item.seller!.name}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Quantity Column
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${item.quantityLabel} ${item.variant?.unit ?? item.product?.defaultVariantModel?.unit ?? 'pc'}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    // Rate Column
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          currency.format(item.sale.sellingPrice),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    // Total Column
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          currency.format(item.sale.sellingPrice * item.sale.quantity),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (item != data.lineItems.last)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                  indent: 16,
                  endIndent: 16,
                ),
            ],
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildBillChangesSection(_BillDetailsData data, NumberFormat currency, ThemeData theme) {
    final charges = data.charges;
    final hasCharges = charges.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: MyText.bodySmall('Charge Name', fontWeight: 600),
                ),
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: MyText.bodySmall('Total', fontWeight: 600),
                  ),
                ),
              ],
            ),
          ),
          if (!hasCharges)
            Padding(
              padding: const EdgeInsets.all(16),
              child: MyText.bodySmall(
                'No additional charges were applied to this invoice.',
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            )
          else ...[
            for (final charge in charges)...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: MyText.bodyMedium(
                        charge.chargeName,
                        fontWeight: 600,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: MyText.bodyMedium(currency.format(charge.chargeAmount)),
                      ),
                    ),
                  ],
                ),
              ),
              if (charge != charges.last)
                Divider(height: 1, thickness: 0.5, color: theme.colorScheme.onSurface.withOpacity(0.05)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildExpensesSection(_BillDetailsData data, NumberFormat currency, ThemeData theme) {
    final expenses = data.expenses;
    final hasExpenses = expenses.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 20,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                MyText.bodySmall('EXPENSES', fontWeight: 600, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                const Spacer(),
                MyText.bodySmall(
                  hasExpenses ? currency.format(data.expensesTotal) : 'No Expenses',
                  fontWeight: 600,
                  color: hasExpenses ? theme.colorScheme.secondary : theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ],
            ),
          ),
          if (!hasExpenses)
            Padding(
              padding: const EdgeInsets.all(16),
              child: MyText.bodySmall(
                'No expenses were recorded for this order.',
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            )
          else ...[
            for (final expense in expenses)...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyText.bodyMedium(
                            expense.expenseName,
                            fontWeight: 500,
                          ),
                          if (expense.expenseNote != null && expense.expenseNote!.isNotEmpty)
                            MyText.bodySmall(
                              expense.expenseNote!,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: MyText.bodyMedium(
                          currency.format(expense.expenseAmount),
                          fontWeight: 600,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (expense != expenses.last)
                Divider(height: 1, thickness: 0.5, color: theme.colorScheme.onSurface.withOpacity(0.05)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSummarySection(_BillDetailsData data, NumberFormat currency, ThemeData theme) {
    final rows = <MapEntry<String, String>>[
      MapEntry('Item Total', currency.format(data.itemTotal)),
      if (data.chargesTotal > 0) MapEntry('Charge Total', currency.format(data.chargesTotal)),
      if (data.expensesTotal > 0) MapEntry('Expense Total', currency.format(data.expensesTotal)),
      MapEntry('Grand Total', currency.format(data.grandTotal))
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: MyText.bodySmall('Summary', fontWeight: 600),
                ),
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: MyText.bodySmall('Amount', fontWeight: 600),
                  ),
                ),
              ],
            ),
          ),
          for (final entry in rows)...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: MyText.bodyMedium(
                      entry.key,
                      fontWeight: entry.key == 'Grand Total' ? 700 : 600,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: MyText.bodyMedium(
                        entry.value,
                        fontWeight: entry.key == 'Grand Total' ? 700 : 600,
                        color: (entry.key.contains('Pending') || entry.key.contains('Amount Pending'))
                            ? Colors.orange
                            : (entry.key.contains('Amount Received') || entry.key.contains('Received') ? theme.colorScheme.primary : null),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (entry != rows.last)
              Divider(height: 1, thickness: 0.5, color: theme.colorScheme.onSurface.withOpacity(0.05)),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoMetric(String label, String value, ThemeData theme, {Color? valueColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _BillDetailsData {
  final Order order;
  final OrderPayment? payment;
  final List<BillLineItem> lineItems;
  final List<OrderCharge> charges;
  final List<OrderExpense> expenses;
  final Map<int, Customer> customerById;

  const _BillDetailsData({
    required this.order,
    required this.payment,
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

  String get invoiceLabel => 'Invoice #${order.id}';

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
      // For buyer orders, use current implementation (subtotal + chargesTotal)
      return itemTotal + chargesTotal;
    }
  }

  double get receivedAmount => payment?.receiveAmount ?? 0.0;

  double get outstandingAmount => grandTotal - receivedAmount;

  // Calculate paymentAmount and pendingPayment based on order type
  double get paymentAmount {
    if (order.orderFor == 'seller') {
      // For seller orders, paymentAmount is the amount to be paid to seller (after deducting charges)
      return grandTotal;
    } else {
      // For buyer orders, paymentAmount is the total amount received
      return receivedAmount;
    }
  }

  double get pendingPayment {
    if (order.orderFor == 'seller') {
      // For seller orders, pendingPayment is the amount still owed to seller
      return paymentAmount - receivedAmount;
    } else {
      // For buyer orders, pendingPayment is the remaining amount to be paid
      return outstandingAmount;
    }
  }

  String get paymentMethodLabel {
    if (payment == null) {
      return 'Not recorded';
    }
    final methods = <String>[];
    if (payment!.cashPayment == 1) {
      methods.add('Cash');
    }
    if (payment!.upiPayment == 1) {
      methods.add('UPI');
    }
    if (payment!.cardPayment == 1) {
      methods.add('Card');
    }
    if (payment!.creditPayment == 1) {
      methods.add('Credit');
    }
    if (methods.isEmpty) {
      return 'Not recorded';
    }
    return methods.join(', ');
  }
}

