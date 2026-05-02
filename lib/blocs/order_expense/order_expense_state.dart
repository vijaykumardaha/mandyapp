part of 'order_expense_bloc.dart';

sealed class OrderExpenseState extends Equatable {
  const OrderExpenseState();

  @override
  List<Object?> get props => [];
}

// Initial state
class OrderExpenseInitial extends OrderExpenseState {}

// Loading state
class OrderExpenseLoading extends OrderExpenseState {}

// Loaded state - list of order expenses
class OrderExpensesLoaded extends OrderExpenseState {
  final List<OrderExpense> orderExpenses;

  const OrderExpensesLoaded(this.orderExpenses);

  @override
  List<Object?> get props => [orderExpenses];
}

// Single order expense loaded
class OrderExpenseLoaded extends OrderExpenseState {
  final OrderExpense orderExpense;

  const OrderExpenseLoaded(this.orderExpense);

  @override
  List<Object?> get props => [orderExpense];
}

// Order expense operation success
class OrderExpenseOperationSuccess extends OrderExpenseState {
  final String message;

  const OrderExpenseOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// Order expense error state
class OrderExpenseError extends OrderExpenseState {
  final String message;

  const OrderExpenseError(this.message);

  @override
  List<Object?> get props => [message];
}

// Order expense empty state
class OrderExpenseEmpty extends OrderExpenseState {}
