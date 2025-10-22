import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mandyapp/dao/item_sale_dao.dart';
import 'package:mandyapp/dao/product_stock_dao.dart';
import 'package:mandyapp/models/item_sale_model.dart';

part 'item_sale_event.dart';
part 'item_sale_state.dart';

class ItemSaleBloc extends Bloc<ItemSaleEvent, ItemSaleState> {
  final ItemSaleDAO _itemSaleDAO;
  final ProductStockDAO _productStockDAO;

  ItemSaleBloc({ItemSaleDAO? dao})
      : _itemSaleDAO = dao ?? ItemSaleDAO(),
        _productStockDAO = ProductStockDAO(),
        super(const ItemSaleInitial()) {
    on<LoadItemSales>(_onLoadItemSales);
    on<AddItemSaleEvent>(_onAddItemSale);
    on<UpdateItemSaleEvent>(_onUpdateItemSale);
    on<DeleteItemSaleEvent>(_onDeleteItemSale);
  }

  Future<void> _onLoadItemSales(LoadItemSales event, Emitter<ItemSaleState> emit) async {
    emit(const ItemSaleLoading());
    try {
      final sales = await _itemSaleDAO.getItemSales(
        sellerId: event.sellerId,
        productId: event.productId,
        variantId: event.variantId,
        excludeCartLinked: event.excludeCartLinked,
      );
      emit(ItemSalesLoaded(sales));
    } catch (error) {
      emit(ItemSaleError('Failed to load item sales: ${error.toString()}'));
    }
  }

  Future<void> _onAddItemSale(AddItemSaleEvent event, Emitter<ItemSaleState> emit) async {
    emit(const ItemSaleLoading());
    try {
      await _itemSaleDAO.insertItemSale(event.sale);
      final sales = await _itemSaleDAO.getItemSales(
        sellerId: event.sale.sellerId,
        excludeCartLinked: true,
      );
      emit(ItemSaleOperationSuccess(sales: sales, message: 'Sale added successfully'));
    } catch (error) {
      emit(ItemSaleError('Failed to add sale: ${error.toString()}'));
    }
  }

  Future<void> _onUpdateItemSale(UpdateItemSaleEvent event, Emitter<ItemSaleState> emit) async {
    emit(const ItemSaleLoading());
    try {
      await _itemSaleDAO.updateItemSale(event.sale);
      final sales = await _itemSaleDAO.getItemSales(sellerId: event.sale.sellerId);
      emit(ItemSaleOperationSuccess(sales: sales, message: 'Sale updated successfully'));
    } catch (error) {
      emit(ItemSaleError('Failed to update sale: ${error.toString()}'));
    }
  }

  Future<void> _onDeleteItemSale(DeleteItemSaleEvent event, Emitter<ItemSaleState> emit) async {
    emit(const ItemSaleLoading());
    try {
      final existingSale = await _itemSaleDAO.getItemSaleById(event.saleId);
      await _itemSaleDAO.deleteItemSale(event.saleId);
      if (existingSale?.stockId != null) {
        final stock = await _productStockDAO.getStockById(existingSale!.stockId!);
        if (stock != null) {
          final updatedStock = stock.copyWith(
            currentStock: stock.currentStock + existingSale.quantity,
            lastUpdated: DateTime.now().toIso8601String(),
          );
          await _productStockDAO.upsertStock(updatedStock);
        }
      }
      final sales = await _itemSaleDAO.getItemSales();
      emit(ItemSaleOperationSuccess(sales: sales, message: 'Sale removed successfully'));
    } catch (error) {
      emit(ItemSaleError('Failed to delete sale: ${error.toString()}'));
    }
  }
}
