import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/product_stock_model.dart';
import 'package:mandyapp/models/product_variant_model.dart';
import 'package:mandyapp/dao/product_stock_dao.dart';
import 'package:mandyapp/widgets/common/reusable_controls.dart';
import 'package:mandyapp/widgets/selling/product_card.dart';

typedef AddToSaleSubmitCallback = Future<void> Function(
  ProductVariant variant,
  double quantity,
  double rate,
  void Function(String message) onBanner,
);

class AddToSaleBottomSheet extends StatefulWidget {
  final List<ProductVariant> variants;
  final String? sellerLabel;
  final AddToSaleSubmitCallback onSubmit;
  final Widget Function(ThemeData theme, String message, VoidCallback onDismiss) bannerBuilder;

  const AddToSaleBottomSheet({
    super.key,
    required this.variants,
    required this.onSubmit,
    this.sellerLabel,
    required this.bannerBuilder,
  });

  @override
  State<AddToSaleBottomSheet> createState() => _AddToSaleBottomSheetState();
}

class _AddToSaleBottomSheetState extends State<AddToSaleBottomSheet> {
  final Map<int, TextEditingController> _quantityControllers = {};
  final Map<int, TextEditingController> _rateControllers = {};
  final Map<int, double> _currentStocks = {};
  final ProductStockDAO _stockDAO = ProductStockDAO();
  Timer? _bannerTimer;
  String? _bannerMessage;
  bool _sheetClosing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    for (var i = 0; i < widget.variants.length; i++) {
      final variant = widget.variants[i];
      final key = _keyForVariant(variant, i);
      _quantityControllers[key] = TextEditingController(
        text: '0', // Start with 0 instead of variant.quantity
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

  void _setBannerMessage(String? message, {bool autoDismiss = true}) {
    _bannerTimer?.cancel();

    if (!mounted || _sheetClosing) {
      return;
    }

    setState(() {
      _bannerMessage = message;
    });

    if (message != null && autoDismiss) {
      _bannerTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted || _sheetClosing) return;
        setState(() {
          _bannerMessage = null;
        });
      });
    }
  }


  @override
  void dispose() {
    _sheetClosing = true;
    _bannerTimer?.cancel();
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
      padding: EdgeInsets.only(left: 16, right: 16, top: 24, bottom: bottomInset + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_bannerMessage != null)
            widget.bannerBuilder(theme, _bannerMessage!, () => _setBannerMessage(null, autoDismiss: false)),
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

                double computeTotal() {
                  final quantity = double.tryParse(qtyController.text.trim()) ?? 0;
                  final rate = double.tryParse(rateController.text.trim()) ?? 0;
                  return quantity * rate;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index > 0)
                      Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    MyText.bodyMedium(
                                      variant.variantName,
                                      fontWeight: 600,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    if (variant.manageStock && variant.id != null && !_isLoading) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (_currentStocks[variant.id] ?? 0) > 0 
                                              ? theme.colorScheme.primaryContainer 
                                              : theme.colorScheme.errorContainer,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: MyText.bodySmall(
                                          '${(_currentStocks[variant.id] ?? 0).toStringAsFixed(2)} ${variant.unit}',
                                          fontWeight: 500,
                                          color: (_currentStocks[variant.id] ?? 0) > 0 
                                              ? theme.colorScheme.onPrimaryContainer 
                                              : theme.colorScheme.onErrorContainer,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          flex: 3,
                                          child: TextField(
                                            controller: qtyController,
                                            enabled: variant.id != null,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: InputDecoration(
                                              labelText: 'Qty (${variant.unit})',
                                              border: const OutlineInputBorder(),
                                              isDense: true,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                              suffixIcon: VerticalStepper(
                                                controller: qtyController,
                                                onChanged: () => setState(() {}),
                                                step: 1,
                                                minValue: 0,
                                              ),
                                              suffixIconConstraints: const BoxConstraints(minWidth: 36, maxWidth: 36),
                                            ),
                                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          flex: 4,
                                          child: TextField(
                                            controller: rateController,
                                            enabled: variant.id != null,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: InputDecoration(
                                              labelText: 'Rate',
                                              border: const OutlineInputBorder(),
                                              isDense: true,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                              suffixIcon: VerticalStepper(
                                                controller: rateController,
                                                onChanged: () => setState(() {}),
                                                step: 0.1,
                                                minValue: 0,
                                              ),
                                              suffixIconConstraints: const BoxConstraints(minWidth: 36, maxWidth: 36),
                                            ),
                                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(minWidth: 72),
                                          child: OutlinedButton(
                                            onPressed: variant.id == null
                                                ? null
                                                : () async {
                                                    final quantity = double.tryParse(qtyController.text.trim());
                                                    if (quantity == null || quantity <= 0) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          behavior: SnackBarBehavior.floating,
                                                          margin: EdgeInsets.only(top: 16, left: 16, right: 16),
                                                          content: Text('Enter a valid quantity.'),
                                                        ),
                                                      );
                                                      return;
                                                    }

                                                    final rate = double.tryParse(rateController.text.trim());
                                                    if (rate == null || rate <= 0) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          behavior: SnackBarBehavior.floating,
                                                          margin: EdgeInsets.only(top: 16, left: 16, right: 16),
                                                          content: Text('Enter a valid rate.'),
                                                        ),
                                                      );
                                                      return;
                                                    }
                                                    await widget.onSubmit(variant, quantity, rate, (message) {
                                                      _setBannerMessage(message);
                                                    });
                                                    _setBannerMessage('Item has been added to your list.');
                                                  },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: theme.colorScheme.primary,
                                              side: BorderSide(color: theme.colorScheme.primary, width: 1.4),
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              textStyle: const TextStyle(fontWeight: FontWeight.w700),
                                            ),
                                            child: Text('ADD (₹${computeTotal().toStringAsFixed(2)})'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
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
