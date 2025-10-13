part of 'cart_bloc.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

// Load all carts
class LoadCarts extends CartEvent {}

// Load carts by user
class LoadCartsByUser extends CartEvent {
  final int userId;

  const LoadCartsByUser(this.userId);

  @override
  List<Object?> get props => [userId];
}

// Load cart with items
class LoadCartWithItems extends CartEvent {
  final int cartId;

  const LoadCartWithItems(this.cartId);

  @override
  List<Object?> get props => [cartId];
}

// Load cart by ID (for checkout screen)
class LoadCartById extends CartEvent {
  final int cartId;

  const LoadCartById(this.cartId);

  @override
  List<Object?> get props => [cartId];
}

// Load open cart for user
class LoadOpenCart extends CartEvent {
  final int userId;

  const LoadOpenCart(this.userId);

  @override
  List<Object?> get props => [userId];
}

// Create new cart
class CreateCart extends CartEvent {
  final Cart cart;

  const CreateCart(this.cart);

  @override
  List<Object?> get props => [cart];
}

// Update cart
class UpdateCart extends CartEvent {
  final Cart cart;

  const UpdateCart(this.cart);

  @override
  List<Object?> get props => [cart];
}

// Delete cart
class DeleteCart extends CartEvent {
  final int cartId;

  const DeleteCart(this.cartId);

  @override
  List<Object?> get props => [cartId];
}

// Add item to cart
class AddItemToCart extends CartEvent {
  final CartItem item;

  const AddItemToCart(this.item);

  @override
  List<Object?> get props => [item];
}

// Update cart item
class UpdateCartItem extends CartEvent {
  final CartItem item;

  const UpdateCartItem(this.item);

  @override
  List<Object?> get props => [item];
}

// Remove item from cart
class RemoveItemFromCart extends CartEvent {
  final CartItem item;

  const RemoveItemFromCart(this.item);

  @override
  List<Object?> get props => [item];
}

// Update cart status
class UpdateCartStatus extends CartEvent {
  final int cartId;
  final String status;

  const UpdateCartStatus(this.cartId, this.status);

  @override
  List<Object?> get props => [cartId, status];
}

// Clear cart (remove all items)
class ClearCart extends CartEvent {
  final int cartId;

  const ClearCart(this.cartId);

  @override
  List<Object?> get props => [cartId];
}
