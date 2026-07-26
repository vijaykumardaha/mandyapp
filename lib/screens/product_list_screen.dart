import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/product/product_bloc.dart';
import 'package:mandyapp/helpers/extensions/string.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/widgets/common/my_spacing.dart';
import 'package:mandyapp/widgets/common/my_text.dart';
import 'package:mandyapp/models/product_model.dart';
import 'package:mandyapp/screens/product_detail_screen.dart';
import 'package:mandyapp/widgets/product_list/product_card_widget.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late ThemeData theme;
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<ProductBloc>().add(SearchProducts(query.trim()));
    });
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
        automaticallyImplyLeading: false,
        title: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search products...',
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            prefixIcon: Icon(Icons.search, size: 20, color: theme.colorScheme.onSurfaceVariant),
            prefixIconConstraints: const BoxConstraints(minWidth: 36),
            suffixIcon: IconButton(
              icon: Icon(Icons.add_box_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
              tooltip: 'add_product'.tr(),
              onPressed: () => _navigateToProductDetail(),
            ),
            suffixIconConstraints: const BoxConstraints(minWidth: 40),
          ),
        ),
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
                      return ProductCardWidget(
                        product: product,
                        theme: theme,
                        onEdit: () => _navigateToProductDetail(product),
                        onDelete: () => _deleteProduct(product),
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
}
