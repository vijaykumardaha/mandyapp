import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mandyapp/blocs/stock/stock_bloc.dart';
import 'package:mandyapp/dao/customer_dao.dart';
import 'package:mandyapp/dao/product_dao.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/models/product_model.dart';
import 'package:mandyapp/models/product_stock_model.dart';
import 'package:mandyapp/models/product_variant_model.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  StockScreenState createState() => StockScreenState();
}

class StockScreenState extends State<StockScreen> {
  final CustomerDAO _customerDAO = CustomerDAO();
  final ProductDAO _productDAO = ProductDAO();

  List<Customer> _customers = [];
  List<Product> _products = [];
  bool _initialLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    context.read<StockBloc>().add(const LoadStocks());
  }

  String _productLabel(ProductStock stock) {
    final id = int.tryParse(stock.productId);
    if (id == null) return stock.productId;
    for (final product in _products) {
      if (product.id == id) {
        return _productDisplayName(product);
      }
    }
    return 'Product #${stock.productId}';
  }

  String _variantLabel(ProductStock stock) {
    final productId = int.tryParse(stock.productId);
    final variantId = int.tryParse(stock.variantId);
    if (productId == null || variantId == null) return stock.variantId;
    final variants = _variantsForProduct(productId);
    for (final variant in variants) {
      if (variant.id == variantId) {
        return _variantDisplayName(variant);
      }
    }
    return 'Variant #${stock.variantId}';
  }

  List<ProductVariant> _variantsForProduct(int? productId) {
    for (final product in _products) {
      if (product.id == productId) {
        return product.variants ?? <ProductVariant>[];
      }
    }
    return <ProductVariant>[];
  }

  String _productDisplayName(Product product) {
    final defaultVariant = product.defaultVariantModel;
    if (defaultVariant != null) {
      return '${defaultVariant.variantName} (ID: ${product.id})';
    }
    return 'Product #${product.id ?? ''}';
  }

  String _variantDisplayName(ProductVariant variant) {
    final qtyLabel = variant.quantity > 0 ? ' - ${variant.quantity} ${variant.unit}' : '';
    return '${variant.variantName}$qtyLabel';
  }

  Future<void> _loadInitialData() async {
    try {
      final customers = await _customerDAO.getCustomers();
      final products = await _productDAO.getAllProductsWithVariants();
      if (mounted) {
        setState(() {
          _customers = customers;
          _products = products;
          _initialLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loadError = 'Failed to load reference data: ${error.toString()}';
          _initialLoading = false;
        });
      }
    }
  }

  Future<void> _refreshStocks() async {
    context.read<StockBloc>().add(const LoadStocks());
  }

  void showAddStockForm() {
    _showStockForm();
  }

  void _showStockForm({ProductStock? stock}) {
    final formKey = GlobalKey<FormState>();
    int? selectedCustomerId = stock?.customerId;
    int? selectedProductId = stock != null ? int.tryParse(stock.productId) : null;
    int? selectedVariantId = stock != null ? int.tryParse(stock.variantId) : null;
    final initialStockController = TextEditingController(text: stock?.initialStock.toString() ?? '');
    final stockController = TextEditingController(text: stock?.currentStock.toString() ?? '');
    final unitController = TextEditingController(text: stock?.unit ?? 'Kg');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final variantsForSelectedProduct = selectedProductId != null
                  ? _variantsForProduct(selectedProductId)
                  : <ProductVariant>[];
              if (selectedVariantId != null &&
                  variantsForSelectedProduct.every((variant) => variant.id != selectedVariantId)) {
                selectedVariantId = null;
              }
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText.titleMedium(
                        stock == null ? 'Add Stock' : 'Edit Stock',
                        fontWeight: 600,
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<int>(
                        value: selectedCustomerId,
                        decoration: const InputDecoration(
                          labelText: 'Customer',
                          border: OutlineInputBorder(),
                        ),
                        items: _customers
                            .map(
                              (c) => DropdownMenuItem<int>(
                                value: c.id,
                                child: Text('${c.name ?? 'Unnamed'} (${c.phone ?? '-'})'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setSheetState(() => selectedCustomerId = value);
                        },
                        validator: (value) => value == null ? 'Please select a customer' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: selectedProductId,
                        decoration: const InputDecoration(
                          labelText: 'Product',
                          border: OutlineInputBorder(),
                        ),
                        items: _products
                            .map(
                              (p) => DropdownMenuItem<int>(
                                value: p.id,
                                child: Text(_productDisplayName(p)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setSheetState(() {
                            selectedProductId = value;
                            selectedVariantId = null;
                          });
                        },
                        validator: (value) => value == null ? 'Please select a product' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: selectedVariantId,
                        decoration: const InputDecoration(
                          labelText: 'Variant',
                          border: OutlineInputBorder(),
                        ),
                        items: variantsForSelectedProduct
                            .map(
                              (variant) => DropdownMenuItem<int>(
                                value: variant.id,
                                child: Text(_variantDisplayName(variant)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setSheetState(() => selectedVariantId = value);
                        },
                        validator: (value) {
                          if ((variantsForSelectedProduct.isNotEmpty && value == null) || selectedProductId == null) {
                            return 'Please select a variant';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: initialStockController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Initial Stock',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter initial stock';
                          }
                          final parsed = double.tryParse(value);
                          if (parsed == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: stockController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Current Stock',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter stock';
                          }
                          final parsed = double.tryParse(value);
                          if (parsed == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: unitController.text.isEmpty ? 'Kg' : unitController.text,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                        ),
                        items: const ['Kg', 'g', 'L', 'ml', 'Pcs', 'Box']
                            .map(
                              (unit) => DropdownMenuItem<String>(
                                value: unit,
                                child: Text(unit),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setSheetState(() {
                              unitController.text = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState?.validate() != true) {
                              return;
                            }
                            if (selectedProductId == null || selectedVariantId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  margin: EdgeInsets.only(top: 16, left: 16, right: 16),
                                  content: Text('Please select product and variant'),
                                ),
                              );
                              return;
                            }

                            final now = DateTime.now().toIso8601String();
                            final newStock = ProductStock(
                              id: stock?.id,
                              customerId: selectedCustomerId!,
                              productId: selectedProductId!.toString(),
                              variantId: selectedVariantId!.toString(),
                              currentStock: double.parse(stockController.text),
                              initialStock: double.parse(initialStockController.text),
                              unit: unitController.text.isEmpty ? 'Kg' : unitController.text,
                              lastUpdated: now,
                              createdAt: stock?.createdAt ?? now,
                            );

                            context.read<StockBloc>().add(UpsertStock(newStock));
                            Navigator.of(context).pop();
                          },
                          child: Text(stock == null ? 'Save Stock' : 'Update Stock'),
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

  String _customerLabel(ProductStock stock) {
    final customer = _customers.firstWhere(
      (c) => c.id == stock.customerId,
      orElse: () => Customer(id: stock.customerId, name: 'Customer #${stock.customerId}'),
    );
    return customer.name ?? 'Customer #${stock.customerId}';
  }

  String _createdLabel(ProductStock stock) {
    final parsed = DateTime.tryParse(stock.createdAt);
    if (parsed == null) return stock.createdAt;
    return DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
  }

  Widget _buildStockStat(String label, String value, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText.bodySmall(
            label,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(height: 6),
          MyText.bodyMedium(
            value,
            fontWeight: 600,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.primary.withOpacity(0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          MyText.bodySmall(
            label,
            fontWeight: 500,
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ProductStock stock) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: MyText.titleMedium('Delete stock?', fontWeight: 600),
        content: MyText.bodyMedium('This action will remove the stock entry for ${_customerLabel(stock)} created on ${_createdLabel(stock)}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<StockBloc>().add(DeleteStock(stock.id!));
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyText.titleMedium('Unable to load stocks', fontWeight: 600),
              const SizedBox(height: 12),
              MyText.bodyMedium(_loadError!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _initialLoading = true;
                    _loadError = null;
                  });
                  _loadInitialData();
                  _refreshStocks();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock'),
        actions: [
          IconButton(
            tooltip: 'Add Stock',
            onPressed: showAddStockForm,
            icon: const Icon(Icons.add),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocConsumer<StockBloc, StockState>(
        listener: (context, state) {
          if (state is StockOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                content: Text(state.message),
              ),
            );
          } else if (state is StockError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                content: Text(state.message),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is StockLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is StockLoaded || state is StockOperationSuccess) {
            final stocks = state is StockLoaded ? state.stocks : (state as StockOperationSuccess).stocks;

            if (stocks.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refreshStocks,
                child: ListView(
                  children: const [
                    SizedBox(height: 120),
                    Center(child: Text('No stock entries yet. Use Add Stock to create one.')),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refreshStocks,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: stocks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final stock = stocks[index];
                  final theme = Theme.of(context);
                  final unitLabel = stock.unit.trim();
                  final initialValue = unitLabel.isNotEmpty ? '${stock.initialStock} $unitLabel' : '${stock.initialStock}';
                  final currentValue = unitLabel.isNotEmpty ? '${stock.currentStock} $unitLabel' : '${stock.currentStock}';

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
                      color: theme.colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    MyText.titleMedium(
                                      _customerLabel(stock),
                                      fontWeight: 600,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today_outlined, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                        const SizedBox(width: 6),
                                        MyText.bodySmall(
                                          _createdLabel(stock),
                                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Edit',
                                    onPressed: () => _showStockForm(stock: stock),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: 'Delete',
                                    onPressed: () => _confirmDelete(stock),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStockStat('Initial Stock', initialValue, theme),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStockStat('Current Stock', currentValue, theme),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildInfoTag(Icons.shopping_bag_outlined, _productLabel(stock), theme),
                              _buildInfoTag(Icons.layers_outlined, _variantLabel(stock), theme),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }

          if (state is StockError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MyText.titleMedium('Failed to load stocks', fontWeight: 600),
                    const SizedBox(height: 12),
                    MyText.bodyMedium(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshStocks,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
