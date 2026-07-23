import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/product/product_bloc.dart';
import 'package:mandyapp/helpers/extensions/string.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/product_model.dart';
import 'package:mandyapp/screens/product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late ThemeData theme;

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

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: MyText.titleMedium('delete_product'.tr(), fontWeight: 600),
        content: MyText.bodyMedium('are_you_sure_delete_product'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: MyText.bodyMedium('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ProductBloc>().add(DeleteProduct(product.id!));
              Navigator.pop(dialogContext);
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
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToProductDetail(),
            tooltip: 'add_product'.tr(),
          ),
        ],
      ),
      body: Column(
        children: [
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

                  return ListView.builder(
                    padding: MySpacing.all(16),
                    itemCount: productState.products.length,
                    itemBuilder: (context, index) {
                      final product = productState.products[index];
                      return _buildProductCard(product);
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

  Widget _buildProductCard(Product product) {
    final variantCount = product.variantCount;
    final defaultVariant = product.defaultVariantModel;
    final variants = product.variants ?? [];

    return Card(
      margin: MySpacing.bottom(12),
      child: Padding(
        padding: MySpacing.all(16),
        child: Row(
          children: [
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
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
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (value) {
                if (value == 'edit') {
                  _navigateToProductDetail(product);
                } else if (value == 'delete') {
                  _deleteProduct(product);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit, size: 20),
                      MySpacing.width(8),
                      MyText.bodyMedium('edit'.tr()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, size: 20, color: Colors.red),
                      MySpacing.width(8),
                      MyText.bodyMedium('delete'.tr(), color: Colors.red),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
