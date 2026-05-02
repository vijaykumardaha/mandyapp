part of 'order_payment_bloc.dart';

abstract class OrderPaymentEvent extends Equatable {
  const OrderPaymentEvent();

  @override
  List<Object?> get props => [];
}

class LoadOrderPayments extends OrderPaymentEvent {
  const LoadOrderPayments();

  @override
  List<Object?> get props => [];
}

class LoadOrderPaymentByOrderId extends OrderPaymentEvent {
  final int orderId;

  const LoadOrderPaymentByOrderId(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class CreateOrderPayment extends OrderPaymentEvent {
  final OrderPayment orderPayment;

  const CreateOrderPayment(this.orderPayment);

  @override
  List<Object?> get props => [orderPayment];
}

class UpdateOrderPayment extends OrderPaymentEvent {
  final OrderPayment orderPayment;

  const UpdateOrderPayment(this.orderPayment);

  @override
  List<Object?> get props => [orderPayment];
}

class DeleteOrderPayment extends OrderPaymentEvent {
  final int paymentId;

  const DeleteOrderPayment(this.paymentId);

  @override
  List<Object?> get props => [paymentId];
}

class GetOrderPaymentById extends OrderPaymentEvent {
  final int paymentId;

  const GetOrderPaymentById(this.paymentId);

  @override
  List<Object?> get props => [paymentId];
}

class DeleteOrderPaymentsByOrderId extends OrderPaymentEvent {
  final int orderId;

  const DeleteOrderPaymentsByOrderId(this.orderId);

  @override
  List<Object?> get props => [orderId];
}
