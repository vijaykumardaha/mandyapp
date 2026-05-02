import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/order/order_bloc.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/order_item_model.dart';
import 'package:mandyapp/widgets/checkout/checkout_stepper_field.dart';

class BillSummaryTile extends StatefulWidget {
  final OrderItem item;
  final Function()? onPersistCheckout;
  final bool isEdit;

  const BillSummaryTile({
    Key? key,
    required this.item,
    required this.isEdit,
    this.onPersistCheckout,
  }) : super(key: key);
  
  @override
  State<BillSummaryTile> createState() => _BillSummaryTileState();
}

class _BillSummaryTileState extends State<BillSummaryTile> {
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    );
    _priceController = TextEditingController(
      text: widget.item.sellingPrice.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _handleQuantityChange(double value, BuildContext context) {
    if (value == widget.item.quantity) return;
    final updatedItem = widget.item.copyWith(quantity: value);
    context.read<OrderBloc>().add(UpdateOrderItem(updatedItem));
    widget.onPersistCheckout?.call();
  }

  void _handlePriceChange(double value, BuildContext context) {
    if (value == widget.item.sellingPrice) return;
    final updatedItem = widget.item.copyWith(sellingPrice: value);
    context.read<OrderBloc>().add(UpdateOrderItem(updatedItem));
    widget.onPersistCheckout?.call();
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
                widget.item.variantName ?? 'Variant #${widget.item.variantId}',
                fontWeight: 600,
              ),
            ),
          ),
          if (widget.isEdit) ...[
            CheckoutStepperField(
              key: ValueKey('qty-${widget.item.id ?? widget.item.variantId}-${widget.item.buyerOrderId}'),
              label: 'Qty',
              initialValue: widget.item.quantity,
              step: 1,
              minValue: 0.1,
              unit: widget.item.unit,
              controller: _quantityController,
              onChanged: (value) => _handleQuantityChange(value, context),
            ),
            MySpacing.width(6),
            CheckoutStepperField(
              key: ValueKey('rate-${widget.item.id ?? widget.item.variantId}-${widget.item.buyerOrderId}'),
              label: 'Rate',
              initialValue: widget.item.sellingPrice,
              step: 0.5,
              minValue: 0.1,
              controller: _priceController,
              onChanged: (value) => _handlePriceChange(value, context),
            ),
          ] else ...[
            MyText.bodyMedium(
              '${widget.item.quantity} ${widget.item.unit}',
              fontWeight: 500,
            ),
            MySpacing.width(12),
            MyText.bodyMedium(
              '₹${widget.item.sellingPrice.toStringAsFixed(2)}',
              fontWeight: 500,
            ),
          ],
          MySpacing.width(12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MyText.bodyLarge(
                '₹${(widget.item.quantity * widget.item.sellingPrice).toStringAsFixed(2)}',
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
