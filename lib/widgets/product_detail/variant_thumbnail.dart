import 'dart:io';

import 'package:flutter/material.dart';

class VariantThumbnail extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;

  const VariantThumbnail({
    super.key,
    required this.imagePath,
    this.width = 50,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholder = Container(
      width: width,
      height: height,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_not_supported,
        size: 24,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );

    if (imagePath.isEmpty) {
      return placeholder;
    }

    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    }

    return Image.file(
      File(imagePath),
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}
