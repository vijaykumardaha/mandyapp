import 'package:flutter/material.dart';
import 'package:mandiapp/dao/product_variant_dao.dart';
import 'package:mandiapp/widgets/common/common_app_bar.dart';
import 'package:mandiapp/helpers/theme/app_theme.dart';
import 'package:mandiapp/widgets/common/my_text.dart';
import 'package:mandiapp/utils/info_controller.dart';
import 'package:mandiapp/models/product_variant_model.dart';
import 'package:mandiapp/widgets/common/vertical_stepper.dart';

class PriceUpdateScreen extends StatefulWidget {
  const PriceUpdateScreen({super.key});

  @override
  State<PriceUpdateScreen> createState() => _PriceUpdateScreenState();
}

class _PriceUpdateScreenState extends State<PriceUpdateScreen> {
  late ThemeData theme;
  final ProductVariantDAO _variantDAO = ProductVariantDAO();
  final TextEditingController _searchController = TextEditingController();
  final Map<int, TextEditingController> _priceControllers = {};
  final Map<int, TextEditingController> _qtyControllers = {};
  List<ProductVariant> _variants = [];
  List<ProductVariant> _filteredVariants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    _loadVariants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final ctrl in _priceControllers.values) {
      ctrl.dispose();
    }
    for (final ctrl in _qtyControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  TextEditingController _priceCtrl(ProductVariant v) {
    return _priceControllers.putIfAbsent(
        v.id ?? v.hashCode,
        () => TextEditingController(
            text: v.sellingPrice.toStringAsFixed(2)));
  }

  TextEditingController _qtyCtrl(ProductVariant v) {
    return _qtyControllers.putIfAbsent(
        v.id ?? v.hashCode,
        () => TextEditingController(
            text: v.quantity.toStringAsFixed(2)));
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredVariants = _variants;
      } else {
        _filteredVariants = _variants
            .where((v) =>
                v.variantName
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _loadVariants() async {
    setState(() {
      _isLoading = true;
    });
    final variants = await _variantDAO.getAllVariants();
    setState(() {
      _variants = variants.where((v) => v.isDeleted == 0).toList();
      _filteredVariants = _variants;
      _isLoading = false;
    });
  }

   Future<void> _updateVariant(ProductVariant variant, double? newPrice,
       double? newQuantity) async {
     final updated = variant.copyWith(
       sellingPrice: newPrice ?? variant.sellingPrice,
       quantity: newQuantity ?? variant.quantity,
     );
     await _variantDAO.updateVariant(updated);
     Info.message('Product price updated', context: context);
     final priceCtrl = _priceCtrl(variant);
     final qtyCtrl = _qtyCtrl(variant);
     priceCtrl.text = updated.sellingPrice.toStringAsFixed(2);
     qtyCtrl.text = updated.quantity.toStringAsFixed(2);
     setState(() {
       final idx = _variants.indexOf(variant);
       if (idx != -1) {
         _variants[idx] = updated;
       }
       final fIdx = _filteredVariants.indexOf(variant);
       if (fIdx != -1) {
         _filteredVariants[fIdx] = updated;
       }
     });
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CommonAppBar(
        backgroundColor: theme.colorScheme.surface,
        titleWidget: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search products...',
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: theme.colorScheme.primary, width: 1.5),
            ),
            prefixIcon: Icon(Icons.search,
                size: 20, color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredVariants.isEmpty
              ? Center(
                  child: MyText.bodyMedium(
                    'No variants found',
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredVariants.length,
                  itemBuilder: (context, index) {
                    return _buildVariantTile(_filteredVariants[index]);
                  },
                ),
    );
  }

  Widget _buildVariantTile(ProductVariant variant) {
    final sellingPriceCtrl = _priceCtrl(variant);
    final quantityCtrl = _qtyCtrl(variant);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText.bodyMedium(
                        variant.variantName,
                        fontWeight: 600,
                      ),
                      if (variant.unit.isNotEmpty)
                        MyText.bodySmall(
                          variant.unit,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                          fontSize: 11,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText.bodySmall(
                          'Rate (₹)',
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: sellingPriceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          readOnly: true,
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            suffixIcon: VerticalStepper(
                              controller: sellingPriceCtrl,
                              onChanged: () => setState(() {}),
                              step: 1,
                              minValue: 0,
                            ),
                            suffixIconConstraints: const BoxConstraints(minWidth: 36, maxWidth: 36),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: theme.colorScheme.outline.withValues(alpha: 0.15),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText.bodySmall(
                          'Qty',
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: quantityCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          readOnly: true,
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            suffixIcon: VerticalStepper(
                              controller: quantityCtrl,
                              onChanged: () => setState(() {}),
                              step: 1,
                              minValue: 0,
                            ),
                            suffixIconConstraints: const BoxConstraints(minWidth: 36, maxWidth: 36),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  final newPrice = double.tryParse(sellingPriceCtrl.text);
                  final newQty = double.tryParse(quantityCtrl.text);
                  if (newPrice != null || newQty != null) {
                    _updateVariant(variant, newPrice, newQty);
                  } else {
                    Info.message('Enter at least one value to update', context: context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text('Update', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}