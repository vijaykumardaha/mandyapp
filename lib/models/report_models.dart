class DailySalesData {
  final String date;
  final int productId;
  final int variantId;
  final String productName;
  final String unit;
  final int? sellerId;
  final String? sellerName;
  final double totalQuantity;
  final int transactionCount;
  final double totalRevenue;
  final double avgPrice;

  const DailySalesData({
    required this.date,
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.unit,
    required this.sellerId,
    required this.sellerName,
    required this.totalQuantity,
    required this.transactionCount,
    required this.totalRevenue,
    required this.avgPrice,
  });

  factory DailySalesData.fromJson(Map<String, dynamic> json) {
    return DailySalesData(
      date: json['date'] as String,
      productId: json['product_id'] as int,
      variantId: json['variant_id'] as int,
      productName:
          json['variant_name'] as String? ?? 'Product ${json['product_id']}',
      unit: json['unit'] as String? ?? 'units',
      sellerId: json['seller_id'] as int?,
      sellerName: json['seller_name'] as String?,
      totalQuantity: (json['total_quantity'] as num?)?.toDouble() ?? 0.0,
      transactionCount: json['transaction_count'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      avgPrice: (json['avg_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'product_id': productId,
      'variant_id': variantId,
      'product_name': productName,
      'unit': unit,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'total_quantity': totalQuantity,
      'transaction_count': transactionCount,
      'total_revenue': totalRevenue,
      'avg_price': avgPrice,
    };
  }
}

class DailyPurchaseData {
  final String date;
  final int productId;
  final int variantId;
  final String productName;
  final String unit;
  final int? sellerId;
  final String? sellerName;
  final double totalQuantity;
  final int transactionCount;
  final double totalCost;
  final double avgPrice;

  const DailyPurchaseData({
    required this.date,
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.unit,
    required this.sellerId,
    required this.sellerName,
    required this.totalQuantity,
    required this.transactionCount,
    required this.totalCost,
    required this.avgPrice,
  });

  factory DailyPurchaseData.fromJson(Map<String, dynamic> json) {
    return DailyPurchaseData(
      date: json['date'] as String,
      productId: json['product_id'] as int,
      variantId: json['variant_id'] as int,
      productName:
          json['variant_name'] as String? ?? 'Product ${json['product_id']}',
      unit: json['unit'] as String? ?? 'units',
      sellerId: json['seller_id'] as int?,
      sellerName: json['seller_name'] as String?,
      totalQuantity: (json['total_quantity'] as num?)?.toDouble() ?? 0.0,
      transactionCount: json['transaction_count'] as int? ?? 0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0.0,
      avgPrice: (json['avg_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MandiProfitData {
  final String date;
  final double dailyProfit;
  final double dailyRevenue;
  final double dailyCost;
  final int transactions;
  final double avgTransactionProfit;

  const MandiProfitData({
    required this.date,
    required this.dailyProfit,
    required this.dailyRevenue,
    required this.dailyCost,
    required this.transactions,
    required this.avgTransactionProfit,
  });

  factory MandiProfitData.fromJson(Map<String, dynamic> json) {
    return MandiProfitData(
      date: json['date'] as String,
      dailyProfit: (json['daily_profit'] as num?)?.toDouble() ?? 0.0,
      dailyRevenue: (json['daily_revenue'] as num?)?.toDouble() ?? 0.0,
      dailyCost: (json['daily_cost'] as num?)?.toDouble() ?? 0.0,
      transactions: json['transactions'] as int? ?? 0,
      avgTransactionProfit:
          (json['avg_transaction_profit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CustomerLedgerData {
  final int customerId;
  final String customerName;
  final String customerPhone;
  final int totalTransactions;
  final double totalPaid;
  final double totalReceived;
  final double netBalance;

  const CustomerLedgerData({
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.totalTransactions,
    required this.totalPaid,
    required this.totalReceived,
    required this.netBalance,
  });

  factory CustomerLedgerData.fromJson(Map<String, dynamic> json) {
    return CustomerLedgerData(
      customerId: json['customer_id'] as int,
      customerName: json['customer_name'] as String? ?? 'Unknown Customer',
      customerPhone: json['customer_phone'] as String? ?? '',
      totalTransactions: json['total_transactions'] as int? ?? 0,
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0.0,
      totalReceived: (json['total_received'] as num?)?.toDouble() ?? 0.0,
      netBalance: (json['net_balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PendingPaymentData {
  final String customerName;
  final String customerPhone;
  final int customerId;
  final int? billingId;
  final String? billingType;
  final int totalBills;
  final double totalAmount;
  final double paidAmount;
  final double pendingAmount;
  final String oldestBillDate;
  final String latestBillDate;
  final int daysPending;

  const PendingPaymentData({
    required this.customerName,
    required this.customerPhone,
    required this.customerId,
    required this.billingId,
    required this.billingType,
    required this.totalBills,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.oldestBillDate,
    required this.latestBillDate,
    required this.daysPending,
  });

  factory PendingPaymentData.fromJson(Map<String, dynamic> json) {
    final oldestDate =
        DateTime.tryParse(json['oldest_bill_date'] as String? ?? '') ??
            DateTime.now();
    final latestDate =
        DateTime.tryParse(json['latest_bill_date'] as String? ?? '') ??
            DateTime.now();
    final daysPending = latestDate.difference(oldestDate).inDays.abs();

    return PendingPaymentData(
      customerName: json['customer_name'] as String? ?? 'Unknown Customer',
      customerPhone: json['customer_phone'] as String? ?? '',
      customerId: json['customer_id'] as int,
      billingId: json['billing_id'] as int?,
      billingType: json['billing_type'] as String?,
      totalBills: json['total_bills'] as int? ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      pendingAmount: (json['pending_amount'] as num?)?.toDouble() ?? 0.0,
      oldestBillDate: json['oldest_bill_date'] as String? ?? '',
      latestBillDate: json['latest_bill_date'] as String? ?? '',
      daysPending: daysPending,
    );
  }
}

class ReportsSummaryData {
  final int totalDays;
  final int totalTransactions;
  final double totalRevenue;
  final double totalCost;
  final double totalProfit;
  final int uniqueProducts;
  final int uniqueBuyers;
  final int uniqueSellers;
  final double avgTransactionValue;

  const ReportsSummaryData({
    required this.totalDays,
    required this.totalTransactions,
    required this.totalRevenue,
    required this.totalCost,
    required this.totalProfit,
    required this.uniqueProducts,
    required this.uniqueBuyers,
    required this.uniqueSellers,
    required this.avgTransactionValue,
  });

  factory ReportsSummaryData.fromJson(Map<String, dynamic> json) {
    return ReportsSummaryData(
      totalDays: json['total_days'] as int? ?? 0,
      totalTransactions: json['total_transactions'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (json['total_profit'] as num?)?.toDouble() ?? 0.0,
      uniqueProducts: json['unique_products'] as int? ?? 0,
      uniqueBuyers: json['unique_buyers'] as int? ?? 0,
      uniqueSellers: json['unique_sellers'] as int? ?? 0,
      avgTransactionValue:
          (json['avg_transaction_value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  double get profitMargin =>
      totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0.0;
}

class StockTransactionReportData {
  final String date;
  final int stockId;
  final int productId;
  final int? productVariantId;
  final String productName;
  final String? variantName;
  final String? unit;
  final int buyerId;
  final String buyerName;
  final double buyQuantity;
  final double totalAmount;
  final double avgPrice;

  const StockTransactionReportData({
    required this.date,
    required this.stockId,
    required this.productId,
    this.productVariantId,
    required this.productName,
    this.variantName,
    this.unit,
    required this.buyerId,
    required this.buyerName,
    required this.buyQuantity,
    required this.totalAmount,
    required this.avgPrice,
  });

  factory StockTransactionReportData.fromJson(Map<String, dynamic> json) {
    return StockTransactionReportData(
      date: json['date'] as String,
      stockId: json['stock_id'] as int,
      productId: json['product_id'] as int,
      productVariantId: json['product_variant_id'] as int?,
      productName:
          json['product_name'] as String? ?? 'Product ${json['product_id']}',
      variantName: json['variant_name'] as String?,
      unit: json['unit'] as String?,
      buyerId: json['buyer_id'] as int,
      buyerName: json['buyer_name'] as String? ?? 'Unknown',
      buyQuantity: (json['buy_quantity'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      avgPrice: (json['avg_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class StockSummaryData {
  final int stockId;
  final int productId;
  final int? productVariantId;
  final String productName;
  final String? variantName;
  final String? unit;
  final double initialQuantity;
  final double quantity;
  final double soldQuantity;
  final double lossQuantity;
  final double purchaseAmount;
  final double soldAmount;
  final double remainingValue;
  final double profit;

  const StockSummaryData({
    required this.stockId,
    required this.productId,
    this.productVariantId,
    required this.productName,
    this.variantName,
    this.unit,
    required this.initialQuantity,
    required this.quantity,
    required this.soldQuantity,
    required this.lossQuantity,
    required this.purchaseAmount,
    required this.soldAmount,
    required this.remainingValue,
    required this.profit,
  });

  factory StockSummaryData.fromJson(Map<String, dynamic> json) {
    final soldQty = (json['sold_quantity'] as num?)?.toDouble() ?? 0.0;
    final initialQty = (json['initial_quantity'] as num?)?.toDouble() ?? 0.0;
    final purchaseAmt = (json['purchase_amount'] as num?)?.toDouble() ?? 0.0;
    final soldAmt = (json['sold_amount'] as num?)?.toDouble() ?? 0.0;
    final remainingQty = initialQty - soldQty;
    final costPerUnit = initialQty > 0 ? purchaseAmt / initialQty : 0.0;

    return StockSummaryData(
      stockId: json['stock_id'] as int,
      productId: json['product_id'] as int,
      productVariantId: json['product_variant_id'] as int?,
      productName:
          json['product_name'] as String? ?? 'Product ${json['product_id']}',
      variantName: json['variant_name'] as String?,
      unit: json['unit'] as String?,
      initialQuantity: initialQty,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      soldQuantity: soldQty,
      lossQuantity: (json['loss_quantity'] as num?)?.toDouble() ?? 0.0,
      purchaseAmount: purchaseAmt,
      soldAmount: soldAmt,
      remainingValue: remainingQty * costPerUnit,
      profit: soldAmt - (soldQty * costPerUnit),
    );
  }
}

class ExpensesReportData {
  final String date;
  final int? orderId;
  final String expenseName;
  final double totalAmount;

  const ExpensesReportData({
    required this.date,
    required this.orderId,
    required this.expenseName,
    required this.totalAmount,
  });

  factory ExpensesReportData.fromJson(Map<String, dynamic> json) {
    return ExpensesReportData(
      date: json['date'] as String,
      orderId: (json['order_id'] as num?)?.toInt(),
      expenseName: json['expense_name'] as String? ?? 'General Expense',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
