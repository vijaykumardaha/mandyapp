import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandiapp/dao/customer_dao.dart';
import 'package:mandiapp/dao/customer_payment_dao.dart';
import 'package:mandiapp/dao/order_charge_dao.dart';
import 'package:mandiapp/dao/order_dao.dart';
import 'package:mandiapp/dao/order_expense_dao.dart';
import 'package:mandiapp/dao/order_payment_dao.dart';
import 'package:mandiapp/dao/product_dao.dart';
import 'package:mandiapp/dao/product_variant_dao.dart';
import 'package:mandiapp/models/customer_model.dart';
import 'package:mandiapp/models/customer_payment_model.dart';
import 'package:mandiapp/models/order_payment_model.dart';
import 'package:mandiapp/services/printer_service.dart' as printer_service;
import 'package:mandiapp/utils/app_helper.dart';
import 'package:mandiapp/utils/db_helper.dart';
import 'package:mandiapp/utils/info_controller.dart';
import 'package:mandiapp/widgets/bill_details/bill_details_data.dart';
import 'package:mandiapp/widgets/bill_details/receipt_info.dart';
import 'package:mandiapp/widgets/bill_details/receipt_items.dart';
import 'package:mandiapp/widgets/bill_details/receipt_payment.dart';
import 'package:mandiapp/widgets/bill_details/receipt_summary.dart';
import 'package:mandiapp/widgets/billing/bill_line_item.dart';
import 'package:mandiapp/widgets/common/common_app_bar.dart';
import 'package:mandiapp/widgets/common/dropdown_option.dart';

const _paymentSources = ['cash', 'upi', 'card', 'credit'];

String _paymentSourceLabel(String source) => switch (source) {
      'cash' => 'Cash',
      'upi' => 'UPI',
      'card' => 'Card',
      'credit' => 'Credit',
      _ => source,
    };

class BillDetailsScreen extends StatefulWidget {
  final int orderId;

  const BillDetailsScreen({super.key, required this.orderId});

  @override
  State<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends State<BillDetailsScreen> {
  late Future<BillDetailsData> _billFuture;
  String _mandiName = '';
  bool _isCustomer = false;

  @override
  void initState() {
    super.initState();
    _billFuture = _loadBillDetails();
    _loadMandiName();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = await AppHelper.getCurrentUser();
    if (mounted) {
      setState(() => _isCustomer = user?.isCustomer ?? false);
    }
  }

  Future<void> _loadMandiName() async {
    final user = await AppHelper.getCurrentUser();
    final name = user?.name?.trim() ?? '';
    if (!mounted) return;
    setState(() => _mandiName = name);
  }

  Future<void> _handlePrint(BillDetailsData data) async {
    final printerService = printer_service.PrinterService.instance;

    if (!printerService.connectionStatus.value) {
      if (mounted) {
        Info.error('No printer connected. Please connect a printer first.',
            context: context);
      }
      return;
    }

    if (!printerService.bluetoothEnabled.value) {
      if (mounted) {
        Info.error('Bluetooth is not enabled. Please enable Bluetooth.',
            context: context);
      }
      return;
    }

    if (mounted) {
      Info.message('Printing bills...',
          context: context, duration: const Duration(seconds: 2));
    }

    final isSellerOrder = data.order.orderFor == 'seller';
    final invoiceItems = data.lineItems
        .map((item) => printer_service.InvoiceItem(
              productName: item.productName,
              quantity: item.sale.quantity,
              unit: item.unitLabel.isNotEmpty ? item.unitLabel : 'pc',
              price: item.sellingPrice,
              total: item.totalPrice,
              partnerName:
                  isSellerOrder ? item.sale.buyerName : item.sellerLabel,
              partnerType: isSellerOrder ? 'Buyer' : 'Seller',
            ))
        .toList();

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
      if (success) {
        Info.message('Bill printed successfully',
            context: context, duration: const Duration(seconds: 3));
      } else {
        Info.error('Failed to print bill. Please try again.',
            context: context, duration: const Duration(seconds: 3));
      }
    }
  }

  Future<BillDetailsData> _loadBillDetails() async {
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

    final items = order.items ??
        await orderDAO.getOrderItems(order.id!, orderFor: order.orderFor);
    final payments = await orderPaymentDAO.getOrderPaymentsByOrderId(order.id!);
    final charges = await orderChargeDAO.getOrderCharges(order.id.toString());
    final expenses = await orderExpenseDAO.getByOrderId(order.id!);
    final customers = await customerDAO.getCustomers();
    final Map<int, Customer> customerById = {
      for (final customer in customers) customer.id!: customer,
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

    return BillDetailsData(
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

  void _showReceivePaymentSheet(BillDetailsData data) {
    String selectedSource = 'cash';
    final amountController = TextEditingController(
      text: data.pendingPayment.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final theme = Theme.of(context);
            const accentColor = Colors.green;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Receive Payment',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Due: ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(data.pendingPayment)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₹ ',
                        prefixStyle: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: accentColor, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter amount';
                        }
                        final amount = double.tryParse(value.trim());
                        if (amount == null || amount <= 0) {
                          return 'Enter valid amount';
                        }
                        if (amount > data.pendingPayment) {
                          return 'Amount exceeds pending balance';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedSource,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      menuMaxHeight: 300,
                      elevation: 4,
                      decoration: InputDecoration(
                        labelText: 'Payment Method',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: accentColor, width: 2),
                        ),
                      ),
                      items: [
                        for (final source in _paymentSources)
                          DropdownMenuItem(
                            value: source,
                            child: DropdownOption(
                              selected: selectedSource == source,
                              child: Text(_paymentSourceLabel(source)),
                            ),
                          ),
                      ],
                      selectedItemBuilder: (context) => [
                        for (final source in _paymentSources)
                          Text(_paymentSourceLabel(source)),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => selectedSource = value);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final amount =
                              double.parse(amountController.text.trim());
                          Navigator.pop(context);
                          await _receivePayment(data, amount, selectedSource);
                        },
                        child: const Text(
                          'Receive Payment',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _receivePayment(
      BillDetailsData data, double amount, String source) async {
    if (!mounted) return;
    Info.message('Recording payment...',
        context: context, duration: const Duration(seconds: 2));

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final orderPaymentDAO = OrderPaymentDAO();
      final customerPaymentDAO = CustomerPaymentDAO();

      // 1. Insert into order_payments (reduces bill pending)
      await orderPaymentDAO.insertOrderPayment(OrderPayment(
        id: DBHelper.generateUuidInt(),
        orderId: data.order.id!,
        source: source,
        amount: amount,
        updatedAt: now,
      ));

      // 2. Insert into customer_payments (keeps customer ledger consistent)
      final transactionType =
          data.order.orderFor == 'buyer' ? 'paid' : 'received';
      await customerPaymentDAO.insertPayment(CustomerPayment(
        customerId: data.order.customerId,
        amount: amount,
        type: transactionType,
        source: source,
        note: 'Bill #${data.order.id}',
        paymentDate: now,
      ));

      // 3. Refresh bill details
      if (mounted) {
        setState(() {
          _billFuture = _loadBillDetails();
        });
        Info.message('Payment recorded successfully',
            context: context, duration: const Duration(seconds: 2));
      }
    } catch (e) {
      if (mounted) {
        Info.error('Failed to record payment. Please try again.',
            context: context, duration: const Duration(seconds: 3));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CommonAppBar(
        titleWidget: FutureBuilder<BillDetailsData>(
          future: _billFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final data = snapshot.data!;
              final orderForLabel =
                  data.order.orderFor == 'seller' ? 'Seller' : 'Buyer';
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
        actions: [],
      ),
      body: SafeArea(
        child: FutureBuilder<BillDetailsData>(
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
                          color:
                              theme.colorScheme.error.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: theme.colorScheme.error.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Failed to load bill',
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
            final currency =
                NumberFormat.currency(locale: 'en_IN', symbol: '₹');
            final createdAt = DateTime.fromMillisecondsSinceEpoch(
                data.order.updatedAt ?? DateTime.now().millisecondsSinceEpoch);

            return Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 360),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withValues(alpha: 0.05),
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
                            if (_mandiName.isNotEmpty) ...[
                              Center(
                                child: Text(
                                  _mandiName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Center(
                              child: Text(
                                '#${data.order.id ?? '-'}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            ReceiptInfo(
                                data: data, createdAt: createdAt, theme: theme),
                            const SizedBox(height: 12),
                            const Divider(thickness: 1),
                            ReceiptItems(
                                data: data, currency: currency, theme: theme),
                            const Divider(thickness: 1),
                            ReceiptSummary(
                                data: data, currency: currency, theme: theme),
                            const Divider(thickness: 1),
                            ReceiptPayment(
                                data: data, currency: currency, theme: theme),
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
                    const SizedBox(height: 16),
                    if (!_isCustomer)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Print Bill'),
                                  content: const Text(
                                      'Do you really want to print this bill?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
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
                                _handlePrint(data);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.print_outlined,
                                    size: 18,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Print Bill',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (data.pendingPayment > 0) ...[
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => _showReceivePaymentSheet(data),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Pay Due Amount',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
