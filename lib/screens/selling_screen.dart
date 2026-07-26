import 'package:flutter/material.dart';
import 'package:mandyapp/utils/info_controller.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/order_item/order_item_bloc.dart';
import 'package:mandyapp/blocs/product/product_bloc.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/widgets/common/my_text.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/models/order_item_model.dart';
import 'package:mandyapp/models/product_model.dart';
import 'package:mandyapp/models/product_variant_model.dart';
import 'package:mandyapp/blocs/customer/customer_bloc.dart';
import 'package:mandyapp/widgets/selling/add_to_sale_bottom_sheet.dart';
import 'package:mandyapp/widgets/selling/alphabet_filter.dart' as extracted;
import 'package:mandyapp/widgets/selling/customer_grid.dart';
import 'package:mandyapp/widgets/selling/product_card.dart';

class SellingScreen extends StatefulWidget {
  const SellingScreen({super.key});

  @override
  State<SellingScreen> createState() => SellingScreenState();
}

class SellingScreenState extends State<SellingScreen> {
  late ThemeData theme;
  Customer? sellerCustomer;
  Customer? buyerCustomer;
  String? _selectedAlphabet;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    context.read<ProductBloc>().add(LoadProducts());
    context.read<CustomerBloc>().add(const FetchCustomer(query: ''));
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(sellerCustomer != null ? 'Selling to ${sellerCustomer!.name}' : 'Select Seller'),
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
      selectedAlphabet: _selectedAlphabet,
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
      body: BlocListener<OrderItemBloc, OrderItemState>(
        listenWhen: (previous, current) => current is OrderItemError,
        listener: (context, saleState) {
          if (saleState is OrderItemError) {
            Info.error(saleState.message, context: context);
          }
        },
        child: sellerCustomer == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  extracted.AlphabetFilter(
                    onAlphabetSelected: (alphabet) {
                      setState(() {
                        _selectedAlphabet = alphabet;
                      });
                    },
                  ),
                  Expanded(child: _buildCustomerGrid()),
                ],
              )
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
    );
  }
}
