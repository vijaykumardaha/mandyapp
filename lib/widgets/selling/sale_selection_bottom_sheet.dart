import 'package:flutter/material.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/models/item_sale_model.dart';
import 'package:mandyapp/widgets/common/customer_inline_autocomplete.dart';

typedef SaleSelectionFormatCustomer = String Function(Customer? customer);
typedef SaleSelectionSellerLookup = String? Function(ItemSale sale);
typedef SaleSelectionTitleLookup = String Function(ItemSale sale);
typedef SaleSelectionDeleteCallback = Future<bool> Function(ItemSale sale, int index);
typedef SaleSelectionCheckoutCallback = Future<void> Function(
  BuildContext sheetContext,
  List<ItemSale> selectedSales,
);
typedef SaleSelectionCloseCallback = void Function(BuildContext sheetContext);

class SaleSelectionBottomSheet extends StatefulWidget {
  final List<ItemSale> initialSales;
  final Customer? buyerCustomer;
  final ValueChanged<Customer?> onBuyerChanged;
  final SaleSelectionFormatCustomer formatCustomer;
  final SaleSelectionSellerLookup sellerNameForSale;
  final SaleSelectionTitleLookup productTitleForSale;
  final SaleSelectionDeleteCallback onDeleteSale;
  final SaleSelectionCheckoutCallback onCheckout;
  final SaleSelectionCloseCallback onClose;

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
    required this.onClose,
  });

  @override
  State<SaleSelectionBottomSheet> createState() => _SaleSelectionBottomSheetState();
}

class _SaleSelectionBottomSheetState extends State<SaleSelectionBottomSheet> {
  late final List<ItemSale> _saleList;
  final Set<int> _selectedIndices = <int>{};
  late Customer? _buyerCustomer;

  @override
  void initState() {
    super.initState();
    _saleList = List<ItemSale>.from(widget.initialSales);
    _buyerCustomer = widget.buyerCustomer;
  }

  @override
  Widget build(BuildContext context) {
    final sheetTheme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        color: sheetTheme.colorScheme.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: bottomPadding + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sheetTheme.colorScheme.outline.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                MySpacing.height(20),
                CustomerInlineAutocomplete(
                  initialCustomer: _buyerCustomer,
                  formatCustomer: widget.formatCustomer,
                  onCustomerSelected: (customer) {
                    setState(() {
                      _buyerCustomer = customer;
                    });
                    widget.onBuyerChanged(customer);
                  },
                ),
                MySpacing.height(18),
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
                                            'Total: ₹${sale.totalPrice.toStringAsFixed(2)}',
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

                                          if (_saleList.isEmpty) {
                                            widget.onClose(context);
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
                ),
                MySpacing.height(24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => widget.onClose(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          side: BorderSide(color: sheetTheme.colorScheme.outline.withOpacity(0.4)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    MySpacing.width(16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedIndices.isEmpty || _buyerCustomer == null
                            ? null
                            : () async {
                                final selectedSales = _selectedIndices
                                    .map((index) => _saleList[index])
                                    .toList(growable: false);
                                await widget.onCheckout(context, selectedSales);
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
      ),
    );
  }
}
