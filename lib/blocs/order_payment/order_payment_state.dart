part of 'order_payment_bloc.dart';

abstract class OrderPaymentState extends Equatable {
  const OrderPaymentState();

  @override
  List<Object?> get props => [];
}

class OrderPaymentInitial extends OrderPaymentState {}

class OrderPaymentLoading extends OrderPaymentState {}

class OrderPaymentsLoaded extends OrderPaymentState {
  final List<OrderPayment> orderPayments;

  OrderPaymentsLoaded(this.orderPayments);

  @override
  List<Object?> get props => [orderPayments];
}

class OrderPaymentLoaded extends OrderPaymentState {
  final OrderPayment orderPayment;

  OrderPaymentLoaded(this.orderPayment);

  @override
  List<Object?> get props => [orderPayment];
}

class OrderPaymentOperationSuccess extends OrderPaymentState {
  final String message;

  OrderPaymentOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class OrderPaymentError extends OrderPaymentState {
  final String message;

  OrderPaymentError(this.message);

  @override
  List<Object?> get props => [message];
}

class OrderPaymentEmpty extends OrderPaymentState {}
