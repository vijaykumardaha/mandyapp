import 'package:flutter/material.dart';
import 'package:mandiapp/models/product_variant_model.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';
import 'package:mandiapp/widgets/product_detail/variant_thumbnail.dart';

class VariantListItem extends StatelessWidget {
  final ProductVariant variant;
  final bool isDefault;
  final String variantKey;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String?> onDefaultChanged;
  final ThemeData theme;

  const VariantListItem({
    super.key,
    required this.variant,
    required this.isDefault,
    required this.variantKey,
    required this.onEdit,
    required this.onDelete,
    required this.onDefaultChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: MySpacing.bottom(8),
      padding: MySpacing.all(12),
      decoration: BoxDecoration(
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: isDefault
            ? theme.colorScheme.primary.withValues(alpha: 0.05)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Radio<String>(
            value: variantKey,
            groupValue: isDefault ? variantKey : null,
            onChanged: onDefaultChanged,
          ),
          if (variant.imagePath.isNotEmpty)
            Container(
              margin: MySpacing.only(right: 12, top: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: VariantThumbnail(imagePath: variant.imagePath),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MyText.bodyMedium(
                      variant.variantName,
                      fontWeight: 600,
                    ),
                    if (isDefault)
                      Container(
                        margin: MySpacing.only(left: 8),
                        padding: MySpacing.xy(8, 4),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: MyText.bodySmall(
                          'Default',
                          color: theme.colorScheme.primary,
                          fontWeight: 600,
                        ),
                      ),
                  ],
                ),
                MySpacing.height(4),
                MyText.bodySmall(
                  'Selling Price: ${variant.sellingPrice.toStringAsFixed(2)} | Quantity: ${variant.quantity.toStringAsFixed(2)} ${variant.unit}',
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
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
                    const MyText.bodyMedium('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, size: 20, color: Colors.red),
                    MySpacing.width(8),
                    const MyText.bodyMedium('Delete', color: Colors.red),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
