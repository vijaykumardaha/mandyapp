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

  String get totalQuantityLabel {
    if (data.isEmpty) {
      return '${totalQuantity.toStringAsFixed(2)} units';
    }
    final byUnit = <String, double>{};
    for (final item in data) {
      byUnit[item.unit] = (byUnit[item.unit] ?? 0) + item.totalQuantity;
    }
    final dominant =
        byUnit.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return '${totalQuantity.toStringAsFixed(2)} ${dominant.key.unitAbbreviation}';
  }

  @override
  List<Object?> get props =>
      [data, totalRevenue, totalQuantity, totalTransactions];
}

class DailyPurchaseReportLoaded extends ReportsState {
  final List<DailyPurchaseData> data;
  final double totalCost;
  final double totalQuantity;
  final int totalTransactions;

  const DailyPurchaseReportLoaded({
    required this.data,
    required this.totalCost,
    required this.totalQuantity,
    required this.totalTransactions,
  });

  String get totalQuantityLabel {
    if (data.isEmpty) {
      return '${totalQuantity.toStringAsFixed(2)} units';
    }
    final byUnit = <String, double>{};
    for (final item in data) {
      byUnit[item.unit] = (byUnit[item.unit] ?? 0) + item.totalQuantity;
    }
    final dominant =
        byUnit.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return '${totalQuantity.toStringAsFixed(2)} ${dominant.key.unitAbbreviation}';
  }

  @override
  List<Object?> get props =>
      [data, totalCost, totalQuantity, totalTransactions];
}

class ExpensesReportLoaded extends ReportsState {
  final List<ExpensesReportData> data;
  final double totalAmount;
  final int totalTransactions;

  const ExpensesReportLoaded({
    required this.data,
    required this.totalAmount,
    required this.totalTransactions,
  });

  @override
  List<Object?> get props => [data, totalAmount, totalTransactions];
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
  final double totalBuyerPending;
  final double totalSellerPending;

  const PendingPaymentReportLoaded({
    required this.data,
    required this.totalPendingAmount,
    required this.totalBuyerPending,
    required this.totalSellerPending,
  });

  @override
  List<Object?> get props =>
      [data, totalPendingAmount, totalBuyerPending, totalSellerPending];
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
  final double todayExpenses;
  final int todayOrders;
  final double netBalance;
  final double openingBalance;
  final double totalReceived;
  final double totalPending;
  final double paidToSellers;
  final double pendingToSellers;
  final double buyerPendingCheckout;
  final double sellerPendingCheckout;
  final double totalPaid;
  final double totalReceive;

  const DashboardDataLoaded({
    required this.todaySales,
    required this.grossProfit,
    required this.todayExpenses,
    required this.todayOrders,
    required this.netBalance,
    required this.openingBalance,
    required this.totalReceived,
    required this.totalPending,
    required this.paidToSellers,
    required this.pendingToSellers,
    required this.buyerPendingCheckout,
    required this.sellerPendingCheckout,
    required this.totalPaid,
    required this.totalReceive,
  });

  @override
  List<Object?> get props => [
        todaySales,
        grossProfit,
        todayExpenses,
        todayOrders,
        netBalance,
        openingBalance,
        totalReceived,
        totalPending,
        paidToSellers,
        pendingToSellers,
        buyerPendingCheckout,
        sellerPendingCheckout,
        totalPaid,
        totalReceive,
      ];
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
  List<Object?> get props =>
      [totalReceived, totalPending, paidToSellers, pendingToSellers];
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

class StockTransactionReportLoaded extends ReportsState {
  final List<StockTransactionReportData> data;
  final double totalQuantity;
  final double totalAmount;

  const StockTransactionReportLoaded({
    required this.data,
    required this.totalQuantity,
    required this.totalAmount,
  });

  String get totalQuantityLabel {
    if (data.isEmpty) {
      return '${totalQuantity.toStringAsFixed(2)} units';
    }
    final byUnit = <String, double>{};
    for (final item in data) {
      final unit = (item.unit ?? '').trim();
      if (unit.isEmpty) continue;
      byUnit[unit] = (byUnit[unit] ?? 0) + item.buyQuantity;
    }
    if (byUnit.isEmpty) {
      return '${totalQuantity.toStringAsFixed(2)} units';
    }
    final dominant =
        byUnit.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return '${totalQuantity.toStringAsFixed(2)} ${dominant.key.unitAbbreviation}';
  }

  @override
  List<Object?> get props => [data, totalQuantity, totalAmount];
}

class StockSummaryReportLoaded extends ReportsState {
  final List<StockSummaryData> data;
  final double totalPurchaseAmount;
  final double totalSoldAmount;
  final double totalProfit;
  final double totalStockQuantity;

  const StockSummaryReportLoaded({
    required this.data,
    required this.totalPurchaseAmount,
    required this.totalSoldAmount,
    required this.totalProfit,
    required this.totalStockQuantity,
  });

  @override
  List<Object?> get props => [
        data,
        totalPurchaseAmount,
        totalSoldAmount,
        totalProfit,
        totalStockQuantity
      ];
}

class MandiTransactionReportLoaded extends ReportsState {
  final List<MandiTransactionReportData> data;
  final double totalPaid;
  final double totalReceive;
  final int totalTransactions;

  const MandiTransactionReportLoaded({
    required this.data,
    required this.totalPaid,
    required this.totalReceive,
    required this.totalTransactions,
  });

  @override
  List<Object?> get props => [data, totalPaid, totalReceive, totalTransactions];
}

class BalanceSheetReportLoaded extends ReportsState {
  final List<BalanceSheetReportData> data;
  final double openingBalance;
  final double totalNetBalance;
  final double totalProfit;
  final double totalExpenses;
  final double totalMandiPaid;
  final double totalMandiReceive;

  const BalanceSheetReportLoaded({
    required this.data,
    required this.openingBalance,
    required this.totalNetBalance,
    required this.totalProfit,
    required this.totalExpenses,
    required this.totalMandiPaid,
    required this.totalMandiReceive,
  });

  double get totalClosingBalance => openingBalance + totalNetBalance;

  @override
  List<Object?> get props => [
        data,
        openingBalance,
        totalNetBalance,
        totalProfit,
        totalExpenses,
        totalMandiPaid,
        totalMandiReceive,
      ];
}
