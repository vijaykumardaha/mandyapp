import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mandyapp/dao/order_item_dao.dart';
import 'package:mandyapp/models/order_item_model.dart';

part 'order_item_event.dart';
part 'order_item_state.dart';

class OrderItemBloc extends Bloc<OrderItemEvent, OrderItemState> {
  final OrderItemDAO _orderItemDAO;

  OrderItemBloc({OrderItemDAO? dao})
      : _orderItemDAO = dao ?? OrderItemDAO(),
        super(const OrderItemInitial()) {
    on<LoadOrderItems>(_onLoadOrderItems);
    on<LoadBillableOrderItems>(_onLoadBillableOrderItems);
    on<AddOrderItemEvent>(_onAddOrderItem);
    on<UpdateOrderItemEvent>(_onUpdateOrderItem);
    on<DeleteOrderItemEvent>(_onDeleteOrderItem);
  }

  Future<void> _onLoadOrderItems(LoadOrderItems event, Emitter<OrderItemState> emit) async {
    emit(const OrderItemLoading());
    try {
      final orderItems = await _orderItemDAO.getOrderItems(
        sellerId: event.sellerId,
        productId: event.productId,
        variantId: event.variantId,
        excludeOrderLinked: event.excludeOrderLinked,
      );
      emit(OrderItemsLoaded(orderItems));
    } catch (error) {
      emit(OrderItemError('Failed to load order items: ${error.toString()}'));
    }
  }

  Future<void> _onLoadBillableOrderItems(LoadBillableOrderItems event, Emitter<OrderItemState> emit) async {
    emit(const OrderItemLoading());
    try {
      // Load order items that are billable (not linked to any order)
      final orderItems = await _orderItemDAO.getSellerOrderItems(sellerId: event.sellerId);

      emit(OrderItemsLoaded(orderItems, message: 'Billable order items loaded'));
    } catch (error) {
      emit(OrderItemError('Failed to load billable order items: ${error.toString()}'));
    }
  }

  Future<void> _onAddOrderItem(AddOrderItemEvent event, Emitter<OrderItemState> emit) async {
    emit(const OrderItemLoading());
    try {
      await _orderItemDAO.insertOrderItem(event.orderItem);
      final orderItems = await _orderItemDAO.getOrderItems(
        sellerId: event.orderItem.sellerId,
        excludeOrderLinked: true,
      );
      emit(OrderItemsLoaded(orderItems, message: 'Order item added successfully'));
    } catch (error) {
      emit(OrderItemError('Failed to add order item: ${error.toString()}'));
    }
  }

  Future<void> _onUpdateOrderItem(UpdateOrderItemEvent event, Emitter<OrderItemState> emit) async {
    emit(const OrderItemLoading());
    try {
      await _orderItemDAO.updateOrderItem(event.orderItem);
      final orderItems = await _orderItemDAO.getOrderItems(sellerId: event.orderItem.sellerId);
      emit(OrderItemsLoaded(orderItems, message: 'Order item updated successfully'));
    } catch (error) {
      emit(OrderItemError('Failed to update order item: ${error.toString()}'));
    }
  }

  Future<void> _onDeleteOrderItem(DeleteOrderItemEvent event, Emitter<OrderItemState> emit) async {
    emit(const OrderItemLoading());
    try {
      await _orderItemDAO.deleteOrderItem(event.orderItemId);
    } catch (error) {
      emit(OrderItemError('Failed to delete order item: ${error.toString()}'));
    }
  }
}
