class ProductVariant {
  int? id;
  int productId;
  String variantName;
  double buyingPrice;
  double sellingPrice;
  double quantity;
  String unit;
  String imagePath;
  bool manageStock;

  ProductVariant({
    this.id,
    required this.productId,
    required this.variantName,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.quantity,
    required this.unit,
    required this.imagePath,
    this.manageStock = true,
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
      'manage_stock': manageStock ? 1 : 0,
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
      manageStock: (json['manage_stock'] as int? ?? 1) == 1,
    );
  }

  double get profit => sellingPrice - buyingPrice;
  double get profitMargin => buyingPrice > 0 ? ((profit / buyingPrice) * 100) : 0;
}
