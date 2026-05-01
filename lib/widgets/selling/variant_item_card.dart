import 'package:flutter/material.dart';
import 'package:mandyapp/models/product_variant_model.dart';
import 'package:mandyapp/widgets/common/reusable_controls.dart';

class VariantItemCard extends StatefulWidget {
  final ProductVariant variant;
  final TextEditingController qtyController;
  final TextEditingController rateController;

  final ThemeData theme;
  final bool isLoading;
  final Future<void> Function()? onAddPressed;
  const VariantItemCard({
    Key? key,
    required this.variant,
    required this.qtyController,
    required this.rateController,
    required this.theme,
    this.isLoading = false,
    this.onAddPressed,
  }) : super(key: key);

  @override
  State<VariantItemCard> createState() => _VariantItemCardState();

}

class _VariantItemCardState extends State<VariantItemCard> {

  @override
  void initState() {
    super.initState();
  }

  // Handle quantity changes
  void _onQuantityChanged() {
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
                                    step: 1
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
