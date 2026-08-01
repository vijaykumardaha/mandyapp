import 'package:mandiapp/helpers/extensions/string.dart';
import 'package:mandiapp/models/customer_model.dart';
import 'package:mandiapp/models/order_item_model.dart';
import 'package:mandiapp/models/product_model.dart';
import 'package:mandiapp/models/product_variant_model.dart';

class BillLineItem {
  final OrderItem sale;
  final Product? product;
  final ProductVariant? variant;
  final Customer? seller;

  const BillLineItem({
    required this.sale,
    required this.product,
    required this.variant,
    required this.seller,
  });

  String get productName {
    final variantName = variant?.variantName.trim();
    if (variantName != null && variantName.isNotEmpty) {
      return variantName;
    }

    final baseName = product?.defaultVariantModel?.variantName.trim();
    if (baseName != null && baseName.isNotEmpty) {
      return baseName;
    }

    return 'Unknown Item';
  }

  String? get variantLabel {
    if (variant == null) return null;
    final variantName = variant!.variantName.trim();
    if (variantName.isNotEmpty && variantName != productName) {
      return variantName;
    }
    return '${variant!.quantity.toStringAsFixed(0)} ${variant!.unit.unitAbbreviation}';
  }

  String get quantityLabel {
    final qty = sale.quantity;
    if (qty % 1 == 0) {
      return qty.toStringAsFixed(0);
    }
    return qty.toStringAsFixed(2);
  }

  double get sellingPrice => sale.sellingPrice;

  double get totalPrice => sale.quantity * sale.sellingPrice;

  String get unitLabel {
    final saleUnit = sale.unit.trim();
    if (saleUnit.isNotEmpty) {
      return saleUnit.unitAbbreviation;
    }
    final variantUnit = variant?.unit.trim();
    if (variantUnit != null && variantUnit.isNotEmpty) {
      return variantUnit.unitAbbreviation;
    }
    return '';
  }

  String get sellerLabel {
    final sellerName = seller?.name?.trim();
    if (sellerName != null && sellerName.isNotEmpty) {
      return sellerName;
    }
    return 'Seller';
  }
}
