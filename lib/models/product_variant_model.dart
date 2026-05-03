class ProductVariant {
  int? id;
  int? mandyId;
  int productId;
  String variantName;
  double buyingPrice;
  double sellingPrice;
  double quantity;
  String unit;
  String imagePath;
  int? updatedAt;
  int? isDeleted;
  int? syncStatus;

  ProductVariant({
    this.id,
    this.mandyId,
    required this.productId,
    required this.variantName,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.quantity,
    required this.unit,
    required this.imagePath,
    this.updatedAt,
    this.isDeleted = 0,
    this.syncStatus = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mandy_id': mandyId,
      'product_id': productId,
      'variant_name': variantName,
      'buying_price': buyingPrice,
      'selling_price': sellingPrice,
      'quantity': quantity,
      'unit': unit,
      'image_path': imagePath,
      'updated_at': updatedAt ?? DateTime.now().millisecondsSinceEpoch,
      'is_deleted': isDeleted ?? 0,
      'sync_status': syncStatus ?? 0,
    };
  }

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as int?,
      mandyId: json['mandy_id'] as int?,
      productId: json['product_id'] as int,
      variantName: json['variant_name'] as String,
      buyingPrice: (json['buying_price'] as num).toDouble(),
      sellingPrice: (json['selling_price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      imagePath: json['image_path'] as String,
      updatedAt: json['updated_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      isDeleted: json['is_deleted'] as int? ?? 0,
      syncStatus: json['sync_status'] as int? ?? 0,
    );
  }

  double get profit => sellingPrice - buyingPrice;
  double get profitMargin => buyingPrice > 0 ? ((profit / buyingPrice) * 100) : 0;
}
