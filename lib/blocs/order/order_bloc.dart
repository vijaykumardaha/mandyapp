import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:krishimandi/dao/order_dao.dart';
import 'package:krishimandi/models/order_item_model.dart';
import 'package:krishimandi/models/order_model.dart';

part 'order_event.dart';
part 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderDAO orderDAO = OrderDAO();

  OrderBloc() : super(OrderInitial()) {
    // Load all orders (now loads open order for default user)
    on<LoadOrders>((event, emit) async {
      try {
        emit(OrderLoading());
        final orders = await orderDAO.getAllOrders();
        if (orders.isEmpty) {
          emit(OrderEmpty());
        } else {
          emit(OrdersLoaded(orders));
        }
      } catch (error) {
        emit(const OrderError('Failed to load orders. Please try again.'));
      }
    });

    // Load orders by customer ID
    on<LoadOrdersByCustomer>((event, emit) async {
      try {
        emit(OrderLoading());
        final orders = await orderDAO.getOrdersByCustomer(event.customerId);
        if (orders.isEmpty) {
          emit(OrderEmpty());
        } else {
          emit(OrdersLoaded(orders));
        }
      } catch (error) {
        emit(const OrderError('Failed to load orders. Please try again.'));
      }
    });

    // Load order with items
    on<LoadOrderWithItems>((event, emit) async {
      try {
        emit(OrderLoading());
        final order = await orderDAO.getOrderWithItems(event.orderId);
        if (order != null) {
          emit(OrderWithItemsLoaded(order));
        } else {
          emit(const OrderError('Order not found'));
        }
      } catch (error) {
        emit(const OrderError('Failed to load order. Please try again.'));
      }
    });

    // Load order by ID (for checkout screen)
    on<LoadOrderById>((event, emit) async {
      try {
        // emit(OrderLoading());
        final order = await orderDAO.getOrderWithItems(event.orderId);
        if (order != null) {
          emit(OrderWithItemsLoaded(order));
          add(LoadOrderWithItems(event.orderId));
        } else {
          emit(const OrderError('Order not found'));
        }
      } catch (error) {
        emit(const OrderError('Failed to load order. Please try again.'));
      }
    });

    // Create new order
    on<CreateOrder>((event, emit) async {
      try {
        emit(OrderLoading());
        final orderId = await orderDAO.insertOrder(event.order);
        final order = await orderDAO.getOrderWithItems(orderId);
        if (order != null) {
          emit(OrderWithItemsLoaded(order));
          add(LoadOrders());
          emit(const OrderOperationSuccess('Order created successfully'));
        }
      } catch (error) {
        emit(const OrderError('Failed to create order. Please try again.'));
      }
    });

    // Update order
    on<UpdateOrder>((event, emit) async {
      try {
        emit(OrderLoading());
        await orderDAO.updateOrder(event.order);
        final order = await orderDAO.getOrderWithItems(event.order.id!);
        if (order != null) {
          emit(OrderWithItemsLoaded(order));
          emit(const OrderOperationSuccess('Order updated successfully'));
        }
      } catch (error) {
        emit(const OrderError('Failed to update order. Please try again.'));
      }
    });

    // Delete order
    on<DeleteOrder>((event, emit) async {
      try {
        await orderDAO.deleteOrder(event.orderId);
        // Reload orders to get updated list
        add(LoadOrders());
      } catch (error) {
        emit(const OrderError('Failed to delete order. Please try again.'));
      }
    });

    // Add item to order
    on<AddItemToOrder>((event, emit) async {
      try {
        await orderDAO.insertOrderItem(event.item);
        // Reload orders to get updated items
        add(LoadOrders());
      } catch (error) {
        emit(const OrderError('Failed to add item. Please try again.'));
      }
    });

    // Update order item
    on<UpdateOrderItem>((event, emit) async {
      try {
        await orderDAO.updateOrderItem(event.item);
        // Reload orders to get updated items
        add(LoadOrders());

        // Determine order ID based on order type
        final orderId = event.item.sellerOrderId ?? event.item.buyerOrderId;
        if (orderId != null) {
          // Get order to determine its type
          final order = await orderDAO.getOrderById(orderId);
          if (order != null) {
            add(LoadOrderById(orderId));
          }
        }
      } catch (error) {
        emit(const OrderError('Failed to update item. Please try again.'));
      }
    });

    // Remove item from order
    on<RemoveItemFromOrder>((event, emit) async {
      try {
        await orderDAO.deleteOrderItem(event.item.id!);
        // Reload orders to get updated items
        add(LoadOrders());

        // Determine order ID based on order type
        final orderId = event.item.sellerOrderId ?? event.item.buyerOrderId;
        if (orderId != null) {
          // Get order to determine its type
          final order = await orderDAO.getOrderById(orderId);
          if (order != null) {
            add(LoadOrderById(orderId));
          }
        }
      } catch (error) {
        emit(const OrderError('Failed to remove item. Please try again.'));
      }
    });

    // Clear order
    on<ClearOrder>((event, emit) async {
      try {
        emit(OrderLoading());
        await orderDAO.clearOrder(event.orderId);
        final order = await orderDAO.getOrderWithItems(event.orderId);
        if (order != null) {
          emit(OrderWithItemsLoaded(order));
          emit(const OrderOperationSuccess('Order cleared'));
        }
      } catch (error) {
        emit(const OrderError('Failed to clear order. Please try again.'));
      }
    });
  }
}
