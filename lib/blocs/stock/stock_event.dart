part of 'stock_bloc.dart';

abstract class StockEvent extends Equatable {
  const StockEvent();

  @override
  List<Object?> get props => [];
}

class LoadStocks extends StockEvent {
  final int? customerId;

  const LoadStocks({this.customerId});

  @override
  List<Object?> get props => [customerId];
}

class UpsertStock extends StockEvent {
  final ProductStock stock;

  const UpsertStock(this.stock);

  @override
  List<Object?> get props => [stock];
}

class DeleteStock extends StockEvent {
  final int stockId;

  const DeleteStock(this.stockId);

  @override
  List<Object?> get props => [stockId];
}
