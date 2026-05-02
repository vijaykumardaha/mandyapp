import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mandyapp/dao/order_expense_dao.dart';
import 'package:mandyapp/models/order_expense_model.dart';

part 'order_expense_event.dart';
part 'order_expense_state.dart';

class OrderExpenseBloc extends Bloc<OrderExpenseEvent, OrderExpenseState> {
  final OrderExpenseDao _orderExpenseDao = OrderExpenseDao();

  OrderExpenseBloc() : super(OrderExpenseInitial()) {
    on<CreateOrderExpense>(_onCreateOrderExpense);
    on<UpdateOrderExpense>(_onUpdateOrderExpense);
    on<DeleteOrderExpense>(_onDeleteOrderExpense);
    on<DeleteOrderExpensesByOrderId>(_onDeleteOrderExpensesByOrderId);
    on<LoadOrderExpenses>(_onLoadOrderExpenses);
    on<LoadOrderExpensesByOrderId>(_onLoadOrderExpensesByOrderId);
    on<LoadOrderExpensesByOrderIdOrNull>(_onLoadOrderExpensesByOrderIdOrNull);
    on<GetOrderExpenseById>(_onGetOrderExpenseById);
  }

  Future<void> _onCreateOrderExpense(
    CreateOrderExpense event,
    Emitter<OrderExpenseState> emit,
  ) async {
    try {
      emit(OrderExpenseLoading());
      await _orderExpenseDao.insert(event.orderExpense);
      final orderExpenses = await _orderExpenseDao.getByOrderId(event.orderExpense.orderId!);
      emit(OrderExpensesLoaded(orderExpenses));
      emit(OrderExpenseOperationSuccess('Order expense added successfully'));
    } catch (e) {
      emit(OrderExpenseError('Failed to add order expense: $e'));
    }
  }

  Future<void> _onUpdateOrderExpense(
    UpdateOrderExpense event,
    Emitter<OrderExpenseState> emit,
  ) async {
    try {
      emit(OrderExpenseLoading());
      await _orderExpenseDao.update(event.orderExpense);
      final orderExpenses = await _orderExpenseDao.getByOrderId(event.orderExpense.orderId!);
      emit(OrderExpensesLoaded(orderExpenses));
      emit(OrderExpenseOperationSuccess('Order expense updated successfully'));
    } catch (e) {
      emit(OrderExpenseError('Failed to update order expense: $e'));
    }
  }

  Future<void> _onDeleteOrderExpense(
    DeleteOrderExpense event,
    Emitter<OrderExpenseState> emit,
  ) async {
    try {
      emit(OrderExpenseLoading());
      await _orderExpenseDao.delete(event.expenseId);
      // We need to get the order ID to reload the expenses, but we don't have it here
      // For now, emit success and let the UI handle the reload
      emit(OrderExpenseOperationSuccess('Order expense deleted successfully'));
    } catch (e) {
      emit(OrderExpenseError('Failed to delete order expense: $e'));
    }
  }

  Future<void> _onDeleteOrderExpensesByOrderId(
    DeleteOrderExpensesByOrderId event,
    Emitter<OrderExpenseState> emit,
  ) async {
    try {
      emit(OrderExpenseLoading());
      await _orderExpenseDao.deleteByOrderId(event.orderId);
      emit(OrderExpenseOperationSuccess('Order expenses deleted successfully'));
    } catch (e) {
      emit(OrderExpenseError('Failed to delete order expenses: $e'));
    }
  }

  Future<void> _onLoadOrderExpenses(
    LoadOrderExpenses event,
    Emitter<OrderExpenseState> emit,
  ) async {
    try {
      emit(OrderExpenseLoading());
      final orderExpenses = await _orderExpenseDao.getAll();
      emit(OrderExpensesLoaded(orderExpenses));
    } catch (e) {
      emit(OrderExpenseError('Failed to load order expenses: $e'));
    }
  }

  Future<void> _onLoadOrderExpensesByOrderId(
    LoadOrderExpensesByOrderId event,
    Emitter<OrderExpenseState> emit,
  ) async {
    try {
      emit(OrderExpenseLoading());
      final orderExpenses = await _orderExpenseDao.getByOrderId(event.orderId);
      emit(OrderExpensesLoaded(orderExpenses));
    } catch (e) {
      emit(OrderExpenseError('Failed to load order expenses: $e'));
    }
  }

  Future<void> _onLoadOrderExpensesByOrderIdOrNull(
    LoadOrderExpensesByOrderIdOrNull event,
    Emitter<OrderExpenseState> emit,
  ) async {
    try {
      emit(OrderExpenseLoading());
      final orderExpenses = await _orderExpenseDao.getByOrderIdOrNull(event.orderId);
      emit(OrderExpensesLoaded(orderExpenses));
    } catch (e) {
      emit(OrderExpenseError('Failed to load order expenses: $e'));
    }
  }

  Future<void> _onGetOrderExpenseById(
    GetOrderExpenseById event,
    Emitter<OrderExpenseState> emit,
  ) async {
    try {
      emit(OrderExpenseLoading());
      final orderExpense = await _orderExpenseDao.getById(event.expenseId);
      if (orderExpense != null) {
        emit(OrderExpenseLoaded(orderExpense));
      } else {
        emit(OrderExpenseError('Order expense not found'));
      }
    } catch (e) {
      emit(OrderExpenseError('Failed to get order expense: $e'));
    }
  }
}
