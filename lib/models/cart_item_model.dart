class CartItem {
  int? id;
  int cartId;
  int productId;
  int variantId;
  double quantity;
  double unitPrice;
  double totalPrice;

  CartItem({
    this.id,
    required this.cartId,
    required this.productId,
    required this.variantId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  // Convert CartItem to Map for database insertion
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cart_id': cartId,
      'product_id': productId,
      'variant_id': variantId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }

  // Create CartItem from Map (database query result)
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int?,
      cartId: json['cart_id'] as int,
      productId: json['product_id'] as int,
      variantId: json['variant_id'] as int,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
    );
  }

  // Create a copy of CartItem with updated fields
  CartItem copyWith({
    int? id,
    int? cartId,
    int? productId,
    int? variantId,
    double? quantity,
    double? unitPrice,
    double? totalPrice,
  }) {
    return CartItem(
      id: id ?? this.id,
      cartId: cartId ?? this.cartId,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  // Calculate total price based on quantity and unit price
  static double calculateTotalPrice(double quantity, double unitPrice) {
    return quantity * unitPrice;
  }

  // Check if item is for a variant (always true now since both are required)
  bool get isVariant => true;

  @override
  String toString() {
    return 'CartItem{id: $id, cartId: $cartId, productId: $productId, variantId: $variantId, quantity: $quantity, unitPrice: $unitPrice, totalPrice: $totalPrice}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.id == id &&
        other.cartId == cartId &&
        other.productId == productId &&
        other.variantId == variantId &&
        other.quantity == quantity &&
        other.unitPrice == unitPrice &&
        other.totalPrice == totalPrice;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        cartId.hashCode ^
        productId.hashCode ^
        variantId.hashCode ^
        quantity.hashCode ^
        unitPrice.hashCode ^
        totalPrice.hashCode;
  }
}
