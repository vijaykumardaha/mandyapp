import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mandiapp/utils/info_controller.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandiapp/blocs/order_item/order_item_bloc.dart';
import 'package:mandiapp/blocs/product/product_bloc.dart';
import 'package:mandiapp/helpers/theme/app_theme.dart';
import 'package:mandiapp/services/sync_service.dart';
import 'package:mandiapp/widgets/common/common_app_bar.dart';
import 'package:mandiapp/widgets/common/my_text.dart';
import 'package:mandiapp/models/customer_model.dart';
import 'package:mandiapp/models/order_item_model.dart';
import 'package:mandiapp/models/product_model.dart';
import 'package:mandiapp/models/product_variant_model.dart';
import 'package:mandiapp/blocs/customer/customer_bloc.dart';
import 'package:mandiapp/widgets/selling/add_to_sale_bottom_sheet.dart';
import 'package:mandiapp/widgets/selling/customer_grid.dart';
import 'package:mandiapp/widgets/selling/product_card.dart';

class SellingScreen extends StatefulWidget {
  const SellingScreen({super.key});

  @override
  State<SellingScreen> createState() => SellingScreenState();
}

class SellingScreenState extends State<SellingScreen> {
  late ThemeData theme;
  Customer? sellerCustomer;
  Customer? buyerCustomer;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final List<StreamSubscription<String>> _syncSubscriptions = [];

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    context.read<ProductBloc>().add(LoadProducts());
    context.read<CustomerBloc>().add(const FetchCustomer(query: ''));

    _syncSubscriptions.add(SyncService.instance.tableUpdates.listen((table) {
      if (!mounted) return;
      if (table == 'products' || table == 'product_variants') {
        final state = context.read<ProductBloc>().state;
        if (state is ProductLoaded) {
          context.read<ProductBloc>().add(LoadProducts());
        }
      }
      if (table == 'customers') {
        final state = context.read<CustomerBloc>().state;
        if (state is CustomerLoaded) {
          context.read<CustomerBloc>().add(const FetchCustomer(query: ''));
        }
      }
      if (table == 'order_items') {
        final state = context.read<OrderItemBloc>().state;
        if (state is OrderItemsLoaded) {
          context.read<OrderItemBloc>().add(const LoadAllUnlinkedOrderItems());
        }
      }
    }));
  }

  @override
  void dispose() {
    for (final sub in _syncSubscriptions) {
      sub.cancel();
    }
    _searchController.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return CommonAppBar(
      titleWidget: sellerCustomer != null
          ? Text(
              'Selling to ${sellerCustomer!.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            )
          : TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Search seller...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
      actions: [
        if (sellerCustomer != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Change Customer',
              onPressed: () {
                setState(() {
                  sellerCustomer = null;
                });
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCustomerGrid() {
    return CustomerGrid(
      searchQuery: _searchQuery,
      onCustomerSelected: (customer) {
        setState(() {
          sellerCustomer = customer;
        });
      },
    );
  }


  void _showAddToSaleBottomSheet(Product product) {
    if (sellerCustomer == null) {
      Info.message('Please select a customer before recording sales.', context: context);
      return;
    }

    final defaultVariant = product.defaultVariantModel;
    List<ProductVariant> variants =
        List<ProductVariant>.from(product.variants ?? <ProductVariant>[]);
    if (variants.isEmpty && defaultVariant != null) {
      variants = [defaultVariant];
    }

    if (variants.isEmpty) {
      Info.message('No variants available for this product.', context: context);
      return;
    }

    FocusScope.of(context).unfocus();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // removes top radius
      ),
      builder: (sheetContext) {
        return AddToSaleBottomSheet(
          variants: variants,
          onSubmit: (variant, quantity, rate) async {
            await _submitCartItem(
              product,
              variant,
              quantity: quantity,
              overrideSellingPrice: rate,
            );
          },
        );
      },
    );
  }

  Future<void> _submitCartItem(
    Product product,
    ProductVariant variant, {
    required double quantity,
    double? overrideSellingPrice,
  }) async {

    final effectiveSellingPrice = overrideSellingPrice ?? variant.sellingPrice;
    final sale = OrderItem(
      sellerId: sellerCustomer!.id!,
      sellerName: sellerCustomer!.name,
      buyerOrderId: null,
      buyerId: null,
      productId: product.id ?? 0,
      variantId: variant.id!,
      sellingPrice: effectiveSellingPrice,
      quantity: quantity,
      unit: variant.unit,
      productName: variant.variantName,
      imagePath: variant.imagePath,
    );

    context.read<OrderItemBloc>().add(AddOrderItemEvent(sale));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: BlocListener<OrderItemBloc, OrderItemState>(
          listenWhen: (previous, current) => current is OrderItemError,
          listener: (context, saleState) {
            if (saleState is OrderItemError) {
              Info.error(saleState.message, context: context);
            }
          },
          child: sellerCustomer == null
              ? _buildCustomerGrid()
              : BlocBuilder<ProductBloc, ProductState>(
                  builder: (context, productState) {
                    if (productState is ProductLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
  
                    if (productState is ProductLoaded) {
                      var products = productState.products;
                      final customerProductIds = sellerCustomer!.selectedProductIds;
                      if (customerProductIds.isNotEmpty) {
                        products = products
                            .where((p) => customerProductIds.contains(p.id))
                            .toList();
                      }
  
                      if (products.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 56,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                MyText.bodyMedium(
                                  'No products found',
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 6),
                                MyText.bodySmall(
                                  'Add products to start selling',
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
  
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 1,
                          crossAxisSpacing: 5,
                          mainAxisSpacing: 5,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ProductCard(
                            product: product,
                            theme: Theme.of(context),
                            onAddTapped: () => _showAddToSaleBottomSheet(product),
                          );
                        },
                      );
                    }
  
                    if (productState is ProductError) {
                      return Center(
                        child: Text(
                          productState.message,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      );
                    }
  
                    return const SizedBox.shrink();
                  },
                ),
        ),
      ),
    );
  }
}
