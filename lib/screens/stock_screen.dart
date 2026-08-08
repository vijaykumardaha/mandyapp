import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:krishimandi/blocs/customer/customer_bloc.dart';
import 'package:krishimandi/blocs/product/product_bloc.dart';
import 'package:krishimandi/blocs/stock/stock_bloc.dart';
import 'package:krishimandi/helpers/theme/app_theme.dart';
import 'package:krishimandi/models/customer_model.dart';
import 'package:krishimandi/models/product_model.dart';
import 'package:krishimandi/models/product_variant_model.dart';
import 'package:krishimandi/models/stock_model.dart';
import 'package:krishimandi/services/sync_service.dart';
import 'package:krishimandi/utils/app_helper.dart';
import 'package:krishimandi/utils/constants.dart';
import 'package:krishimandi/utils/info_controller.dart';
import 'package:krishimandi/widgets/common/common_app_bar.dart';
import 'package:krishimandi/widgets/common/dropdown_option.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';
import 'package:krishimandi/widgets/stock/stock_list_item.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  late ThemeData theme;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isAdmin = true;
  StreamSubscription<String>? _syncSubscription;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    _loadRole();
    context.read<StockBloc>().add(LoadStocks());
    context.read<CustomerBloc>().add(const FetchCustomer(query: ''));
    context.read<ProductBloc>().add(LoadProducts());

    _syncSubscription = SyncService.instance.tableUpdates.listen((table) {
      if (!mounted) return;
      if (table == DbTables.stocks) {
        final state = context.read<StockBloc>().state;
        if (state is StockLoaded) {
          context.read<StockBloc>().add(LoadStocks());
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

  @override
  void dispose() {
    _syncSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<Stock> _filterStocks(List<Stock> stocks) {
    if (_searchQuery.isEmpty) return stocks;
    return stocks
        .where((s) =>
            s.productId.toString().contains(_searchQuery) ||
            s.sellerId.toString().contains(_searchQuery))
        .toList();
  }

  void _showStockDialog([Stock? stock]) {
    final customerState = context.read<CustomerBloc>().state;
    final productState = context.read<ProductBloc>().state;
    final customers = customerState is CustomerLoaded
        ? customerState.customers
        : <Customer>[];
    final products =
        productState is ProductLoaded ? productState.products : <Product>[];

    showDialog(
      context: context,
      useSafeArea: false,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.zero,
        child: _StockFormDialog(
          stock: stock,
          products: products,
          customers: customers,
        ),
      ),
    );
  }

  void _deleteStock(Stock stock) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const MyText.titleMedium('Delete Stock', fontWeight: 600),
        content: MyText.bodyMedium(
          'Are you sure you want to delete stock for Product #${stock.productId}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const MyText.bodyMedium('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<StockBloc>().add(DeleteStock(stock.id!));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const MyText.bodyMedium('Delete'),
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
          onChanged: (value) => setState(() => _searchQuery = value),
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search stocks...',
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
                ? InkWell(
                    onTap: () => _showStockDialog(),
                    child: Icon(Icons.add_circle_outline,
                        size: 22, color: theme.colorScheme.primary),
                  )
                : null,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<StockBloc, StockState>(
          listener: (context, state) {
            if (state is StockError) {
              Info.error(state.message, context: context);
            } else if (state is StockOperationSuccess) {
              Info.message(state.message, context: context);
              context.read<StockBloc>().add(LoadStocks());
            }
          },
          builder: (context, state) {
            if (state is StockLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is StockLoaded) {
              final stocks = _filterStocks(state.stocks);
              if (stocks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      MySpacing.height(16),
                      MyText.bodyLarge(
                        'No stocks found',
                        color: theme.colorScheme.outline,
                      ),
                      MySpacing.height(8),
                      MyText.bodyMedium(
                        'Tap the + button to add your first stock entry',
                        color: theme.colorScheme.outline,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: MySpacing.all(16),
                itemCount: stocks.length,
                itemBuilder: (context, index) {
                  final stock = stocks[index];
                  final customerState = context.read<CustomerBloc>().state;
                  final productState = context.read<ProductBloc>().state;
                  final customers = customerState is CustomerLoaded
                      ? customerState.customers
                      : <Customer>[];
                  final products = productState is ProductLoaded
                      ? productState.products
                      : <Product>[];
                  final seller = customers
                      .where((c) => c.id == stock.sellerId)
                      .firstOrNull;
                  final product = products
                      .where((p) => p.id == stock.productId)
                      .firstOrNull;
                  return StockListItem(
                    stock: stock,
                    theme: theme,
                    isAdmin: _isAdmin,
                    sellerName: seller?.name,
                    productName: product?.defaultVariantModel?.variantName,
                    onEdit: () => _showStockDialog(stock),
                    onDelete: () => _deleteStock(stock),
                  );
                },
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

class _StockFormDialog extends StatefulWidget {
  final Stock? stock;
  final List<Product> products;
  final List<Customer> customers;

  const _StockFormDialog({
    this.stock,
    required this.products,
    required this.customers,
  });

  @override
  State<_StockFormDialog> createState() => _StockFormDialogState();
}

class _StockFormDialogState extends State<_StockFormDialog> {
  final _initialQtyController = TextEditingController();
  final _purchaseAmountController = TextEditingController();
  Customer? _selectedSeller;
  Product? _selectedProduct;
  ProductVariant? _selectedVariant;

  late final bool _isEditing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.stock != null;
    _initialQtyController.text = widget.stock?.initialQuantity.toString() ?? '';
    _purchaseAmountController.text =
        widget.stock?.purchaseAmount.toString() ?? '';

    if (_isEditing) {
      _selectedSeller = widget.customers
          .where((c) => c.id == widget.stock!.sellerId)
          .firstOrNull;
      _selectedProduct = widget.products
          .where((p) => p.id == widget.stock!.productId)
          .firstOrNull;
      if (_selectedProduct != null) {
        _selectedVariant = _selectedProduct?.variants
            ?.where((v) => v.id == widget.stock!.productVariantId)
            .firstOrNull;
      }
    }
  }

  @override
  void dispose() {
    _initialQtyController.dispose();
    _purchaseAmountController.dispose();
    super.dispose();
  }

  List<ProductVariant> _getVariants() {
    if (_selectedProduct == null) return [];
    return _selectedProduct?.variants ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: kToolbarHeight + 20,
        title: MyText.titleMedium(
          _isEditing ? 'Edit Stock' : 'Add Stock',
          fontWeight: 600,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<Customer>(
                value: _selectedSeller,
                isExpanded: true,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                menuMaxHeight: 300,
                elevation: 4,
                decoration: const InputDecoration(
                  labelText: 'Seller',
                  border: OutlineInputBorder(),
                ),
                items: widget.customers
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: DropdownOption(
                            selected: _selectedSeller == c,
                            child: Text(c.name ?? 'Seller #${c.id}'),
                          ),
                        ))
                    .toList(),
                selectedItemBuilder: (context) => widget.customers
                    .map((c) => Text(c.name ?? 'Seller #${c.id}'))
                    .toList(),
                onChanged: (value) => setState(() => _selectedSeller = value),
              ),
              MySpacing.height(12),
              DropdownButtonFormField<Product>(
                value: _selectedProduct,
                isExpanded: true,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                menuMaxHeight: 300,
                elevation: 4,
                decoration: const InputDecoration(
                  labelText: 'Product',
                  border: OutlineInputBorder(),
                ),
                items: widget.products.map((p) {
                  final name =
                      p.defaultVariantModel?.variantName ?? 'Product #${p.id}';
                  final img = p.defaultVariantModel?.imagePath;
                  return DropdownMenuItem(
                    value: p,
                    child: DropdownOption(
                      selected: _selectedProduct == p,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: _buildDropdownImage(img, 32),
                          ),
                          MySpacing.width(8),
                          Flexible(
                            child: Text(name, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                selectedItemBuilder: (context) => widget.products.map((p) {
                  final name =
                      p.defaultVariantModel?.variantName ?? 'Product #${p.id}';
                  final img = p.defaultVariantModel?.imagePath;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: _buildDropdownImage(img, 32),
                      ),
                      MySpacing.width(8),
                      Flexible(
                          child: Text(name, overflow: TextOverflow.ellipsis)),
                    ],
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProduct = value;
                    _selectedVariant = null;
                  });
                },
              ),
              MySpacing.height(12),
              DropdownButtonFormField<ProductVariant>(
                value: _selectedVariant,
                isExpanded: true,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                menuMaxHeight: 300,
                elevation: 4,
                decoration: const InputDecoration(
                  labelText: 'Variant',
                  border: OutlineInputBorder(),
                ),
                items: _getVariants()
                    .map((v) => DropdownMenuItem(
                          value: v,
                          child: DropdownOption(
                            selected: _selectedVariant == v,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: _buildDropdownImage(v.imagePath, 32),
                                ),
                                MySpacing.width(8),
                                Flexible(
                                  child: Text(v.variantName,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
                selectedItemBuilder: (context) => _getVariants()
                    .map((v) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: _buildDropdownImage(v.imagePath, 32),
                            ),
                            MySpacing.width(8),
                            Flexible(
                              child: Text(v.variantName,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedVariant = value),
              ),
              MySpacing.height(12),
              TextField(
                controller: _initialQtyController,
                decoration: const InputDecoration(
                  labelText: 'Initial Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              MySpacing.height(12),
              TextField(
                controller: _purchaseAmountController,
                decoration: const InputDecoration(
                  labelText: 'Purchase Amount (₹)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              MySpacing.height(16),
              LayoutBuilder(
                builder: (ctx, constraints) => Row(
                  children: [
                    SizedBox(
                      width: constraints.maxWidth * 0.5 - 6,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const MyText.bodyMedium('Cancel'),
                      ),
                    ),
                    MySpacing.width(12),
                    SizedBox(
                      width: constraints.maxWidth * 0.5 - 6,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: MyText.bodyMedium(_isEditing ? 'Update' : 'Add'),
                      ),
                    ),
                  ],
                ),
              ),
              MySpacing.height(16),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_selectedSeller == null || _selectedSeller!.id == null) {
      Info.message('Please select a seller', context: context);
      return;
    }
    if (_selectedProduct == null || _selectedProduct!.id == null) {
      Info.message('Please select a product', context: context);
      return;
    }
    if (_selectedVariant == null || _selectedVariant!.id == null) {
      Info.message('Please select a variant', context: context);
      return;
    }
    final initialQty = double.tryParse(_initialQtyController.text);
    final purchaseAmount = double.tryParse(_purchaseAmountController.text);

    if (initialQty == null || initialQty <= 0) {
      Info.message('Please enter a valid quantity', context: context);
      return;
    }
    if (purchaseAmount == null || purchaseAmount < 0) {
      Info.message('Please enter a valid purchase amount', context: context);
      return;
    }

    final newStock = Stock(
      id: widget.stock?.id,
      mandiId: widget.stock?.mandiId,
      sellerId: _selectedSeller!.id!,
      productId: _selectedProduct!.id!,
      productVariantId: _selectedVariant!.id!,
      initialQuantity: initialQty,
      quantity: _isEditing ? widget.stock!.quantity : initialQty,
      soldQuantity: widget.stock?.soldQuantity ?? 0,
      lossQuantity: widget.stock?.lossQuantity ?? 0,
      purchaseAmount: purchaseAmount,
      soldAmount: widget.stock?.soldAmount ?? 0,
    );

    if (_isEditing) {
      context.read<StockBloc>().add(UpdateStock(newStock));
    } else {
      context.read<StockBloc>().add(AddStock(newStock));
    }
    Navigator.pop(context);
  }

  Widget _buildDropdownImage(String? path, double size) {
    final placeholder = Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(Icons.image,
          size: size * 0.6,
          color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
    if (path == null || path.isEmpty) return placeholder;
    if (path.startsWith('assets/')) {
      return Image.asset(path,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder);
    }
    return Image.file(File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder);
  }
}
