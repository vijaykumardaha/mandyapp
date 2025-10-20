import 'package:flutter/foundation.dart';
import 'package:mandyapp/models/item_sale_model.dart';

class Cart {
  int id;
  int customerId;
  String createdAt;
  String status; // 'open', 'completed'
  String cartFor; // 'seller' or 'buyer'
  List<ItemSale>? items;

  Cart({
    required this.id,
    required this.customerId,
    required this.createdAt,
    this.cartFor = 'buyer',
    this.status = 'open',
    this.items,
  });

  // Convert Cart to Map for database insertion
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'created_at': createdAt,
      'cart_for': cartFor,
      'status': status,
    };
  }

  // Create Cart from Map (database query result)
  factory Cart.fromJson(Map<String, dynamic> json, {List<ItemSale>? items}) {
    return Cart(
      id: json['id'] as int,
      customerId: json['customer_id'] as int,
      createdAt: json['created_at'] as String,
      cartFor: (json['cart_for'] as String?)?.trim().toLowerCase() == 'seller' ? 'seller' : 'buyer',
      status: json['status'] as String? ?? 'open',
      items: items,
    );
  }

  // Create a copy of Cart with updated fields
  Cart copyWith({
    required int id,
    int? customerId,
    String? createdAt,
    String? cartFor,
    String? status,
    List<ItemSale>? items,
  }) {
    return Cart(
      id: id,
      customerId: customerId ?? this.customerId,
      createdAt: createdAt ?? this.createdAt,
      cartFor: cartFor != null && cartFor.trim().toLowerCase() == 'seller' ? 'seller' : (cartFor != null ? 'buyer' : this.cartFor),
      status: status ?? this.status,
      items: items ?? this.items,
    );
  }

  // Check if cart is open
  bool get isOpen => status == 'open';

  // Check if cart is completed
  bool get isCompleted => status == 'completed';

  // Get total number of items in cart (total quantity, not number of line items)
  int get itemCount {
    if (items == null || items!.isEmpty) return 0;
    return totalQuantity.toInt();
  }

  // Get number of different line items in cart (for counting distinct products)
  int get lineItemCount => items?.length ?? 0;

  // Get total quantity of all items
  double get totalQuantity {
    if (items == null || items!.isEmpty) return 0.0;
    return items!.fold(0.0, (sum, item) => sum + item.quantity);
  }

  // Get total price of all items
  double get totalPrice {
    if (items == null || items!.isEmpty) return 0.0;
    return items!.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Check if cart is empty
  bool get isEmpty => items == null || items!.isEmpty;

  // Check if cart has items
  bool get hasItems => items != null && items!.isNotEmpty;

  @override
  String toString() {
    return 'Cart{id: $id, customerId: $customerId, createdAt: $createdAt, status: $status, itemCount: $itemCount}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cart &&
        other.id == id &&
        other.customerId == customerId &&
        other.createdAt == createdAt &&
        other.cartFor == cartFor &&
        other.status == status &&
        listEquals(other.items, items);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      customerId,
      createdAt,
      cartFor,
      status,
      Object.hashAll(items ?? const []),
    );
  }
}
