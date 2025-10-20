part of 'cart_payment_bloc.dart';

abstract class CartPaymentState extends Equatable {
  const CartPaymentState();

  @override
  List<Object?> get props => [];
}

// Initial state
class CartPaymentInitial extends CartPaymentState {}

// Loading state
class CartPaymentLoading extends CartPaymentState {}

// Cart payments loaded successfully
class CartPaymentsLoaded extends CartPaymentState {
  final List<CartPayment> payments;

  const CartPaymentsLoaded(this.payments);

  @override
  List<Object?> get props => [payments];
}

// Payment summary loaded
class PaymentSummaryLoaded extends CartPaymentState {
  final double totalAmount;
  final int paymentCount;
  final Map<String, double> paymentMethodTotals;

  const PaymentSummaryLoaded({
    required this.totalAmount,
    required this.paymentCount,
    required this.paymentMethodTotals,
  });

  @override
  List<Object?> get props => [totalAmount, paymentCount, paymentMethodTotals];
}

// Single payment loaded
class CartPaymentLoaded extends CartPaymentState {
  final CartPayment payment;

  const CartPaymentLoaded(this.payment);

  @override
  List<Object?> get props => [payment];
}

// Payment operation success
class CartPaymentOperationSuccess extends CartPaymentState {
  final String message;

  const CartPaymentOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// Payment operation failure
class CartPaymentOperationFailure extends CartPaymentState {
  final String error;

  const CartPaymentOperationFailure(this.error);

  @override
  List<Object?> get props => [error];
}

// Payment processing state
class PaymentProcessing extends CartPaymentState {
  final String message;

  const PaymentProcessing(this.message);

  @override
  List<Object?> get props => [message];
}

// Payment completed state
class PaymentCompleted extends CartPaymentState {
  final CartPayment payment;
  final String message;

  const PaymentCompleted(this.payment, this.message);

  @override
  List<Object?> get props => [payment, message];
}
