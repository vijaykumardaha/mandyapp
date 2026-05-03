import 'package:flutter/material.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';

class EmptyCart extends StatelessWidget {
  const EmptyCart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: MySpacing.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          MySpacing.height(16),
          MyText.bodyMedium(
            'Your cart is empty',
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          MySpacing.height(8),
          MyText.bodySmall(
            'Add items to get started',
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ],
      ),
    );
  }
}
