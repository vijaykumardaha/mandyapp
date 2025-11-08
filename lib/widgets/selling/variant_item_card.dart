import 'package:flutter/material.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/product_variant_model.dart';
import 'package:mandyapp/widgets/common/reusable_controls.dart';

class VariantItemCard extends StatefulWidget {
  final ProductVariant variant;
  final TextEditingController qtyController;
  final TextEditingController rateController;
  final Map<int, double> currentStocks;
  final ThemeData theme;
  final bool isLoading;
  final Future<void> Function()? onAddPressed;
  const VariantItemCard({
    Key? key,
    required this.variant,
    required this.qtyController,
    required this.rateController,
    required this.currentStocks,
    required this.theme,
    this.isLoading = false,
    this.onAddPressed,
  }) : super(key: key);

  @override
  State<VariantItemCard> createState() => _VariantItemCardState();

  // Helper method to get available stock for the variant
  String get stockDisplayText {
    if (variant.id == null || !currentStocks.containsKey(variant.id)) {
      return variant.variantName;
    }
    final stock = currentStocks[variant.id]!;
    return '${variant.variantName} (${stock.toStringAsFixed(2)} ${variant.unit})';
  }

}

class _VariantItemCardState extends State<VariantItemCard> {
  // Track the current available stock
  double? _availableStock;

  @override
  void initState() {
    super.initState();
    // Initialize available stock when widget is first created
    _updateAvailableStock();
  }

  // Update the available stock based on current quantity
  void _updateAvailableStock() {
    if (widget.variant.id != null && widget.variant.manageStock) {
      final currentStock = widget.currentStocks[widget.variant.id!] ?? 0;
      final currentQty = double.tryParse(widget.qtyController.text) ?? 0;
      setState(() {
        _availableStock = currentStock - currentQty;
      });
    }
  }

  // Handle quantity changes
  void _onQuantityChanged() {
    final quantity = double.tryParse(widget.qtyController.text) ?? 0;
    
    // Update available stock
    if (widget.variant.manageStock && widget.variant.id != null) {
      final currentStock = widget.currentStocks[widget.variant.id!] ?? 0;
      setState(() {
        _availableStock = currentStock - quantity;
      });
    }
    
    // Update the UI
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double computeTotal() {
      final quantity = double.tryParse(widget.qtyController.text.trim()) ?? 0;
      final rate = double.tryParse(widget.rateController.text.trim()) ?? 0;
      return quantity * rate;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          height: 1,
          thickness: 0.5,
          color: widget.theme.colorScheme.outline.withOpacity(0.1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Variant info section
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyText.bodyMedium(
                            widget.stockDisplayText,
                            fontWeight: 600,
                            color: widget.variant.manageStock && 
                                   widget.variant.id != null && 
                                   (widget.currentStocks[widget.variant.id] ?? 0) <= 0
                                ? widget.theme.colorScheme.error
                                : widget.theme.colorScheme.onSurfaceVariant,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Input fields section
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Rate Field
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: widget.rateController,
                                enabled: widget.variant.id != null,
                                readOnly: true,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: InputDecoration(
                                  labelText: 'Rate',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 6),
                                  suffixIcon: VerticalStepper(
                                    controller: widget.rateController,
                                    onChanged: () => setState(() {}),
                                    step: 0.1,
                                    minValue: 0,
                                  ),
                                  suffixIconConstraints: const BoxConstraints(
                                      minWidth: 36, maxWidth: 36),
                                ),
                                style: widget.theme.textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Quantity Field
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: widget.qtyController,
                                enabled: widget.variant.id != null,
                                readOnly: true,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                style:
                                    widget.theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Qty (${widget.variant.unit})',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 6,
                                  ),
                                  suffixIcon: VerticalStepper(
                                    controller: widget.qtyController,
                                    onChanged: _onQuantityChanged,
                                    step: 1,
                                    minValue: 0,
                                    maxValue: widget.variant.manageStock &&
                                            widget.variant.id != null
                                        ? (widget.currentStocks[widget.variant.id] ?? 0) + 
                                            (double.tryParse(widget.qtyController.text) ?? 0)
                                        : null,
                                  ),
                                  suffixIconConstraints: const BoxConstraints(
                                    minWidth: 36,
                                    maxWidth: 36,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Add Button
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                  minWidth: 75, maxWidth: 75),
                              child: OutlinedButton(
                                onPressed: widget.variant.id == null ||
                                        widget.isLoading
                                    ? null
                                    : () async {
                                        final quantity = double.tryParse(
                                            widget.qtyController.text.trim());
                                        if (quantity == null || quantity <= 0) {
                                          // Show error in the UI directly
                                          return;
                                        }

                                        // Check stock availability if stock management is enabled
                                        if (widget.variant.manageStock &&
                                            widget.variant.id != null) {
                                          final currentStock = widget.currentStocks[widget.variant.id!] ?? 0;
                                          final availableStock = currentStock - quantity;
                                          
                                          if (availableStock < 0) {
                                            // Show error in the UI directly
                                            return;
                                          }
                                          
                                          // Update available stock display
                                          setState(() {
                                            _availableStock = availableStock;
                                          });
                                        }

                                        final rate = double.tryParse(
                                            widget.rateController.text.trim());
                                        if (rate == null || rate <= 0) {
                                          // Show error in the UI directly
                                          return;
                                        }

                                        await widget.onAddPressed?.call();
                                      },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      widget.theme.colorScheme.primary,
                                  side: BorderSide(
                                      color: widget.theme.colorScheme.primary,
                                      width: 1.4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  textStyle: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('ADD'),
                                    Text(
                                      '₹${computeTotal().toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
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
  }
}
