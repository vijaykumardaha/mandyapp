import 'package:mandyapp/models/product_variant_model.dart';

class Product {
  int? id;
  int? mandyId;
  int defaultVariant;
  int? updatedAt;
  int? isDeleted;
  int? syncStatus;
  List<ProductVariant>? variants;

  Product({
    this.id,
    this.mandyId,
    required this.defaultVariant,
    this.updatedAt,
    this.isDeleted = 0,
    this.syncStatus = 0,
    this.variants,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mandy_id': mandyId,
      'default_variant': defaultVariant,
      'updated_at': updatedAt ?? DateTime.now().millisecondsSinceEpoch,
      'is_deleted': isDeleted ?? 0,
      'sync_status': syncStatus ?? 0,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json, {List<ProductVariant>? variants}) {
    return Product(
      id: json['id'] as int?,
      mandyId: json['mandy_id'] as int?,
      defaultVariant: (json['default_variant'] as int?) ?? 0,
      updatedAt: json['updated_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      isDeleted: json['is_deleted'] as int? ?? 0,
      syncStatus: json['sync_status'] as int? ?? 0,
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

