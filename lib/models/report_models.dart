class DailySalesData {
  final String date;
  final int productId;
  final int variantId;
  final String productName;
  final String unit;
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
      productName: json['variant_name'] as String? ?? 'Product ${json['product_id']}',
      unit: json['unit'] as String? ?? 'units',
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
      'total_quantity': totalQuantity,
      'transaction_count': transactionCount,
      'total_revenue': totalRevenue,
      'avg_price': avgPrice,
    };
  }
}

class SellerPurchaseData {
  final String sellerName;
  final String sellerPhone;
  final int totalPurchases;
  final double totalCost;
  final double totalQuantity;
  final double avgBuyingPrice;

  const SellerPurchaseData({
    required this.sellerName,
    required this.sellerPhone,
    required this.totalPurchases,
    required this.totalCost,
    required this.totalQuantity,
    required this.avgBuyingPrice,
  });

  factory SellerPurchaseData.fromJson(Map<String, dynamic> json) {
    return SellerPurchaseData(
      sellerName: json['seller_name'] as String? ?? 'Unknown Seller',
      sellerPhone: json['seller_phone'] as String? ?? '',
      totalPurchases: json['total_purchases'] as int? ?? 0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0.0,
      totalQuantity: (json['total_quantity'] as num?)?.toDouble() ?? 0.0,
      avgBuyingPrice: (json['avg_buying_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class BuyerSalesData {
  final String buyerName;
  final String buyerPhone;
  final int totalBills;
  final double totalRevenue;
  final double totalQuantity;
  final double avgSellingPrice;

  const BuyerSalesData({
    required this.buyerName,
    required this.buyerPhone,
    required this.totalBills,
    required this.totalRevenue,
    required this.totalQuantity,
    required this.avgSellingPrice,
  });

  factory BuyerSalesData.fromJson(Map<String, dynamic> json) {
    return BuyerSalesData(
      buyerName: json['buyer_name'] as String? ?? 'Unknown Buyer',
      buyerPhone: json['buyer_phone'] as String? ?? '',
      totalBills: json['total_bills'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalQuantity: (json['total_quantity'] as num?)?.toDouble() ?? 0.0,
      avgSellingPrice: (json['avg_selling_price'] as num?)?.toDouble() ?? 0.0,
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
      avgTransactionProfit: (json['avg_transaction_profit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CustomerLedgerData {
  final int customerId;
  final String customerName;
  final String customerPhone;
  final int totalTransactions;
  final double totalPurchases;
  final double totalSales;
  final double netBalance;

  const CustomerLedgerData({
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.totalTransactions,
    required this.totalPurchases,
    required this.totalSales,
    required this.netBalance,
  });

  factory CustomerLedgerData.fromJson(Map<String, dynamic> json) {
    return CustomerLedgerData(
      customerId: json['customer_id'] as int,
      customerName: json['customer_name'] as String? ?? 'Unknown Customer',
      customerPhone: json['customer_phone'] as String? ?? '',
      totalTransactions: json['total_transactions'] as int? ?? 0,
      totalPurchases: (json['total_purchases'] as num?)?.toDouble() ?? 0.0,
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
      netBalance: (json['net_balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PendingPaymentData {
  final String customerName;
  final String customerPhone;
  final int customerId;
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
    required this.totalBills,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.oldestBillDate,
    required this.latestBillDate,
    required this.daysPending,
  });

  factory PendingPaymentData.fromJson(Map<String, dynamic> json) {
    final oldestDate = DateTime.tryParse(json['oldest_bill_date'] as String? ?? '') ?? DateTime.now();
    final latestDate = DateTime.tryParse(json['latest_bill_date'] as String? ?? '') ?? DateTime.now();
    final daysPending = latestDate.difference(oldestDate).inDays.abs();

    return PendingPaymentData(
      customerName: json['customer_name'] as String? ?? 'Unknown Customer',
      customerPhone: json['customer_phone'] as String? ?? '',
      customerId: json['customer_id'] as int,
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

class PaymentModeData {
  final String paymentMethod;
  final int transactionCount;
  final double totalAmount;
  final double avgTransaction;
  final String firstPaymentDate;
  final String lastPaymentDate;

  const PaymentModeData({
    required this.paymentMethod,
    required this.transactionCount,
    required this.totalAmount,
    required this.avgTransaction,
    required this.firstPaymentDate,
    required this.lastPaymentDate,
  });

  factory PaymentModeData.fromJson(Map<String, dynamic> json) {
    return PaymentModeData(
      paymentMethod: json['payment_method'] as String? ?? 'Unknown',
      transactionCount: json['transaction_count'] as int? ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      avgTransaction: (json['avg_transaction'] as num?)?.toDouble() ?? 0.0,
      firstPaymentDate: json['first_payment_date'] as String? ?? '',
      lastPaymentDate: json['last_payment_date'] as String? ?? '',
    );
  }
}

class StockMovementData {
  final int productId;
  final String productName;
  final String unit;
  final double stockIn;
  final double stockOut;
  final double netStockChange;
  final int salesTransactions;
  final int purchaseTransactions;

  const StockMovementData({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.stockIn,
    required this.stockOut,
    required this.netStockChange,
    required this.salesTransactions,
    required this.purchaseTransactions,
  });

  factory StockMovementData.fromJson(Map<String, dynamic> json) {
    return StockMovementData(
      productId: json['product_id'] as int,
      productName: json['variant_name'] as String? ?? 'Product ${json['product_id']}',
      unit: json['unit'] as String? ?? 'units',
      stockIn: (json['quantity_purchased'] as num?)?.toDouble() ?? 0.0,
      stockOut: (json['quantity_sold'] as num?)?.toDouble() ?? 0.0,
      netStockChange: (json['net_stock_change'] as num?)?.toDouble() ?? 0.0,
      salesTransactions: json['sales_transactions'] as int? ?? 0,
      purchaseTransactions: json['purchase_transactions'] as int? ?? 0,
    );
  }
}

class TopSellingProductData {
  final int productId;
  final int variantId;
  final String productName;
  final String unit;
  final double totalQuantitySold;
  final double totalRevenue;
  final int transactionCount;
  final double avgSellingPrice;
  final String lastSoldDate;
  final int revenueRank;
  final int quantityRank;

  const TopSellingProductData({
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.unit,
    required this.totalQuantitySold,
    required this.totalRevenue,
    required this.transactionCount,
    required this.avgSellingPrice,
    required this.lastSoldDate,
    required this.revenueRank,
    required this.quantityRank,
  });

  factory TopSellingProductData.fromJson(Map<String, dynamic> json) {
    return TopSellingProductData(
      productId: json['product_id'] as int,
      variantId: json['variant_id'] as int,
      productName: json['variant_name'] as String? ?? 'Product ${json['product_id']}',
      unit: json['unit'] as String? ?? 'units',
      totalQuantitySold: (json['total_quantity_sold'] as num?)?.toDouble() ?? 0.0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      transactionCount: json['transaction_count'] as int? ?? 0,
      avgSellingPrice: (json['avg_selling_price'] as num?)?.toDouble() ?? 0.0,
      lastSoldDate: json['last_sold_date'] as String? ?? '',
      revenueRank: json['revenue_rank'] as int? ?? 0,
      quantityRank: json['quantity_rank'] as int? ?? 0,
    );
  }
}

class ChargesPerformanceData {
  final String chargeType;
  final int transactionCount;
  final double totalChargeAmount;
  final double avgChargeAmount;
  final int uniqueCarts;
  final double avgChargePerCart;

  const ChargesPerformanceData({
    required this.chargeType,
    required this.transactionCount,
    required this.totalChargeAmount,
    required this.avgChargeAmount,
    required this.uniqueCarts,
    required this.avgChargePerCart,
  });

  factory ChargesPerformanceData.fromJson(Map<String, dynamic> json) {
    return ChargesPerformanceData(
      chargeType: json['charge_name'] as String? ?? 'Unknown Charge',
      transactionCount: json['times_applied'] as int? ?? 0,
      totalChargeAmount: (json['total_charge_amount'] as num?)?.toDouble() ?? 0.0,
      avgChargeAmount: (json['avg_charge_amount'] as num?)?.toDouble() ?? 0.0,
      uniqueCarts: json['unique_carts'] as int? ?? 0,
      avgChargePerCart: (json['avg_charge_per_cart'] as num?)?.toDouble() ?? 0.0,
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
      avgTransactionValue: (json['avg_transaction_value'] as num?)?.toDouble() ?? 0.0,
    );
  }

  double get profitMargin => totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0.0;
}
