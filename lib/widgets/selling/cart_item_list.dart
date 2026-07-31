import 'package:flutter/material.dart';
import 'package:mandiapp/models/customer_model.dart';
import 'package:mandiapp/models/order_item_model.dart';
import 'package:mandiapp/widgets/common/my_text.dart';

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
  final bool buyerMode;

  @override
  State<CartItemList> createState() => _CartItemListState();
}

class _CartItemListState extends State<CartItemList> {
  final Set<int> _selectedIndices = <int>{};
  List<OrderItem> _saleList = [];

  @override
  void initState() {
    super.initState();
    _saleList = List<OrderItem>.from(widget.initialSales);
  }

  @override
  void didUpdateWidget(CartItemList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSales != widget.initialSales) {
      _saleList = List<OrderItem>.from(widget.initialSales);
    }
    if (oldWidget.buyerMode != widget.buyerMode) {
      _selectedIndices.clear();
    }
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_saleList.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Column(
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 56,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              MyText.bodyMedium(
                                'No items in cart',
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              const SizedBox(height: 6),
                              MyText.bodySmall(
                                'Add items to start billing',
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
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
                          final titleText = productTitle;

                          void toggleSelection(bool value) {
                            setState(() {
                              if (value) {
                                _selectedIndices.add(index);
                              } else {
                                _selectedIndices.remove(index);
                              }
                            });
                          }

                          final canSelect =
                              widget.buyerMode || widget.buyerCustomer != null;

                          return Opacity(
                            opacity: canSelect ? 1.0 : 0.55,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: canSelect
                                    ? () => toggleSelection(!isChecked)
                                    : null,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isChecked
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.05)
                                        : Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isChecked
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .outline
                                              .withValues(alpha: 0.12),
                                      width: isChecked ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: isChecked
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isChecked
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .outline
                                                    .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: isChecked
                                            ? const Icon(Icons.check,
                                                size: 16, color: Colors.white)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: MyText.bodyMedium(
                                                    titleText,
                                                    fontWeight: 600,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                MyText.bodyMedium(
                                                  '₹${(sale.quantity * sale.sellingPrice).toStringAsFixed(2)}',
                                                  fontWeight: 600,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ],
                                            ),
                                            if (sellerName != null) ...[
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: MyText.bodySmall(
                                                      'Seller: $sellerName',
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  MyText.bodySmall(
                                                    '$quantityLabel × ₹${sale.sellingPrice.toStringAsFixed(2)}',
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withValues(alpha: 0.6),
                                                  ),
                                                ],
                                              ),
                                            ] else ...[
                                              const SizedBox(height: 4),
                                              MyText.bodySmall(
                                                '$quantityLabel × ₹${sale.sellingPrice.toStringAsFixed(2)}',
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          if (_selectedIndices.isNotEmpty && widget.buyerCustomer != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: sheetTheme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color:
                        sheetTheme.colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _performCheckout,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Builder(
                  builder: (context) {
                    final itemCount = _selectedIndices.length;
                    final itemLabel = itemCount == 1 ? 'item' : 'items';
                    return Text('Checkout ($itemCount $itemLabel)');
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
