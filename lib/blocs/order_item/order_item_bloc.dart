import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mandiapp/dao/order_item_dao.dart';
import 'package:mandiapp/models/order_item_model.dart';
import 'package:mandiapp/services/sync_service.dart';

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
    on<ClearOrderItems>(_onClearOrderItems);
    on<LoadAllUnlinkedOrderItems>(_onLoadAllUnlinkedOrderItems);

    SyncService.instance.tableUpdates.listen((table) {
      if (table == 'order_items' && !isClosed) {
        add(const LoadAllUnlinkedOrderItems());
      }
    });
  }

  Future<void> _onLoadOrderItems(LoadOrderItems event, Emitter<OrderItemState> emit) async {
    emit(const OrderItemLoading());
    try {
      List<OrderItem> orderItems = [];

      if (event.sellerId != null) {
        final sellerItems = await _orderItemDAO.getOrderItems(
          sellerId: event.sellerId,
          productId: event.productId,
          variantId: event.variantId,
          excludeSellerOrderLinked: event.excludeOrderLinked,
        );
        orderItems.addAll(sellerItems);
      }

      if (event.buyerId != null) {
        final buyerItems = await _orderItemDAO.getOrderItems(
          buyerId: event.buyerId,
          productId: event.productId,
          variantId: event.variantId,
          excludeBuyerOrderLinked: event.excludeOrderLinked,
        );
        orderItems.addAll(buyerItems);
      }

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
        excludeSellerOrderLinked: true,
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
    try {
      await _orderItemDAO.deleteOrderItem(event.orderItemId);
      List<OrderItem> orderItems = [];
      if (event.sellerId != null) {
        final sellerItems = await _orderItemDAO.getOrderItems(
          sellerId: event.sellerId,
          excludeSellerOrderLinked: true,
        );
        orderItems.addAll(sellerItems);
      }
      if (event.buyerId != null) {
        final buyerItems = await _orderItemDAO.getOrderItems(
          buyerId: event.buyerId,
          excludeBuyerOrderLinked: true,
        );
        orderItems.addAll(buyerItems);
      }
      emit(OrderItemsLoaded(orderItems));
    } catch (error) {
      emit(OrderItemError('Failed to delete order item: ${error.toString()}'));
    }
  }

  void _onClearOrderItems(ClearOrderItems event, Emitter<OrderItemState> emit) {
    emit(const OrderItemsLoaded([]));
  }

  Future<void> _onLoadAllUnlinkedOrderItems(LoadAllUnlinkedOrderItems event, Emitter<OrderItemState> emit) async {
    emit(const OrderItemLoading());
    try {
      final orderItems = await _orderItemDAO.getOrderItems(
        excludeBuyerOrderLinked: true,
        excludeSellerOrderLinked: true,
      );
      emit(OrderItemsLoaded(orderItems));
    } catch (error) {
      emit(OrderItemError('Failed to load order items: ${error.toString()}'));
    }
  }
}
