part of 'order_bloc.dart';


abstract class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object?> get props => [];
}

// Load all orders
class LoadOrders extends OrderEvent {}

// Load order with items
class LoadOrderWithItems extends OrderEvent {
  final int orderId;

  const LoadOrderWithItems(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

// Load order by ID (for checkout screen)
class LoadOrderById extends OrderEvent {
  final int orderId;

  const LoadOrderById(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

// Create new order
class CreateOrder extends OrderEvent {
  final Order order;

  const CreateOrder(this.order);

  @override
  List<Object?> get props => [order];
}

// Update order
class UpdateOrder extends OrderEvent {
  final Order order;

  const UpdateOrder(this.order);

  @override
  List<Object?> get props => [order];
}

// Delete order
class DeleteOrder extends OrderEvent {
  final int orderId;

  const DeleteOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

// Add item to order
class AddItemToOrder extends OrderEvent {
  final OrderItem item;

  const AddItemToOrder(this.item);

  @override
  List<Object?> get props => [item];
}

// Update order item
class UpdateOrderItem extends OrderEvent {
  final OrderItem item;

  const UpdateOrderItem(this.item);

  @override
  List<Object?> get props => [item];
}

// Remove item from order
class RemoveItemFromOrder extends OrderEvent {
  final OrderItem item;

  const RemoveItemFromOrder(this.item);

  @override
  List<Object?> get props => [item];
}

// Update order status
class UpdateOrderStatus extends OrderEvent {
  final int orderId;
  final String status;

  const UpdateOrderStatus(this.orderId, this.status);

  @override
  List<Object?> get props => [orderId, status];
}

// Clear order (remove all items)
class ClearOrder extends OrderEvent {
  final int orderId;

  const ClearOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}
