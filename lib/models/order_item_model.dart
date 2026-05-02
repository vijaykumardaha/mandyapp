class OrderItem {
  int? id;
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
  String createdAt;
  String updatedAt;
  // Variant details from product_variants table
  String? variantName;
  String? imagePath;

  OrderItem({
    this.id,
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
    required this.createdAt,
    required this.updatedAt,
    this.variantName,
    this.imagePath,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int?,
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
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      variantName: json['variant_name'] as String?,
      imagePath: json['image_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'created_at': createdAt,
      'updated_at': updatedAt,
      // Note: variantName and imagePath are read-only fields from product_variants table
      // They are not stored in the order_items table
    };
  }

  OrderItem copyWith({
    int? id,
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
    String? createdAt,
    String? updatedAt,
    String? variantName,
    String? imagePath,
  }) {
    return OrderItem(
      id: id ?? this.id,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      variantName: variantName ?? this.variantName,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  @override
  String toString() {
    return 'OrderItem(id: $id, sellerId: $sellerId, buyerOrderId: $buyerOrderId, sellerOrderId: $sellerOrderId, buyerId: $buyerId, productId: $productId, variantId: $variantId, buyingPrice: $buyingPrice, sellingPrice: $sellingPrice, quantity: $quantity, unit: $unit, createdAt: $createdAt, updatedAt: $updatedAt, variantName: $variantName, imagePath: $imagePath)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OrderItem &&
      other.id == id &&
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
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.variantName == variantName &&
      other.imagePath == imagePath;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      sellerId.hashCode ^
      buyerOrderId.hashCode ^
      sellerOrderId.hashCode ^
      buyerId.hashCode ^
      productId.hashCode ^
      variantId.hashCode ^
      buyingPrice.hashCode ^
      sellingPrice.hashCode ^
      quantity.hashCode ^
      unit.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      variantName.hashCode ^
      imagePath.hashCode;
  }
}
