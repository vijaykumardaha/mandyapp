part of 'item_sale_bloc.dart';

abstract class ItemSaleState extends Equatable {
  const ItemSaleState();

  @override
  List<Object?> get props => [];
}

class ItemSaleInitial extends ItemSaleState {
  const ItemSaleInitial();
}

class ItemSaleLoading extends ItemSaleState {
  const ItemSaleLoading();
}

class ItemSalesLoaded extends ItemSaleState {
  final List<ItemSale> sales;

  const ItemSalesLoaded(this.sales);

  @override
  List<Object?> get props => [sales];
}

class ItemSaleOperationSuccess extends ItemSaleState {
  final List<ItemSale> sales;
  final String message;

  const ItemSaleOperationSuccess({required this.sales, required this.message});

  @override
  List<Object?> get props => [sales, message];
}

class ItemSaleError extends ItemSaleState {
  final String message;

  const ItemSaleError(this.message);

  @override
  List<Object?> get props => [message];
}
