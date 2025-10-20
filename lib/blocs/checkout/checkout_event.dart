part of 'checkout_bloc.dart';

abstract class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => [];
}

// Load cart for checkout with product details
class LoadCheckoutCart extends CheckoutEvent {
  final int cartId;

  const LoadCheckoutCart(this.cartId);

  @override
  List<Object?> get props => [cartId];
}

// Load product details for cart items
class LoadProductDetails extends CheckoutEvent {
  final List<int> productIds;

  const LoadProductDetails(this.productIds);

  @override
  List<Object?> get props => [productIds];
}

// Load variant details for cart items
class LoadVariantDetails extends CheckoutEvent {
  final List<int> variantIds;

  const LoadVariantDetails(this.variantIds);

  @override
  List<Object?> get props => [variantIds];
}

// Complete checkout order
class CompleteCheckout extends CheckoutEvent {
  final int cartId;

  const CompleteCheckout(this.cartId);

  @override
  List<Object?> get props => [cartId];
}

// ==================== CHECKOUT ITEM OPERATIONS ====================

// Update cart item (for increment/decrement in checkout)
class UpdateCheckoutItem extends CheckoutEvent {
  final ItemSale item;

  const UpdateCheckoutItem(this.item);

  @override
  List<Object?> get props => [item];
}

// Remove item from cart (for removing items in checkout)
class RemoveCheckoutItem extends CheckoutEvent {
  final ItemSale item;

  const RemoveCheckoutItem(this.item);

  @override
  List<Object?> get props => [item];
}
