import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/order/order_bloc.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/widgets/checkout/payment_method_selector.dart' as pms;
import 'package:mandyapp/models/order_model.dart';
import 'package:mandyapp/blocs/charge_types/charge_types_bloc.dart';

class PaymentSection extends StatefulWidget {
  final Order order;
  final Set<int> selectedChargeIds;
  final Map<int, TextEditingController> chargeControllers;
  final Set<pms.PaymentMethod> selectedPaymentMethods;
  final Map<pms.PaymentMethod, double> paymentAmounts;
  final Function(Set<pms.PaymentMethod>, Map<pms.PaymentMethod, double>) onPaymentMethodChanged;
  final Function() onSchedulePersistCheckout;

  const PaymentSection({
    Key? key,
    required this.order,
    required this.selectedChargeIds,
    required this.chargeControllers,
    required this.selectedPaymentMethods,
    required this.paymentAmounts,
    required this.onPaymentMethodChanged,
    required this.onSchedulePersistCheckout,
  }) : super(key: key);

  @override
  State<PaymentSection> createState() => _PaymentSectionState();
}

class _PaymentSectionState extends State<PaymentSection> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChargeTypesBloc, ChargeTypesState>(
      builder: (context, chargesState) {
        double subtotal = widget.order.totalPrice;
        double chargesTotal = 0.0;

        if (chargesState is ChargeTypesLoaded) {
          // Get order information to filter charges by type
          final orderState = context.read<OrderBloc>().state;
          if (orderState is OrdersLoaded) {
            final order = orderState.orders.first;

            // Calculate total from edited charge amounts for selected charges only, filtered by order type
            for (var charge in chargesState.chargeTypes) {
              if (charge.isActive == 1 && 
                  charge.chargeFor == order.orderFor && 
                  widget.selectedChargeIds.contains(charge.id) && 
                  widget.chargeControllers.containsKey(charge.id)) {
                final editedAmount = double.tryParse(widget.chargeControllers[charge.id!]!.text) ?? charge.chargeAmount;
                chargesTotal += editedAmount;
              }
            }
          }
        }

        double grandTotal = widget.order.orderFor == 'seller'
            ? subtotal - chargesTotal
            : subtotal + chargesTotal;

        // Calculate received amount from payment methods
        double receivedAmount = widget.paymentAmounts.values.fold(0.0, (sum, amount) => sum + amount);
        double pendingAmount = grandTotal - receivedAmount;

        // Calculate paymentAmount and pendingPayment based on order type
        double paymentAmount, pendingPayment;
        if (widget.order.orderFor == 'seller') {
          // For seller orders: paymentAmount is the amount to be paid to seller
          paymentAmount = grandTotal;
          // pendingPayment is the amount still owed to seller
          pendingPayment = paymentAmount - receivedAmount;
        } else {
          // For buyer orders: paymentAmount is the amount received
          paymentAmount = receivedAmount;
          // pendingPayment is the remaining amount to be paid
          pendingPayment = pendingAmount;
        }

        return Container(
          padding: MySpacing.all(0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: MyText.bodySmall('Summary', fontWeight: 600),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: MyText.bodySmall('Amount', fontWeight: 600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _summaryRow('Item Totals', subtotal, context),
                    _summaryRow('Charge Total', chargesTotal, context),
                    _summaryRow('Grand Total', grandTotal, context, emphasized: true),
                    _summaryRow(
                      widget.order.orderFor == 'seller' ? 'Amount Owed' : 'Payment Amount',
                      paymentAmount,
                      context,
                      valueColor: Colors.blue,
                    ),
                    _summaryRow(
                      widget.order.orderFor == 'seller' ? 'Amount Received' : 'Received Amount',
                      receivedAmount,
                      context,
                      valueColor: Colors.green,
                    ),
                    _summaryRow(
                      widget.order.orderFor == 'seller' 
                          ? 'Amount Pending' 
                          : (pendingPayment >= 0 ? 'Pending Payment' : 'Payment Due'),
                      pendingPayment.abs(),
                      context,
                      valueColor: pendingPayment > 0 ? Colors.orange : Colors.green,
                    ),
                  ],
                ),
              ),
              MySpacing.height(16),
              pms.PaymentMethodSelector(
                selectedPaymentMethods: widget.selectedPaymentMethods,
                paymentAmounts: widget.paymentAmounts,
                orderFor: widget.order.orderFor,
                onSelectionChanged: (selectedMethods, paymentAmounts) {
                  widget.onPaymentMethodChanged(selectedMethods, paymentAmounts);
                  widget.onSchedulePersistCheckout();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryRow(String label, double amount, BuildContext context, {bool emphasized = false, Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.08)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: MyText.bodyMedium(
              label,
              fontWeight: emphasized ? 700 : 600,
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: MyText.bodyMedium(
                '₹${amount.toStringAsFixed(2)}',
                fontWeight: emphasized ? 700 : 600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
