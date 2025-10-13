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
import 'package:mandyapp/utils/sync_vegetable.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product? product;
  
  const ProductDetailScreen({super.key, this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late ThemeData theme;
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  int? _selectedCategoryId;
  String? _imagePath;
  String? _selectedVegetableId;
  List<ProductVariant> _variants = [];
  final ProductVariantDAO _variantDAO = ProductVariantDAO();
  final ProductDAO _productDAO = ProductDAO();

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    context.read<CategoryBloc>().add(LoadCategories());

    // If editing existing product, populate fields
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _selectedCategoryId = widget.product!.categoryId;
      _imagePath = widget.product!.imagePath;
      _loadVariants();
    }
  }

  Future<void> _loadVariants() async {
    if (widget.product?.id != null) {
      final variants = await _variantDAO.getVariantsByProductId(widget.product!.id!);
      setState(() {
        _variants = variants;
      });
    }
  }

  void _onVegetableSelected(String? vegetableKey) {
    if (vegetableKey != null) {
      final vegetable = SyncVegetable.getVegetableByKey(vegetableKey);
      if (vegetable != null) {
        setState(() {
          _selectedVegetableId = vegetableKey;
          _nameController.text = vegetable['name'];
          _imagePath = vegetable['path'];
        });
      }
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
                  SnackBar(content: Text('please_enter_category_name'.tr())),
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
    final nameController = TextEditingController(text: variant?.variantName);
    final costPriceController = TextEditingController(text: variant?.costPrice.toString() ?? '');
    final sellingPriceController = TextEditingController(text: variant?.sellingPrice.toString() ?? '');
    final quantityController = TextEditingController(text: variant?.quantity.toString() ?? '');
    String selectedUnit = variant?.unit ?? 'Kg';
    String? selectedVegetableKey;
    String? variantImagePath = variant?.imagePath;

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
                // Vegetable Image Selector
                MyText.bodyMedium('select_vegetable_image'.tr(), fontWeight: 500),
                MySpacing.height(8),
                DropdownButtonFormField<String>(
                  value: selectedVegetableKey,
                  decoration: InputDecoration(
                    hintText: 'choose_vegetable'.tr(),
                    border: const OutlineInputBorder(),
                    contentPadding: MySpacing.xy(12, 10),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('no_image'.tr()),
                    ),
                    ...SyncVegetable.vegetables.map((veg) {
                      return DropdownMenuItem<String>(
                        value: veg['key'],
                        child: Row(
                          children: [
                            if (veg['path'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.asset(
                                  veg['path'],
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.image_not_supported, size: 24);
                                  },
                                ),
                              ),
                            MySpacing.width(8),
                            Text(veg['name']),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedVegetableKey = value;
                      if (value != null) {
                        final vegetable = SyncVegetable.getVegetableByKey(value);
                        variantImagePath = vegetable?['path'];
                      } else {
                        variantImagePath = null;
                      }
                    });
                  },
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
                  controller: costPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'cost_price'.tr(),
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
                if (sellingPriceController.text.isEmpty || quantityController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('please_fill_required_fields'.tr())),
                  );
                  return;
                }

                final newVariant = ProductVariant(
                  id: variant?.id,
                  productId: widget.product?.id ?? 0,
                  variantName: nameController.text.isEmpty ? null : nameController.text,
                  costPrice: double.tryParse(costPriceController.text) ?? 0.0,
                  sellingPrice: double.parse(sellingPriceController.text),
                  quantity: double.parse(quantityController.text),
                  unit: selectedUnit,
                  imagePath: variantImagePath,
                );

                setState(() {
                  if (variant == null) {
                    _variants.add(newVariant);
                  } else {
                    final index = _variants.indexOf(variant);
                    if (index != -1) {
                      _variants[index] = newVariant;
                    }
                  }
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
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('please_select_category'.tr())),
      );
      return;
    }

    if (_variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('please_add_at_least_one_variant'.tr())),
      );
      return;
    }

    final product = Product(
      id: widget.product?.id,
      name: _nameController.text,
      categoryId: _selectedCategoryId!,
      imagePath: _imagePath,
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
      for (var variant in _variants) {
        variant.productId = productId;
        await _variantDAO.insertVariant(variant);
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
                child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vegetable Dropdown
                        MyText.bodyMedium('select_vegetable'.tr(), fontWeight: 500),
                        MySpacing.height(8),
                        DropdownButtonFormField<String>(
                          value: _selectedVegetableId,
                          decoration: InputDecoration(
                            hintText: 'choose_vegetable'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: MySpacing.xy(16, 14),
                          ),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text('custom_product'.tr()),
                            ),
                            ...SyncVegetable.vegetables.map((veg) {
                              return DropdownMenuItem<String>(
                                value: veg['key'],
                                child: Row(
                                  children: [
                                    if (veg['path'] != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.asset(
                                          veg['path'],
                                          width: 30,
                                          height: 30,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(Icons.image_not_supported, size: 30);
                                          },
                                        ),
                                      ),
                                    MySpacing.width(12),
                                    Text(veg['name']),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: _onVegetableSelected,
                        ),
                        
                        MySpacing.height(16),
                        
                        // Product Name
                        RichText(
                          text: TextSpan(
                            text: 'product_name'.tr(),
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
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'enter_product_name'.tr(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: MySpacing.xy(16, 14),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'please_enter_product_name'.tr();
                            }
                            return null;
                          },
                        ),
                        
                        MySpacing.height(16),
                        
                        // Product Category
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
                        
                        // Product Variants Section (At least one required)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                  'at_least_one_variant_required'.tr(),
                                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                                  fontSize: 11,
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: _showAddVariantDialog,
                              icon: const Icon(Icons.add),
                              label: MyText.bodyMedium('add_variant'.tr()),
                            ),
                          ],
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
                              ),
                              child: Row(
                                children: [
                                  // Variant Image
                                  if (variant.imagePath != null)
                                    Container(
                                      margin: MySpacing.right(12),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.asset(
                                          variant.imagePath!,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 50,
                                              height: 50,
                                              color: theme.colorScheme.surfaceVariant,
                                              child: Icon(
                                                Icons.image_not_supported,
                                                size: 24,
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (variant.variantName != null)
                                          MyText.bodyMedium(
                                            variant.variantName!,
                                            fontWeight: 600,
                                          ),
                                        MySpacing.height(4),
                                        MyText.bodySmall(
                                          '${'selling_price'.tr()}: ${variant.sellingPrice} | ${'quantity'.tr()}: ${variant.quantity} ${variant.unit}',
                                          color: theme.colorScheme.onBackground.withOpacity(0.7),
                                        ),
                                      ],
                                    ),
                                  ),
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
                            );
                          }),
                        
                        MySpacing.height(24),
                        
                        // Save Button
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
                ),
              );
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
