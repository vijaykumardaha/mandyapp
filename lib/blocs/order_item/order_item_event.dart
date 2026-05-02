part of 'order_item_bloc.dart';

abstract class OrderItemEvent extends Equatable {
  const OrderItemEvent();

  @override
  List<Object?> get props => [];
}

class LoadOrderItems extends OrderItemEvent {
  final int? sellerId;
  final int? productId;
  final int? variantId;
  final bool excludeOrderLinked;

  const LoadOrderItems({this.sellerId, this.productId, this.variantId, this.excludeOrderLinked = true});

  @override
  List<Object?> get props => [sellerId, productId, variantId, excludeOrderLinked];
}

class AddOrderItemEvent extends OrderItemEvent {
  final OrderItem orderItem;

  const AddOrderItemEvent(this.orderItem);

  @override
  List<Object?> get props => [orderItem];
}

class UpdateOrderItemEvent extends OrderItemEvent {
  final OrderItem orderItem;

  const UpdateOrderItemEvent(this.orderItem);

  @override
  List<Object?> get props => [orderItem];
}

class DeleteOrderItemEvent extends OrderItemEvent {
  final int orderItemId;

  const DeleteOrderItemEvent(this.orderItemId);

  @override
  List<Object?> get props => [orderItemId];
}

class LoadBillableOrderItems extends OrderItemEvent {
  final int sellerId;
  final bool excludeOrderLinked;

  const LoadBillableOrderItems({
    required this.sellerId,
    this.excludeOrderLinked = true,
  });

  @override
  List<Object?> get props => [sellerId, excludeOrderLinked];
}
