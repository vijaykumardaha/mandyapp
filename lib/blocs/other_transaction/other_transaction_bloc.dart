import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:krishimandi/dao/other_transaction_dao.dart';
import 'package:krishimandi/models/other_transaction_model.dart';

part 'other_transaction_event.dart';
part 'other_transaction_state.dart';

class OtherTransactionBloc
    extends Bloc<OtherTransactionEvent, OtherTransactionState> {
  final OtherTransactionDAO _transactionDAO = OtherTransactionDAO();

  OtherTransactionBloc() : super(OtherTransactionInitial()) {
    on<LoadOtherTransactions>(_onLoadOtherTransactions);
    on<CreateOtherTransaction>(_onCreateOtherTransaction);
    on<UpdateOtherTransaction>(_onUpdateOtherTransaction);
    on<DeleteOtherTransaction>(_onDeleteOtherTransaction);
  }

  Future<void> _onLoadOtherTransactions(
    LoadOtherTransactions event,
    Emitter<OtherTransactionState> emit,
  ) async {
    try {
      emit(OtherTransactionLoading());
      final transactions = await _transactionDAO.getAllTransactions();
      emit(OtherTransactionLoaded(transactions));
    } catch (e) {
      emit(const OtherTransactionError(
          'Failed to load transactions. Please try again.'));
    }
  }

  Future<void> _onCreateOtherTransaction(
    CreateOtherTransaction event,
    Emitter<OtherTransactionState> emit,
  ) async {
    try {
      emit(OtherTransactionLoading());
      await _transactionDAO.insertTransaction(event.transaction);
      final transactions = await _transactionDAO.getAllTransactions();
      emit(OtherTransactionLoaded(transactions));
      emit(const OtherTransactionOperationSuccess(
          'Transaction added successfully'));
    } catch (e) {
      emit(const OtherTransactionError(
          'Failed to add transaction. Please try again.'));
    }
  }

  Future<void> _onUpdateOtherTransaction(
    UpdateOtherTransaction event,
    Emitter<OtherTransactionState> emit,
  ) async {
    try {
      emit(OtherTransactionLoading());
      await _transactionDAO.updateTransaction(event.transaction);
      final transactions = await _transactionDAO.getAllTransactions();
      emit(OtherTransactionLoaded(transactions));
      emit(const OtherTransactionOperationSuccess(
          'Transaction updated successfully'));
    } catch (e) {
      emit(const OtherTransactionError(
          'Failed to update transaction. Please try again.'));
    }
  }

  Future<void> _onDeleteOtherTransaction(
    DeleteOtherTransaction event,
    Emitter<OtherTransactionState> emit,
  ) async {
    try {
      emit(OtherTransactionLoading());
      await _transactionDAO.deleteTransaction(event.transactionId);
      final transactions = await _transactionDAO.getAllTransactions();
      emit(OtherTransactionLoaded(transactions));
      emit(const OtherTransactionOperationSuccess(
          'Transaction deleted successfully'));
    } catch (e) {
      emit(const OtherTransactionError(
          'Failed to delete transaction. Please try again.'));
    }
  }
}
