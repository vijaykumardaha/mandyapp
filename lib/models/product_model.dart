import 'package:mandyapp/models/product_variant_model.dart';

class Product {
  int? id;
  int categoryId;
  int defaultVariant;
  List<ProductVariant>? variants;

  Product({
    this.id,
    required this.categoryId,
    required this.defaultVariant,
    this.variants,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'default_variant': defaultVariant,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json, {List<ProductVariant>? variants}) {
    return Product(
      id: json['id'] as int?,
      categoryId: json['category_id'] as int,
      defaultVariant: (json['default_variant'] as int?) ?? 0,
      variants: variants,
    );
  }

  ProductVariant? get defaultVariantModel {
    if (variants == null || variants!.isEmpty) return null;
    for (final variant in variants!) {
      if (variant.id == defaultVariant) {
        return variant;
      }
    }
    return variants!.first;
  }

  int get variantCount => variants?.length ?? 0;
  bool get hasVariants => variants != null && variants!.isNotEmpty;
}

