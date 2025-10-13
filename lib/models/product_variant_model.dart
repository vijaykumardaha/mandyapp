class ProductVariant {
  int? id;
  int productId;
  String? variantName;
  double costPrice;
  double sellingPrice;
  double quantity;
  String unit;
  String? imagePath;

  ProductVariant({
    this.id,
    required this.productId,
    this.variantName,
    this.costPrice = 0.0,
    required this.sellingPrice,
    required this.quantity,
    this.unit = 'Kg',
    this.imagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'variant_name': variantName,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'quantity': quantity,
      'unit': unit,
      'image_path': imagePath,
    };
  }

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as int?,
      productId: json['product_id'] as int,
      variantName: json['variant_name'] as String?,
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['selling_price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'Kg',
      imagePath: json['image_path'] as String?,
    );
  }

  double get profit => sellingPrice - costPrice;
  double get profitMargin => costPrice > 0 ? ((profit / costPrice) * 100) : 0;
}
