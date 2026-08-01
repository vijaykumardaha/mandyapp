import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:krishimandi/dao/order_payment_dao.dart';
import 'package:krishimandi/models/order_payment_model.dart';

part 'order_payment_event.dart';
part 'order_payment_state.dart';

class OrderPaymentBloc extends Bloc<OrderPaymentEvent, OrderPaymentState> {
  final OrderPaymentDAO _orderPaymentDAO = OrderPaymentDAO();

  OrderPaymentBloc() : super(OrderPaymentInitial()) {
    on<LoadOrderPayments>(_onLoadOrderPayments);
    on<LoadOrderPaymentByOrderId>(_onLoadOrderPaymentByOrderId);
    on<CreateOrderPayment>(_onCreateOrderPayment);
    on<UpdateOrderPayment>(_onUpdateOrderPayment);
    on<DeleteOrderPayment>(_onDeleteOrderPayment);
    on<GetOrderPaymentById>(_onGetOrderPaymentById);
    on<DeleteOrderPaymentsByOrderId>(_onDeleteOrderPaymentsByOrderId);
  }

  Future<void> _onLoadOrderPayments(
    LoadOrderPayments event,
    Emitter<OrderPaymentState> emit,
  ) async {
    try {
      emit(OrderPaymentLoading());
      final orderPayments = await _orderPaymentDAO.getAllOrderPayments();
      emit(OrderPaymentsLoaded(orderPayments));
    } catch (e) {
      emit(const OrderPaymentError(
          'Failed to load order payments. Please try again.'));
    }
  }

  Future<void> _onLoadOrderPaymentByOrderId(
    LoadOrderPaymentByOrderId event,
    Emitter<OrderPaymentState> emit,
  ) async {
    try {
      emit(OrderPaymentLoading());
      final orderPayments =
          await _orderPaymentDAO.getOrderPaymentsByOrderId(event.orderId);
      if (orderPayments.isNotEmpty) {
        emit(OrderPaymentsLoaded(orderPayments));
      } else {
        emit(OrderPaymentEmpty());
      }
    } catch (e) {
      emit(const OrderPaymentError(
          'Failed to load order payments. Please try again.'));
    }
  }

  Future<void> _onCreateOrderPayment(
    CreateOrderPayment event,
    Emitter<OrderPaymentState> emit,
  ) async {
    try {
      emit(OrderPaymentLoading());
      await _orderPaymentDAO.insertOrderPayment(event.orderPayment);
      final orderPayments = await _orderPaymentDAO.getAllOrderPayments();
      emit(OrderPaymentsLoaded(orderPayments));
      emit(const OrderPaymentOperationSuccess(
          'Order payment added successfully'));
    } catch (e) {
      emit(const OrderPaymentError(
          'Failed to add order payment. Please try again.'));
    }
  }

  Future<void> _onUpdateOrderPayment(
    UpdateOrderPayment event,
    Emitter<OrderPaymentState> emit,
  ) async {
    try {
      emit(OrderPaymentLoading());
      await _orderPaymentDAO.updateOrderPayment(event.orderPayment);
      final orderPayments = await _orderPaymentDAO.getAllOrderPayments();
      emit(OrderPaymentsLoaded(orderPayments));
      emit(const OrderPaymentOperationSuccess(
          'Order payment updated successfully'));
    } catch (e) {
      emit(const OrderPaymentError(
          'Failed to update order payment. Please try again.'));
    }
  }

  Future<void> _onDeleteOrderPayment(
    DeleteOrderPayment event,
    Emitter<OrderPaymentState> emit,
  ) async {
    try {
      emit(OrderPaymentLoading());
      await _orderPaymentDAO.deleteOrderPayment(event.paymentId);
      final orderPayments = await _orderPaymentDAO.getAllOrderPayments();
      emit(OrderPaymentsLoaded(orderPayments));
      emit(const OrderPaymentOperationSuccess(
          'Order payment deleted successfully'));
    } catch (e) {
      emit(const OrderPaymentError(
          'Failed to delete order payment. Please try again.'));
    }
  }

  Future<void> _onGetOrderPaymentById(
    GetOrderPaymentById event,
    Emitter<OrderPaymentState> emit,
  ) async {
    try {
      emit(OrderPaymentLoading());
      final orderPayment =
          await _orderPaymentDAO.getOrderPaymentById(event.paymentId);
      if (orderPayment != null) {
        emit(OrderPaymentLoaded(orderPayment));
      } else {
        emit(const OrderPaymentError('Order payment not found'));
      }
    } catch (e) {
      emit(const OrderPaymentError(
          'Failed to get order payment. Please try again.'));
    }
  }

  Future<void> _onDeleteOrderPaymentsByOrderId(
    DeleteOrderPaymentsByOrderId event,
    Emitter<OrderPaymentState> emit,
  ) async {
    try {
      emit(OrderPaymentLoading());
      await _orderPaymentDAO.deleteOrderPayments(event.orderId);
      final orderPayments = await _orderPaymentDAO.getAllOrderPayments();
      emit(OrderPaymentsLoaded(orderPayments));
      emit(const OrderPaymentOperationSuccess(
          'Order payments deleted successfully'));
    } catch (e) {
      emit(const OrderPaymentError(
          'Failed to delete order payments. Please try again.'));
    }
  }
}
