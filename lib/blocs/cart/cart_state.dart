part of 'cart_bloc.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

// Initial state
class CartInitial extends CartState {}

// Loading state
class CartLoading extends CartState {}

// Loaded state - list of carts
class CartsLoaded extends CartState {
  final List<Cart> carts;

  const CartsLoaded(this.carts);

  @override
  List<Object?> get props => [carts];
}

// Single cart loaded with items
class CartWithItemsLoaded extends CartState {
  final Cart cart;

  const CartWithItemsLoaded(this.cart);

  @override
  List<Object?> get props => [cart];
}

// Cart operation success
class CartOperationSuccess extends CartState {
  final String message;

  const CartOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// Cart error state
class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cart empty state
class CartEmpty extends CartState {}
