import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/product/product_bloc.dart';
import 'package:mandyapp/blocs/item_sale/item_sale_bloc.dart';
import 'package:mandyapp/blocs/category/category_bloc.dart';
import 'package:mandyapp/blocs/cart/cart_bloc.dart';
import 'package:mandyapp/helpers/extensions/string.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/models/product_model.dart';
import 'package:mandyapp/models/product_variant_model.dart';
import 'package:mandyapp/blocs/customer/customer_bloc.dart';
import 'package:mandyapp/models/item_sale_model.dart';
import 'package:mandyapp/models/cart_model.dart';
import 'package:mandyapp/utils/db_helper.dart';

class SellingScreen extends StatefulWidget {
  const SellingScreen({super.key});

  @override
  State<SellingScreen> createState() => SellingScreenState();
}

class _VerticalStepper extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  final double step;
  final double minValue;

  const _VerticalStepper({
    required this.controller,
    required this.onChanged,
    this.step = 1,
    this.minValue = 0,
  });

  void _adjust(bool increment) {
    final current = double.tryParse(controller.text.trim()) ?? 0;
    double nextValue = increment ? current + step : current - step;
    if (nextValue < minValue) nextValue = minValue;
    controller.text = nextValue == nextValue.truncateToDouble()
        ? nextValue.toStringAsFixed(0)
        : nextValue.toStringAsFixed(2);
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    return SizedBox(
      width: 36,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.keyboard_arrow_up,
            color: color,
            onTap: () => _adjust(true),
          ),
          const SizedBox(height: 2),
          _StepperButton(
            icon: Icons.keyboard_arrow_down,
            color: color,
            onTap: () => _adjust(false),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _StepperButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        height: 18,
        width: 32,
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class SellingScreenState extends State<SellingScreen> {
  static const int _defaultCustomerId = 1;
  late ThemeData theme;
  int? _selectedCategoryId;
  Customer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    context.read<ProductBloc>().add(LoadProducts());
    context.read<CategoryBloc>().add(LoadCategories());
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

  String? _variantNameForSale(ItemSale sale) {
    final productBlocState = context.read<ProductBloc>().state;
    if (productBlocState is! ProductLoaded) {
      return null;
    }

    final product = productBlocState.products.firstWhere(
      (element) => element.id == sale.productId,
      orElse: () => Product(id: sale.productId, categoryId: 0, defaultVariant: 0, variants: const <ProductVariant>[]),
    );

    final variants = product.variants;
    if (variants == null || variants.isEmpty) {
      return product.defaultVariantModel?.variantName;
    }

    for (final variant in variants) {
      if (variant.id == sale.variantId) {
        return variant.variantName;
      }
    }

    return product.defaultVariantModel?.variantName ?? variants.first.variantName;
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      titleSpacing: 16,
      title: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: _buildCustomerSearchField(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filter Categories',
          onPressed: showCategoryFilterDialog,
        ),
      ],
    );
  }

  Widget _buildCustomerSearchField() {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, customerState) {
        final customers = customerState is CustomerLoaded ? customerState.customers : <Customer>[];
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
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: textEditingController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                textEditingController.clear();
                                context.read<CustomerBloc>().add(const FetchCustomer(query: ''));
                                setState(() {
                                  _selectedCustomer = null;
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (value) {
                      context.read<CustomerBloc>().add(FetchCustomer(query: value));
                    },
                    onSubmitted: (_) => onFieldSubmitted(),
                  );
                },
                onSelected: (customer) {
                  setState(() {
                    _selectedCustomer = customer;
                  });
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220, minWidth: 280),
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
                              leading: const Icon(Icons.person_outline, size: 20),
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
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _productTitle(Product product) {
    return product.defaultVariantModel?.variantName ?? 'Product #${product.id ?? ''}';
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Icon(
        Icons.inventory_2,
        size: 32,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildVariantImage(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
      );
    }
    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
    );
  }

  void _showAddToSaleBottomSheet(Product product) {
    if (_selectedCustomer == null) {
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
    List<ProductVariant> variants = List<ProductVariant>.from(product.variants ?? <ProductVariant>[]);
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final quantityControllers = <int, TextEditingController>{};
        final rateControllers = <int, TextEditingController>{};

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedCustomer != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MyText.bodySmall(
                        'Seller : ${_formatCustomer(_selectedCustomer)}',
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 360),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: variants.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final variant = variants[index];
                        final hasDiscount = variant.buyingPrice > variant.sellingPrice;
                        final savings = hasDiscount ? variant.buyingPrice - variant.sellingPrice : 0;
                        final variantKey = variant.id ?? (-index - 1);
                        final qtyController = quantityControllers.putIfAbsent(
                          variantKey,
                          () => TextEditingController(
                            text: variant.quantity
                                .toStringAsFixed(variant.quantity % 1 == 0 ? 0 : 2)
                                .replaceFirst(RegExp(r'\.0+'), ''),
                          ),
                        );
                        final rateController = rateControllers.putIfAbsent(
                          variantKey,
                          () => TextEditingController(text: variant.sellingPrice.toStringAsFixed(2)),
                        );

                        double _computeTotal() {
                          final quantity = double.tryParse(qtyController.text.trim()) ?? 0;
                          final rate = double.tryParse(rateController.text.trim()) ?? 0;
                          return quantity * rate;
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (index > 0)
                              Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (hasDiscount)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: MyText.bodySmall(
                                        'Save ₹${savings.toStringAsFixed(0)}',
                                        fontWeight: 700,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: SizedBox(
                                              height: 52,
                                              width: 52,
                                              child: variant.imagePath.isNotEmpty
                                                  ? _buildVariantImage(variant.imagePath)
                                                  : Container(
                                                      color: theme.colorScheme.surfaceVariant,
                                                      child: _buildImagePlaceholder(),
                                                    ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.45),
                                                borderRadius: const BorderRadius.only(
                                                  bottomLeft: Radius.circular(10),
                                                  bottomRight: Radius.circular(10),
                                                ),
                                              ),
                                              child: MyText.bodySmall(
                                                variant.variantName,
                                                color: Colors.white,
                                                fontWeight: 700,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Flexible(
                                                  flex: 3,
                                                  child: TextField(
                                                    controller: qtyController,
                                                    enabled: variant.id != null,
                                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                    decoration: InputDecoration(
                                                      labelText: 'Qty (${variant.unit})',
                                                      border: const OutlineInputBorder(),
                                                      isDense: true,
                                                      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                                      suffixIcon: _VerticalStepper(
                                                        controller: qtyController,
                                                        onChanged: () => setSheetState(() {}),
                                                        step: 1,
                                                        minValue: 0,
                                                      ),
                                                      suffixIconConstraints: const BoxConstraints(minWidth: 36, maxWidth: 36),
                                                    ),
                                                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                                    onChanged: (_) => setSheetState(() {}),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Flexible(
                                                  flex: 4,
                                                  child: TextField(
                                                    controller: rateController,
                                                    enabled: variant.id != null,
                                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                    decoration: InputDecoration(
                                                      labelText: 'Rate',
                                                      border: const OutlineInputBorder(),
                                                      isDense: true,
                                                      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                                      suffixIcon: _VerticalStepper(
                                                        controller: rateController,
                                                        onChanged: () => setSheetState(() {}),
                                                        step: 0.1,
                                                        minValue: 0,
                                                      ),
                                                      suffixIconConstraints: const BoxConstraints(minWidth: 36, maxWidth: 36),
                                                    ),
                                                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                                    onChanged: (_) => setSheetState(() {}),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                ConstrainedBox(
                                                  constraints: const BoxConstraints(minWidth: 72),
                                                  child: OutlinedButton(
                                                    onPressed: variant.id == null
                                                        ? null
                                                        : () {
                                                          final quantity = double.tryParse(qtyController.text.trim());
                                                          if (quantity == null || quantity <= 0) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(
                                                                behavior: SnackBarBehavior.floating,
                                                                margin: EdgeInsets.only(top: 16, left: 16, right: 16),
                                                                content: Text('Enter a valid quantity.'),
                                                              ),
                                                            );
                                                            return;
                                                          }
                                                          final rate = double.tryParse(rateController.text.trim());
                                                          if (rate == null || rate <= 0) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(
                                                                behavior: SnackBarBehavior.floating,
                                                                margin: EdgeInsets.only(top: 16, left: 16, right: 16),
                                                                content: Text('Enter a valid rate.'),
                                                              ),
                                                            );
                                                            return;
                                                          }
                                                          _submitCartItem(
                                                            product,
                                                            variant,
                                                            quantity: quantity,
                                                            overrideSellingPrice: rate,
                                                          );
                                                        },
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: theme.colorScheme.primary,
                                                      side: BorderSide(color: theme.colorScheme.primary, width: 1.4),
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                                                    ),
                                                    child: Text('ADD (₹${_computeTotal().toStringAsFixed(2)})'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
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
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(top: 16, left: 16, right: 16),
          content: Text('Please select a customer before adding items.'),
        ),
      );
      return;
    }

    final sellerId = _selectedCustomer!.id;
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

    final effectiveSellingPrice = overrideSellingPrice ?? variant.sellingPrice;
    final sale = ItemSale(
      sellerId: sellerId,
      buyerCartId: null,
      buyerId: sellerId,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
        content: Text('${variant.variantName} recorded in sales.'),
      ),
    );
  }

  List<ItemSale> _salesFromState(ItemSaleState state) {
    if (state is ItemSalesLoaded) {
      return state.sales;
    }
    if (state is ItemSaleOperationSuccess) {
      return state.sales;
    }
    return const [];
  }

  List<ItemSale> _currentSales() {
    final state = context.read<ItemSaleBloc>().state;
    return _salesFromState(state);
  }

  Future<List<ItemSale>?> _showSaleSelectionSheet(List<ItemSale> sales) async {
    final saleList = sales.toList(growable: true);
    final selectedIndices = saleList.asMap().keys.toSet();
    final itemSaleBloc = context.read<ItemSaleBloc>();

    return showModalBottomSheet<List<ItemSale>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        MyText.titleMedium('Select sales items for checkout', fontWeight: 700),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    MySpacing.height(12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 380),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: saleList.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final sale = saleList[index];
                          final isChecked = selectedIndices.contains(index);
                          final variantName = _variantNameForSale(sale);
                          final sellerName = _sellerNameForSale(sale);
                          final quantityLabel =
                              '${sale.quantity.toStringAsFixed(sale.quantity % 1 == 0 ? 0 : 2)} ${sale.unit}';
                          final subtitle = [
                            if (variantName != null) 'Variant: $variantName',
                            if (sellerName != null) 'Seller: $sellerName',
                          ].join(' • ');
                          final titleText = variantName ?? 'Product #${sale.productId}';

                          return CheckboxListTile(
                            value: isChecked,
                            onChanged: (value) {
                              setSheetState(() {
                                if (value == true) {
                                  selectedIndices.add(index);
                                } else {
                                  selectedIndices.remove(index);
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                            title: MyText.bodyMedium(
                              titleText,
                              fontWeight: 600,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (subtitle.isNotEmpty)
                                  MyText.bodySmall(
                                    subtitle,
                                  ),
                                MySpacing.height(4),
                                MyText.bodySmall(
                                  'Qty: $quantityLabel    Rate: ₹${sale.sellingPrice.toStringAsFixed(2)}    Total: ₹${sale.totalPrice.toStringAsFixed(2)}',
                                  fontWeight: 600,
                                ),
                              ],
                            ),
                            secondary: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              color: theme.colorScheme.error,
                              tooltip: 'Delete sale',
                              onPressed: sale.id == null
                                  ? null
                                  : () {
                                      itemSaleBloc.add(DeleteItemSaleEvent(sale.id!));
                                      setSheetState(() {
                                        saleList.removeAt(index);

                                        final updatedIndices = <int>{};
                                        for (final selectedIndex in selectedIndices) {
                                          if (selectedIndex == index) {
                                            continue;
                                          }
                                          updatedIndices.add(
                                            selectedIndex > index ? selectedIndex - 1 : selectedIndex,
                                          );
                                        }
                                        selectedIndices
                                          ..clear()
                                          ..addAll(updatedIndices);
                                      });

                                      if (saleList.isEmpty) {
                                        Navigator.pop(context, <ItemSale>[]);
                                      }
                                    },
                            ),
                          );
                        },
                      ),
                    ),
                    MySpacing.height(16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        MySpacing.width(16),
                        ElevatedButton(
                          onPressed: selectedIndices.isEmpty
                              ? null
                              : () {
                                  final selectedSales = selectedIndices
                                      .map((index) => saleList[index])
                                      .toList(growable: false);
                                  Navigator.pop(context, selectedSales);
                                },
                          child: Builder(
                            builder: (context) {
                              if (selectedIndices.isEmpty) {
                                return const Text('Create Cart');
                              }
                              final itemCount = selectedIndices.length;
                              final itemLabel = itemCount == 1 ? 'item' : 'items';
                              return Text('Create Cart ($itemCount $itemLabel)');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showItemList() async {
    final selectedSales = await _pickSalesForCart();
    if (selectedSales == null) {
      return;
    }

    await _createNewCart(selectedSales);
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

  Future<void> _createNewCart(List<ItemSale> selectedSales) async {
    if (selectedSales.isEmpty) {
      _showSnack('Select at least one sale item.');
      return;
    }

    final cartBloc = context.read<CartBloc>();
    final itemSaleBloc = context.read<ItemSaleBloc>();
    final cartId = DBHelper.generateUuidInt();
    final timestamp = DateTime.now().toIso8601String();

    final cart = Cart(
      id: cartId,
      customerId: _defaultCustomerId,
      createdAt: timestamp,
      cartFor: 'seller',
      status: 'open',
    );

    cartBloc.add(CreateCart(cart));

    final customerId = _selectedCustomer?.id;

    for (final sale in selectedSales) {
      final originalSaleId = sale.id;
      final buyerId = customerId ?? sale.buyerId ?? sale.sellerId;
      final now = DateTime.now().toIso8601String();
      final cartLinkedSale = sale.copyWith(
        id: DBHelper.generateUuidInt(),
        buyerCartId: cartId,
        buyerId: buyerId,
        createdAt: now,
        updatedAt: now,
      );
      cartBloc.add(AddItemToCart(cartLinkedSale));

      if (originalSaleId != null) {
        itemSaleBloc.add(DeleteItemSaleEvent(originalSaleId));
      }
    } 

    itemSaleBloc.add(const LoadItemSales());

    _showSnack('Cart created from selected sales.');
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

  void showCategoryFilterDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, state) {
          if (state is CategoryLoaded) {
            return AlertDialog(
              title: MyText.titleMedium('filter_by_category'.tr(), fontWeight: 600),
              contentPadding: MySpacing.xy(0, 20),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // All option
                    RadioListTile<int?>(
                      value: null,
                      groupValue: _selectedCategoryId,
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                        context.read<ProductBloc>().add(LoadProducts());
                        Navigator.pop(context);
                      },
                      title: MyText.bodyMedium('all'.tr()),
                      dense: true,
                      contentPadding: MySpacing.x(24),
                    ),
                    const Divider(height: 1),
                    // Category options
                    ...state.categories.map((category) {
                      return RadioListTile<int?>(
                        value: category.id,
                        groupValue: _selectedCategoryId,
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                          if (value != null) {
                            context.read<ProductBloc>().add(LoadProductsByCategory(value));
                          }
                          Navigator.pop(context);
                        },
                        title: MyText.bodyMedium(category.name),
                        dense: true,
                        contentPadding: MySpacing.x(24),
                      );
                    }),
                  ],
                ),
              ),
            );
          }
          return AlertDialog(
            title: MyText.titleMedium('filter_by_category'.tr(), fontWeight: 600),
            content: const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: BlocListener<ItemSaleBloc, ItemSaleState>(
        listenWhen: (previous, current) =>
            current is ItemSaleOperationSuccess || current is ItemSaleError,
        listener: (context, saleState) {
          if (saleState is ItemSaleOperationSuccess) {
            final message = saleState.message;
            if (!message.toLowerCase().contains('removed')) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                  content: Text(message),
                ),
              );
            }
          } else if (saleState is ItemSaleError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                content: Text(saleState.message),
              ),
            );
          }
        },
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<ProductBloc, ProductState>(
                builder: (context, productState) {
                  if (productState is ProductLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (productState is ProductLoaded) {
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

                    return GridView.builder(
                      padding: MySpacing.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: productState.products.length,
                      itemBuilder: (context, index) {
                        final product = productState.products[index];
                        return _buildProductCard(product);
                      },
                    );
                  }

                  if (productState is ProductError) {
                    return Center(
                      child: MyText.bodyLarge(
                        productState.message,
                        color: theme.colorScheme.error,
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: BlocBuilder<ItemSaleBloc, ItemSaleState>(
        builder: (context, saleState) {
          final sales = _salesFromState(saleState);
          if (sales.isEmpty) {
            return const SizedBox.shrink();
          }

          final itemCount = sales.length;
          final itemLabel = itemCount == 1 ? 'item' : 'items';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FloatingActionButton.extended(
              onPressed: _showItemList,
              icon: const Icon(Icons.shopping_cart_checkout),
              label: Text('Sold Item ($itemCount $itemLabel)'),
            ),
          );
        },
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

  Widget _buildProductCard(Product product) {
    final defaultVariant = product.defaultVariantModel;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Product Image with floating cart controls
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                // Image
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: defaultVariant != null && defaultVariant.imagePath.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                          child: _buildVariantImage(defaultVariant.imagePath),
                        )
                      : _buildImagePlaceholder(),
                ),
                
                // Overlay price chip
                if (defaultVariant != null)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Material(
                      color: theme.colorScheme.primary,
                      elevation: 4,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showAddToSaleBottomSheet(product),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_shopping_cart,
                                size: 18,
                                color: theme.colorScheme.onPrimary,
                              ),
                              const SizedBox(width: 6),
                              MyText.bodySmall(
                                'Add',
                                color: theme.colorScheme.onPrimary,
                                fontWeight: 600,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Product Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: MySpacing.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Product Name
                  MyText.bodySmall(
                    _productTitle(product),
                    fontWeight: 600,
                    fontSize: 11,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (defaultVariant != null) ...[
                    MySpacing.height(4),
                    MyText.bodySmall(
                      '${defaultVariant.quantity.toStringAsFixed(defaultVariant.quantity % 1 == 0 ? 0 : 2)} ${defaultVariant.unit}',
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 9,
                    ),
                  ],

                  // Show variant info only if more than 1 variant
                  
                  // Show single variant price
                  if (defaultVariant != null)
                    MyText.bodySmall(
                      '₹${defaultVariant.sellingPrice.toStringAsFixed(2)}',
                      fontWeight: 600,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
