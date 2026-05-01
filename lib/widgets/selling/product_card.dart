import 'dart:io';

import 'package:flutter/material.dart';
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
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onAddTapped,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
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
            ),
            const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
