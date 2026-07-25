import 'package:flutter/material.dart';

enum ReportRangePreset { today, yesterday, week, month, custom }

enum ReportType {
  dailySales,
  sellerPurchase,
  buyerSales,
  mandiProfit,
  pendingPayment,
  customerLedger,
  paymentMode,
  topSellingProducts,
  chargesPerformance,
}

class ReportHelpers {
  static String presetLabel(ReportRangePreset preset) {
    switch (preset) {
      case ReportRangePreset.today:
        return 'Today';
      case ReportRangePreset.yesterday:
        return 'Yesterday';
      case ReportRangePreset.week:
        return 'This Week';
      case ReportRangePreset.month:
        return 'This Month';
      case ReportRangePreset.custom:
        return 'Custom';
    }
  }

  static String reportTypeLabel(ReportType type) {
    switch (type) {
      case ReportType.dailySales:
        return 'Daily Sales';
      case ReportType.sellerPurchase:
        return 'Seller Purchase';
      case ReportType.buyerSales:
        return 'Buyer Sales';
      case ReportType.mandiProfit:
        return 'Mandi Profit';
      case ReportType.pendingPayment:
        return 'Pending Payment';
      case ReportType.customerLedger:
        return 'Customer Ledger';
      case ReportType.paymentMode:
        return 'Payment Mode';
      case ReportType.topSellingProducts:
        return 'Top Selling Products';
      case ReportType.chargesPerformance:
        return 'Charges Performance';
    }
  }

  static IconData getReportIcon(ReportType type) {
    switch (type) {
      case ReportType.dailySales:
        return Icons.trending_up;
      case ReportType.sellerPurchase:
        return Icons.shopping_cart;
      case ReportType.buyerSales:
        return Icons.point_of_sale;
      case ReportType.mandiProfit:
        return Icons.account_balance;
      case ReportType.pendingPayment:
        return Icons.pending_actions;
      case ReportType.customerLedger:
        return Icons.account_balance_wallet;
      case ReportType.paymentMode:
        return Icons.payment;
      case ReportType.topSellingProducts:
        return Icons.star;
      case ReportType.chargesPerformance:
        return Icons.assessment;
    }
  }

  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
