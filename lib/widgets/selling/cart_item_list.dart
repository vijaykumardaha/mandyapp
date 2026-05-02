import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/customer/customer_bloc.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/models/order_item_model.dart';

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

  @override
  State<CartItemList> createState() => _CartItemListState();
}

class _CartItemListState extends State<CartItemList> {
  final Set<int> _selectedIndices = <int>{};
  List<OrderItem> _saleList = [];
  Customer? _buyerCustomer;
  bool _showCustomerList = false;
  String? _selectedAlphabet;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _saleList = List<OrderItem>.from(widget.initialSales);
    _buyerCustomer = widget.buyerCustomer;
    
    // Load customer data to ensure it's available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerBloc>().add(const FetchCustomer(query: ''));
    });
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

        // Filter customers by selected alphabet
        List<Customer> customers = allCustomers;
        if (_selectedAlphabet != null) {
          customers = allCustomers.where((customer) {
            final name = customer.name?.trim().toUpperCase() ?? '';
            return name.startsWith(_selectedAlphabet!);
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
                  _selectedAlphabet != null 
                      ? 'No customers found starting with "${_selectedAlphabet}"'
                      : 'No customers found',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                if (_selectedAlphabet != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedAlphabet = null;
                      });
                    },
                    child: MyText.bodySmall(
                      'Show all customers',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
                if (_selectedAlphabet == null && allCustomers.isEmpty) ...[
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

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Alphabet filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 16),
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
          // Customer grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
                    _buyerCustomer = customer;
                    _showCustomerList = false; // Auto-switch to cart view after selection
                  });
                  widget.onBuyerChanged(customer);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .shadow
                            .withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]),
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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ));
            },
          ),
        ]);
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
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: sheetTheme.colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sheetTheme.colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 20,
                              color: sheetTheme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MyText.bodySmall(
                                    'Customer',
                                    color: sheetTheme.colorScheme.primary,
                                    fontWeight: 500,
                                  ),
                                  const SizedBox(height: 2),
                                  MyText.bodyMedium(
                                    _buyerCustomer != null 
                                        ? widget.formatCustomer(_buyerCustomer)
                                        : 'No customer selected',
                                    fontWeight: 600,
                                    color: sheetTheme.colorScheme.onSurface,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _showCustomerList = true;
                                });
                              },
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: sheetTheme.colorScheme.primary,
                              ),
                              tooltip: 'Change Customer',
                              style: IconButton.styleFrom(
                                backgroundColor: sheetTheme.colorScheme.primary.withOpacity(0.1),
                                padding: const EdgeInsets.all(8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_saleList.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 64,
                                color: sheetTheme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              MyText.bodyMedium(
                                'No items in cart',
                                color: sheetTheme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 8),
                              if (_buyerCustomer == null)
                                MyText.bodySmall(
                                  'Select a customer to add items',
                                  color: sheetTheme.colorScheme.onSurfaceVariant,
                                ),
                            ],
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
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final sale = _saleList[index];
                          final isChecked = _selectedIndices.contains(index);
                          final sellerName = widget.sellerNameForSale(sale);
                          final quantityLabel =
                              '${sale.quantity.toStringAsFixed(sale.quantity % 1 == 0 ? 0 : 2)} ${sale.unit}';
                          final productTitle = widget.productTitleForSale(sale);
                          final titleText = sellerName != null
                              ? '$productTitle (${sellerName})'
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
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => toggleSelection(!isChecked),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: sheetTheme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isChecked
                                        ? sheetTheme.colorScheme.primary
                                        : sheetTheme.colorScheme.outline
                                            .withOpacity(0.15),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: sheetTheme.colorScheme.shadow
                                          .withOpacity(isChecked ? 0.16 : 0.08),
                                      blurRadius: 14,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          MyText.bodyMedium(
                                            titleText,
                                            fontWeight: 700,
                                          ),
                                          MySpacing.height(4),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              MyText.bodySmall('Qty: $quantityLabel'),
                                              MyText.bodySmall(
                                                  'Rate: ₹${sale.sellingPrice.toStringAsFixed(2)}'),
                                              MyText.bodySmall(
                                                'Total: ₹${(sale.quantity * sale.sellingPrice).toStringAsFixed(2)}',
                                                fontWeight: 600,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: _isDeleting 
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                              ),
                                            )
                                          : const Icon(Icons.delete_outline),
                                      color: sheetTheme.colorScheme.error,
                                      tooltip: 'Delete item',
                                      onPressed: _isDeleting ? null : () async {
                                              debugPrint('Delete button pressed for item at index $index');
                                              setState(() {
                                                _isDeleting = true;
                                              });
                                              
                                              try {
                                                // Always allow deletion, handle differently based on whether item has ID
                                                bool removed = true;
                                                if (sale.id != null) {
                                                  debugPrint('Calling onDeleteSale for item with ID: ${sale.id}');
                                                  // If item has ID, call the delete callback
                                                  removed = await widget.onDeleteSale(sale, index);
                                                  debugPrint('onDeleteSale completed, removed: $removed');
                                                } else {
                                                  debugPrint('Deleting local item without ID');
                                                }
                                                
                                                if (!mounted || !removed) {
                                                  debugPrint('Early return from delete - mounted: $mounted, removed: $removed');
                                                  return;
                                                }

                                                setState(() {
                                                  debugPrint('Updating state after deletion');
                                                  _saleList.removeAt(index);

                                                  final updatedIndices = <int>{};
                                                  for (final selectedIndex
                                                      in _selectedIndices) {
                                                    if (selectedIndex == index) {
                                                      continue;
                                                    }
                                                    updatedIndices.add(
                                                      selectedIndex > index
                                                          ? selectedIndex - 1
                                                          : selectedIndex,
                                                    );
                                                  }
                                                  _selectedIndices
                                                    ..clear()
                                                    ..addAll(updatedIndices);
                                                  _isDeleting = false;
                                                  debugPrint('State updated, _isDeleting set to false');
                                                });
                                              } catch (e) {
                                                debugPrint('Error during deletion: $e');
                                                if (mounted) {
                                                  setState(() {
                                                    _isDeleting = false;
                                                  });
                                                }
                                              }
                                            },
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            decoration: BoxDecoration(
              color: sheetTheme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: sheetTheme.colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                if (_showCustomerList) {
                  // If in customer selection mode, switch back to cart
                  setState(() {
                    _showCustomerList = false;
                  });
                } else if (_selectedIndices.isEmpty) {
                  // No items selected, don't allow checkout
                  return;
                } else if (_buyerCustomer == null) {
                  // Show customer list for selection
                  setState(() {
                    _showCustomerList = true;
                  });
                } else {
                  // Proceed with checkout
                  _performCheckout();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
              child: Builder(
                builder: (context) {
                  if (_showCustomerList) {
                    return const Text('Back to Cart');
                  } else if (_selectedIndices.isEmpty) {
                    return const Text('Select Items to Checkout');
                  } else if (_buyerCustomer == null) {
                    return const Text('Select Customer');
                  } else {
                    final itemCount = _selectedIndices.length;
                    final itemLabel = itemCount == 1 ? 'item' : 'items';
                    return Text('Checkout Cart ($itemCount $itemLabel)');
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
