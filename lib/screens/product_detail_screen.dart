import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/category/category_bloc.dart';
import 'package:mandyapp/blocs/product/product_bloc.dart';
import 'package:mandyapp/helpers/extensions/string.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/category_model.dart';
import 'package:mandyapp/models/product_model.dart';
import 'package:mandyapp/models/product_variant_model.dart';
import 'package:mandyapp/dao/product_variant_dao.dart';
import 'package:mandyapp/dao/product_dao.dart';
import 'package:image_picker/image_picker.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product? product;
  
  const ProductDetailScreen({super.key, this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late ThemeData theme;

  int? _selectedCategoryId;
  List<ProductVariant> _variants = [];
  final ProductVariantDAO _variantDAO = ProductVariantDAO();
  final ProductDAO _productDAO = ProductDAO();
  String? _defaultVariantKey;

  Widget _variantThumbnail(String imagePath) {
    final placeholder = Container(
      width: 50,
      height: 50,
      color: theme.colorScheme.surfaceVariant,
      child: Icon(
        Icons.image_not_supported,
        size: 24,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );

    if (imagePath.isEmpty) {
      return placeholder;
    }

    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    }

    return Image.file(
      File(imagePath),
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
  
  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    context.read<CategoryBloc>().add(LoadCategories());

    if (widget.product != null) {
      _selectedCategoryId = widget.product!.categoryId;
      _loadVariants();
    }
  }

  Future<void> _loadVariants() async {
    if (widget.product?.id != null) {
      final variants = await _variantDAO.getVariantsByProductId(widget.product!.id!);
      setState(() {
        _variants = variants;
        _defaultVariantKey = widget.product != null ? 'id_${widget.product!.defaultVariant}' : null;
        _ensureDefaultVariantKey();
      });
    }
  }

  String _variantKey(ProductVariant variant) {
    return variant.id != null ? 'id_${variant.id}' : 'temp_${identityHashCode(variant)}';
  }

  void _ensureDefaultVariantKey() {
    if (_variants.isEmpty) {
      _defaultVariantKey = null;
      return;
    }

    final hasMatch = _variants.any((variant) => _variantKey(variant) == _defaultVariantKey);
    if (!hasMatch) {
      _defaultVariantKey = _variantKey(_variants.first);
    }
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: MyText.titleMedium('add_category'.tr(), fontWeight: 600),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'category_name'.tr(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: MySpacing.xy(16, 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: MyText.bodyMedium('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                    content: Text('please_enter_category_name'.tr()),
                  ),
                );
                return;
              }

              final category = Category(name: nameController.text);
              context.read<CategoryBloc>().add(AddCategory(category));
              Navigator.pop(context);
            },
            child: MyText.bodyMedium('add'.tr()),
          ),
        ],
      ),
    );
  }

  void _showAddVariantDialog([ProductVariant? variant]) {
    final nameController = TextEditingController(text: variant?.variantName ?? '');
    final buyingPriceController = TextEditingController(text: variant != null ? variant.buyingPrice.toString() : '');
    final sellingPriceController = TextEditingController(text: variant != null ? variant.sellingPrice.toString() : '');
    final quantityController = TextEditingController(text: variant != null ? variant.quantity.toString() : '');
    String selectedUnit = variant?.unit ?? 'Kg';
    String imagePath = variant?.imagePath ?? '';
    bool manageStock = variant?.manageStock ?? true;
    final ImagePicker imagePicker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: MyText.titleMedium(
            variant == null ? 'add_variant'.tr() : 'edit_variant'.tr(),
            fontWeight: 600,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imagePath.isNotEmpty
                        ? Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: theme.colorScheme.surfaceVariant,
                            child: Icon(
                              Icons.image,
                              size: 36,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
                MySpacing.height(12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final picked = await imagePicker.pickImage(source: ImageSource.camera);
                          if (picked != null) {
                            setDialogState(() {
                              imagePath = picked.path;
                            });
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                      ),
                    ),
                    MySpacing.width(12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final picked = await imagePicker.pickImage(source: ImageSource.gallery);
                          if (picked != null) {
                            setDialogState(() {
                              imagePath = picked.path;
                            });
                          }
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                      ),
                    ),
                  ],
                ),
                MySpacing.height(12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'variant_name'.tr(),
                    hintText: 'e.g., 500g, 1Kg, Small, Medium',
                    border: const OutlineInputBorder(),
                  ),
                ),
                MySpacing.height(12),
                TextField(
                  controller: buyingPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'buying_price'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                MySpacing.height(12),
                TextField(
                  controller: sellingPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'selling_price'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                MySpacing.height(12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'quantity'.tr(),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    MySpacing.width(12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit,
                        decoration: InputDecoration(
                          labelText: 'unit'.tr(),
                          border: const OutlineInputBorder(),
                        ),
                        items: ['Kg', 'g', 'L', 'ml', 'Pcs', 'Box']
                            .map((unit) => DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() => selectedUnit = value!);
                        },
                      ),
                    ),
                  ],
                ),
                MySpacing.height(12),
                CheckboxListTile(
                  value: manageStock,
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => manageStock = value);
                    }
                  },
                  title: MyText.bodyMedium('Manage stock for this variant'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: MyText.bodyMedium('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final buyingPriceText = buyingPriceController.text.trim();
                final sellingPriceText = sellingPriceController.text.trim();
                final quantityText = quantityController.text.trim();

                if (name.isEmpty || imagePath.isEmpty || buyingPriceText.isEmpty || sellingPriceText.isEmpty || quantityText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                      content: Text('please_fill_required_fields'.tr()),
                    ),
                  );
                  return;
                }

                final buyingPrice = double.tryParse(buyingPriceText);
                final sellingPrice = double.tryParse(sellingPriceText);
                final quantity = double.tryParse(quantityText);

                if (buyingPrice == null || sellingPrice == null || quantity == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                      content: Text('please_enter_valid_numbers'.tr()),
                    ),
                  );
                  return;
                }

                final newVariant = ProductVariant(
                  id: variant?.id,
                  productId: widget.product?.id ?? 0,
                  variantName: name,
                  buyingPrice: buyingPrice,
                  sellingPrice: sellingPrice,
                  quantity: quantity,
                  unit: selectedUnit,
                  imagePath: imagePath,
                  manageStock: manageStock,
                );

                setState(() {
                  final originalKey = variant != null ? _variantKey(variant) : null;
                  if (variant == null) {
                    _variants.add(newVariant);
                    _defaultVariantKey ??= _variantKey(newVariant);
                  } else {
                    final index = _variants.indexOf(variant);
                    if (index != -1) {
                      _variants[index] = newVariant;
                      if (_defaultVariantKey == originalKey) {
                        _defaultVariantKey = _variantKey(newVariant);
                      }
                    }
                  }

                  _ensureDefaultVariantKey();
                });

                Navigator.pop(context);
              },
              child: MyText.bodyMedium(variant == null ? 'add'.tr() : 'update'.tr()),
            ),
          ],
        ),
      ),
    );
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
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
          content: Text('please_select_category'.tr()),
        ),
      );
      return;
    }

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
      categoryId: _selectedCategoryId!,
      defaultVariant: defaultVariant.id ?? widget.product?.defaultVariant ?? 0,
    );

    int? productId;

    if (widget.product == null) {
      // Insert new product directly using DAO to get the ID
      await _productDAO.insertProduct(product);
      productId = product.id; // ID is set by insertProduct
      
      // Trigger BLoC to reload products
      context.read<ProductBloc>().add(LoadProducts());
    } else {
      // Update existing product
      await _productDAO.updateProduct(product);
      productId = product.id;
      
      // Trigger BLoC to reload products
      context.read<ProductBloc>().add(LoadProducts());
    }

    // Save variants if product ID is available
    if (productId != null && _variants.isNotEmpty) {
      // Delete existing variants and insert new ones
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
      body: BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, categoryState) {
          if (categoryState is CategoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final categories = categoryState is CategoryLoaded ? categoryState.categories : <Category>[];
          
          // Set initial category if not set and categories are available
          if (_selectedCategoryId == null && categories.isNotEmpty && widget.product == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _selectedCategoryId = categories.first.id;
              });
            });
          }
          
          return SingleChildScrollView(
            child: Padding(
              padding: MySpacing.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'product_category'.tr(),
                      style: TextStyle(
                        color: theme.colorScheme.onBackground,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      children: const [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  MySpacing.height(8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedCategoryId,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: MySpacing.xy(16, 14),
                          ),
                          items: categories.map((category) {
                            return DropdownMenuItem(
                              value: category.id,
                              child: Text(category.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedCategoryId = value);
                          },
                        ),
                      ),
                      MySpacing.width(12),
                      ElevatedButton(
                        onPressed: _showAddCategoryDialog,
                        style: ElevatedButton.styleFrom(
                          padding: MySpacing.xy(20, 14),
                        ),
                        child: MyText.bodyMedium(
                          'new_category'.tr(),
                          fontWeight: 600,
                        ),
                      ),
                    ],
                  ),

                  MySpacing.height(24),
                  RichText(
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
                  MySpacing.height(4),
                  MyText.bodySmall(
                    'Add detailed information for each variant.',
                    color: theme.colorScheme.onBackground.withOpacity(0.6),
                    fontSize: 11,
                  ),
                  MySpacing.height(12),
                  TextButton.icon(
                    onPressed: _showAddVariantDialog,
                    icon: const Icon(Icons.add),
                    label: MyText.bodyMedium('add_variant'.tr()),
                  ),
                  MySpacing.height(12),

                  if (_variants.isEmpty)
                    Container(
                      padding: MySpacing.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
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
                      return Container(
                        margin: MySpacing.bottom(8),
                        padding: MySpacing.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                          color: _variantKey(variant) == _defaultVariantKey
                              ? theme.colorScheme.primary.withOpacity(0.05)
                              : null,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Radio<String>(
                              value: _variantKey(variant),
                              groupValue: _defaultVariantKey,
                              onChanged: (value) {
                                setState(() {
                                  _defaultVariantKey = value;
                                });
                              },
                            ),
                            if (variant.imagePath.isNotEmpty)
                              Container(
                                margin: MySpacing.only(right: 12, top: 4),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: _variantThumbnail(variant.imagePath),
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      MyText.bodyMedium(
                                        variant.variantName,
                                        fontWeight: 600,
                                      ),
                                      if (_variantKey(variant) == _defaultVariantKey)
                                        Container(
                                          margin: MySpacing.only(left: 8),
                                          padding: MySpacing.xy(8, 4),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: MyText.bodySmall(
                                            'Default',
                                            color: theme.colorScheme.primary,
                                            fontWeight: 600,
                                          ),
                                        ),
                                    ],
                                  ),
                                  MySpacing.height(4),
                                  MyText.bodySmall(
                                    '${'selling_price'.tr()}: ${variant.sellingPrice.toStringAsFixed(2)} | ${'quantity'.tr()}: ${variant.quantity.toStringAsFixed(2)} ${variant.unit}',
                                    color: theme.colorScheme.onBackground.withOpacity(0.7),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _showAddVariantDialog(variant),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                  onPressed: () => _deleteVariant(variant),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                  MySpacing.height(24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProduct,
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
          );
        },
      ),
    );
  }
}
