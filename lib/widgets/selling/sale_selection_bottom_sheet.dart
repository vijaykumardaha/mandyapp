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
typedef SaleSelectionDeleteCallback = Future<bool> Function(OrderItem sale, int index);
typedef SaleSelectionCheckoutCallback = Future<void> Function(
  List<OrderItem> selectedSales,
);
typedef SaleSelectionCloseCallback = void Function(BuildContext sheetContext);

class SaleSelectionBottomSheet extends StatefulWidget {
  final List<OrderItem> initialSales;
  final Customer? buyerCustomer;
  final ValueChanged<Customer?> onBuyerChanged;
  final SaleSelectionFormatCustomer formatCustomer;
  final SaleSelectionSellerLookup sellerNameForSale;
  final SaleSelectionTitleLookup productTitleForSale;
  final SaleSelectionDeleteCallback onDeleteSale;
  final SaleSelectionCheckoutCallback onCheckout;
  final bool showCancelButton;

  const SaleSelectionBottomSheet({
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

  @override
  State<SaleSelectionBottomSheet> createState() => _SaleSelectionBottomSheetState();
}

class _SaleSelectionBottomSheetState extends State<SaleSelectionBottomSheet> {
  final Set<int> _selectedIndices = <int>{};
  List<OrderItem> _saleList = [];
  Customer? _buyerCustomer;
  bool _showCustomerList = false;

  @override
  void initState() {
    super.initState();
    _saleList = List<OrderItem>.from(widget.initialSales);
    _buyerCustomer = widget.buyerCustomer;
  }

  Widget _buildCustomerSelection() {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, customerState) {
        final allCustomers = customerState is CustomerLoaded
            ? customerState.customers
            : <Customer>[];
        final isLoading = customerState is CustomerLoading;

        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (allCustomers.isEmpty) {
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
                  'No customers found',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          );
        }

        return Container(
          height: 200,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: allCustomers.length,
            itemBuilder: (context, index) {
              final customer = allCustomers[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _buyerCustomer = customer;
                    _showCustomerList = false;
                  });
                  widget.onBuyerChanged(customer);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow.withOpacity(0.04),
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            if (_showCustomerList) ...[
              _buildCustomerSelection(),
              MySpacing.height(18),
            ],
            if (_saleList.isEmpty)
              Center(
                child: MyText.bodySmall(
                  'No sales found.',
                  color: sheetTheme.colorScheme.onSurface.withOpacity(0.6),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 380),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  physics: const BouncingScrollPhysics(),
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
                  final titleText = sellerName != null ? '$productTitle (${sellerName})' : productTitle;
        
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
                                : sheetTheme.colorScheme.outline.withOpacity(0.15),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: sheetTheme.colorScheme.shadow.withOpacity(isChecked ? 0.16 : 0.08),
                              blurRadius: 14,
                              spreadRadius: 0,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: isChecked,
                              onChanged: (value) => toggleSelection(value ?? false),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(width: 12),
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
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      MyText.bodySmall('Qty: $quantityLabel'),
                                      MyText.bodySmall('Rate: ₹${sale.sellingPrice.toStringAsFixed(2)}'),
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
                              icon: const Icon(Icons.delete_outline),
                              color: sheetTheme.colorScheme.error,
                              tooltip: 'Delete sale',
                              onPressed: sale.id == null
                                  ? null
                                  : () async {
                                      final removed = await widget.onDeleteSale(sale, index);
                                      if (!mounted || !removed) {
                                        return;
                                      }
        
                                      setState(() {
                                        _saleList.removeAt(index);
        
                                        final updatedIndices = <int>{};
                                        for (final selectedIndex in _selectedIndices) {
                                          if (selectedIndex == index) {
                                            continue;
                                          }
                                          updatedIndices.add(
                                            selectedIndex > index ? selectedIndex - 1 : selectedIndex,
                                          );
                                        }
                                        _selectedIndices
                                          ..clear()
                                          ..addAll(updatedIndices);
                                      });
                                    },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            MySpacing.height(24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedIndices.isEmpty
                        ? null
                        : () {
                            if (_buyerCustomer == null) {
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Builder(
                      builder: (context) {
                        if (_selectedIndices.isEmpty || _buyerCustomer == null) {
                          return const Text('Checkout Cart');
                        }
                        final itemCount = _selectedIndices.length;
                        final itemLabel = itemCount == 1 ? 'item' : 'items';
                        return Text('Checkout Cart ($itemCount $itemLabel)');
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }
}
