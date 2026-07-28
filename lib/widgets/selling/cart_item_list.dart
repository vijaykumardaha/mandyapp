import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandiapp/blocs/customer/customer_bloc.dart';
import 'package:mandiapp/widgets/common/my_text.dart';
import 'package:mandiapp/models/customer_model.dart';
import 'package:mandiapp/models/order_item_model.dart';

typedef SaleSelectionFormatCustomer = String Function(Customer? customer);
typedef SaleSelectionSellerLookup = String? Function(OrderItem sale);
typedef SaleSelectionTitleLookup = String Function(OrderItem sale);
typedef SaleSelectionDeleteCallback = Future<bool> Function(
    OrderItem sale, int index);
typedef SaleSelectionCheckoutCallback = Future<void> Function(
  List<OrderItem> selectedSales,
);
typedef SaleSelectionCloseCallback = void Function(BuildContext sheetContext);

class CartItemList extends StatefulWidget {
  const CartItemList({
    super.key,
    required this.initialSales,
    required this.buyerCustomer,
    required this.onBuyerChanged,
    required this.formatCustomer,
    required this.sellerNameForSale,
    required this.productTitleForSale,
    required this.onDeleteSale,
    required this.onCheckout,
    this.showCancelButton = true,
    this.customerLabel = 'Customer',
    this.buyerMode = false,
  });

  final List<OrderItem> initialSales;
  final Customer? buyerCustomer;
  final ValueChanged<Customer?> onBuyerChanged;
  final SaleSelectionFormatCustomer formatCustomer;
  final SaleSelectionSellerLookup sellerNameForSale;
  final SaleSelectionTitleLookup productTitleForSale;
  final SaleSelectionDeleteCallback onDeleteSale;
  final SaleSelectionCheckoutCallback onCheckout;
  final bool showCancelButton;
  final String customerLabel;
  final bool buyerMode;

  @override
  State<CartItemList> createState() => _CartItemListState();
}

class _CartItemListState extends State<CartItemList> {
  final Set<int> _selectedIndices = <int>{};
  List<OrderItem> _saleList = [];
  Customer? _buyerCustomer;
  bool _showCustomerList = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _saleList = List<OrderItem>.from(widget.initialSales);
    _buyerCustomer = widget.buyerCustomer;
    _showCustomerList = !widget.buyerMode;
    
    // Load customer data to ensure it's available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerBloc>().add(const FetchCustomer(query: ''));
    });
  }

  @override
  void didUpdateWidget(CartItemList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSales != widget.initialSales) {
      _saleList = List<OrderItem>.from(widget.initialSales);
    }
    if (oldWidget.buyerCustomer != widget.buyerCustomer) {
      _buyerCustomer = widget.buyerCustomer;
    }
    if (oldWidget.buyerMode != widget.buyerMode) {
      _showCustomerList = !widget.buyerMode;
      _selectedIndices.clear();
    }
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search ${widget.buyerMode ? 'buyer' : 'seller'}...',
          prefixIcon: const Icon(Icons.search, size: 20),
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
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildCustomerSelection() {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, customerState) {
        // Debug: Print customer state changes
        debugPrint('CustomerBloc state: ${customerState.runtimeType}, _showCustomerList: $_showCustomerList');
        
        // Only show loading if we're actually in customer selection mode
        if (!_showCustomerList) {
          return const SizedBox.shrink();
        }
        
        final allCustomers = customerState is CustomerLoaded
            ? customerState.customers
            : <Customer>[];
        final isLoading = customerState is CustomerLoading;
        final hasError = customerState is SyncCustomerError;

        // Filter customers by search query
        List<Customer> customers = allCustomers;
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          customers = allCustomers.where((customer) {
            final name = (customer.name?.trim() ?? '').toLowerCase();
            final phone = (customer.phone?.trim() ?? '').toLowerCase();
            return name.contains(query) || phone.contains(query);
          }).toList();
        }

        if (isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading customers...'),
              ],
            ),
          );
        }

        if (hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                MyText.bodyMedium(
                  'Failed to load customers',
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    context.read<CustomerBloc>().add(const FetchCustomer(query: ''));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (customers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                MyText.bodyMedium(
                  _searchQuery.isNotEmpty
                      ? 'No customers found matching "${_searchQuery}"'
                      : 'No customers found',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                    child: MyText.bodySmall(
                      'Clear search',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
                if (_searchQuery.isEmpty && allCustomers.isEmpty) ...[
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      context.read<CustomerBloc>().add(const FetchCustomer(query: ''));
                    },
                    child: const Text('Refresh Customers'),
                  ),
                ],
              ],
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
                  _buyerCustomer = customer;
                  _showCustomerList = false;
                });
                widget.onBuyerChanged(customer);
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
        );
      },
    );
  }

  void _performCheckout() async {
    final selectedSales = _selectedIndices
        .map((index) => _saleList[index])
        .toList(growable: false);
    await widget.onCheckout(selectedSales);
  }

  @override
  Widget build(BuildContext context) {
    final sheetTheme = Theme.of(context);

    return SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          // Sticky search field
          if (_showCustomerList)
            _buildSearchField(),
          // Scrollable content area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Content based on toggle state
                    if (_showCustomerList) ...[
                      _buildCustomerSelection(),
                    ] else ...[
                      // Customer info bar at top of cart
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                              child: Icon(
                                Icons.person_outline,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MyText.bodyMedium(
                                    _buyerCustomer != null
                                        ? widget.formatCustomer(_buyerCustomer)
                                        : 'No customer selected',
                                    fontWeight: 600,
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _showCustomerList = true;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.swap_horiz,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_saleList.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 56,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                MyText.bodyMedium(
                                  'No items in cart',
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 6),
                                MyText.bodySmall(
                                  'Add items to start billing',
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                                ),
                              ],
                            ),
                          ),
                        )
                    ],
                    // Always show cart items when not in customer selection mode
                    if (!_showCustomerList && _saleList.isNotEmpty)
                      ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _saleList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final sale = _saleList[index];
                          final isChecked = _selectedIndices.contains(index);
                          final sellerName = widget.sellerNameForSale(sale);
                          final quantityLabel =
                              '${sale.quantity.toStringAsFixed(sale.quantity % 1 == 0 ? 0 : 2)} ${sale.unit}';
                          final productTitle = widget.productTitleForSale(sale);
                          final titleText = sellerName != null
                              ? '$productTitle [${sellerName}]'
                              : productTitle;

                          void toggleSelection(bool value) {
                            setState(() {
                              if (value) {
                                _selectedIndices.add(index);
                              } else {
                                _selectedIndices.remove(index);
                              }
                            });
                          }

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => toggleSelection(!isChecked),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isChecked
                                      ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                                      : Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isChecked
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.outline.withOpacity(0.12),
                                    width: isChecked ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: isChecked
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isChecked
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).colorScheme.outline.withOpacity(0.4),
                                        ),
                                      ),
                                      child: isChecked
                                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: MyText.bodyMedium(
                                                  titleText,
                                                  fontWeight: 600,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              MyText.bodyMedium(
                                                '₹${(sale.quantity * sale.sellingPrice).toStringAsFixed(2)}',
                                                fontWeight: 600,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          MyText.bodySmall(
                                            '$quantityLabel × ₹${sale.sellingPrice.toStringAsFixed(2)}',
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    // Add bottom padding to account for sticky button
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          
          // Sticky bottom button
          if (!_showCustomerList)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: sheetTheme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: sheetTheme.colorScheme.shadow.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                if (_selectedIndices.isEmpty) {
                  return;
                } else if (_buyerCustomer == null) {
                  setState(() {
                    _showCustomerList = true;
                  });
                } else {
                  _performCheckout();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Builder(
                builder: (context) {
                  if (_selectedIndices.isEmpty) {
                    return const Text('Select Items to Checkout');
                  } else if (_buyerCustomer == null) {
                    return const Text('Select Customer');
                  } else {
                    final itemCount = _selectedIndices.length;
                    final itemLabel = itemCount == 1 ? 'item' : 'items';
                    return Text('Checkout ($itemCount $itemLabel)');
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
