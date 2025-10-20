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
import 'package:mandyapp/screens/product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late ThemeData theme;
  int? _selectedCategoryId;

  Widget _buildVariantImage(String imagePath) {
    final placeholder = Icon(
      Icons.inventory_2,
      size: 32,
      color: theme.colorScheme.onSurfaceVariant,
    );

    if (imagePath.isEmpty) {
      return placeholder;
    }

    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    }

    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    context.read<ProductBloc>().add(LoadProducts());
    context.read<CategoryBloc>().add(LoadCategories());
  }

  void _navigateToProductDetail([Product? product]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
    
    if (result == true) {
      context.read<ProductBloc>().add(LoadProducts());
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
            border: const OutlineInputBorder(),
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

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: MyText.titleMedium('delete_product'.tr(), fontWeight: 600),
        content: MyText.bodyMedium('are_you_sure_delete_product'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: MyText.bodyMedium('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ProductBloc>().add(DeleteProduct(product.id!));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: MyText.bodyMedium('delete'.tr(), color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyText.titleMedium('products'.tr(), fontWeight: 600),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: _showAddCategoryDialog,
            tooltip: 'add_category'.tr(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToProductDetail(),
            tooltip: 'add_product'.tr(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, categoryState) {
              if (categoryState is CategoryLoaded && categoryState.categories.isNotEmpty) {
                return Container(
                  height: 50,
                  padding: MySpacing.x(16),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCategoryChip('all'.tr(), null, categoryState.categories),
                      ...categoryState.categories.map((category) =>
                          _buildCategoryChip(category.name, category.id, categoryState.categories)),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          // Product List
          Expanded(
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, productState) {
                if (productState is ProductLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (productState is ProductLoaded) {
                  if (productState.products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: theme.colorScheme.onBackground.withOpacity(0.3),
                          ),
                          MySpacing.height(16),
                          MyText.bodyLarge(
                            'no_products_found'.tr(),
                            color: theme.colorScheme.onBackground.withOpacity(0.6),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return BlocBuilder<CategoryBloc, CategoryState>(
                    builder: (context, categoryState) {
                      final categoryMap = <int, String>{};
                      if (categoryState is CategoryLoaded) {
                        for (var category in categoryState.categories) {
                          if (category.id != null) {
                            categoryMap[category.id!] = category.name;
                          }
                        }
                      }
                      return ListView.builder(
                        padding: MySpacing.all(16),
                        itemCount: productState.products.length,
                        itemBuilder: (context, index) {
                          final product = productState.products[index];
                          return _buildProductCard(product, categoryMap);
                        },
                      );
                    },
                  );
                } else if (productState is ProductError) {
                  return Center(
                    child: MyText.bodyMedium(productState.message),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, int? categoryId, List<Category> categories) {
    final isSelected = _selectedCategoryId == categoryId;
    return Padding(
      padding: MySpacing.right(8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategoryId = selected ? categoryId : null;
          });
          if (_selectedCategoryId == null) {
            context.read<ProductBloc>().add(LoadProducts());
          } else {
            context.read<ProductBloc>().add(LoadProductsByCategory(_selectedCategoryId!));
          }
        },
        selectedColor: theme.colorScheme.primary.withOpacity(0.2),
        checkmarkColor: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildProductCard(Product product, Map<int, String> categoryMap) {
    final categoryName = categoryMap[product.categoryId] ?? 'unknown'.tr();
    final variantCount = product.variantCount;
    final defaultVariant = product.defaultVariantModel;
    final variants = product.variants ?? [];
    
    return Card(
      margin: MySpacing.bottom(12),
      child: InkWell(
        onTap: () => _navigateToProductDetail(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: MySpacing.all(16),
          child: Row(
            children: [
              // Product Image or Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: defaultVariant != null && defaultVariant.imagePath.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildVariantImage(defaultVariant.imagePath),
                      )
                    : Center(
                        child: Icon(
                          Icons.inventory_2,
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                      ),
              ),
              MySpacing.width(16),
              
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category and Name in one row
                    Row(
                      children: [
                        Container(
                          padding: MySpacing.xy(8, 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: MyText.bodySmall(
                            categoryName,
                            fontSize: 10,
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: 600,
                          ),
                        ),
                        MySpacing.width(8),
                        Expanded(
                          child: MyText.bodyLarge(
                            defaultVariant?.variantName ?? 'Product #${product.id ?? ''}',
                            fontWeight: 600,
                          ),
                        ),
                      ],
                    ),
                    MySpacing.height(8),
                    Row(
                      children: [
                        Container(
                          padding: MySpacing.xy(8, 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory,
                                size: 14,
                                color: theme.colorScheme.onTertiaryContainer,
                              ),
                              MySpacing.width(4),
                              MyText.bodySmall(
                                '$variantCount ${'variants'.tr()}',
                                fontSize: 11,
                                color: theme.colorScheme.onTertiaryContainer,
                                fontWeight: 600,
                              ),
                            ],
                          ),
                        ),
                        if (variantCount > 0 && variants.isNotEmpty) ...[
                          MySpacing.width(12),
                          Expanded(
                            child: MyText.bodySmall(
                              variants.take(2).map((variant) =>
                                '₹${variant.sellingPrice.toStringAsFixed(0)} (${variant.quantity}${variant.unit})'
                              ).join(', ') + (variants.length > 2 ? '...' : ''),
                              color: theme.colorScheme.onBackground.withOpacity(0.6),
                              fontSize: 11,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (defaultVariant != null) ...[
                          MySpacing.height(8),
                          MyText.bodyMedium(
                            '₹${defaultVariant.sellingPrice.toStringAsFixed(0)}',
                            fontWeight: 600,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _deleteProduct(product),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
