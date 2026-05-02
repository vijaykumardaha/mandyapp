import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/order_item/order_item_bloc.dart';
import 'package:mandyapp/models/product_variant_model.dart';
import 'package:mandyapp/widgets/selling/variant_item_card.dart';

typedef AddToSaleSubmitCallback = Future<void> Function(
  ProductVariant variant,
  double quantity,
  double rate,
);

class AddToSaleBottomSheet extends StatefulWidget {
  final List<ProductVariant> variants;
  final AddToSaleSubmitCallback onSubmit;

  const AddToSaleBottomSheet({
    super.key,
    required this.variants,
    required this.onSubmit,
  });

  @override
  State<AddToSaleBottomSheet> createState() => _AddToSaleBottomSheetState();
}

class _AddToSaleBottomSheetState extends State<AddToSaleBottomSheet> {
  final Map<int, TextEditingController> _quantityControllers = {};
  final Map<int, TextEditingController> _rateControllers = {};
  String _successMessage = '';

  @override
  void initState() {
    super.initState();

    for (var i = 0; i < widget.variants.length; i++) {
      final variant = widget.variants[i];
      final key = _keyForVariant(variant, i);
      _quantityControllers[key] = TextEditingController(
        text: variant.quantity.toStringAsFixed(2),
      );
      _rateControllers[key] = TextEditingController(
        text: variant.sellingPrice.toStringAsFixed(2),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    for (final controller in _rateControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int _keyForVariant(ProductVariant variant, int index) {
    return variant.id ?? (-index - 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<OrderItemBloc, OrderItemState>(
      listener: (context, state) {
        if (state is OrderItemsLoaded) {

          // Set success message
          setState(() {
              _successMessage = 'Successfully added to cart.';
          });

          // Clear message after 2 seconds
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _successMessage = '';
              });
            }
          });
        }
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success message at first position
            if (_successMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _successMessage,
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.variants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 5),
                itemBuilder: (context, index) {
                  final variant = widget.variants[index];
                  final key = _keyForVariant(variant, index);
                  final qtyController = _quantityControllers[key]!;
                  final rateController = _rateControllers[key]!;

                  return VariantItemCard(
                    variant: variant,
                    qtyController: qtyController,
                    rateController: rateController,
                    theme: theme,
                    onAddPressed: () async {
                      final quantity =
                          double.tryParse(qtyController.text.trim());
                      if (quantity == null || quantity <= 0) {
                        // Show error in the UI directly
                        return;
                      }

                      final rate = double.tryParse(rateController.text.trim());
                      if (rate == null || rate <= 0) {
                        // Show error in the UI directly
                        return;
                      }

                      try {
                        await widget.onSubmit(
                          variant,
                          quantity,
                          rate,
                        );
                      } catch (e) {
                        debugPrint('Error adding item to sale: $e');
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
