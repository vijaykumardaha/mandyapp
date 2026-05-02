import 'package:flutter/material.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/models/order_item_model.dart';

class PaymentItemWidget extends StatefulWidget {
  final Customer seller;
  final List<OrderItem> sales;
  final String Function(Customer) formatCustomer;
  final void Function(OrderItem sale, int index) onDeleteSale;
  final Future<void> Function(List<OrderItem> selected) onConfirm;
  final VoidCallback? onEditSeller;

  const PaymentItemWidget({
    super.key,
    required this.seller,
    required this.sales,
    required this.formatCustomer,
    required this.onDeleteSale,
    required this.onConfirm,
    this.onEditSeller,
  });

  @override
  State<PaymentItemWidget> createState() => _PaymentItemWidgetState();
}

class _PaymentItemWidgetState extends State<PaymentItemWidget> {
  final Set<int> _selectedIndices = {};
  late List<OrderItem> _sales;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _sales = widget.sales;
    
    // Scroll to first selected item after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedIndices.isNotEmpty) {
        _scrollToFirstSelected();
      }
    });
  }

  @override
  void didUpdateWidget(covariant PaymentItemWidget oldWidget) {
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;
    
    // Calculate the position to scroll to
    final itemHeight = 100.0; // Approximate height of each item
    final targetPosition = index * itemHeight;
    
    // Scroll to the target position with animation
    _scrollController.animateTo(
      targetPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToFirstSelected() {
    if (_selectedIndices.isEmpty) return;
    
    final firstSelectedIndex = _selectedIndices.reduce((a, b) => a < b ? a : b);
    _scrollToIndex(firstSelectedIndex);
  }

  void _scrollToLastSelected() {
    if (_selectedIndices.isEmpty) return;
    
    final lastSelectedIndex = _selectedIndices.reduce((a, b) => a > b ? a : b);
    _scrollToIndex(lastSelectedIndex);
  }

  void _toggleSelection(int index, bool value) {
    setState(() {
      if (value) {
        _selectedIndices.add(index);
        // Scroll to the newly selected item
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToIndex(index);
        });
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

    await widget.onConfirm(selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Scrollable content area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MyText.bodySmall(
                              'Seller',
                              color: theme.colorScheme.primary,
                              fontWeight: 500,
                            ),
                            const SizedBox(height: 2),
                            MyText.bodyMedium(
                              widget.formatCustomer(widget.seller),
                              fontWeight: 600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ],
                        ),
                      ),
                                            IconButton(
                        onPressed: () {
                          // Go back to customer selection
                          if (widget.onEditSeller != null) {
                            widget.onEditSeller!();
                          }
                        },
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        tooltip: 'Change Seller',
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ),
                MySpacing.height(20),

                // Items List
                _sales.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 100),
                            const Icon(Icons.inventory_outlined, size: 48),
                            MySpacing.height(12),
                            MyText.bodyMedium('No unsold items recorded for this seller.'),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
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
                                                'Total: ₹${(sale.quantity * sale.sellingPrice).toStringAsFixed(2)}',
                                                fontWeight: 600,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                                                      ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
        
        // Sticky bottom button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),

          child: ElevatedButton(
            onPressed: _confirm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('Create Bill'),
          ),
        ),
      ],
    );
  }
}
