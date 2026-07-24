import 'package:flutter/material.dart';
import 'package:mandyapp/blocs/charge_types/charge_types_bloc.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/charge_type_model.dart';

class ChargesSectionWidget extends StatelessWidget {
  final String orderFor;
  final Set<int> selectedChargeIds;
  final ChargeTypesState chargesState;
  final Function(Set<int>) onSelectionChanged;

  const ChargesSectionWidget({
    super.key,
    required this.orderFor,
    required this.selectedChargeIds,
    required this.chargesState,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (chargesState is ChargeTypesLoading) {
      return _buildLoadingSection(context);
    }

    final state = chargesState;
    if (state is ChargeTypesLoaded) {
      final activeCharges = state.chargeTypes
          .where((charge) =>
              charge.isActive == 1 && charge.chargeFor == orderFor)
          .toList();

      if (activeCharges.isEmpty) {
        return _buildNoChargesSection(context);
      }

      return _buildChargesSection(context, activeCharges);
    }

    return _buildNoChargesSection(context);
  }

  Widget _buildLoadingSection(BuildContext context) {
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

  Widget _buildNoChargesSection(BuildContext context) {
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
      BuildContext context, List<ChargeType> activeCharges) {
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
          ...activeCharges.map((charge) {
            if (charge.id == null) return const SizedBox.shrink();

            final isSelected = selectedChargeIds.contains(charge.id);

            return Padding(
              padding: MySpacing.horizontal(16),
              child: CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  final updated = Set<int>.from(selectedChargeIds);
                  if (value == true) {
                    updated.add(charge.id!);
                  } else {
                    updated.remove(charge.id!);
                  }
                  onSelectionChanged(updated);
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
}
