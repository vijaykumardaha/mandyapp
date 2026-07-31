import 'package:flutter/material.dart';
import 'package:mandiapp/blocs/charge_types/charge_types_bloc.dart';
import 'package:mandiapp/models/charge_type_model.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';

class ChargesSectionWidget extends StatelessWidget {
  final String orderFor;
  final Set<int> selectedChargeIds;
  final ChargeTypesState chargesState;
  final double subtotal;
  final Function(Set<int>) onSelectionChanged;

  const ChargesSectionWidget({
    super.key,
    required this.orderFor,
    required this.selectedChargeIds,
    required this.chargesState,
    required this.subtotal,
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
          .where(
              (charge) => charge.isActive == 1 && charge.chargeFor == orderFor)
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
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildNoChargesSection(BuildContext context) {
    return Container(
      margin: MySpacing.bottom(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: MySpacing.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MyText.bodyMedium('Additional Charges', fontWeight: 600),
                MySpacing.height(2),
                MyText.bodySmall(
                  'Extra fees like delivery or service charges',
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
          MySpacing.height(12),
          Padding(
            padding: MySpacing.only(left: 12),
            child: MyText.bodySmall(
              'No extra charges for this order',
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargesSection(
      BuildContext context, List<ChargeType> activeCharges) {
    return Container(
      margin: MySpacing.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: MySpacing.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MyText.bodyMedium('Additional Charges', fontWeight: 600),
                MySpacing.height(2),
                MyText.bodySmall(
                  'Select any extra fees that apply',
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          ...activeCharges.map((charge) {
            if (charge.id == null) return const SizedBox.shrink();

            final isSelected = selectedChargeIds.contains(charge.id);

            return Padding(
              padding: MySpacing.only(left: 12, top: 8),
              child: InkWell(
                onTap: () {
                  final updated = Set<int>.from(selectedChargeIds);
                  if (isSelected) {
                    updated.remove(charge.id!);
                  } else {
                    updated.add(charge.id!);
                  }
                  onSelectionChanged(updated);
                },
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 20,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4),
                    ),
                    MySpacing.width(12),
                    Expanded(
                      child:
                          MyText.bodyMedium(charge.chargeName, fontWeight: 500),
                    ),
                    MyText.bodySmall(
                      charge.chargeType == 'percentage'
                          ? () {
                              final pct = charge.chargeAmount
                                  .toStringAsFixed(2)
                                  .replaceFirst(RegExp(r'\.?0+$'), '');
                              final amt = (subtotal * charge.chargeAmount / 100)
                                  .toStringAsFixed(2)
                                  .replaceFirst(RegExp(r'\.?0+$'), '');
                              return '$pct% = ₹$amt';
                            }()
                          : '₹${charge.chargeAmount.toStringAsFixed(2)}',
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            );
          }),
          MySpacing.height(16),
        ],
      ),
    );
  }
}
