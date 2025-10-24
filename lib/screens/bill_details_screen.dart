import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mandyapp/dao/cart_charge_dao.dart';
import 'package:mandyapp/dao/cart_dao.dart';
import 'package:mandyapp/dao/cart_payment_dao.dart';
import 'package:mandyapp/dao/product_dao.dart';
import 'package:mandyapp/dao/product_variant_dao.dart';
import 'package:mandyapp/dao/customer_dao.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/cart_charge_model.dart';
import 'package:mandyapp/models/cart_model.dart';
import 'package:mandyapp/models/cart_payment_model.dart';
import 'package:mandyapp/models/item_sale_model.dart';
import 'package:mandyapp/models/product_model.dart';
import 'package:mandyapp/models/product_variant_model.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/screens/checkout_screen.dart';
import 'package:mandyapp/utils/printer/printer_service.dart' as printer_service;

class BillDetailsScreen extends StatefulWidget {
  final int cartId;

  const BillDetailsScreen({super.key, required this.cartId});

  @override
  State<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class InvoiceItem {
  final String productName;
  final double quantity;
  final String unit;
  final double price;
  final double total;

  const InvoiceItem({
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.total,
  });
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
          cartId: data.cart.id,
          initialCartCharges: data.charges,
          initialPayment: data.payment,
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
      cartId: data.cart.id,
      customerName: data.customerName,
      cartType: data.cart.cartFor,
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
    final cartDAO = CartDAO();
    final cartPaymentDAO = CartPaymentDAO();
    final cartChargeDAO = CartChargeDAO();
    final productDAO = ProductDAO();
    final productVariantDAO = ProductVariantDAO();
    final customerDAO = CustomerDAO();

    final cart = await cartDAO.getCartWithItems(widget.cartId);
    if (cart == null) {
      throw StateError('Cart not found');
    }

    final items = cart.items ?? await cartDAO.getCartItems(cart.id, cartFor: cart.cartFor);
    final payment = await cartPaymentDAO.getCartPaymentByCartId(cart.id);
    final charges = await cartChargeDAO.getCartCharges(cart.id.toString());
    final customers = await customerDAO.getCustomers();
    final Map<int, Customer> customerById = {
      for (final customer in customers)
        if (customer.id != null) customer.id!: customer,
    };

    final List<_BillLineItem> lineItems = [];
    for (final item in items) {
      final product = await productDAO.getProductById(item.productId);
      final variant = await productVariantDAO.getVariantById(item.variantId);
      lineItems.add(
        _BillLineItem(
          sale: item,
          product: product,
          variant: variant,
          seller: customerById[item.sellerId],
        ),
      );
    }

    return _BillDetailsData(
      cart: cart,
      payment: payment,
      lineItems: lineItems,
      charges: charges,
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
        title: MyText.titleMedium('Invoice #${widget.cartId}', fontWeight: 600),
      ),
      body: FutureBuilder<_BillDetailsData>(
        future: _billFuture,
        builder: (context, snapshot) {
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
          final createdAt = DateTime.tryParse(data.cart.createdAt) ?? DateTime.now();

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
                            MyText.titleMedium('Invoice', fontWeight: 700),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                MyText.bodySmall('Invoice ID:', color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                const SizedBox(width: 6),
                                MyText.bodySmall('#${data.cart.id}', fontWeight: 600),
                                const SizedBox(width: 20),
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
                                      'Payment',
                                      data.paymentMethodLabel,
                                      theme,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: _buildInfoMetric(
                                      data.cart.cartFor == 'seller' ? 'Amount Received' : 'Received Amount',
                                      currency.format(data.receivedAmount),
                                      theme,
                                      valueColor: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: _buildInfoMetric(
                                      data.cart.cartFor == 'seller' ? 'Amount Pending' : 'Pending Amount',
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
                const SizedBox(height: 24),
                _buildActionButtons(theme, data),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, _BillDetailsData data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 140,
          child: _ActionButton(
            icon: Icons.edit,
            label: 'Edit',
            color: theme.colorScheme.primary,
            onPressed: () => _handleEdit(data),
          ),
        ),
        SizedBox(
          width: 140,
          child: _ActionButton(
            icon: Icons.print,
            label: 'Print',
            color: Colors.orange,
            onPressed: () => _handlePrint(data),
          ),
        ),
      ],
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: MyText.bodySmall('Product', fontWeight: 600)),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: MyText.bodySmall('Qty', fontWeight: 600),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: MyText.bodySmall('Rate', fontWeight: 600),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: MyText.bodySmall('Total', fontWeight: 600),
                  ),
                ),
              ],
            ),
          ),
          for (final item in data.lineItems)...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText.bodyMedium(item.productName, fontWeight: 600),
                        const SizedBox(height: 2),
                        MyText.bodySmall(
                          item.sellerLabel,
                          color: theme.colorScheme.onSurface.withOpacity(0.65),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: MyText.bodyMedium('${item.quantityLabel} ${item.unitLabel}'),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: MyText.bodyMedium(currency.format(item.sellingPrice)),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: MyText.bodyMedium(currency.format(item.totalPrice)),
                    ),
                  ),
                ],
              ),
            ),
            if (item != data.lineItems.last)
              Divider(height: 1, thickness: 0.5, color: theme.colorScheme.onSurface.withOpacity(0.05)),
          ],
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

  Widget _buildSummarySection(_BillDetailsData data, NumberFormat currency, ThemeData theme) {
    final rows = <MapEntry<String, String>>[
      MapEntry('Item Total', currency.format(data.itemTotal)),
      if (data.chargesTotal > 0) MapEntry('Charge Total', currency.format(data.chargesTotal)),
      MapEntry('Grand Total', currency.format(data.grandTotal)),
      MapEntry(
        data.cart.cartFor == 'seller' ? 'Amount Received' : 'Received Amount',
        currency.format(data.receivedAmount),
      ),
      MapEntry(
        data.cart.cartFor == 'seller' ? 'Amount Pending' : 'Pending Amount',
        currency.format(data.outstandingAmount.abs()),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          MyText.bodySmall(
            label,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          const Spacer(),
          MyText.bodyMedium(
            value,
            fontWeight: 600,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _BillDetailsData {
  final Cart cart;
  final CartPayment? payment;
  final List<_BillLineItem> lineItems;
  final List<CartCharge> charges;
  final Map<int, Customer> customerById;

  const _BillDetailsData({
    required this.cart,
    required this.payment,
    required this.lineItems,
    required this.charges,
    required this.customerById,
  });

  String get customerName {
    final customer = customerById[cart.customerId];
    return customer?.name?.trim().isNotEmpty ?? false
        ? customer!.name!.trim()
        : 'Customer ${cart.customerId}';
  }

  String get invoiceLabel => 'Invoice #${cart.id}';

  double get itemTotal {
    return lineItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get chargesTotal {
    return charges.fold(0.0, (sum, charge) => sum + charge.chargeAmount);
  }

  double get grandTotal {
    if (cart.cartFor == 'seller') {
      return itemTotal - chargesTotal;
    } else {
      // For buyer carts, use current implementation (subtotal + chargesTotal)
      return itemTotal + chargesTotal;
    }
  }

  double get receivedAmount => payment?.receiveAmount ?? 0.0;

  double get outstandingAmount => grandTotal - receivedAmount;

  // Calculate paymentAmount and pendingPayment based on cart type
  double get paymentAmount {
    if (cart.cartFor == 'seller') {
      // For seller carts, paymentAmount is the amount to be paid to seller (after deducting charges)
      return grandTotal;
    } else {
      // For buyer carts, paymentAmount is the total amount received
      return receivedAmount;
    }
  }

  double get pendingPayment {
    if (cart.cartFor == 'seller') {
      // For seller carts, pendingPayment is the amount still owed to seller
      return paymentAmount - receivedAmount;
    } else {
      // For buyer carts, pendingPayment is the remaining amount to be paid
      return outstandingAmount;
    }
  }

  String get paymentMethodLabel {
    if (payment == null) {
      return 'Not recorded';
    }
    final methods = <String>[];
    if (payment!.cashPayment) {
      methods.add('Cash');
    }
    if (payment!.upiPayment) {
      methods.add('UPI');
    }
    if (payment!.cardPayment) {
      methods.add('Card');
    }
    if (payment!.creditPayment) {
      methods.add('Credit');
    }
    if (methods.isEmpty) {
      return 'Not recorded';
    }
    return methods.join(', ');
  }
}

class _BillLineItem {
  final ItemSale sale;
  final Product? product;
  final ProductVariant? variant;
  final Customer? seller;

  const _BillLineItem({
    required this.sale,
    required this.product,
    required this.variant,
    required this.seller,
  });

  String get productName {
    final variantName = variant?.variantName.trim();
    if (variantName != null && variantName.isNotEmpty) {
      return variantName;
    }

    final baseName = product?.defaultVariantModel?.variantName.trim();
    if (baseName != null && baseName.isNotEmpty) {
      return baseName;
    }

    return 'Unknown Item';
  }

  String? get variantLabel {
    if (variant == null) return null;
    final variantName = variant!.variantName.trim();
    if (variantName.isNotEmpty && variantName != productName) {
      return variantName;
    }
    return '${variant!.quantity.toStringAsFixed(0)} ${variant!.unit}';
  }

  String get quantityLabel {
    final qty = sale.quantity;
    if (qty % 1 == 0) {
      return qty.toStringAsFixed(0);
    }
    return qty.toStringAsFixed(2);
  }

  double get sellingPrice => sale.sellingPrice;

  double get totalPrice => sale.totalPrice;

  String get unitLabel {
    final saleUnit = sale.unit.trim();
    if (saleUnit.isNotEmpty) {
      return saleUnit;
    }
    final variantUnit = variant?.unit.trim();
    if (variantUnit != null && variantUnit.isNotEmpty) {
      return variantUnit;
    }
    return '';
  }

  String get sellerLabel {
    final sellerName = seller?.name?.trim();
    if (sellerName != null && sellerName.isNotEmpty) {
      return sellerName;
    }
    return 'Seller #${sale.sellerId}';
  }
}
