part of 'reports_bloc.dart';

abstract class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportsEmpty extends ReportsState {}

class ReportsError extends ReportsState {
  final String message;

  const ReportsError(this.message);

  @override
  List<Object?> get props => [message];
}

class DailySalesReportLoaded extends ReportsState {
  final List<DailySalesData> data;
  final double totalRevenue;
  final double totalQuantity;
  final int totalTransactions;

  const DailySalesReportLoaded({
    required this.data,
    required this.totalRevenue,
    required this.totalQuantity,
    required this.totalTransactions,
  });

  @override
  List<Object?> get props => [data, totalRevenue, totalQuantity, totalTransactions];
}

class SellerPurchaseReportLoaded extends ReportsState {
  final List<SellerPurchaseData> data;
  final double totalCost;
  final double totalQuantity;
  final int totalTransactions;

  const SellerPurchaseReportLoaded({
    required this.data,
    required this.totalCost,
    required this.totalQuantity,
    required this.totalTransactions,
  });

  @override
  List<Object?> get props => [data, totalCost, totalQuantity, totalTransactions];
}

class BuyerSalesReportLoaded extends ReportsState {
  final List<BuyerSalesData> data;
  final double totalRevenue;
  final double totalQuantity;
  final int totalTransactions;

  const BuyerSalesReportLoaded({
    required this.data,
    required this.totalRevenue,
    required this.totalQuantity,
    required this.totalTransactions,
  });

  @override
  List<Object?> get props => [data, totalRevenue, totalQuantity, totalTransactions];
}

class MandiProfitReportLoaded extends ReportsState {
  final List<MandiProfitData> data;
  final double totalProfit;
  final double totalRevenue;
  final double totalCost;

  const MandiProfitReportLoaded({
    required this.data,
    required this.totalProfit,
    required this.totalRevenue,
    required this.totalCost,
  });

  @override
  List<Object?> get props => [data, totalProfit, totalRevenue, totalCost];
}

class CustomerLedgerReportLoaded extends ReportsState {
  final List<CustomerLedgerData> data;
  final double totalNetBalance;

  const CustomerLedgerReportLoaded({
    required this.data,
    required this.totalNetBalance,
  });

  @override
  List<Object?> get props => [data, totalNetBalance];
}

class PendingPaymentReportLoaded extends ReportsState {
  final List<PendingPaymentData> data;
  final double totalPendingAmount;

  const PendingPaymentReportLoaded({
    required this.data,
    required this.totalPendingAmount,
  });

  @override
  List<Object?> get props => [data, totalPendingAmount];
}

class PaymentModeReportLoaded extends ReportsState {
  final List<PaymentModeData> data;
  final double totalAmount;

  const PaymentModeReportLoaded({
    required this.data,
    required this.totalAmount,
  });

  @override
  List<Object?> get props => [data, totalAmount];
}

class StockMovementReportLoaded extends ReportsState {
  final List<StockMovementData> data;
  final double netStockChange;

  const StockMovementReportLoaded({
    required this.data,
    required this.netStockChange,
  });

  @override
  List<Object?> get props => [data, netStockChange];
}

class TopSellingProductsReportLoaded extends ReportsState {
  final List<TopSellingProductData> data;
  final double totalRevenue;

  const TopSellingProductsReportLoaded({
    required this.data,
    required this.totalRevenue,
  });

  @override
  List<Object?> get props => [data, totalRevenue];
}

class ChargesPerformanceReportLoaded extends ReportsState {
  final List<ChargesPerformanceData> data;
  final double totalChargeAmount;

  const ChargesPerformanceReportLoaded({
    required this.data,
    required this.totalChargeAmount,
  });

  @override
  List<Object?> get props => [data, totalChargeAmount];
}

class ReportsSummaryLoaded extends ReportsState {
  final ReportsSummaryData summary;

  const ReportsSummaryLoaded(this.summary);

  @override
  List<Object?> get props => [summary];
}

class DashboardDataLoaded extends ReportsState {
  final double todaySales;
  final double grossProfit;
  final int todayOrders;
  final double netBalance;
  final double totalReceived;
  final double totalPending;
  final double paidToSellers;
  final double pendingToSellers;
  final double availableStock;
  final int lowStockItems;
  final int outOfStockItems;

  const DashboardDataLoaded({
    required this.todaySales,
    required this.grossProfit,
    required this.todayOrders,
    required this.netBalance,
    required this.totalReceived,
    required this.totalPending,
    required this.paidToSellers,
    required this.pendingToSellers,
    required this.availableStock,
    required this.lowStockItems,
    required this.outOfStockItems,
  });

  @override
  List<Object?> get props => [
    todaySales,
    grossProfit,
    todayOrders,
    netBalance,
    totalReceived,
    totalPending,
    paidToSellers,
    pendingToSellers,
    availableStock,
    lowStockItems,
    outOfStockItems,
  ];
}

class StockSummaryLoaded extends ReportsState {
  final double availableStock;
  final int lowStockItems;
  final int outOfStockItems;

  const StockSummaryLoaded({
    required this.availableStock,
    required this.lowStockItems,
    required this.outOfStockItems,
  });

  @override
  List<Object?> get props => [availableStock, lowStockItems, outOfStockItems];
}

class PaymentSummaryLoaded extends ReportsState {
  final double totalReceived;
  final double totalPending;
  final double paidToSellers;
  final double pendingToSellers;

  const PaymentSummaryLoaded({
    required this.totalReceived,
    required this.totalPending,
    required this.paidToSellers,
    required this.pendingToSellers,
  });

  @override
  List<Object?> get props => [totalReceived, totalPending, paidToSellers, pendingToSellers];
}

class TodayOrdersLoaded extends ReportsState {
  final int ordersCount;

  const TodayOrdersLoaded(this.ordersCount);

  @override
  List<Object?> get props => [ordersCount];
}

class NetBalanceLoaded extends ReportsState {
  final double netBalance;

  const NetBalanceLoaded(this.netBalance);

  @override
  List<Object?> get props => [netBalance];
}
