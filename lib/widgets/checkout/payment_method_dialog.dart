import 'package:flutter/material.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/widgets/checkout/payment_method_selector.dart' as pms;

class PaymentMethodDialog extends StatelessWidget {
  final Set<pms.PaymentMethod> selectedPaymentMethods;
  final Map<pms.PaymentMethod, double> paymentAmounts;
  final String orderFor;
  final Function(Set<pms.PaymentMethod>, Map<pms.PaymentMethod, double>) onSelectionChanged;
  final Function() onPayNow;

  const PaymentMethodDialog({
    Key? key,
    required this.selectedPaymentMethods,
    required this.paymentAmounts,
    required this.orderFor,
    required this.onSelectionChanged,
    required this.onPayNow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Content
            pms.PaymentMethodSelector(
              selectedPaymentMethods: selectedPaymentMethods,
              paymentAmounts: paymentAmounts,
              orderFor: orderFor,
              onSelectionChanged: (selectedMethods, paymentAmounts) {
                onSelectionChanged(selectedMethods, paymentAmounts);
              },
            ),

            // Footer with Record Payment button
            Container(
              padding: MySpacing.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    onPayNow();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: MyText.bodyLarge('Record Payment', fontWeight: 600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
