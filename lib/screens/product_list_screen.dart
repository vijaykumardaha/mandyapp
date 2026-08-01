import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:krishimandi/blocs/product/product_bloc.dart';
import 'package:krishimandi/helpers/theme/app_theme.dart';
import 'package:krishimandi/models/product_model.dart';
import 'package:krishimandi/screens/product_detail_screen.dart';
import 'package:krishimandi/services/sync_service.dart';
import 'package:krishimandi/utils/app_helper.dart';
import 'package:krishimandi/utils/constants.dart';
import 'package:krishimandi/widgets/common/common_app_bar.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';
import 'package:krishimandi/widgets/product_list/product_card_widget.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late ThemeData theme;
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _isAdmin = true;
  StreamSubscription<String>? _syncSubscription;

  @override
  void dispose() {
    _syncSubscription?.cancel();
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
    _loadRole();
    context.read<ProductBloc>().add(LoadProducts());

    _syncSubscription = SyncService.instance.tableUpdates.listen((table) {
      if (!mounted) return;
      if (table == DbTables.products || table == DbTables.productVariants) {
        final state = context.read<ProductBloc>().state;
        if (state is ProductLoaded) {
          context.read<ProductBloc>().add(LoadProducts());
        }
      }
    });
  }

  Future<void> _loadRole() async {
    final user = await AppHelper.getCurrentUser();
    if (mounted) {
      setState(() {
        _isAdmin = user?.isAdmin ?? true;
      });
    }
  }

  void _navigateToProductDetail([Product? product]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );

    if (result == true) {
      if (!mounted) return;
      context.read<ProductBloc>().add(LoadProducts());
    }
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const MyText.titleMedium('Delete Product', fontWeight: 600),
        content: const MyText.bodyMedium(
            'Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const MyText.bodyMedium('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ProductBloc>().add(DeleteProduct(product.id!));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const MyText.bodyMedium('Delete', color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
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
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            prefixIcon: Icon(Icons.search,
                size: 20, color: theme.colorScheme.onSurfaceVariant),
            prefixIconConstraints: const BoxConstraints(minWidth: 36),
            suffixIcon: _isAdmin
                ? IconButton(
                    icon: Icon(Icons.add_box_outlined,
                        size: 20, color: theme.colorScheme.onSurfaceVariant),
                    tooltip: 'Add Product',
                    onPressed: () => _navigateToProductDetail(),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 40),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
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
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.3),
                            ),
                            MySpacing.height(16),
                            MyText.bodyLarge(
                              'No products found',
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                            MySpacing.height(4),
                            MyText.bodySmall(
                              'Try a different search, or add a new product',
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4),
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
                          isAdmin: _isAdmin,
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
      ),
    );
  }
}
