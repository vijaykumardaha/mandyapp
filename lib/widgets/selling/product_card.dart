import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/product_model.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final ThemeData theme;
  final VoidCallback? onAddTapped;

  const ProductCard({
    super.key,
    required this.product,
    required this.theme,
    this.onAddTapped,
  });

  static String productTitle(Product product) {
    return product.defaultVariantModel?.variantName ??
        'Product #${product.id ?? ''}';
  }

  static Widget buildImagePlaceholder(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.inventory_2,
        size: 32,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  static Widget buildVariantImage(String imagePath, ThemeData theme) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            buildImagePlaceholder(theme),
      );
    }
    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) =>
          buildImagePlaceholder(theme),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultVariant = product.defaultVariantModel;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                  child: defaultVariant != null &&
                          defaultVariant.imagePath.isNotEmpty
                      ? ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
                          child: ProductCard.buildVariantImage(
                              defaultVariant.imagePath, theme),
                        )
                      : ProductCard.buildImagePlaceholder(theme),
                ),
                if (defaultVariant != null)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Material(
                      color: theme.colorScheme.primary,
                      elevation: 4,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: onAddTapped,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_shopping_cart,
                                size: 18,
                                color: theme.colorScheme.onPrimary,
                              ),
                              const SizedBox(width: 6),
                              MyText.bodySmall(
                                'Add',
                                color: theme.colorScheme.onPrimary,
                                fontWeight: 600,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox.shrink(),
        ],
      ),
    );
  }
}
