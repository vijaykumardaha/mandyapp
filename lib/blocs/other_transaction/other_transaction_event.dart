part of 'other_transaction_bloc.dart';

abstract class OtherTransactionEvent extends Equatable {
  const OtherTransactionEvent();

  @override
  List<Object?> get props => [];
}

// Load all transactions
class LoadOtherTransactions extends OtherTransactionEvent {}

// Create new transaction
class CreateOtherTransaction extends OtherTransactionEvent {
  final OtherTransaction transaction;

  const CreateOtherTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

// Update transaction
class UpdateOtherTransaction extends OtherTransactionEvent {
  final OtherTransaction transaction;

  const UpdateOtherTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

// Delete transaction
class DeleteOtherTransaction extends OtherTransactionEvent {
  final int transactionId;

  const DeleteOtherTransaction(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}
