import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/charge_types/charge_types_bloc.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/order_model.dart';
import 'package:mandyapp/models/charge_type_model.dart';

class ChargesSection extends StatefulWidget {
  final Order order;
  final Set<int> selectedChargeIds;
  final Map<int, TextEditingController> chargeControllers;
  final Function(Set<int>, Map<int, TextEditingController>) onChargesChanged;
  final Function() onSchedulePersistCheckout;
  final Function(List<ChargeType>) onShowChargeSelectionDialog;
  final bool initialChargesApplied;
  final Function(List<ChargeType>) applyInitialCharges;

  const ChargesSection({
    Key? key,
    required this.order,
    required this.selectedChargeIds,
    required this.chargeControllers,
    required this.onChargesChanged,
    required this.onSchedulePersistCheckout,
    required this.onShowChargeSelectionDialog,
    required this.initialChargesApplied,
    required this.applyInitialCharges,
  }) : super(key: key);

  @override
  State<ChargesSection> createState() => _ChargesSectionState();
}

class _ChargesSectionState extends State<ChargesSection> {
  bool _chargesExpanded = true;
  final Map<int, ChargeType> _chargesById = {};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChargeTypesBloc, ChargeTypesState>(
      builder: (context, state) {
        if (state is ChargeTypesLoaded) {
          if (!widget.initialChargesApplied) {
            widget.applyInitialCharges(state.chargeTypes);
          }

          // Filter active charges by order type
          final activeCharges = state.chargeTypes
              .where((charge) => charge.isActive == 1 && charge.chargeFor == widget.order.orderFor)
              .toList();

          _chargesById
            ..clear()
            ..addEntries(activeCharges.where((charge) => charge.id != null).map((charge) => MapEntry(charge.id!, charge)));

          if (activeCharges.isEmpty) {
            return _buildNoChargesSection();
          }

          return _buildChargesSection(state, activeCharges);
        }

        return _buildLoadingSection();
      },
    );
  }

  Widget _buildNoChargesSection() {
    return Container(
      margin: MySpacing.bottom(12),
      padding: MySpacing.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              MySpacing.width(8),
              MyText.bodyMedium('Charges', fontWeight: 600),
              const Spacer(),
              Container(
                padding: MySpacing.xy(8, 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: MyText.bodySmall(
                  'No Charges',
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: 600,
                ),
              ),
            ],
          ),
          MySpacing.height(12),
          Container(
            padding: MySpacing.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                MySpacing.width(8),
                Expanded(
                  child: MyText.bodySmall(
                    'No active charges for ${widget.order.orderFor == 'buyer' ? 'buyers' : 'sellers'}',
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargesSection(ChargeTypesState state, List<ChargeType> activeCharges) {
    return Container(
      margin: MySpacing.bottom(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: MySpacing.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                MySpacing.width(8),
                MyText.bodyLarge('Charges', fontWeight: 600),
                const Spacer(),
                Container(
                  padding: MySpacing.xy(8, 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: MyText.bodySmall(
                    '${widget.selectedChargeIds.length} Charge${widget.selectedChargeIds.length != 1 ? 's' : ''}',
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: 600,
                  ),
                ),
                MySpacing.width(8),
                InkWell(
                  onTap: () => widget.onShowChargeSelectionDialog(
                    (state as ChargeTypesLoaded).chargeTypes.where((charge) => charge.isActive == 1).toList(),
                  ),
                  child: Container(
                    padding: MySpacing.xy(8, 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.white,
                        ),
                        MySpacing.width(4),
                        MyText.bodySmall(
                          'Add',
                          color: Colors.white,
                          fontWeight: 600,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Charges Content
          if (_chargesExpanded) ..._buildChargeItems(activeCharges),
        ],
      ),
    );
  }

  List<Widget> _buildChargeItems(List<ChargeType> activeCharges) {
    return [
      MySpacing.height(12),
      ...activeCharges.where((charge) => widget.selectedChargeIds.contains(charge.id)).map((charge) {
        // Create controller for this charge if it doesn't exist
        if (!widget.chargeControllers.containsKey(charge.id)) {
          final calculatedAmount = charge.chargeType == 'percentage'
              ? widget.order.totalPrice * charge.chargeAmount / 100
              : charge.chargeAmount;
          widget.chargeControllers[charge.id!] = TextEditingController(
            text: calculatedAmount.toStringAsFixed(2),
          );
        }

        return _buildChargeItem(charge);
      }).toList(),
    ];
  }

  Widget _buildChargeItem(ChargeType charge) {
    return Padding(
      padding: MySpacing.bottom(12),
      child: Container(
        padding: MySpacing.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            // Charge Icon and Name
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    padding: MySpacing.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  MySpacing.width(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText.bodyMedium(
                          charge.chargeName,
                          fontWeight: 600,
                        ),
                        MySpacing.height(2),
                        MyText.bodySmall(
                          charge.chargeType == 'percentage'
                              ? '${charge.chargeAmount.toStringAsFixed(1)}% of total'
                              : 'Fixed amount',
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            MySpacing.width(12),

            // Amount Input
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: widget.chargeControllers[charge.id!],
                  decoration: InputDecoration(
                    contentPadding: MySpacing.xy(12, 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    prefixText: '₹',
                    hintText: '0.00',
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    widget.onSchedulePersistCheckout();
                  },
                ),
              ),
            ),
            MySpacing.width(8),

            // Delete Button
            InkWell(
              onTap: () {
                final newSelectedIds = Set<int>.from(widget.selectedChargeIds);
                final newControllers = Map<int, TextEditingController>.from(widget.chargeControllers);
                
                newSelectedIds.remove(charge.id!);
                newControllers.remove(charge.id!);
                
                widget.onChargesChanged(newSelectedIds, newControllers);
                widget.onSchedulePersistCheckout();
              },
              child: Container(
                padding: MySpacing.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Container(
      margin: MySpacing.bottom(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: MySpacing.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                MySpacing.width(8),
                MyText.bodyLarge('Charges', fontWeight: 600),
                const Spacer(),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          // Loading Content
          Padding(
            padding: MySpacing.all(16),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  MySpacing.height(12),
                  MyText.bodyMedium(
                    'Loading charges...',
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
