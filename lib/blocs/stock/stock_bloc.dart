import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mandiapp/dao/stock_dao.dart';
import 'package:mandiapp/models/stock_model.dart';

part 'stock_event.dart';
part 'stock_state.dart';

class StockBloc extends Bloc<StockEvent, StockState> {
  final StockDAO _stockDAO = StockDAO();

  StockBloc() : super(StockInitial()) {
    // ── Stock Events ──
    on<LoadStocks>(_onLoadStocks);
    on<AddStock>(_onAddStock);
    on<UpdateStock>(_onUpdateStock);
    on<DeleteStock>(_onDeleteStock);
    on<SearchStocks>(_onSearchStocks);

    // ── Stock Transaction Events ──
    on<LoadStockTransactions>(_onLoadStockTransactions);
    on<LoadTransactionsByStock>(_onLoadTransactionsByStock);
    on<LoadTransactionsByBill>(_onLoadTransactionsByBill);
    on<AddStockTransaction>(_onAddStockTransaction);
    on<DeleteStockTransaction>(_onDeleteStockTransaction);
  }

  Future<void> _onLoadStocks(
    LoadStocks event,
    Emitter<StockState> emit,
  ) async {
    try {
      emit(StockLoading());
      final stocks = await _stockDAO.getAllStocks();
      emit(StockLoaded(stocks));
    } catch (e) {
      emit(const StockError('Failed to load stocks. Please try again.'));
    }
  }

  Future<void> _onAddStock(
    AddStock event,
    Emitter<StockState> emit,
  ) async {
    try {
      emit(StockLoading());
      await _stockDAO.insertStock(event.stock);
      final stocks = await _stockDAO.getAllStocks();
      emit(StockLoaded(stocks));
      emit(const StockOperationSuccess('Stock added successfully'));
    } catch (e) {
      emit(const StockError('Failed to add stock. Please try again.'));
    }
  }

  Future<void> _onUpdateStock(
    UpdateStock event,
    Emitter<StockState> emit,
  ) async {
    try {
      emit(StockLoading());
      await _stockDAO.updateStock(event.stock);
      final stocks = await _stockDAO.getAllStocks();
      emit(StockLoaded(stocks));
      emit(const StockOperationSuccess('Stock updated successfully'));
    } catch (e) {
      emit(const StockError('Failed to update stock. Please try again.'));
    }
  }

  Future<void> _onDeleteStock(
    DeleteStock event,
    Emitter<StockState> emit,
  ) async {
    try {
      emit(StockLoading());
      await _stockDAO.deleteStock(event.stockId);
      final stocks = await _stockDAO.getAllStocks();
      emit(StockLoaded(stocks));
      emit(const StockOperationSuccess('Stock deleted successfully'));
    } catch (e) {
      emit(const StockError('Failed to delete stock. Please try again.'));
    }
  }

  Future<void> _onSearchStocks(
    SearchStocks event,
    Emitter<StockState> emit,
  ) async {
    try {
      emit(StockLoading());
      final allStocks = await _stockDAO.getAllStocks();
      if (event.query.isEmpty) {
        emit(StockLoaded(allStocks));
        return;
      }
      final query = event.query.toLowerCase();
      final filtered = allStocks
          .where((s) =>
              s.productId.toString().contains(query) ||
              s.sellerId.toString().contains(query))
          .toList();
      emit(StockLoaded(filtered));
    } catch (e) {
      emit(const StockError('Failed to search stocks. Please try again.'));
    }
  }

  // ── Stock Transaction Handlers ──────────────

  Future<void> _onLoadStockTransactions(
    LoadStockTransactions event,
    Emitter<StockState> emit,
  ) async {
    try {
      emit(StockLoading());
      final transactions = await _stockDAO.getAllStockTransactions();
      emit(StockTransactionsLoaded(transactions));
    } catch (e) {
      emit(const StockError(
          'Failed to load stock transactions. Please try again.'));
    }
  }

  Future<void> _onLoadTransactionsByStock(
    LoadTransactionsByStock event,
    Emitter<StockState> emit,
  ) async {
    try {
      emit(StockLoading());
      final transactions =
          await _stockDAO.getTransactionsByStock(event.stockId);
      emit(StockTransactionsLoaded(transactions));
    } catch (e) {
      emit(const StockError('Failed to load transactions. Please try again.'));
    }
  }

  Future<void> _onLoadTransactionsByBill(
    LoadTransactionsByBill event,
    Emitter<StockState> emit,
  ) async {
    try {
      emit(StockLoading());
      final transactions = await _stockDAO.getTransactionsByBill(event.billId);
      emit(StockTransactionsLoaded(transactions));
    } catch (e) {
      emit(const StockError('Failed to load transactions. Please try again.'));
    }
  }

  Future<void> _onAddStockTransaction(
    AddStockTransaction event,
    Emitter<StockState> emit,
  ) async {
    try {
      emit(StockLoading());
      await _stockDAO.insertStockTransaction(event.transaction);

      // Update stock quantity
      final stock = await _stockDAO.getStockById(event.transaction.stockId);
      if (stock != null) {
        stock.quantity = stock.quantity - event.transaction.buyQuantity;
        stock.soldQuantity = stock.soldQuantity + event.transaction.buyQuantity;
        stock.soldAmount = stock.soldAmount + event.transaction.totalAmount;
        await _stockDAO.updateStock(stock);
      }

      final transactions = await _stockDAO.getAllStockTransactions();
      emit(StockTransactionsLoaded(transactions));
      emit(const StockOperationSuccess('Stock transaction added successfully'));
    } catch (e) {
      emit(const StockError(
          'Failed to add stock transaction. Please try again.'));
    }
  }

  Future<void> _onDeleteStockTransaction(
    DeleteStockTransaction event,
    Emitter<StockState> emit,
  ) async {
    try {
      emit(StockLoading());
      await _stockDAO.deleteStockTransaction(event.transactionId);
      final transactions = await _stockDAO.getAllStockTransactions();
      emit(StockTransactionsLoaded(transactions));
      emit(const StockOperationSuccess(
          'Stock transaction deleted successfully'));
    } catch (e) {
      emit(const StockError(
          'Failed to delete stock transaction. Please try again.'));
    }
  }
}
