import 'package:flutter/material.dart';
import 'package:mandiapp/models/stock_model.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';

class StockListItem extends StatelessWidget {
  final Stock stock;
  final ThemeData theme;
  final bool isAdmin;
  final String? sellerName;
  final String? productName;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const StockListItem({
    super.key,
    required this.stock,
    required this.theme,
    this.isAdmin = true,
    this.sellerName,
    this.productName,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: MySpacing.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: MySpacing.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: MySpacing.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.inventory_2,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                MySpacing.width(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText.titleSmall(
                        productName ?? 'Product #${stock.productId}',
                        fontWeight: 600,
                      ),
                      MySpacing.height(2),
                      MyText.bodySmall(
                        sellerName ?? 'Seller #${stock.sellerId}',
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
                if (isAdmin)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit?.call();
                      if (value == 'delete') onDelete?.call();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      if (stock.soldQuantity <= 0)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
              ],
            ),
            MySpacing.height(10),
            Divider(
                height: 1, color: theme.dividerColor.withValues(alpha: 0.15)),
            MySpacing.height(10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Initial', stock.initialQuantity.toStringAsFixed(1)),
                _buildStat('Current', stock.quantity.toStringAsFixed(1)),
                _buildStat('Sold', stock.soldQuantity.toStringAsFixed(1)),
                _buildStat('Loss', stock.lossQuantity.toStringAsFixed(1)),
                _buildStat(
                    'Purchase', '₹${stock.purchaseAmount.toStringAsFixed(0)}'),
                _buildStat(
                    'Sold Amt', '₹${stock.soldAmount.toStringAsFixed(0)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText.bodySmall(
          label,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          fontSize: 10,
        ),
        const SizedBox(height: 2),
        MyText.bodyMedium(value, fontWeight: 600, fontSize: 13),
      ],
    );
  }
}
