import 'package:flutter/material.dart';
import 'package:mandyapp/helpers/extensions/string.dart';
import 'package:mandyapp/widgets/common/my_spacing.dart';
import 'package:mandyapp/widgets/common/my_text.dart';
import 'package:mandyapp/models/product_model.dart';
import 'package:mandyapp/widgets/product_list/variant_image.dart';

class ProductCardWidget extends StatelessWidget {
  final Product product;
  final ThemeData theme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCardWidget({
    super.key,
    required this.product,
    required this.theme,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final variantCount = product.variantCount;
    final defaultVariant = product.defaultVariantModel;
    final variants = product.variants ?? [];

    return Card(
      margin: MySpacing.bottom(12),
      child: Padding(
        padding: MySpacing.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: defaultVariant != null && defaultVariant.imagePath.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: VariantImage(imagePath: defaultVariant.imagePath),
                    )
                  : Center(
                      child: Icon(
                        Icons.inventory_2,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                    ),
            ),
            MySpacing.width(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: MyText.bodyLarge(
                          defaultVariant?.variantName ?? 'Product #${product.id ?? ''}',
                          fontWeight: 600,
                        ),
                      ),
                      Container(
                        padding: MySpacing.xy(8, 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: MyText.bodySmall(
                          '$variantCount ${'variants'.tr()}',
                          fontSize: 11,
                          color: theme.colorScheme.onTertiaryContainer,
                          fontWeight: 600,
                        ),
                      ),
                    ],
                  ),
                  MySpacing.height(8),
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            ...variants.take(2).map((variant) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: MyText.bodySmall(
                                '₹${variant.sellingPrice.toStringAsFixed(0)} \\ ${variant.quantity} ${variant.unit}',
                                color: theme.colorScheme.primary,
                                fontSize: 10,
                              ),
                            )),
                            if (variants.length > 2)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onSurface.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: MyText.bodySmall(
                                  '+${variants.length - 2}',
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
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
                      MyText.bodyMedium('edit'.tr()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, size: 20, color: Colors.red),
                      MySpacing.width(8),
                      MyText.bodyMedium('delete'.tr(), color: Colors.red),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
