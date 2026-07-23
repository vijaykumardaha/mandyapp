import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/charge_types/charge_types_bloc.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/charge_type_model.dart';

class ChargeTypesScreen extends StatefulWidget {
  const ChargeTypesScreen({super.key});

  @override
  State<ChargeTypesScreen> createState() => _ChargeTypesScreenState();
}

class _ChargeTypesScreenState extends State<ChargeTypesScreen> {
  late ThemeData theme;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    context.read<ChargeTypesBloc>().add(LoadChargeTypes());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChargeType> _filterCharges(List<ChargeType> charges) {
    if (_searchQuery.isEmpty) return charges;
    return charges.where((c) =>
      c.chargeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      c.chargeType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      c.chargeFor.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  void _showChargeTypeDialog([ChargeType? charge]) {
    final isEditing = charge != null;
    final nameController = TextEditingController(text: charge?.chargeName ?? '');
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
                  isEditing ? 'Edit ChargeType' : 'Add ChargeType',
                  fontWeight: 600,
                ),
                MySpacing.height(16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'ChargeType Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                MySpacing.height(12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  decoration: const InputDecoration(
                    labelText: 'ChargeType Type',
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
                    labelText: selectedType == 'percentage' ? 'Percentage (%)' : 'Fixed Amount (₹)',
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDefault
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade400,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isDefault
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
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
                        MyText.bodyMedium('Set as default charge'),
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
                        child: MyText.bodyMedium('Cancel'),
                      ),
                    ),
                    MySpacing.width(12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final chargeAmount = double.tryParse(amountController.text);
                          if (chargeAmount == null || chargeAmount < 0) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(
                                behavior: SnackBarBehavior.floating,
                                margin: EdgeInsets.only(top: 16, left: 16, right: 16),
                                content: Text('Please enter a valid amount'),
                              ),
                            );
                            return;
                          }

                          final newChargeType = ChargeType(
                            id: charge?.id,
                            mandyId: charge?.mandyId,
                            chargeName: nameController.text,
                            chargeType: selectedType,
                            chargeAmount: chargeAmount,
                            chargeFor: selectedChargeTypeFor,
                            isDefault: isDefault ? 1 : 0,
                            isActive: charge?.isActive ?? 1,
                          );

                          if (isEditing) {
                            context.read<ChargeTypesBloc>().add(UpdateChargeType(newChargeType));
                          } else {
                            context.read<ChargeTypesBloc>().add(CreateChargeType(newChargeType));
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
        title: MyText.titleMedium('Delete ChargeType', fontWeight: 600),
        content: MyText.bodyMedium(
          'Are you sure you want to delete "${charge.chargeName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: MyText.bodyMedium('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ChargeTypesBloc>().add(DeleteChargeType(charge.id!));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: MyText.bodyMedium('Delete'),
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search charges...',
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            prefixIcon: Icon(Icons.search, size: 20, color: theme.colorScheme.onSurfaceVariant),
            prefixIconConstraints: const BoxConstraints(minWidth: 36),
            suffixIcon: IconButton(
              icon: Icon(Icons.add, size: 20, color: theme.colorScheme.onSurfaceVariant),
              tooltip: 'Add charge',
              onPressed: () => _showChargeTypeDialog(),
            ),
            suffixIconConstraints: const BoxConstraints(minWidth: 40),
          ),
        ),
      ),
      body: BlocConsumer<ChargeTypesBloc, ChargeTypesState>(
        listener: (context, state) {
          if (state is ChargeTypesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                content: Text(state.message),
              ),
            );
          } else if (state is ChargeTypesOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
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
                return Card(
                  margin: MySpacing.bottom(8),
                  child: ListTile(
                    title: MyText.bodyLarge(
                      charge.chargeName,
                      fontWeight: 500,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: MySpacing.xy(6, 2),
                              decoration: BoxDecoration(
                                color: charge.chargeType == 'percentage'
                                    ? Colors.purple.withOpacity(0.1)
                                    : theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: charge.chargeType == 'percentage'
                                      ? Colors.purple.withOpacity(0.3)
                                      : theme.colorScheme.primary.withOpacity(0.3),
                                ),
                              ),
                              child: MyText.bodySmall(
                                charge.chargeType == 'percentage'
                                    ? 'Percentage ${charge.chargeAmount.toStringAsFixed(2)}%'
                                    : 'Fixed ₹${charge.chargeAmount.toStringAsFixed(2)}',
                                color: charge.chargeType == 'percentage'
                                    ? Colors.purple
                                    : theme.colorScheme.primary,
                                fontWeight: 600,
                                fontSize: 10,
                              ),
                            ),
                            Container(
                              padding: MySpacing.xy(6, 2),
                              decoration: BoxDecoration(
                                color: charge.chargeFor == 'buyer'
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: charge.chargeFor == 'buyer'
                                      ? Colors.blue.withOpacity(0.3)
                                      : Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: MyText.bodySmall(
                                charge.chargeFor == 'buyer' ? 'For Buyers' : 'For Sellers',
                                color: charge.chargeFor == 'buyer' ? Colors.blue : Colors.orange,
                                fontWeight: 500,
                                fontSize: 10,
                              ),
                            ),
                            if (charge.isDefault == 1)
                              Container(
                                padding: MySpacing.xy(6, 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                  ),
                                ),
                                child: MyText.bodySmall(
                                  'Default',
                                  color: Colors.green,
                                  fontWeight: 500,
                                  fontSize: 10,
                                ),
                              ),
                            Container(
                              padding: MySpacing.xy(6, 2),
                              decoration: BoxDecoration(
                                color: charge.isActive == 1
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: charge.isActive == 1
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.red.withOpacity(0.3),
                                ),
                              ),
                              child: MyText.bodySmall(
                                charge.isActive == 1 ? 'Active' : 'Disabled',
                                color: charge.isActive == 1 ? Colors.green : Colors.red,
                                fontWeight: 500,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showChargeTypeDialog(charge);
                        } else if (value == 'toggle') {
                          _toggleChargeTypeStatus(charge);
                        } else if (value == 'delete') {
                          _deleteChargeType(charge);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit, size: 20),
                              MySpacing.width(8),
                              const Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                charge.isActive == 1
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 20,
                              ),
                              MySpacing.width(8),
                              Text(charge.isActive == 1 ? 'Disable' : 'Activate'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete, size: 20, color: Colors.red),
                              MySpacing.width(8),
                              const Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
