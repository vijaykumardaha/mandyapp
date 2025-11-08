import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/checkout/checkout_bloc.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/cart_model.dart';
import 'package:mandyapp/models/charge_model.dart';

class ChargeSelectionDialog extends StatefulWidget {
  final List<Charge> availableCharges;
  final Set<int> selectedChargeIds;
  final Function(Set<int>) onApply;

  const ChargeSelectionDialog({
    Key? key,
    required this.availableCharges,
    required this.selectedChargeIds,
    required this.onApply,
  }) : super(key: key);

  @override
  State<ChargeSelectionDialog> createState() => _ChargeSelectionDialogState();

  static Future<Set<int>?> show(
    BuildContext context, {
    required List<Charge> availableCharges,
    required Set<int> selectedChargeIds,
  }) async {
    Set<int> tempSelectedIds = Set.from(selectedChargeIds);
    final checkoutState = context.read<CheckoutBloc>().state;
    
    if (checkoutState is! CheckoutDataLoaded) {
      return null;
    }

    final cart = checkoutState.cart;
    final filteredCharges = availableCharges.where((charge) => charge.chargeFor == cart.cartFor).toList();

    final result = await showDialog<Set<int>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          title: MyText.titleMedium('Select Charges', fontWeight: 600),
          content: SizedBox(
            width: double.maxFinite,
            child: filteredCharges.isEmpty
                ? _buildEmptyState(context, cart)
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredCharges.length,
                    itemBuilder: (context, index) => _buildChargeItem(
                      context,
                      filteredCharges[index],
                      tempSelectedIds,
                      dialogSetState,
                      cart,
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: MyText.bodyMedium('Cancel'),
            ),
            if (filteredCharges.isNotEmpty)
              ElevatedButton(
                onPressed: () => Navigator.pop(context, tempSelectedIds),
                child: MyText.bodyMedium('Apply'),
              ),
          ],
        ),
      ),
    );

    return result;
  }

  static Widget _buildEmptyState(BuildContext context, Cart cart) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          MySpacing.height(16),
          MyText.bodyMedium(
            'No charges available for ${cart.cartFor == 'buyer' ? 'buyers' : 'sellers'}',
            color: Theme.of(context).colorScheme.outline,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget _buildChargeItem(
    BuildContext context,
    Charge charge,
    Set<int> tempSelectedIds,
    StateSetter dialogSetState,
    Cart cart,
  ) {
    final isSelected = tempSelectedIds.contains(charge.id);

    return Container(
      margin: MySpacing.bottom(8),
      padding: MySpacing.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: isSelected,
              onChanged: (value) {
                dialogSetState(() {
                  if (value == true) {
                    tempSelectedIds.add(charge.id!);
                  } else {
                    tempSelectedIds.remove(charge.id!);
                  }
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          MySpacing.width(12),

          // Charge Name
          Expanded(
            flex: 3,
            child: MyText.bodyMedium(
              charge.chargeName,
              fontWeight: 500,
            ),
          ),

          // Charge Type Badge
          Container(
            padding: MySpacing.xy(4, 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
              ),
            ),
            child: MyText.bodySmall(
              charge.chargeType == 'percentage' ? '${charge.chargeAmount.toStringAsFixed(1)}%' : 'Fixed',
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: 500,
              fontSize: 10,
            ),
          ),

          MySpacing.width(8),

          // Amount - Show calculated amount for both types
          MyText.bodyMedium(
            charge.chargeType == 'percentage'
                ? '₹${(cart.totalPrice * charge.chargeAmount / 100).toStringAsFixed(2)}'
                : '₹${charge.chargeAmount.toStringAsFixed(2)}',
            color: Theme.of(context).colorScheme.primary,
            fontWeight: 600,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This widget is primarily used via the static show() method
    return const SizedBox.shrink();
  }
}

class _ChargeSelectionDialogState extends State<ChargeSelectionDialog> {
  late Set<int> _selectedChargeIds;

  @override
  void initState() {
    super.initState();
    _selectedChargeIds = Set.from(widget.selectedChargeIds);
  }

  Widget _buildEmptyState(BuildContext context, Cart cart) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          MySpacing.height(16),
          MyText.bodyMedium(
            'No charges available for ${cart.cartFor == 'buyer' ? 'buyers' : 'sellers'}',
            color: Theme.of(context).colorScheme.outline,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChargeItem(
    BuildContext context,
    Charge charge,
    Set<int> selectedIds,
    void Function(void Function()) setStateCallback,
    Cart cart,
  ) {
    final isSelected = selectedIds.contains(charge.id);

    return Container(
      margin: MySpacing.bottom(8),
      padding: MySpacing.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: isSelected,
              onChanged: (value) {
                setStateCallback(() {
                  if (value == true) {
                    selectedIds.add(charge.id!);
                  } else {
                    selectedIds.remove(charge.id);
                  }
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          MySpacing.width(12),

          // Charge Name
          Expanded(
            flex: 3,
            child: MyText.bodyMedium(
              charge.chargeName,
              fontWeight: 500,
            ),
          ),

          // Charge Type Badge
          Container(
            padding: MySpacing.xy(4, 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
              ),
            ),
            child: MyText.bodySmall(
              charge.chargeType == 'percentage' ? '${charge.chargeAmount.toStringAsFixed(1)}%' : 'Fixed',
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: 500,
              fontSize: 10,
            ),
          ),

          MySpacing.width(8),

          // Amount - Show calculated amount for both types
          MyText.bodyMedium(
            charge.chargeType == 'percentage'
                ? '₹${(cart.totalPrice * charge.chargeAmount / 100).toStringAsFixed(2)}'
                : '₹${charge.chargeAmount.toStringAsFixed(2)}',
            color: Theme.of(context).colorScheme.primary,
            fontWeight: 600,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = context.read<CheckoutBloc>().state;
    
    if (checkoutState is! CheckoutDataLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final cart = checkoutState.cart;
    
    return AlertDialog(
      title: MyText.titleMedium('Select Charges', fontWeight: 600),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.availableCharges.isEmpty
            ? _buildEmptyState(context, cart)
            : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.availableCharges.length,
                itemBuilder: (context, index) => _buildChargeItem(
                  context,
                  widget.availableCharges[index],
                  _selectedChargeIds,
                  setState,
                  cart,
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: MyText.bodyMedium('Cancel'),
        ),
        if (widget.availableCharges.isNotEmpty)
          ElevatedButton(
            onPressed: () {
              widget.onApply(_selectedChargeIds);
              Navigator.pop(context);
            },
            child: MyText.bodyMedium('Apply'),
          ),
      ],
    );
  }
}
