import 'package:flutter/foundation.dart';
import 'package:mandyapp/models/order_item_model.dart';

class Order {
  int? id;
  int? mandyId;
  int customerId;
  String createdAt;
  String status; // 'open', 'completed'
  String orderFor; // 'seller' or 'buyer'
  int? updatedAt;
  int? isDeleted;
  int? syncStatus;
  List<OrderItem>? items;

  Order({
    this.id,
    this.mandyId,
    required this.customerId,
    required this.createdAt,
    this.orderFor = 'buyer',
    this.status = 'open',
    this.updatedAt,
    this.isDeleted = 0,
    this.syncStatus = 0,
    this.items,
  });

  // Convert Order to Map for database insertion
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mandy_id': mandyId,
      'customer_id': customerId,
      'created_at': createdAt,
      'order_for': orderFor,
      'status': status,
      'updated_at': updatedAt ?? DateTime.now().millisecondsSinceEpoch,
      'is_deleted': isDeleted ?? 0,
      'sync_status': syncStatus ?? 0,
    };
  }

  // Create Order from Map (database query result)
  factory Order.fromJson(Map<String, dynamic> json, {List<OrderItem>? items}) {
    return Order(
      id: json['id'] as int?,
      mandyId: json['mandy_id'] as int?,
      customerId: json['customer_id'] as int,
      createdAt: json['created_at'] as String,
      orderFor: (json['order_for'] as String?)?.trim().toLowerCase() == 'seller' ? 'seller' : 'buyer',
      status: json['status'] as String? ?? 'open',
      updatedAt: json['updated_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      isDeleted: json['is_deleted'] as int? ?? 0,
      syncStatus: json['sync_status'] as int? ?? 0,
      items: items,
    );
  }

  // Create a copy of Order with updated fields
  Order copyWith({
    required int id,
    int? customerId,
    String? createdAt,
    String? orderFor,
    String? status,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id,
      customerId: customerId ?? this.customerId,
      createdAt: createdAt ?? this.createdAt,
      orderFor: orderFor != null && orderFor.trim().toLowerCase() == 'seller' ? 'seller' : (orderFor != null ? 'buyer' : this.orderFor),
      status: status ?? this.status,
      items: items ?? this.items,
    );
  }

  // Check if order is open
  bool get isOpen => status == 'open';

  // Check if order is completed
  bool get isCompleted => status == 'completed';

  // Get total number of items in order (total quantity, not number of line items)
  int get itemCount {
    if (items == null || items!.isEmpty) return 0;
    return totalQuantity.toInt();
  }

  // Get number of different line items in order (for counting distinct products)
  int get lineItemCount => items?.length ?? 0;

  // Get total quantity of all items
  double get totalQuantity {
    if (items == null || items!.isEmpty) return 0.0;
    return items!.fold(0.0, (sum, item) => sum + item.quantity);
  }

  // Get total price of all items
  double get totalPrice {
    if (items == null || items!.isEmpty) return 0.0;
    return items!.fold(0.0, (sum, item) => sum + item.sellingPrice * item.quantity);
  }

  // Check if order is empty
  bool get isEmpty => items == null || items!.isEmpty;

  // Check if order has items
  bool get hasItems => items != null && items!.isNotEmpty;

  @override
  String toString() {
    return 'Order{id: $id, customerId: $customerId, createdAt: $createdAt, status: $status, itemCount: $itemCount}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order &&
        other.id == id &&
        other.customerId == customerId &&
        other.createdAt == createdAt &&
        other.orderFor == orderFor &&
        other.status == status &&
        listEquals(other.items, items);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      customerId,
      createdAt,
      orderFor,
      status,
      Object.hashAll(items ?? const []),
    );
  }
}
