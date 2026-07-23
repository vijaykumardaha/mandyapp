import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/charge_types/charge_types_bloc.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/charge_type_model.dart';
import 'package:mandyapp/models/order_model.dart';
import 'package:mandyapp/widgets/checkout/charge_selection_dialog.dart';

class ChargesSectionWidget extends StatefulWidget {
  final Order order;
  final String orderFor;

  const ChargesSectionWidget({
    super.key,
    required this.order,
    required this.orderFor,
  });

  @override
  State<ChargesSectionWidget> createState() => _ChargesSectionWidgetState();
}

class _ChargesSectionWidgetState extends State<ChargesSectionWidget> {
  Set<int> _selectedChargeIds = {};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChargeTypesBloc, ChargeTypesState>(
      builder: (context, chargeState) {
        if (chargeState is ChargeTypesLoading) {
          return _buildLoadingSection();
        }

        if (chargeState is ChargeTypesLoaded) {
          final activeCharges = chargeState.chargeTypes
              .where((charge) =>
                  charge.isActive == 1 && charge.chargeFor == widget.orderFor)
              .toList();

          if (activeCharges.isEmpty) {
            return _buildNoChargesSection();
          }

          // Auto-select default charges
          for (final charge in activeCharges) {
            if (charge.isDefault == 1 && charge.id != null) {
              _selectedChargeIds.add(charge.id!);
            }
          }

          return _buildChargesSection(chargeState, activeCharges);
        }

        return _buildNoChargesSection();
      },
    );
  }

  Widget _buildLoadingSection() {
    return Container(
      margin: MySpacing.bottom(12),
      padding: MySpacing.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildNoChargesSection() {
    return Container(
      margin: MySpacing.bottom(12),
      padding: MySpacing.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              MySpacing.width(8),
              MyText.bodyMedium('Charges', fontWeight: 600),
            ],
          ),
          MySpacing.height(12),
          MyText.bodySmall(
            'No charges available',
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ],
      ),
    );
  }

  Widget _buildChargesSection(
      ChargeTypesState state, List<ChargeType> activeCharges) {
    return Container(
      margin: MySpacing.bottom(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: MySpacing.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                MySpacing.width(8),
                MyText.bodyMedium('Charges', fontWeight: 600),
              ],
            ),
          ),

          // Charges List
          ...activeCharges.map((charge) {
            if (charge.id == null) return const SizedBox.shrink();

            final isSelected = _selectedChargeIds.contains(charge.id);

            return Padding(
              padding: MySpacing.horizontal(16),
              child: CheckboxListTile(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedChargeIds.add(charge.id!);
                  } else {
                    _selectedChargeIds.remove(charge.id!);
                  }
                });
              },
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MyText.bodyMedium(charge.chargeName),
                  MyText.bodySmall(
                    '₹${charge.chargeAmount.toStringAsFixed(2)}',
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ],
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              dense: true,
            ),
            );
          }),
          MySpacing.height(16),
        ],
      ),
    );
  }

  Future<void> _showChargeSelectionDialog(List<ChargeType> currentCharges) async {
    final selectedIds = await ChargeSelectionDialog.show(
      context,
      availableCharges: currentCharges,
      selectedChargeIds: _selectedChargeIds,
    );

    if (selectedIds != null) {
      setState(() {
        _selectedChargeIds = selectedIds;
      });
    }
  }
}
