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
     Info.message('${variant.variantName} updated', context: context);
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
            fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.search_rounded,
                size: 20, color: theme.colorScheme.onSurfaceVariant),
            suffixIcon: _searchController.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    child: Icon(Icons.close_rounded,
                        size: 18, color: theme.colorScheme.onSurfaceVariant),
                  )
                : null,
          ),
        ),
        showBackButton: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filteredVariants.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _filteredVariants.length,
                    itemBuilder: (context, index) {
                      return _buildVariantTile(_filteredVariants[index]);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          MyText.bodyMedium(
            'No products found',
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantTile(ProductVariant variant) {
    final sellingPriceCtrl = _priceCtrl(variant);
    final quantityCtrl = _qtyCtrl(variant);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(variant),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildInputRow(
                        label: 'Rate (₹)',
                        controller: sellingPriceCtrl,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: _buildInputRow(
                        label: 'Quantity',
                        controller: quantityCtrl,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildUpdateButton(variant, sellingPriceCtrl, quantityCtrl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ProductVariant variant) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.06),
            theme.colorScheme.surface,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              size: 22,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: MyText.bodySmall(
              '₹${variant.sellingPrice.toStringAsFixed(0)}',
              color: theme.colorScheme.primary,
              fontWeight: 600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow({
    required String label,
    required TextEditingController controller,
    String? suffix,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText.bodySmall(
                  label,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
                const SizedBox(height: 1),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  readOnly: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          if (suffix != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: MyText.bodySmall(
                suffix,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          VerticalStepper(
            controller: controller,
            onChanged: () => setState(() {}),
            step: label.startsWith('Rate') ? 5 : 1,
            minValue: 0,
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton(
    ProductVariant variant,
    TextEditingController priceCtrl,
    TextEditingController qtyCtrl,
  ) {
    return ElevatedButton(
      onPressed: () {
        final newPrice = double.tryParse(priceCtrl.text);
        final newQty = double.tryParse(qtyCtrl.text);
        if (newPrice != null || newQty != null) {
          _updateVariant(variant, newPrice, newQty);
        } else {
          Info.message('Enter at least one value to update', context: context);
        }
      },
      child: const Text('Update', style: TextStyle(fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(40, 0),
        elevation: 0,
      ),
    );
  }
}
