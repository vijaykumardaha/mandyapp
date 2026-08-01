import 'package:flutter/foundation.dart';
import 'package:krishimandi/models/order_item_model.dart';

class Order {
  int? id;
  int? mandiId;
  int customerId;
  String orderFor; // 'seller' or 'buyer'
  int? updatedAt;
  int? isDeleted;
  int? syncStatus;
  List<OrderItem>? items;

  Order({
    this.id,
    this.mandiId,
    required this.customerId,
    this.orderFor = 'buyer',
    this.updatedAt,
    this.isDeleted = 0,
    this.syncStatus = 0,
    this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mandi_id': mandiId,
      'customer_id': customerId,
      'order_for': orderFor,
      'updated_at': updatedAt ?? DateTime.now().millisecondsSinceEpoch,
      'is_deleted': isDeleted ?? 0,
      'sync_status': syncStatus ?? 0,
    };
  }

  factory Order.fromJson(Map<String, dynamic> json, {List<OrderItem>? items}) {
    return Order(
      id: json['id'] as int?,
      mandiId: json['mandi_id'] as int?,
      customerId: json['customer_id'] as int,
      orderFor: (json['order_for'] as String?)?.trim().toLowerCase() == 'seller'
          ? 'seller'
          : 'buyer',
      updatedAt:
          json['updated_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      isDeleted: json['is_deleted'] as int? ?? 0,
      syncStatus: json['sync_status'] as int? ?? 0,
      items: items,
    );
  }

  Order copyWith({
    required int id,
    int? customerId,
    String? orderFor,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id,
      customerId: customerId ?? this.customerId,
      orderFor: orderFor != null && orderFor.trim().toLowerCase() == 'seller'
          ? 'seller'
          : (orderFor != null ? 'buyer' : this.orderFor),
      items: items ?? this.items,
    );
  }

  int get itemCount {
    if (items == null || items!.isEmpty) return 0;
    return totalQuantity.toInt();
  }

  int get lineItemCount => items?.length ?? 0;

  double get totalQuantity {
    if (items == null || items!.isEmpty) return 0.0;
    return items!.fold(0.0, (sum, item) => sum + item.quantity);
  }

  double get totalPrice {
    if (items == null || items!.isEmpty) return 0.0;
    return items!
        .fold(0.0, (sum, item) => sum + item.sellingPrice * item.quantity);
  }

  bool get isEmpty => items == null || items!.isEmpty;

  bool get hasItems => items != null && items!.isNotEmpty;

  @override
  String toString() {
    return 'Order{id: $id, customerId: $customerId, itemCount: $itemCount}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order &&
        other.id == id &&
        other.customerId == customerId &&
        other.orderFor == orderFor &&
        listEquals(other.items, items);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      customerId,
      orderFor,
      Object.hashAll(items ?? const []),
    );
  }
}
