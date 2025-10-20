class ProductStock {
  int? id;
  int customerId;
  String productId;
  String variantId;
  double initialStock;
  double currentStock;
  String unit;
  String lastUpdated;
  String createdAt;

  ProductStock({
    this.id,
    required this.customerId,
    required this.productId,
    required this.variantId,
    this.initialStock = 0.0,
    required this.currentStock,
    this.unit = 'Kg',
    required this.lastUpdated,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'product_id': productId,
      'variant_id': variantId,
      'initial_stock': initialStock,
      'current_stock': currentStock,
      'unit': unit,
      'last_updated': lastUpdated,
      'created_at': createdAt,
    };
  }

  factory ProductStock.fromJson(Map<String, dynamic> json) {
    return ProductStock(
      id: json['id'] as int?,
      customerId: json['customer_id'] as int,
      productId: json['product_id'] as String,
      variantId: json['variant_id'] as String,
      initialStock: (json['initial_stock'] as num?)?.toDouble() ?? 0.0,
      currentStock: (json['current_stock'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'Kg',
      lastUpdated: json['last_updated'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  ProductStock copyWith({
    int? id,
    int? customerId,
    String? productId,
    String? variantId,
    double? initialStock,
    double? currentStock,
    String? unit,
    String? lastUpdated,
    String? createdAt,
  }) {
    return ProductStock(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      initialStock: initialStock ?? this.initialStock,
      currentStock: currentStock ?? this.currentStock,
      unit: unit ?? this.unit,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
