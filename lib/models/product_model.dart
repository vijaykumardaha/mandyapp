import 'package:mandyapp/models/product_variant_model.dart';

class Product {
  int? id;
  String name;
  int categoryId;
  String? imagePath;
  List<ProductVariant>? variants;

  Product({
    this.id,
    required this.name,
    required this.categoryId,
    this.imagePath,
    this.variants,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_id': categoryId,
      'image_path': imagePath,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json, {List<ProductVariant>? variants}) {
    return Product(
      id: json['id'] as int?,
      name: json['name'] as String,
      categoryId: json['category_id'] as int,
      imagePath: json['image_path'] as String?,
      variants: variants,
    );
  }

  int get variantCount => variants?.length ?? 0;
  bool get hasVariants => variants != null && variants!.isNotEmpty;
}
