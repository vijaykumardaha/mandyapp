import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandiapp/blocs/stock/stock_bloc.dart';
import 'package:mandiapp/helpers/theme/app_theme.dart';
import 'package:mandiapp/models/stock_model.dart';
import 'package:mandiapp/services/sync_service.dart';
import 'package:mandiapp/utils/app_helper.dart';
import 'package:mandiapp/utils/info_controller.dart';
import 'package:mandiapp/widgets/common/common_app_bar.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';
import 'package:mandiapp/widgets/stock/stock_list_item.dart';

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

    _syncSubscription = SyncService.instance.tableUpdates.listen((table) {
      if (!mounted) return;
      if (table == 'stocks') {
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
    return stocks.where((s) =>
      s.productId.toString().contains(_searchQuery) ||
      s.sellerId.toString().contains(_searchQuery)
    ).toList();
  }

  void _showStockDialog([Stock? stock]) {
    final isEditing = stock != null;
    final sellerIdController = TextEditingController(
      text: stock?.sellerId.toString() ?? '',
    );
    final productIdController = TextEditingController(
      text: stock?.productId.toString() ?? '',
    );
    final variantIdController = TextEditingController(
      text: stock?.productVariantId?.toString() ?? '',
    );
    final initialQtyController = TextEditingController(
      text: stock?.initialQuantity.toString() ?? '',
    );
    final purchaseAmountController = TextEditingController(
      text: stock?.purchaseAmount.toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MyText.titleMedium(
                  isEditing ? 'Edit Stock' : 'Add Stock',
                  fontWeight: 600,
                ),
                MySpacing.height(16),
                TextField(
                  controller: sellerIdController,
                  decoration: const InputDecoration(
                    labelText: 'Seller ID',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                MySpacing.height(12),
                TextField(
                  controller: productIdController,
                  decoration: const InputDecoration(
                    labelText: 'Product ID',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                MySpacing.height(12),
                TextField(
                  controller: variantIdController,
                  decoration: const InputDecoration(
                    labelText: 'Product Variant ID (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                MySpacing.height(12),
                TextField(
                  controller: initialQtyController,
                  decoration: const InputDecoration(
                    labelText: 'Initial Quantity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                MySpacing.height(12),
                TextField(
                  controller: purchaseAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Purchase Amount (₹)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                MySpacing.height(16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: MyText.bodyMedium('Cancel'),
                      ),
                    ),
                    MySpacing.width(12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final sellerId = int.tryParse(sellerIdController.text);
                          final productId = int.tryParse(productIdController.text);
                          final initialQty = double.tryParse(initialQtyController.text);
                          final purchaseAmount = double.tryParse(purchaseAmountController.text);

                          if (sellerId == null || productId == null) {
                            Info.message('Please enter valid Seller ID and Product ID', context: sheetContext);
                            return;
                          }
                          if (initialQty == null || initialQty <= 0) {
                            Info.message('Please enter a valid quantity', context: sheetContext);
                            return;
                          }
                          if (purchaseAmount == null || purchaseAmount < 0) {
                            Info.message('Please enter a valid purchase amount', context: sheetContext);
                            return;
                          }

                          final newStock = Stock(
                            id: stock?.id,
                            mandiId: stock?.mandiId,
                            sellerId: sellerId,
                            productId: productId,
                            productVariantId: int.tryParse(variantIdController.text),
                            initialQuantity: initialQty,
                            quantity: isEditing ? stock!.quantity : initialQty,
                            soldQuantity: stock?.soldQuantity ?? 0,
                            lossQuantity: stock?.lossQuantity ?? 0,
                            purchaseAmount: purchaseAmount,
                            soldAmount: stock?.soldAmount ?? 0,
                          );

                          if (isEditing) {
                            context.read<StockBloc>().add(UpdateStock(newStock));
                          } else {
                            context.read<StockBloc>().add(AddStock(newStock));
                          }
                          Navigator.pop(sheetContext);
                        },
                        child: MyText.bodyMedium(isEditing ? 'Update' : 'Add'),
                      ),
                    ),
                  ],
                ),
                MySpacing.height(16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteStock(Stock stock) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: MyText.titleMedium('Delete Stock', fontWeight: 600),
        content: MyText.bodyMedium(
          'Are you sure you want to delete stock for Product #${stock.productId}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: MyText.bodyMedium('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<StockBloc>().add(DeleteStock(stock.id!));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: MyText.bodyMedium('Delete'),
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
            suffixIcon: _isAdmin
                ? IconButton(
                    icon: Icon(Icons.add, size: 20, color: theme.colorScheme.onSurfaceVariant),
                    tooltip: 'Add stock',
                    onPressed: () => _showStockDialog(),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 40),
          ),
        ),
      ),
      body: BlocConsumer<StockBloc, StockState>(
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
                return StockListItem(
                  stock: stock,
                  theme: theme,
                  isAdmin: _isAdmin,
                  onEdit: () => _showStockDialog(stock),
                  onDelete: () => _deleteStock(stock),
                );
              },
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
