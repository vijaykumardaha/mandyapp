import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mandyapp/dao/report_dao.dart';
import 'package:mandyapp/models/report_models.dart';

part 'reports_event.dart';
part 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final ReportDAO reportDAO;

  ReportsBloc({
    required this.reportDAO,
  }) : super(ReportsInitial()) {
    on<LoadDailySalesReport>(_onLoadDailySalesReport);
    on<LoadSellerPurchaseReport>(_onLoadSellerPurchaseReport);
    on<LoadBuyerSalesReport>(_onLoadBuyerSalesReport);
    on<LoadMandiProfitReport>(_onLoadMandiProfitReport);
    on<LoadCustomerLedgerReport>(_onLoadCustomerLedgerReport);
    on<LoadPendingPaymentReport>(_onLoadPendingPaymentReport);
    on<LoadPaymentModeReport>(_onLoadPaymentModeReport);
    on<LoadStockMovementReport>(_onLoadStockMovementReport);
    on<LoadTopSellingProductsReport>(_onLoadTopSellingProductsReport);
    on<LoadChargesPerformanceReport>(_onLoadChargesPerformanceReport);
    on<LoadReportsSummary>(_onLoadReportsSummary);
    on<LoadDashboardData>(_onLoadDashboardData);
    on<LoadStockSummary>(_onLoadStockSummary);
    on<LoadPaymentSummary>(_onLoadPaymentSummary);
    on<LoadTodayOrders>(_onLoadTodayOrders);
    on<LoadNetBalance>(_onLoadNetBalance);
  }

  Future<void> _onLoadDailySalesReport(
    LoadDailySalesReport event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());

    try {
      final rawData = await reportDAO.getDailySalesReport(
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      if (rawData.isEmpty) {
        emit(ReportsEmpty());
        return;
      }

      final data = rawData.map(DailySalesData.fromJson).toList();

      final totalRevenue = data.fold(0.0, (sum, item) => sum + item.totalRevenue);
      final totalQuantity = data.fold(0.0, (sum, item) => sum + item.totalQuantity);
      final totalTransactions = data.fold(0, (sum, item) => sum + item.transactionCount);

      emit(DailySalesReportLoaded(
        data: data,
        totalRevenue: totalRevenue,
        totalQuantity: totalQuantity,
        totalTransactions: totalTransactions,
      ));
    } catch (error) {
      emit(ReportsError('Failed to load daily sales report: ${error.toString()}'));
    }
  }

  Future<void> _onLoadSellerPurchaseReport(
    LoadSellerPurchaseReport event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());

    try {
      final rawData = await reportDAO.getSellerPurchaseSummary(
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      if (rawData.isEmpty) {
        emit(ReportsEmpty());
        return;
      }

      final data = rawData.map(SellerPurchaseData.fromJson).toList();

      final totalCost = data.fold(0.0, (sum, item) => sum + item.totalCost);
      final totalQuantity = data.fold(0.0, (sum, item) => sum + item.totalQuantity);
      final totalTransactions = data.fold(0, (sum, item) => sum + item.totalPurchases);

      emit(SellerPurchaseReportLoaded(
        data: data,
        totalCost: totalCost,
        totalQuantity: totalQuantity,
        totalTransactions: totalTransactions,
      ));
    } catch (error) {
      emit(ReportsError('Failed to load seller purchase report: ${error.toString()}'));
    }
  }

  Future<void> _onLoadBuyerSalesReport(
    LoadBuyerSalesReport event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());

    try {
      final rawData = await reportDAO.getBuyerSalesSummary(
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      if (rawData.isEmpty) {
        emit(ReportsEmpty());
        return;
      }

      final data = rawData.map(BuyerSalesData.fromJson).toList();

      final totalRevenue = data.fold(0.0, (sum, item) => sum + item.totalRevenue);
      final totalQuantity = data.fold(0.0, (sum, item) => sum + item.totalQuantity);
      final totalTransactions = data.fold(0, (sum, item) => sum + item.totalBills);

      emit(BuyerSalesReportLoaded(
        data: data,
        totalRevenue: totalRevenue,
        totalQuantity: totalQuantity,
        totalTransactions: totalTransactions,
      ));
    } catch (error) {
      emit(ReportsError('Failed to load buyer sales report: ${error.toString()}'));
    }
  }

  Future<void> _onLoadMandiProfitReport(
    LoadMandiProfitReport event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());

    try {
      final rawData = await reportDAO.getMandiProfitReport(
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      if (rawData.isEmpty) {
        emit(ReportsEmpty());
        return;
      }

      final data = rawData.map(MandiProfitData.fromJson).toList();

      final totalProfit = data.fold(0.0, (sum, item) => sum + item.dailyProfit);
      final totalRevenue = data.fold(0.0, (sum, item) => sum + item.dailyRevenue);
      final totalCost = data.fold(0.0, (sum, item) => sum + item.dailyCost);

      emit(MandiProfitReportLoaded(
        data: data,
        totalProfit: totalProfit,
        totalRevenue: totalRevenue,
        totalCost: totalCost,
      ));
    } catch (error) {
      emit(ReportsError('Failed to load mandi profit report: ${error.toString()}'));
    }
  }

  Future<void> _onLoadCustomerLedgerReport(
    LoadCustomerLedgerReport event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());

    try {
      final rawData = await reportDAO.getCustomerLedgerReport(
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      if (rawData.isEmpty) {
        emit(ReportsEmpty());
        return;
      }

      final data = rawData.map(CustomerLedgerData.fromJson).toList();
      final totalNetBalance = data.fold(0.0, (sum, item) => sum + item.netBalance);

      emit(CustomerLedgerReportLoaded(
        data: data,
        totalNetBalance: totalNetBalance,
      ));
    } catch (error) {
      emit(ReportsError('Failed to load customer ledger report: ${error.toString()}'));
    }
  }

  Future<void> _onLoadPendingPaymentReport(
    LoadPendingPaymentReport event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());

    try {
      final rawData = await reportDAO.getPendingPaymentReport(
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      if (rawData.isEmpty) {
        emit(ReportsEmpty());
        return;
      }

      final data = rawData.map(PendingPaymentData.fromJson).toList();
      final totalPendingAmount = data.fold(0.0, (sum, item) => sum + item.pendingAmount);

      emit(PendingPaymentReportLoaded(
        data: data,
        totalPendingAmount: totalPendingAmount,
      ));
    } catch (error) {
      emit(ReportsError('Failed to load pending payment report: ${error.toString()}'));
    }
  }

  Future<void> _onLoadPaymentModeReport(
    LoadPaymentModeReport event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());

    try {
      final rawData = await reportDAO.getPaymentModeSummary(
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      if (rawData.isEmpty) {
        emit(ReportsEmpty());
        return;
      }

      final data = rawData.map(PaymentModeData.fromJson).toList();
      final totalAmount = data.fold(0.0, (sum, item) => sum + item.totalAmount);

      emit(PaymentModeReportLoaded(
        data: data,
        totalAmount: totalAmount,
      ));
    } catch (error) {
      emit(ReportsError('Failed to load payment mode report: ${error.toString()}'));
    }
  }

  Future<void> _onLoadStockMovementReport(
    LoadStockMovementReport event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());

    try {
      final rawData = await reportDAO.getStockMovementReport(
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      if (rawData.isEmpty) {
        emit(ReportsEmpty());
        return;
      }

      final data = rawData.map(StockMovementData.fromJson).toList();
      final netStockChange = data.fold(0.0, (sum, item) => sum + item.netStockChange);

      emit(StockMovementReportLoaded(
        data: data,
        netStockChange: netStockChange,
      ));
    } catch (error) {
      emit(ReportsError('Failed to load stock movement report: ${error.toString()}'));
    }
  }

  Future<void> _onLoadTopSellingProductsReport(
    LoadTopSellingProductsReport event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());

    try {
      final rawData = await reportDAO.getTopSellingProducts(
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      if (rawData.isEmpty) {
        emit(ReportsEmpty());
        return;
      }

      final data = rawData.map(TopSellingProductData.fromJson).toList();
      final totalRevenue = data.fold(0.0, (sum, item) => sum + item.totalRevenue);

      emit(TopSellingProductsReportLoaded(
        data: data,
        totalRevenue: totalRevenue,
      ));
    } catch (error) {
      emit(ReportsError('Failed to load top selling products report: ${error.toString()}'));
    }
  }

  Future<void> _onLoadChargesPerformanceReport(
    LoadChargesPerformanceReport event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());

    try {
      final rawData = await reportDAO.getChargesPerformanceReport(
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      if (rawData.isEmpty) {
        emit(ReportsEmpty());
        return;
      }

      final data = rawData.map(ChargesPerformanceData.fromJson).toList();
      final totalChargeAmount = data.fold(0.0, (sum, item) => sum + item.totalChargeAmount);

      emit(ChargesPerformanceReportLoaded(
        data: data,
        totalChargeAmount: totalChargeAmount,
      ));
    } catch (error) {
      emit(ReportsError('Failed to load charges performance report: ${error.toString()}'));
    }
  }

  Future<void> _onLoadReportsSummary(
    LoadReportsSummary event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());

    try {
      final rawData = await reportDAO.getReportsSummary(
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      if (rawData.isEmpty) {
        emit(ReportsEmpty());
        return;
      }

      final summary = ReportsSummaryData.fromJson(rawData);

      emit(ReportsSummaryLoaded(summary));
    } catch (error) {
      emit(ReportsError('Failed to load reports summary: ${error.toString()}'));
    }
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());

    try {
      // Get today's date range
      final today = DateTime.now();
      final fromDate = DateTime(today.year, today.month, today.day);
      final toDate = DateTime(today.year, today.month, today.day, 23, 59, 59);

      // Get all dashboard data in parallel
      final todaySalesFuture = reportDAO.getDailySalesReport(fromDate: fromDate, toDate: toDate);
      final profitFuture = reportDAO.getMandiProfitReport(fromDate: fromDate, toDate: toDate);
      final paymentSummaryFuture = reportDAO.getPaymentSummary();
      final stockSummaryFuture = reportDAO.getStockSummary();
      final ordersFuture = reportDAO.getTodayOrdersCount();
      final netBalanceFuture = reportDAO.getNetBalance();

      final results = await Future.wait([
        todaySalesFuture,
        profitFuture,
        paymentSummaryFuture,
        stockSummaryFuture,
        ordersFuture,
        netBalanceFuture,
      ]);

      final todaySalesData = results[0] as List<Map<String, dynamic>>;
      final profitData = results[1] as List<Map<String, dynamic>>;
      final paymentSummary = results[2] as Map<String, dynamic>;
      final stockSummary = results[3] as Map<String, dynamic>;
      final ordersCount = results[4] as int;
      final netBalance = results[5] as double;

      // Calculate today's sales
      final todaySales = todaySalesData.fold(0.0, (sum, item) => sum + (item['total_revenue'] as num).toDouble());

      // Calculate today's profit
      final todayProfit = profitData.fold(0.0, (sum, item) => sum + (item['daily_profit'] as num).toDouble());

      emit(DashboardDataLoaded(
        todaySales: todaySales,
        grossProfit: todayProfit,
        todayOrders: ordersCount,
        netBalance: netBalance,
        totalReceived: paymentSummary['total_received'] ?? 0.0,
        totalPending: paymentSummary['total_pending'] ?? 0.0,
        paidToSellers: paymentSummary['total_paid_to_sellers'] ?? 0.0,
        pendingToSellers: paymentSummary['total_pending_to_sellers'] ?? 0.0,
        availableStock: stockSummary['total_stock'] ?? 0.0,
        lowStockItems: stockSummary['low_stock_count'] ?? 0,
        outOfStockItems: stockSummary['out_of_stock_count'] ?? 0,
      ));
    } catch (error) {
      emit(ReportsError('Failed to load dashboard data: ${error.toString()}'));
    }
  }

  Future<void> _onLoadStockSummary(
    LoadStockSummary event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());

    try {
      final stockSummary = await reportDAO.getStockSummary();

      emit(StockSummaryLoaded(
        availableStock: stockSummary['total_stock'] ?? 0.0,
        lowStockItems: stockSummary['low_stock_count'] ?? 0,
        outOfStockItems: stockSummary['out_of_stock_count'] ?? 0,
      ));
    } catch (error) {
      emit(ReportsError('Failed to load stock summary: ${error.toString()}'));
    }
  }

  Future<void> _onLoadPaymentSummary(
    LoadPaymentSummary event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());

    try {
      final paymentSummary = await reportDAO.getPaymentSummary();

      emit(PaymentSummaryLoaded(
        totalReceived: paymentSummary['total_received'] ?? 0.0,
        totalPending: paymentSummary['total_pending'] ?? 0.0,
        paidToSellers: paymentSummary['total_paid_to_sellers'] ?? 0.0,
        pendingToSellers: paymentSummary['total_pending_to_sellers'] ?? 0.0,
      ));
    } catch (error) {
      emit(ReportsError('Failed to load payment summary: ${error.toString()}'));
    }
  }

  Future<void> _onLoadTodayOrders(
    LoadTodayOrders event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());

    try {
      final ordersCount = await reportDAO.getTodayOrdersCount();

      emit(TodayOrdersLoaded(ordersCount));
    } catch (error) {
      emit(ReportsError('Failed to load today orders: ${error.toString()}'));
    }
  }

  Future<void> _onLoadNetBalance(
    LoadNetBalance event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());

    try {
      final netBalance = await reportDAO.getNetBalance();

      emit(NetBalanceLoaded(netBalance));
    } catch (error) {
      emit(ReportsError('Failed to load net balance: ${error.toString()}'));
    }
  }
}
