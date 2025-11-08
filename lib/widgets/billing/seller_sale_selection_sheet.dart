import 'package:flutter/material.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/models/item_sale_model.dart';

class SellerSaleSelectionSheet extends StatefulWidget {
  final Customer seller;
  final List<ItemSale> sales;
  final String Function(Customer) formatCustomer;
  final VoidCallback onReload;
  final void Function(ItemSale sale, int index) onDeleteSale;
  final Future<void> Function(List<ItemSale> selected) onConfirm;

  const SellerSaleSelectionSheet({
    super.key,
    required this.seller,
    required this.sales,
    required this.formatCustomer,
    required this.onReload,
    required this.onDeleteSale,
    required this.onConfirm,
  });

  @override
  State<SellerSaleSelectionSheet> createState() => _SellerSaleSelectionSheetState();
}

class _SellerSaleSelectionSheetState extends State<SellerSaleSelectionSheet> {
  final Set<int> _selectedIndices = {};
  late List<ItemSale> _sales;

  @override
  void initState() {
    super.initState();
    _sales = widget.sales;
  }

  @override
  void didUpdateWidget(covariant SellerSaleSelectionSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sales != widget.sales) {
      setState(() {
        _sales = widget.sales;
        _selectedIndices
          ..clear()
          ..addAll(_selectedIndices.where((index) => index < _sales.length));
      });
    }
  }

  void _toggleSelection(int index, bool value) {
    setState(() {
      if (value) {
        _selectedIndices.add(index);
      } else {
        _selectedIndices.remove(index);
      }
    });
  }

  Future<void> _confirm() async {
    final selected = _selectedIndices.map((index) => _sales[index]).toList(growable: false);
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one sale item.')),
      );
      return;
    }

    Navigator.of(context).pop();
    await widget.onConfirm(selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        color: theme.colorScheme.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: bottomPadding + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                MySpacing.height(16),
                MyText.titleMedium('Create seller bill', fontWeight: 700),
                MySpacing.height(8),
                MyText.bodySmall(
                  'Seller: ${widget.formatCustomer(widget.seller)}',
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                MySpacing.height(20),
                SizedBox(
                  height: 360,
                  child: _sales.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.inventory_outlined, size: 48),
                              MySpacing.height(12),
                              MyText.bodyMedium('No unsold items recorded for this seller.'),
                              MySpacing.height(12),
                              OutlinedButton.icon(
                                onPressed: widget.onReload,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reload'),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _sales.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final sale = _sales[index];
                            final isChecked = _selectedIndices.contains(index);
                            final quantityLabel = '${sale.quantity.toStringAsFixed(sale.quantity % 1 == 0 ? 0 : 2)} ${sale.unit}';

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => _toggleSelection(index, !isChecked),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isChecked
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outline.withOpacity(0.15),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.shadow
                                            .withOpacity(isChecked ? 0.16 : 0.08),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: isChecked,
                                        onChanged: (value) =>
                                            _toggleSelection(index, value ?? false),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6)),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            MyText.bodyMedium(
                                              'Sale #${sale.id ?? '-'}',
                                              fontWeight: 700,
                                            ),
                                            MySpacing.height(4),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                MyText.bodySmall(
                                                    'Qty: $quantityLabel'),
                                                MyText.bodySmall(
                                                    'Rate: ₹${sale.sellingPrice.toStringAsFixed(2)}'),
                                                MyText.bodySmall(
                                                  'Total: ₹${sale.totalPrice.toStringAsFixed(2)}',
                                                  fontWeight: 600,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
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
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                          side: BorderSide(
                              color: theme.colorScheme.outline.withOpacity(0.4)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    MySpacing.width(16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _confirm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text('Select Items'),
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
