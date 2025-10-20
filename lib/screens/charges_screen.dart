import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/charges/charges_bloc.dart';
import 'package:mandyapp/blocs/charges/charges_event.dart';
import 'package:mandyapp/blocs/charges/charges_state.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/charge_model.dart';

class ChargesScreen extends StatefulWidget {
  const ChargesScreen({super.key});

  @override
  State<ChargesScreen> createState() => _ChargesScreenState();
}

class _ChargesScreenState extends State<ChargesScreen> {
  late ThemeData theme;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    context.read<ChargesBloc>().add(LoadCharges());
  }

  void _showChargeDialog([Charge? charge]) {
    final isEditing = charge != null;
    final nameController = TextEditingController(text: charge?.chargeName ?? '');
    final amountController = TextEditingController(
      text: charge?.chargeAmount.toString() ?? '',
    );
    String selectedType = charge?.chargeType ?? 'fixed';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: MyText.titleMedium(
          isEditing ? 'Edit Charge' : 'Add Charge',
          fontWeight: 600,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Charge Name',
                border: OutlineInputBorder(),
              ),
            ),
            MySpacing.height(16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Charge Amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            MySpacing.height(16),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'Charge Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount')),
                DropdownMenuItem(value: 'percentage', child: Text('Percentage')),
              ],
              onChanged: (value) {
                if (value != null) {
                  selectedType = value;
                }
              },
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
              if (nameController.text.isEmpty || amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.only(top: 16, left: 16, right: 16),
                    content: Text('Please fill all fields'),
                  ),
                );
                return;
              }

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

              final newCharge = Charge(
                id: charge?.id,
                chargeName: nameController.text,
                chargeType: selectedType,
                chargeAmount: chargeAmount,
                isActive: charge?.isActive ?? 1,
              );

              if (isEditing) {
                context.read<ChargesBloc>().add(UpdateCharge(newCharge));
              } else {
                context.read<ChargesBloc>().add(AddCharge(newCharge));
              }
              Navigator.pop(context);
            },
            child: MyText.bodyMedium(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _deleteCharge(Charge charge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: MyText.titleMedium('Delete Charge', fontWeight: 600),
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
              context.read<ChargesBloc>().add(DeleteCharge(charge.id!));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: MyText.bodyMedium('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleChargeStatus(Charge charge) {
    context.read<ChargesBloc>().add(ToggleChargeStatus(charge));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: MyText.titleLarge('Charges Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showChargeDialog(),
          ),
        ],
      ),
      body: BlocConsumer<ChargesBloc, ChargesState>(
        listener: (context, state) {
          if (state is ChargesError) {
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
          if (state is ChargesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ChargesLoaded) {
            if (state.charges.isEmpty) {
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
              itemCount: state.charges.length,
              itemBuilder: (context, index) {
                final charge = state.charges[index];
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
                    subtitle: MyText.bodyMedium(
                      charge.chargeType == 'percentage'
                          ? '${charge.chargeAmount.toStringAsFixed(2)}%'
                          : '\$${charge.chargeAmount.toStringAsFixed(2)}',
                      color: theme.colorScheme.primary,
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
                          onPressed: () => _toggleChargeStatus(charge),
                          tooltip: charge.isActive == 1
                              ? 'Deactivate'
                              : 'Activate',
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showChargeDialog(charge),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteCharge(charge),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
