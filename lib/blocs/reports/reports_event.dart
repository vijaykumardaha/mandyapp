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

class LoadSellerPurchaseReport extends ReportsEvent {
  final DateTime fromDate;
  final DateTime toDate;

  const LoadSellerPurchaseReport({
    required this.fromDate,
    required this.toDate,
  });

  @override
  List<Object?> get props => [fromDate, toDate];
}

class LoadBuyerSalesReport extends ReportsEvent {
  final DateTime fromDate;
  final DateTime toDate;

  const LoadBuyerSalesReport({
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

class LoadPaymentModeReport extends ReportsEvent {
  final DateTime fromDate;
  final DateTime toDate;

  const LoadPaymentModeReport({
    required this.fromDate,
    required this.toDate,
  });

  @override
  List<Object?> get props => [fromDate, toDate];
}

class LoadStockMovementReport extends ReportsEvent {
  final DateTime fromDate;
  final DateTime toDate;

  const LoadStockMovementReport({
    required this.fromDate,
    required this.toDate,
  });

  @override
  List<Object?> get props => [fromDate, toDate];
}

class LoadTopSellingProductsReport extends ReportsEvent {
  final DateTime fromDate;
  final DateTime toDate;

  const LoadTopSellingProductsReport({
    required this.fromDate,
    required this.toDate,
  });

  @override
  List<Object?> get props => [fromDate, toDate];
}

class LoadChargesPerformanceReport extends ReportsEvent {
  final DateTime fromDate;
  final DateTime toDate;

  const LoadChargesPerformanceReport({
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
  const LoadDashboardData();
}

class LoadStockSummary extends ReportsEvent {
  const LoadStockSummary();
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
