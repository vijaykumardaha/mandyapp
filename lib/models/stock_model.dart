class Stock {
  int? id;
  int? mandiId;
  int sellerId;
  int productId;
  int productVariantId;
  double initialQuantity;
  double quantity;
  double soldQuantity;
  double lossQuantity;
  double purchaseAmount;
  double soldAmount;
  int? updatedAt;
  int syncStatus;
  int isDeleted;

  Stock({
    this.id,
    this.mandiId,
    required this.sellerId,
    required this.productId,
    required this.productVariantId,
    required this.initialQuantity,
    required this.quantity,
    this.soldQuantity = 0,
    this.lossQuantity = 0,
    required this.purchaseAmount,
    this.soldAmount = 0,
    this.updatedAt,
    this.syncStatus = 0,
    this.isDeleted = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mandi_id': mandiId,
      'seller_id': sellerId,
      'product_id': productId,
      'product_variant_id': productVariantId,
      'initial_quantity': initialQuantity,
      'quantity': quantity,
      'sold_quantity': soldQuantity,
      'loss_quantity': lossQuantity,
      'purchase_amount': purchaseAmount,
      'sold_amount': soldAmount,
      'updated_at': updatedAt ?? DateTime.now().millisecondsSinceEpoch,
      'sync_status': syncStatus,
      'is_deleted': isDeleted,
    };
  }

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      id: json['id'] as int?,
      mandiId: json['mandi_id'] as int?,
      sellerId: json['seller_id'] as int,
      productId: json['product_id'] as int,
      productVariantId: json['product_variant_id'] as int,
      initialQuantity: (json['initial_quantity'] as num).toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
      soldQuantity: (json['sold_quantity'] as num?)?.toDouble() ?? 0,
      lossQuantity: (json['loss_quantity'] as num?)?.toDouble() ?? 0,
      purchaseAmount: (json['purchase_amount'] as num).toDouble(),
      soldAmount: (json['sold_amount'] as num?)?.toDouble() ?? 0,
      updatedAt: json['updated_at'] as int?,
      syncStatus: json['sync_status'] as int? ?? 0,
      isDeleted: json['is_deleted'] as int? ?? 0,
    );
  }

  Stock copyWith({
    int? id,
    int? mandiId,
    int? sellerId,
    int? productId,
    int? productVariantId,
    double? initialQuantity,
    double? quantity,
    double? soldQuantity,
    double? lossQuantity,
    double? purchaseAmount,
    double? soldAmount,
    int? updatedAt,
    int? syncStatus,
    int? isDeleted,
  }) {
    return Stock(
      id: id ?? this.id,
      mandiId: mandiId ?? this.mandiId,
      sellerId: sellerId ?? this.sellerId,
      productId: productId ?? this.productId,
      productVariantId: productVariantId ?? this.productVariantId,
      initialQuantity: initialQuantity ?? this.initialQuantity,
      quantity: quantity ?? this.quantity,
      soldQuantity: soldQuantity ?? this.soldQuantity,
      lossQuantity: lossQuantity ?? this.lossQuantity,
      purchaseAmount: purchaseAmount ?? this.purchaseAmount,
      soldAmount: soldAmount ?? this.soldAmount,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

class StockTransaction {
  int? id;
  int stockId;
  int? mandiId;
  int productId;
  int productVariantId;
  int buyerId;
  int? billId;
  double buyQuantity;
  double totalAmount;
  int? updatedAt;
  int syncStatus;
  int isDeleted;

  StockTransaction({
    this.id,
    required this.stockId,
    this.mandiId,
    required this.productId,
    required this.productVariantId,
    required this.buyerId,
    this.billId,
    required this.buyQuantity,
    required this.totalAmount,
    this.updatedAt,
    this.syncStatus = 0,
    this.isDeleted = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stock_id': stockId,
      'mandi_id': mandiId,
      'product_id': productId,
      'product_variant_id': productVariantId,
      'buyer_id': buyerId,
      'bill_id': billId,
      'buy_quantity': buyQuantity,
      'total_amount': totalAmount,
      'updated_at': updatedAt ?? DateTime.now().millisecondsSinceEpoch,
      'sync_status': syncStatus,
      'is_deleted': isDeleted,
    };
  }

  factory StockTransaction.fromJson(Map<String, dynamic> json) {
    return StockTransaction(
      id: json['id'] as int?,
      stockId: json['stock_id'] as int,
      mandiId: json['mandi_id'] as int?,
      productId: json['product_id'] as int,
      productVariantId: json['product_variant_id'] as int,
      buyerId: json['buyer_id'] as int,
      billId: json['bill_id'] as int?,
      buyQuantity: (json['buy_quantity'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      updatedAt: json['updated_at'] as int?,
      syncStatus: json['sync_status'] as int? ?? 0,
      isDeleted: json['is_deleted'] as int? ?? 0,
    );
  }

  StockTransaction copyWith({
    int? id,
    int? stockId,
    int? mandiId,
    int? productId,
    int? productVariantId,
    int? buyerId,
    int? billId,
    double? buyQuantity,
    double? totalAmount,
    int? updatedAt,
    int? syncStatus,
    int? isDeleted,
  }) {
    return StockTransaction(
      id: id ?? this.id,
      stockId: stockId ?? this.stockId,
      mandiId: mandiId ?? this.mandiId,
      productId: productId ?? this.productId,
      productVariantId: productVariantId ?? this.productVariantId,
      buyerId: buyerId ?? this.buyerId,
      billId: billId ?? this.billId,
      buyQuantity: buyQuantity ?? this.buyQuantity,
      totalAmount: totalAmount ?? this.totalAmount,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
