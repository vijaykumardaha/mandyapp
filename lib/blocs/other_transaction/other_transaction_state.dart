part of 'other_transaction_bloc.dart';

abstract class OtherTransactionState extends Equatable {
  const OtherTransactionState();

  @override
  List<Object?> get props => [];
}

// Initial state
class OtherTransactionInitial extends OtherTransactionState {}

// Loading state
class OtherTransactionLoading extends OtherTransactionState {}

// Loaded state - list of transactions
class OtherTransactionLoaded extends OtherTransactionState {
  final List<OtherTransaction> transactions;

  const OtherTransactionLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

// Transaction operation success
class OtherTransactionOperationSuccess extends OtherTransactionState {
  final String message;

  const OtherTransactionOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// Transaction error state
class OtherTransactionError extends OtherTransactionState {
  final String message;

  const OtherTransactionError(this.message);

  @override
  List<Object?> get props => [message];
}
