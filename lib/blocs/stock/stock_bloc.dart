import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mandyapp/dao/product_stock_dao.dart';
import 'package:mandyapp/models/product_stock_model.dart';

part 'stock_event.dart';
part 'stock_state.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  final ProductStockDAO stockDAO = ProductStockDAO();

  StockBloc() : super(StockInitial()) {
    on<LoadStocks>(_onLoadStocks);
    on<UpsertStock>(_onUpsertStock);
    on<DeleteStock>(_onDeleteStock);
  }

  Future<void> _onLoadStocks(LoadStocks event, Emitter<StockState> emit) async {
    emit(StockLoading());
    try {
      final stocks = await stockDAO.getStocks(
        customerId: event.customerId,
      );
      emit(StockLoaded(stocks));
    } catch (error) {
      emit(StockError('Failed to load stocks: ${error.toString()}'));
    }
  }

  Future<void> _onUpsertStock(UpsertStock event, Emitter<StockState> emit) async {
    try {
      emit(StockLoading());
      await stockDAO.upsertStock(event.stock);
      final stocks = await stockDAO.getStocks();
      emit(StockOperationSuccess(stocks, 'Stock saved successfully'));
    } catch (error) {
      emit(StockError('Failed to save stock: ${error.toString()}'));
    }
  }

  Future<void> _onDeleteStock(DeleteStock event, Emitter<StockState> emit) async {
    try {
      emit(StockLoading());
      await stockDAO.deleteStock(event.stockId);
      final stocks = await stockDAO.getStocks();
      emit(StockOperationSuccess(stocks, 'Stock deleted successfully'));
    } catch (error) {
      emit(StockError('Failed to delete stock: ${error.toString()}'));
    }
  }
}
