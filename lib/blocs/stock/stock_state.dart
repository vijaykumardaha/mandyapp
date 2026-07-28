part of 'stock_bloc.dart';

abstract class StockState extends Equatable {
  const StockState();

  @override
  List<Object?> get props => [];
}

// ── Stock States ──────────────────────────

class StockInitial extends StockState {}

class StockLoading extends StockState {}

class StockLoaded extends StockState {
  final List<Stock> stocks;

  const StockLoaded(this.stocks);

  @override
  List<Object?> get props => [stocks];
}

class StockOperationSuccess extends StockState {
  final String message;

  const StockOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class StockError extends StockState {
  final String message;

  const StockError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── Stock Transaction States ──────────────

class StockTransactionsLoaded extends StockState {
  final List<StockTransaction> transactions;

  const StockTransactionsLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}
