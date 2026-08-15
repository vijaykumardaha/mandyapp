part of 'reports_bloc.dart';

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

class LoadDailySalesReport extends ReportsEvent {
  final DateTime fromDate;
  final DateTime toDate;

  const LoadDailySalesReport({
    required this.fromDate,
    required this.toDate,
  });

  @override
  List<Object?> get props => [fromDate, toDate];
}

class LoadDailyPurchaseReport extends ReportsEvent {
  final DateTime fromDate;
  final DateTime toDate;

  const LoadDailyPurchaseReport({
    required this.fromDate,
    required this.toDate,
  });

  @override
  List<Object?> get props => [fromDate, toDate];
}

class LoadExpensesReport extends ReportsEvent {
  final DateTime fromDate;
  final DateTime toDate;

  const LoadExpensesReport({
    required this.fromDate,
    required this.toDate,
  });

  @override
  List<Object?> get props => [fromDate, toDate];
}

class LoadMandiProfitReport extends ReportsEvent {
  final DateTime fromDate;
  final DateTime toDate;

  const LoadMandiProfitReport({
    required this.fromDate,
    required this.toDate,
  });

  @override
  List<Object?> get props => [fromDate, toDate];
}

class LoadCustomerLedgerReport extends ReportsEvent {
  final DateTime fromDate;
  final DateTime toDate;

  const LoadCustomerLedgerReport({
    required this.fromDate,
    required this.toDate,
  });

  @override
  List<Object?> get props => [fromDate, toDate];
}

class LoadPendingPaymentReport extends ReportsEvent {
  final DateTime fromDate;
  final DateTime toDate;

  const LoadPendingPaymentReport({
    required this.fromDate,
    required this.toDate,
  });

  @override
  List<Object?> get props => [fromDate, toDate];
}

class LoadReportsSummary extends ReportsEvent {
  final DateTime fromDate;
  final DateTime toDate;

  const LoadReportsSummary({
    required this.fromDate,
    required this.toDate,
  });

  @override
  List<Object?> get props => [fromDate, toDate];
}

class LoadDashboardData extends ReportsEvent {
  final DateTime fromDate;
  final DateTime toDate;

  const LoadDashboardData({
    required this.fromDate,
    required this.toDate,
  });

  @override
  List<Object?> get props => [fromDate, toDate];
}

class LoadPaymentSummary extends ReportsEvent {
  const LoadPaymentSummary();
}

class LoadTodayOrders extends ReportsEvent {
  const LoadTodayOrders();
}

class LoadNetBalance extends ReportsEvent {
  const LoadNetBalance();
}

class LoadStockTransactionReport extends ReportsEvent {
  final DateTime fromDate;
  final DateTime toDate;

  const LoadStockTransactionReport({
    required this.fromDate,
    required this.toDate,
  });

  @override
  List<Object?> get props => [fromDate, toDate];
}

class LoadStockSummaryReport extends ReportsEvent {
  final DateTime fromDate;
  final DateTime toDate;

  const LoadStockSummaryReport({
    required this.fromDate,
    required this.toDate,
  });

  @override
  List<Object?> get props => [fromDate, toDate];
}

class LoadMandiTransactionReport extends ReportsEvent {
  final DateTime fromDate;
  final DateTime toDate;

  const LoadMandiTransactionReport({
    required this.fromDate,
    required this.toDate,
  });

  @override
  List<Object?> get props => [fromDate, toDate];
}

class LoadBalanceSheetReport extends ReportsEvent {
  final DateTime fromDate;
  final DateTime toDate;

  const LoadBalanceSheetReport({
    required this.fromDate,
    required this.toDate,
  });

  @override
  List<Object?> get props => [fromDate, toDate];
}
