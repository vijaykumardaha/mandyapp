import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/charge_types/charge_types_bloc.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/order_item_model.dart';
import 'package:mandyapp/models/order_model.dart';
import 'package:mandyapp/widgets/checkout/empty_cart.dart';
import 'package:mandyapp/widgets/checkout/charges_section_widget.dart';
import 'package:mandyapp/widgets/checkout/expense_section_widget.dart';
import 'package:mandyapp/widgets/checkout/payment_section_widget.dart';

class CheckoutContent extends StatefulWidget {
  final List<OrderItem>? cartItems;
  final String? customerId;
  final String orderFor;

  const CheckoutContent({
    super.key,
    this.cartItems,
    this.customerId,
    required this.orderFor,
  });

  @override
  State<CheckoutContent> createState() => _CheckoutContentState();
}

class _CheckoutContentState extends State<CheckoutContent> {
  @override
  void initState() {
    super.initState();
    // Initialize ChargeTypesBloc after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ChargeTypesBloc>().add(LoadChargeTypes());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Validate cart items
    if (widget.cartItems == null || widget.cartItems!.isEmpty) {
      return const EmptyCart();
    }
    
    // Ensure all cart items have valid required fields
    for (final item in widget.cartItems!) {
      if (item.sellingPrice < 0 || item.quantity < 0) {
        return const Center(
          child: Text('Invalid cart items detected'),
        );
      }
    }

    // Create a mock order for display purposes
    final order = Order(
      id: 0, // Temporary ID
      customerId: int.tryParse(widget.customerId ?? '0') ?? 0,
      createdAt: DateTime.now().toIso8601String(),
      status: 'pending',
      orderFor: widget.orderFor == 'seller' ? 'seller' : 'buyer', // Ensure valid orderFor value
      items: widget.cartItems ?? [], // Ensure items is never null
    );

    return ListView(
      padding: MySpacing.all(16),
      children: [
        // Cart Items Section
        _buildCartItemsSection(order),

        // Charges Section
        ChargesSectionWidget(
          order: order,
          orderFor: widget.orderFor,
        ),

        // Expense Section
        ExpenseSectionWidget(
          order: order,
          orderFor: widget.orderFor,
        ),

        // Payment Section (scrollable)
        PaymentSectionWidget(
          order: order,
          orderFor: widget.orderFor,
        ),

        // Add bottom padding to account for sticky button
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildCartItemsSection(Order order) {
    return Container(
      margin: MySpacing.bottom(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.bodyLarge('Cart Items', fontWeight: 600),
          MySpacing.height(12),
          ...?order.items?.asMap().entries.map((entry) {
            // final index = entry.key;
            final item = entry.value;
            return Container(
              margin: MySpacing.bottom(8),
              padding: MySpacing.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText.bodyMedium(
                          _productTitleForSale(item),
                          fontWeight: 500,
                        ),
                        MySpacing.height(4),
                        MyText.bodySmall(
                          'Qty: ${item.quantity} × ₹${item.sellingPrice.toStringAsFixed(2)}',
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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

  String _productTitleForSale(OrderItem sale) {
    // Default implementation - you can customize this as needed
    return 'Product #${sale.productId}';
  }
}
