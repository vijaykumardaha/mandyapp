import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/order_item/order_item_bloc.dart';
import 'package:mandyapp/blocs/product/product_bloc.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/models/order_item_model.dart';
import 'package:mandyapp/models/product_model.dart';
import 'package:mandyapp/models/product_variant_model.dart';
import 'package:mandyapp/blocs/customer/customer_bloc.dart';
import 'package:mandyapp/widgets/selling/add_to_sale_bottom_sheet.dart';
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

  Widget _buildAlphabetFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16),
      child: Row(
        children: [
          _buildAlphabetTag('All', _selectedAlphabet == null),
          const SizedBox(width: 8),
          ...List.generate(26, (index) {
            final alphabet = String.fromCharCode(65 + index);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildAlphabetTag(alphabet, _selectedAlphabet == alphabet),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAlphabetTag(String alphabet, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAlphabet =
              isSelected ? null : (alphabet == 'All' ? null : alphabet);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Text(
          alphabet,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerGrid() {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, customerState) {
        final allCustomers = customerState is CustomerLoaded
            ? customerState.customers
            : <Customer>[];
        final isLoading = customerState is CustomerLoading;

        List<Customer> customers = allCustomers;
        if (_selectedAlphabet != null) {
          customers = allCustomers.where((customer) {
            final name = customer.name?.trim().toUpperCase() ?? '';
            return name.startsWith(_selectedAlphabet!);
          }).toList();
        }

        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (customers.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 56,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  MyText.bodyMedium(
                    'No customers found',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 6),
                  MyText.bodySmall(
                    'Add customers to get started',
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(10),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              final name = customer.name ?? 'Unnamed';
              final initials = name.length >= 2
                  ? name.substring(0, 2).toUpperCase()
                  : name.toUpperCase();
              return GestureDetector(
                onTap: () {
                  setState(() {
                    sellerCustomer = customer;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        child: MyText.bodySmall(
                          initials,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: 600,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            MyText.bodySmall(
                              name,
                              fontWeight: 600,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              fontSize: 12,
                            ),
                            if (customer.phone != null)
                              MyText.bodySmall(
                                customer.phone!,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 10,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }


  void _showAddToSaleBottomSheet(Product product) {
    if (sellerCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(top: 16, left: 16, right: 16),
          content: Text('Please select a customer before recording sales.'),
        ),
      );
      return;
    }

    final defaultVariant = product.defaultVariantModel;
    List<ProductVariant> variants =
        List<ProductVariant>.from(product.variants ?? <ProductVariant>[]);
    if (variants.isEmpty && defaultVariant != null) {
      variants = [defaultVariant];
    }

    if (variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(top: 16, left: 16, right: 16),
          content: Text('No variants available for this product.'),
        ),
      );
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(saleState.message),
              ),
            );
          }
        },
        child: sellerCustomer == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAlphabetFilter(),
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
