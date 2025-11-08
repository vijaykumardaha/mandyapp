import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/product/product_bloc.dart';
import 'package:mandyapp/blocs/item_sale/item_sale_bloc.dart';
import 'package:mandyapp/blocs/cart/cart_bloc.dart';
import 'package:mandyapp/helpers/extensions/string.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/dao/product_stock_dao.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/models/product_model.dart';
import 'package:mandyapp/models/product_variant_model.dart';
import 'package:mandyapp/blocs/customer/customer_bloc.dart';
import 'package:mandyapp/models/item_sale_model.dart';
import 'package:mandyapp/models/product_stock_model.dart';
import 'package:mandyapp/models/cart_model.dart';
import 'package:mandyapp/screens/checkout_screen.dart';
import 'package:mandyapp/utils/db_helper.dart';
import 'package:mandyapp/widgets/selling/add_to_sale_bottom_sheet.dart';
import 'package:mandyapp/widgets/selling/product_card.dart';
import 'package:mandyapp/widgets/selling/sale_selection_bottom_sheet.dart';

class SellingScreen extends StatefulWidget {
  const SellingScreen({super.key});

  @override
  State<SellingScreen> createState() => SellingScreenState();
}

class SellingScreenState extends State<SellingScreen> {
  late ThemeData theme;
  Customer? sellerCustomer;
  Customer? buyerCustomer;
  final ProductStockDAO _productStockDAO = ProductStockDAO();

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    context.read<ProductBloc>().add(LoadProducts());
    context.read<CustomerBloc>().add(const FetchCustomer(query: ''));
    context.read<ItemSaleBloc>().add(const LoadItemSales());
  }

  String? _sellerNameForSale(ItemSale sale) {
    final customerBlocState = context.read<CustomerBloc>().state;
    if (customerBlocState is! CustomerLoaded) {
      return null;
    }

    final seller = customerBlocState.customers.firstWhere(
      (customer) => customer.id == sale.sellerId,
      orElse: () => Customer(id: sale.sellerId, name: null),
    );

    return seller.name ?? 'Seller #${sale.sellerId}';
  }

  String _productTitleForSale(ItemSale sale) {
    final productBlocState = context.read<ProductBloc>().state;
    if (productBlocState is! ProductLoaded) {
      return 'Product #${sale.productId}';
    }

    final product = productBlocState.products.firstWhere(
      (element) => element.id == sale.productId,
      orElse: () => Product(
          id: sale.productId,
          categoryId: 0,
          defaultVariant: 0,
          variants: const <ProductVariant>[]),
    );

    final variants = product.variants;
    if (variants != null && variants.isNotEmpty) {
      final matchingVariant = variants.firstWhere(
        (variant) => variant.id == sale.variantId,
        orElse: () => product.defaultVariantModel ?? variants.first,
      );
      if (matchingVariant.variantName.isNotEmpty) {
        return matchingVariant.variantName;
      }
    } else {
      final defaultVariant = product.defaultVariantModel;
      if (defaultVariant != null && defaultVariant.variantName.isNotEmpty) {
        return defaultVariant.variantName;
      }
    }

    return 'Product #${sale.productId}';
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
          : _buildCustomerSearchField(),
      actions: const [],
    );
  }

  Widget _buildCustomerSearchField() {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, customerState) {
        final customers = customerState is CustomerLoaded
            ? customerState.customers
            : <Customer>[];
        final isLoading = customerState is CustomerLoading;

        return Container(
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
          child: Stack(
            children: [
              Autocomplete<Customer>(
                optionsBuilder: (textEditingValue) {
                  final query = textEditingValue.text.trim().toLowerCase();
                  if (query.isEmpty) {
                    return customers.take(15);
                  }
                  return customers.where((customer) {
                    final name = customer.name?.toLowerCase() ?? '';
                    final phone = customer.phone ?? '';
                    return name.contains(query) || phone.contains(query);
                  }).take(15);
                },
                displayStringForOption: _formatCustomer,
                fieldViewBuilder: (context, textEditingController, focusNode,
                    onFieldSubmitted) {
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Select seller name',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: textEditingController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                textEditingController.clear();
                                context
                                    .read<CustomerBloc>()
                                    .add(const FetchCustomer(query: ''));
                                setState(() {
                                  sellerCustomer = null;
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    onChanged: (value) {
                      context
                          .read<CustomerBloc>()
                          .add(FetchCustomer(query: value));
                    },
                    onSubmitted: (_) => onFieldSubmitted(),
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  );
                },
                onSelected: (customer) {
                  setState(() {
                    sellerCustomer = customer;
                  });
                  FocusScope.of(context).unfocus();
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxHeight: 220, minWidth: 280),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shrinkWrap: true,
                          itemCount: options.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: theme.colorScheme.outline.withOpacity(0.1),
                          ),
                          itemBuilder: (context, index) {
                            final customer = options.elementAt(index);
                            return ListTile(
                              dense: true,
                              onTap: () => onSelected(customer),
                              leading:
                                  const Icon(Icons.person_outline, size: 20),
                              title: MyText.bodySmall(
                                customer.name ?? 'Unnamed',
                                fontWeight: 600,
                              ),
                              subtitle: customer.phone != null
                                  ? MyText.bodySmall(
                                      customer.phone!,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    )
                                  : null,
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (isLoading)
                Positioned(
                  right: 12,
                  top: 12,
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary),
                    ),
                  ),
                ),
            ],
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

    final sellerLabel = sellerCustomer != null
        ? 'Seller : ${_formatCustomer(sellerCustomer)}'
        : null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return AddToSaleBottomSheet(
          variants: variants,
          sellerLabel: sellerLabel,
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
    if (sellerCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(top: 16, left: 16, right: 16),
          content: Text('Please select a customer before adding items.'),
        ),
      );
      return;
    }

    final sellerId = sellerCustomer!.id;
    if (sellerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(top: 16, left: 16, right: 16),
          content: Text('Selected customer is missing an identifier.'),
        ),
      );
      return;
    }

    ProductStock? stockRecord;
    if (variant.manageStock) {
      final productId = product.id;
      if (productId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(top: 16, left: 16, right: 16),
            content: Text(''),
          ),
        );
        return;
      }

      stockRecord = await _productStockDAO.getStockForVariant(
        productId: productId,
        variantId: variant.id!,
      );

      if (stockRecord == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(top: 16, left: 16, right: 16),
            content:
                Text('Product is missing an identifier for stock management.'),
          ),
        );
        return;
      }

      if (stockRecord.currentStock < quantity) {
        _showSnack(
              'Only ${stockRecord.currentStock.toStringAsFixed(2)} ${stockRecord.unit} left in stock.');
        return;
      }
    }

    final effectiveSellingPrice = overrideSellingPrice ?? variant.sellingPrice;
    final sale = ItemSale(
      stockId: stockRecord?.id,
      sellerId: sellerId,
      buyerCartId: null,
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

    context.read<ItemSaleBloc>().add(AddItemSaleEvent(sale));

    if (variant.manageStock && stockRecord != null) {
      final updatedStock = stockRecord.copyWith(
        currentStock: stockRecord.currentStock - quantity,
        lastUpdated: DateTime.now().toIso8601String(),
      );
      await _productStockDAO.upsertStock(updatedStock);
    }
  }

  List<ItemSale> _salesFromState(ItemSaleState state) {
    if (state is ItemSalesLoaded) {
      return state.sales;
    }
    return const [];
  }

  List<ItemSale> _currentSales() {
    final state = context.read<ItemSaleBloc>().state;
    return _salesFromState(state);
  }

  Future<List<ItemSale>?> _showSaleSelectionSheet(List<ItemSale> sales) async {
    final result = await showModalBottomSheet<List<ItemSale>>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SaleSelectionBottomSheet(
          initialSales: sales,
          buyerCustomer: buyerCustomer,
          onBuyerChanged: (customer) {
            setState(() {
              buyerCustomer = customer;
            });
          },
          formatCustomer: _formatCustomer,
          sellerNameForSale: _sellerNameForSale,
          productTitleForSale: _productTitleForSale,
          onDeleteSale: (sale, index) async {
            if (sale.id == null) {
              return false;
            }
            context.read<ItemSaleBloc>().add(DeleteItemSaleEvent(sale.id!));
            return true;
          },
          onCheckout: (sheetContext, selectedSales) async {
            final cartId = await _createNewCart(selectedSales);
            if (cartId == null || !mounted) {
              return;
            }
            Navigator.of(sheetContext).pop(selectedSales);
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CheckoutScreen(cartId: cartId),
              ),
            );
          },
          onClose: (sheetContext) {
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );

    return result;
  }

  Future<void> _showItemList() async {
    final selectedSales = await _pickSalesForCart();
    if (selectedSales == null) {
      return;
    }
  }

  Future<List<ItemSale>?> _pickSalesForCart() async {
    final sales = _currentSales();
    if (sales.isEmpty) {
      _showSnack('No sales to convert.');
      return null;
    }

    final selectedSales = await _showSaleSelectionSheet(sales);
    if (!mounted || selectedSales == null) {
      return null;
    }

    if (selectedSales.isEmpty) {
      _showSnack('Select at least one sale item.');
      return null;
    }

    return selectedSales;
  }

  Future<int?> _createNewCart(List<ItemSale> selectedSales) async {
    if (buyerCustomer == null) {
      _showSnack('Please select a buyer name before checkout.');
      return null;
    }

    if (selectedSales.isEmpty) {
      _showSnack('Select at least one sale item.');
      return null;
    }

    final cartBloc = context.read<CartBloc>();
    final itemSaleBloc = context.read<ItemSaleBloc>();
    final cartId = DBHelper.generateUuidInt();
    final timestamp = DateTime.now().toIso8601String();

    final cart = Cart(
      id: cartId,
      customerId: buyerCustomer!.id!,
      createdAt: timestamp,
      cartFor: 'buyer',
      status: 'open',
    );

    cartBloc.add(CreateCart(cart));

    for (final sale in selectedSales) {
      final originalSaleId = sale.id;
      final now = DateTime.now().toIso8601String();
      final cartLinkedSale = sale.copyWith(
        id: DBHelper.generateUuidInt(),
        buyerCartId: cartId,
        buyerId: buyerCustomer!.id!,
        createdAt: now,
        updatedAt: now,
      );
      cartBloc.add(AddItemToCart(cartLinkedSale));

      if (originalSaleId != null) {
        itemSaleBloc.add(DeleteItemSaleEvent(originalSaleId));
      }
    }

    return cartId;
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
        content: Text(message),
      ),
    );
  }

  String _formatCustomer(Customer? customer) {
    if (customer == null) {
      return '';
    }
    final name = customer.name?.trim() ?? '';
    final phone = customer.phone?.trim() ?? '';
    if (name.isNotEmpty && phone.isNotEmpty) {
      return '$name ($phone)';
    }
    if (name.isNotEmpty) {
      return name;
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: BlocListener<ItemSaleBloc, ItemSaleState>(
        listenWhen: (previous, current) => current is ItemSaleError,
        listener: (context, saleState) {
          if (saleState is ItemSaleError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text(saleState.message),
              ),
            );
          }
        },
        child: BlocBuilder<ProductBloc, ProductState>(
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                    onAddTapped: sellerCustomer == null
                        ? null
                        : () => _showAddToSaleBottomSheet(product),
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

      // Floating checkout button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: BlocBuilder<ItemSaleBloc, ItemSaleState>(
        builder: (context, saleState) {
          final sales = _salesFromState(saleState);
          if (sales.isEmpty) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: _showItemList,
            icon: const Icon(Icons.shopping_cart_checkout),
            label: Text('Sold Items (${sales.length})'),
          );
        },
      ),
    );
  }
}
