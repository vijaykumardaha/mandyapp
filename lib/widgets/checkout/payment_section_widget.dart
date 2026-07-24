import 'package:flutter/material.dart';
import 'package:mandyapp/widgets/checkout/payment_method_selector.dart';

class PaymentSectionWidget extends StatefulWidget {
  final String orderFor;
  final double subtotal;
  final double chargesTotal;
  final double expensesTotal;
  final Function(Map<PaymentMethod, double>) onPaymentChanged;

  const PaymentSectionWidget({
    super.key,
    required this.orderFor,
    required this.subtotal,
    required this.chargesTotal,
    required this.expensesTotal,
    required this.onPaymentChanged,
  });

  @override
  State<PaymentSectionWidget> createState() => _PaymentSectionWidgetState();
}

class _PaymentSectionWidgetState extends State<PaymentSectionWidget> {
  Set<PaymentMethod> _selectedPaymentMethods = {PaymentMethod.cash};
  Map<PaymentMethod, double> _paymentAmounts = {};

  @override
  Widget build(BuildContext context) {
    final grandTotal = widget.orderFor == 'seller'
        ? widget.subtotal + widget.chargesTotal - widget.expensesTotal
        : widget.subtotal + widget.chargesTotal + widget.expensesTotal;

    return PaymentMethodSelector(
      selectedPaymentMethods: _selectedPaymentMethods,
      paymentAmounts: _paymentAmounts,
      orderFor: widget.orderFor,
      subtotal: widget.subtotal,
      chargesTotal: widget.chargesTotal,
      expensesTotal: widget.expensesTotal,
      grandTotal: grandTotal,
      onSelectionChanged: (selectedMethods, paymentAmounts) {
        setState(() {
          _selectedPaymentMethods = selectedMethods;
          _paymentAmounts = paymentAmounts;
        });
        widget.onPaymentChanged(paymentAmounts);
      },
    );
  }
}
