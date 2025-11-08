part of 'item_sale_bloc.dart';

abstract class ItemSaleEvent extends Equatable {
  const ItemSaleEvent();

  @override
  List<Object?> get props => [];
}

class LoadItemSales extends ItemSaleEvent {
  final int? sellerId;
  final int? productId;
  final int? variantId;
  final bool excludeCartLinked;

  const LoadItemSales({this.sellerId, this.productId, this.variantId, this.excludeCartLinked = true});

  @override
  List<Object?> get props => [sellerId, productId, variantId, excludeCartLinked];
}

class AddItemSaleEvent extends ItemSaleEvent {
  final ItemSale sale;

  const AddItemSaleEvent(this.sale);

  @override
  List<Object?> get props => [sale];
}

class UpdateItemSaleEvent extends ItemSaleEvent {
  final ItemSale sale;

  const UpdateItemSaleEvent(this.sale);

  @override
  List<Object?> get props => [sale];
}

class DeleteItemSaleEvent extends ItemSaleEvent {
  final int saleId;

  const DeleteItemSaleEvent(this.saleId);

  @override
  List<Object?> get props => [saleId];
}

class LoadBillableSales extends ItemSaleEvent {
  final int sellerId;
  final bool excludeCartLinked;

  const LoadBillableSales({
    required this.sellerId,
    this.excludeCartLinked = true,
  });

  @override
  List<Object?> get props => [sellerId, excludeCartLinked];
}
