class ItemSale {
  int? id;
  int sellerId;
  int? buyerCartId;
  int? sellerCartId;
  int? buyerId;
  int productId;
  int variantId;
  int? stockId;
  double buyingPrice;
  double sellingPrice;
  double quantity;
  String unit;
  String createdAt;
  String updatedAt;

  ItemSale({
    this.id,
    required this.sellerId,
    this.buyerCartId,
    this.sellerCartId,
    this.buyerId,
    required this.productId,
    required this.variantId,
    this.stockId,
    this.buyingPrice = 0.0,
    required this.sellingPrice,
    required this.quantity,
    this.unit = 'Kg',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'buyer_cart_id': buyerCartId,
      'seller_cart_id': sellerCartId,
      'buyer_id': buyerId,
      'product_id': productId,
      'variant_id': variantId,
      'stock_id': stockId,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
      'quantity': quantity,
      'unit': unit,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory ItemSale.fromJson(Map<String, dynamic> json) {
    return ItemSale(
      id: json['id'] as int?,
      sellerId: json['seller_id'] as int,
      buyerCartId: json['buyer_cart_id'] as int?,
      sellerCartId: json['seller_cart_id'] as int?,
      buyerId: json['buyer_id'] as int?,
      productId: json['product_id'] as int,
      variantId: json['variant_id'] as int,
      stockId: json['stock_id'] as int?,
      buyingPrice: (json['buying_price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['selling_price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'Kg',
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  ItemSale copyWith({
    int? id,
    int? sellerId,
    int? buyerCartId,
    int? sellerCartId,
    int? buyerId,
    int? productId,
    int? variantId,
    int? stockId,
    double? buyingPrice,
    double? sellingPrice,
    double? quantity,
    String? unit,
    String? createdAt,
    String? updatedAt,
  }) {
    return ItemSale(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      buyerCartId: buyerCartId ?? this.buyerCartId,
      sellerCartId: sellerCartId ?? this.sellerCartId,
      buyerId: buyerId ?? this.buyerId,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      stockId: stockId ?? this.stockId,
      buyingPrice: buyingPrice ?? this.buyingPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get totalPrice => sellingPrice * quantity;
}
