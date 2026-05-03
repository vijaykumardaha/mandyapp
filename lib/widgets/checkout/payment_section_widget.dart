import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/charge_types/charge_types_bloc.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/order_model.dart';
import 'package:mandyapp/widgets/checkout/payment_method_selector.dart';

class PaymentSectionWidget extends StatefulWidget {
  final Order order;
  final String orderFor;

  const PaymentSectionWidget({
    super.key,
    required this.order,
    required this.orderFor,
  });

  @override
  State<PaymentSectionWidget> createState() => _PaymentSectionWidgetState();
}

class _PaymentSectionWidgetState extends State<PaymentSectionWidget> {
  Set<PaymentMethod> _selectedPaymentMethods = {PaymentMethod.cash};
  Map<PaymentMethod, double> _paymentAmounts = {};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChargeTypesBloc, ChargeTypesState>(
      builder: (context, chargesState) {
        double subtotal = widget.order.totalPrice;
        double chargesTotal = 0.0;

        if (chargesState is ChargeTypesLoaded) {
          // Calculate total from edited charge amounts for selected charges only, filtered by order type
          for (var charge in chargesState.chargeTypes) {
            if (charge.isActive == 1 &&
                charge.chargeFor == widget.orderFor &&
                charge.id != null) {
              final amount = double.tryParse(charge.chargeAmount.toString()) ?? 0.0;
              chargesTotal += amount;
            }
          }
        }

        double grandTotal = widget.order.orderFor == 'seller'
            ? subtotal - chargesTotal
            : subtotal + chargesTotal;

        return PaymentMethodSelector(
          selectedPaymentMethods: _selectedPaymentMethods,
          paymentAmounts: _paymentAmounts,
          orderFor: widget.orderFor,
          subtotal: subtotal,
          chargesTotal: chargesTotal,
          grandTotal: grandTotal,
          onSelectionChanged: (selectedMethods, paymentAmounts) {
            setState(() {
              _selectedPaymentMethods = selectedMethods;
              _paymentAmounts = paymentAmounts;
            });
          },
        );
      },
    );
  }
}
