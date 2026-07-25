import 'package:flutter/material.dart';
import 'package:mandyapp/helpers/utils/info_controller.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/charge_types/charge_types_bloc.dart';
import 'package:mandyapp/dao/customer_dao.dart';
import 'package:mandyapp/dao/order_charge_dao.dart';
import 'package:mandyapp/dao/order_dao.dart';
import 'package:mandyapp/dao/order_expense_dao.dart';
import 'package:mandyapp/dao/order_payment_dao.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/charge_type_model.dart';
import 'package:mandyapp/models/order_charge_model.dart';
import 'package:mandyapp/models/order_expense_model.dart';
import 'package:mandyapp/models/order_item_model.dart';
import 'package:mandyapp/models/order_model.dart';
import 'package:mandyapp/models/order_payment_model.dart';
import 'package:mandyapp/utils/db_helper.dart';
import 'package:mandyapp/utils/printer/printer_service.dart';
import 'package:mandyapp/dao/customer_payment_dao.dart';
import 'package:mandyapp/models/customer_payment_model.dart';
import 'package:mandyapp/widgets/checkout/checkout_content.dart';
import 'package:mandyapp/widgets/checkout/payment_method_selector.dart';

class CheckoutScreen extends StatefulWidget {
  final List<OrderItem>? cartItems;
  final int? customerId;
  final int? orderId;
  final String orderFor;

  const CheckoutScreen({
    super.key,
    this.cartItems,
    this.customerId,
    this.orderId,
    required this.orderFor,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final Set<int> _selectedChargeIds = {};
  final List<Map<String, dynamic>> _expenses = [];
  Map<PaymentMethod, double> _paymentAmounts = {};
  bool _defaultChargesInitialized = false;
  bool _isPlacingOrder = false;
  bool _autoPrint = true;
  String? _customerName;

  final _orderChargeDAO = OrderChargeDAO();
  final _orderExpenseDAO = OrderExpenseDao();
  final _orderPaymentDAO = OrderPaymentDAO();

  @override
  void initState() {
    super.initState();
    _loadCustomerName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChargeTypesBloc>().add(LoadChargeTypes());
      }
    });
  }

  Future<void> _loadCustomerName() async {
    if (widget.customerId == null) return;
    final customer = await CustomerDAO().getCustomerById(widget.customerId!);
    if (mounted) {
      setState(() {
        _customerName = customer?.name;
      });
    }
  }

  void _initDefaultCharges(List<ChargeType> charges) {
    if (_defaultChargesInitialized) return;
    _defaultChargesInitialized = true;
    for (final charge in charges) {
      if (charge.isDefault == 1 &&
          charge.id != null &&
          charge.isActive == 1 &&
          charge.chargeFor == widget.orderFor) {
        _selectedChargeIds.add(charge.id!);
      }
    }
  }

  double _computeChargesTotal(List<ChargeType> charges) {
    double total = 0.0;
    for (final charge in charges) {
      if (charge.isActive == 1 &&
          charge.chargeFor == widget.orderFor &&
          charge.id != null &&
          _selectedChargeIds.contains(charge.id)) {
        total += charge.chargeAmount;
      }
    }
    return total;
  }

  double _computeExpensesTotal() {
    double total = 0.0;
    for (final expense in _expenses) {
      total += (expense['amount'] as double?) ?? 0.0;
    }
    return total;
  }

  String _paymentMethodToSource(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.upi:
        return 'upi';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.credit:
        return 'credit';
    }
  }

  Future<void> _placeOrder(List<ChargeType> chargeTypes) async {
    if (_isPlacingOrder) return;
    setState(() => _isPlacingOrder = true);

    try {
      final now = DateTime.now().toIso8601String();
      int orderId;

      if (widget.orderId != null) {
        orderId = widget.orderId!;
      } else {
        final order = Order(
          customerId: widget.customerId ?? 0,
          orderFor: widget.orderFor,
        );
        orderId = await OrderDAO().insertOrder(order);

        for (final item in widget.cartItems ?? []) {
          final linkedItem = item.copyWith(
            buyerOrderId: widget.orderFor == 'buyer' ? orderId : null,
            sellerOrderId: widget.orderFor == 'seller' ? orderId : null,
          );
          await OrderDAO().updateOrderItem(linkedItem);
        }
      }

      final selectedCharges = <OrderCharge>[];
      for (final charge in chargeTypes) {
        if (charge.isActive == 1 &&
            charge.chargeFor == widget.orderFor &&
            charge.id != null &&
            _selectedChargeIds.contains(charge.id)) {
          selectedCharges.add(OrderCharge(
            orderId: orderId.toString(),
            chargeName: charge.chargeName,
            chargeAmount: charge.chargeAmount,
          ));
        }
      }
      if (selectedCharges.isNotEmpty) {
        await _orderChargeDAO.bulkInsertForOrder(orderId.toString(), selectedCharges);
      }

      for (final expense in _expenses) {
        final amount = (expense['amount'] as double?) ?? 0.0;
        final description = (expense['description'] as String?) ?? '';
        if (amount > 0) {
          await _orderExpenseDAO.insert(OrderExpense(
            expenseName: description,
            expenseAmount: amount,
            orderId: orderId,
            updatedAt: now,
          ));
        }
      }

      final subtotal = widget.cartItems?.fold<double>(
            0.0,
            (sum, item) => sum + item.sellingPrice * item.quantity,
          ) ??
          0.0;
      final chargesTotal = _computeChargesTotal(chargeTypes);
      final expensesTotal = _computeExpensesTotal();
      final grandTotal = widget.orderFor == 'seller'
          ? subtotal + chargesTotal - expensesTotal
          : subtotal + chargesTotal + expensesTotal;

      final paymentAmountsToSave = Map<PaymentMethod, double>.from(_paymentAmounts);
      if (paymentAmountsToSave.isEmpty || paymentAmountsToSave.values.every((a) => a <= 0)) {
        paymentAmountsToSave[PaymentMethod.cash] = grandTotal;
      }

      for (final entry in paymentAmountsToSave.entries) {
        if (entry.value > 0) {
          await _orderPaymentDAO.insertOrderPayment(OrderPayment(
            id: DBHelper.generateUuidInt(),
            orderId: orderId,
            source: _paymentMethodToSource(entry.key),
            amount: entry.value,
            updatedAt: now,
          ));
        }
      }

      final transactionType = widget.orderFor == 'buyer' ? 'received' : 'paid';
      final totalReceived = paymentAmountsToSave.entries.fold<double>(0.0, (sum, e) => sum + e.value);
      if (widget.customerId != null && totalReceived > 0) {
        final source = paymentAmountsToSave.entries
            .where((e) => e.value > 0)
            .map((e) => _paymentMethodToSource(e.key))
            .first;
        await CustomerPaymentDAO().insertPayment(CustomerPayment(
          customerId: widget.customerId!,
          amount: totalReceived,
          type: transactionType,
          source: source,
          note: 'Bill #$orderId',
          paymentDate: DateTime.now().millisecondsSinceEpoch,
        ));
      }

      if (_autoPrint) {
        _printBill(orderId, chargeTypes);
      }

      if (mounted) {
        Info.message('Order placed successfully', context: context);
        Navigator.pop(context, orderId);
      }
    } catch (e) {
      if (mounted) {
        Info.error('Failed to place order: $e', context: context);
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  void _printBill(int orderId, List<ChargeType> chargeTypes) async {
    final printerService = PrinterService.instance;

    if (!printerService.connectionStatus.value) return;

    final subtotal = widget.cartItems?.fold<double>(
          0.0,
          (sum, item) => sum + item.sellingPrice * item.quantity,
        ) ??
        0.0;
    final chargesTotal = _computeChargesTotal(chargeTypes);
    final expensesTotal = _computeExpensesTotal();
    final grandTotal = widget.orderFor == 'seller'
        ? subtotal + chargesTotal - expensesTotal
        : subtotal + chargesTotal + expensesTotal;

    final receivedAmount = _paymentAmounts.values.fold<double>(0.0, (a, b) => a + b);
    final pendingAmount = grandTotal - receivedAmount;

    final paymentMethods = _paymentAmounts.entries
        .where((e) => e.value > 0)
        .map((e) => _paymentMethodToLabel(e.key))
        .join(', ');

    final items = (widget.cartItems ?? []).map((item) => InvoiceItem(
      productName: item.productName ?? 'Unknown',
      quantity: item.quantity.toDouble(),
      unit: 'pc',
      price: item.sellingPrice,
      total: item.sellingPrice * item.quantity,
    )).toList();

    await printerService.printInvoice(
      cartId: orderId,
      customerName: _customerName ?? '',
      cartType: widget.orderFor,
      items: items,
      itemTotal: subtotal,
      chargesTotal: chargesTotal,
      expensesTotal: expensesTotal,
      grandTotal: grandTotal,
      receivedAmount: receivedAmount,
      pendingAmount: pendingAmount,
      paymentMethod: paymentMethods,
    );
  }

  String _paymentMethodToLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.credit:
        return 'Credit';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChargeTypesBloc, ChargeTypesState>(
      builder: (context, chargesState) {
        final List<ChargeType> chargeTypes =
            chargesState is ChargeTypesLoaded ? chargesState.chargeTypes : [];

        _initDefaultCharges(chargeTypes);

        final subtotal = widget.cartItems?.fold<double>(
              0.0,
              (sum, item) => sum + item.sellingPrice * item.quantity,
            ) ??
            0.0;

        final chargesTotal = _computeChargesTotal(chargeTypes);
        final expensesTotal = _computeExpensesTotal();

        return Scaffold(
          appBar: AppBar(
            title: MyText.titleMedium(
              '${widget.orderFor == 'seller' ? 'Seller' : 'Buyer'} billing for ${_customerName ?? ''}',
            ),
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Tooltip(
                  message: _autoPrint ? 'Auto-print ON' : 'Auto-print OFF',
                  child: GestureDetector(
                    onTap: () => setState(() => _autoPrint = !_autoPrint),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _autoPrint
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.print,
                            size: 16,
                            color: _autoPrint
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _autoPrint ? 'Print' : 'No Print',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _autoPrint
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isPlacingOrder
                      ? null
                      : () => _placeOrder(chargeTypes),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isPlacingOrder
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : MyText.bodyLarge(
                          widget.orderFor == 'seller'
                              ? 'Confirm Payment'
                              : 'Place Order',
                          fontWeight: 600,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ),
          body: CheckoutContent(
            cartItems: widget.cartItems,
            customerId: widget.customerId?.toString(),
            orderFor: widget.orderFor,
            chargesState: chargesState,
            selectedChargeIds: _selectedChargeIds,
            expenses: _expenses,
            subtotal: subtotal,
            chargesTotal: chargesTotal,
            expensesTotal: expensesTotal,
            onChargesSelectionChanged: (ids) {
              setState(() {
                _selectedChargeIds
                  ..clear()
                  ..addAll(ids);
              });
            },
            onExpensesChanged: (expenses) {
              setState(() {
                _expenses
                  ..clear()
                  ..addAll(expenses);
              });
            },
            onPaymentChanged: (amounts) {
              setState(() {
                _paymentAmounts = amounts;
              });
            },
          ),
        );
      },
    );
  }
}
