import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandyapp/blocs/checkout/checkout_bloc.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/models/cart_model.dart';
import 'package:mandyapp/models/cart_item_model.dart';
import 'package:mandyapp/models/product_model.dart';
import 'package:mandyapp/models/product_variant_model.dart';

class CheckoutScreen extends StatefulWidget {
  final int cartId;

  const CheckoutScreen({Key? key, required this.cartId}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {

  @override
  void initState() {
    super.initState();
    // Load cart details using CheckoutBloc
    context.read<CheckoutBloc>().add(LoadCheckoutCart(widget.cartId));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<CheckoutBloc, CheckoutState>(
          builder: (context, state) {
            if (state is CheckoutCartLoaded || state is CheckoutDataLoaded) {
              final cart = state is CheckoutCartLoaded ? state.cart :
                          (state as CheckoutDataLoaded).cart;
              return MyText.titleMedium('Checkout - ${cart.name ?? 'Cart'}');
            }
            return MyText.titleMedium('Checkout');
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<CheckoutBloc, CheckoutState>(
        builder: (context, state) {
          if (state is CheckoutLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CheckoutCartLoaded) {
            final cart = state.cart;
            if (cart.items == null || cart.items!.isEmpty) {
              return _buildEmptyCart();
            }

            return _buildCheckoutContent(cart, {}, {});
          }

          if (state is CheckoutDataLoaded) {
            return _buildCheckoutContent(state.cart, state.products, state.variants);
          }

          if (state is CheckoutError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                  MySpacing.height(16),
                  MyText.bodyLarge('Error loading cart', color: Theme.of(context).colorScheme.error),
                  MySpacing.height(8),
                  MyText.bodyMedium(state.message, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  MySpacing.height(16),
                  ElevatedButton(
                    onPressed: () {
                      // Retry loading cart
                      context.read<CheckoutBloc>().add(LoadCheckoutCart(widget.cartId));
                    },
                    child: MyText.bodyMedium('Retry'),
                  ),
                ],
              ),
            );
          }

          return _buildEmptyCart();
        },
      ),
    );
  }
  }


  Widget _buildEmptyCart() {
    return BlocBuilder<CheckoutBloc, CheckoutState>(
      builder: (context, state) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
              MySpacing.height(16),
              MyText.bodyLarge('Cart is empty', color: Theme.of(context).colorScheme.outline),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCheckoutContent(Cart cart, Map<int, Product> products, Map<int, ProductVariant> variants) {
    return Column(
      children: [
        // Cart Summary Header
        BlocBuilder<CheckoutBloc, CheckoutState>(
          builder: (context, state) {
            return Container(
              padding: MySpacing.all(16),
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MyText.bodyLarge('Bill Summary', fontWeight: 600),
                  MyText.bodyLarge(
                    '${cart.itemCount} items',
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: 600,
                  ),
                ],
              ),
            );
          },
        ),

        // Items List
        Expanded(
          child: ListView.builder(
            padding: MySpacing.all(16),
            itemCount: cart.items!.length,
            itemBuilder: (context, index) {
              final item = cart.items![index];
              final product = products[item.productId];
              final variant = variants[item.variantId];

              if (product == null || variant == null) {
                return const SizedBox.shrink();
              }

              return _buildBillItem(context, item, product, variant);
            },
          ),
        ),

        // Bill Footer
        _buildBillFooter(cart),
      ],
    );
  }

  Widget _buildBillItem(BuildContext context, CartItem item, Product product, ProductVariant variant) {
    final theme = Theme.of(context);

    return Container(
      margin: MySpacing.bottom(12),
      padding: MySpacing.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: variant.imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      variant.imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.inventory_2,
                          size: 24,
                          color: theme.colorScheme.onSurfaceVariant,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.inventory_2,
                    size: 24,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
          ),

          MySpacing.width(8),

          // Product Details & Quantity Controls
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Product Name
                MyText.bodySmall(
                  product.name,
                  fontWeight: 600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  fontSize: 12,
                ),

                MySpacing.height(2),

                // Variant Name
                MyText.bodySmall(
                  '${variant.variantName ?? '${variant.quantity}${variant.unit}'}',
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 10,
                ),

                MySpacing.height(6),

                // Quantity Controls (Horizontal Layout)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Decrement Button
                    InkWell(
                      onTap: () => _updateItemQuantity(context, item, -1),
                      child: Container(
                        padding: MySpacing.xy(6, 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.remove,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),

                    MySpacing.width(8),

                    // Quantity Display
                    Container(
                      padding: MySpacing.xy(8, 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: MyText.bodySmall(
                        '${item.quantity.toInt()}',
                        color: Colors.white,
                        fontWeight: 700,
                        fontSize: 11,
                      ),
                    ),

                    MySpacing.width(8),

                    // Increment Button
                    InkWell(
                      onTap: () => _updateItemQuantity(context, item, 1),
                      child: Container(
                        padding: MySpacing.xy(6, 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.add,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          MySpacing.width(8),

          // Price Details
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              MyText.bodyMedium(
                '₹${item.totalPrice.toStringAsFixed(2)}',
                fontWeight: 700,
                color: theme.colorScheme.primary,
                fontSize: 14,
              ),
              MySpacing.height(2),
              MyText.bodySmall(
                '₹${item.unitPrice.toStringAsFixed(2)} each',
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 9,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillFooter(Cart cart) {
    return BlocBuilder<CheckoutBloc, CheckoutState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final primaryColor = theme.colorScheme.primary;

        return Container(
          padding: MySpacing.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
          ),
          child: Column(
            children: [
              // Total Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MyText.titleMedium('Total Amount', fontWeight: 600),
                  MyText.titleMedium(
                    '₹${cart.totalPrice.toStringAsFixed(2)}',
                    fontWeight: 700,
                    color: primaryColor,
                  ),
                ],
              ),

              MySpacing.height(16),

              // Checkout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _completeCheckout(context, cart.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: MySpacing.y(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: MyText.bodyLarge(
                    'Complete Order',
                    fontWeight: 700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateItemQuantity(BuildContext context, CartItem item, int change) {
    if (change > 0) {
      // Increment quantity
      final updatedItem = item.copyWith(
        quantity: item.quantity + 1,
        totalPrice: (item.quantity + 1) * item.unitPrice,
      );
      context.read<CheckoutBloc>().add(UpdateCheckoutItem(updatedItem));
    } else if (change < 0) {
      // Decrement quantity
      if (item.quantity > 1) {
        final updatedItem = item.copyWith(
          quantity: item.quantity - 1,
          totalPrice: (item.quantity - 1) * item.unitPrice,
        );
        context.read<CheckoutBloc>().add(UpdateCheckoutItem(updatedItem));
      } else {
        // Remove item if quantity would become 0
        context.read<CheckoutBloc>().add(RemoveCheckoutItem(item));
      }
    }
  }

  void _completeCheckout(BuildContext context, int cartId) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: MyText.titleMedium('Complete Order?', fontWeight: 600),
        content: MyText.bodyMedium(
          'This will mark the cart as completed and finalize the order.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: MyText.bodyMedium('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Complete checkout using CheckoutBloc
              context.read<CheckoutBloc>().add(CompleteCheckout(cartId));

              // Show success message and navigate back
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order completed successfully!')),
              );

              // Navigate back
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to selling screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
            ),
            child: MyText.bodyMedium('Complete', color: Colors.white),
          ),
        ],
      ),
    );
  }

