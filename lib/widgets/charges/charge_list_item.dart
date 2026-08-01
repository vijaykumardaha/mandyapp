import 'package:flutter/material.dart';
import 'package:krishimandi/models/charge_type_model.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';

class ChargeListItem extends StatelessWidget {
  final ChargeType charge;
  final ThemeData theme;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const ChargeListItem({
    super.key,
    required this.charge,
    required this.theme,
    this.isAdmin = true,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: MySpacing.bottom(8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: charge.isActive == 1
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.red.withValues(alpha: 0.1),
          child: Icon(
            charge.isActive == 1 ? Icons.check : Icons.close,
            size: 18,
            color: charge.isActive == 1 ? Colors.green : Colors.red,
          ),
        ),
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
                      ? Colors.purple.withValues(alpha: 0.1)
                      : theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: charge.chargeType == 'percentage'
                        ? Colors.purple.withValues(alpha: 0.3)
                        : theme.colorScheme.primary.withValues(alpha: 0.3),
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
                      ? Colors.blue.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: charge.chargeFor == 'buyer'
                        ? Colors.blue.withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: MyText.bodySmall(
                  charge.chargeFor == 'buyer' ? 'For Buyers' : 'For Sellers',
                  color:
                      charge.chargeFor == 'buyer' ? Colors.blue : Colors.orange,
                  fontWeight: 500,
                  fontSize: 10,
                ),
              ),
              if (charge.isDefault == 1)
                Container(
                  padding: MySpacing.xy(6, 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const MyText.bodySmall(
                    'Default',
                    color: Colors.green,
                    fontWeight: 500,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
        trailing: isAdmin
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'toggle') {
                    onToggle();
                  } else if (value == 'delete') {
                    onDelete();
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
                        const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
