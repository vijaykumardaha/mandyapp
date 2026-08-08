import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:krishimandi/blocs/order_item/order_item_bloc.dart';
import 'package:krishimandi/helpers/extensions/string.dart';
import 'package:krishimandi/models/customer_model.dart';
import 'package:krishimandi/models/product_variant_model.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';
import 'package:krishimandi/widgets/selling/variant_item_card.dart';

typedef AddToSaleSubmitCallback = Future<void> Function(
  ProductVariant variant,
  double quantity,
  double rate,
  Customer buyer,
);

class AddToSaleBottomSheet extends StatefulWidget {
  final List<ProductVariant> variants;
  final List<Customer> buyers;
  final AddToSaleSubmitCallback onSubmit;

  const AddToSaleBottomSheet({
    super.key,
    required this.variants,
    required this.buyers,
    required this.onSubmit,
  });

  @override
  State<AddToSaleBottomSheet> createState() => _AddToSaleBottomSheetState();
}

class _AddToSaleBottomSheetState extends State<AddToSaleBottomSheet> {
  final Map<int, TextEditingController> _quantityControllers = {};
  final Map<int, TextEditingController> _rateControllers = {};
  String _successMessage = '';
  String _pendingSuccessMessage = '';
  Timer? _successTimer;
  int? _selectedBuyerId;

  Customer? get _selectedBuyer {
    for (final buyer in widget.buyers) {
      if (buyer.id == _selectedBuyerId) return buyer;
    }
    return null;
  }

  Widget _buildBuyerSearchField(ThemeData theme) {
    return InkWell(
      onTap: _openBuyerPicker,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: 'Search buyer...',
          prefixIcon: const Icon(Icons.person_outline, size: 20),
          suffixIcon: _selectedBuyer != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    setState(() {
                      _selectedBuyerId = null;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              : null,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Text(
          _selectedBuyer?.name ?? 'Select buyer',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Future<void> _openBuyerPicker() async {
    final selected = await Navigator.of(context).push<Customer>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _BuyerPickerScreen(
          buyers: widget.buyers,
          selectedBuyerId: _selectedBuyerId,
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() {
        _selectedBuyerId = selected.id;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    for (var i = 0; i < widget.variants.length; i++) {
      final variant = widget.variants[i];
      final key = _keyForVariant(variant, i);
      _quantityControllers[key] = TextEditingController(
        text: variant.quantity.toStringAsFixed(2),
      );
      _rateControllers[key] = TextEditingController(
        text: variant.sellingPrice.toStringAsFixed(2),
      );
    }
  }

  @override
  void dispose() {
    _successTimer?.cancel();
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    for (final controller in _rateControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int _keyForVariant(ProductVariant variant, int index) {
    return variant.id ?? (-index - 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<OrderItemBloc, OrderItemState>(
      listener: (context, state) {
        if (state is OrderItemsLoaded && _pendingSuccessMessage.isNotEmpty) {
          _successTimer?.cancel();
          setState(() {
            _successMessage = _pendingSuccessMessage;
            _pendingSuccessMessage = '';
          });
          // Auto-dismiss so the bar doesn't linger; a fresh add clears and
          // re-shows it with the newly added item's name.
          _successTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _successMessage = '';
              });
            }
          });
        }
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(0, 24, 0, bottomInset + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success message at first position; animates in/out on change.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: _successMessage.isEmpty
                  ? const SizedBox.shrink()
                  : Container(
                      key: ValueKey(_successMessage),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _successMessage,
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText.bodySmall(
                    'Buyer',
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: 600,
                  ),
                  MySpacing.height(4),
                  _buildBuyerSearchField(theme),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 480),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.variants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 5),
                itemBuilder: (context, index) {
                  final variant = widget.variants[index];
                  final key = _keyForVariant(variant, index);
                  final qtyController = _quantityControllers[key]!;
                  final rateController = _rateControllers[key]!;

                  return VariantItemCard(
                    variant: variant,
                    qtyController: qtyController,
                    rateController: rateController,
                    theme: theme,
                    isAddEnabled: _selectedBuyer != null,
                    onAddPressed: () async {
                      final buyer = _selectedBuyer;
                      if (buyer == null) {
                        return;
                      }

                      final quantity =
                          double.tryParse(qtyController.text.trim());
                      if (quantity == null || quantity <= 0) {
                        // Show error in the UI directly
                        return;
                      }

                      final rate = double.tryParse(rateController.text.trim());
                      if (rate == null || rate <= 0) {
                        // Show error in the UI directly
                        return;
                      }

                      final qtyLabel = quantity % 1 == 0
                          ? quantity.toStringAsFixed(0)
                          : quantity.toStringAsFixed(2);
                      // Clear any lingering success bar, then stage the
                      // message naming the item, quantity, and rate added.
                      _successTimer?.cancel();
                      setState(() {
                        _successMessage = '';
                        _pendingSuccessMessage =
                            '${variant.variantName} · $qtyLabel ${variant.unit.unitAbbreviation} × ₹${rate.toStringAsFixed(2)} added to cart.';
                      });

                      try {
                        await widget.onSubmit(
                          variant,
                          quantity,
                          rate,
                          buyer,
                        );
                      } catch (e) {
                        debugPrint('Error adding item to sale: $e');
                        setState(() {
                          _pendingSuccessMessage = '';
                        });
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _BuyerPickerScreen extends StatefulWidget {
  final List<Customer> buyers;
  final int? selectedBuyerId;

  const _BuyerPickerScreen({
    required this.buyers,
    this.selectedBuyerId,
  });

  @override
  State<_BuyerPickerScreen> createState() => _BuyerPickerScreenState();
}

class _BuyerPickerScreenState extends State<_BuyerPickerScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = _query.toLowerCase();
    final buyers = widget.buyers.where((b) {
      final name = (b.name ?? '').toLowerCase();
      final phone = (b.phone ?? '').toLowerCase();
      return name.contains(q) || phone.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search buyer...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _query = value;
            });
          },
        ),
      ),
      body: ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: buyers.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
        itemBuilder: (context, index) {
          final buyer = buyers[index];
          final name = buyer.name ?? 'Unnamed';
          final initials = name.length >= 2
              ? name.substring(0, 2).toUpperCase()
              : name.toUpperCase();
          final isSelected =
              buyer.id != null && buyer.id == widget.selectedBuyerId;
          return ListTile(
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: MyText.bodySmall(
                initials,
                color: theme.colorScheme.primary,
                fontWeight: 600,
                fontSize: 11,
              ),
            ),
            title: MyText.bodyMedium(
              name,
              fontWeight: 600,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: buyer.phone != null
                ? MyText.bodySmall(
                    buyer.phone!,
                    color: theme.colorScheme.onSurfaceVariant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: isSelected
                ? Icon(Icons.check, color: theme.colorScheme.primary)
                : null,
            onTap: () => Navigator.of(context).pop(buyer),
          );
        },
      ),
    );
  }
}
