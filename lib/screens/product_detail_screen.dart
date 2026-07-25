import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/product/product_bloc.dart';
import 'package:mandyapp/helpers/extensions/string.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/product_model.dart';
import 'package:mandyapp/models/product_variant_model.dart';
import 'package:mandyapp/dao/product_variant_dao.dart';
import 'package:mandyapp/dao/product_dao.dart';
import 'package:mandyapp/widgets/product_detail/variant_form_sheet.dart';
import 'package:mandyapp/widgets/product_detail/variant_list_item.dart';

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
        final originalKey =
            variant != null ? _variantKey(variant) : null;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
          content: Text('please_add_at_least_one_variant'.tr()),
        ),
      );
      return;
    }

    if (_defaultVariantKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
          content: Text('please_select_default_variant'.tr()),
        ),
      );
      return;
    }

    final ProductVariant defaultVariant = _variants.firstWhere(
      (variant) => _variantKey(variant) == _defaultVariantKey,
      orElse: () => _variants.first,
    );

    final product = Product(
      id: widget.product?.id,
      mandyId: widget.product?.mandyId,
      defaultVariant: defaultVariant.id ?? widget.product?.defaultVariant ?? 0,
    );

    int? productId;

    if (widget.product == null) {
      await _productDAO.insertProduct(product);
      productId = product.id;

      context.read<ProductBloc>().add(LoadProducts());
    } else {
      await _productDAO.updateProduct(product);
      productId = product.id;

      context.read<ProductBloc>().add(LoadProducts());
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
        appBar: AppBar(
          title: MyText.titleMedium(
            widget.product == null ? 'add_product'.tr() : 'edit_product'.tr(),
            fontWeight: 600,
          ),
        ),
        body: SingleChildScrollView(
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
                          text: 'product_variants'.tr(),
                          style: TextStyle(
                            color: theme.colorScheme.onBackground,
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
                      label: MyText.bodyMedium('add_variant'.tr()),
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
                          color: theme.colorScheme.outline.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: MyText.bodyMedium(
                        'no_variants_added'.tr(),
                        color: theme.colorScheme.onBackground.withOpacity(0.6),
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
                    child: MyText.bodyLarge(
                      'save_product'.tr(),
                      fontWeight: 600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
