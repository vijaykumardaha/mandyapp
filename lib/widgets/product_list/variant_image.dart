import 'dart:io';

import 'package:flutter/material.dart';

class VariantImage extends StatelessWidget {
  final String imagePath;

  const VariantImage({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholder = Icon(
      Icons.inventory_2,
      size: 32,
      color: theme.colorScheme.onSurfaceVariant,
    );

    if (imagePath.isEmpty) {
      return placeholder;
    }

    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    }

    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}
