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
    context.read<OrderItemBloc>().add(const LoadOrderItems());
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      titleSpacing: 16,
      title: sellerCustomer != null
          ? GestureDetector(
              onTap: () {
                setState(() {
                  sellerCustomer = null;
                });
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Text(
                        sellerCustomer?.name != null
                            ? 'Selling of ${sellerCustomer!.name}'
                            : 'Select a seller',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.edit,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ],
                ),
              ),
            )
          : SizedBox(
              height: 36,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // "All" tag
                    _buildAlphabetTag('All', _selectedAlphabet == null),
                    const SizedBox(width: 8),
                    // A-Z tags
                    ...List.generate(26, (index) {
                      final alphabet = String.fromCharCode(65 + index); // A-Z
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildAlphabetTag(
                            alphabet, _selectedAlphabet == alphabet),
                      );
                    }),
                  ],
                ),
              ),
            ),
      actions: const [],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Text(
          alphabet,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
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

        // Filter customers by selected alphabet
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                MyText.bodyMedium(
                  'No customers found',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                MyText.bodySmall(
                  'Add customers to get started',
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    sellerCustomer = customer;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MyText.bodySmall(
                        customer.name ?? 'Unnamed',
                        fontWeight: 600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (customer.phone != null)
                        MyText.bodySmall(
                          customer.phone!,
                          color: theme.colorScheme.onSurfaceVariant,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  Widget _buildSheetFlashBanner(
      ThemeData sheetTheme, String message, VoidCallback onDismiss) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: sheetTheme.colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: sheetTheme.colorScheme.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: MyText.bodyMedium(
              message,
              fontWeight: 600,
              fontSize: 12,
              color: sheetTheme.colorScheme.onSurface,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            color: sheetTheme.colorScheme.onSurface.withOpacity(0.7),
            onPressed: onDismiss,
            padding: const EdgeInsets.all(2),
            splashRadius: 14,
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
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
      buyerOrderId: null,
      buyerId: null,
      productId: product.id ?? 0,
      variantId: variant.id!,
      buyingPrice: variant.buyingPrice,
      sellingPrice: effectiveSellingPrice,
      quantity: quantity,
      unit: variant.unit,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
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
            ? _buildCustomerGrid()
            : BlocBuilder<ProductBloc, ProductState>(
                builder: (context, productState) {
                  if (productState is ProductLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (productState is ProductLoaded) {
                    final products = productState.products;

                    if (products.isEmpty) {
                      return const Center(child: Text('No products found.'));
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1,
                        crossAxisSpacing: 5,
                        mainAxisSpacing: 5,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ProductCard(
                          product: product,
                          theme: theme,
                          onAddTapped: () => _showAddToSaleBottomSheet(product),
                        );
                      },
                    );
                  }

                  if (productState is ProductError) {
                    return Center(
                      child: Text(
                        productState.message,
                        style: TextStyle(color: theme.colorScheme.error),
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
