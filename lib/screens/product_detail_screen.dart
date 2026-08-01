import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:krishimandi/blocs/product/product_bloc.dart';
import 'package:krishimandi/dao/product_dao.dart';
import 'package:krishimandi/dao/product_variant_dao.dart';
import 'package:krishimandi/helpers/theme/app_theme.dart';
import 'package:krishimandi/models/product_model.dart';
import 'package:krishimandi/models/product_variant_model.dart';
import 'package:krishimandi/utils/info_controller.dart';
import 'package:krishimandi/widgets/common/common_app_bar.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';
import 'package:krishimandi/widgets/product_detail/variant_form_sheet.dart';
import 'package:krishimandi/widgets/product_detail/variant_list_item.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product? product;

  const ProductDetailScreen({super.key, this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late ThemeData theme;

  List<ProductVariant> _variants = [];
  final ProductVariantDAO _variantDAO = ProductVariantDAO();
  final ProductDAO _productDAO = ProductDAO();
  String? _defaultVariantKey;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;

    if (widget.product != null) {
      _loadVariants();
    }
  }

  Future<void> _loadVariants() async {
    if (widget.product?.id != null) {
      final variants =
          await _variantDAO.getVariantsByProductId(widget.product!.id!);
      setState(() {
        _variants = variants;
        _defaultVariantKey = widget.product != null
            ? 'id_${widget.product!.defaultVariant}'
            : null;
        _ensureDefaultVariantKey();
      });
    }
  }

  String _variantKey(ProductVariant variant) {
    return variant.id != null
        ? 'id_${variant.id}'
        : 'temp_${identityHashCode(variant)}';
  }

  void _ensureDefaultVariantKey() {
    if (_variants.isEmpty) {
      _defaultVariantKey = null;
      return;
    }

    final hasMatch =
        _variants.any((variant) => _variantKey(variant) == _defaultVariantKey);
    if (!hasMatch) {
      _defaultVariantKey = _variantKey(_variants.first);
    }
  }

  void _showAddVariantDialog([ProductVariant? variant]) async {
    final productId = widget.product?.id ?? 0;
    final result = await VariantFormSheet.show(
      context,
      productId: productId,
      existingVariant: variant,
    );

    if (result != null) {
      setState(() {
        final originalKey = variant != null ? _variantKey(variant) : null;
        if (variant == null) {
          _variants.add(result);
          _defaultVariantKey ??= _variantKey(result);
        } else {
          final index = _variants.indexOf(variant);
          if (index != -1) {
            _variants[index] = result;
            if (_defaultVariantKey == originalKey) {
              _defaultVariantKey = _variantKey(result);
            }
          }
        }

        _ensureDefaultVariantKey();
      });
    }
  }

  void _deleteVariant(ProductVariant variant) {
    setState(() {
      _variants.remove(variant);
      if (_defaultVariantKey == _variantKey(variant)) {
        _defaultVariantKey = null;
      }
      _ensureDefaultVariantKey();
    });
  }

  Future<void> _saveProduct() async {
    _ensureDefaultVariantKey();

    if (_variants.isEmpty) {
      Info.message('Please add at least one variant', context: context);
      return;
    }

    if (_defaultVariantKey == null) {
      Info.message('Please select a default variant', context: context);
      return;
    }

    final ProductVariant defaultVariant = _variants.firstWhere(
      (variant) => _variantKey(variant) == _defaultVariantKey,
      orElse: () => _variants.first,
    );

    final product = Product(
      id: widget.product?.id,
      mandiId: widget.product?.mandiId,
      defaultVariant: defaultVariant.id ?? widget.product?.defaultVariant ?? 0,
    );

    int? productId;

    if (widget.product == null) {
      await _productDAO.insertProduct(product);
      productId = product.id;

      if (mounted) context.read<ProductBloc>().add(LoadProducts());
    } else {
      await _productDAO.updateProduct(product);
      productId = product.id;

      if (mounted) context.read<ProductBloc>().add(LoadProducts());
    }

    if (productId != null && _variants.isNotEmpty) {
      await _variantDAO.deleteVariantsByProductId(productId);
      int? defaultVariantId;
      for (var variant in _variants) {
        final keyBefore = _variantKey(variant);
        variant.productId = productId;
        await _variantDAO.insertVariant(variant);
        final keyAfter = _variantKey(variant);
        if (_defaultVariantKey == keyBefore) {
          _defaultVariantKey = keyAfter;
          defaultVariantId = variant.id;
        }
      }

      defaultVariantId ??= _variants.first.id;
      if (defaultVariantId != null) {
        await _productDAO.updateDefaultVariant(productId, defaultVariantId);
        product.defaultVariant = defaultVariantId;
      }
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        titleWidget: MyText.titleMedium(
          widget.product == null ? 'Add Product' : 'Edit Product',
          fontWeight: 600,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: MySpacing.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: 'Product Variants',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          children: const [
                            TextSpan(
                              text: ' *',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showAddVariantDialog,
                      icon: const Icon(Icons.add),
                      label: const MyText.bodyMedium('Add Variant'),
                    ),
                  ],
                ),
                MySpacing.height(12),
                MySpacing.height(12),
                if (_variants.isEmpty)
                  Container(
                    padding: MySpacing.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: MyText.bodyMedium(
                        'No variants added yet',
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  )
                else
                  ...List.generate(_variants.length, (index) {
                    final variant = _variants[index];
                    final variantKeyStr = _variantKey(variant);
                    return VariantListItem(
                      variant: variant,
                      isDefault: variantKeyStr == _defaultVariantKey,
                      variantKey: variantKeyStr,
                      onEdit: () => _showAddVariantDialog(variant),
                      onDelete: () => _deleteVariant(variant),
                      onDefaultChanged: (value) {
                        setState(() {
                          _defaultVariantKey = value;
                        });
                      },
                      theme: theme,
                    );
                  }),
                MySpacing.height(24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _variants.isEmpty ? null : _saveProduct,
                    style: ElevatedButton.styleFrom(
                      padding: MySpacing.y(16),
                    ),
                    child: const MyText.bodyLarge(
                      'Save Product',
                      fontWeight: 600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
