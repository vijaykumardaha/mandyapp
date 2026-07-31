import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandiapp/blocs/charge_types/charge_types_bloc.dart';
import 'package:mandiapp/helpers/theme/app_theme.dart';
import 'package:mandiapp/models/charge_type_model.dart';
import 'package:mandiapp/services/sync_service.dart';
import 'package:mandiapp/utils/app_helper.dart';
import 'package:mandiapp/utils/constants.dart';
import 'package:mandiapp/utils/info_controller.dart';
import 'package:mandiapp/widgets/charges/charge_list_item.dart';
import 'package:mandiapp/widgets/common/common_app_bar.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';

class ChargeTypesScreen extends StatefulWidget {
  const ChargeTypesScreen({super.key});

  @override
  State<ChargeTypesScreen> createState() => _ChargeTypesScreenState();
}

class _ChargeTypesScreenState extends State<ChargeTypesScreen> {
  late ThemeData theme;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isAdmin = true;
  StreamSubscription<String>? _syncSubscription;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    _loadRole();
    context.read<ChargeTypesBloc>().add(LoadChargeTypes());

    _syncSubscription = SyncService.instance.tableUpdates.listen((table) {
      if (!mounted) return;
      if (table == DbTables.chargeTypes) {
        final state = context.read<ChargeTypesBloc>().state;
        if (state is ChargeTypesLoaded) {
          context.read<ChargeTypesBloc>().add(LoadChargeTypes());
        }
      }
    });
  }

  Future<void> _loadRole() async {
    final user = await AppHelper.getCurrentUser();
    if (mounted) {
      setState(() {
        _isAdmin = user?.isAdmin ?? true;
      });
    }
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<ChargeType> _filterCharges(List<ChargeType> charges) {
    if (_searchQuery.isEmpty) return charges;
    return charges
        .where((c) =>
            c.chargeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.chargeType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.chargeFor.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _showChargeTypeDialog([ChargeType? charge]) {
    final isEditing = charge != null;
    final nameController =
        TextEditingController(text: charge?.chargeName ?? '');
    final amountController = TextEditingController(
      text: charge?.chargeAmount.toString() ?? '',
    );
    String selectedType = charge?.chargeType ?? 'fixed';
    String selectedChargeTypeFor = charge?.chargeFor ?? 'buyer';
    bool isDefault = charge?.isDefault == 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MyText.titleMedium(
                  isEditing ? 'Edit Charge Type' : 'Add Charge Type',
                  fontWeight: 600,
                ),
                MySpacing.height(16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Charge Type Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                MySpacing.height(12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  decoration: const InputDecoration(
                    labelText: 'Charge Type Type',
                    border: OutlineInputBorder(),
                    helperText: 'Choose how the charge amount is calculated',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'fixed',
                      child: Row(
                        children: [
                          Icon(Icons.attach_money, size: 16),
                          SizedBox(width: 8),
                          Text('Fixed Amount'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'percentage',
                      child: Row(
                        children: [
                          Icon(Icons.percent, size: 16),
                          SizedBox(width: 8),
                          Text('Percentage'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setSheetState(() {
                        selectedType = value;
                      });
                    }
                  },
                ),
                MySpacing.height(12),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: selectedType == 'percentage'
                        ? 'Percentage (%)'
                        : 'Fixed Amount (₹)',
                    border: const OutlineInputBorder(),
                    helperText: selectedType == 'percentage'
                        ? 'Enter percentage value (e.g., 5.5 for 5.5%)'
                        : 'Enter fixed amount in rupees',
                  ),
                  keyboardType: TextInputType.number,
                ),
                MySpacing.height(12),
                DropdownButtonFormField<String>(
                  value: selectedChargeTypeFor,
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  decoration: const InputDecoration(
                    labelText: 'Apply to',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'buyer', child: Text('Buyers')),
                    DropdownMenuItem(value: 'seller', child: Text('Sellers')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setSheetState(() {
                        selectedChargeTypeFor = value;
                      });
                    }
                  },
                ),
                MySpacing.height(12),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setSheetState(() => isDefault = !isDefault),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDefault
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade400,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isDefault
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.08)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isDefault,
                          onChanged: (value) {
                            setSheetState(() {
                              isDefault = value ?? false;
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        MySpacing.width(4),
                        const MyText.bodyMedium('Set as default charge'),
                      ],
                    ),
                  ),
                ),
                MySpacing.height(16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const MyText.bodyMedium('Cancel'),
                      ),
                    ),
                    MySpacing.width(12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final chargeAmount =
                              double.tryParse(amountController.text);
                          if (chargeAmount == null || chargeAmount < 0) {
                            Info.message('Please enter a valid amount',
                                context: sheetContext);
                            return;
                          }

                          final newChargeType = ChargeType(
                            id: charge?.id,
                            mandiId: charge?.mandiId,
                            chargeName: nameController.text,
                            chargeType: selectedType,
                            chargeAmount: chargeAmount,
                            chargeFor: selectedChargeTypeFor,
                            isDefault: isDefault ? 1 : 0,
                            isActive: charge?.isActive ?? 1,
                          );

                          if (isEditing) {
                            context
                                .read<ChargeTypesBloc>()
                                .add(UpdateChargeType(newChargeType));
                          } else {
                            context
                                .read<ChargeTypesBloc>()
                                .add(CreateChargeType(newChargeType));
                          }
                          Navigator.pop(sheetContext);
                        },
                        child: MyText.bodyMedium(isEditing ? 'Update' : 'Add'),
                      ),
                    ),
                  ],
                ),
                MySpacing.height(16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteChargeType(ChargeType charge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const MyText.titleMedium('Delete Charge Type', fontWeight: 600),
        content: MyText.bodyMedium(
          'Are you sure you want to delete "${charge.chargeName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const MyText.bodyMedium('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ChargeTypesBloc>().add(DeleteChargeType(charge.id!));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const MyText.bodyMedium('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleChargeTypeStatus(ChargeType charge) {
    context.read<ChargeTypesBloc>().add(ToggleChargeTypeStatus(
          chargeTypeId: charge.id!,
          activate: charge.isActive == 0, // Activate if currently inactive
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        titleWidget: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search charges...',
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            prefixIcon: Icon(Icons.search,
                size: 20, color: theme.colorScheme.onSurfaceVariant),
            prefixIconConstraints: const BoxConstraints(minWidth: 36),
            suffixIcon: _isAdmin
                ? IconButton(
                    icon: Icon(Icons.add,
                        size: 20, color: theme.colorScheme.onSurfaceVariant),
                    tooltip: 'Add Charge',
                    onPressed: () => _showChargeTypeDialog(),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 40),
          ),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<ChargeTypesBloc, ChargeTypesState>(
          listener: (context, state) {
            if (state is ChargeTypesError) {
              Info.error(state.message, context: context);
            } else if (state is ChargeTypesOperationSuccess) {
              Info.message(state.message, context: context);
              // Reload the charge types after successful operation
              context.read<ChargeTypesBloc>().add(LoadChargeTypes());
            }
          },
          builder: (context, state) {
            if (state is ChargeTypesLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ChargeTypesLoaded) {
              final charges = _filterCharges(state.chargeTypes);
              if (charges.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      MySpacing.height(16),
                      MyText.bodyLarge(
                        'No charges found',
                        color: theme.colorScheme.outline,
                      ),
                      MySpacing.height(8),
                      MyText.bodyMedium(
                        'Tap the + button to add your first charge',
                        color: theme.colorScheme.outline,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: MySpacing.all(16),
                itemCount: charges.length,
                itemBuilder: (context, index) {
                  final charge = charges[index];
                  return ChargeListItem(
                    charge: charge,
                    theme: theme,
                    isAdmin: _isAdmin,
                    onEdit: () => _showChargeTypeDialog(charge),
                    onToggle: () => _toggleChargeTypeStatus(charge),
                    onDelete: () => _deleteChargeType(charge),
                  );
                },
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
