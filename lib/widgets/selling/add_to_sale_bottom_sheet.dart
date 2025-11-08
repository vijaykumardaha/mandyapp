import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/product_variant_model.dart';
import 'package:mandyapp/dao/product_stock_dao.dart';
import 'package:mandyapp/widgets/selling/variant_item_card.dart';

typedef AddToSaleSubmitCallback = Future<void> Function(
  ProductVariant variant,
  double quantity,
  double rate,
);

class AddToSaleBottomSheet extends StatefulWidget {
  final List<ProductVariant> variants;
  final String? sellerLabel;
  final AddToSaleSubmitCallback onSubmit;

  const AddToSaleBottomSheet({
    super.key,
    required this.variants,
    required this.onSubmit,
    this.sellerLabel,
  });

  @override
  State<AddToSaleBottomSheet> createState() => _AddToSaleBottomSheetState();
}


class _AddToSaleBottomSheetState extends State<AddToSaleBottomSheet> {
  final Map<int, TextEditingController> _quantityControllers = {};
  final Map<int, TextEditingController> _rateControllers = {};
  final Map<int, double> _currentStocks = {};
  final ProductStockDAO _stockDAO = ProductStockDAO();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    for (var i = 0; i < widget.variants.length; i++) {
      final variant = widget.variants[i];
      final key = _keyForVariant(variant, i);
      _quantityControllers[key] = TextEditingController(
        text: variant.quantity?.toStringAsFixed(2) ?? '0',
      );
      _rateControllers[key] = TextEditingController(
        text: variant.sellingPrice.toStringAsFixed(2),
      );
    }

    // Load stock data
    _loadStocks();
  }

  Future<void> _loadStocks() async {
    try {
      for (final variant in widget.variants) {
        if (variant.id != null && variant.manageStock) {
          final stock = await _stockDAO.getStockForVariant(
            productId: variant.productId,
            variantId: variant.id!,
          );
          if (stock != null) {
            _currentStocks[variant.id!] = stock.currentStock;
          } else {
            _currentStocks[variant.id!] = 0.0;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading stocks: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
          if (widget.sellerLabel != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MyText.bodySmall(
                widget.sellerLabel!,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
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
                  currentStocks: _currentStocks,
                  theme: theme,
                  isLoading: _isLoading,
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
