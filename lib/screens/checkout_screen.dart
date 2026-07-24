import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/charge_types/charge_types_bloc.dart';
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

  final _orderChargeDAO = OrderChargeDAO();
  final _orderExpenseDAO = OrderExpenseDao();
  final _orderPaymentDAO = OrderPaymentDAO();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChargeTypesBloc>().add(LoadChargeTypes());
      }
    });
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
          createdAt: now,
          orderFor: widget.orderFor,
          status: 'completed',
        );
        orderId = await OrderDAO().insertOrder(order);

        for (final item in widget.cartItems ?? []) {
          final linkedItem = item.copyWith(
            id: DBHelper.generateUuidInt(),
            buyerOrderId: widget.orderFor == 'buyer' ? orderId : null,
            sellerOrderId: widget.orderFor == 'seller' ? orderId : null,
          );
          await OrderDAO().insertOrderItem(linkedItem);
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

      if (widget.orderId != null) {
        await OrderDAO().updateOrderStatus(orderId, 'completed');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Order placed successfully'),
          ),
        );
        Navigator.pop(context, orderId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Failed to place order: $e'),
          ),
        );
        setState(() => _isPlacingOrder = false);
      }
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
            title: MyText.titleMedium('Checkout'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
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
