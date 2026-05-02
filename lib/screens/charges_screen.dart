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

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    context.read<ChargeTypesBloc>().add(LoadChargeTypes());
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: MyText.titleMedium(
            isEditing ? 'Edit ChargeType' : 'Add ChargeType',
            fontWeight: 600,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'ChargeType Name',
                  border: OutlineInputBorder(),
                ),
              ),
              MySpacing.height(16),
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
              MySpacing.height(16),
              DropdownButtonFormField<String>(
                value: selectedType,
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
                    setState(() {
                      selectedType = value;
                    });
                  }
                },
              ),
              MySpacing.height(16),
              DropdownButtonFormField<String>(
                value: selectedChargeTypeFor,
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
                    setState(() {
                      selectedChargeTypeFor = value;
                    });
                  }
                },
              ),
              MySpacing.height(16),
              Row(
                children: [
                  Checkbox(
                    value: isDefault,
                    onChanged: (value) {
                      setState(() {
                        isDefault = value ?? false;
                      });
                    },
                  ),
                  MyText.bodyMedium('Set as default charge'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: MyText.bodyMedium('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final chargeAmount = double.tryParse(amountController.text);
                if (chargeAmount == null || chargeAmount < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
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
                Navigator.pop(context);
              },
              child: MyText.bodyMedium(isEditing ? 'Update' : 'Add'),
            ),
          ],
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
        title: MyText.titleLarge('ChargeTypes Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showChargeTypeDialog(),
          ),
        ],
      ),
      body: BlocConsumer<ChargeTypesBloc, dynamic>(
        listener: (context, state) {
          // Check if state has message property (error state)
          if (state.toString().contains('ChargeTypesError') && state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                content: Text(state.message),
              ),
            );
          }
        },
        builder: (context, state) {
          // Check if state has charges property (loaded state)
          if (state.toString().contains('ChargeTypesLoaded')) {
            try {
              final charges = state.charges as List<ChargeType>?;
              if (charges == null || charges.isEmpty) {
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
                      leading: CircleAvatar(
                        backgroundColor: charge.isActive == 1
                            ? Colors.green
                            : Colors.grey,
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                        ),
                      ),
                      title: MyText.bodyLarge(
                        charge.chargeName,
                        fontWeight: 500,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyText.bodyMedium(
                            charge.chargeType == 'percentage'
                                ? '${charge.chargeAmount.toStringAsFixed(2)}%'
                                : '\$${charge.chargeAmount.toStringAsFixed(2)}',
                            color: theme.colorScheme.primary,
                          ),
                          MySpacing.height(4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: MySpacing.xy(4, 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: theme.colorScheme.secondary.withOpacity(0.3),
                                  ),
                                ),
                                child: MyText.bodySmall(
                                  charge.chargeType == 'percentage' ? 'Percentage' : 'Fixed',
                                  color: theme.colorScheme.secondary,
                                  fontWeight: 500,
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
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              charge.isActive == 1
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () => _toggleChargeTypeStatus(charge),
                            tooltip: charge.isActive == 1
                                ? 'Deactivate'
                                : 'Activate',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showChargeTypeDialog(charge),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteChargeType(charge),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            } catch (e) {
              return const Center(child: CircularProgressIndicator());
            }
          }

          // Default loading state
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
