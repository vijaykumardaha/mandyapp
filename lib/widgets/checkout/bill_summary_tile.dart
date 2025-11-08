import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/checkout/checkout_bloc.dart';
import 'checkout_stepper_field.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/item_sale_model.dart';
import 'package:mandyapp/models/product_model.dart';
import 'package:mandyapp/models/product_variant_model.dart';

class BillSummaryTile extends StatelessWidget {
  final ItemSale item;
  final Product product;
  final ProductVariant variant;
  final Function()? onPersistCheckout;
  final bool isEdit;

  const BillSummaryTile({
    Key? key,
    required this.item,
    required this.product,
    required this.variant,
    required this.isEdit,
    this.onPersistCheckout,
  }) : super(key: key);

  void _handleQuantityChange(double value, BuildContext context) {
    if (value == item.quantity) return;
    final updatedItem = item.copyWith(quantity: value);
    context.read<CheckoutBloc>().add(UpdateCheckoutItem(updatedItem));
    onPersistCheckout?.call();
  }

  void _handlePriceChange(double value, BuildContext context) {
    if (value == item.sellingPrice) return;
    final updatedItem = item.copyWith(sellingPrice: value);
    context.read<CheckoutBloc>().add(UpdateCheckoutItem(updatedItem));
    onPersistCheckout?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: MySpacing.bottom(12),
      padding: MySpacing.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: MyText.bodyMedium(
                variant.variantName,
                fontWeight: 600,
              ),
            ),
          ),
          if (isEdit) ...[
            CheckoutStepperField(
              key: ValueKey('qty-${item.id ?? item.variantId}-${item.buyerCartId}'),
              label: 'Qty (${variant.unit})',
              initialValue: item.quantity,
              step: 1,
              minValue: 0.1,
              onChanged: (value) => _handleQuantityChange(value, context),
            ),
            MySpacing.width(6),
            CheckoutStepperField(
              key: ValueKey('rate-${item.id ?? item.variantId}-${item.buyerCartId}'),
              label: 'Rate',
              initialValue: item.sellingPrice,
              step: 0.5,
              minValue: 0.1,
              prefixText: '₹',
              onChanged: (value) => _handlePriceChange(value, context),
            ),
          ] else ...[
            MyText.bodyMedium(
              '${item.quantity} ${variant.unit}',
              fontWeight: 500,
            ),
            MySpacing.width(12),
            MyText.bodyMedium(
              '₹${item.sellingPrice.toStringAsFixed(2)}',
              fontWeight: 500,
            ),
          ],
          MySpacing.width(12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MyText.bodyLarge(
                '₹${item.totalPrice.toStringAsFixed(2)}',
                fontWeight: 700,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
