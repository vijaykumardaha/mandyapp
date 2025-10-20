part of 'cart_payment_bloc.dart';

abstract class CartPaymentEvent extends Equatable {
  const CartPaymentEvent();

  @override
  List<Object?> get props => [];
}

// Load all cart payment summaries
class LoadCartPayments extends CartPaymentEvent {
  const LoadCartPayments();

  @override
  List<Object?> get props => [];
}

// Load cart payment summary for a specific cart
class LoadCartPaymentsByCart extends CartPaymentEvent {
  final int cartId;

  const LoadCartPaymentsByCart(this.cartId);

  @override
  List<Object?> get props => [cartId];
}

// Update cart payment summary
class UpdateCartPayment extends CartPaymentEvent {
  final CartPayment payment;

  const UpdateCartPayment(this.payment);

  @override
  List<Object?> get props => [payment];
}

// Refresh cart payment summaries
class RefreshCartPayments extends CartPaymentEvent {
  const RefreshCartPayments();

  @override
  List<Object?> get props => [];
}
