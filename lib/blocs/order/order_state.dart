part of 'order_bloc.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

// Initial state
class OrderInitial extends OrderState {}

// Loading state
class OrderLoading extends OrderState {}

// Loaded state - list of orders
class OrdersLoaded extends OrderState {
  final List<Order> orders;

  const OrdersLoaded(this.orders);

  @override
  List<Object?> get props => [orders];
}

// Single order loaded with items
class OrderWithItemsLoaded extends OrderState {
  final Order order;

  const OrderWithItemsLoaded(this.order);

  @override
  List<Object?> get props => [order];
}

// Order operation success
class OrderOperationSuccess extends OrderState {
  final String message;

  const OrderOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// Order error state
class OrderError extends OrderState {
  final String message;

  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}

// Order empty state
class OrderEmpty extends OrderState {}
