part of 'checkout_bloc.dart';

abstract class CheckoutState extends Equatable {
  const CheckoutState();

  @override
  List<Object?> get props => [];
}

// Initial state
class CheckoutInitial extends CheckoutState {}

// Loading state
class CheckoutLoading extends CheckoutState {}

// Cart loaded for checkout
class CheckoutCartLoaded extends CheckoutState {
  final Cart cart;

  const CheckoutCartLoaded(this.cart);

  @override
  List<Object?> get props => [cart];
}

// Product details loaded
class ProductDetailsLoaded extends CheckoutState {
  final Map<int, Product> products;

  const ProductDetailsLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

// Variant details loaded
class VariantDetailsLoaded extends CheckoutState {
  final Map<int, ProductVariant> variants;

  const VariantDetailsLoaded(this.variants);

  @override
  List<Object?> get props => [variants];
}

// All checkout data loaded (cart + products + variants)
class CheckoutDataLoaded extends CheckoutState {
  final Cart cart;
  final Map<int, Product> products;
  final Map<int, ProductVariant> variants;

  const CheckoutDataLoaded(this.cart, this.products, this.variants);

  @override
  List<Object?> get props => [cart, products, variants];
}

// Checkout completed successfully
class CheckoutCompleted extends CheckoutState {
  final String message;

  const CheckoutCompleted(this.message);

  @override
  List<Object?> get props => [message];
}

// Checkout error state
class CheckoutError extends CheckoutState {
  final String message;

  const CheckoutError(this.message);

  @override
  List<Object?> get props => [message];
}
