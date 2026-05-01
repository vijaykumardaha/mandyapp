class ProductVariant {
  int? id;
  int productId;
  String variantName;
  double buyingPrice;
  double sellingPrice;
  double quantity;
  String unit;
  String imagePath;

  ProductVariant({
    this.id,
    required this.productId,
    required this.variantName,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.quantity,
    required this.unit,
    required this.imagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'variant_name': variantName,
      'buying_price': buyingPrice,
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
      variantName: json['variant_name'] as String,
      buyingPrice: (json['buying_price'] as num).toDouble(),
      sellingPrice: (json['selling_price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      imagePath: json['image_path'] as String,
    );
  }

  double get profit => sellingPrice - buyingPrice;
  double get profitMargin => buyingPrice > 0 ? ((profit / buyingPrice) * 100) : 0;
}
