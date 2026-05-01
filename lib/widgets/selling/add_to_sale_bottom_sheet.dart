import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/models/product_variant_model.dart';
import 'package:mandyapp/widgets/selling/sale_selection_bottom_sheet.dart';
import 'package:mandyapp/widgets/selling/variant_item_card.dart';

typedef AddToSaleSubmitCallback = Future<void> Function(
  ProductVariant variant,
  double quantity,
  double rate,
);

class AddToSaleBottomSheet extends StatefulWidget {
  final List<ProductVariant> variants;
  final Customer? buyerCustomer;
  final ValueChanged<Customer?> onBuyerChanged;
  final SaleSelectionFormatCustomer formatCustomer;
  final SaleSelectionSellerLookup sellerNameForSale;
  final SaleSelectionTitleLookup productTitleForSale;
  final SaleSelectionDeleteCallback onDeleteSale;
  final SaleSelectionCheckoutCallback onCheckout;
  final SaleSelectionCloseCallback onClose;
  final AddToSaleSubmitCallback onSubmit;

  const AddToSaleBottomSheet({
    super.key,
    required this.variants,
    required this.buyerCustomer,
    required this.onBuyerChanged,
    required this.formatCustomer,
    required this.sellerNameForSale,
    required this.productTitleForSale,
    required this.onDeleteSale,
    required this.onCheckout,
    required this.onClose,
    required this.onSubmit,
  });

  @override
  State<AddToSaleBottomSheet> createState() => _AddToSaleBottomSheetState();
}

class _AddToSaleBottomSheetState extends State<AddToSaleBottomSheet> {
  final Map<int, TextEditingController> _quantityControllers = {};
  final Map<int, TextEditingController> _rateControllers = {};

  @override
  void initState() {
    super.initState();

    for (var i = 0; i < widget.variants.length; i++) {
      final variant = widget.variants[i];
      final key = _keyForVariant(variant, i);
      _quantityControllers[key] = TextEditingController(
        text: variant.quantity?.toStringAsFixed(2) ?? '0',
      );
      _rateControllers[key] = TextEditingController(
        text: variant.sellingPrice?.toStringAsFixed(2) ?? '0',
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

    return Padding(
      padding: EdgeInsets.only(
          left: 16, right: 16, top: 24, bottom: bottomInset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.variants.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                    final quantity = double.tryParse(qtyController.text.trim());
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
    );
  }
}
