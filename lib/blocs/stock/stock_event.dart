part of 'stock_bloc.dart';

abstract class StockEvent extends Equatable {
  const StockEvent();

  @override
  List<Object?> get props => [];
}

// ── Stock Events ──────────────────────────

class LoadStocks extends StockEvent {}

class AddStock extends StockEvent {
  final Stock stock;

  const AddStock(this.stock);

  @override
  List<Object?> get props => [stock];
}

class UpdateStock extends StockEvent {
  final Stock stock;

  const UpdateStock(this.stock);

  @override
  List<Object?> get props => [stock];
}

class DeleteStock extends StockEvent {
  final int stockId;

  const DeleteStock(this.stockId);

  @override
  List<Object?> get props => [stockId];
}

class SearchStocks extends StockEvent {
  final String query;

  const SearchStocks(this.query);

  @override
  List<Object?> get props => [query];
}

// ── Stock Transaction Events ──────────────

class LoadStockTransactions extends StockEvent {}

class LoadTransactionsByStock extends StockEvent {
  final int stockId;

  const LoadTransactionsByStock(this.stockId);

  @override
  List<Object?> get props => [stockId];
}

class LoadTransactionsByBill extends StockEvent {
  final int billId;

  const LoadTransactionsByBill(this.billId);

  @override
  List<Object?> get props => [billId];
}

class AddStockTransaction extends StockEvent {
  final StockTransaction transaction;

  const AddStockTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class DeleteStockTransaction extends StockEvent {
  final int transactionId;

  const DeleteStockTransaction(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}
