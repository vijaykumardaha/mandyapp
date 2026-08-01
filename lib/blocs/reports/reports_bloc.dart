import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mandiapp/dao/report_dao.dart';
import 'package:mandiapp/helpers/extensions/string.dart';
import 'package:mandiapp/models/report_models.dart';

part 'reports_event.dart';
part 'reports_state.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final ReportDAO reportDAO;

  ReportsBloc({
    required this.reportDAO,
  }) : super(ReportsInitial()) {
    on<LoadDailySalesReport>(_onLoadDailySalesReport);
    on<LoadDailyPurchaseReport>(_onLoadDailyPurchaseReport);
    on<LoadMandiProfitReport>(_onLoadMandiProfitReport);
    on<LoadCustomerLedgerReport>(_onLoadCustomerLedgerReport);
    on<LoadPendingPaymentReport>(_onLoadPendingPaymentReport);
    on<LoadReportsSummary>(_onLoadReportsSummary);
    on<LoadDashboardData>(_onLoadDashboardData);
    on<LoadPaymentSummary>(_onLoadPaymentSummary);
    on<LoadTodayOrders>(_onLoadTodayOrders);
    on<LoadNetBalance>(_onLoadNetBalance);
    on<LoadStockTransactionReport>(_onLoadStockTransactionReport);
    on<LoadStockSummaryReport>(_onLoadStockSummaryReport);
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

      final totalRevenue =
          data.fold(0.0, (sum, item) => sum + item.totalRevenue);
      final totalQuantity =
          data.fold(0.0, (sum, item) => sum + item.totalQuantity);
      final totalTransactions =
          data.fold(0, (sum, item) => sum + item.transactionCount);

      emit(DailySalesReportLoaded(
        data: data,
        totalRevenue: totalRevenue,
        totalQuantity: totalQuantity,
        totalTransactions: totalTransactions,
      ));
    } catch (error) {
      emit(const ReportsError(
          'Failed to load daily sales report. Please try again.'));
    }
  }

  Future<void> _onLoadDailyPurchaseReport(
    LoadDailyPurchaseReport event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());

    try {
      final rawData = await reportDAO.getDailyPurchaseReport(
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      if (rawData.isEmpty) {
        emit(ReportsEmpty());
        return;
      }

      final data = rawData.map(DailyPurchaseData.fromJson).toList();

      final totalCost = data.fold(0.0, (sum, item) => sum + item.totalCost);
      final totalQuantity =
          data.fold(0.0, (sum, item) => sum + item.totalQuantity);
      final totalTransactions =
          data.fold(0, (sum, item) => sum + item.transactionCount);

      emit(DailyPurchaseReportLoaded(
        data: data,
        totalCost: totalCost,
        totalQuantity: totalQuantity,
        totalTransactions: totalTransactions,
      ));
    } catch (error) {
      emit(const ReportsError(
          'Failed to load daily purchase report. Please try again.'));
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
      final totalRevenue =
          data.fold(0.0, (sum, item) => sum + item.dailyRevenue);
      final totalCost = data.fold(0.0, (sum, item) => sum + item.dailyCost);

      emit(MandiProfitReportLoaded(
        data: data,
        totalProfit: totalProfit,
        totalRevenue: totalRevenue,
        totalCost: totalCost,
      ));
    } catch (error) {
      emit(const ReportsError(
          'Failed to load mandi profit report. Please try again.'));
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
      final totalNetBalance =
          data.fold(0.0, (sum, item) => sum + item.netBalance);

      emit(CustomerLedgerReportLoaded(
        data: data,
        totalNetBalance: totalNetBalance,
      ));
    } catch (error) {
      emit(const ReportsError(
          'Failed to load customer ledger report. Please try again.'));
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
      final totalPendingAmount =
          data.fold(0.0, (sum, item) => sum + item.pendingAmount);
      final totalBuyerPending = data
          .where((item) => item.billingType == 'Buyer')
          .fold(0.0, (sum, item) => sum + item.pendingAmount);
      final totalSellerPending = data
          .where((item) => item.billingType == 'Seller')
          .fold(0.0, (sum, item) => sum + item.pendingAmount);

      emit(PendingPaymentReportLoaded(
        data: data,
        totalPendingAmount: totalPendingAmount,
        totalBuyerPending: totalBuyerPending,
        totalSellerPending: totalSellerPending,
      ));
    } catch (error) {
      emit(const ReportsError(
          'Failed to load pending payment report. Please try again.'));
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
      emit(const ReportsError(
          'Failed to load reports summary. Please try again.'));
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
      final todaySalesFuture =
          reportDAO.getDailySalesReport(fromDate: fromDate, toDate: toDate);
      final profitFuture =
          reportDAO.getMandiProfitReport(fromDate: fromDate, toDate: toDate);
      final paymentSummaryFuture =
          reportDAO.getPaymentSummary(fromDate: fromDate, toDate: toDate);
      final ordersFuture = reportDAO.getTodayOrdersCount();
      final netBalanceFuture =
          reportDAO.getNetBalance(fromDate: fromDate, toDate: toDate);

      final results = await Future.wait([
        todaySalesFuture,
        profitFuture,
        paymentSummaryFuture,
        ordersFuture,
        netBalanceFuture,
      ]);

      final todaySalesData = results[0] as List<Map<String, dynamic>>;
      final profitData = results[1] as List<Map<String, dynamic>>;
      final paymentSummary = results[2] as Map<String, dynamic>;
      final ordersCount = results[3] as int;
      final netBalance = results[4] as double;

      // Calculate today's sales
      final todaySales = todaySalesData.fold(
          0.0, (sum, item) => sum + (item['total_revenue'] as num).toDouble());

      // Calculate today's profit
      final todayProfit = profitData.fold(
          0.0, (sum, item) => sum + (item['daily_profit'] as num).toDouble());

      emit(DashboardDataLoaded(
          todaySales: todaySales,
          grossProfit: todayProfit,
          todayOrders: ordersCount,
          netBalance: netBalance,
          totalReceived: paymentSummary['total_received'] ?? 0.0,
          totalPending: paymentSummary['total_pending'] ?? 0.0,
          paidToSellers: paymentSummary['total_paid_to_sellers'] ?? 0.0,
          pendingToSellers: paymentSummary['total_pending_to_sellers'] ?? 0.0));
    } catch (error) {
      emit(const ReportsError(
          'Failed to load dashboard data. Please try again.'));
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
      emit(const ReportsError(
          'Failed to load payment summary. Please try again.'));
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
      emit(
          const ReportsError('Failed to load today orders. Please try again.'));
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
      emit(const ReportsError('Failed to load net balance. Please try again.'));
    }
  }

  Future<void> _onLoadStockTransactionReport(
    LoadStockTransactionReport event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());

    try {
      final rawData = await reportDAO.getStockTransactionReport(
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      if (rawData.isEmpty) {
        emit(ReportsEmpty());
        return;
      }

      final data = rawData.map(StockTransactionReportData.fromJson).toList();
      final totalQuantity =
          data.fold(0.0, (sum, item) => sum + item.buyQuantity);
      final totalAmount = data.fold(0.0, (sum, item) => sum + item.totalAmount);

      emit(StockTransactionReportLoaded(
        data: data,
        totalQuantity: totalQuantity,
        totalAmount: totalAmount,
      ));
    } catch (error) {
      emit(const ReportsError(
          'Failed to load stock transaction report. Please try again.'));
    }
  }

  Future<void> _onLoadStockSummaryReport(
    LoadStockSummaryReport event,
    Emitter<ReportsState> emit,
  ) async {
    emit(ReportsLoading());

    try {
      final rawData = await reportDAO.getStockSummaryReport(
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      if (rawData.isEmpty) {
        emit(ReportsEmpty());
        return;
      }

      final data = rawData.map(StockSummaryData.fromJson).toList();
      final totalPurchaseAmount =
          data.fold(0.0, (sum, item) => sum + item.purchaseAmount);
      final totalSoldAmount =
          data.fold(0.0, (sum, item) => sum + item.soldAmount);
      final totalProfit = data.fold(0.0, (sum, item) => sum + item.profit);
      final totalStockQuantity =
          data.fold(0.0, (sum, item) => sum + item.quantity);

      emit(StockSummaryReportLoaded(
        data: data,
        totalPurchaseAmount: totalPurchaseAmount,
        totalSoldAmount: totalSoldAmount,
        totalProfit: totalProfit,
        totalStockQuantity: totalStockQuantity,
      ));
    } catch (error) {
      emit(const ReportsError(
          'Failed to load stock summary report. Please try again.'));
    }
  }
}
