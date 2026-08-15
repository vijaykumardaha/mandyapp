import 'package:flutter/material.dart';

enum ReportRangePreset { today, yesterday, week, month, custom }

enum ReportType {
  dailySales,
  dailyPurchase,
  mandiProfit,
  pendingPayment,
  customerLedger,
  stockTransaction,
  stockSummary,
  expenses,
  mandiTransaction,
  balanceSheet,
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
      case ReportType.dailyPurchase:
        return 'Daily Purchase';
      case ReportType.mandiProfit:
        return 'Mandi Profit';
      case ReportType.pendingPayment:
        return 'Pending Payment';
      case ReportType.customerLedger:
        return 'Customer Ledger';
      case ReportType.stockTransaction:
        return 'Stock Transaction';
      case ReportType.stockSummary:
        return 'Stock Summary';
      case ReportType.expenses:
        return 'Expenses';
      case ReportType.mandiTransaction:
        return 'Mandi Transaction';
      case ReportType.balanceSheet:
        return 'Balance Sheet';
    }
  }

  static IconData getReportIcon(ReportType type) {
    switch (type) {
      case ReportType.dailySales:
        return Icons.trending_up;
      case ReportType.dailyPurchase:
        return Icons.shopping_cart;
      case ReportType.mandiProfit:
        return Icons.account_balance;
      case ReportType.pendingPayment:
        return Icons.pending_actions;
      case ReportType.customerLedger:
        return Icons.account_balance_wallet;
      case ReportType.stockTransaction:
        return Icons.receipt_long;
      case ReportType.stockSummary:
        return Icons.inventory_2;
      case ReportType.expenses:
        return Icons.trending_down;
      case ReportType.mandiTransaction:
        return Icons.swap_horiz;
      case ReportType.balanceSheet:
        return Icons.menu_book;
    }
  }

  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
