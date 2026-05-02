part of 'order_item_bloc.dart';

abstract class OrderItemState extends Equatable {
  const OrderItemState();

  @override
  List<Object?> get props => [];
}

class OrderItemInitial extends OrderItemState {
  const OrderItemInitial();
}

class OrderItemLoading extends OrderItemState {
  const OrderItemLoading();
}

class OrderItemsLoaded extends OrderItemState {
  final List<OrderItem> orderItems;
  final String? message;

  const OrderItemsLoaded(this.orderItems, {this.message});

  @override
  List<Object?> get props => [orderItems, message];
}

class OrderItemError extends OrderItemState {
  final String message;

  const OrderItemError(this.message);

  @override
  List<Object?> get props => [message];
}
