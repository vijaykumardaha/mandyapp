part of 'order_expense_bloc.dart';

sealed class OrderExpenseEvent extends Equatable {
  const OrderExpenseEvent();

  @override
  List<Object?> get props => [];
}

// Load all order expenses
class LoadOrderExpenses extends OrderExpenseEvent {}

// Load order expenses by order ID
class LoadOrderExpensesByOrderId extends OrderExpenseEvent {
  final int orderId;

  const LoadOrderExpensesByOrderId(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

// Load order expenses by order ID or null
class LoadOrderExpensesByOrderIdOrNull extends OrderExpenseEvent {
  final int orderId;

  const LoadOrderExpensesByOrderIdOrNull(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

// Create new order expense
class CreateOrderExpense extends OrderExpenseEvent {
  final OrderExpense orderExpense;

  const CreateOrderExpense(this.orderExpense);

  @override
  List<Object?> get props => [orderExpense];
}

// Update order expense
class UpdateOrderExpense extends OrderExpenseEvent {
  final OrderExpense orderExpense;

  const UpdateOrderExpense(this.orderExpense);

  @override
  List<Object?> get props => [orderExpense];
}

// Delete order expense
class DeleteOrderExpense extends OrderExpenseEvent {
  final int expenseId;

  const DeleteOrderExpense(this.expenseId);

  @override
  List<Object?> get props => [expenseId];
}

// Get order expense by ID
class GetOrderExpenseById extends OrderExpenseEvent {
  final int expenseId;

  const GetOrderExpenseById(this.expenseId);

  @override
  List<Object?> get props => [expenseId];
}

// Delete order expenses by order ID
class DeleteOrderExpensesByOrderId extends OrderExpenseEvent {
  final int orderId;

  const DeleteOrderExpensesByOrderId(this.orderId);

  @override
  List<Object?> get props => [orderId];
}
