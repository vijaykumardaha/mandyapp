class OrderItem {
  int? id;
  int? mandyId;
  int sellerId;
  int? buyerOrderId;
  int? sellerOrderId;
  int? buyerId;
  int productId;
  int variantId;
  double buyingPrice;
  double sellingPrice;
  double quantity;
  String unit;
  int? updatedAt;
  int? isDeleted;
  int? syncStatus;
  String? productName;
  String? imagePath;
  String? sellerName;
  String? buyerName;

  OrderItem({
    this.id,
    this.mandyId,
    required this.sellerId,
    this.buyerOrderId,
    this.sellerOrderId,
    this.buyerId,
    required this.productId,
    required this.variantId,
    this.buyingPrice = 0.0,
    required this.sellingPrice,
    required this.quantity,
    this.unit = 'Kg',
    this.updatedAt,
    this.isDeleted = 0,
    this.syncStatus = 0,
    this.productName,
    this.imagePath,
    this.sellerName,
    this.buyerName,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int?,
      mandyId: json['mandy_id'] as int?,
      sellerId: json['seller_id'] as int,
      buyerOrderId: json['buyer_order_id'] as int?,
      sellerOrderId: json['seller_order_id'] as int?,
      buyerId: json['buyer_id'] as int?,
      productId: json['product_id'] as int,
      variantId: json['variant_id'] as int,
      buyingPrice: (json['buying_price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['selling_price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'Kg',
      updatedAt: json['updated_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      isDeleted: json['is_deleted'] as int? ?? 0,
      syncStatus: json['sync_status'] as int? ?? 0,
      productName: json['product_name'] as String?,
      imagePath: json['image_path'] as String?,
      sellerName: json['seller_name'] as String?,
      buyerName: json['buyer_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mandy_id': mandyId,
      'seller_id': sellerId,
      'buyer_order_id': buyerOrderId,
      'seller_order_id': sellerOrderId,
      'buyer_id': buyerId,
      'product_id': productId,
      'variant_id': variantId,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
      'quantity': quantity,
      'unit': unit,
      'updated_at': updatedAt ?? DateTime.now().millisecondsSinceEpoch,
      'is_deleted': isDeleted ?? 0,
      'sync_status': syncStatus ?? 0,
      'product_name': productName,
      'image_path': imagePath,
      'seller_name': sellerName,
      'buyer_name': buyerName,
    };
  }

  OrderItem copyWith({
    int? id,
    int? mandyId,
    int? sellerId,
    int? buyerOrderId,
    int? sellerOrderId,
    int? buyerId,
    int? productId,
    int? variantId,
    double? buyingPrice,
    double? sellingPrice,
    double? quantity,
    String? unit,
    int? updatedAt,
    int? isDeleted,
    int? syncStatus,
    String? productName,
    String? imagePath,
    String? sellerName,
    String? buyerName,
  }) {
    return OrderItem(
      id: id ?? this.id,
      mandyId: mandyId ?? this.mandyId,
      sellerId: sellerId ?? this.sellerId,
      buyerOrderId: buyerOrderId ?? this.buyerOrderId,
      sellerOrderId: sellerOrderId ?? this.sellerOrderId,
      buyerId: buyerId ?? this.buyerId,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      buyingPrice: buyingPrice ?? this.buyingPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      productName: productName ?? this.productName,
      imagePath: imagePath ?? this.imagePath,
      sellerName: sellerName ?? this.sellerName,
      buyerName: buyerName ?? this.buyerName,
    );
  }

  @override
  String toString() {
    return 'OrderItem(id: $id, mandyId: $mandyId, sellerId: $sellerId, buyerOrderId: $buyerOrderId, sellerOrderId: $sellerOrderId, buyerId: $buyerId, productId: $productId, variantId: $variantId, buyingPrice: $buyingPrice, sellingPrice: $sellingPrice, quantity: $quantity, unit: $unit, updatedAt: $updatedAt, isDeleted: $isDeleted, syncStatus: $syncStatus, productName: $productName, imagePath: $imagePath, sellerName: $sellerName, buyerName: $buyerName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OrderItem &&
      other.id == id &&
      other.mandyId == mandyId &&
      other.sellerId == sellerId &&
      other.buyerOrderId == buyerOrderId &&
      other.sellerOrderId == sellerOrderId &&
      other.buyerId == buyerId &&
      other.productId == productId &&
      other.variantId == variantId &&
      other.buyingPrice == buyingPrice &&
      other.sellingPrice == sellingPrice &&
      other.quantity == quantity &&
      other.unit == unit &&
      other.updatedAt == updatedAt &&
      other.isDeleted == isDeleted &&
      other.syncStatus == syncStatus &&
      other.productName == productName &&
      other.imagePath == imagePath &&
      other.sellerName == sellerName &&
      other.buyerName == buyerName;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      mandyId,
      sellerId,
      buyerOrderId,
      sellerOrderId,
      buyerId,
      productId,
      variantId,
      buyingPrice,
      sellingPrice,
      quantity,
      unit,
      updatedAt,
      isDeleted,
      syncStatus,
      productName,
      imagePath,
      sellerName,
      buyerName,
    );
  }
}
