import 'package:flutter/material.dart';
import 'package:mandyapp/blocs/charge_types/charge_types_bloc.dart';
import 'package:mandyapp/widgets/common/my_spacing.dart';
import 'package:mandyapp/widgets/common/my_text.dart';
import 'package:mandyapp/models/order_item_model.dart';
import 'package:mandyapp/widgets/checkout/empty_cart.dart';
import 'package:mandyapp/widgets/checkout/charges_section_widget.dart';
import 'package:mandyapp/widgets/checkout/expense_section_widget.dart';
import 'package:mandyapp/widgets/checkout/payment_method_selector.dart';
import 'package:mandyapp/widgets/checkout/payment_section_widget.dart';

class CheckoutContent extends StatefulWidget {
  final List<OrderItem>? cartItems;
  final String? customerId;
  final String orderFor;
  final ChargeTypesState chargesState;
  final Set<int> selectedChargeIds;
  final List<Map<String, dynamic>> expenses;
  final double subtotal;
  final double chargesTotal;
  final double expensesTotal;
  final Function(Set<int>) onChargesSelectionChanged;
  final Function(List<Map<String, dynamic>>) onExpensesChanged;
  final Function(Map<PaymentMethod, double>) onPaymentChanged;

  const CheckoutContent({
    super.key,
    this.cartItems,
    this.customerId,
    required this.orderFor,
    required this.chargesState,
    required this.selectedChargeIds,
    required this.expenses,
    required this.subtotal,
    required this.chargesTotal,
    required this.expensesTotal,
    required this.onChargesSelectionChanged,
    required this.onExpensesChanged,
    required this.onPaymentChanged,
  });

  @override
  State<CheckoutContent> createState() => _CheckoutContentState();
}

class _CheckoutContentState extends State<CheckoutContent> {
  @override
  Widget build(BuildContext context) {
    if (widget.cartItems == null || widget.cartItems!.isEmpty) {
      return const EmptyCart();
    }

    for (final item in widget.cartItems!) {
      if (item.sellingPrice < 0 || item.quantity < 0) {
        return const Center(
          child: Text('Some items have invalid prices or quantities'),
        );
      }
    }

    return ListView(
      key: const PageStorageKey('checkout_list'),
      padding: MySpacing.all(16),
      children: [
        _buildCartItemsSection(context),
        ChargesSectionWidget(
          orderFor: widget.orderFor,
          selectedChargeIds: widget.selectedChargeIds,
          chargesState: widget.chargesState,
          subtotal: widget.subtotal,
          onSelectionChanged: widget.onChargesSelectionChanged,
        ),
        ExpenseSectionWidget(
          orderFor: widget.orderFor,
          expenses: widget.expenses,
          onExpensesChanged: widget.onExpensesChanged,
        ),
        PaymentSectionWidget(
          orderFor: widget.orderFor,
          subtotal: widget.subtotal,
          chargesTotal: widget.chargesTotal,
          expensesTotal: widget.expensesTotal,
          onPaymentChanged: widget.onPaymentChanged,
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildCartItemsSection(BuildContext context) {
    return Container(
      margin: MySpacing.bottom(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: MySpacing.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText.bodyMedium('Your Order Items', fontWeight: 600),
                MySpacing.height(2),
                MyText.bodySmall(
                  'Products you are purchasing',
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ),
          MySpacing.height(12),
          ...?widget.cartItems?.map((item) {
            return Container(
              margin: MySpacing.only(left: 12, bottom: 8),
              padding: MySpacing.bottom(8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText.bodyMedium(
                          item.productName ?? 'Product #${item.productId}',
                          fontWeight: 500,
                        ),
                        MySpacing.height(4),
                        MyText.bodySmall(
                          '${item.quantity} × ₹${item.sellingPrice.toStringAsFixed(2)} each',
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                  MyText.bodyMedium(
                    '₹${(item.quantity * item.sellingPrice).toStringAsFixed(2)}',
                    fontWeight: 600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
